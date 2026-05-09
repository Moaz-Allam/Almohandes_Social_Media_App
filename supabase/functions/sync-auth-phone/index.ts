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
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function envSecret(name: string): string {
  return (Deno.env.get(name) ?? '').trim().replace(/^['"]|['"]$/g, '');
}

function normalizeSupportedPhone(phone: string): string | null {
  const compact = phone.trim().replace(/[^\d+]/g, '');
  if (/^\+9647[3-9]\d{8}$/.test(compact)) {
    return compact;
  }
  if (/^009647[3-9]\d{8}$/.test(compact)) {
    return `+${compact.slice(2)}`;
  }
  if (/^07[3-9]\d{8}$/.test(compact)) {
    return `+964${compact.slice(1)}`;
  }
  if (/^\+201[0125]\d{8}$/.test(compact)) {
    return compact;
  }
  if (/^00201[0125]\d{8}$/.test(compact)) {
    return `+${compact.slice(2)}`;
  }
  if (/^01[0125]\d{8}$/.test(compact)) {
    return `+20${compact.slice(1)}`;
  }
  return null;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return json({ success: false, message: 'Method not allowed.' }, 405);
  }

  try {
    const authHeader =
      request.headers.get('authorization') ??
      request.headers.get('Authorization') ??
      '';
    if (!authHeader.startsWith('Bearer ')) {
      return json(
        { success: false, message: 'انتهت جلسة الدخول. سجل الدخول مرة أخرى.' },
        401,
      );
    }

    const { phone } = await request.json();
    if (typeof phone !== 'string') {
      return json({ success: false, message: 'رقم الهاتف غير صحيح.' }, 400);
    }

    const normalizedPhone = normalizeSupportedPhone(phone);
    if (!normalizedPhone) {
      return json({ success: false, message: 'رقم الهاتف غير صحيح.' }, 400);
    }

    const supabaseUrl = envSecret('SUPABASE_URL');
    const anonKey = envSecret('SUPABASE_ANON_KEY') ||
      envSecret('SUPABASE_PUBLISHABLE_KEY');
    const serviceRoleKey = envSecret('SUPABASE_SERVICE_ROLE_KEY') ||
      envSecret('SERVICE_ROLE_KEY');
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return json(
        { success: false, message: 'خدمة الحسابات غير مهيأة الآن.' },
        500,
      );
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return json(
        { success: false, message: 'انتهت جلسة الدخول. سجل الدخول مرة أخرى.' },
        401,
      );
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    const metadata = {
      ...(userData.user.user_metadata ?? {}),
      phone: normalizedPhone,
    };
    const { error: updateError } = await adminClient.auth.admin.updateUserById(
      userData.user.id,
      {
        phone: normalizedPhone,
        phone_confirm: true,
        user_metadata: metadata,
      },
    );

    if (updateError) {
      const message = updateError.message.toLowerCase();
      const isDuplicate = message.includes('duplicate') ||
        message.includes('already') ||
        message.includes('registered') ||
        message.includes('unique');
      console.error('Auth phone sync failed', {
        status: updateError.status,
        name: updateError.name,
        message: updateError.message,
      });
      return json(
        {
          success: false,
          message: isDuplicate
            ? 'رقم الهاتف مستخدم بالفعل.'
            : 'تعذر ربط رقم الهاتف بالحساب الآن.',
        },
        isDuplicate ? 409 : 500,
      );
    }

    return json({ success: true });
  } catch (_error) {
    return json(
      { success: false, message: 'تعذر ربط رقم الهاتف بالحساب الآن.' },
      500,
    );
  }
});
