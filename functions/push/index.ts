// PitLane push notification sender — deployed as Supabase edge function "push" (verify_jwt: on).
// Any logged-in user can notify another user (same trust level as DMs). Subscriptions live in
// app_data rows id = "push:<uid>:<endpointHash>"; dead subscriptions (404/410) are pruned.
import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
webpush.setVapidDetails(
  Deno.env.get("VAPID_SUBJECT")!,
  Deno.env.get("VAPID_PUBLIC_KEY")!,
  Deno.env.get("VAPID_PRIVATE_KEY")!,
);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { to, title, body, url } = await req.json();
    if (!to || !title || !/^[0-9a-f-]{36}$/i.test(String(to))) {
      return new Response(JSON.stringify({ error: "bad request" }), { status: 400, headers: cors });
    }
    const { data: rows, error } = await admin
      .from("app_data")
      .select("id,data")
      .like("id", `push:${to}:%`);
    if (error) throw error;

    let sent = 0;
    for (const r of rows ?? []) {
      const sub = r.data?.sub;
      if (!sub?.endpoint) continue;
      try {
        await webpush.sendNotification(
          sub,
          JSON.stringify({ title: String(title).slice(0, 80), body: String(body ?? "").slice(0, 160), url: url || "https://robert30z.github.io/PitLane/" }),
        );
        sent++;
      } catch (e) {
        const sc = (e as { statusCode?: number }).statusCode;
        if (sc === 404 || sc === 410) await admin.from("app_data").delete().eq("id", r.id);
      }
    }
    return new Response(JSON.stringify({ sent }), { headers: { ...cors, "content-type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: cors });
  }
});
