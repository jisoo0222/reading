package app.dokdok.reader;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Insets;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.CancellationSignal;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import android.view.View;
import android.view.WindowInsets;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;
import android.window.OnBackInvokedDispatcher;

import androidx.credentials.Credential;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.GetCredentialCancellationException;
import androidx.credentials.exceptions.GetCredentialException;
import androidx.credentials.exceptions.NoCredentialException;

import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;

import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;

/**
 * GitHub Pages의 똑독 화면을 띄우고 연결이 끊기면 앱에 담긴 화면을 보여 줘요.
 * - 시스템 뒤로가기 → 앱 안의 '뒤로' 버튼(gback)과 연결
 * - 프로필 사진 고르기 → 갤러리 선택 창
 * - 이미지 저장(문장 카드·독서 유형 카드·스티커) → 사진 앱(Pictures/DdokDok)에 저장
 * - 공유하기 → 안드로이드 공유 창
 */
public class MainActivity extends Activity {
    private static final int REQ_FILE = 41;
    private static final int REQ_SHARE = 42;
    private static final String ASSET_URL = "file:///android_asset/index.html";
    private static final String PUBLISHED_URL = "https://jisoo0222.github.io/reading/Reading_app.html";
    private static final String SUPABASE_AUTH_HOST = "zgsodnnlblfnrbcwatvs.supabase.co";
    /** 앱에 들어 있는 Pretendard 글꼴을 웹 화면에 건네줄 때 쓰는 가상 주소 */
    private static final String FONT_URL = "https://dokdok.app.font/PretendardVariable.woff2";
    private WebView web;
    private ValueCallback<Uri[]> fileCb;
    private boolean fallbackLoaded;
    private boolean bridgeAttached;
    private CancellationSignal googleSignIn;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#F3EDE7"));
        setContentView(web);
        // API 35 이상에서 강제되는 edge-to-edge에서도 조작이 시스템 바에 가리지 않게 해요.
        web.setOnApplyWindowInsetsListener((view, insets) -> {
            if (Build.VERSION.SDK_INT >= 30) {
                Insets bars = insets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
                view.setPadding(bars.left, bars.top, bars.right, bars.bottom);
                return WindowInsets.CONSUMED;
            }
            view.setPadding(insets.getSystemWindowInsetLeft(), insets.getSystemWindowInsetTop(),
                    insets.getSystemWindowInsetRight(), insets.getSystemWindowInsetBottom());
            return insets.consumeSystemWindowInsets();
        });
        web.requestApplyInsets();
        if (Build.VERSION.SDK_INT >= 33) {
            getOnBackInvokedDispatcher().registerOnBackInvokedCallback(
                    OnBackInvokedDispatcher.PRIORITY_DEFAULT, this::onBackPressed);
        }

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(false);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        if (!BuildConfig.DEBUG) s.setCacheMode(WebSettings.LOAD_NO_CACHE);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setTextZoom(100); // 시스템 글꼴 크기 때문에 레이아웃이 깨지지 않게 고정
        // 화면 설계(폭 360px)를 기기 폭에 맞춰 통째로 확대해서 Pixel 등 큰 화면을 꽉 채워요.
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        setBridgeAttached(true);

        web.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if (!request.isForMainFrame()) return true;
                if (isAppPage(uri)) {
                    setBridgeAttached(true);
                    return false;
                }
                if (isKakaoAuthPage(uri)) {
                    setBridgeAttached(false);
                    return false;
                }
                boolean email = "mailto".equals(uri.getScheme());
                if (!email && !"https".equals(uri.getScheme()) && !"http".equals(uri.getScheme())) return true;
                try {
                    startActivity(new Intent(email ? Intent.ACTION_SENDTO : Intent.ACTION_VIEW, uri));
                } catch (Exception e) {
                    toast("연결할 앱을 찾지 못했어요");
                }
                return true;
            }

            @Override
            public void onPageFinished(WebView v, String url) {
                if (isAppPage(Uri.parse(url))) v.evaluateJavascript(SHIM, null);
            }

            @Override
            public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest r) {
                // 웹 화면이 Pretendard를 요청하면 앱 안의 글꼴 파일을 그대로 넘겨줘요.
                if (FONT_URL.equals(r.getUrl().toString())) {
                    try {
                        Map<String, String> h = new HashMap<>();
                        h.put("Access-Control-Allow-Origin", "*");
                        h.put("Cache-Control", "max-age=31536000");
                        return new WebResourceResponse("font/woff2", null, 200, "OK", h,
                                getAssets().open("fonts/PretendardVariable.woff2"));
                    } catch (Exception e) {
                        return null;
                    }
                }
                return super.shouldInterceptRequest(v, r);
            }

            @Override
            public void onReceivedError(WebView v, WebResourceRequest r, WebResourceError e) {
                loadFallback(v, r);
            }

            @Override
            public void onReceivedHttpError(WebView v, WebResourceRequest r, WebResourceResponse e) {
                loadFallback(v, r);
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams p) {
                if (fileCb != null) fileCb.onReceiveValue(null);
                fileCb = cb;
                Intent i = new Intent(Intent.ACTION_GET_CONTENT);
                i.addCategory(Intent.CATEGORY_OPENABLE);
                i.setType("image/*");
                try {
                    startActivityForResult(Intent.createChooser(i, "사진 고르기"), REQ_FILE);
                } catch (Exception e) {
                    fileCb = null;
                    return false;
                }
                return true;
            }
        });

        web.loadUrl(startPage());
    }

    private static String startPage() {
        return BuildConfig.DEV_URL.isEmpty() ? PUBLISHED_URL : BuildConfig.DEV_URL;
    }

    private static boolean isAppPage(Uri uri) {
        if (!uri.isHierarchical()) return false;
        String page = uri.buildUpon().clearQuery().fragment(null).build().toString();
        if (ASSET_URL.equals(page) || PUBLISHED_URL.equals(page)) return true;
        return !BuildConfig.DEV_URL.isEmpty() && (BuildConfig.DEV_URL.equals(page)
                || (BuildConfig.DEV_URL + "Reading_app.html").equals(page));
    }

    private boolean isPublishedPage() {
        String url = web.getUrl();
        return url != null && PUBLISHED_URL.equals(Uri.parse(url).buildUpon().clearQuery().fragment(null).build().toString());
    }

    private static boolean isKakaoAuthPage(Uri uri) {
        if (!"https".equals(uri.getScheme()) || uri.getUserInfo() != null
                || (uri.getPort() != -1 && uri.getPort() != 443)) return false;
        String host = uri.getHost();
        if ("kauth.kakao.com".equals(host) || "accounts.kakao.com".equals(host)) return true;
        if (!SUPABASE_AUTH_HOST.equals(host)) return false;
        String path = uri.getEncodedPath();
        return "/auth/v1/callback".equals(path)
                || ("/auth/v1/authorize".equals(path) && "kakao".equals(uri.getQueryParameter("provider")));
    }

    private void setBridgeAttached(boolean attached) {
        if (attached == bridgeAttached) return;
        if (attached) web.addJavascriptInterface(new Bridge(), "AndroidBridge");
        else web.removeJavascriptInterface("AndroidBridge");
        bridgeAttached = attached;
    }

    private void loadFallback(WebView view, WebResourceRequest request) {
        if (fallbackLoaded || !request.isForMainFrame()) return;
        Uri uri = request.getUrl();
        if (!isAppPage(uri) || "file".equals(uri.getScheme())) return;
        fallbackLoaded = true;
        toast("연결이 잠시 끊겨서 앱에 들어 있는 화면을 보여 드려요.");
        setBridgeAttached(true);
        view.loadUrl(ASSET_URL);
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        super.onActivityResult(req, res, data);
        if (req == REQ_SHARE) {
            web.evaluateJavascript("window.__shareResult && window.__shareResult(" + (res == RESULT_OK) + ")", null);
            return;
        }
        if (req != REQ_FILE || fileCb == null) return;
        Uri[] r = null;
        if (res == RESULT_OK && data != null && data.getData() != null) r = new Uri[]{data.getData()};
        fileCb.onReceiveValue(r);
        fileCb = null;
    }

    @Override
    protected void onDestroy() {
        if (googleSignIn != null) {
            googleSignIn.cancel();
            googleSignIn = null;
        }
        super.onDestroy();
    }

    private void startGoogleSignIn(String requestId) {
        if (!isPublishedPage() || googleSignIn != null) return;
        byte[] random = new byte[32];
        new SecureRandom().nextBytes(random);
        String nonce = Base64.encodeToString(random, Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING);
        String hashedNonce;
        try {
            byte[] bytes = MessageDigest.getInstance("SHA-256").digest(nonce.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(bytes.length * 2);
            for (byte b : bytes) hex.append(Character.forDigit((b & 0xff) >>> 4, 16)).append(Character.forDigit(b & 0xf, 16));
            hashedNonce = hex.toString();
        } catch (NoSuchAlgorithmException e) {
            finishGoogleSignIn(requestId, "error", "", "");
            return;
        }

        googleSignIn = new CancellationSignal();
        try {
            GetSignInWithGoogleOption option = new GetSignInWithGoogleOption.Builder(getString(R.string.google_server_client_id))
                    .setNonce(hashedNonce)
                    .build();
            GetCredentialRequest request = new GetCredentialRequest.Builder().addCredentialOption(option).build();
            CredentialManager.create(this).getCredentialAsync(this, request, googleSignIn, this::runOnUiThread,
                    new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                        @Override
                        public void onResult(GetCredentialResponse response) {
                            Credential credential = response.getCredential();
                            if (!(credential instanceof CustomCredential)
                                    || !GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL.equals(credential.getType())) {
                                finishGoogleSignIn(requestId, "error", "", "");
                                return;
                            }
                            try {
                                String idToken = GoogleIdTokenCredential.createFrom(credential.getData()).getIdToken();
                                finishGoogleSignIn(requestId, "ok", idToken, nonce);
                            } catch (RuntimeException e) {
                                finishGoogleSignIn(requestId, "error", "", "");
                            }
                        }

                        @Override
                        public void onError(GetCredentialException error) {
                            String status = "error";
                            if (error instanceof GetCredentialCancellationException) status = "cancelled";
                            else if (error instanceof NoCredentialException) status = "no_account";
                            finishGoogleSignIn(requestId, status, "", "");
                        }
                    });
        } catch (RuntimeException e) {
            finishGoogleSignIn(requestId, "error", "", "");
        }
    }

    private void finishGoogleSignIn(String requestId, String status, String token, String nonce) {
        googleSignIn = null;
        if (isFinishing() || isDestroyed() || !isPublishedPage()) return;
        String payload = "{id:" + JSONObject.quote(requestId) + ",status:" + JSONObject.quote(status)
                + ",token:" + JSONObject.quote(token) + ",nonce:" + JSONObject.quote(nonce) + "}";
        web.evaluateJavascript("window.ddokGoogleSignInResult && window.ddokGoogleSignInResult(" + payload + ")", null);
    }

    @Override
    public void onBackPressed() {
        // 팝업이 열려 있으면 닫고, 아니면 앱 안의 '뒤로' 버튼을 누른 것처럼 동작. 더 갈 곳이 없으면 앱 종료.
        web.evaluateJavascript(
            "(function(){var d=document.querySelector('dialog[open]');if(d){if(d.dispatchEvent(new Event('cancel',{cancelable:true})))d.close();return 'x'}" +
            "var o=document.getElementById('ov2');if(o){o.click();return 'x'}" +
            "var s=document.getElementById('sheet'),ov=document.getElementById('ov');if(s&&s.classList.contains('on')){if(ov)ov.click();else s.classList.remove('on');return 'x'}" +
            "var b=document.querySelector('[aria-label=\"뒤로\"]');if(b){b.click();return 'b'}return ''})()",
            v -> { if (v == null || v.equals("\"\"") || v.equals("null")) MainActivity.super.onBackPressed(); });
    }

    /** 웹 쪽에서 부르는 기능: 이미지 저장, 공유 */
    private class Bridge {
        @JavascriptInterface
        public void signInWithGoogle(String requestId) {
            if (requestId == null || !requestId.matches("[0-9a-f-]{36}")) return;
            runOnUiThread(() -> startGoogleSignIn(requestId));
        }

        @JavascriptInterface
        public void saveImage(String dataUrl, String name) {
            try {
                String b64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
                byte[] bytes = Base64.decode(b64, Base64.DEFAULT);
                String fn = name == null || name.isEmpty() ? "ddokdok.png" : name;
                if (Build.VERSION.SDK_INT >= 29) {
                    ContentValues cv = new ContentValues();
                    cv.put(MediaStore.Images.Media.DISPLAY_NAME, fn);
                    cv.put(MediaStore.Images.Media.MIME_TYPE, "image/png");
                    cv.put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/DdokDok");
                    Uri u = getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, cv);
                    try (OutputStream os = getContentResolver().openOutputStream(u)) { os.write(bytes); }
                } else {
                    File dir = new File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "DdokDok");
                    dir.mkdirs();
                    try (FileOutputStream os = new FileOutputStream(new File(dir, fn))) { os.write(bytes); }
                }
                toast("사진에 저장했어요");
            } catch (Exception e) {
                toast("저장하지 못했어요");
            }
        }

        @JavascriptInterface
        public void shareText(String title, String text) {
            runOnUiThread(() -> {
                Intent i = new Intent(Intent.ACTION_SEND);
                i.setType("text/plain");
                i.putExtra(Intent.EXTRA_SUBJECT, title);
                i.putExtra(Intent.EXTRA_TEXT, text);
                try {
                    startActivityForResult(Intent.createChooser(i, "공유하기"), REQ_SHARE);
                } catch (Exception e) {
                    web.evaluateJavascript("window.__shareResult && window.__shareResult(false)", null);
                }
            });
        }
    }

    private void toast(String m) {
        runOnUiThread(() -> Toast.makeText(this, m, Toast.LENGTH_SHORT).show());
    }

    /**
     * 페이지가 열린 뒤 넣는 작은 연결 코드.
     * - 웹뷰는 navigator.share 가 없어서 안드로이드 공유 창으로 연결
     * - 'blob:' 이미지 다운로드 링크를 가로채 사진 앱에 저장
     * - 기기에 Pretendard가 없어도 같은 글씨로 보이도록 앱 안의 글꼴을 연결
     * 웹 파일(Reading_app.html)은 고치지 않아요.
     */
    private static final String SHIM =
        "(function(){if(window.__dk)return;window.__dk=1;var B=window.AndroidBridge;if(!B)return;" +
        "var fs=document.createElement('style');fs.textContent=\"@font-face{font-family:Pretendard;src:url('" + FONT_URL + "') format('woff2');font-weight:45 920;font-style:normal;font-display:swap}\";document.head.appendChild(fs);" +
        "navigator.share=function(d){d=d||{};return new Promise(function(resolve,reject){if(window.__shareResult){reject(new Error('Share already open'));return}window.__shareResult=function(ok){window.__shareResult=null;if(ok)resolve();else{var e=new Error('Share cancelled');e.name='AbortError';reject(e)}};try{B.shareText(d.title||'',[d.text,d.url].filter(Boolean).join('\\n'))}catch(e){window.__shareResult=null;reject(e)}})};" +
        "navigator.canShare=function(){return false};" +
        "var oc=HTMLAnchorElement.prototype.click;HTMLAnchorElement.prototype.click=function(){" +
        "if(this.download&&/^(blob:|data:)/.test(this.href)){var n=this.download,h=this.href;" +
        "if(h.indexOf('data:')===0){B.saveImage(h,n);return}" +
        "fetch(h).then(function(r){return r.blob()}).then(function(b){var f=new FileReader();f.onload=function(){B.saveImage(f.result,n)};f.readAsDataURL(b)});return}" +
        "return oc.apply(this,arguments)}})()";
}
