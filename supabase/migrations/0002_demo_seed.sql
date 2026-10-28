-- EclipseVerse Plus demo data.
-- Run after 0001_initial_schema.sql on a fresh project.
-- All products/events are fictional project data; currency rows are clearly marked demo.
-- Image paths are placeholders in the public 'eclipseverse-media' Storage bucket.

insert into public.categories (slug, name, description, sort_order) values
('album', 'Albums & Music', 'Album fisik, single, dan rilisan musik EclipseVerse.', 1),
('apparel', 'Apparel', 'Pakaian bertema EclipseVerse.', 2),
('accessory', 'Accessories', 'Aksesori harian bertema EclipseVerse.', 3),
('collectible', 'Collectibles', 'Photocard, poster, lightstick, dan koleksi.', 4)
on conflict (slug) do nothing;

insert into public.products
(sku, category_id, name, description, price_idr, stock, cover_image_path, is_published)
select v.sku, c.id, v.name, v.description, v.price_idr, v.stock, v.cover_image_path, true
from (values
('EV-ALB-001','album','Album Penumbra (Standard)','Album studio pertama Eclipse dengan 10 lagu original.',185000,50,'products/album-penumbra-standard.jpg'),
('EV-ALB-002','album','Album Penumbra (Deluxe)','Edisi deluxe dengan photobook dan poster eksklusif.',275000,30,'products/album-penumbra-deluxe.jpg'),
('EV-ALB-003','album','Single Totality','Single fisik berisi lagu Totality dan dua bonus track.',95000,40,'products/single-totality.jpg'),
('EV-ALB-004','album','Penumbra Vinyl Edition','Piringan vinyl edisi kolektor dengan sleeve kosmik.',425000,12,'products/penumbra-vinyl.jpg'),
('EV-ALB-005','album','Penumbra Digital Album','Album digital dengan booklet digital.',65000,100,'products/penumbra-digital.jpg'),
('EV-ALB-006','album','Totality Limited CD','CD single edisi terbatas dengan lyric card.',125000,25,'products/totality-limited-cd.jpg'),
('EV-ALB-007','album','Eclipse Live Session','Album rekaman live session pilihan.',155000,22,'products/live-session.jpg'),
('EV-ALB-008','album','Acoustic Moonlight EP','EP akustik dengan lima track.',135000,28,'products/moonlight-ep.jpg'),
('EV-ALB-009','album','Solar Flare Remix Album','Album remix dance dan electronic.',175000,18,'products/solar-flare-remix.jpg'),
('EV-ALB-010','album','Eclipse Discography Box','Box set rilisan musik pilihan EclipseVerse.',650000,8,'products/discography-box.jpg'),
('EV-APP-011','apparel','T-Shirt Eclipse Black','Kaos hitam katun dengan logo Eclipse.',165000,40,'products/tshirt-eclipse-black.jpg'),
('EV-APP-012','apparel','Hoodie Corona','Hoodie fleece dengan grafis corona.',325000,25,'products/hoodie-corona.jpg'),
('EV-APP-013','apparel','Tour Jacket Umbra','Jaket tour edisi terbatas dengan bordir 13 member.',485000,15,'products/tour-jacket-umbra.jpg'),
('EV-APP-014','apparel','Oversized Nebula Tee','Kaos oversized dengan ilustrasi nebula.',185000,35,'products/nebula-tee.jpg'),
('EV-APP-015','apparel','Moonphase Long Sleeve','Kaos lengan panjang dengan grafis fase bulan.',215000,24,'products/moonphase-long-sleeve.jpg'),
('EV-APP-016','apparel','Starlight Zip Hoodie','Hoodie zipper bertema starlight.',355000,18,'products/starlight-zip-hoodie.jpg'),
('EV-APP-017','apparel','Eclipse Varsity Jacket','Jaket varsity koleksi kampus EclipseVerse.',525000,10,'products/varsity-jacket.jpg'),
('EV-APP-018','apparel','Cosmic Bucket Hat','Bucket hat dengan emblem kosmik.',115000,30,'products/cosmic-bucket-hat.jpg'),
('EV-APP-019','apparel','Orbit Beanie','Beanie rajut dengan label Orbit.',95000,32,'products/orbit-beanie.jpg'),
('EV-APP-020','apparel','Penumbra Sweatshirt','Sweatshirt dengan artwork Penumbra.',285000,20,'products/penumbra-sweatshirt.jpg'),
('EV-ACC-021','accessory','Lanyard Eclipse','Lanyard dengan logo Eclipse dan clip besi.',45000,100,'products/lanyard-eclipse.jpg'),
('EV-ACC-022','accessory','Tote Bag Solar','Tote bag kanvas dengan ilustrasi Solar.',85000,60,'products/tote-solar.jpg'),
('EV-ACC-023','accessory','Keychain Set 13 Member','Gantungan kunci akrilik 13 karakter Eclipse.',75000,80,'products/keychain-13.jpg'),
('EV-ACC-024','accessory','Cosmic Enamel Pin','Pin enamel bertema galaksi.',55000,75,'products/enamel-pin.jpg'),
('EV-ACC-025','accessory','Moonlight Phone Grip','Phone grip dengan simbol bulan.',45000,70,'products/phone-grip.jpg'),
('EV-ACC-026','accessory','Eclipse Acrylic Stand','Acrylic stand untuk meja belajar.',65000,55,'products/acrylic-stand.jpg'),
('EV-ACC-027','accessory','Nebula Sticker Pack','Paket stiker tahan air bertema nebula.',35000,150,'products/sticker-pack.jpg'),
('EV-ACC-028','accessory','Star Map Notebook','Notebook dengan cover peta bintang.',60000,65,'products/star-map-notebook.jpg'),
('EV-ACC-029','accessory','Orbit Keyring','Keyring metal dengan logo Orbit.',50000,85,'products/orbit-keyring.jpg'),
('EV-ACC-030','accessory','Solar Travel Pouch','Pouch serbaguna motif solar flare.',70000,45,'products/travel-pouch.jpg'),
('EV-ACC-031','accessory','Eclipse Hair Clip Set','Set jepit rambut bertema Eclipse.',40000,60,'products/hair-clip-set.jpg'),
('EV-ACC-032','accessory','Stardust Bracelet','Gelang aksesori dengan charm bintang.',80000,40,'products/stardust-bracelet.jpg'),
('EV-ACC-033','accessory','Nebula Mini Umbrella','Payung lipat dengan motif nebula.',135000,25,'products/mini-umbrella.jpg'),
('EV-ACC-034','accessory','Cosmic Luggage Tag','Tag koper bertema perjalanan kosmik.',55000,50,'products/luggage-tag.jpg'),
('EV-ACC-035','accessory','Moon Phase Keycap','Keycap dekoratif bertema fase bulan.',65000,35,'products/moon-phase-keycap.jpg'),
('EV-COL-036','collectible','Lightstick Eclipse v1','Lightstick Eclipse dengan tiga mode warna.',395000,20,'products/lightstick-v1.jpg'),
('EV-COL-037','collectible','Photocard Set A: Penumbra','Set photocard 13 member edisi Penumbra.',55000,120,'products/photocard-set-a.jpg'),
('EV-COL-038','collectible','Poster Set Penumbra','Set enam poster A3 artwork Penumbra.',65000,70,'products/poster-set-penumbra.jpg'),
('EV-COL-039','collectible','Photocard Binder','Binder koleksi photocard dengan sleeve.',145000,35,'products/photocard-binder.jpg'),
('EV-COL-040','collectible','Photocard Sleeve Pack','Paket sleeve pelindung kartu.',25000,200,'products/sleeve-pack.jpg'),
('EV-COL-041','collectible','Member Polaroid Set','Set polaroid 13 member fiktif Eclipse.',75000,80,'products/polaroid-set.jpg'),
('EV-COL-042','collectible','Holographic Photo Set','Foto koleksi dengan finishing holografik.',90000,45,'products/holographic-photo-set.jpg'),
('EV-COL-043','collectible','Eclipse Logo Badge Set','Set badge logo dan simbol Eclipse.',40000,100,'products/logo-badge-set.jpg'),
('EV-COL-044','collectible','Mini Lightstick Keychain','Keychain mini terinspirasi lightstick.',95000,40,'products/mini-lightstick.jpg'),
('EV-COL-045','collectible','Penumbra Artbook','Artbook konsep visual rilisan Penumbra.',225000,16,'products/penumbra-artbook.jpg'),
('EV-COL-046','collectible','Cosmic Acrylic Card','Kartu akrilik transparan bertema kosmik.',85000,55,'products/acrylic-card.jpg'),
('EV-COL-047','collectible','Eclipse Trading Card Pack','Paket kartu koleksi acak untuk demo.',35000,180,'products/trading-card-pack.jpg'),
('EV-COL-048','collectible','Limited Member Photo Frame','Frame foto koleksi edisi terbatas.',110000,22,'products/photo-frame.jpg'),
('EV-COL-049','collectible','Totality Concert Slogan','Slogan kain untuk event Totality.',50000,60,'products/concert-slogan.jpg'),
('EV-COL-050','collectible','Eclipse Anniversary Box','Box koleksi anniversary dengan beberapa item.',450000,12,'products/anniversary-box.jpg')
) as v(sku, category_slug, name, description, price_idr, stock, cover_image_path)
join public.categories c on c.slug = v.category_slug
on conflict (sku) do nothing;

insert into public.members(stage_name, position, description, fun_fact, sort_order) values
('Solen','Leader, Main Vocalist','Pemimpin Eclipse yang tenang dan berpengalaman. Suaranya jadi ciri khas lagu-lagu balada Eclipse.','Menulis lagu debut Eclipse di kamar kos',1),
('Lunar','Lead Vocalist','Vokalis dengan range tinggi yang kuat. Sering jadi pusat harmoni di chorus.','Hafal 40 lagu tema film animasi',2),
('Astra','Vocalist','Vokalis dengan warna suara lembut dan khas. Cocok untuk lagu akustik.','Pernah menjadi penyiar radio kampus',3),
('Orion','Main Dancer','Penari utama dengan teknik dan ekspresi kuat. Sering jadi center di koreografi dinamis.','Juara kompetisi breakdance tingkat provinsi',4),
('Vega','Lead Dancer','Penari dengan gerakan presisi. Sering membantu koreografi member lain.','Koreografer pertama lagu Penumbra',5),
('Nova','Dancer','Penari energik dengan ciri khas gerakan cepat.','Bisa menari sambil memainkan yo-yo',6),
('Zephyr','Main Rapper','Rapper utama dengan flow cepat dan lirik tajam.','Menulis lirik rap dalam tiga bahasa',7),
('Atlas','Lead Rapper','Rapper dengan gaya santai namun kuat di panggung.','Kolektor sepatu edisi terbatas',8),
('Lyra','Rapper','Rapper dengan gaya unik dan ekspresif.','Pernah menjadi juara lomba debat sekolah',9),
('Cassio','Visual','Wajah utama Eclipse dengan aura misterius.','Pernah menjadi model majalah sekolah',10),
('Rigel','Producer','Produser internal Eclipse yang menciptakan banyak beat.','Membuat 10 beat dalam satu malam',11),
('Altair','Guitarist','Gitaris dengan permainan melodi yang khas.','Bermain gitar sejak usia 7 tahun',12),
('Mira','Maknae','Anggota termuda dengan energi ceria yang menular.','Anggota termuda yang hobi merakit puzzle 1000 keping',13)
on conflict (stage_name) do update set
  position = excluded.position, description = excluded.description,
  fun_fact = excluded.fun_fact, sort_order = excluded.sort_order;

insert into public.cards(member_id, slug, card_name, rarity, image_path, points_cost, is_available)
select m.id, lower(m.stage_name), m.stage_name || ' - Eclipse Edition',
  case when m.sort_order in (1,4,7) then 'rare' else 'common' end,
  'cards/' || lower(m.stage_name) || '-eclipse-edition.jpg',
  case when m.sort_order in (1,4,7) then 150 else 100 end, true
from public.members m
on conflict (slug) do nothing;

insert into public.events
(slug, title, description, event_date, venue, city, latitude, longitude, status, is_demo, poster_path)
values
('fan-meeting-yogyakarta','Eclipse Fan Meeting Yogyakarta','Fan meeting dengan sesi tanya jawab dan performance akustik.',now() + interval '7 days','Aula Cakrawala Yogyakarta','Yogyakarta',-7.795600,110.369500,'scheduled',true,'events/fan-meeting-yogyakarta.jpg'),
('fan-meeting-jakarta','Eclipse Fan Meeting Jakarta','Fan meeting dengan panggung utama dan surprise performance.',now() + interval '14 days','Balai Nirwana Jakarta','Jakarta',-6.208800,106.845600,'scheduled',true,'events/fan-meeting-jakarta.jpg'),
('penumbra-showcase-bandung','Penumbra Showcase Bandung','Showcase album Penumbra dengan full band performance.',now() + interval '21 days','Gedung Pentas Parahyangan','Bandung',-6.917500,107.619100,'scheduled',true,'events/penumbra-showcase-bandung.jpg'),
('totality-live-surabaya','Totality Live Surabaya','Konser mini bertema single Totality dengan visual effects.',now() + interval '28 days','Arena Surya Bahari','Surabaya',-7.257500,112.752100,'scheduled',true,'events/totality-live-surabaya.jpg'),
('summer-fest-denpasar','Eclipse Summer Fest Denpasar','Festival musim panas dengan Eclipse sebagai headliner.',now() + interval '35 days','Pusat Konvensi Samudra','Denpasar',-8.670500,115.212600,'scheduled',true,'events/summer-fest-denpasar.jpg'),
('world-tour-seoul','Eclipse World Tour Seoul','Konser tur dunia pertama Eclipse di Seoul.',now() + interval '60 days','Aurora Dome Seoul','Seoul',37.566500,126.978000,'scheduled',true,'events/world-tour-seoul.jpg'),
('acoustic-night-semarang','Eclipse Acoustic Night Semarang','Malam akustik dan cerita di balik lagu-lagu Eclipse.',now() + interval '42 days','Pendopo Bintang Semarang','Semarang',-6.966700,110.416700,'scheduled',true,'events/acoustic-night-semarang.jpg'),
('cosmic-pop-up-malang','Cosmic Pop-up Store Malang','Pop-up store demo dengan merchandise dan photo zone.',now() + interval '49 days','Galeri Orbit Malang','Malang',-7.966600,112.632600,'scheduled',true,'events/cosmic-pop-up-malang.jpg'),
('fan-art-festival-bogor','Eclipse Fan Art Festival Bogor','Pameran fan art fiktif dan workshop ilustrasi.',now() + interval '56 days','Ruang Kreatif Puncak','Bogor',-6.595000,106.816600,'scheduled',true,'events/fan-art-festival-bogor.jpg'),
('midnight-comeback-live','Midnight Comeback Live','Live showcase untuk era rilisan baru Eclipse.',now() + interval '70 days','Studio Aurora','Jakarta',-6.208800,106.845600,'scheduled',true,'events/midnight-comeback-live.jpg'),
('starlight-campus-tour','Starlight Campus Tour','Acara musik kampus fiktif dengan sesi interaksi penggemar.',now() + interval '77 days','Auditorium Cakrawala','Yogyakarta',-7.795600,110.369500,'scheduled',true,'events/starlight-campus-tour.jpg'),
('anniversary-gala','Eclipse Anniversary Gala','Perayaan anniversary dengan penampilan dan retrospektif perjalanan grup.',now() + interval '90 days','Hall Nebula','Surabaya',-7.257500,112.752100,'scheduled',true,'events/anniversary-gala.jpg')
on conflict (slug) do nothing;

-- Clearly labelled starter exchange rates only; replace via the live rate API job.
insert into public.currency_rates(base_code, target_code, rate, source, fetched_at) values
('USD','USD',1,'demo-seed',now()),
('USD','IDR',16250,'demo-seed',now()),
('USD','KRW',1380,'demo-seed',now()),
('USD','JPY',155,'demo-seed',now()),
('IDR','IDR',1,'demo-seed',now()),
('IDR','USD',1.0/16250,'demo-seed',now()),
('IDR','KRW',1380.0/16250,'demo-seed',now()),
('IDR','JPY',155.0/16250,'demo-seed',now())
on conflict (base_code, target_code) do nothing;

-- Sample questions are fictional. The answer key is never exposed through the public quiz view.
insert into public.quiz_questions(question_text, options, correct_option, explanation, difficulty, points, is_active) values
('Siapa leader Eclipse?', '{"A":"Solen","B":"Lunar","C":"Astra","D":"Mira"}','A','Solen adalah leader dan main vocalist Eclipse.','easy',10,true),
('Siapa yang dikenal sebagai main dancer?', '{"A":"Atlas","B":"Orion","C":"Rigel","D":"Lyra"}','B','Orion adalah main dancer Eclipse.','easy',10,true),
('Siapa produser internal Eclipse?', '{"A":"Vega","B":"Nova","C":"Rigel","D":"Altair"}','C','Rigel berperan sebagai producer internal.','easy',10,true),
('Siapa anggota termuda Eclipse?', '{"A":"Mira","B":"Cassio","C":"Zephyr","D":"Solen"}','A','Mira adalah maknae Eclipse.','easy',10,true),
('Siapa yang menulis lirik rap dalam tiga bahasa?', '{"A":"Lunar","B":"Zephyr","C":"Atlas","D":"Astra"}','B','Fun fact Zephyr adalah menulis lirik rap dalam tiga bahasa.','normal',15,true),
('Siapa gitaris Eclipse?', '{"A":"Altair","B":"Orion","C":"Cassio","D":"Nova"}','A','Altair adalah guitarist Eclipse.','easy',10,true),
('Apa judul album studio pertama Eclipse?', '{"A":"Totality","B":"Solar Flare","C":"Penumbra","D":"Moonlight"}','C','Penumbra adalah album studio pertama Eclipse.','easy',10,true),
('Siapa yang pernah menjadi penyiar radio kampus?', '{"A":"Astra","B":"Lyra","C":"Mira","D":"Vega"}','A','Astra pernah menjadi penyiar radio kampus.','normal',15,true),
('Siapa yang mengoleksi sepatu edisi terbatas?', '{"A":"Solen","B":"Atlas","C":"Rigel","D":"Lunar"}','B','Atlas adalah kolektor sepatu edisi terbatas.','normal',15,true),
('Siapa yang menjadi koreografer pertama lagu Penumbra?', '{"A":"Nova","B":"Orion","C":"Vega","D":"Mira"}','C','Vega menjadi koreografer pertama lagu Penumbra.','normal',15,true)
on conflict do nothing;

-- Quick verification:
-- select count(*) from public.products; -- target 50
-- select count(*) from public.members;  -- target 13
-- select count(*) from public.cards;    -- target 13
-- select count(*) from public.events;   -- target 12
