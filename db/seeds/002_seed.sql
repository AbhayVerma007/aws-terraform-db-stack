-- Generate 120 randomized hotel bookings
INSERT INTO hotel_bookings (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT 
    gen_random_uuid(), 
    (ARRAY[gen_random_uuid(), gen_random_uuid(), gen_random_uuid()])[floor(random() * 3 + 1)], -- 3 random Orgs
    'HOTEL-' || floor(random() * 10 + 1)::text,
    (ARRAY['delhi', 'mumbai', 'bangalore', 'pune'])[floor(random() * 4 + 1)], -- Multiple cities
    CURRENT_DATE + (random() * 10)::int,
    CURRENT_DATE + 15 + (random() * 10)::int,
    (random() * 5000 + 1000)::numeric(12,2),
    (ARRAY['CONFIRMED', 'CANCELLED', 'PENDING'])[floor(random() * 3 + 1)], -- Multiple statuses
    NOW() - (random() * interval '45 days') -- Dates spread over the last 45 days
FROM generate_series(1, 120);

-- Generate booking events for roughly half of the bookings
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT 
    id, 
    'BOOKING_CREATED', 
    '{"source": "web", "platform": "desktop"}'::jsonb,
    created_at + interval '1 hour'
FROM hotel_bookings
WHERE random() > 0.5;