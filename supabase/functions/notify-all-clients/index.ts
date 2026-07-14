import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = "dreamventz2026";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

const CATEGORY_NAMES: Record<number, string> = {
  1: "Photography",
  2: "Mehndi Artist",
  3: "Make-Up Artist",
  4: "Caterers",
  5: "DJ & Bands",
  6: "Decoraters",   // ✅ typo matches DB — was "Decorators"
  7: "Pandits",
  8: "Invites & Gifts",
};

function base64url(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(): Promise<string> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not set");
  const sa = JSON.parse(raw);

  const header = base64url(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" }))
  );
  const now = Math.floor(Date.now() / 1000);
  const payload = base64url(
    new TextEncoder().encode(JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }))
  );

  const signingInput = `${header}.${payload}`;
  const pemBody = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\n/g, "");

  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8", keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false, ["sign"]
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", cryptoKey,
    new TextEncoder().encode(signingInput)
  );
  const jwt = `${signingInput}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) throw new Error(`Failed to get access token: ${await res.text()}`);
  return (await res.json()).access_token;
}

async function sendFcmNotification(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: data ?? {},
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channel_id: "new_services_channel",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
          },
        },
      }),
    }
  );
  if (!res.ok) {
    console.error(`FCM send failed: ${await res.text()}`);
    return false;
  }
  return true;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { vendor_id, studio_name, category_id } = await req.json();

    if (!vendor_id || !studio_name || !category_id) {
      return new Response(
        JSON.stringify({ success: false, error: "vendor_id, studio_name and category_id are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const categoryName = CATEGORY_NAMES[category_id] ?? "Event Services";
    const accessToken = await getAccessToken();

    // ─── FEATURE 1: Notify clients who wishlisted this vendor ────────────────

    const { data: vendorCards } = await supabase
      .from("vendor_cards")
      .select("id")
      .eq("vendor_id", vendor_id);

    const vendorCardIds = (vendorCards ?? []).map((c: { id: string }) => c.id);
    let feature1Sent = 0;

    if (vendorCardIds.length > 0) {
      const { data: wishlistRows } = await supabase
        .from("wishlist")
        .select("user_id")
        .in("vendor_card_id", vendorCardIds);

      const userIds = [...new Set(
        (wishlistRows ?? []).map((w: { user_id: string }) => w.user_id)
      )];

      if (userIds.length > 0) {
        const { data: profiles } = await supabase
          .from("profiles")
          .select("fcm_token")
          .in("id", userIds)
          .not("fcm_token", "is", null);

        const tokens = (profiles ?? [])
          .map((p: { fcm_token: string }) => p.fcm_token)
          .filter((t: string) => t && t.trim() !== "");

        const title = `✨ ${studio_name} just added something new!`;
        const body = `Fresh ${categoryName} services are live — tap to see what's new 🎯`;

        const results = await Promise.all(
          tokens.map((token: string) =>
            sendFcmNotification(accessToken, token, title, body, {
              type: "favourite_vendor_new_product",
              vendor_id: vendor_id,
              category_id: category_id.toString(),  // ✅ client uses this to filter
              category_name: categoryName,            // ✅ client uses this as page title
            })
          )
        );

        feature1Sent = results.filter(Boolean).length;
        console.log(`✅ Feature 1 — sent: ${feature1Sent}`);
      }
    }

// ─── FEATURE 2: Every 10 products → notify ALL clients ───────────────────

const { data: counterRow } = await supabase
  .from("notification_counters")
  .select("count")
  .eq("id", "product_publish_count")
  .single();

const currentCount = (counterRow?.count ?? 0) + 1;

// ✅ upsert instead of update — creates row if missing, updates if exists
await supabase
  .from("notification_counters")
  .upsert({
    id: "product_publish_count",
    count: currentCount,
    last_notified_at: new Date().toISOString(),
  });

let feature2Sent = 0;

if (currentCount % 10 === 0) {
  const { data: allProfiles } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("role", "user")
    .not("fcm_token", "is", null);

  const allTokens = (allProfiles ?? [])
    .map((p: { fcm_token: string }) => p.fcm_token)
    .filter((t: string) => t && t.trim() !== "");

  // ✅ Amazon/Flipkart style — urgency + discovery
      const bulkTitle = "🛍️ New services just dropped on DreamVentz!";
      const bulkBody = `${currentCount}+ vendors are ready for your next event — Photography, Decor & more. Don't miss out!`;

      const bulkResults = await Promise.all(
        allTokens.map((token: string) =>
          sendFcmNotification(accessToken, token, bulkTitle, bulkBody, {
            type: "bulk_new_services",
            count: currentCount.toString(),
          })
        )
      );

      feature2Sent = bulkResults.filter(Boolean).length;
      console.log(`✅ Feature 2 — bulk sent: ${feature2Sent} (count: ${currentCount})`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        feature1_sent: feature1Sent,
        feature2_sent: feature2Sent,
        total_product_count: currentCount,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("notify-all-clients error:", err);
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});