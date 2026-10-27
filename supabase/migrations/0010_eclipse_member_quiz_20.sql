-- EclipseVerse revision batch 1
-- Rebuild the quiz bank as exactly 20 Eclipse-member questions.
-- Every question has exactly two options so the game UI stays simple.
-- Run after the existing quiz migrations.

TRUNCATE TABLE public.quiz_questions RESTART IDENTITY;

INSERT INTO public.quiz_questions
  (question_text, options, correct_option, explanation, difficulty, points, is_active)
VALUES
  ('Siapa leader sekaligus main vocalist Eclipse?', '{"A":"Solen","B":"Lunar"}', 'A', 'Solen adalah leader dan main vocalist Eclipse.', 'easy', 10, true),
  ('Siapa yang berposisi sebagai lead vocalist?', '{"A":"Astra","B":"Lunar"}', 'B', 'Lunar adalah lead vocalist Eclipse.', 'easy', 10, true),
  ('Siapa yang pernah menjadi penyiar radio kampus?', '{"A":"Astra","B":"Mira"}', 'A', 'Astra pernah menjadi penyiar radio kampus.', 'easy', 10, true),
  ('Siapa main dancer Eclipse?', '{"A":"Orion","B":"Vega"}', 'A', 'Orion adalah main dancer Eclipse.', 'easy', 10, true),
  ('Siapa koreografer pertama lagu Penumbra?', '{"A":"Vega","B":"Nova"}', 'A', 'Vega adalah koreografer pertama lagu Penumbra.', 'normal', 15, true),
  ('Siapa yang bisa menari sambil memainkan yo-yo?', '{"A":"Nova","B":"Lyra"}', 'A', 'Nova memiliki kemampuan menari sambil memainkan yo-yo.', 'normal', 15, true),
  ('Siapa main rapper Eclipse?', '{"A":"Atlas","B":"Zephyr"}', 'B', 'Zephyr adalah main rapper Eclipse.', 'easy', 10, true),
  ('Siapa lead rapper Eclipse?', '{"A":"Atlas","B":"Lyra"}', 'A', 'Atlas adalah lead rapper Eclipse.', 'easy', 10, true),
  ('Siapa yang pernah menjadi juara lomba debat sekolah?', '{"A":"Lyra","B":"Cassio"}', 'A', 'Lyra pernah menjadi juara lomba debat sekolah.', 'normal', 15, true),
  ('Siapa yang pernah menjadi model majalah sekolah?', '{"A":"Cassio","B":"Rigel"}', 'A', 'Cassio pernah menjadi model majalah sekolah.', 'normal', 15, true),
  ('Siapa producer internal Eclipse?', '{"A":"Rigel","B":"Altair"}', 'A', 'Rigel berperan sebagai producer internal Eclipse.', 'easy', 10, true),
  ('Siapa guitarist Eclipse?', '{"A":"Altair","B":"Zephyr"}', 'A', 'Altair adalah guitarist Eclipse.', 'easy', 10, true),
  ('Siapa maknae Eclipse?', '{"A":"Mira","B":"Astra"}', 'A', 'Mira adalah anggota termuda atau maknae Eclipse.', 'easy', 10, true),
  ('Siapa yang hafal 40 lagu tema film animasi?', '{"A":"Lunar","B":"Solen"}', 'A', 'Lunar hafal 40 lagu tema film animasi.', 'normal', 15, true),
  ('Siapa yang menulis lagu debut Eclipse di kamar kos?', '{"A":"Solen","B":"Orion"}', 'A', 'Solen menulis lagu debut Eclipse di kamar kos.', 'normal', 15, true),
  ('Siapa yang menjadi kolektor sepatu edisi terbatas?', '{"A":"Atlas","B":"Nova"}', 'A', 'Atlas adalah kolektor sepatu edisi terbatas.', 'normal', 15, true),
  ('Siapa yang menulis lirik rap dalam tiga bahasa?', '{"A":"Zephyr","B":"Lyra"}', 'A', 'Zephyr menulis lirik rap dalam tiga bahasa.', 'normal', 15, true),
  ('Siapa yang membuat 10 beat dalam satu malam?', '{"A":"Rigel","B":"Altair"}', 'A', 'Rigel pernah membuat 10 beat dalam satu malam.', 'normal', 15, true),
  ('Siapa yang bermain gitar sejak usia 7 tahun?', '{"A":"Altair","B":"Cassio"}', 'A', 'Altair bermain gitar sejak usia 7 tahun.', 'normal', 15, true),
  ('Siapa anggota termuda yang hobi merakit puzzle 1000 keping?', '{"A":"Mira","B":"Lunar"}', 'A', 'Mira adalah maknae yang hobi merakit puzzle 1000 keping.', 'normal', 15, true);

-- Keep the server-side contract aligned with the Flutter game.
ALTER TABLE public.game_scores
  DROP CONSTRAINT IF EXISTS game_scores_correct_count_check;
ALTER TABLE public.game_scores
  ADD CONSTRAINT game_scores_correct_count_check
  CHECK (correct_count BETWEEN 0 AND 10);

ALTER TABLE public.game_scores
  DROP CONSTRAINT IF EXISTS game_scores_question_count_check;
ALTER TABLE public.game_scores
  ADD CONSTRAINT game_scores_question_count_check
  CHECK (question_count = 10);
