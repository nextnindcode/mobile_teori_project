-- Demo data cleanup: real geolocatable venues, varied Oct-Dec 2026 schedules,
-- and team/profile image fields for EclipseVerse fictional members.
-- Apply after 0006_point_membership_and_redeem_quota.sql.

alter table public.members
  add column if not exists team text not null default 'Vocal Team';

alter table public.members
  drop constraint if exists members_team_check;
alter table public.members
  add constraint members_team_check
  check (team in ('Vocal Team', 'Performance Team', 'Hip-Hop Team'));

update public.members
set team = case
  when lower(position) like '%vocal%' or stage_name in ('Solen','Lunar','Astra','Mira')
    then 'Vocal Team'
  when lower(position) like '%rapper%' or stage_name in ('Zephyr','Atlas','Lyra','Rigel')
    then 'Hip-Hop Team'
  else 'Performance Team'
end,
profile_image_path = coalesce(
  nullif(profile_image_path, ''),
  'cards/' || lower(stage_name) || '-eclipse-edition.jpg'
);

-- Keep fictional event names, but point them to real, mappable venues and
-- spread demo schedules across the requested October-December 2026 window.
update public.events set
  event_date = '2026-10-30 19:00:00+07',
  venue = 'Taman Budaya Yogyakarta',
  city = 'Yogyakarta',
  latitude = -7.801400,
  longitude = 110.367000
where slug = 'fan-meeting-yogyakarta';

update public.events set
  event_date = '2026-11-07 15:30:00+07',
  venue = 'Balai Sarbini',
  city = 'Jakarta',
  latitude = -6.219200,
  longitude = 106.815300
where slug = 'fan-meeting-jakarta';

update public.events set
  event_date = '2026-11-15 18:30:00+07',
  venue = 'Sabuga (Sasana Budaya Ganesha)',
  city = 'Bandung',
  latitude = -6.888400,
  longitude = 107.610200
where slug = 'penumbra-showcase-bandung';

update public.events set
  event_date = '2026-11-28 19:30:00+07',
  venue = 'Grand City Convention Hall',
  city = 'Surabaya',
  latitude = -7.265700,
  longitude = 112.738800
where slug = 'totality-live-surabaya';

update public.events set
  event_date = '2026-12-05 17:00:00+07',
  venue = 'Bali Nusa Dua Convention Center',
  city = 'Denpasar',
  latitude = -8.800500,
  longitude = 115.229000
where slug = 'summer-fest-denpasar';

update public.events set
  event_date = '2026-12-12 16:00:00+09',
  venue = 'KSPO Dome',
  city = 'Seoul',
  latitude = 37.520700,
  longitude = 127.115500
where slug = 'world-tour-seoul';

update public.events set
  event_date = '2026-12-16 19:00:00+07',
  venue = 'UTC Convention Hall',
  city = 'Semarang',
  latitude = -7.050000,
  longitude = 110.390000
where slug = 'acoustic-night-semarang';

update public.events set
  event_date = '2026-12-20 20:00:00+07',
  venue = 'Graha Cakrawala, Universitas Negeri Malang',
  city = 'Malang',
  latitude = -7.959500,
  longitude = 112.615000
where slug = 'cosmic-pop-up-malang';

update public.events set
  event_date = '2026-12-23 15:00:00+07',
  venue = 'IPB International Convention Center',
  city = 'Bogor',
  latitude = -6.597600,
  longitude = 106.806000
where slug = 'fan-art-festival-bogor';

update public.events set
  event_date = '2026-12-26 19:30:00+07',
  venue = 'JIExpo Kemayoran',
  city = 'Jakarta',
  latitude = -6.145000,
  longitude = 106.845000
where slug = 'midnight-comeback-live';

update public.events set
  event_date = '2026-11-02 16:00:00+07',
  venue = 'Auditorium Universitas Gadjah Mada',
  city = 'Yogyakarta',
  latitude = -7.770800,
  longitude = 110.377600
where slug = 'starlight-campus-tour';

update public.events set
  event_date = '2026-12-30 18:30:00+07',
  venue = 'Taman Ismail Marzuki',
  city = 'Jakarta',
  latitude = -6.190900,
  longitude = 106.832900
where slug = 'anniversary-gala';
