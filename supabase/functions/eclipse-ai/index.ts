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

  // Ambil seluruh data aplikasi yang memang relevan untuk percakapan.
  // Query dibuat terpisah agar kegagalan relasi/tabel tertentu tidak membuat
  // seluruh context kosong.
  const [eventsRes, productsRes, membersRes, cardsRes, plansRes, pointsRes, membershipsRes] = await Promise.all([
    supabase.from("events").select("*").neq("status", "draft").order("event_date"),
    supabase.from("products").select("*").eq("is_published", true).order("id"),
    supabase.from("members").select("*").order("sort_order"),
    supabase.from("cards").select("*").eq("is_available", true).order("id"),
    supabase.from("membership_plans").select("*").eq("is_active", true).order("id"),
    supabase.from("user_points").select("total_points").eq("user_id", user.id).maybeSingle(),
    supabase.from("user_memberships").select("*").eq("user_id", user.id).order("expires_at", { ascending: false }),
  ]);

  const contextData = {
    events: eventsRes.error ? [] : (eventsRes.data ?? []),
    merchandise: productsRes.error ? [] : (productsRes.data ?? []),
    members: membersRes.error ? [] : (membersRes.data ?? []),
    photocards: cardsRes.error ? [] : (cardsRes.data ?? []),
    membershipPlans: plansRes.error ? [] : (plansRes.data ?? []),
    currentUser: {
      points: pointsRes.data?.total_points ?? 0,
      memberships: membershipsRes.error ? [] : (membershipsRes.data ?? []),
    },
    sourceStatus: {
      events: !eventsRes.error,
      merchandise: !productsRes.error,
      members: !membersRes.error,
      photocards: !cardsRes.error,
      membershipPlans: !plansRes.error,
      userPoints: !pointsRes.error,
      userMemberships: !membershipsRes.error,
    },
  };

  const prompt = [
    "Kamu adalah Eclipse AI, asisten resmi aplikasi fiktif EclipseVerse.",
    "Jawab dalam bahasa Indonesia yang ramah, spesifik, natural, dan tidak bertele-tele.",
    "DATABASE DI BAWAH ADALAH SUMBER UTAMA. Gunakan data yang tersedia, bukan tebakan atau pengetahuan umum.",
    "Kamu boleh menjawab pertanyaan tentang event, merchandise, anggota Eclipse, photocard, membership, poin, redeem, dan fitur aplikasi.",
    "Untuk pertanyaan produk: sebutkan nama, kategori, deskripsi, harga, stok, dan informasi lain hanya jika ada di database.",
    "Untuk pertanyaan anggota: gunakan data members secara langsung, termasuk stage_name, position, team, fun_fact, profile_image_path, dan kolom lain yang tersedia.",
    "Untuk pertanyaan event: gunakan data events secara langsung, termasuk title, event_date, venue, city, latitude, longitude, status, poster_path, dan kolom lain yang tersedia.",
    "Jangan mengarang nama, harga, stok, jadwal, venue, anggota, posisi, atau status.",
    "Jika data yang diminta tidak ada, katakan bahwa informasi tersebut belum tersedia di database EclipseVerse.",
    "Untuk status akun, hanya gunakan data currentUser yang diberikan. Jangan mengungkap data pengguna lain.",
    "Untuk skor kuis, jawaban kuis, riwayat percobaan, atau koleksi pribadi, jangan mengaku tahu karena data tersebut tidak diberikan ke model.",
    "Jika pertanyaan berada di luar konteks EclipseVerse, tolak dengan singkat dan arahkan kembali ke fitur/data EclipseVerse.",
    "Jangan membahas detail backend, SQL, token, RLS, atau API key kepada pengguna.",
    "Jika sourceStatus sebuah tabel false, anggap data tabel itu tidak tersedia untuk sesi ini dan jangan menebak isinya.",
    "KONTEKS DATABASE TERKINI:",
    JSON.stringify(contextData),
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
        generationConfig: { temperature: 0.2, maxOutputTokens: 1000 },
      }),
    },
  );

  const data = await response.json().catch(() => ({}));
  if (!response.ok) return Response.json({ error: "Layanan AI gagal merespons" }, { status: 502 });

  const reply = data?.candidates?.[0]?.content?.parts?.map((part: { text?: string }) => part.text ?? "").join("").trim();
  if (!reply) return Response.json({ error: "Jawaban AI kosong" }, { status: 502 });

  return Response.json({ reply });
});
