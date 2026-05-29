// ============================================================
// send-push — delivers an Arabic OS push for a new notification row.
//
// Trigger: a Supabase Database Webhook on INSERT of public.notifications
// (configure in Dashboard → Database → Webhooks, type "Supabase Edge
// Functions", events: INSERT). The webhook posts { type, record, ... }.
//
// Flow: notification.profile_id → profiles.user_id → device_tokens →
// FCM HTTP v1 (one message per token). FCM v1 delivers to Android, iOS
// (APNs) and Web Push (via the webpush block) through the same API.
//
// Secrets required (supabase secrets set ...):
//   FCM_SERVICE_ACCOUNT  – the full service-account JSON (stringified)
//   (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically)
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ---- Google OAuth (service account → access token) -------------------------

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function base64url(input: string | Uint8Array): string {
  const bytes =
    typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let str = '';
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(
    JSON.stringify(claim),
  )}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64url(new Uint8Array(signature))}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`OAuth failed: ${JSON.stringify(data)}`);
  }
  return data.access_token as string;
}

// ---- Handler ---------------------------------------------------------------

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const serviceAccountRaw = Deno.env.get('FCM_SERVICE_ACCOUNT');
    if (!serviceAccountRaw) {
      return json({ sent: false, error: 'FCM_SERVICE_ACCOUNT not set' }, 500);
    }
    const serviceAccount = JSON.parse(serviceAccountRaw);
    const projectId = serviceAccount.project_id as string;

    const payload = await req.json();
    // Webhook shape: { type, table, record, old_record }
    const record = payload.record ?? payload;
    const profileId: string | undefined = record?.profile_id;
    const title: string = record?.title ?? 'إشعار جديد';
    const body: string = record?.message ?? record?.preview ?? '';
    const actionUrl: string = record?.action_url ?? '';
    if (!profileId) {
      return json({ sent: false, error: 'missing profile_id' }, 400);
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // profile_id → user_id → device tokens
    const { data: profile } = await admin
      .from('profiles')
      .select('user_id')
      .eq('id', profileId)
      .maybeSingle();
    const userId = profile?.user_id;
    if (!userId) {
      return json({ sent: false, error: 'no user for profile' }, 200);
    }

    const { data: tokens } = await admin
      .from('device_tokens')
      .select('token, platform')
      .eq('user_id', userId);
    if (!tokens || tokens.length === 0) {
      return json({ sent: false, reason: 'no device tokens' }, 200);
    }

    const accessToken = await getAccessToken(serviceAccount);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    let delivered = 0;
    const stale: string[] = [];
    for (const row of tokens) {
      const message = {
        message: {
          token: row.token,
          notification: { title, body },
          data: { action_url: actionUrl },
          android: { priority: 'HIGH', notification: { sound: 'default' } },
          apns: {
            payload: { aps: { sound: 'default', 'mutable-content': 1 } },
          },
          webpush: {
            notification: { title, body, icon: '/icons/Icon-192.png' },
            fcm_options: actionUrl ? { link: actionUrl } : undefined,
          },
        },
      };
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      });
      if (res.ok) {
        delivered++;
      } else if (res.status === 404 || res.status === 400) {
        // Token no longer valid — schedule for cleanup.
        stale.push(row.token);
      }
    }

    if (stale.length > 0) {
      await admin.from('device_tokens').delete().in('token', stale);
    }

    return json({ sent: delivered > 0, delivered, pruned: stale.length });
  } catch (error) {
    return json({ sent: false, error: `${error}` }, 500);
  }
});
