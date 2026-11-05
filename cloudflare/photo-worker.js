/**
 * CampusFix photo API (Cloudflare Worker + Workers KV or R2).
 *
 * Replaces Firebase Storage for incident photos. Paste this file into a
 * Worker in the Cloudflare dashboard, then add:
 *   - a binding named   PHOTOS  -> a KV namespace (free, no card needed)
 *                                  or an R2 bucket (both work)
 *   - a variable named  FIREBASE_PROJECT_ID  (e.g. alu-campus-fix)
 *
 * Routes
 *   POST   /photos/incidents/{uid}/{name}.jpg   upload (owner only)
 *   GET    /photos/incidents/{uid}/{name}.jpg   view (anyone with the link)
 *   DELETE /photos/incidents/{uid}/{name}.jpg   delete (owner only)
 *
 * Uploads and deletes need "Authorization: Bearer <Firebase ID token>".
 * The token is checked against Google's public keys, so only signed-in,
 * email-verified CampusFix users can write, and only into their own folder
 * (the same rules storage.rules enforced on Firebase Storage).
 */

const MAX_BYTES = 5 * 1024 * 1024; // 5 MB, same limit as before
const PATH_RE = /^incidents\/([A-Za-z0-9]{1,128})\/[A-Za-z0-9_-]{1,200}\.jpg$/;
const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      if (url.pathname === '/' || url.pathname === '/health') {
        return json({ ok: true, service: 'campusfix-photos' });
      }
      if (!url.pathname.startsWith('/photos/')) throw new HttpError(404, 'Not found');

      const path = decodeURIComponent(url.pathname.slice('/photos/'.length));
      const match = PATH_RE.exec(path);
      if (!match) throw new HttpError(400, 'Invalid photo path');
      const ownerUid = match[1];

      switch (request.method) {
        case 'GET':
          return await serve(env, path);
        case 'POST':
        case 'PUT':
          await requireOwner(request, env, ownerUid);
          return await upload(request, env, url, path);
        case 'DELETE':
          await requireOwner(request, env, ownerUid);
          await store(env).delete(path);
          return json({ deleted: path });
        default:
          throw new HttpError(405, 'Method not allowed');
      }
    } catch (e) {
      const status = e instanceof HttpError ? e.status : 500;
      if (status === 500) console.error(e);
      return json({ error: e instanceof HttpError ? e.message : 'Server error' }, status);
    }
  },
};

async function serve(env, path) {
  const photo = await store(env).get(path);
  if (!photo) throw new HttpError(404, 'Photo not found');
  return new Response(photo.body, {
    headers: {
      'content-type': photo.contentType || 'image/jpeg',
      'cache-control': 'public, max-age=31536000, immutable',
    },
  });
}

/**
 * Same three operations over whichever storage PHOTOS is bound to.
 * KV namespaces have getWithMetadata; R2 buckets have head.
 */
function store(env) {
  // PHOTOS is the intended name; KV is the dashboard's default, accepted too.
  const b = env.PHOTOS || env.KV;
  if (!b) throw new Error('No storage binding: add a KV namespace called PHOTOS (or KV)');
  if (typeof b.getWithMetadata === 'function') {
    return {
      put: (key, body, contentType) => b.put(key, body, { metadata: { contentType } }),
      get: async (key) => {
        const { value, metadata } = await b.getWithMetadata(key, { type: 'stream' });
        return value ? { body: value, contentType: metadata?.contentType } : null;
      },
      delete: (key) => b.delete(key),
    };
  }
  return {
    put: (key, body, contentType) => b.put(key, body, { httpMetadata: { contentType } }),
    get: async (key) => {
      const obj = await b.get(key);
      return obj ? { body: obj.body, contentType: obj.httpMetadata?.contentType } : null;
    },
    delete: (key) => b.delete(key),
  };
}

async function upload(request, env, url, path) {
  const type = request.headers.get('content-type') || '';
  if (!type.startsWith('image/')) throw new HttpError(415, 'Only images can be uploaded');

  const declared = Number(request.headers.get('content-length') || 0);
  if (declared > MAX_BYTES) throw new HttpError(413, 'Photo is larger than 5 MB');

  const body = await request.arrayBuffer();
  if (body.byteLength === 0) throw new HttpError(400, 'Empty upload');
  if (body.byteLength > MAX_BYTES) throw new HttpError(413, 'Photo is larger than 5 MB');

  await store(env).put(path, body, type);
  return json({ path, url: `${url.origin}/photos/${path}` }, 201);
}

/** Verifies the Firebase ID token and that it belongs to the folder owner. */
async function requireOwner(request, env, ownerUid) {
  const auth = request.headers.get('authorization') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!token) throw new HttpError(401, 'Sign in required');
  if (!env.FIREBASE_PROJECT_ID) throw new Error('FIREBASE_PROJECT_ID is not set');

  const claims = await verifyFirebaseToken(token, env.FIREBASE_PROJECT_ID);
  if (claims.email_verified !== true) throw new HttpError(403, 'Verify your email first');
  if (claims.sub !== ownerUid) throw new HttpError(403, 'You can only change your own photos');
}

// ---- Firebase ID token verification (RS256, Google's public keys) ---------

let keyCache = { keys: null, expires: 0 };

async function googleKeys() {
  if (keyCache.keys && Date.now() < keyCache.expires) return keyCache.keys;
  const res = await fetch(JWKS_URL);
  if (!res.ok) throw new Error(`Could not load Google keys (${res.status})`);
  const { keys } = await res.json();
  keyCache = { keys, expires: Date.now() + 60 * 60 * 1000 };
  return keys;
}

async function verifyFirebaseToken(token, projectId) {
  const parts = token.split('.');
  if (parts.length !== 3) throw new HttpError(401, 'Invalid sign-in token');

  let header, claims;
  try {
    header = JSON.parse(decodeText(parts[0]));
    claims = JSON.parse(decodeText(parts[1]));
  } catch {
    throw new HttpError(401, 'Invalid sign-in token');
  }
  if (header.alg !== 'RS256') throw new HttpError(401, 'Invalid sign-in token');

  const jwk = (await googleKeys()).find((k) => k.kid === header.kid);
  if (!jwk) throw new HttpError(401, 'Sign-in token expired, please retry');

  const key = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    base64UrlBytes(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  if (!valid) throw new HttpError(401, 'Invalid sign-in token');

  const now = Math.floor(Date.now() / 1000);
  if (claims.aud !== projectId) throw new HttpError(401, 'Token is for another project');
  if (claims.iss !== `https://securetoken.google.com/${projectId}`) {
    throw new HttpError(401, 'Token is for another project');
  }
  if (typeof claims.exp !== 'number' || claims.exp <= now) {
    throw new HttpError(401, 'Sign-in token expired, please retry');
  }
  if (typeof claims.iat !== 'number' || claims.iat > now + 300) {
    throw new HttpError(401, 'Invalid sign-in token');
  }
  if (!claims.sub) throw new HttpError(401, 'Invalid sign-in token');
  return claims;
}

function base64UrlBytes(s) {
  let b64 = s.replace(/-/g, '+').replace(/_/g, '/');
  while (b64.length % 4) b64 += '=';
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function decodeText(s) {
  return new TextDecoder().decode(base64UrlBytes(s));
}

// ---- helpers ---------------------------------------------------------------

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}
