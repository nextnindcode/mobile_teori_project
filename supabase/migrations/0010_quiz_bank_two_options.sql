-- EclipseVerse quiz repair: activate a 20-question member bank with A/B options only.
-- Existing rows are retained for history; no destructive DELETE is used.
-- Apply this migration in Supabase SQL Editor or with Supabase CLI.

UPDATE public.quiz_questions SET is_active = false;

INSERT INTO public.quiz_questions
  (question_text, options, correct_option, explanation, difficulty, points, is_active)
SELECT v.question_text, v.options::jsonb, v.correct_option, v.explanation, v.difficulty, v.points, false
FROM (VALUES
  ('Siapa leader sekaligus main vocalist Eclipse?', '{"A":"Solen","B":"Lunar"}', 'A', 'Solen tercatat sebagai Leader, Main Vocalist di data members.', 'easy', 10),
  ('Siapa yang tercatat sebagai lead vocalist Eclipse?', '{"A":"Astra","B":"Lunar"}', 'B', 'Lunar tercatat sebagai Lead Vocalist.', 'easy', 10),
  ('Siapa anggota yang pernah menjadi penyiar radio kampus?', '{"A":"Astra","B":"Mira"}', 'A', 'Fun fact Astra adalah pernah menjadi penyiar radio kampus.', 'normal', 15),
  ('Siapa main dancer Eclipse?', '{"A":"Orion","B":"Vega"}', 'A', 'Orion tercatat sebagai Main Dancer.', 'easy', 10),
  ('Siapa lead dancer Eclipse?', '{"A":"Nova","B":"Vega"}', 'B', 'Vega tercatat sebagai Lead Dancer.', 'easy', 10),
  ('Siapa anggota yang bisa menari sambil memainkan yo-yo?', '{"A":"Nova","B":"Lyra"}', 'A', 'Fun fact Nova adalah bisa menari sambil memainkan yo-yo.', 'normal', 15),
  ('Siapa main rapper Eclipse?', '{"A":"Zephyr","B":"Atlas"}', 'A', 'Zephyr tercatat sebagai Main Rapper.', 'easy', 10),
  ('Siapa lead rapper Eclipse?', '{"A":"Atlas","B":"Lyra"}', 'A', 'Atlas tercatat sebagai Lead Rapper.', 'easy', 10),
  ('Siapa yang pernah menjadi juara lomba debat sekolah?', '{"A":"Lyra","B":"Cassio"}', 'A', 'Fun fact Lyra adalah pernah menjadi juara lomba debat sekolah.', 'normal', 15),
  ('Siapa yang tercatat sebagai visual Eclipse?', '{"A":"Cassio","B":"Rigel"}', 'A', 'Cassio tercatat sebagai Visual.', 'easy', 10),
  ('Siapa yang pernah menjadi model majalah sekolah?', '{"A":"Cassio","B":"Astra"}', 'A', 'Fun fact Cassio adalah pernah menjadi model majalah sekolah.', 'normal', 15),
  ('Siapa producer internal Eclipse?', '{"A":"Rigel","B":"Altair"}', 'A', 'Rigel tercatat sebagai Producer.', 'easy', 10),
  ('Siapa yang membuat 10 beat dalam satu malam?', '{"A":"Rigel","B":"Zephyr"}', 'A', 'Fun fact Rigel adalah membuat 10 beat dalam satu malam.', 'hard', 20),
  ('Siapa guitarist Eclipse?', '{"A":"Altair","B":"Orion"}', 'A', 'Altair tercatat sebagai Guitarist.', 'easy', 10),
  ('Siapa yang bermain gitar sejak usia 7 tahun?', '{"A":"Altair","B":"Solen"}', 'A', 'Fun fact Altair adalah bermain gitar sejak usia 7 tahun.', 'normal', 15),
  ('Siapa maknae Eclipse?', '{"A":"Mira","B":"Cassio"}', 'A', 'Mira tercatat sebagai Maknae.', 'easy', 10),
  ('Siapa anggota termuda yang hobi merakit puzzle 1000 keping?', '{"A":"Mira","B":"Nova"}', 'A', 'Fun fact Mira adalah anggota termuda yang hobi merakit puzzle 1000 keping.', 'normal', 15),
  ('Siapa yang hafal 40 lagu tema film animasi?', '{"A":"Lunar","B":"Solen"}', 'A', 'Fun fact Lunar adalah hafal 40 lagu tema film animasi.', 'hard', 20),
  ('Siapa yang menulis lirik rap dalam tiga bahasa?', '{"A":"Zephyr","B":"Atlas"}', 'A', 'Fun fact Zephyr adalah menulis lirik rap dalam tiga bahasa.', 'hard', 20),
  ('Siapa yang merupakan kolektor sepatu edisi terbatas?', '{"A":"Atlas","B":"Lyra"}', 'A', 'Fun fact Atlas adalah kolektor sepatu edisi terbatas.', 'normal', 15)
) AS v(question_text, options, correct_option, explanation, difficulty, points)
WHERE NOT EXISTS (
  SELECT 1 FROM public.quiz_questions q WHERE q.question_text = v.question_text
);

-- Re-enable only the 20 two-option questions above.
UPDATE public.quiz_questions
SET is_active = true,
    options = jsonb_build_object('A', options -> 'A', 'B', options -> 'B')
WHERE question_text IN (
  'Siapa leader sekaligus main vocalist Eclipse?',
  'Siapa yang tercatat sebagai lead vocalist Eclipse?',
  'Siapa anggota yang pernah menjadi penyiar radio kampus?',
  'Siapa main dancer Eclipse?',
  'Siapa lead dancer Eclipse?',
  'Siapa anggota yang bisa menari sambil memainkan yo-yo?',
  'Siapa main rapper Eclipse?',
  'Siapa lead rapper Eclipse?',
  'Siapa yang pernah menjadi juara lomba debat sekolah?',
  'Siapa yang tercatat sebagai visual Eclipse?',
  'Siapa yang pernah menjadi model majalah sekolah?',
  'Siapa producer internal Eclipse?',
  'Siapa yang membuat 10 beat dalam satu malam?',
  'Siapa guitarist Eclipse?',
  'Siapa yang bermain gitar sejak usia 7 tahun?',
  'Siapa maknae Eclipse?',
  'Siapa anggota termuda yang hobi merakit puzzle 1000 keping?',
  'Siapa yang hafal 40 lagu tema film animasi?',
  'Siapa yang menulis lirik rap dalam tiga bahasa?',
  'Siapa yang merupakan kolektor sepatu edisi terbatas?'
);

ALTER TABLE public.game_scores
  DROP CONSTRAINT IF EXISTS game_scores_correct_count_check;
ALTER TABLE public.game_scores
  ADD CONSTRAINT game_scores_correct_count_check CHECK (correct_count BETWEEN 0 AND question_count);

ALTER TABLE public.game_scores
  DROP CONSTRAINT IF EXISTS game_scores_question_count_check;
ALTER TABLE public.game_scores
  ADD CONSTRAINT game_scores_question_count_check CHECK (question_count BETWEEN 1 AND 20);

CREATE OR REPLACE FUNCTION public.submit_quiz_attempt(p_answers jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_item jsonb;
  v_question public.quiz_questions%rowtype;
  v_count integer := 0;
  v_correct integer := 0;
  v_points integer := 0;
  v_score_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF jsonb_typeof(p_answers) <> 'array' OR jsonb_array_length(p_answers) <> 10 THEN
    RAISE EXCEPTION 'Submit exactly 10 answers';
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_answers)
  LOOP
    IF NOT (v_item ? 'question_id') OR NOT (v_item ? 'answer')
       OR nullif(trim(v_item ->> 'answer'), '') IS NULL THEN
      RAISE EXCEPTION 'Each answer needs question_id and a non-empty answer';
    END IF;

    SELECT * INTO v_question
    FROM public.quiz_questions
    WHERE id = (v_item ->> 'question_id')::bigint AND is_active = true;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Question not found or inactive';
    END IF;

    v_count := v_count + 1;
    IF v_item ->> 'answer' = v_question.correct_option THEN
      v_correct := v_correct + 1;
      v_points := v_points + v_question.points;
    END IF;
  END LOOP;

  IF (SELECT count(DISTINCT (value ->> 'question_id')) FROM jsonb_array_elements(p_answers)) <> 10 THEN
    RAISE EXCEPTION 'Duplicate question IDs are not allowed';
  END IF;

  INSERT INTO public.game_scores(user_id, score, correct_count, question_count)
  VALUES (v_uid, v_points, v_correct, v_count)
  RETURNING id INTO v_score_id;

  INSERT INTO public.user_points(user_id, total_points, updated_at)
  VALUES (v_uid, v_points, now())
  ON CONFLICT (user_id) DO UPDATE
    SET total_points = public.user_points.total_points + excluded.total_points,
        updated_at = now();

  IF v_points > 0 THEN
    INSERT INTO public.point_transactions(user_id, amount, transaction_type, reference_id, description)
    VALUES (v_uid, v_points, 'quiz_reward', v_score_id, 'Reward from quiz attempt');
  END IF;

  RETURN jsonb_build_object(
    'attempt_id', v_score_id,
    'score', v_points,
    'correct_count', v_correct,
    'question_count', v_count,
    'points_earned', v_points
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_quiz_attempt(jsonb) TO authenticated;
