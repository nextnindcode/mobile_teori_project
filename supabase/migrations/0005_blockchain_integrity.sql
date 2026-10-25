-- Append-only integrity ledger for orders, membership payments and card redemptions.
create or replace function public.append_blockchain_entry(p_action_type text, p_transaction_data jsonb)
returns bigint
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $
declare
  v_previous text;
  v_current text;
  v_id bigint;
begin
  perform pg_advisory_xact_lock(93402026);
  select current_hash into v_previous from public.blockchain_ledger order by id desc limit 1;
  v_previous := coalesce(v_previous, repeat('0', 64));
  v_current := encode(digest(v_previous || '|' || p_transaction_data::text, 'sha256'), 'hex');
  insert into public.blockchain_ledger(user_id, action_type, transaction_data, previous_hash, current_hash)
  values (auth.uid(), p_action_type, p_transaction_data, v_previous, v_current)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.record_business_ledger_entry()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $
declare
  v_user uuid;
  v_action text;
  v_payload jsonb;
begin
  if tg_table_name = 'orders' then
    v_user := new.user_id;
    v_action := 'merchandise_order';
    v_payload := jsonb_build_object('order_id', new.id, 'user_id', new.user_id, 'total_idr', new.total_idr, 'status', new.status);
  elsif tg_table_name = 'membership_transactions' then
    v_user := new.user_id;
    v_action := 'membership_payment';
    v_payload := jsonb_build_object('transaction_id', new.id, 'user_id', new.user_id, 'plan_id', new.plan_id, 'amount_idr', new.amount_idr, 'status', new.status);
  else
    v_user := new.user_id;
    v_action := 'photocard_redemption';
    v_payload := jsonb_build_object('redemption_id', new.id, 'user_id', new.user_id, 'card_id', new.card_id, 'points_spent', new.points_spent, 'status', new.status);
  end if;

  perform pg_advisory_xact_lock(93402026);
  perform public.append_blockchain_entry(v_action, v_payload);
  return new;
end;
$$;

drop trigger if exists ledger_order_insert on public.orders;
create trigger ledger_order_insert after insert on public.orders
for each row execute function public.record_business_ledger_entry();
drop trigger if exists ledger_membership_payment_insert on public.membership_transactions;
create trigger ledger_membership_payment_insert after insert on public.membership_transactions
for each row execute function public.record_business_ledger_entry();
drop trigger if exists ledger_card_redemption_insert on public.redemption_transactions;
create trigger ledger_card_redemption_insert after insert on public.redemption_transactions
for each row execute function public.record_business_ledger_entry();

create or replace function public.verify_blockchain_ledger()
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $
declare
  v_row record;
  v_previous text := repeat('0', 64);
  v_expected text;
  v_count integer := 0;
  v_invalid bigint := null;
begin
  for v_row in select id, transaction_data, previous_hash, current_hash
               from public.blockchain_ledger order by id
  loop
    v_count := v_count + 1;
    v_expected := encode(digest(v_row.previous_hash || '|' || v_row.transaction_data::text, 'sha256'), 'hex');
    if v_row.previous_hash <> v_previous or v_row.current_hash <> v_expected then
      v_invalid := v_row.id;
      exit;
    end if;
    v_previous := v_row.current_hash;
  end loop;
  return jsonb_build_object('valid', v_invalid is null, 'block_count', v_count, 'invalid_block_id', v_invalid);
end;
$$;
revoke all on function public.verify_blockchain_ledger() from public, anon;
grant execute on function public.verify_blockchain_ledger() to authenticated;
revoke all on function public.append_blockchain_entry(text,jsonb) from public, anon, authenticated;
revoke all on function public.record_business_ledger_entry() from public, anon, authenticated;
