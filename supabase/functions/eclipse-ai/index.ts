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
  const prompt = [
    "Kamu adalah Eclipse AI, asisten resmi di aplikasi fiktif EclipseVerse.",
    "Jawab hanya dalam konteks aplikasi: event, katalog merchandise, membership, mini-game, poin/redeem PC, konversi waktu/mata uang, dan penggunaan aplikasi.",
    "Jika pertanyaan di luar konteks aplikasi, jelaskan bahwa kamu hanya dapat membantu topik EclipseVerse.",
    "Jangan mengarang status pesanan, saldo, profil, harga, atau data akun yang tidak disertakan dalam konteks.",
    "Jawab dalam bahasa Indonesia dengan ringkas dan ramah.",
    "Pertanyaan pengguna: " + message.trim(),
  ].join("\n");
  const response = await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + apiKey, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }], generationConfig: { temperature: 0.4, maxOutputTokens: 600 } }),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) return Response.json({ error: "Layanan AI gagal merespons" }, { status: 502 });
  const reply = data?.candidates?.[0]?.content?.parts?.map((part: {text?: string}) => part.text ?? "").join("").trim();
  if (!reply) return Response.json({ error: "Jawaban AI kosong" }, { status: 502 });
  return Response.json({ reply });
});
