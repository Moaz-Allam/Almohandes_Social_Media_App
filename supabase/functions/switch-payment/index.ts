// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info, x-customer-auth",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function envSecret(name: string): string {
  return (Deno.env.get(name) ?? "").trim().replace(/^['"]|['"]$/g, "");
}

function html(body: string, status = 200): Response {
  return new Response(body, {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/xhtml+xml; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function normalizeSwitchApiUrl(value: string): string {
  let url = value.trim().replace(/^['"]|['"]$/g, "") ||
    "https://test.oppwa.com/v1";
  if (url.includes("gate2play.test.ctpe.info")) {
    url = "https://test.oppwa.com/v1";
  }
  return url.replace(/\/$/, "");
}

function publicFunctionUrl(req: Request): string {
  const configuredUrl = envSecret("SWITCH_PAYMENT_RETURN_URL");
  if (configuredUrl) {
    return configuredUrl.replace(/[?#].*$/, "").replace(/\/$/, "");
  }

  const supabaseUrl = envSecret("SUPABASE_URL");
  if (supabaseUrl) {
    return `${supabaseUrl.replace(/\/$/, "")}/functions/v1/switch-payment`;
  }

  const url = new URL(req.url);
  const host = req.headers.get("x-forwarded-host") || url.host;
  const protocol = req.headers.get("x-forwarded-proto") || "https";
  return `${protocol}://${host}/functions/v1/switch-payment`;
}

function paymentResultUrl(req: Request, checkoutId: string): string {
  return `${publicFunctionUrl(req)}?action=payment-result&checkoutId=${
    encodeURIComponent(checkoutId)
  }`;
}

function serviceClient() {
  const supabaseUrl = envSecret("SUPABASE_URL");
  const serviceKey = envSecret("SERVICE_ROLE_KEY") ||
    envSecret("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return null;
  }
  return createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });
}

async function paymentGatewayBaseUrl(adminClient: any): Promise<string> {
  let adminUrl = "";
  if (adminClient) {
    const { data } = await adminClient
      .from("admin_settings")
      .select("key, value_json")
      .eq("key", "switch_api_url")
      .maybeSingle();
    if (data?.value_json != null) {
      adminUrl = typeof data.value_json === "object"
        ? JSON.stringify(data.value_json)
        : String(data.value_json);
    }
  }
  return normalizeSwitchApiUrl(
    envSecret("SWITCH_API_URL") || adminUrl || "https://test.oppwa.com/v1",
  );
}

function paymentPage(req: Request, checkoutId: string, gatewayBaseUrl: string) {
  const resultUrl = paymentResultUrl(req, checkoutId);
  const scriptUrl =
    `${gatewayBaseUrl}/paymentWidgets.js?checkoutId=${encodeURIComponent(checkoutId)}`;
  const brands = escapeHtml(envSecret("SWITCH_PAYMENT_BRANDS") || "VISA MASTER");
  return html(`<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="ar" dir="rtl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>دفع Premium</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f5f7fb; color: #101828; }
    main { max-width: 560px; margin: 0 auto; padding: 24px 16px 36px; }
    h1 { font-size: 24px; margin: 0 0 8px; }
    p { color: #475467; line-height: 1.7; margin: 0 0 18px; }
    .panel { background: #fff; border: 1px solid #e4e7ec; border-radius: 8px; padding: 16px; }
  </style>
  <script>
    var wpwlOptions = { locale: "ar", style: "card" };
  </script>
  <script async="async" src="${escapeHtml(scriptUrl)}"></script>
</head>
<body>
  <main>
    <h1>دفع Premium</h1>
    <p>أدخل بيانات البطاقة لإكمال الاشتراك. بعد انتهاء الدفع ارجع للتطبيق واضغط تحقق من الدفع.</p>
    <section class="panel">
      <form action="${escapeHtml(resultUrl)}" class="paymentWidgets" data-brands="${brands}"></form>
    </section>
  </main>
</body>
</html>`);
}

function paymentResultPage(url: URL) {
  const checkoutId = escapeHtml(url.searchParams.get("checkoutId") ?? "");
  return html(`<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="ar" dir="rtl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>نتيجة الدفع</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f5f7fb; color: #101828; }
    main { max-width: 560px; margin: 0 auto; padding: 32px 16px; }
    .panel { background: #fff; border: 1px solid #e4e7ec; border-radius: 8px; padding: 18px; }
    h1 { font-size: 24px; margin: 0 0 8px; }
    p { color: #475467; line-height: 1.7; margin: 0; }
    code { direction: ltr; display: block; margin-top: 12px; word-break: break-all; }
  </style>
</head>
<body>
  <main>
    <section class="panel">
      <h1>تم استلام نتيجة الدفع</h1>
      <p>ارجع إلى التطبيق واضغط تحقق من الدفع لتفعيل Premium.</p>
      ${checkoutId ? `<code>${checkoutId}</code>` : ""}
    </section>
  </main>
</body>
</html>`);
}

function paymentGatewayMessage(data: any): string {
  const result = data?.result ?? data?.details?.result ?? data;
  const description = result?.description || data?.description || data?.message;
  const code = result?.code || data?.code;
  if (description && code) return `تعذر إنشاء طلب الدفع: ${description} (${code})`;
  if (description) return `تعذر إنشاء طلب الدفع: ${description}`;
  return "تعذر إنشاء طلب الدفع من بوابة الدفع.";
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method === "GET") {
    const url = new URL(req.url);
    if (url.searchParams.get("action") === "payment-result") {
      return paymentResultPage(url);
    }
    const checkoutId = url.searchParams.get("checkoutId")?.trim() ?? "";
    if (!checkoutId) {
      return html(
        "<!DOCTYPE html><html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"ar\" dir=\"rtl\"><head><meta charset=\"utf-8\" /><title>رابط الدفع غير صالح</title></head><body><p>رابط الدفع غير صالح.</p></body></html>",
        400,
      );
    }
    const gatewayBaseUrl = await paymentGatewayBaseUrl(serviceClient());
    return paymentPage(req, checkoutId, gatewayBaseUrl);
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    // ================= AUTH =================
    // Use x-customer-auth to bypass infrastructure-level JWT verification if it's failing
    const authHeader = req.headers.get("x-customer-auth") || req.headers.get("Authorization") || req.headers.get("authorization");
    
    console.log("AUTH HEADER RECEIVED:", authHeader ? "YES" : "NO");

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      console.error("Missing or invalid Authorization header");
      return json(
        { error: "Missing or invalid Authorization header", received: !!authHeader },
        401,
      );
    }

    const SUPABASE_URL = envSecret("SUPABASE_URL");
    const SUPABASE_ANON_KEY = envSecret("SUPABASE_ANON_KEY") || envSecret("SUPABASE_SERVICE_ROLE_KEY"); // Fallback to service role if anon is missing for some reason

    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      console.error("Missing Supabase environment variables");
      return json({ error: "Server configuration error" }, 500);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabase.auth.getUser();

    if (userError || !user) {
      console.error("JWT Verification failed:", userError?.message || "User not found");
      return json(
        { 
          error: "Invalid JWT", 
          details: userError?.message || "User not found"
        },
        401,
      );
    }

    console.log("Authenticated User ID:", user.id);

    // ================= ADMIN CLIENT =================
    const adminClient = createClient(
      envSecret("SUPABASE_URL"),
      envSecret("SERVICE_ROLE_KEY") || envSecret("SUPABASE_SERVICE_ROLE_KEY")
    );

    async function getAdminSettings(keys: string[]) {
      const { data } = await adminClient
        .from("admin_settings")
        .select("key, value_json")
        .in("key", keys);
      
      const settings: Record<string, string | null> = {};
      keys.forEach(k => settings[k] = null);
      
      data?.forEach(row => {
        settings[row.key] = typeof row.value_json === "object"
          ? JSON.stringify(row.value_json)
          : String(row.value_json);
      });
      
      return settings;
    }

    // ================= BODY =================
    const body = await req.json();
    const action = body.action;

    async function currentProfileId(): Promise<string> {
      const { data, error } = await adminClient
        .from("profiles")
        .select("id")
        .eq("user_id", user.id)
        .maybeSingle();

      if (error) {
        console.error("Profile lookup failed:", error);
        throw new Error("تعذر العثور على ملفك الشخصي");
      }
      if (!data?.id) {
        throw new Error("تعذر العثور على ملفك الشخصي");
      }
      return String(data.id);
    }

    async function activateSubscription(profileId: string) {
      const { error: rpcError } = await adminClient.rpc("activate_subscription_p", {
        p_profile_id: profileId,
      });

      if (rpcError) {
        console.error("RPC failed:", rpcError);
        throw new Error(rpcError.message);
      }
    }

    // ================= TEST PAYMENT =================
    if (action === "activate-test-subscription") {
      return json({ error: "Test payment is disabled in production." }, 403);
    }

    // ================= CREATE CHECKOUT =================
    if (action === "create-checkout") {
      if (!body.amount) {
        return json({ error: "amount required" }, 400);
      }
      const profileId = await currentProfileId();

      const adminSettings = await getAdminSettings(["switch_api_url", "switch_api_token", "switch_entity_id"]);
      const ADMIN_SWITCH_URL = adminSettings.switch_api_url;
      const ADMIN_SWITCH_TOKEN = adminSettings.switch_api_token;
      const ADMIN_SWITCH_ENTITY = adminSettings.switch_entity_id;

      const SWITCH_API_TOKEN = (envSecret("SWITCH_API_TOKEN") || ADMIN_SWITCH_TOKEN || "").trim().replace(/^['"]|['"]$/g, "");
      const SWITCH_ENTITY_ID = (envSecret("SWITCH_ENTITY_ID") || ADMIN_SWITCH_ENTITY || "").trim().replace(/^['"]|['"]$/g, "");
      let SWITCH_API_URL = normalizeSwitchApiUrl(envSecret("SWITCH_API_URL") || ADMIN_SWITCH_URL || "https://test.oppwa.com/v1");

      console.log("CREATING CHECKOUT WITH CONFIG:", {
        url: SWITCH_API_URL,
        hasToken: !!SWITCH_API_TOKEN,
        hasEntity: !!SWITCH_ENTITY_ID,
        source: envSecret("SWITCH_API_TOKEN") ? "ENV" : "ADMIN_SETTINGS"
      });

      if (!SWITCH_API_TOKEN || !SWITCH_ENTITY_ID) {
        return json(
          { error: "Switch configuration missing (Token or Entity ID)" },
          500,
        );
      }

      const normalizedUrl = SWITCH_API_URL;
      const endpoint = `${normalizedUrl}/checkouts`;

      console.log("Calling Switch Endpoint:", endpoint);

      const formData = new URLSearchParams();
      formData.append("entityId", SWITCH_ENTITY_ID);
      formData.append("amount", Number(body.amount).toFixed(2));
      formData.append("currency", "IQD");
      formData.append("paymentType", "DB");
      formData.append("shopperResultUrl", paymentResultUrl(req, ""));
      
      // Add optional metadata if provided
      formData.append("merchantTransactionId", typeof body.orderId === "string" && body.orderId.trim()
        ? body.orderId.trim()
        : `premium_${profileId}_${Date.now()}`);
      if (body.customerEmail) formData.append("customer.email", body.customerEmail);
      if (body.customerName) {
        // HyperPay expects givenName and surname. We'll split or just use as givenName.
        const names = body.customerName.split(' ');
        formData.append("customer.givenName", names[0]);
        if (names.length > 1) formData.append("customer.surname", names.slice(1).join(' '));
      }
      if (body.customerPhone) formData.append("customer.mobile", body.customerPhone);

      const res = await fetch(endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${SWITCH_API_TOKEN}`,
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
        },
        body: formData.toString(),
      });

      console.log("Gateway Response Status:", res.status);
      const responseText = await res.text();
      
      let data: any = {};
      try {
        data = JSON.parse(responseText);
      } catch (e) {
        console.error("Failed to parse Switch Response (likely HTML error):", responseText.substring(0, 500));
        return json(
          { 
            error: "بوابة الدفع أعادت استجابة غير صالحة.", 
            status: res.status,
            details: responseText.substring(0, 200),
            endpoint: endpoint
          },
          502,
        );
      }

      if (!res.ok || !data.id) {
        console.error("SWITCH ERROR:", data);
        return json({ error: paymentGatewayMessage(data), details: data }, 400);
      }

      const checkoutId = String(data.id);
      return json(
        {
          success: true,
          checkoutId,
          profileId,
          paymentUrl: `${publicFunctionUrl(req)}?checkoutId=${encodeURIComponent(checkoutId)}`,
          paymentWidgetUrl: `${normalizedUrl}/paymentWidgets.js?checkoutId=${encodeURIComponent(checkoutId)}`,
          paymentResultUrl: paymentResultUrl(req, checkoutId),
        },
      );
    }

      // ================= VERIFY + ACTIVATE =================
    if (action === "verify-and-activate") {
      const { checkoutId, profileId } = body;

      if (!checkoutId || !profileId) {
        return json({ error: "Missing checkoutId or profileId" }, 400);
      }

      const ownedProfileId = await currentProfileId();
      if (String(profileId) !== ownedProfileId) {
        return json({ error: "لا يمكنك تفعيل اشتراك لمستخدم آخر." }, 403);
      }

      const adminSettings = await getAdminSettings(["switch_api_url", "switch_api_token", "switch_entity_id"]);
      const ADMIN_SWITCH_URL = adminSettings.switch_api_url;
      const ADMIN_SWITCH_TOKEN = adminSettings.switch_api_token;
      const ADMIN_SWITCH_ENTITY = adminSettings.switch_entity_id;

      const SWITCH_API_TOKEN = (envSecret("SWITCH_API_TOKEN") || ADMIN_SWITCH_TOKEN || "").trim().replace(/^['"]|['"]$/g, "");
      const SWITCH_ENTITY_ID = (envSecret("SWITCH_ENTITY_ID") || ADMIN_SWITCH_ENTITY || "").trim().replace(/^['"]|['"]$/g, "");
      let SWITCH_API_URL = normalizeSwitchApiUrl(envSecret("SWITCH_API_URL") || ADMIN_SWITCH_URL || "https://test.oppwa.com/v1");
      
      console.log("USING SWITCH CONFIG:", {
        url: SWITCH_API_URL,
        hasToken: !!SWITCH_API_TOKEN,
        hasEntity: !!SWITCH_ENTITY_ID,
        source: envSecret("SWITCH_API_TOKEN") ? "ENV" : "ADMIN_SETTINGS"
      });

      if (!SWITCH_API_TOKEN || !SWITCH_ENTITY_ID) {
        return json(
          { error: "Switch configuration missing (Token or Entity ID)" },
          500,
        );
      }

      const normalizedUrl = SWITCH_API_URL;

      const verifyRes = await fetch(
        `${normalizedUrl}/checkouts/${checkoutId}/payment?entityId=${SWITCH_ENTITY_ID}`,
        {
          headers: {
            Authorization: `Bearer ${SWITCH_API_TOKEN}`,
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
          },
        }
      );


      const payment = await verifyRes.json();
      console.log("PAYMENT VERIFICATION RESULT:", {
        code: payment.result?.code || "",
        description: payment.result?.description || ""
      });

      const isSuccess = /^(000\.000|000\.100\.1)/.test(
        payment.result?.code || ""
      );

      if (!isSuccess) {
        console.error("PAYMENT FAILED. Code:", payment.result?.code, "Message:", payment.result?.description);
        return json(
          {
            error: "لم يتم تأكيد الدفع بعد. أكمل الدفع ثم حاول التحقق مرة أخرى.",
            code: payment.result?.code,
            description: payment.result?.description,
            details: payment.result
          },
          400,
        );
      }


      const starts = new Date();
      const expires = new Date();
      expires.setFullYear(expires.getFullYear() + 1);

      console.log("Activating subscription via RPC for profile:", profileId);
      await activateSubscription(profileId);
      
      console.log("Successfully activated subscription via RPC");

      return json({ success: true });
    }

    return json({ error: "Invalid action" }, 400);

  } catch (err: any) {
    console.error("CRITICAL ERROR:", err);
    return json(
      { error: "Unexpected server error", details: err.message || String(err) },
      500,
    );
  }
});
