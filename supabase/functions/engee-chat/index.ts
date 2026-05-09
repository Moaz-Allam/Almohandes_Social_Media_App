// @ts-nocheck
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info, x-customer-auth",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
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

function truncate(value: string, max: number): string {
  return value.length <= max ? value : `${value.slice(0, max - 1)}…`;
}

const systemPrompt = `أنتِ "المهندسة إنجي"، مساعدة هندسية ذكية داخل تطبيق المهندس.

القواعد:
- أجيبي بالعربية الواضحة إلا إذا كتب المستخدم بالإنجليزية.
- قدمي إرشاداً هندسياً عملياً ومهنياً، مع التنبيه عند الحاجة لمراجعة مهندس مرخص أو جهة قانونية.
- لا تخترعي قوانين أو أكواد بناء محددة. إذا كان الحكم يعتمد على بلد أو كود، اسألي عن الموقع أو اذكري أن الإجابة عامة.
- لا تقدمي أرقام تصميم نهائية أو حلول سلامة إنشائية حاسمة بدون بيانات كافية.
- كوني مختصرة، منظمة، ومباشرة.`;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ success: false, message: "Method not allowed." }, 405);
  }

  try {
    const authHeader =
      request.headers.get("x-customer-auth") ??
      request.headers.get("authorization") ??
      request.headers.get("Authorization") ??
      "";
    if (!authHeader.startsWith("Bearer ")) {
      return json(
        { success: false, message: "انتهت جلسة الدخول. سجل الدخول مرة أخرى." },
        401,
      );
    }

    const supabaseUrl = envSecret("SUPABASE_URL");
    const anonKey = envSecret("SUPABASE_ANON_KEY") ||
      envSecret("SUPABASE_PUBLISHABLE_KEY");
    const serviceRoleKey = envSecret("SUPABASE_SERVICE_ROLE_KEY") ||
      envSecret("SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return json(
        { success: false, message: "خدمة المهندسة إنجي غير مهيأة الآن." },
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
        { success: false, message: "انتهت جلسة الدخول. سجل الدخول مرة أخرى." },
        401,
      );
    }

    const body = await request.json().catch(() => ({}));
    const { conversationId } = body;
    const userMessage = extractMessage(body);
    if (!userMessage) {
      return json({ success: false, message: "اكتب رسالتك أولاً." }, 400);
    }
    if (userMessage.length > 2000) {
      return json(
        { success: false, message: "اختصر الرسالة إلى أقل من 2000 حرف." },
        400,
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("id, full_name, role, bio, subscription_status, subscription_expires_at, has_pro_badge")
      .eq("user_id", userData.user.id)
      .maybeSingle();
    if (profileError || !profile) {
      return json(
        { success: false, message: "تعذر العثور على ملفك الشخصي." },
        404,
      );
    }

    const { data: subscription, error: subscriptionError } = await admin
      .from("subscriptions")
      .select("status, expires_at")
      .eq("profile_id", profile.id)
      .maybeSingle();
    if (subscriptionError) {
      console.error("Subscription lookup failed", subscriptionError);
    }
    const subscriptionPremium =
      subscription?.status === "active" &&
      (!subscription.expires_at ||
        new Date(subscription.expires_at).getTime() > Date.now());
    const profilePremium =
      (profile.subscription_status === "active" ||
        profile.has_pro_badge === true) &&
      (!profile.subscription_expires_at ||
        new Date(profile.subscription_expires_at).getTime() > Date.now());
    if (!subscriptionPremium && !profilePremium) {
      return json(
        { success: false, message: "هذه الميزة متاحة لمشتركي Premium فقط." },
        403,
      );
    }

    let conversation = null;
    if (typeof conversationId === "string" && conversationId.trim()) {
      const { data } = await admin
        .from("ai_conversations")
        .select("id")
        .eq("id", conversationId.trim())
        .eq("profile_id", profile.id)
        .maybeSingle();
      conversation = data;
    }
    if (!conversation) {
      const { data } = await admin
        .from("ai_conversations")
        .select("id")
        .eq("profile_id", profile.id)
        .order("updated_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      conversation = data;
    }
    if (!conversation) {
      const title = truncate(userMessage, 42);
      const { data, error } = await admin
        .from("ai_conversations")
        .insert({ profile_id: profile.id, title })
        .select("id")
        .single();
      if (error) throw error;
      conversation = data;
    }

    const { data: savedUserMessage, error: userInsertError } = await admin
      .from("ai_messages")
      .insert({
        profile_id: profile.id,
        conversation_id: conversation.id,
        role: "user",
        content: userMessage,
      })
      .select("id, role, content, created_at, conversation_id")
      .single();
    if (userInsertError) throw userInsertError;

    const { data: historyRows } = await admin
      .from("ai_messages")
      .select("role, content")
      .eq("conversation_id", conversation.id)
      .order("created_at", { ascending: false })
      .limit(14);
    const history = (historyRows ?? []).reverse().map((row) => ({
      role: row.role === "assistant" ? "assistant" : "user",
      content: String(row.content ?? ""),
    }));

    const aiReply = await completeWithOpenRouter([
      { role: "system", content: systemPrompt },
      ...history,
    ]);

    const { data: savedAssistantMessage, error: assistantInsertError } =
      await admin
        .from("ai_messages")
        .insert({
          profile_id: profile.id,
          conversation_id: conversation.id,
          role: "assistant",
          content: aiReply,
        })
        .select("id, role, content, created_at, conversation_id")
        .single();
    if (assistantInsertError) throw assistantInsertError;

    await admin
      .from("ai_conversations")
      .update({ updated_at: new Date().toISOString() })
      .eq("id", conversation.id);

    return json({
      success: true,
      conversationId: conversation.id,
      userMessage: savedUserMessage,
      assistantMessage: savedAssistantMessage,
    });
  } catch (error) {
    console.error("engineer-chat failed", error);
    return json(
      { success: false, message: "تعذر إرسال الرسالة إلى إنجي الآن." },
      500,
    );
  }
});

async function completeWithOpenRouter(messages: Array<Record<string, string>>) {
  const apiKey = envSecret("OPENROUTER_API_KEY");
  const model = envSecret("ENGINEER_AI_MODEL") || "openrouter/free";
  if (!apiKey) {
    return "إنجي جاهزة داخل التطبيق، لكن مفتاح نموذج الذكاء الاصطناعي غير مضاف في إعدادات الخادم بعد. أضف OPENROUTER_API_KEY في Supabase لتفعيل الردود الذكية المجانية.";
  }

  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": envSecret("SITE_URL") || "https://engineer.app",
      "X-Title": "Engineer Engee Assistant",
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.35,
      max_tokens: 700,
    }),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    console.error("OpenRouter failed", response.status, data);
    return "تعذر الوصول إلى نموذج الذكاء الاصطناعي الآن. حاول مرة أخرى بعد قليل.";
  }
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content === "string" && content.trim()) {
    return content.trim();
  }
  return "لم أستطع تكوين رد واضح الآن. أعد صياغة السؤال بتفاصيل أكثر.";
}

function extractMessage(body: any): string {
  const candidates = [
    body?.message,
    body?.content,
    body?.text,
    body?.prompt,
    body?.input,
    body?.query,
  ];
  for (const candidate of candidates) {
    if (typeof candidate === "string" && candidate.trim()) {
      return candidate.trim();
    }
  }
  if (Array.isArray(body?.messages)) {
    for (let i = body.messages.length - 1; i >= 0; i--) {
      const item = body.messages[i];
      if (item?.role === "user" && typeof item?.content === "string") {
        const content = item.content.trim();
        if (content) return content;
      }
    }
  }
  return "";
}
