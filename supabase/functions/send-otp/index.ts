import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type OtpPayload = {
  phone_local10: string;
  code: string;
  expires_at: string;
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

function toInternational(phoneKey: string): string {
  if (/^07[3-9]\d{8}$/.test(phoneKey)) {
    return `+964${phoneKey.slice(1)}`;
  }
  if (/^01[0125]\d{8}$/.test(phoneKey)) {
    return `+20${phoneKey.slice(1)}`;
  }
  return phoneKey;
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
    return json({ sent: false, message: 'Method not allowed.' }, 405);
  }

  try {
    const { phone } = await request.json();
    if (typeof phone !== 'string' || phone.trim().length === 0) {
      return json({ sent: false, message: 'رقم الهاتف غير صحيح.' }, 400);
    }

    const accountSid = Deno.env.get('TWILIO_ACCOUNT_SID');
    const authToken = Deno.env.get('TWILIO_AUTH_TOKEN');
    const verifyServiceSid = Deno.env.get('TWILIO_VERIFY_SERVICE_SID');
    const normalizedPhone = normalizeSupportedPhone(phone);

    if (!normalizedPhone) {
      return json({ sent: false, message: 'رقم الهاتف غير صحيح.' }, 400);
    }

    if (accountSid && authToken && verifyServiceSid) {
      const params = new URLSearchParams();
      params.set('To', normalizedPhone);
      params.set('Channel', 'sms');
      params.set('Locale', 'ar');

      const verifyResponse = await fetch(
        `https://verify.twilio.com/v2/Services/${verifyServiceSid}/Verifications`,
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
        return json(
          { sent: false, message: 'تعذر إرسال رمز التحقق الآن.' },
          502,
        );
      }

      return json({ sent: true });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !serviceRoleKey) {
      return json(
        { sent: false, message: 'خدمة التحقق غير مهيأة الآن.' },
        500,
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const { data, error } = await supabase.rpc('create_signup_otp', {
      p_phone: phone,
    });

    if (error) {
      const message = error.message?.includes('otp_rate_limited')
        ? 'تم طلب رموز كثيرة. حاول مرة أخرى بعد قليل.'
        : 'تعذر إنشاء رمز التحقق الآن.';
      return json({ sent: false, message }, 400);
    }

    const otp = data as OtpPayload;
    const to = toInternational(otp.phone_local10);
    const messagingServiceSid = Deno.env.get('TWILIO_MESSAGING_SERVICE_SID');
    const fromPhone = Deno.env.get('TWILIO_FROM_PHONE');
    const allowDebugCode = Deno.env.get('OTP_DEBUG_DELIVERY') === 'true';

    if (!accountSid || !authToken || (!messagingServiceSid && !fromPhone)) {
      if (allowDebugCode) {
        return json({
          sent: true,
          expiresAt: otp.expires_at,
          debugCode: otp.code,
        });
      }
      return json(
        {
          sent: false,
          message: 'بوابة الرسائل غير مهيأة. أضف إعدادات Twilio في Supabase.',
        },
        503,
      );
    }

    const params = new URLSearchParams();
    params.set('To', to);
    params.set(
      'Body',
      `رمز التحقق الخاص بتطبيق Engineer هو ${otp.code}. صالح لمدة 10 دقائق.`,
    );
    if (messagingServiceSid) {
      params.set('MessagingServiceSid', messagingServiceSid);
    } else if (fromPhone) {
      params.set('From', fromPhone);
    }

    const twilioResponse = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      },
    );

    if (!twilioResponse.ok) {
      return json(
        { sent: false, message: 'تعذر إرسال رمز التحقق الآن.' },
        502,
      );
    }

    return json({ sent: true, expiresAt: otp.expires_at });
  } catch (_error) {
    return json({ sent: false, message: 'تعذر إرسال رمز التحقق الآن.' }, 500);
  }
});
