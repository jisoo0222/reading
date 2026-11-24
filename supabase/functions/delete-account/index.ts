// 외부 SDK 없이 Supabase의 공식 HTTP API를 호출해요.
// SUPABASE_SERVICE_ROLE_KEY는 서버 환경에서만 읽고 응답/로그에 넣지 않아요.
const allowed = new Set((Deno.env.get('DDOK_ALLOWED_ORIGINS') || 'https://jisoo0222.github.io,null').split(',').map(x => x.trim()));
function response(status: number, code: string, origin: string, extra: Record<string, unknown> = {}) {
  return new Response(status === 204 ? null : JSON.stringify({ code, ...extra }), { status, headers: {
    'Content-Type': 'application/json', 'Cache-Control': 'no-store',
    'Access-Control-Allow-Origin': allowed.has(origin) ? origin : 'https://jisoo0222.github.io',
    'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Vary': 'Origin',
  }});
}
Deno.serve(async (req: Request) => {
  const origin = req.headers.get('origin') || 'null';
  if (!allowed.has(origin)) return response(403, 'origin_not_allowed', origin);
  if (req.method === 'OPTIONS') return response(204, 'preflight', origin);
  if (req.method !== 'POST') return response(405, 'method_not_allowed', origin);
  const url = Deno.env.get('SUPABASE_URL'), key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return response(503, 'server_not_configured', origin);
  const authorization = req.headers.get('authorization') || '';
  if (!/^Bearer [^\s]+$/.test(authorization)) return response(401, 'login_required', origin);
  if (Number(req.headers.get('content-length') || 0) > 1024) return response(413, 'invalid_request', origin);
  let input;
  try { const text = await req.text(); if (text.length > 1024) throw Error(); input = JSON.parse(text); }
  catch { return response(400, 'invalid_request', origin); }
  if (!input || typeof input !== 'object' || Array.isArray(input) || input.confirmation !== '탈퇴' || Object.keys(input).some(k => k !== 'confirmation')) return response(400, 'confirmation_required', origin);
  try {
    const userResponse = await fetch(url + '/auth/v1/user', { headers: { apikey: key, Authorization: authorization }, signal: AbortSignal.timeout(15000) });
    if (!userResponse.ok) return response(401, 'login_required', origin);
    const user = await userResponse.json();
    if (!/^[0-9a-f-]{36}$/i.test(user.id || '')) return response(401, 'login_required', origin);
    // refresh 시각이 아닌 인증 서버가 반환한 마지막 로그인 시각을 확인해요.
    const signedAt = Date.parse(user.last_sign_in_at || '');
    if (!Number.isFinite(signedAt) || Date.now() - signedAt > 15 * 60 * 1000 || signedAt > Date.now() + 60000) return response(403, 'reauth_required', origin);
    const adminHeaders = { apikey: key, Authorization: 'Bearer ' + key, 'Content-Type': 'application/json' };
    // 삭제 중 새로운 개인 기록/커뮤니티 글이 생기지 않도록 서버 저장을 먼저 잠가요.
    const prepared = await fetch(url + '/rest/v1/rpc/ddok_delete_prepare', { method: 'POST', headers: adminHeaders, body: JSON.stringify({ p_user: user.id }), signal: AbortSignal.timeout(15000) });
    if (!prepared.ok) return response(503, 'deletion_not_ready', origin);
    const inventory = await prepared.json();
    const byBucket = new Map<string, string[]>();
    for (const f of inventory.files || []) {
      if (typeof f.bucket !== 'string' || typeof f.name !== 'string') return response(503, 'storage_inventory_failed', origin);
      if (!byBucket.has(f.bucket)) byBucket.set(f.bucket, []);
      byBucket.get(f.bucket).push(f.name);
    }
    // SQL에서 storage.objects 행만 지우면 실제 파일이 남으므로 Storage API로 삭제해요.
    for (const [bucket, names] of byBucket) {
      for (let i = 0; i < names.length; i += 100) {
        const removed = await fetch(url + '/storage/v1/object/' + encodeURIComponent(bucket), { method: 'DELETE', headers: adminHeaders, body: JSON.stringify({ prefixes: names.slice(i, i + 100) }), signal: AbortSignal.timeout(20000) });
        if (!removed.ok) return response(503, 'storage_delete_failed', origin);
      }
    }
    const removed = await fetch(url + '/auth/v1/admin/users/' + encodeURIComponent(user.id), { method: 'DELETE', headers: adminHeaders, body: JSON.stringify({ should_soft_delete: false }), signal: AbortSignal.timeout(20000) });
    if (!removed.ok) return response(503, 'account_delete_failed', origin);
    // Auth 삭제 트리거와 FK cascade가 회원/독서/커뮤니티 데이터를 제거해요.
    return response(200, 'deleted', origin, { deleted: true });
  } catch {
    return response(503, 'connection_failed', origin);
  }
});
