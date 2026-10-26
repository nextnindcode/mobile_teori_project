-- Protect the member-only game challenge at the database boundary.
-- The normal quiz remains available to every authenticated user.
create or replace function public.submit_member_quiz_attempt(p_answers jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if not public.has_active_membership(auth.uid()) then
    raise exception 'Active membership required for member challenge';
  end if;
  return public.submit_quiz_attempt(p_answers);
end;
$$;
revoke all on function public.submit_member_quiz_attempt(jsonb) from public, anon;
grant execute on function public.submit_member_quiz_attempt(jsonb) to authenticated;
