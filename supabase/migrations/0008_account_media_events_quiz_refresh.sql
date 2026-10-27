-- EclipseVerse revision batch 1: account-safe media, richer event data, and 20-question quiz.
-- Apply after 0007_event_schedule_member_teams.sql.
-- Safe to re-run: policies are dropped before recreation and quiz rows are guarded.

-- Allow a signed-in user to manage only their own avatar folder.
drop policy if exists eclipseverse_media_admin_insert on storage.objects;
drop policy if exists eclipseverse_media_admin_update on storage.objects;
drop policy if exists eclipseverse_media_admin_delete on storage.objects;

create policy eclipseverse_media_admin_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'eclipseverse-media'
  and (
    exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
    or (
      (storage.foldername(name))[1] = 'avatars'
      and (storage.foldername(name))[2] = (select auth.uid())::text
    )
  )
);

create policy eclipseverse_media_admin_update on storage.objects
for update to authenticated
using (
  bucket_id = 'eclipseverse-media'
  and (
    exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
    or (
      (storage.foldername(name))[1] = 'avatars'
      and (storage.foldername(name))[2] = (select auth.uid())::text
    )
  )
)
with check (
  bucket_id = 'eclipseverse-media'
  and (
    exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
    or (
      (storage.foldername(name))[1] = 'avatars'
      and (storage.foldername(name))[2] = (select auth.uid())::text
    )
  )
);

create policy eclipseverse_media_admin_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'eclipseverse-media'
  and (
    exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
    or (
      (storage.foldername(name))[1] = 'avatars'
      and (storage.foldername(name))[2] = (select auth.uid())::text
    )
  )
);

-- Keep the app's profile email aligned when Supabase Auth confirms an email change.
create or replace function public.sync_profile_email_from_auth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.email is distinct from old.email then
    update public.profiles
      set email = coalesce(new.email, ''), updated_at = now()
      where id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists sync_profile_email_after_auth_update on auth.users;
create trigger sync_profile_email_after_auth_update
after update of email on auth.users
for each row execute procedure public.sync_profile_email_from_auth();

-- Make sure all seeded events expose their existing Storage poster paths and can be mapped.
update public.events
set poster_path = coalesce(nullif(poster_path, ''), 'events/' || slug || '.jpg')
where status <> 'draft';

insert into public.event_media(event_id, storage_path, alt_text, sort_order)
select id, poster_path, title, 0
from public.events
where poster_path is not null and poster_path <> ''
on conflict (event_id, storage_path) do nothing;

-- Use the photocard-specific image where present; otherwise fall back to its member portrait.
update public.cards c
set image_path = coalesce(
  nullif(c.image_path, ''),
  nullif(m.profile_image_path, '')
)
from public.members m
where c.member_id = m.id
  and (c.image_path is null or c.image_path = '');

-- The game now runs 20 questions per session.
alter table public.game_scores
  drop constraint if exists game_scores_correct_count_check;
alter table public.game_scores
  add constraint game_scores_correct_count_check
  check (correct_count between 0 and 20);

alter table public.game_scores
  drop constraint if exists game_scores_question_count_check;
alter table public.game_scores
  add constraint game_scores_question_count_check
  check (question_count between 1 and 20);

insert into public.quiz_questions
  (question_text, options, correct_option, explanation, difficulty, points, is_active)
select v.question_text, v.options::jsonb, v.correct_option, v.explanation, v.difficulty, v.points, true
from (values
  ('Apa nama fandom resmi Eclipse?', '{"A":"Starlings","B":"Eclipsers","C":"Orbitals","D":"Moonlights"}', 'B', 'Eclipsers adalah nama fandom resmi Eclipse.', 'easy', 10),
  ('Apa judul lagu utama era Penumbra?', '{"A":"Totality","B":"Afterglow","C":"Shadow Play","D":"Gravity"}', 'A', 'Totality adalah single utama yang terkait dengan era Penumbra.', 'normal', 15),
  ('Siapa anggota yang dikenal sebagai gitaris?', '{"A":"Altair","B":"Mira","C":"Solen","D":"Astra"}', 'A', 'Altair dikenal sebagai gitaris Eclipse.', 'easy', 10),
  ('Produk mana yang termasuk kategori apparel?', '{"A":"Photocard","B":"Hoodie Eclipse","C":"Album Penumbra","D":"Digital Album"}', 'B', 'Hoodie Eclipse termasuk kategori apparel.', 'easy', 10),
  ('Apa yang perlu dicek sebelum datang ke event?', '{"A":"Warna aplikasi","B":"Tanggal, venue, dan tiket","C":"Jumlah chat AI","D":"Tema ponsel"}', 'B', 'Tanggal, venue, dan tiket membantu persiapan menghadiri event.', 'easy', 10),
  ('Apa fungsi fitur konversi waktu?', '{"A":"Mengubah harga produk","B":"Membandingkan jam antar zona waktu","C":"Mengubah foto","D":"Menukar poin"}', 'B', 'Konversi waktu menampilkan waktu yang setara pada beberapa zona.', 'easy', 10),
  ('Apa fungsi fitur kompas di halaman lokasi?', '{"A":"Menentukan skor kuis","B":"Menunjukkan arah perangkat dan tujuan","C":"Membeli merchandise","D":"Mengubah email"}', 'B', 'Kompas menggunakan sensor perangkat untuk membantu menunjukkan arah.', 'easy', 10),
  ('Apa yang dibutuhkan untuk membuka koleksi photocard yang sudah dimiliki?', '{"A":"Kuota redeem baru setiap kali","B":"Akses ke akun pemilik kartu","C":"Membeli kartu yang sama lagi","D":"Menghapus cache"}', 'B', 'Koleksi yang sudah dimiliki terikat pada akun pengguna.', 'normal', 15),
  ('Di mana informasi harga merchandise seharusnya diambil?', '{"A":"Tebakan AI","B":"Katalog database aplikasi","C":"Nama file gambar","D":"Warna kartu"}', 'B', 'Harga harus bersumber dari katalog database.', 'normal', 15),
  ('Apa yang terjadi jika izin lokasi ditolak?', '{"A":"Aplikasi harus crash","B":"Fitur lokasi menjelaskan izin dibutuhkan dan tetap aman","C":"Akun terhapus","D":"Membership aktif otomatis"}', 'B', 'Aplikasi perlu menangani penolakan izin tanpa crash.', 'normal', 15)
) as v(question_text, options, correct_option, explanation, difficulty, points)
where not exists (
  select 1 from public.quiz_questions q where q.question_text = v.question_text
);

create or replace function public.submit_quiz_attempt(p_answers jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_item jsonb;
  v_question public.quiz_questions%rowtype;
  v_count integer := 0;
  v_correct integer := 0;
  v_score integer := 0;
  v_points integer := 0;
  v_score_id uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if jsonb_typeof(p_answers) <> 'array'
     or jsonb_array_length(p_answers) < 1
     or jsonb_array_length(p_answers) > 20 then
    raise exception 'Submit between 1 and 20 answers';
  end if;

  for v_item in select value from jsonb_array_elements(p_answers)
  loop
    if not (v_item ? 'question_id') or not (v_item ? 'answer') then
      raise exception 'Each answer needs question_id and answer';
    end if;
    select * into v_question
    from public.quiz_questions
    where id = (v_item ->> 'question_id')::bigint and is_active = true;
    if not found then
      raise exception 'Question not found or inactive';
    end if;
    v_count := v_count + 1;
    if v_item ->> 'answer' = v_question.correct_option then
      v_correct := v_correct + 1;
      v_points := v_points + v_question.points;
    end if;
  end loop;

  if (select count(distinct (value ->> 'question_id'))
      from jsonb_array_elements(p_answers)) <> v_count then
    raise exception 'Duplicate question IDs are not allowed';
  end if;

  v_score := v_points;
  insert into public.game_scores(user_id, score, correct_count, question_count)
  values (v_uid, v_score, v_correct, v_count)
  returning id into v_score_id;

  insert into public.user_points(user_id, total_points, updated_at)
  values (v_uid, v_points, now())
  on conflict (user_id) do update
    set total_points = public.user_points.total_points + excluded.total_points,
        updated_at = now();

  if v_points > 0 then
    insert into public.point_transactions(user_id, amount, transaction_type, reference_id, description)
    values (v_uid, v_points, 'quiz_reward', v_score_id, 'Reward from quiz attempt');
  end if;

  return jsonb_build_object(
    'attempt_id', v_score_id,
    'score', v_score,
    'correct_count', v_correct,
    'question_count', v_count,
    'points_earned', v_points
  );
end;
$$;

grant execute on function public.submit_quiz_attempt(jsonb) to authenticated;
