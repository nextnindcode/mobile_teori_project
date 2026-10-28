-- Feedback: user can submit feedback for their own account.
-- The app also displays submitted feedback, so authenticated users may read feedback.

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS feedback_read_authenticated ON public.feedback;
DROP POLICY IF EXISTS feedback_insert_own ON public.feedback;

CREATE POLICY feedback_read_authenticated
ON public.feedback
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY feedback_insert_own
ON public.feedback
FOR INSERT
TO authenticated
WITH CHECK (user_id = (SELECT auth.uid()));

GRANT SELECT, INSERT ON public.feedback TO authenticated;
