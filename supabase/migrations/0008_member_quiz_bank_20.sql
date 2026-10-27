-- EclipseVerse Revision 1: member-only quiz bank.
-- Keeps exactly 20 active questions with two answer choices each.
-- Questions are derived from public.members; answers remain server-side.

update public.quiz_questions
set is_active = false;

insert into public.quiz_questions
  (question_text, options, correct_option, explanation, difficulty, points, is_active)
values
  ('Siapa leader sekaligus Main Vocalist Eclipse?', '{"A":"Solen","B":"Lunar"}'::jsonb, 'A', 'Solen tercatat sebagai Leader, Main Vocalist.', 'easy', 10, true),
  ('Siapa yang berposisi sebagai Lead Vocalist?', '{"A":"Astra","B":"Lunar"}'::jsonb, 'B', 'Lunar tercatat sebagai Lead Vocalist.', 'easy', 10, true),
  ('Siapa yang pernah menjadi penyiar radio kampus?', '{"A":"Astra","B":"Mira"}'::jsonb, 'A', 'Fun fact Astra adalah pernah menjadi penyiar radio kampus.', 'easy', 10, true),
  ('Siapa yang berposisi sebagai Main Dancer?', '{"A":"Orion","B":"Vega"}'::jsonb, 'A', 'Orion tercatat sebagai Main Dancer.', 'easy', 10, true),
  ('Siapa yang menjadi koreografer pertama lagu Penumbra?', '{"A":"Vega","B":"Nova"}'::jsonb, 'A', 'Fun fact Vega adalah koreografer pertama lagu Penumbra.', 'easy', 10, true),
  ('Siapa yang bisa menari sambil memainkan yo-yo?', '{"A":"Nova","B":"Lyra"}'::jsonb, 'A', 'Fun fact Nova adalah bisa menari sambil memainkan yo-yo.', 'easy', 10, true),
  ('Siapa yang dikenal sebagai Main Rapper Eclipse?', '{"A":"Zephyr","B":"Atlas"}'::jsonb, 'A', 'Zephyr tercatat sebagai Main Rapper.', 'easy', 10, true),
  ('Siapa yang merupakan Lead Rapper?', '{"A":"Lyra","B":"Atlas"}'::jsonb, 'B', 'Atlas tercatat sebagai Lead Rapper.', 'easy', 10, true),
  ('Siapa yang merupakan Visual Eclipse?', '{"A":"Cassio","B":"Rigel"}'::jsonb, 'A', 'Cassio tercatat sebagai Visual.', 'easy', 10, true),
  ('Siapa yang merupakan anggota termuda atau Maknae?', '{"A":"Mira","B":"Solen"}'::jsonb, 'A', 'Mira tercatat sebagai Maknae, yaitu anggota termuda.', 'easy', 10, true),
  ('Siapa yang dikenal sebagai Producer Eclipse?', '{"A":"Rigel","B":"Altair"}'::jsonb, 'A', 'Rigel tercatat sebagai Producer.', 'normal', 15, true),
  ('Siapa yang berposisi sebagai Guitarist?', '{"A":"Altair","B":"Zephyr"}'::jsonb, 'A', 'Altair tercatat sebagai Guitarist.', 'normal', 15, true),
  ('Siapa yang menulis lagu debut Eclipse di kamar kos?', '{"A":"Solen","B":"Orion"}'::jsonb, 'A', 'Fun fact Solen adalah menulis lagu debut Eclipse di kamar kos.', 'normal', 15, true),
  ('Siapa yang hafal 40 lagu tema film animasi?', '{"A":"Lunar","B":"Astra"}'::jsonb, 'A', 'Fun fact Lunar adalah hafal 40 lagu tema film animasi.', 'normal', 15, true),
  ('Siapa yang pernah menjadi juara kompetisi breakdance tingkat provinsi?', '{"A":"Orion","B":"Nova"}'::jsonb, 'A', 'Fun fact Orion adalah juara kompetisi breakdance tingkat provinsi.', 'normal', 15, true),
  ('Siapa yang menulis lirik rap dalam tiga bahasa?', '{"A":"Atlas","B":"Zephyr"}'::jsonb, 'B', 'Fun fact Zephyr adalah menulis lirik rap dalam tiga bahasa.', 'normal', 15, true),
  ('Siapa yang pernah menjadi juara lomba debat sekolah?', '{"A":"Lyra","B":"Cassio"}'::jsonb, 'A', 'Fun fact Lyra adalah pernah menjadi juara lomba debat sekolah.', 'normal', 15, true),
  ('Siapa yang pernah menjadi model majalah sekolah?', '{"A":"Cassio","B":"Rigel"}'::jsonb, 'A', 'Fun fact Cassio adalah pernah menjadi model majalah sekolah.', 'normal', 15, true),
  ('Siapa yang membuat 10 beat dalam satu malam?', '{"A":"Rigel","B":"Altair"}'::jsonb, 'A', 'Fun fact Rigel adalah membuat 10 beat dalam satu malam.', 'normal', 15, true),
  ('Siapa yang bermain gitar sejak usia 7 tahun?', '{"A":"Altair","B":"Mira"}'::jsonb, 'A', 'Fun fact Altair adalah bermain gitar sejak usia 7 tahun.', 'normal', 15, true);

-- Public clients only need the active question bank and never receive the answer key.
create or replace view public.quiz_questions_public as
select id, question_text, options, explanation, difficulty, points
from public.quiz_questions
where is_active = true;

-- Defensive check: the intended active bank is exactly 20 questions.
do $$
begin
  if (select count(*) from public.quiz_questions where is_active = true) <> 20 then
    raise exception 'Member quiz bank must contain exactly 20 active questions';
  end if;
end;
$$;
