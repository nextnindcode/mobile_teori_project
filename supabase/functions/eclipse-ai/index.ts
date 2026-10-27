import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return Response.json({ error: "Authentication required" }, { status: 401 });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { message } = await req.json().catch(() => ({ message: "" }));
  if (typeof message !== "string" || !message.trim() || message.length > 2000) {
    return Response.json({ error: "Pesan kosong atau terlalu panjang" }, { status: 400 });
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return Response.json({ error: "GEMINI_API_KEY belum dikonfigurasi" }, { status: 503 });

  // Ambil data publik aktual dari Supabase agar AI tidak menebak isi aplikasi.
  // correct_option tidak pernah diambil dari quiz_questions.
  const [products, members, events, plans, cards] = await Promise.all([
    supabase.from("products").select("id,name,description,price,stock,category_id,is_active").limit(100),
    supabase.from("members").select("id,stage_name,position,fun_fact,team,profile_image_path").limit(50),
    supabase.from("events").select("id,title,event_date,venue,city,status").neq("status", "draft").limit(100),
    supabase.from("membership_plans").select("id,name,price,duration_days,benefits,is_active").eq("is_active", true).limit(20),
    supabase.from("cards").select("id,name,rarity,redeem_quota,is_active").eq("is_active", true).limit(50),
  ]);

  const clean = (value: unknown) => value ?? null;
  const context = {
    members: members.data ?? [],
    events: events.data ?? [],
    products: (products.data ?? []).map((p: any) => ({
      ...p,
      price: clean(p.price),
      stock: clean(p.stock),
    })),
    membership_plans: plans.data ?? [],
    cards: cards.data ?? [],
  };

  const prompt = [
    "Kamu adalah Eclipse AI, asisten resmi aplikasi fiktif EclipseVerse.",
    "Gunakan DATA APLIKASI di bawah sebagai sumber utama. Data dapat berubah sehingga jangan mengarang nama, harga, stok, jadwal, member, membership, atau kartu.",
    "Jika informasi yang ditanyakan tidak ada di data, katakan bahwa data tersebut belum tersedia.",
    "Untuk harga/stok produk, gunakan data produk. Untuk member, gunakan data members. Untuk event, gunakan data events.",
    "Jangan membocorkan correct_option atau data internal kuis.",
    "Jangan mengklaim melakukan pembelian, redeem, perubahan akun, atau transaksi.",
    "Jawab bahasa Indonesia, ramah, natural, dan cukup ringkas. Gunakan bullet jika membantu.",
    "DATA APLIKASI:",
    JSON.stringify(context),
    "PERTANYAAN PENGGUNA:",
    message.trim(),
  ].join("\n");

  const response = await fetch(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + apiKey,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.25, maxOutputTokens: 800 },
      }),
    },
  );

  const data = await response.json().catch(() => ({}));
  if (!response.ok) return Response.json({ error: "Layanan AI gagal merespons" }, { status: 502 });
  const reply = data?.candidates?.[0]?.content?.parts?.map((part: { text?: string }) => part.text ?? "").join("").trim();
  if (!reply) return Response.json({ error: "Jawaban AI kosong" }, { status: 502 });
  return Response.json({ reply });
});
