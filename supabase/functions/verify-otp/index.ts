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

function isDevOtpMode(): boolean {
  const value = Deno.env.get('OTP_DEV_MODE')?.trim().toLowerCase();
  return value === 'true' || value === '1' || value === 'yes';
}

function envSecret(name: string): string {
  return (Deno.env.get(name) ?? '').trim().replace(/^['"]|['"]$/g, '');
}

function envEnabled(name: string): boolean {
  const value = envSecret(name).toLowerCase();
  return value === 'true' || value === '1' || value === 'yes';
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return json({ verified: false, message: 'Method not allowed.' }, 405);
  }

  try {
    const { phone, code } = await request.json();
    if (
      typeof phone !== 'string' ||
      typeof code !== 'string' ||
      !/^\d{6}$/.test(code.trim())
    ) {
      return json({ verified: false, message: 'رمز التحقق غير صحيح.' }, 400);
    }

    const normalizedPhone = normalizeSupportedPhone(phone);
    if (!normalizedPhone) {
      return json({ verified: false, message: 'رقم الهاتف غير صحيح.' }, 400);
    }

    const supabaseUrl = envSecret('SUPABASE_URL');
    const serviceRoleKey = envSecret('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !serviceRoleKey) {
      return json(
        { verified: false, message: 'خدمة التحقق غير مهيأة الآن.' },
        500,
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const accountSid = envSecret('TWILIO_ACCOUNT_SID');
    const authToken = envSecret('TWILIO_AUTH_TOKEN');
    const verifyServiceSid = envSecret('TWILIO_VERIFY_SERVICE_SID');

    if (
      isDevOtpMode() ||
      envEnabled('OTP_PROVIDER_FALLBACK_TO_DEBUG') ||
      envEnabled('OTP_DEBUG_DELIVERY')
    ) {
      const { data, error } = await supabase.rpc('verify_otp_token', {
        p_phone_local10: normalizedPhone,
        p_verification_code: code.trim(),
      });

      if (error) {
        return json(
          { verified: false, message: 'تعذر التحقق من الرمز الآن.' },
          500,
        );
      }

      if (data === true || isDevOtpMode()) {
        return json({ verified: data === true });
      }
    }

    if (accountSid && authToken && verifyServiceSid) {
      const params = new URLSearchParams();
      params.set('To', normalizedPhone);
      params.set('Code', code.trim());

      const verifyResponse = await fetch(
        `https://verify.twilio.com/v2/Services/${verifyServiceSid}/VerificationCheck`,
        {
          method: 'POST',
          headers: {
            Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: params,
        },
      );

      if (!verifyResponse.ok) {
        if (
          envEnabled('OTP_PROVIDER_FALLBACK_TO_DEBUG') ||
          envEnabled('OTP_DEBUG_DELIVERY')
        ) {
          return json({ verified: false });
        }
        return json(
          { verified: false, message: 'تعذر التحقق من الرمز الآن.' },
          502,
        );
      }

      const result = await verifyResponse.json();
      if (result.status !== 'approved') {
        return json({ verified: false });
      }

      const { error } = await supabase.rpc('mark_signup_phone_verified', {
        p_phone: normalizedPhone,
      });

      if (error) {
        return json(
          { verified: false, message: 'تعذر حفظ حالة التحقق الآن.' },
          500,
        );
      }

      return json({ verified: true });
    }

    const { data, error } = await supabase.rpc('verify_otp_token', {
      p_phone_local10: normalizedPhone,
      p_verification_code: code.trim(),
    });

    if (error) {
      return json(
        { verified: false, message: 'تعذر التحقق من الرمز الآن.' },
        500,
      );
    }

    return json({ verified: data === true });
  } catch (_error) {
    return json({ verified: false, message: 'تعذر التحقق من الرمز الآن.' }, 500);
  }
});
