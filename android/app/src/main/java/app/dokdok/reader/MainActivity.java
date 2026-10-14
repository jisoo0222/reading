package app.dokdok.reader;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import android.view.View;
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

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;

/**
 * 똑독 웹 프로토타입(Reading_app.html)을 그대로 띄우는 안드로이드 화면.
 * - 시스템 뒤로가기 → 앱 안의 '뒤로' 버튼(gback)과 연결
 * - 프로필 사진 고르기 → 갤러리 선택 창
 * - 이미지 저장(문장 카드·독서 유형 카드·스티커) → 사진 앱(Pictures/DdokDok)에 저장
 * - 공유하기 → 안드로이드 공유 창
 */
public class MainActivity extends Activity {
    private static final int REQ_FILE = 41;
    private static final String ASSET_URL = "file:///android_asset/index.html";
    /** 앱에 들어 있는 Pretendard 글꼴을 웹 화면에 건네줄 때 쓰는 가상 주소 */
    private static final String FONT_URL = "https://dokdok.app.font/PretendardVariable.woff2";
    private WebView web;
    private ValueCallback<Uri[]> fileCb;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#F3EDE7"));
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setTextZoom(100); // 시스템 글꼴 크기 때문에 레이아웃이 깨지지 않게 고정
        // 화면 설계(폭 360px)를 기기 폭에 맞춰 통째로 확대해서 Pixel 등 큰 화면을 꽉 채워요.
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.addJavascriptInterface(new Bridge(), "AndroidBridge");

        web.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView v, String url) {
                v.evaluateJavascript(SHIM, null);
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
                // 개발 서버에 연결하지 못하면 앱 안의 화면으로 바꿔 띄워요.
                if (r.isForMainFrame() && !BuildConfig.DEV_URL.isEmpty()
                        && r.getUrl().toString().startsWith(BuildConfig.DEV_URL)) {
                    toast("개발 서버가 꺼져 있어서 앱에 들어 있는 화면을 띄웠어요");
                    v.loadUrl(ASSET_URL);
                }
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

        if (state != null) web.restoreState(state);
        else web.loadUrl(BuildConfig.DEV_URL.isEmpty() ? ASSET_URL : BuildConfig.DEV_URL);
    }

    @Override
    protected void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        web.saveState(out);
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        super.onActivityResult(req, res, data);
        if (req != REQ_FILE || fileCb == null) return;
        Uri[] r = null;
        if (res == RESULT_OK && data != null && data.getData() != null) r = new Uri[]{data.getData()};
        fileCb.onReceiveValue(r);
        fileCb = null;
    }

    @Override
    public void onBackPressed() {
        // 팝업이 열려 있으면 닫고, 아니면 앱 안의 '뒤로' 버튼을 누른 것처럼 동작. 더 갈 곳이 없으면 앱 종료.
        web.evaluateJavascript(
            "(function(){var o=document.getElementById('ov2');if(o){o.click();return 'x'}" +
            "var b=document.querySelector('[aria-label=\"뒤로\"]');if(b){b.click();return 'b'}return ''})()",
            v -> { if (v == null || v.equals("\"\"") || v.equals("null")) MainActivity.super.onBackPressed(); });
    }

    /** 웹 쪽에서 부르는 기능: 이미지 저장, 공유 */
    private class Bridge {
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
                startActivity(Intent.createChooser(i, "공유하기"));
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
        "navigator.share=function(d){d=d||{};B.shareText(d.title||'',[d.text,d.url].filter(Boolean).join('\\n'));return Promise.resolve()};" +
        "navigator.canShare=function(){return false};" +
        "var oc=HTMLAnchorElement.prototype.click;HTMLAnchorElement.prototype.click=function(){" +
        "if(this.download&&/^(blob:|data:)/.test(this.href)){var n=this.download,h=this.href;" +
        "if(h.indexOf('data:')===0){B.saveImage(h,n);return}" +
        "fetch(h).then(function(r){return r.blob()}).then(function(b){var f=new FileReader();f.onload=function(){B.saveImage(f.result,n)};f.readAsDataURL(b)});return}" +
        "return oc.apply(this,arguments)}})()";
}
