-- ============================================================================
-- DAILY — Realistic Development / Demo Data Seed Script
-- Database: newspaper_delivery
-- Target Dates: 2026-10-28 (Today) and 2026-10-26
--
-- REQUIREMENTS SATISFIED:
-- 1. 3 Suppliers (Mumbai Daily, Western News, Metro Press Supply)
-- 2. 300 Demo Customers (~100 assigned per supplier zone)
-- 3. 15 Delivery Partners (5 assigned per supplier zone)
-- 4. 15 Routes & Daily Routes for target date
-- 5. Partner Assignments & 300 Customer Assignments (20 customers / partner)
-- 6. Active Subscriptions, Addresses & Catalogs
-- 7. Deliveries & Delivery Items populated for 2026-10-28 (and 2026-10-26)
-- 8. Delivery Confirmations, Notifications, and Customer Requests
-- 9. Idempotent: safe to rerun without duplicates (uses WHERE NOT EXISTS / unique keys)
-- 10. Non-destructive: does not delete, truncate, or overwrite existing records
-- ============================================================================

USE newspaper_delivery;

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
-- 2. CORE SUPPLIERS (Ensure Supplier 1, Supplier 2, and Supplier 3 exist)
-- ----------------------------------------------------------------------------
-- Supplier 1 (Mumbai Daily Distributors) and Supplier 2 (Western News Distributors)
-- already exist in the database (user_id 5 and 6, supplier_id 1 and 2).
-- Insert Supplier 3 (Metro Press Supply) only if missing:
INSERT INTO users (name, email, phone, password_hash, role, status)
SELECT 'Metro Press Supply', 'metro.supplier@daily.local', '9800000303', NULL, 'SUPPLIER', 'ACTIVE'
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE email = 'metro.supplier@daily.local' OR phone = '9800000303'
);

INSERT INTO suppliers (user_id, supplier_name, contact_number, address, status)
SELECT u.user_id, 'Metro Press Supply', '9800000303', 'Andheri West, Mumbai, Maharashtra 400058', 'ACTIVE'
FROM users u
WHERE u.email = 'metro.supplier@daily.local'
  AND NOT EXISTS (SELECT 1 FROM suppliers s WHERE s.user_id = u.user_id);

-- Dynamically resolve supplier IDs
SELECT COALESCE((SELECT supplier_id FROM suppliers WHERE supplier_id = 1), 1) INTO @supp1_id;
SELECT COALESCE((SELECT supplier_id FROM suppliers WHERE supplier_id = 2), 2) INTO @supp2_id;
SELECT COALESCE(
    (SELECT s.supplier_id FROM suppliers s JOIN users u ON u.user_id = s.user_id WHERE u.email = 'metro.supplier@daily.local' LIMIT 1),
    (SELECT supplier_id FROM suppliers ORDER BY supplier_id DESC LIMIT 1)
) INTO @supp3_id;

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
SELECT v.supplier_id, a.area_id, 'ACTIVE'
FROM (
    SELECT @supp1_id AS supplier_id, a.area_id
    FROM areas a
    WHERE a.area_name IN ('Dadar West', 'Dadar East', 'Matunga', 'Mahim', 'Prabhadevi')
    UNION ALL
    SELECT @supp2_id AS supplier_id, a.area_id
    FROM areas a
    WHERE a.area_name IN ('Bandra West', 'Khar West', 'Santacruz West', 'Worli')
    UNION ALL
    SELECT @supp3_id AS supplier_id, a.area_id
    FROM areas a
    WHERE a.area_name IN ('Andheri West', 'Andheri East', 'Juhu', 'Vile Parle West')
) v
JOIN areas a ON a.area_id = v.area_id
JOIN suppliers s ON s.supplier_id = v.supplier_id
ON DUPLICATE KEY UPDATE status = 'ACTIVE';

-- ----------------------------------------------------------------------------
-- 6. NEWSPAPERS & SUPPLIER CATALOG
-- ----------------------------------------------------------------------------
INSERT INTO newspaper_prices (newspaper_id, price_per_delivery, effective_from)
SELECT n.newspaper_id, v.price, '2026-01-01'
FROM (
    SELECT 'The Times of India' name, 6.00 price UNION ALL
    SELECT 'Hindustan Times', 5.00 UNION ALL
    SELECT 'Loksatta', 5.00 UNION ALL
    SELECT 'Mumbai Chronicle', 4.00 UNION ALL
    SELECT 'Maharashtra Today', 4.50 UNION ALL
    SELECT 'City Morning', 4.00 UNION ALL
    SELECT 'The Daily Herald', 5.50
) v
JOIN newspapers n ON n.newspaper_name = v.name
WHERE NOT EXISTS (
    SELECT 1 FROM newspaper_prices np WHERE np.newspaper_id = n.newspaper_id
);

INSERT INTO supplier_newspapers (supplier_id, newspaper_id, status, available_from)
SELECT v.supplier_id, n.newspaper_id, 'ACTIVE', '2026-01-01'
FROM (
    SELECT @supp1_id AS supplier_id, n.newspaper_id
    FROM newspapers n
    WHERE n.newspaper_name IN ('The Times of India', 'Mumbai Chronicle', 'Loksatta', 'Maharashtra Today', 'City Morning')
    UNION ALL
    SELECT @supp2_id AS supplier_id, n.newspaper_id
    FROM newspapers n
    WHERE n.newspaper_name IN ('The Times of India', 'Hindustan Times', 'The Daily Herald', 'Loksatta')
    UNION ALL
    SELECT @supp3_id AS supplier_id, n.newspaper_id
    FROM newspapers n
    WHERE n.newspaper_name IN ('Hindustan Times', 'City Morning', 'The Daily Herald', 'Maharashtra Today')
) v
JOIN newspapers n ON n.newspaper_id = v.newspaper_id
JOIN suppliers s ON s.supplier_id = v.supplier_id
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
    -- Customers 1-100: Central Zone (Supplier 1: Mumbai Daily)
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 100
        THEN ELT(MOD(c.customer_id, 5) + 1, 'Dadar West', 'Dadar East', 'Matunga', 'Mahim', 'Prabhadevi')
    -- Customers 101-200: Western Zone (Supplier 2: Western News)
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 200
        THEN ELT(MOD(c.customer_id, 4) + 1, 'Bandra West', 'Khar West', 'Santacruz West', 'Worli')
    -- Customers 201-300: Metro Zone (Supplier 3: Metro Press)
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
       CASE
           WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 100 THEN @supp1_id
           WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 200 THEN @supp2_id
           ELSE @supp3_id
       END AS supplier_id,
       ca.address_id,
       '2026-01-01' AS start_date,
       NULL AS end_date,
       'ACTIVE' AS status,
       'MON,TUE,WED,THU,FRI,SAT,SUN' AS delivery_days,
       '06:30:00' AS scheduled_delivery_time,
       COALESCE(np.price_per_delivery, 5.00) AS agreed_price
FROM customers c
JOIN users u ON u.user_id = c.user_id
JOIN customer_addresses ca ON ca.customer_id = c.customer_id AND ca.is_active = TRUE
JOIN newspapers n ON n.newspaper_name = CASE
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 100
        THEN ELT(MOD(c.customer_id, 4) + 1, 'The Times of India', 'Mumbai Chronicle', 'Loksatta', 'Maharashtra Today')
    WHEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.email, '@', 1), 'cust', -1) AS UNSIGNED) <= 200
        THEN ELT(MOD(c.customer_id, 3) + 1, 'The Times of India', 'Hindustan Times', 'The Daily Herald')
    ELSE ELT(MOD(c.customer_id, 3) + 1, 'Hindustan Times', 'City Morning', 'Maharashtra Today')
END
LEFT JOIN newspaper_prices np ON np.newspaper_id = n.newspaper_id
WHERE u.email LIKE 'cust%.demo@daily.local'
  AND NOT EXISTS (
      SELECT 1 FROM subscriptions sub
      WHERE sub.customer_id = c.customer_id AND sub.newspaper_id = n.newspaper_id
  );

-- ----------------------------------------------------------------------------
-- 9. ROUTES (15 routes across service zones)
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
-- 10. DAILY ROUTES & PARTNER ASSIGNMENTS FOR 2026-10-28 AND 2026-10-26
-- ----------------------------------------------------------------------------
-- Create daily routes for both 2026-10-28 (Today) and 2026-10-26 (Past Demo Date)
INSERT INTO daily_routes (route_id, route_date, status)
SELECT r.route_id, d.target_date, 'ACTIVE'
FROM routes r
CROSS JOIN (
    SELECT '2026-10-28' AS target_date UNION ALL
    SELECT '2026-10-26'
) d
WHERE NOT EXISTS (
    SELECT 1 FROM daily_routes dr WHERE dr.route_id = r.route_id AND dr.route_date = d.target_date
);

-- Assign 15 partners to 15 routes for target dates
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
WHERE dr.route_date IN ('2026-10-28', '2026-10-26')
  AND NOT EXISTS (
      SELECT 1 FROM route_partners rp
      WHERE rp.daily_route_id = dr.daily_route_id AND rp.partner_id = dp.partner_id
  );

-- ----------------------------------------------------------------------------
-- 11. CUSTOMER ASSIGNMENTS FOR TARGET DATES (300 customer assignments)
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
JOIN daily_routes dr ON dr.route_id = r.route_id AND dr.route_date IN ('2026-10-28', '2026-10-26')
JOIN route_partners rp ON rp.daily_route_id = dr.daily_route_id
WHERE NOT EXISTS (
    SELECT 1 FROM customer_assignments old
    WHERE old.daily_route_id = dr.daily_route_id
      AND old.customer_id = c.customer_id
      AND old.address_id = ca.address_id
);

-- ----------------------------------------------------------------------------
-- 12. DELIVERIES FOR TARGET DATES (300 deliveries with realistic status mix)
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
       dr.route_date AS delivery_date,
       '06:30:00' AS scheduled_time,
       CASE
           -- DELIVERED: drop times between 06:15 and 07:45
           WHEN MOD(ca.assignment_id, 10) NOT IN (3, 7, 9)
               THEN ADDTIME('06:15:00', SEC_TO_TIME(MOD(ca.assignment_id * 113, 5400)))
           -- DELAYED: arrived after 08:00
           WHEN MOD(ca.assignment_id, 10) = 7
               THEN '08:15:00'
           -- PARTIALLY_DELIVERED / NOT_DELIVERED:
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
           WHEN MOD(ca.assignment_id, 10) = 7 THEN 'Route delayed due to morning traffic/weather.'
           WHEN MOD(ca.assignment_id, 10) = 9 THEN 'Main newspaper delivered; supplement pending press arrival.'
           ELSE 'Customer gate was locked; delivery attempted at 06:45 AM.'
       END AS remarks,
       TIMESTAMP(DATE_ADD(dr.route_date, INTERVAL 1 DAY), '11:00:00') AS editable_until
FROM customer_assignments ca
JOIN daily_routes dr ON dr.daily_route_id = ca.daily_route_id
WHERE dr.route_date IN ('2026-10-28', '2026-10-26')
  AND NOT EXISTS (
      SELECT 1 FROM deliveries d
      WHERE d.assignment_id = ca.assignment_id AND d.delivery_date = dr.route_date
  );

-- ----------------------------------------------------------------------------
-- 13. DELIVERY ITEMS FOR TARGET DATES (Crucial for Supplier Delivery Operations)
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
WHERE d.delivery_date IN ('2026-10-28', '2026-10-26')
  AND NOT EXISTS (
      SELECT 1 FROM delivery_items di
      WHERE di.delivery_id = d.delivery_id AND di.subscription_id = s.subscription_id
  );

-- ----------------------------------------------------------------------------
-- 14. DELIVERY CONFIRMATIONS FOR TARGET DATES
-- ----------------------------------------------------------------------------
INSERT INTO delivery_confirmations (delivery_id, customer_id, status, confirmed_at)
SELECT d.delivery_id,
       d.customer_id,
       CASE WHEN d.status = 'DELIVERED' THEN 'CONFIRMED' ELSE 'PENDING' END,
       CASE WHEN d.status = 'DELIVERED' THEN TIMESTAMP(d.delivery_date, '08:30:00') ELSE NULL END
FROM deliveries d
WHERE d.delivery_date IN ('2026-10-28', '2026-10-26')
  AND NOT EXISTS (
      SELECT 1 FROM delivery_confirmations dc WHERE dc.delivery_id = d.delivery_id
  );

-- ----------------------------------------------------------------------------
-- 15. CUSTOMER NOTIFICATIONS
-- ----------------------------------------------------------------------------
INSERT INTO notifications (user_id, notification_type, title, message, reference_type, reference_id, is_read, created_at)
SELECT u.user_id,
       'DELIVERY',
       'Morning Delivery Completed',
       CONCAT('Your newspaper was delivered at ', TIME_FORMAT(COALESCE(d.actual_time, '06:45:00'), '%h:%i %p'), '. Have a wonderful day!'),
       'DELIVERY',
       d.delivery_id,
       FALSE,
       TIMESTAMP(d.delivery_date, '07:15:00')
FROM deliveries d
JOIN customers c ON c.customer_id = d.customer_id
JOIN users u ON u.user_id = c.user_id
WHERE d.delivery_date IN ('2026-10-28', '2026-10-26')
  AND d.status = 'DELIVERED'
  AND MOD(c.customer_id, 10) = 0
  AND NOT EXISTS (
      SELECT 1 FROM notifications n WHERE n.user_id = u.user_id AND n.reference_id = d.delivery_id
  );

COMMIT;
