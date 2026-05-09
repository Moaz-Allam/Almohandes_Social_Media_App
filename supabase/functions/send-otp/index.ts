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

async function createLocalOtp(normalizedPhone: string): Promise<
  | { ok: true; otp: OtpPayload }
  | { ok: false; message: string; status: number }
> {
  const supabaseUrl = envSecret('SUPABASE_URL');
  const serviceRoleKey = envSecret('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) {
    return {
      ok: false,
      status: 500,
      message: 'خدمة التحقق غير مهيأة الآن.',
    };
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data, error } = await supabase.rpc('create_signup_otp', {
    p_phone: normalizedPhone,
  });

  if (error) {
    return {
      ok: false,
      status: 400,
      message: error.message?.includes('otp_rate_limited')
        ? 'تم طلب رموز كثيرة. حاول مرة أخرى بعد قليل.'
        : 'تعذر إنشاء رمز التحقق الآن.',
    };
  }

  return { ok: true, otp: data as OtpPayload };
}

async function twilioErrorDetails(response: Response): Promise<{
  code?: string;
  message?: string;
  moreInfo?: string;
}> {
  const text = await response.text();
  try {
    const data = JSON.parse(text);
    return {
      code: data.code == null ? undefined : String(data.code),
      message: data.message == null ? undefined : String(data.message),
      moreInfo: data.more_info == null ? undefined : String(data.more_info),
    };
  } catch (_) {
    return { message: text.slice(0, 240) };
  }
}

function smsFailureMessage(
  status: number,
  details: { code?: string; message?: string },
): string {
  if (status === 401 || status === 403 || details.code === '20003') {
    return 'إعدادات بوابة الرسائل غير صحيحة. تحقق من إعدادات Twilio.';
  }
  if (details.code === '21211' || details.code === '60200') {
    return 'رقم الهاتف غير صحيح.';
  }
  if (details.code === '21608') {
    return 'حساب الرسائل التجريبي لا يرسل إلا للأرقام الموثقة في Twilio.';
  }
  if (details.code === '21408') {
    return 'إرسال الرسائل إلى هذه الدولة غير مفعل في Twilio.';
  }
  if (
    status === 429 ||
    details.code === '60203' ||
    details.code === '60212' ||
    details.code === '60220'
  ) {
    return 'تم طلب رموز كثيرة. حاول مرة أخرى بعد قليل.';
  }
  return 'تعذر إرسال رمز التحقق الآن من بوابة الرسائل.';
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

    const accountSid = envSecret('TWILIO_ACCOUNT_SID');
    const authToken = envSecret('TWILIO_AUTH_TOKEN');
    const verifyServiceSid = envSecret('TWILIO_VERIFY_SERVICE_SID');
    const normalizedPhone = normalizeSupportedPhone(phone);

    if (!normalizedPhone) {
      return json({ sent: false, message: 'رقم الهاتف غير صحيح.' }, 400);
    }

    if (isDevOtpMode()) {
      const localOtp = await createLocalOtp(normalizedPhone);
      if (!localOtp.ok) {
        return json(
          { sent: false, message: localOtp.message },
          localOtp.status,
        );
      }

      const otp = localOtp.otp;
      return json({
        sent: true,
        expiresAt: otp.expires_at,
        debugCode: otp.code,
        message: `تم إنشاء رمز الاختبار: ${otp.code}`,
      });
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
        const details = await twilioErrorDetails(verifyResponse);
        console.error('Twilio Verify send failed', {
          status: verifyResponse.status,
          code: details.code,
          message: details.message,
          moreInfo: details.moreInfo,
          countryPrefix: normalizedPhone.slice(0, 3),
        });
        if (
          (details.code === '20003' || verifyResponse.status === 401) &&
          (envEnabled('OTP_PROVIDER_FALLBACK_TO_DEBUG') ||
            envEnabled('OTP_DEBUG_DELIVERY'))
        ) {
          const localOtp = await createLocalOtp(normalizedPhone);
          if (!localOtp.ok) {
            return json(
              { sent: false, message: localOtp.message },
              localOtp.status,
            );
          }
          return json({
            sent: true,
            expiresAt: localOtp.otp.expires_at,
            debugCode: localOtp.otp.code,
            message: `تم إنشاء رمز التحقق: ${localOtp.otp.code}`,
          });
        }
        return json(
          {
            sent: false,
            message: smsFailureMessage(verifyResponse.status, details),
            providerCode: details.code,
          },
          502,
        );
      }

      return json({ sent: true });
    }

    const localOtp = await createLocalOtp(normalizedPhone);
    if (!localOtp.ok) {
      return json(
        { sent: false, message: localOtp.message },
        localOtp.status,
      );
    }

    const otp = localOtp.otp;
    const to = toInternational(otp.phone_local10);
    const messagingServiceSid = envSecret('TWILIO_MESSAGING_SERVICE_SID');
    const fromPhone = envSecret('TWILIO_FROM_PHONE');
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
      const details = await twilioErrorDetails(twilioResponse);
      console.error('Twilio SMS send failed', {
        status: twilioResponse.status,
        code: details.code,
        message: details.message,
        moreInfo: details.moreInfo,
        countryPrefix: to.slice(0, 3),
      });
      return json(
        {
          sent: false,
          message: smsFailureMessage(twilioResponse.status, details),
          providerCode: details.code,
        },
        502,
      );
    }

    return json({ sent: true, expiresAt: otp.expires_at });
  } catch (_error) {
    return json({ sent: false, message: 'تعذر إرسال رمز التحقق الآن.' }, 500);
  }
});
