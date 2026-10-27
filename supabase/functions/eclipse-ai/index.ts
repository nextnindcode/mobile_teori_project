import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return Response.json({ error: "Authentication required" }, { status: 401 });
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return Response.json({ error: "Authentication required" }, { status: 401 });

  const { message } = await req.json().catch(() => ({ message: "" }));
  if (typeof message !== "string" || !message.trim() || message.length > 2000) {
    return Response.json({ error: "Pesan kosong atau terlalu panjang" }, { status: 400 });
  }
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return Response.json({ error: "GEMINI_API_KEY belum dikonfigurasi" }, { status: 503 });

  // Use the authenticated user's session for RLS-protected application data.
  const [events, products, members, cards, plans, points, memberships] = await Promise.all([
    supabase.from("events").select("*")
      .neq("status", "draft").order("event_date").limit(40),
    supabase.from("products").select("*,categories(name)")
      .eq("is_published", true).limit(60),
    supabase.from("members").select("*")
      .order("sort_order").limit(30),
    supabase.from("cards").select("*,members(stage_name)")
      .eq("is_available", true).limit(40),
    supabase.from("membership_plans").select("name,description,price_points,quota_amount,benefits")
      .eq("is_active", true).limit(10),
    supabase.from("user_points").select("total_points").eq("user_id", user.id).maybeSingle(),
    supabase.from("user_memberships").select("status,starts_at,expires_at,redeem_quota,membership_plans(name)")
      .eq("user_id", user.id).order("expires_at", { ascending: false }).limit(3),
  ]);

  const contextData = {
    events: events.data ?? [],
    merchandise: products.data ?? [],
    members: members.data ?? [],
    photocards: cards.data ?? [],
    membershipPlans: plans.data ?? [],
    currentUser: {
      points: points.data?.total_points ?? 0,
      memberships: memberships.data ?? [],
    },
    dataNotes: [
      "Harga merchandise dalam IDR.",
      "Tanggal event berasal dari event_date database.",
      "Jangan menyimpulkan membership aktif hanya dari riwayat membership.",
      "Jangan mengaku mengetahui skor kuis pribadi, jawaban, riwayat percobaan kuis, atau koleksi photocard milik pengguna. Data tersebut tidak diberikan ke AI demi privasi.",
      "Untuk biodata anggota, gunakan tanggal lahir, hobi, posisi vokal/dance/rap, dan cerita lagu hanya jika kolom atau sumber data memang tersedia. Jangan mengarang detail yang tidak tersedia.",
      "Untuk jadwal event dan astronomi, gunakan tanggal dari database jika tersedia. Jangan membuat tanggal gerhana atau event sendiri.",
      "Untuk pertanyaan tentang album pertama, jumlah produk, stok, hoodie, payung, atau merchandise tertentu, periksa katalog aktual. Jika produk tidak ada atau stoknya nol, katakan dengan sopan bahwa produk belum tersedia dan rekomendasikan hanya produk lain yang benar-benar ada dalam katalog.",
      "Gunakan bahasa yang ramah pengguna dan hindari jargon backend/blockchain. Jangan mengatakan transaksi sudah dicatat di blockchain; jelaskan hasilnya dengan sederhana.",
      "Jika data tidak tersedia, jelaskan bahwa data belum tersedia.",
    ],
  };

  const prompt = [
    "Kamu adalah Eclipse AI, asisten resmi aplikasi fiktif EclipseVerse.",
    "Jawab dalam bahasa Indonesia yang ramah, spesifik, dan jelas menggunakan konteks database sebagai sumber utama.",
    "Bantu pengguna tentang jadwal event (tanggal, jam, venue, kota), katalog merchandise (nama, deskripsi, harga, stok), anggota Eclipse (posisi, tim, deskripsi, fun fact), photocard, membership, poin, redeem, dan fitur aplikasi.",
    "Jangan mengarang nama produk, harga, stok, tanggal event, informasi anggota, atau status akun.",
    "Bedakan status membership saat ini dengan riwayat. Jangan mengungkap data akun pengguna lain.",
    "Jika query gagal atau data kosong, nyatakan keterbatasannya secara jujur.",
    "Jika pertanyaan di luar konteks EclipseVerse, jelaskan batasan dengan singkat.",
    "KONTEKS DATABASE TERKINI:",
    JSON.stringify(contextData),
    "PERTANYAAN PENGGUNA:",
    message.trim(),
  ].join("\n");

  const response = await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + apiKey, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }], generationConfig: { temperature: 0.25, maxOutputTokens: 900 } }),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) return Response.json({ error: "Layanan AI gagal merespons" }, { status: 502 });
  const reply = data?.candidates?.[0]?.content?.parts?.map((part: {text?: string}) => part.text ?? "").join("").trim();
  if (!reply) return Response.json({ error: "Jawaban AI kosong" }, { status: 502 });
  return Response.json({ reply });
});
