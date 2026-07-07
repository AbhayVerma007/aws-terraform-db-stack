INSERT INTO users (email, full_name)
VALUES
  ('alice@example.com', 'Alice Johnson'),
  ('bob@example.com', 'Bob Smith'),
  ('carol@example.com', 'Carol Lee')
ON CONFLICT (email) DO NOTHING;

INSERT INTO login_events (user_id, event_type, event_at)
SELECT id, 'login', NOW() - INTERVAL '1 day'
FROM users
ON CONFLICT DO NOTHING;
