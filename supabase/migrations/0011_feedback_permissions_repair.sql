-- Repair feedback table privileges and RLS for authenticated submissions.
-- Each user may insert feedback only under their own auth user ID.

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT ON TABLE public.feedback TO authenticated;

DROP POLICY IF EXISTS eclipseverse_feedback_insert_self ON public.feedback;
CREATE POLICY eclipseverse_feedback_insert_self
ON public.feedback FOR INSERT TO authenticated
WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS eclipseverse_feedback_select_authenticated ON public.feedback;
CREATE POLICY eclipseverse_feedback_select_authenticated
ON public.feedback FOR SELECT TO authenticated
USING (true);

-- Compatibility with policy names used by earlier migrations.
DROP POLICY IF EXISTS feedback_insert_own ON public.feedback;
DROP POLICY IF EXISTS feedback_read_authenticated ON public.feedback;
DROP POLICY IF EXISTS eclipseverse_feedback_insert_self ON public.feedback;
CREATE POLICY eclipseverse_feedback_insert_self
ON public.feedback FOR INSERT TO authenticated
WITH CHECK (user_id = (SELECT auth.uid()));
DROP POLICY IF EXISTS eclipseverse_feedback_select_authenticated ON public.feedback;
CREATE POLICY eclipseverse_feedback_select_authenticated
ON public.feedback FOR SELECT TO authenticated
USING (true);
