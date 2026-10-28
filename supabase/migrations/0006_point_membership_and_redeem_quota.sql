-- EclipseVerse point-based membership packages and quota-based photocard redemption.
-- Apply after 0005_blockchain_integrity.sql in Supabase SQL Editor.

alter table public.membership_plans
  add column if not exists price_points integer not null default 100,
  add column if not exists quota_amount integer not null default 1;

alter table public.user_memberships
  add column if not exists redeem_quota integer not null default 0;

alter table public.point_transactions
  drop constraint if exists point_transactions_transaction_type_check;
alter table public.point_transactions
  add constraint point_transactions_transaction_type_check
  check (transaction_type in (
    'quiz_reward', 'photocard_redemption', 'membership_purchase', 'admin_adjustment'
  ));

alter table public.redemption_transactions
  drop constraint if exists redemption_transactions_points_spent_check;
alter table public.redemption_transactions
  add constraint redemption_transactions_points_spent_check
  check (points_spent >= 0);

-- The group decided membership is purchased with points and grants redemption uses.
-- These point prices are initial demo values and can be adjusted in the plan table.
update public.membership_plans
set is_active = false
where code in ('monthly', 'quarterly');

insert into public.membership_plans
  (code, name, description, price_idr, duration_days, benefits, is_active, price_points, quota_amount)
values
  ('starter', 'Starter', '1 kali redeem photocard. Kuota berlaku selama 1 tahun.', 0, 365,
   '["1 kali redeem photocard","Akses kategori Collectibles","Tantangan mini-game member"]'::jsonb, true, 100, 1),
  ('fan', 'Fan', '3 kali redeem photocard. Kuota berlaku selama 1 tahun.', 0, 365,
   '["3 kali redeem photocard","Akses kategori Collectibles","Tantangan mini-game member"]'::jsonb, true, 250, 3),
  ('ultimate', 'Ultimate', '6 kali redeem photocard. Kuota berlaku selama 1 tahun.', 0, 365,
   '["6 kali redeem photocard","Akses kategori Collectibles","Tantangan mini-game member"]'::jsonb, true, 450, 6)
on conflict (code) do update set
  name = excluded.name,
  description = excluded.description,
  price_idr = 0,
  duration_days = 365,
  benefits = excluded.benefits,
  is_active = true,
  price_points = excluded.price_points,
  quota_amount = excluded.quota_amount;

create or replace function public.purchase_membership_with_points(p_plan_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_plan public.membership_plans%rowtype;
  v_membership_id uuid;
  v_expiry timestamptz;
  v_balance integer;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_plan
  from public.membership_plans
  where id = p_plan_id and is_active = true
  for update;
  if not found then
    raise exception 'Paket membership tidak tersedia';
  end if;

  insert into public.user_points(user_id, total_points)
  values (v_uid, 0)
  on conflict (user_id) do nothing;

  select total_points into v_balance
  from public.user_points
  where user_id = v_uid
  for update;

  if v_balance < v_plan.price_points then
    raise exception 'Poin tidak cukup';
  end if;

  update public.user_points
  set total_points = total_points - v_plan.price_points, updated_at = now()
  where user_id = v_uid;

  select id into v_membership_id
  from public.user_memberships
  where user_id = v_uid and status = 'active'
    and starts_at <= now() and expires_at > now()
  order by expires_at desc
  limit 1
  for update;

  v_expiry := now() + make_interval(days => v_plan.duration_days);

  if v_membership_id is null then
    insert into public.user_memberships
      (user_id, plan_id, status, starts_at, expires_at, redeem_quota)
    values
      (v_uid, v_plan.id, 'active', now(), v_expiry, v_plan.quota_amount)
    returning id into v_membership_id;
  else
    update public.user_memberships
    set plan_id = v_plan.id,
        redeem_quota = redeem_quota + v_plan.quota_amount,
        expires_at = greatest(expires_at, v_expiry)
    where id = v_membership_id;
  end if;

  insert into public.point_transactions
    (user_id, amount, transaction_type, reference_id, description)
  values
    (v_uid, -v_plan.price_points, 'membership_purchase', v_membership_id,
     'Pembelian paket membership ' || v_plan.name || ' menggunakan poin');

  perform public.append_blockchain_entry(
    'membership_points_package',
    jsonb_build_object(
      'user_id', v_uid,
      'membership_id', v_membership_id,
      'plan_id', v_plan.id,
      'points_spent', v_plan.price_points,
      'quota_added', v_plan.quota_amount
    )
  );

  return jsonb_build_object(
    'membership_id', v_membership_id,
    'points_spent', v_plan.price_points,
    'quota_added', v_plan.quota_amount,
    'status', 'active'
  );
end;
$$;

create or replace function public.redeem_photocard(p_card_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_card public.cards%rowtype;
  v_membership_id uuid;
  v_remaining integer;
  v_redemption_id uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_card
  from public.cards
  where id = p_card_id and is_available = true
  for update;
  if not found then
    raise exception 'Photocard tidak tersedia';
  end if;

  select id, redeem_quota into v_membership_id, v_remaining
  from public.user_memberships
  where user_id = v_uid and status = 'active'
    and starts_at <= now() and expires_at > now()
    and redeem_quota > 0
  order by expires_at desc
  limit 1
  for update;

  if v_membership_id is null then
    raise exception 'Kuota redeem habis. Tukarkan poin untuk membeli paket membership terlebih dahulu.';
  end if;

  if exists (
    select 1 from public.user_cards
    where user_id = v_uid and card_id = p_card_id
  ) then
    raise exception 'Photocard ini sudah kamu miliki';
  end if;

  update public.user_memberships
  set redeem_quota = redeem_quota - 1
  where id = v_membership_id
  returning redeem_quota into v_remaining;

  insert into public.user_cards(user_id, card_id, acquisition_source)
  values (v_uid, p_card_id, 'redemption');

  insert into public.redemption_transactions(user_id, card_id, points_spent)
  values (v_uid, p_card_id, 0)
  returning id into v_redemption_id;

  return jsonb_build_object(
    'redemption_id', v_redemption_id,
    'card_id', p_card_id,
    'points_spent', 0,
    'quota_remaining', v_remaining
  );
end;
$$;

grant execute on function public.purchase_membership_with_points(bigint) to authenticated;
grant execute on function public.redeem_photocard(bigint) to authenticated;
