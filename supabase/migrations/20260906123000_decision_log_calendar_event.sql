-- Links a decision_log row to the Google Calendar reminder created for it
-- while it's awaiting confirmation. Written and cleared by a Claude Code
-- Routine (not the dashboard itself, not an Edge Function/webhook) that
-- polls decision_log and syncs unconfirmed rows to a 1pm America/Panama
-- Calendar event; the event is deleted and these columns cleared once the
-- row is confirmed. calendar_event_link is Google's own htmlLink so the
-- dashboard never has to reconstruct a Calendar URL itself.
alter table decision_log
  add column calendar_event_id text,
  add column calendar_event_link text;
