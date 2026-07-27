-- Restrict push_subscriptions.endpoint to known Web Push service origins
--
-- Closes an SSRF: `endpoint` was free text, and the send-reminders Edge
-- Function (service-role, invoked every minute) POSTs directly to it via
-- `webpush.sendNotification`. RLS on push_subscriptions only checks
-- `user_id = auth.uid()`, never the endpoint's shape, so any authenticated
-- user could write an arbitrary URL as their own subscription (e.g. a
-- cloud metadata address, or an internal-only host) — and since delivery
-- fans out to every member of a reminder's farm, one malicious row made
-- the server issue attacker-controlled outbound requests every time any
-- reminder fired anywhere in that farm. See DECISIONS.md.
--
-- These three origins cover every browser this app supports push
-- notifications on (Chrome/Edge/Opera/Brave and other Chromium browsers
-- via FCM, Firefox, and Safari/iOS — see DECISIONS.md's push-notification
-- entry). A real browser-issued PushManager subscription endpoint always
-- starts with exactly one of these, so nothing legitimate is excluded.
-- `like` is used (not a regex) so this is a plain literal-prefix check —
-- Postgres LIKE has no special meaning for `.`/`/`, and each pattern's
-- only wildcard is the trailing `%`.

alter table push_subscriptions
add constraint push_subscriptions_endpoint_allowed_origin
check (
  endpoint like 'https://fcm.googleapis.com/%'
  or endpoint like 'https://updates.push.services.mozilla.com/%'
  or endpoint like 'https://web.push.apple.com/%'
);
