-- Allow authenticated users to submit feedback and read the public review feed.
-- Each inserted row must belong to the currently authenticated user.
alter table public.feedback enable row level security;

grant select, insert on table public.feedback to authenticated;

drop policy if exists eclipseverse_feedback_insert_self on public.feedback;
create policy eclipseverse_feedback_insert_self
on public.feedback
for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists eclipseverse_feedback_select_authenticated on public.feedback;
create policy eclipseverse_feedback_select_authenticated
on public.feedback
for select
to authenticated
using (true);
