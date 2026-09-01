-- Milestone dates now track ACTUAL start / end, not planned-vs-actual.
-- The contract makes no per-milestone date commitments; the only schedule
-- commitment is the 21-week clock from contract_meta.h1_disbursement_date
-- (which drives the delay-penalty math). So a "planned end date" was a promise
-- the owner can't make — replaced with when work on each milestone actually
-- began and finished.
alter table milestones rename column planned_date to start_date;
alter table milestones rename column actual_date to end_date;
