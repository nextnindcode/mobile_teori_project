-- EclipseVerse polish: 18 varied events around four nearby Jogja-Klaten venues
-- plus richer fictional member profiles. Apply after 0007_event_schedule_member_teams.sql.
-- This only replaces demo events; non-demo events are preserved.

alter table public.members
  add column if not exists favorite_food text,
  add column if not exists spirit_animal text,
  add column if not exists birth_date date,
  add column if not exists favorite_color text,
  add column if not exists hobby text;

update public.members set
  team = case
    when stage_name in ('Solen','Lunar','Astra','Mira') then 'Vocal Team'
    when stage_name in ('Zephyr','Atlas','Lyra','Rigel') then 'Hip-Hop Team'
    else 'Performance Team'
  end,
  favorite_food = case stage_name
    when 'Solen' then 'Mie kuah pedas'
    when 'Lunar' then 'Pancake madu'
    when 'Astra' then 'Soto ayam'
    when 'Orion' then 'Tteokbokki'
    when 'Vega' then 'Pasta aglio e olio'
    when 'Nova' then 'Es krim stroberi'
    when 'Zephyr' then 'Ayam panggang'
    when 'Atlas' then 'Burger keju'
    when 'Lyra' then 'Seblak'
    when 'Cassio' then 'Roti kayu manis'
    when 'Rigel' then 'Nasi goreng'
    when 'Altair' then 'Sate ayam'
    when 'Mira' then 'Mochi'
    else 'Ramen'
  end,
  spirit_animal = case stage_name
    when 'Solen' then 'Serigala'
    when 'Lunar' then 'Kucing putih'
    when 'Astra' then 'Rusa'
    when 'Orion' then 'Macan tutul'
    when 'Vega' then 'Burung kolibri'
    when 'Nova' then 'Berang-berang'
    when 'Zephyr' then 'Elang'
    when 'Atlas' then 'Beruang'
    when 'Lyra' then 'Rubah'
    when 'Cassio' then 'Angsa'
    when 'Rigel' then 'Gagak'
    when 'Altair' then 'Kuda'
    when 'Mira' then 'Kelinci'
    else 'Kucing'
  end,
  birth_date = case stage_name
    when 'Solen' then date '2001-02-14'
    when 'Lunar' then date '2002-09-08'
    when 'Astra' then date '2003-04-21'
    when 'Orion' then date '2001-11-30'
    when 'Vega' then date '2002-06-17'
    when 'Nova' then date '2004-01-09'
    when 'Zephyr' then date '2000-08-26'
    when 'Atlas' then date '2001-12-05'
    when 'Lyra' then date '2003-03-12'
    when 'Cassio' then date '2002-10-03'
    when 'Rigel' then date '2000-05-19'
    when 'Altair' then date '2001-07-27'
    when 'Mira' then date '2005-02-02'
    else birth_date
  end,
  favorite_color = case stage_name
    when 'Solen' then 'Midnight blue'
    when 'Lunar' then 'Pearl white'
    when 'Astra' then 'Lavender'
    when 'Orion' then 'Crimson'
    when 'Vega' then 'Sage green'
    when 'Nova' then 'Peach'
    when 'Zephyr' then 'Charcoal'
    when 'Atlas' then 'Cobalt'
    when 'Lyra' then 'Burgundy'
    when 'Cassio' then 'Silver'
    when 'Rigel' then 'Indigo'
    when 'Altair' then 'Forest green'
    when 'Mira' then 'Butter yellow'
    else 'Violet'
  end,
  hobby = case stage_name
    when 'Solen' then 'Menulis lirik dan meracik kopi'
    when 'Lunar' then 'Memotret langit malam'
    when 'Astra' then 'Membaca novel fantasi'
    when 'Orion' then 'Mengoleksi sneakers'
    when 'Vega' then 'Membuat koreografi'
    when 'Nova' then 'Merakit miniatur'
    when 'Zephyr' then 'Menulis rap dan freestyle'
    when 'Atlas' then 'Bermain basket'
    when 'Lyra' then 'Menggambar komik'
    when 'Cassio' then 'Fotografi analog'
    when 'Rigel' then 'Membuat beat elektronik'
    when 'Altair' then 'Merawat tanaman dan bermain gitar'
    when 'Mira' then 'Puzzle dan membuat gelang'
    else 'Mendengarkan musik'
  end;

-- The dates are intentionally fixed for the demo and include past and future events.
-- Four mappable venues keep route lengths manageable for the location feature.
insert into public.events
  (slug, title, description, event_date, venue, city, latitude, longitude, status, is_demo)
values
  ('eclipse-acoustic-morning-2026','Acoustic Morning: First Light','Sesi akustik santai dan cerita di balik lagu debut Eclipse.','2026-10-03 10:30:00+07','Taman Budaya Yogyakarta','Yogyakarta',-7.801400,110.367000,'completed',true),
  ('eclipse-fan-art-lab-2026','Fan Art Lab: Draw Our Orbit','Workshop ilustrasi dan pameran karya Eclipse Lovers.','2026-10-10 13:00:00+07','Auditorium Universitas Gadjah Mada','Yogyakarta',-7.770800,110.377600,'completed',true),
  ('eclipse-mini-stage-klaten-2026','Mini Stage: Echoes in Klaten','Panggung mini dengan sesi interaksi dan lagu pilihan.','2026-10-17 16:30:00+07','Alun-Alun Klaten','Klaten',-7.705000,110.606000,'completed',true),
  ('eclipse-photocard-swap-2026','Photocard Swap & Cafe Day','Meet-up kolektor untuk bertukar cerita dan koleksi.','2026-10-24 14:00:00+07','Jogja Expo Center','Yogyakarta',-7.801900,110.403000,'completed',true),
  ('eclipseverse-campus-tour-2026','Starlight Campus Tour','Penampilan kampus dengan sesi tanya jawab member.','2026-10-29 18:30:00+07','Auditorium Universitas Gadjah Mada','Yogyakarta',-7.770800,110.377600,'scheduled',true),
  ('eclipse-lightstick-workshop-2026','Lightstick Decorating Workshop','Dekorasi lightstick dan sesi foto bertema galaksi.','2026-11-01 10:00:00+07','Jogja Expo Center','Yogyakarta',-7.801900,110.403000,'scheduled',true),
  ('eclipse-penumbra-showcase-2026','Penumbra: Mini Showcase','Mini showcase dengan live band dan visual kosmik.','2026-11-07 19:00:00+07','Taman Budaya Yogyakarta','Yogyakarta',-7.801400,110.367000,'scheduled',true),
  ('eclipse-dance-practice-2026','Open Dance Practice','Belajar potongan koreografi bersama tim Performance.','2026-11-11 16:00:00+07','Auditorium Universitas Gadjah Mada','Yogyakarta',-7.770800,110.377600,'scheduled',true),
  ('eclipse-voice-studio-2026','Voice Studio: Harmonies','Sesi vokal dan harmonisasi bersama tim Vocal.','2026-11-14 15:30:00+07','Alun-Alun Klaten','Klaten',-7.705000,110.606000,'scheduled',true),
  ('eclipse-hiphop-cypher-2026','Orbit Cypher Night','Cypher rap, freestyle, dan sesi beat-making.','2026-11-21 19:30:00+07','Jogja Expo Center','Yogyakarta',-7.801900,110.403000,'scheduled',true),
  ('eclipse-fan-meeting-klaten-2026','Eclipse Lovers Meet-up Klaten','Fan meeting dengan games ringan dan sesi foto.','2026-11-25 18:00:00+07','Alun-Alun Klaten','Klaten',-7.705000,110.606000,'scheduled',true),
  ('eclipse-merch-preview-2026','Cosmic Merch Preview','Lihat koleksi merchandise baru sebelum dirilis.','2026-11-28 13:00:00+07','Jogja Expo Center','Yogyakarta',-7.801900,110.403000,'scheduled',true),
  ('eclipse-totality-live-2026','Totality Live Session','Live performance dengan setlist lagu Totality dan Penumbra.','2026-12-02 19:00:00+07','Taman Budaya Yogyakarta','Yogyakarta',-7.801400,110.367000,'scheduled',true),
  ('eclipse-star-map-night-2026','Star Map Night','Acara malam bertema astronomi, musik, dan cerita member.','2026-12-05 18:30:00+07','Auditorium Universitas Gadjah Mada','Yogyakarta',-7.770800,110.377600,'scheduled',true),
  ('eclipse-winter-fan-festival-2026','Winter Fan Festival','Festival penggemar dengan booth kreatif dan mini stage.','2026-12-12 15:00:00+07','Jogja Expo Center','Yogyakarta',-7.801900,110.403000,'scheduled',true),
  ('eclipse-unplugged-klaten-2026','Unplugged Evening','Pertunjukan unplugged dengan lagu pilihan penggemar.','2026-12-18 19:00:00+07','Alun-Alun Klaten','Klaten',-7.705000,110.606000,'scheduled',true),
  ('eclipse-year-end-stage-2026','Year-End Orbit Stage','Panggung akhir tahun dengan penampilan seluruh tim.','2026-12-20 16:30:00+07','Taman Budaya Yogyakarta','Yogyakarta',-7.801400,110.367000,'scheduled',true),
  ('eclipse-new-year-countdown-2026','Countdown to a New Orbit','Acara penutup tahun dengan musik, games, dan pesan member.','2026-12-27 18:30:00+07','Jogja Expo Center','Yogyakarta',-7.801900,110.403000,'scheduled',true)
on conflict (slug) do update set
  title = excluded.title,
  description = excluded.description,
  event_date = excluded.event_date,
  venue = excluded.venue,
  city = excluded.city,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  status = excluded.status,
  is_demo = true;

delete from public.events
where is_demo = true
  and slug not in (
    'eclipse-acoustic-morning-2026','eclipse-fan-art-lab-2026','eclipse-mini-stage-klaten-2026',
    'eclipse-photocard-swap-2026','eclipseverse-campus-tour-2026','eclipse-lightstick-workshop-2026',
    'eclipse-penumbra-showcase-2026','eclipse-dance-practice-2026','eclipse-voice-studio-2026',
    'eclipse-hiphop-cypher-2026','eclipse-fan-meeting-klaten-2026','eclipse-merch-preview-2026',
    'eclipse-totality-live-2026','eclipse-star-map-night-2026','eclipse-winter-fan-festival-2026',
    'eclipse-unplugged-klaten-2026','eclipse-year-end-stage-2026','eclipse-new-year-countdown-2026'
  );
