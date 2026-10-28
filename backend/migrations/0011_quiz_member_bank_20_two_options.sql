-- EclipseVerse quiz revision: exactly 20 active member-focused questions.
-- Every question has exactly two options (A/B).
-- Source of member facts: public.members.

DELETE FROM public.quiz_questions;

INSERT INTO public.quiz_questions
  (question_text, options, correct_option, explanation, difficulty, points, is_active)
VALUES
  ('Siapa leader sekaligus main vocalist Eclipse?', '{"A":"Solen","B":"Lunar"}'::jsonb, 'A', 'Solen tercatat sebagai Leader, Main Vocalist di data members.', 'easy', 10, true),
  ('Siapa yang tercatat sebagai lead vocalist Eclipse?', '{"A":"Astra","B":"Lunar"}'::jsonb, 'B', 'Lunar tercatat sebagai Lead Vocalist.', 'easy', 10, true),
  ('Siapa anggota yang pernah menjadi penyiar radio kampus?', '{"A":"Astra","B":"Mira"}'::jsonb, 'A', 'Fun fact Astra adalah pernah menjadi penyiar radio kampus.', 'normal', 15, true),
  ('Siapa main dancer Eclipse?', '{"A":"Orion","B":"Vega"}'::jsonb, 'A', 'Orion tercatat sebagai Main Dancer.', 'easy', 10, true),
  ('Siapa lead dancer Eclipse?', '{"A":"Nova","B":"Vega"}'::jsonb, 'B', 'Vega tercatat sebagai Lead Dancer.', 'easy', 10, true),
  ('Siapa anggota yang bisa menari sambil memainkan yo-yo?', '{"A":"Nova","B":"Lyra"}'::jsonb, 'A', 'Fun fact Nova adalah bisa menari sambil memainkan yo-yo.', 'normal', 15, true),
  ('Siapa main rapper Eclipse?', '{"A":"Zephyr","B":"Atlas"}'::jsonb, 'A', 'Zephyr tercatat sebagai Main Rapper.', 'easy', 10, true),
  ('Siapa lead rapper Eclipse?', '{"A":"Atlas","B":"Lyra"}'::jsonb, 'A', 'Atlas tercatat sebagai Lead Rapper.', 'easy', 10, true),
  ('Siapa yang pernah menjadi juara lomba debat sekolah?', '{"A":"Lyra","B":"Cassio"}'::jsonb, 'A', 'Fun fact Lyra adalah pernah menjadi juara lomba debat sekolah.', 'normal', 15, true),
  ('Siapa yang tercatat sebagai visual Eclipse?', '{"A":"Cassio","B":"Rigel"}'::jsonb, 'A', 'Cassio tercatat sebagai Visual.', 'easy', 10, true),
  ('Siapa yang pernah menjadi model majalah sekolah?', '{"A":"Cassio","B":"Astra"}'::jsonb, 'A', 'Fun fact Cassio adalah pernah menjadi model majalah sekolah.', 'normal', 15, true),
  ('Siapa producer internal Eclipse?', '{"A":"Rigel","B":"Altair"}'::jsonb, 'A', 'Rigel tercatat sebagai Producer.', 'easy', 10, true),
  ('Siapa yang membuat 10 beat dalam satu malam?', '{"A":"Rigel","B":"Zephyr"}'::jsonb, 'A', 'Fun fact Rigel adalah membuat 10 beat dalam satu malam.', 'hard', 20, true),
  ('Siapa guitarist Eclipse?', '{"A":"Altair","B":"Orion"}'::jsonb, 'A', 'Altair tercatat sebagai Guitarist.', 'easy', 10, true),
  ('Siapa yang bermain gitar sejak usia 7 tahun?', '{"A":"Altair","B":"Solen"}'::jsonb, 'A', 'Fun fact Altair adalah bermain gitar sejak usia 7 tahun.', 'normal', 15, true),
  ('Siapa maknae Eclipse?', '{"A":"Mira","B":"Cassio"}'::jsonb, 'A', 'Mira tercatat sebagai Maknae.', 'easy', 10, true),
  ('Siapa anggota termuda yang hobi merakit puzzle 1000 keping?', '{"A":"Mira","B":"Nova"}'::jsonb, 'A', 'Fun fact Mira adalah anggota termuda yang hobi merakit puzzle 1000 keping.', 'normal', 15, true),
  ('Siapa yang hafal 40 lagu tema film animasi?', '{"A":"Lunar","B":"Solen"}'::jsonb, 'A', 'Fun fact Lunar adalah hafal 40 lagu tema film animasi.', 'hard', 20, true),
  ('Siapa yang menulis lirik rap dalam tiga bahasa?', '{"A":"Zephyr","B":"Atlas"}'::jsonb, 'A', 'Fun fact Zephyr adalah menulis lirik rap dalam tiga bahasa.', 'hard', 20, true),
  ('Siapa yang merupakan kolektor sepatu edisi terbatas?', '{"A":"Atlas","B":"Lyra"}'::jsonb, 'A', 'Fun fact Atlas adalah kolektor sepatu edisi terbatas.', 'normal', 15, true);

-- Pastikan bank benar-benar hanya berisi soal dua opsi dan aktif.
UPDATE public.quiz_questions
SET options = jsonb_build_object(
  'A', options -> 'A',
  'B', options -> 'B'
)
WHERE jsonb_typeof(options) = 'object';

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
