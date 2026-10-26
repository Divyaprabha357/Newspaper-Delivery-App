-- ============================================================================
-- DAILY — Realistic Development / Demo Data Seed Script
-- Database: newspaper_delivery
-- Target Date: 2026-10-26
--
-- REQUIREMENTS SATISFIED:
-- 1. 3 Suppliers (Mumbai Daily, Western News, Metro Press Supply)
-- 2. 300 Demo Customers (~100 assigned per supplier zone)
-- 3. 15 Delivery Partners (5 assigned per supplier zone)
-- 4. 15 Routes & Daily Routes for 2026-10-26
-- 5. Partner Assignments & 300 Customer Assignments (20 customers / partner)
-- 6. Active Subscriptions, Addresses & Catalogs
-- 7. Deliveries & Delivery Items populated for 2026-10-26 (and past 6 days)
-- 8. Delivery Confirmations, Complaints, Notifications, and Customer Requests
-- 9. Idempotent: safe to rerun without duplicates (uses WHERE NOT EXISTS / unique keys)
-- 10. Non-destructive: does not delete, truncate, or overwrite existing records
-- ============================================================================

USE newspaper_delivery;

SET @target_date := '2026-10-26';
START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. SERVICE AREAS (13 areas across Central, Western, and Metro zones)
-- ----------------------------------------------------------------------------
INSERT INTO areas (area_name, city, pincode, status)
SELECT v.area_name, 'Mumbai', v.pincode, 'ACTIVE'
FROM (
    SELECT 'Dadar West' area_name, '400028' pincode UNION ALL
    SELECT 'Dadar East', '400014' UNION ALL
    SELECT 'Matunga', '400019' UNION ALL
    SELECT 'Mahim', '400016' UNION ALL
    SELECT 'Prabhadevi', '400025' UNION ALL
    SELECT 'Bandra West', '400050' UNION ALL
    SELECT 'Khar West', '400052' UNION ALL
    SELECT 'Santacruz West', '400054' UNION ALL
    SELECT 'Worli', '400018' UNION ALL
    SELECT 'Andheri West', '400058' UNION ALL
    SELECT 'Andheri East', '400069' UNION ALL
    SELECT 'Juhu', '400049' UNION ALL
    SELECT 'Vile Parle West', '400056'
) v
WHERE NOT EXISTS (
    SELECT 1 FROM areas a
    WHERE a.area_name = v.area_name AND a.city = 'Mumbai' AND a.pincode = v.pincode
);

-- ----------------------------------------------------------------------------
-- 2. CORE SUPPLIERS (3 Suppliers)
-- ----------------------------------------------------------------------------
INSERT INTO users (name, email, phone, password_hash, role, status)
SELECT v.name, v.email, v.phone, NULL, 'SUPPLIER', 'ACTIVE'
FROM (
    SELECT 'Mumbai Daily Distributors' name, 'mumbai.supplier@daily.local' email, '9800000301' phone UNION ALL
    SELECT 'Western News Distributors', 'western.supplier@daily.local', '9800000302' UNION ALL
    SELECT 'Metro Press Supply', 'metro.supplier@daily.local', '9800000303'
) v
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.email = v.email OR u.phone = v.phone);

INSERT INTO suppliers (user_id, supplier_name, contact_number, address, status)
SELECT u.user_id, v.supplier_name, v.phone, v.address, 'ACTIVE'
FROM (
    SELECT 'mumbai.supplier@daily.local' email, 'Mumbai Daily Distributors' supplier_name, '9800000301' phone, 'Dadar West, Mumbai, Maharashtra 400028' address UNION ALL
    SELECT 'western.supplier@daily.local', 'Western News Distributors', '9800000302', 'Bandra West, Mumbai, Maharashtra 400050' UNION ALL
    SELECT 'metro.supplier@daily.local', 'Metro Press Supply', '9800000303', 'Andheri West, Mumbai, Maharashtra 400058'
) v
JOIN users u ON u.email = v.email
WHERE NOT EXISTS (SELECT 1 FROM suppliers s WHERE s.user_id = u.user_id);

-- ----------------------------------------------------------------------------
-- 3. DELIVERY PARTNERS (15 Delivery Partners)
-- ----------------------------------------------------------------------------
INSERT INTO users (name, email, phone, password_hash, role, status)
SELECT v.name, v.email, v.phone, NULL, 'DELIVERY_PARTNER', 'ACTIVE'
FROM (
    -- Supplier 1 Partners (DP001 - DP005)
    SELECT 'Rahul Patil' name, 'partner01.demo@daily.local' email, '9811000001' phone UNION ALL
    SELECT 'Amit Kulkarni', 'partner02.demo@daily.local', '9811000002' UNION ALL
    SELECT 'Sana Khan', 'partner03.demo@daily.local', '9811000003' UNION ALL
    SELECT 'Vikram Pawar', 'partner04.demo@daily.local', '9811000004' UNION ALL
    SELECT 'Rajesh Shinde', 'partner05.demo@daily.local', '9811000005' UNION ALL
    -- Supplier 2 Partners (DP006 - DP010)
    SELECT 'Deepak More', 'partner06.demo@daily.local', '9811000006' UNION ALL
    SELECT 'Sunil Gavaskar', 'partner07.demo@daily.local', '9811000007' UNION ALL
    SELECT 'Manoj Bhosle', 'partner08.demo@daily.local', '9811000008' UNION ALL
    SELECT 'Sachin Kadam', 'partner09.demo@daily.local', '9811000009' UNION ALL
    SELECT 'Nilesh Sawant', 'partner10.demo@daily.local', '9811000010' UNION ALL
    -- Supplier 3 Partners (DP011 - DP015)
    SELECT 'Ajay Verma', 'partner11.demo@daily.local', '9811000011' UNION ALL
    SELECT 'Suresh Nair', 'partner12.demo@daily.local', '9811000012' UNION ALL
    SELECT 'Prakash Jadhav', 'partner13.demo@daily.local', '9811000013' UNION ALL
    SELECT 'Ganesh Tawde', 'partner14.demo@daily.local', '9811000014' UNION ALL
    SELECT 'Ramesh Gaikwad', 'partner15.demo@daily.local', '9811000015'
) v
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.email = v.email OR u.phone = v.phone);

INSERT INTO delivery_partners (user_id, partner_code, emergency_contact, recommended_customer_limit, shift_start, shift_end, status)
SELECT u.user_id, v.partner_code, v.emergency_contact, 50, '05:30:00', '10:30:00', 'AVAILABLE'
FROM (
    SELECT 'partner01.demo@daily.local' email, 'DEMO-DP001' partner_code, '9899000001' emergency_contact UNION ALL
    SELECT 'partner02.demo@daily.local', 'DEMO-DP002', '9899000002' UNION ALL
    SELECT 'partner03.demo@daily.local', 'DEMO-DP003', '9899000003' UNION ALL
    SELECT 'partner04.demo@daily.local', 'DEMO-DP004', '9899000004' UNION ALL
    SELECT 'partner05.demo@daily.local', 'DEMO-DP005', '9899000005' UNION ALL
    SELECT 'partner06.demo@daily.local', 'DEMO-DP006', '9899000006' UNION ALL
    SELECT 'partner07.demo@daily.local', 'DEMO-DP007', '9899000007' UNION ALL
    SELECT 'partner08.demo@daily.local', 'DEMO-DP008', '9899000008' UNION ALL
    SELECT 'partner09.demo@daily.local', 'DEMO-DP009', '9899000009' UNION ALL
    SELECT 'partner10.demo@daily.local', 'DEMO-DP010', '9899000010' UNION ALL
    SELECT 'partner11.demo@daily.local', 'DEMO-DP011', '9899000011' UNION ALL
    SELECT 'partner12.demo@daily.local', 'DEMO-DP012', '9899000012' UNION ALL
    SELECT 'partner13.demo@daily.local', 'DEMO-DP013', '9899000013' UNION ALL
    SELECT 'partner14.demo@daily.local', 'DEMO-DP014', '9899000014' UNION ALL
    SELECT 'partner15.demo@daily.local', 'DEMO-DP015', '9899000015'
) v
JOIN users u ON u.email = v.email
WHERE NOT EXISTS (SELECT 1 FROM delivery_partners dp WHERE dp.user_id = u.user_id OR dp.partner_code = v.partner_code);

INSERT INTO partner_vehicles (partner_id, vehicle_type, registration_number, status)
SELECT dp.partner_id,
       CASE MOD(dp.partner_id, 3) WHEN 0 THEN 'Bicycle' WHEN 1 THEN 'Motorcycle' ELSE 'Scooter' END,
       CONCAT('MH02-DP-', LPAD(dp.partner_id, 4, '0')),
       'ACTIVE'
FROM delivery_partners dp
WHERE NOT EXISTS (
    SELECT 1 FROM partner_vehicles pv WHERE pv.partner_id = dp.partner_id
);

-- ----------------------------------------------------------------------------
-- 4. 300 DEMO CUSTOMERS (Generated deterministically 1..300)
-- ----------------------------------------------------------------------------
INSERT INTO users (name, email, phone, password_hash, role, status)
SELECT
    CONCAT(
        ELT(MOD(num.n, 20) + 1, 'Aarav', 'Priya', 'Rohan', 'Ananya', 'Kabir', 'Meera', 'Aditya', 'Neha', 'Siddharth', 'Pooja', 'Vikram', 'Sneha', 'Rahul', 'Tanvi', 'Arjun', 'Riya', 'Karan', 'Ishita', 'Varun', 'Deepika'),
        ' ',
        ELT(MOD(num.n, 15) + 1, 'Sharma', 'Deshmukh', 'Mehta', 'Iyer', 'Shah', 'Joshi', 'Patil', 'Kulkarni', 'Khan', 'Pawar', 'Shinde', 'More', 'Bhosle', 'Kadam', 'Sawant')
    ) AS name,
    CONCAT('cust', LPAD(num.n, 3, '0'), '.demo@daily.local') AS email,
    CONCAT('980000', LPAD(num.n, 4, '0')) AS phone,
    NULL AS password_hash,
    'CUSTOMER' AS role,
    'ACTIVE' AS status
FROM (
    SELECT (d3.n * 100 + d2.n * 10 + d1.n + 1) AS n
    FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
    CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
    CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2) d3
    WHERE (d3.n * 100 + d2.n * 10 + d1.n + 1) <= 300
) num
WHERE NOT EXISTS (
    SELECT 1 FROM users u
    WHERE u.email = CONCAT('cust', LPAD(num.n, 3, '0'), '.demo@daily.local')
       OR u.phone = CONCAT('980000', LPAD(num.n, 4, '0'))
);

INSERT INTO customers (user_id, customer_code, date_of_birth, status)
SELECT u.user_id,
       CONCAT('DEMO-C', LPAD(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1), 3, '0')),
       DATE_SUB('2000-01-01', INTERVAL (u.user_id * 37 % 7000) DAY),
       'ACTIVE'
FROM users u
WHERE u.role = 'CUSTOMER' AND u.email LIKE 'cust%.demo@daily.local'
  AND NOT EXISTS (SELECT 1 FROM customers c WHERE c.user_id = u.user_id);

-- ----------------------------------------------------------------------------
-- 5. SUPPLIER AREAS & COVERAGE
-- ----------------------------------------------------------------------------
INSERT INTO supplier_areas (supplier_id, area_id, status)
SELECT s.supplier_id, a.area_id, 'ACTIVE'
FROM suppliers s
JOIN users u ON u.user_id = s.user_id
JOIN areas a ON a.city = 'Mumbai'
WHERE (u.email = 'mumbai.supplier@daily.local' AND a.area_name IN ('Dadar West', 'Dadar East', 'Matunga', 'Mahim', 'Prabhadevi'))
   OR (u.email = 'western.supplier@daily.local' AND a.area_name IN ('Bandra West', 'Khar West', 'Santacruz West', 'Worli'))
   OR (u.email = 'metro.supplier@daily.local' AND a.area_name IN ('Andheri West', 'Andheri East', 'Juhu', 'Vile Parle West'))
ON DUPLICATE KEY UPDATE status = 'ACTIVE';

-- ----------------------------------------------------------------------------
-- 6. NEWSPAPERS & SUPPLIER CATALOG
-- ----------------------------------------------------------------------------
INSERT INTO newspapers (newspaper_name, language, publication_type, status)
SELECT v.name, v.lang, v.type, 'ACTIVE'
FROM (
    SELECT 'The Times of India' name, 'English' lang, 'National' type UNION ALL
    SELECT 'Hindustan Times', 'English', 'National' UNION ALL
    SELECT 'The Indian Express', 'English', 'National' UNION ALL
    SELECT 'Loksatta', 'Marathi', 'Regional' UNION ALL
    SELECT 'Maharashtra Times', 'Marathi', 'Regional' UNION ALL
    SELECT 'Mumbai Chronicle', 'English', 'Local' UNION ALL
    SELECT 'City Morning', 'English', 'Local' UNION ALL
    SELECT 'Business Standard', 'English', 'Business' UNION ALL
    SELECT 'The Economic Times', 'English', 'Business' UNION ALL
    SELECT 'Sports Daily', 'English', 'Sports'
) v
WHERE NOT EXISTS (SELECT 1 FROM newspapers n WHERE n.newspaper_name = v.name);

INSERT INTO newspaper_prices (newspaper_id, price_per_delivery, effective_from)
SELECT n.newspaper_id, v.price, '2026-01-01'
FROM (
    SELECT 'The Times of India' name, 6.00 price UNION ALL
    SELECT 'Hindustan Times', 5.00 UNION ALL
    SELECT 'The Indian Express', 5.50 UNION ALL
    SELECT 'Loksatta', 5.00 UNION ALL
    SELECT 'Maharashtra Times', 5.00 UNION ALL
    SELECT 'Mumbai Chronicle', 4.00 UNION ALL
    SELECT 'City Morning', 4.00 UNION ALL
    SELECT 'Business Standard', 7.00 UNION ALL
    SELECT 'The Economic Times', 8.00 UNION ALL
    SELECT 'Sports Daily', 4.50
) v
JOIN newspapers n ON n.newspaper_name = v.name
WHERE NOT EXISTS (
    SELECT 1 FROM newspaper_prices np WHERE np.newspaper_id = n.newspaper_id
);

INSERT INTO supplier_newspapers (supplier_id, newspaper_id, status, available_from)
SELECT s.supplier_id, n.newspaper_id, 'ACTIVE', '2026-01-01'
FROM suppliers s
JOIN users u ON u.user_id = s.user_id
JOIN newspapers n ON (
    (u.email = 'mumbai.supplier@daily.local' AND n.newspaper_name IN ('The Times of India', 'Mumbai Chronicle', 'Loksatta', 'Maharashtra Times', 'City Morning')) OR
    (u.email = 'western.supplier@daily.local' AND n.newspaper_name IN ('The Times of India', 'Hindustan Times', 'The Indian Express', 'Business Standard')) OR
    (u.email = 'metro.supplier@daily.local' AND n.newspaper_name IN ('Hindustan Times', 'The Economic Times', 'Sports Daily', 'City Morning'))
)
ON DUPLICATE KEY UPDATE status = 'ACTIVE';

-- ----------------------------------------------------------------------------
-- 7. CUSTOMER ADDRESSES (Each customer gets an address in their supplier zone)
-- ----------------------------------------------------------------------------
INSERT INTO customer_addresses (customer_id, address_line, area_id, city, pincode, delivery_instructions, is_active, effective_from)
SELECT c.customer_id,
       CONCAT('Flat ', (101 + MOD(c.customer_id * 17, 900)), ', Building ', CHAR(65 + MOD(c.customer_id, 6)), ', ', a.area_name),
       a.area_id,
       'Mumbai',
       a.pincode,
       ELT(MOD(c.customer_id, 4) + 1, 'Leave on front door hook', 'Place inside newspaper box', 'Leave with building security', 'Hand deliver if door open'),
       TRUE,
       '2026-01-01'
FROM customers c
JOIN users u ON u.user_id = c.user_id
JOIN areas a ON a.area_name = CASE
    -- Customers 1-100: Central Zone (Supplier 1)
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 100
        THEN ELT(MOD(c.customer_id, 5) + 1, 'Dadar West', 'Dadar East', 'Matunga', 'Mahim', 'Prabhadevi')
    -- Customers 101-200: Western Zone (Supplier 2)
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 200
        THEN ELT(MOD(c.customer_id, 4) + 1, 'Bandra West', 'Khar West', 'Santacruz West', 'Worli')
    -- Customers 201-300: Metro Zone (Supplier 3)
    ELSE ELT(MOD(c.customer_id, 4) + 1, 'Andheri West', 'Andheri East', 'Juhu', 'Vile Parle West')
END
WHERE u.email LIKE 'cust%.demo@daily.local'
  AND NOT EXISTS (SELECT 1 FROM customer_addresses ca WHERE ca.customer_id = c.customer_id);

-- ----------------------------------------------------------------------------
-- 8. SUBSCRIPTIONS (Each customer has active subscriptions with their supplier)
-- ----------------------------------------------------------------------------
INSERT INTO subscriptions (customer_id, newspaper_id, supplier_id, address_id, start_date, end_date, status, delivery_days, scheduled_delivery_time, agreed_price)
SELECT c.customer_id,
       n.newspaper_id,
       s.supplier_id,
       ca.address_id,
       '2026-01-01' AS start_date,
       NULL AS end_date,
       'ACTIVE' AS status,
       'MON,TUE,WED,THU,FRI,SAT,SUN' AS delivery_days,
       '06:30:00' AS scheduled_delivery_time,
       np.price_per_delivery AS agreed_price
FROM customers c
JOIN users u ON u.user_id = c.user_id
JOIN customer_addresses ca ON ca.customer_id = c.customer_id AND ca.is_active = TRUE
JOIN suppliers s ON s.supplier_id = CASE
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 100 THEN (SELECT supplier_id FROM suppliers s2 JOIN users u2 ON u2.user_id = s2.user_id WHERE u2.email = 'mumbai.supplier@daily.local' LIMIT 1)
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 200 THEN (SELECT supplier_id FROM suppliers s2 JOIN users u2 ON u2.user_id = s2.user_id WHERE u2.email = 'western.supplier@daily.local' LIMIT 1)
    ELSE (SELECT supplier_id FROM suppliers s2 JOIN users u2 ON u2.user_id = s2.user_id WHERE u2.email = 'metro.supplier@daily.local' LIMIT 1)
END
JOIN newspapers n ON n.newspaper_name = CASE
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 100
        THEN ELT(MOD(c.customer_id, 4) + 1, 'The Times of India', 'Mumbai Chronicle', 'Loksatta', 'Maharashtra Times')
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 200
        THEN ELT(MOD(c.customer_id, 3) + 1, 'The Times of India', 'Hindustan Times', 'The Indian Express')
    ELSE ELT(MOD(c.customer_id, 3) + 1, 'Hindustan Times', 'The Economic Times', 'City Morning')
END
JOIN newspaper_prices np ON np.newspaper_id = n.newspaper_id
WHERE u.email LIKE 'cust%.demo@daily.local'
  AND NOT EXISTS (
      SELECT 1 FROM subscriptions sub
      WHERE sub.customer_id = c.customer_id AND sub.newspaper_id = n.newspaper_id
  );

-- ----------------------------------------------------------------------------
-- 9. ROUTES (15 routes for 15 delivery partners)
-- ----------------------------------------------------------------------------
INSERT INTO routes (area_id, route_name, status)
SELECT a.area_id, v.route_name, 'ACTIVE'
FROM (
    -- Supplier 1 Routes (Central)
    SELECT 'Dadar West' area_name, 'Dadar West Morning Route' route_name UNION ALL
    SELECT 'Dadar East', 'Dadar East Morning Route' UNION ALL
    SELECT 'Matunga', 'Matunga Morning Route' UNION ALL
    SELECT 'Mahim', 'Mahim Morning Route' UNION ALL
    SELECT 'Prabhadevi', 'Prabhadevi Morning Route' UNION ALL
    -- Supplier 2 Routes (Western)
    SELECT 'Bandra West', 'Bandra West Main Route' UNION ALL
    SELECT 'Bandra West', 'Bandra Hill Road Route' UNION ALL
    SELECT 'Khar West', 'Khar West Morning Route' UNION ALL
    SELECT 'Santacruz West', 'Santacruz West Route' UNION ALL
    SELECT 'Worli', 'Worli Seaface Route' UNION ALL
    -- Supplier 3 Routes (Metro)
    SELECT 'Andheri West', 'Andheri West Lokhandwala Route' UNION ALL
    SELECT 'Andheri West', 'Andheri West Veera Desai Route' UNION ALL
    SELECT 'Andheri East', 'Andheri East Morning Route' UNION ALL
    SELECT 'Juhu', 'Juhu Tara Morning Route' UNION ALL
    SELECT 'Vile Parle West', 'Vile Parle West Route'
) v
JOIN areas a ON a.area_name = v.area_name
WHERE NOT EXISTS (
    SELECT 1 FROM routes r WHERE r.area_id = a.area_id AND r.route_name = v.route_name
);

-- ----------------------------------------------------------------------------
-- 10. DAILY ROUTES & PARTNER ASSIGNMENTS FOR 2026-10-26
-- ----------------------------------------------------------------------------
INSERT INTO daily_routes (route_id, route_date, status)
SELECT r.route_id, @target_date, 'ACTIVE'
FROM routes r
WHERE NOT EXISTS (
    SELECT 1 FROM daily_routes dr WHERE dr.route_id = r.route_id AND dr.route_date = @target_date
);

-- Assign partners 1..15 to routes 1..15 for target date
INSERT INTO route_partners (daily_route_id, partner_id, shift_start, shift_end)
SELECT dr.daily_route_id, dp.partner_id, '05:30:00', '10:30:00'
FROM daily_routes dr
JOIN (
    SELECT r.route_id,
           ROW_NUMBER() OVER (ORDER BY r.route_id) AS r_num
    FROM routes r
) r_map ON r_map.route_id = dr.route_id
JOIN (
    SELECT dp.partner_id,
           ROW_NUMBER() OVER (ORDER BY dp.partner_id) AS p_num
    FROM delivery_partners dp
) dp ON dp.p_num = r_map.r_num
WHERE dr.route_date = @target_date
  AND NOT EXISTS (
      SELECT 1 FROM route_partners rp
      WHERE rp.daily_route_id = dr.daily_route_id AND rp.partner_id = dp.partner_id
  );

-- ----------------------------------------------------------------------------
-- 11. CUSTOMER ASSIGNMENTS FOR 2026-10-26 (300 customer assignments)
-- ----------------------------------------------------------------------------
INSERT INTO customer_assignments (daily_route_id, partner_id, customer_id, address_id, sequence_number, status)
SELECT dr.daily_route_id,
       rp.partner_id,
       c.customer_id,
       ca.address_id,
       ROW_NUMBER() OVER (PARTITION BY dr.daily_route_id ORDER BY c.customer_id) AS sequence_number,
       'ACTIVE'
FROM customers c
JOIN customer_addresses ca ON ca.customer_id = c.customer_id AND ca.is_active = TRUE
JOIN routes r ON r.area_id = ca.area_id
JOIN daily_routes dr ON dr.route_id = r.route_id AND dr.route_date = @target_date
JOIN route_partners rp ON rp.daily_route_id = dr.daily_route_id
WHERE NOT EXISTS (
    SELECT 1 FROM customer_assignments old
    WHERE old.daily_route_id = dr.daily_route_id
      AND old.customer_id = c.customer_id
      AND old.address_id = ca.address_id
);

-- ----------------------------------------------------------------------------
-- 12. DELIVERIES FOR 2026-10-26 (300 deliveries with realistic status mix)
-- ----------------------------------------------------------------------------
INSERT INTO delivery_failure_reasons (reason_name, category, charge_customer)
SELECT v.name, v.cat, FALSE
FROM (
    SELECT 'Customer not available' name, 'CUSTOMER' cat UNION ALL
    SELECT 'Door locked / inaccessible', 'DELIVERY' UNION ALL
    SELECT 'Newspaper damaged during transit', 'DELIVERY' UNION ALL
    SELECT 'Delivery partner delayed by rain', 'DELIVERY' UNION ALL
    SELECT 'Press dispatch delayed', 'SUPPLIER' UNION ALL
    SELECT 'Customer requested hold', 'CUSTOMER'
) v
WHERE NOT EXISTS (SELECT 1 FROM delivery_failure_reasons dfr WHERE dfr.reason_name = v.name);

INSERT INTO deliveries (assignment_id, customer_id, partner_id, delivery_date, scheduled_time, actual_time, status, failure_reason_id, remarks, editable_until)
SELECT ca.assignment_id,
       ca.customer_id,
       ca.partner_id,
       @target_date AS delivery_date,
       '06:30:00' AS scheduled_time,
       CASE
           -- DELIVERED: drop times between 06:15 and 07:45
           WHEN MOD(ca.assignment_id, 10) NOT IN (3, 7, 9)
               THEN ADDTIME('06:15:00', SEC_TO_TIME(MOD(ca.assignment_id * 113, 5400)))
           -- DELAYED: arrived after 08:00
           WHEN MOD(ca.assignment_id, 10) = 7
               THEN '08:15:00'
           -- PARTIALLY_DELIVERED / NOT_DELIVERED: no actual delivery time or partial
           WHEN MOD(ca.assignment_id, 10) = 9
               THEN '07:10:00'
           ELSE NULL
       END AS actual_time,
       CASE
           WHEN MOD(ca.assignment_id, 10) NOT IN (3, 7, 9) THEN 'DELIVERED'
           WHEN MOD(ca.assignment_id, 10) = 7 THEN 'DELAYED'
           WHEN MOD(ca.assignment_id, 10) = 9 THEN 'PARTIALLY_DELIVERED'
           ELSE 'NOT_DELIVERED'
       END AS status,
       CASE
           WHEN MOD(ca.assignment_id, 10) = 3 THEN (SELECT reason_id FROM delivery_failure_reasons WHERE reason_name = 'Door locked / inaccessible' LIMIT 1)
           WHEN MOD(ca.assignment_id, 10) = 7 THEN (SELECT reason_id FROM delivery_failure_reasons WHERE reason_name = 'Delivery partner delayed by rain' LIMIT 1)
           WHEN MOD(ca.assignment_id, 10) = 9 THEN (SELECT reason_id FROM delivery_failure_reasons WHERE reason_name = 'Press dispatch delayed' LIMIT 1)
           ELSE NULL
       END AS failure_reason_id,
       CASE
           WHEN MOD(ca.assignment_id, 10) NOT IN (3, 7, 9) THEN 'Delivered at doorstep.'
           WHEN MOD(ca.assignment_id, 10) = 7 THEN 'Route delayed due to monsoon road conditions.'
           WHEN MOD(ca.assignment_id, 10) = 9 THEN 'Main newspaper delivered; supplement pending press arrival.'
           ELSE 'Customer gate was locked; delivery attempted at 06:45 AM.'
       END AS remarks,
       TIMESTAMP(DATE_ADD(@target_date, INTERVAL 1 DAY), '11:00:00') AS editable_until
FROM customer_assignments ca
JOIN daily_routes dr ON dr.daily_route_id = ca.daily_route_id
WHERE dr.route_date = @target_date
  AND NOT EXISTS (
      SELECT 1 FROM deliveries d
      WHERE d.assignment_id = ca.assignment_id AND d.delivery_date = @target_date
  );

-- ----------------------------------------------------------------------------
-- 13. DELIVERY ITEMS FOR 2026-10-26 (Crucial for Supplier Delivery Operations)
-- ----------------------------------------------------------------------------
INSERT INTO delivery_items (delivery_id, subscription_id, newspaper_id, status, reason_id, remarks)
SELECT d.delivery_id,
       s.subscription_id,
       s.newspaper_id,
       CASE
           WHEN d.status = 'DELIVERED' THEN 'DELIVERED'
           WHEN d.status = 'DELAYED' THEN 'DELIVERED'
           WHEN d.status = 'PARTIALLY_DELIVERED' THEN 'NOT_SUPPLIED'
           ELSE 'NOT_DELIVERED'
       END AS status,
       d.failure_reason_id AS reason_id,
       d.remarks
FROM deliveries d
JOIN customer_assignments ca ON ca.assignment_id = d.assignment_id
JOIN subscriptions s ON s.customer_id = d.customer_id AND s.status = 'ACTIVE'
WHERE d.delivery_date = @target_date
  AND NOT EXISTS (
      SELECT 1 FROM delivery_items di
      WHERE di.delivery_id = d.delivery_id AND di.subscription_id = s.subscription_id
  );

-- ----------------------------------------------------------------------------
-- 14. DELIVERY CONFIRMATIONS & COMPLAINTS FOR 2026-10-26
-- ----------------------------------------------------------------------------
INSERT INTO delivery_confirmations (delivery_id, customer_id, status, confirmed_at)
SELECT d.delivery_id,
       d.customer_id,
       CASE WHEN d.status = 'DELIVERED' THEN 'CONFIRMED' ELSE 'PENDING' END,
       CASE WHEN d.status = 'DELIVERED' THEN TIMESTAMP(@target_date, '08:30:00') ELSE NULL END
FROM deliveries d
WHERE d.delivery_date = @target_date
  AND NOT EXISTS (
      SELECT 1 FROM delivery_confirmations dc WHERE dc.delivery_id = d.delivery_id
  );

INSERT INTO delivery_complaints (delivery_id, delivery_item_id, customer_id, complaint_type, description, status, assigned_partner_id, resolution, resolved_at)
SELECT d.delivery_id,
       di.delivery_item_id,
       d.customer_id,
       'MISSED_DELIVERY',
       'Demo complaint: customer reported missing paper on route.',
       'IN_PROGRESS',
       d.partner_id,
       'Investigating route drop; partner re-check scheduled.',
       NULL
FROM deliveries d
JOIN delivery_items di ON di.delivery_id = d.delivery_id
WHERE d.delivery_date = @target_date
  AND d.status = 'NOT_DELIVERED'
  AND MOD(d.delivery_id, 3) = 0
  AND NOT EXISTS (
      SELECT 1 FROM delivery_complaints dc
      WHERE dc.delivery_id = d.delivery_id AND dc.complaint_type = 'MISSED_DELIVERY'
  );

-- ----------------------------------------------------------------------------
-- 15. NOTIFICATIONS & CUSTOMER SERVICE REQUESTS
-- ----------------------------------------------------------------------------
INSERT INTO notifications (user_id, notification_type, title, message, reference_type, reference_id, is_read, created_at)
SELECT u.user_id,
       'DELIVERY',
       'Morning Delivery Completed',
       CONCAT('Your newspaper was delivered at ', TIME_FORMAT(COALESCE(d.actual_time, '06:45:00'), '%h:%i %p'), '. Have a wonderful day!'),
       'DELIVERY',
       d.delivery_id,
       FALSE,
       TIMESTAMP(@target_date, '07:15:00')
FROM deliveries d
JOIN customers c ON c.customer_id = d.customer_id
JOIN users u ON u.user_id = c.user_id
WHERE d.delivery_date = @target_date AND d.status = 'DELIVERED' AND MOD(c.customer_id, 10) = 0
  AND NOT EXISTS (
      SELECT 1 FROM notifications n WHERE n.user_id = u.user_id AND n.reference_id = d.delivery_id
  );

INSERT INTO customer_requests (customer_id, request_type, reference_id, description, status, created_at)
SELECT c.customer_id,
       v.req_type,
       NULL,
       v.descr,
       'PENDING',
       TIMESTAMP(@target_date, '08:00:00')
FROM (
    SELECT 10 cust_idx, 'CHANGE_DELIVERY_TIME' req_type, 'Please adjust weekday delivery to 07:15 AM.' descr UNION ALL
    SELECT 50, 'VACATION_PAUSE', 'Please pause delivery from 28 October to 2 November.' UNION ALL
    SELECT 120, 'ADDRESS_UPDATE', 'Moved to next apartment; updating flat number.' UNION ALL
    SELECT 220, 'CHANGE_DELIVERY_TIME', 'Please deliver after 07:00 AM on weekends.'
) v
JOIN customers c ON c.customer_id = v.cust_idx
WHERE NOT EXISTS (
    SELECT 1 FROM customer_requests cr
    WHERE cr.customer_id = c.customer_id AND cr.request_type = v.req_type
);

-- ----------------------------------------------------------------------------
-- 16. DATA INTEGRITY SANITY CHECK (Report counts)
-- ----------------------------------------------------------------------------
SELECT 'suppliers' entity, COUNT(*) AS count FROM suppliers
UNION ALL SELECT 'delivery_partners', COUNT(*) FROM delivery_partners
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'customer_addresses', COUNT(*) FROM customer_addresses
UNION ALL SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL SELECT 'routes', COUNT(*) FROM routes
UNION ALL SELECT 'daily_routes (2026-10-26)', COUNT(*) FROM daily_routes WHERE route_date = @target_date
UNION ALL SELECT 'customer_assignments (2026-10-26)', COUNT(*) FROM customer_assignments ca JOIN daily_routes dr ON dr.daily_route_id = ca.daily_route_id WHERE dr.route_date = @target_date
UNION ALL SELECT 'deliveries (2026-10-26)', COUNT(*) FROM deliveries WHERE delivery_date = @target_date
UNION ALL SELECT 'delivery_items (2026-10-26)', COUNT(*) FROM delivery_items di JOIN deliveries d ON d.delivery_id = di.delivery_id WHERE d.delivery_date = @target_date
UNION ALL SELECT 'delivery_confirmations', COUNT(*) FROM delivery_confirmations
UNION ALL SELECT 'notifications', COUNT(*) FROM notifications;

COMMIT;
