-- DAILY demo seed data for newspaper_delivery
-- Safe to run more than once: inserts use natural-key checks / unique-key upserts.
-- Intended for a DEVELOPMENT / DEMO database only. Payment rows below are simulated seed records,
-- not real gateway transactions. Do not use these records as proof of actual payment.
-- This script does not drop tables, rename tables, or alter your schema.

USE newspaper_delivery;
SET @seed_today := CURRENT_DATE();
START TRANSACTION;

-- 1) Users (password_hash left NULL so this script does not invent login credentials).
-- Existing users with these emails are retained and reused.
INSERT INTO users (name,email,phone,password_hash,role)
SELECT v.name,v.email,v.phone,NULL,v.role
FROM (
 SELECT 'Aarav Sharma' name,'aarav.demo@daily.local' email,'9000000101' phone,'CUSTOMER' role UNION ALL
 SELECT 'Priya Deshmukh','priya.demo@daily.local','9000000102','CUSTOMER' UNION ALL
 SELECT 'Rohan Mehta','rohan.demo@daily.local','9000000103','CUSTOMER' UNION ALL
 SELECT 'Ananya Iyer','ananya.demo@daily.local','9000000104','CUSTOMER' UNION ALL
 SELECT 'Kabir Shah','kabir.demo@daily.local','9000000105','CUSTOMER' UNION ALL
 SELECT 'Meera Joshi','meera.demo@daily.local','9000000106','CUSTOMER' UNION ALL
 SELECT 'Rahul Patil','rahul.partner@daily.local','9000000201','DELIVERY_PARTNER' UNION ALL
 SELECT 'Amit Kulkarni','amit.partner@daily.local','9000000202','DELIVERY_PARTNER' UNION ALL
 SELECT 'Sana Khan','sana.partner@daily.local','9000000203','DELIVERY_PARTNER' UNION ALL
 SELECT 'Vikram Pawar','vikram.partner@daily.local','9000000204','DELIVERY_PARTNER' UNION ALL
 SELECT 'Mumbai Daily Distributors','mumbai.supplier@daily.local','9000000301','SUPPLIER' UNION ALL
 SELECT 'Western News Distributors','western.supplier@daily.local','9000000302','SUPPLIER' UNION ALL
 SELECT 'Metro Press Supply','metro.supplier@daily.local','9000000303','SUPPLIER'
) v
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.email=v.email)
  AND NOT EXISTS (SELECT 1 FROM users u WHERE u.phone=v.phone);

-- 2) Service areas
INSERT INTO areas (area_name,city,pincode)
SELECT v.area_name,'Mumbai',v.pincode
FROM (
 SELECT 'Dadar West' area_name,'400028' pincode UNION ALL
 SELECT 'Dadar East','400014' UNION ALL
 SELECT 'Matunga','400019' UNION ALL
 SELECT 'Bandra West','400050' UNION ALL
 SELECT 'Andheri West','400058' UNION ALL
 SELECT 'Mahim','400016' UNION ALL
 SELECT 'Prabhadevi','400025' UNION ALL
 SELECT 'Worli','400018'
) v
WHERE NOT EXISTS (SELECT 1 FROM areas a WHERE a.area_name=v.area_name AND a.city='Mumbai' AND a.pincode=v.pincode);

-- 3) Role-specific records
INSERT INTO customers (user_id,customer_code,date_of_birth)
SELECT u.user_id, v.customer_code, v.dob
FROM (
 SELECT 'aarav.demo@daily.local' email,'DEMO-C001' customer_code,'1998-05-15' dob UNION ALL
 SELECT 'priya.demo@daily.local','DEMO-C002','1995-11-22' UNION ALL
 SELECT 'rohan.demo@daily.local','DEMO-C003','1989-03-08' UNION ALL
 SELECT 'ananya.demo@daily.local','DEMO-C004','2000-07-19' UNION ALL
 SELECT 'kabir.demo@daily.local','DEMO-C005','1992-01-27' UNION ALL
 SELECT 'meera.demo@daily.local','DEMO-C006','1985-09-03'
) v JOIN users u ON u.email=v.email
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.user_id=u.user_id)
  AND NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_code=v.customer_code);

INSERT INTO suppliers (user_id,supplier_name,contact_number,address)
SELECT u.user_id,v.supplier_name,v.phone,v.address
FROM (
 SELECT 'mumbai.supplier@daily.local' email,'Mumbai Daily Distributors' supplier_name,'9000000301' phone,'Dadar West, Mumbai, Maharashtra' address UNION ALL
 SELECT 'western.supplier@daily.local','Western News Distributors','9000000302','Bandra West, Mumbai, Maharashtra' UNION ALL
 SELECT 'metro.supplier@daily.local','Metro Press Supply','9000000303','Andheri West, Mumbai, Maharashtra'
) v JOIN users u ON u.email=v.email
WHERE NOT EXISTS (SELECT 1 FROM suppliers s WHERE s.user_id=u.user_id);

INSERT INTO delivery_partners (user_id,partner_code,emergency_contact,recommended_customer_limit,shift_start,shift_end,status)
SELECT u.user_id,v.partner_code,v.emergency_contact,45,'05:30:00','10:30:00',v.status
FROM (
 SELECT 'rahul.partner@daily.local' email,'DEMO-DP001' partner_code,'9000000401' emergency_contact,'ON_ROUTE' status UNION ALL
 SELECT 'amit.partner@daily.local','DEMO-DP002','9000000402','AVAILABLE' UNION ALL
 SELECT 'sana.partner@daily.local','DEMO-DP003','9000000403','AVAILABLE' UNION ALL
 SELECT 'vikram.partner@daily.local','DEMO-DP004','9000000404','OFF_DUTY'
) v JOIN users u ON u.email=v.email
WHERE NOT EXISTS (SELECT 1 FROM delivery_partners dp WHERE dp.user_id=u.user_id)
  AND NOT EXISTS (SELECT 1 FROM delivery_partners dp WHERE dp.partner_code=v.partner_code);

-- 4) Supplier coverage and vehicles
INSERT INTO supplier_areas (supplier_id,area_id,status)
SELECT s.supplier_id,a.area_id,'ACTIVE'
FROM suppliers s JOIN users u ON u.user_id=s.user_id
JOIN areas a ON a.city='Mumbai'
WHERE (u.email='mumbai.supplier@daily.local' AND a.area_name IN ('Dadar West','Dadar East','Matunga','Mahim','Prabhadevi'))
   OR (u.email='western.supplier@daily.local' AND a.area_name IN ('Bandra West','Mahim','Worli'))
   OR (u.email='metro.supplier@daily.local' AND a.area_name IN ('Andheri West','Bandra West'))
ON DUPLICATE KEY UPDATE status='ACTIVE';

INSERT INTO partner_vehicles (partner_id,vehicle_type,registration_number,status)
SELECT dp.partner_id,v.vehicle_type,v.registration_number,'ACTIVE'
FROM (
 SELECT 'rahul.partner@daily.local' email,'Scooter' vehicle_type,'MH02-DEMO-101' registration_number UNION ALL
 SELECT 'amit.partner@daily.local','Motorcycle','MH02-DEMO-102' UNION ALL
 SELECT 'sana.partner@daily.local','Bicycle','MH02-DEMO-103' UNION ALL
 SELECT 'vikram.partner@daily.local','Motorcycle','MH02-DEMO-104'
) v JOIN users u ON u.email=v.email JOIN delivery_partners dp ON dp.user_id=u.user_id
WHERE NOT EXISTS (SELECT 1 FROM partner_vehicles pv WHERE pv.partner_id=dp.partner_id AND pv.registration_number=v.registration_number);

-- 5) Newspaper catalogue
INSERT INTO newspapers (newspaper_name,language,publication_type)
SELECT v.newspaper_name,v.language,v.publication_type
FROM (
 SELECT 'The Times of India' newspaper_name,'English' language,'National' publication_type UNION ALL
 SELECT 'Hindustan Times','English','National' UNION ALL
 SELECT 'The Indian Express','English','National' UNION ALL
 SELECT 'Loksatta','Marathi','Regional' UNION ALL
 SELECT 'Maharashtra Times','Marathi','Regional' UNION ALL
 SELECT 'Mumbai Chronicle','English','Local' UNION ALL
 SELECT 'City Morning','English','Local' UNION ALL
 SELECT 'Business Standard','English','Business' UNION ALL
 SELECT 'The Economic Times','English','Business' UNION ALL
 SELECT 'Sports Daily','English','Sports'
) v WHERE NOT EXISTS (SELECT 1 FROM newspapers n WHERE n.newspaper_name=v.newspaper_name);

INSERT INTO newspaper_prices (newspaper_id,price_per_delivery,effective_from)
SELECT n.newspaper_id,v.price,CURRENT_DATE()
FROM (
 SELECT 'The Times of India' newspaper_name,6.00 price UNION ALL
 SELECT 'Hindustan Times',5.00 UNION ALL
 SELECT 'The Indian Express',5.50 UNION ALL
 SELECT 'Loksatta',5.00 UNION ALL
 SELECT 'Maharashtra Times',5.00 UNION ALL
 SELECT 'Mumbai Chronicle',4.00 UNION ALL
 SELECT 'City Morning',4.00 UNION ALL
 SELECT 'Business Standard',7.00 UNION ALL
 SELECT 'The Economic Times',8.00 UNION ALL
 SELECT 'Sports Daily',4.50
) v JOIN newspapers n ON n.newspaper_name=v.newspaper_name
WHERE NOT EXISTS (SELECT 1 FROM newspaper_prices p WHERE p.newspaper_id=n.newspaper_id AND p.effective_from=CURRENT_DATE());

INSERT INTO supplier_newspapers (supplier_id,newspaper_id,status,available_from)
SELECT s.supplier_id,n.newspaper_id,'ACTIVE',CURRENT_DATE()
FROM suppliers s JOIN users u ON u.user_id=s.user_id
JOIN newspapers n ON (
 (u.email='mumbai.supplier@daily.local' AND n.newspaper_name IN ('The Times of India','Loksatta','Maharashtra Times','Mumbai Chronicle','City Morning')) OR
 (u.email='western.supplier@daily.local' AND n.newspaper_name IN ('The Times of India','Hindustan Times','The Indian Express','Business Standard')) OR
 (u.email='metro.supplier@daily.local' AND n.newspaper_name IN ('Hindustan Times','The Economic Times','Sports Daily','City Morning'))
)
WHERE NOT EXISTS (SELECT 1 FROM supplier_newspapers sn WHERE sn.supplier_id=s.supplier_id AND sn.newspaper_id=n.newspaper_id);

-- 6) Customer addresses
INSERT INTO customer_addresses (customer_id,address_line,area_id,city,pincode,delivery_instructions,is_active,effective_from)
SELECT c.customer_id,v.address_line,a.area_id,'Mumbai',a.pincode,v.instructions,TRUE,CURRENT_DATE()
FROM (
 SELECT 'aarav.demo@daily.local' email,'12 Shivaji Park Road' address_line,'Dadar West' area_name,'Leave at main door' instructions UNION ALL
 SELECT 'priya.demo@daily.local','45 Tilak Road','Dadar East','Place inside the newspaper box' UNION ALL
 SELECT 'rohan.demo@daily.local','8 Kings Circle','Matunga','Hand over to building security' UNION ALL
 SELECT 'ananya.demo@daily.local','21 Hill Road','Bandra West','Leave with reception' UNION ALL
 SELECT 'kabir.demo@daily.local','17 Veera Desai Road','Andheri West','Use lobby newspaper stand' UNION ALL
 SELECT 'meera.demo@daily.local','6 Lady Jamshedji Road','Mahim','Leave beside the door'
) v JOIN users u ON u.email=v.email JOIN customers c ON c.user_id=u.user_id
JOIN areas a ON a.area_name=v.area_name AND a.city='Mumbai'
WHERE NOT EXISTS (SELECT 1 FROM customer_addresses ca WHERE ca.customer_id=c.customer_id AND ca.address_line=v.address_line);

-- 7) Subscriptions: each customer has one or more active/paused subscriptions.
INSERT INTO subscriptions (customer_id,newspaper_id,supplier_id,address_id,start_date,end_date,status,delivery_days,scheduled_delivery_time,agreed_price)
SELECT c.customer_id,n.newspaper_id,s.supplier_id,ca.address_id,v.start_date,v.end_date,v.status,'MON,TUE,WED,THU,FRI,SAT',v.delivery_time,v.price
FROM (
 SELECT 'aarav.demo@daily.local' email,'The Times of India' paper,'mumbai.supplier@daily.local' supplier_email,'06:45:00' delivery_time,6.00 price,'2026-08-01' start_date,NULL end_date,'ACTIVE' status UNION ALL
 SELECT 'aarav.demo@daily.local','Mumbai Chronicle','mumbai.supplier@daily.local','06:45:00',4.00,'2026-08-15',NULL,'ACTIVE' UNION ALL
 SELECT 'priya.demo@daily.local','Loksatta','mumbai.supplier@daily.local','06:50:00',5.00,'2026-07-01',NULL,'ACTIVE' UNION ALL
 SELECT 'priya.demo@daily.local','Hindustan Times','western.supplier@daily.local','06:50:00',5.00,'2026-06-01',NULL,'PAUSED' UNION ALL
 SELECT 'rohan.demo@daily.local','Maharashtra Times','mumbai.supplier@daily.local','06:40:00',5.00,'2026-09-01',NULL,'ACTIVE' UNION ALL
 SELECT 'ananya.demo@daily.local','The Times of India','western.supplier@daily.local','07:00:00',6.00,'2026-08-10',NULL,'ACTIVE' UNION ALL
 SELECT 'kabir.demo@daily.local','The Economic Times','metro.supplier@daily.local','07:10:00',8.00,'2026-07-15',NULL,'ACTIVE' UNION ALL
 SELECT 'meera.demo@daily.local','City Morning','metro.supplier@daily.local','06:55:00',4.00,'2026-05-01',NULL,'ACTIVE'
) v JOIN users u ON u.email=v.email JOIN customers c ON c.user_id=u.user_id
JOIN newspapers n ON n.newspaper_name=v.paper JOIN users su ON su.email=v.supplier_email JOIN suppliers s ON s.user_id=su.user_id
JOIN customer_addresses ca ON ca.customer_id=c.customer_id AND ca.is_active=TRUE
WHERE NOT EXISTS (SELECT 1 FROM subscriptions sub WHERE sub.customer_id=c.customer_id AND sub.newspaper_id=n.newspaper_id AND sub.supplier_id=s.supplier_id AND sub.address_id=ca.address_id AND sub.start_date=v.start_date);

INSERT INTO subscription_pauses (subscription_id,start_date,end_date,reason)
SELECT s.subscription_id,'2026-10-20','2026-10-28','Customer requested a short holiday pause.'
FROM subscriptions s JOIN customers c ON c.customer_id=s.customer_id JOIN users u ON u.user_id=c.user_id JOIN newspapers n ON n.newspaper_id=s.newspaper_id
WHERE u.email='priya.demo@daily.local' AND n.newspaper_name='Hindustan Times'
AND NOT EXISTS (SELECT 1 FROM subscription_pauses p WHERE p.subscription_id=s.subscription_id AND p.start_date='2026-10-20');

-- 8) Routes and today's route assignments
INSERT INTO routes (area_id,route_name,status)
SELECT a.area_id,v.route_name,'ACTIVE' FROM (
 SELECT 'Dadar West' area_name,'Dadar West Morning Route' route_name UNION ALL
 SELECT 'Dadar East','Dadar East Morning Route' UNION ALL
 SELECT 'Matunga','Matunga Early Route' UNION ALL
 SELECT 'Bandra West','Bandra West Morning Route' UNION ALL
 SELECT 'Andheri West','Andheri West Morning Route'
) v JOIN areas a ON a.area_name=v.area_name AND a.city='Mumbai'
WHERE NOT EXISTS (SELECT 1 FROM routes r WHERE r.area_id=a.area_id AND r.route_name=v.route_name);

INSERT INTO daily_routes (route_id,route_date,status)
SELECT r.route_id,@seed_today,'ACTIVE' FROM routes r
WHERE NOT EXISTS (SELECT 1 FROM daily_routes dr WHERE dr.route_id=r.route_id AND dr.route_date=@seed_today);

INSERT INTO route_partners (daily_route_id,partner_id,shift_start,shift_end)
SELECT dr.daily_route_id,dp.partner_id,dp.shift_start,dp.shift_end
FROM daily_routes dr JOIN routes r ON r.route_id=dr.route_id
JOIN areas a ON a.area_id=r.area_id JOIN users pu ON pu.email=CASE a.area_name
 WHEN 'Dadar West' THEN 'rahul.partner@daily.local'
 WHEN 'Dadar East' THEN 'amit.partner@daily.local'
 WHEN 'Matunga' THEN 'amit.partner@daily.local'
 WHEN 'Bandra West' THEN 'sana.partner@daily.local'
 ELSE 'vikram.partner@daily.local' END
JOIN delivery_partners dp ON dp.user_id=pu.user_id
WHERE dr.route_date=@seed_today AND NOT EXISTS (SELECT 1 FROM route_partners rp WHERE rp.daily_route_id=dr.daily_route_id AND rp.partner_id=dp.partner_id);

INSERT INTO customer_assignments (daily_route_id,partner_id,customer_id,address_id,sequence_number,status)
SELECT dr.daily_route_id,dp.partner_id,c.customer_id,ca.address_id,
       ROW_NUMBER() OVER (PARTITION BY dr.daily_route_id ORDER BY c.customer_id),'ACTIVE'
FROM daily_routes dr JOIN routes r ON r.route_id=dr.route_id JOIN areas a ON a.area_id=r.area_id
JOIN customer_addresses ca ON ca.area_id=a.area_id AND ca.is_active=TRUE
JOIN customers c ON c.customer_id=ca.customer_id
JOIN users cu ON cu.user_id=c.user_id
JOIN users pu ON pu.email=CASE a.area_name
 WHEN 'Dadar West' THEN 'rahul.partner@daily.local'
 WHEN 'Dadar East' THEN 'amit.partner@daily.local'
 WHEN 'Matunga' THEN 'amit.partner@daily.local'
 WHEN 'Bandra West' THEN 'sana.partner@daily.local'
 ELSE 'vikram.partner@daily.local' END
JOIN delivery_partners dp ON dp.user_id=pu.user_id
WHERE dr.route_date=@seed_today
AND NOT EXISTS (SELECT 1 FROM customer_assignments old WHERE old.daily_route_id=dr.daily_route_id AND old.customer_id=c.customer_id AND old.address_id=ca.address_id AND old.status='ACTIVE');

-- 9) Historical delivery history for the last seven days plus today's mixed statuses.
INSERT INTO delivery_failure_reasons (reason_name,category,charge_customer)
SELECT v.reason_name,v.category,FALSE FROM (
 SELECT 'Customer not available' reason_name,'CUSTOMER' category UNION ALL
 SELECT 'Address inaccessible','DELIVERY' UNION ALL
 SELECT 'Newspaper damaged','DELIVERY' UNION ALL
 SELECT 'Delivery partner issue','DELIVERY' UNION ALL
 SELECT 'Newspaper not supplied by supplier','SUPPLIER' UNION ALL
 SELECT 'Heavy rain / access delay','OTHER'
) v WHERE NOT EXISTS (SELECT 1 FROM delivery_failure_reasons r WHERE r.reason_name=v.reason_name);

INSERT INTO deliveries (assignment_id,customer_id,partner_id,delivery_date,scheduled_time,actual_time,status,failure_reason_id,remarks,editable_until)
SELECT ca.assignment_id,ca.customer_id,ca.partner_id,dates.delivery_date,
       COALESCE((SELECT MIN(s.scheduled_delivery_time) FROM subscriptions s WHERE s.customer_id=ca.customer_id AND s.status='ACTIVE'),'07:00:00'),
       CASE WHEN dates.delivery_date < @seed_today AND MOD(ca.assignment_id + DATEDIFF(@seed_today,dates.delivery_date),7) NOT IN (3,5) THEN ADDTIME('06:50:00',SEC_TO_TIME(MOD(ca.assignment_id*137,900))) ELSE NULL END,
       CASE WHEN dates.delivery_date=@seed_today THEN CASE MOD(ca.assignment_id,5) WHEN 0 THEN 'NOT_DELIVERED' WHEN 1 THEN 'DELAYED' ELSE 'DELIVERED' END
            WHEN MOD(ca.assignment_id + DATEDIFF(@seed_today,dates.delivery_date),7)=3 THEN 'NOT_DELIVERED'
            WHEN MOD(ca.assignment_id + DATEDIFF(@seed_today,dates.delivery_date),7)=5 THEN 'DELAYED'
            ELSE 'DELIVERED' END,
       CASE WHEN MOD(ca.assignment_id + DATEDIFF(@seed_today,dates.delivery_date),7)=3 THEN (SELECT reason_id FROM delivery_failure_reasons WHERE reason_name='Customer not available' LIMIT 1)
            WHEN MOD(ca.assignment_id + DATEDIFF(@seed_today,dates.delivery_date),7)=5 THEN (SELECT reason_id FROM delivery_failure_reasons WHERE reason_name='Heavy rain / access delay' LIMIT 1)
            ELSE NULL END,
       CASE WHEN dates.delivery_date=@seed_today AND MOD(ca.assignment_id,5)=0 THEN 'Awaiting delivery update'
            WHEN MOD(ca.assignment_id + DATEDIFF(@seed_today,dates.delivery_date),7)=3 THEN 'Customer was not available at delivery address.'
            WHEN MOD(ca.assignment_id + DATEDIFF(@seed_today,dates.delivery_date),7)=5 THEN 'Delivery delayed due to route conditions.'
            ELSE 'Newspaper delivered successfully.' END,
       TIMESTAMP(DATE_ADD(dates.delivery_date,INTERVAL 1 DAY),'11:00:00')
FROM customer_assignments ca
JOIN daily_routes dr ON dr.daily_route_id=ca.daily_route_id
JOIN (
 SELECT DATE_SUB(CURRENT_DATE(),INTERVAL 6 DAY) delivery_date UNION ALL
 SELECT DATE_SUB(CURRENT_DATE(),INTERVAL 5 DAY) UNION ALL
 SELECT DATE_SUB(CURRENT_DATE(),INTERVAL 4 DAY) UNION ALL
 SELECT DATE_SUB(CURRENT_DATE(),INTERVAL 3 DAY) UNION ALL
 SELECT DATE_SUB(CURRENT_DATE(),INTERVAL 2 DAY) UNION ALL
 SELECT DATE_SUB(CURRENT_DATE(),INTERVAL 1 DAY) UNION ALL
 SELECT CURRENT_DATE()
) dates
WHERE ca.status IN ('ACTIVE','COMPLETED')
AND NOT EXISTS (SELECT 1 FROM deliveries d WHERE d.assignment_id=ca.assignment_id AND d.delivery_date=dates.delivery_date);

-- Match each generated delivery to every active subscription for that customer/address.
INSERT INTO delivery_items (delivery_id,subscription_id,newspaper_id,status,reason_id,remarks)
SELECT d.delivery_id,s.subscription_id,s.newspaper_id,
       CASE WHEN d.status='NOT_DELIVERED' THEN 'NOT_DELIVERED'
            WHEN d.status='PARTIALLY_DELIVERED' THEN 'NOT_SUPPLIED'
            ELSE 'DELIVERED' END,
       CASE WHEN d.status='NOT_DELIVERED' THEN d.failure_reason_id ELSE NULL END,
       CASE WHEN d.status='NOT_DELIVERED' THEN d.remarks ELSE NULL END
FROM deliveries d JOIN customer_assignments ca ON ca.assignment_id=d.assignment_id
JOIN subscriptions s ON s.customer_id=d.customer_id AND s.address_id=ca.address_id
WHERE s.start_date<=d.delivery_date AND (s.end_date IS NULL OR s.end_date>=d.delivery_date)
AND NOT EXISTS (SELECT 1 FROM delivery_items di WHERE di.delivery_id=d.delivery_id AND di.subscription_id=s.subscription_id);

INSERT INTO delivery_confirmations (delivery_id,customer_id,status)
SELECT d.delivery_id,d.customer_id,CASE WHEN d.status='DELIVERED' THEN 'CONFIRMED' ELSE 'PENDING' END
FROM deliveries d WHERE NOT EXISTS (SELECT 1 FROM delivery_confirmations dc WHERE dc.delivery_id=d.delivery_id);

-- 10) Bills and bill items for current / previous month. These are demo billing records.
INSERT INTO bills (customer_id,billing_period_start,billing_period_end,subtotal,adjustments,total_amount,status)
SELECT c.customer_id,DATE_FORMAT(DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH),'%Y-%m-01'),LAST_DAY(DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH)),
       sums.total,0.00,sums.total,CASE WHEN MOD(c.customer_id,3)=0 THEN 'PENDING' ELSE 'PAID' END
FROM customers c JOIN (
 SELECT s.customer_id,ROUND(SUM(s.agreed_price*26),2) total FROM subscriptions s
 WHERE s.status IN ('ACTIVE','PAUSED') GROUP BY s.customer_id
) sums ON sums.customer_id=c.customer_id
WHERE NOT EXISTS (SELECT 1 FROM bills b WHERE b.customer_id=c.customer_id AND b.billing_period_start=DATE_FORMAT(DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH),'%Y-%m-01'));

INSERT INTO bill_items (bill_id,subscription_id,newspaper_id,delivery_days,rate_per_delivery,amount)
SELECT b.bill_id,s.subscription_id,s.newspaper_id,26,s.agreed_price,ROUND(s.agreed_price*26,2)
FROM bills b JOIN subscriptions s ON s.customer_id=b.customer_id AND s.status IN ('ACTIVE','PAUSED')
WHERE b.billing_period_start=DATE_FORMAT(DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH),'%Y-%m-01')
AND NOT EXISTS (SELECT 1 FROM bill_items bi WHERE bi.bill_id=b.bill_id AND bi.subscription_id=s.subscription_id);

-- Simulated sample payments: demo-only references; one success for paid bills and one pending for open bills.
INSERT INTO payments (bill_id,customer_id,amount,payment_method,transaction_reference,status,payment_date)
SELECT b.bill_id,b.customer_id,b.total_amount,
       CASE MOD(b.customer_id,3) WHEN 0 THEN 'UPI' WHEN 1 THEN 'CARD' ELSE 'NET_BANKING' END,
       CONCAT('DEMO-',DATE_FORMAT(CURRENT_DATE(),'%Y%m'),' -B',b.bill_id),
       CASE WHEN b.status='PAID' THEN 'SUCCESS' ELSE 'PENDING' END,
       TIMESTAMP(b.billing_period_end,'09:15:00')
FROM bills b
WHERE b.billing_period_start=DATE_FORMAT(DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH),'%Y-%m-01')
AND NOT EXISTS (SELECT 1 FROM payments p WHERE p.bill_id=b.bill_id AND p.transaction_reference=CONCAT('DEMO-',DATE_FORMAT(CURRENT_DATE(),'%Y%m'),' -B',b.bill_id));

INSERT INTO partner_payments (partner_id,payment_period,amount,status,paid_at)
SELECT dp.partner_id,DATE_FORMAT(DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH),'%Y-%m'),
       CASE dp.partner_code WHEN 'DEMO-DP001' THEN 12500.00 WHEN 'DEMO-DP002' THEN 11800.00 WHEN 'DEMO-DP003' THEN 12100.00 ELSE 10900.00 END,
       CASE WHEN MOD(dp.partner_id,3)=0 THEN 'PENDING' ELSE 'PAID' END,
       CASE WHEN MOD(dp.partner_id,3)=0 THEN NULL ELSE TIMESTAMP(LAST_DAY(DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH)),'18:00:00') END
FROM delivery_partners dp
WHERE dp.partner_code LIKE 'DEMO-DP%'
AND NOT EXISTS (SELECT 1 FROM partner_payments pp WHERE pp.partner_id=dp.partner_id AND pp.payment_period=DATE_FORMAT(DATE_SUB(CURRENT_DATE(),INTERVAL 1 MONTH),'%Y-%m'));

-- 11) Service requests, complaints, and notifications
INSERT INTO customer_requests (customer_id,request_type,reference_id,description,status)
SELECT c.customer_id,v.request_type,NULL,v.description,v.status
FROM (
 SELECT 'aarav.demo@daily.local' email,'CHANGE_DELIVERY_TIME' request_type,'Please move delivery to 7:15 AM on weekdays.' description,'PENDING' status UNION ALL
 SELECT 'priya.demo@daily.local','CHANGE_ADDRESS','Please update my delivery address after verification.','APPROVED' UNION ALL
 SELECT 'rohan.demo@daily.local','REPORT_MISSED_DELIVERY','The newspaper was not at my door yesterday morning.','IN_PROGRESS' UNION ALL
 SELECT 'ananya.demo@daily.local','CHANGE_NEWSPAPER','I would like to switch to The Indian Express.','PENDING' UNION ALL
 SELECT 'meera.demo@daily.local','TRACK_REQUEST_STATUS','Please share an update on my earlier service request.','COMPLETED'
) v JOIN users u ON u.email=v.email JOIN customers c ON c.user_id=u.user_id
WHERE NOT EXISTS (SELECT 1 FROM customer_requests r WHERE r.customer_id=c.customer_id AND r.request_type=v.request_type AND r.description=v.description);

INSERT INTO delivery_complaints (delivery_id,delivery_item_id,customer_id,complaint_type,description,status,assigned_partner_id,resolved_by,resolution,resolved_at)
SELECT d.delivery_id,di.delivery_item_id,d.customer_id,'MISSED_DELIVERY',
       'Demo complaint: customer reported a missing newspaper.',
       CASE WHEN d.status='NOT_DELIVERED' THEN 'IN_PROGRESS' ELSE 'RESOLVED' END,
       d.partner_id,
       CASE WHEN d.status='NOT_DELIVERED' THEN NULL ELSE (SELECT user_id FROM users WHERE email='mumbai.supplier@daily.local' LIMIT 1) END,
       CASE WHEN d.status='NOT_DELIVERED' THEN NULL ELSE 'Demo resolution: replacement delivery arranged.' END,
       CASE WHEN d.status='NOT_DELIVERED' THEN NULL ELSE CURRENT_TIMESTAMP END
FROM deliveries d JOIN delivery_items di ON di.delivery_id=d.delivery_id
JOIN subscriptions s ON s.subscription_id=di.subscription_id
JOIN customers c ON c.customer_id=d.customer_id JOIN users u ON u.user_id=c.user_id
WHERE d.status='NOT_DELIVERED' AND u.email='rohan.demo@daily.local'
AND NOT EXISTS (SELECT 1 FROM delivery_complaints dc WHERE dc.delivery_id=d.delivery_id AND dc.customer_id=d.customer_id AND dc.complaint_type='MISSED_DELIVERY');

INSERT INTO notifications (user_id,notification_type,title,message,reference_type,reference_id,is_read,created_at)
SELECT u.user_id,v.notification_type,v.title,v.message,v.reference_type,NULL,v.is_read,TIMESTAMP(DATE_SUB(CURRENT_DATE(),INTERVAL v.days_ago DAY),v.at_time)
FROM (
 SELECT 'aarav.demo@daily.local' email,'DELIVERY' notification_type,'Your newspaper was delivered' title,'The Times of India was delivered at 6:52 AM. Have a good morning!' message,'DELIVERY' reference_type,1 days_ago,'06:55:00' at_time,FALSE is_read UNION ALL
 SELECT 'aarav.demo@daily.local','PAYMENT','Monthly bill available','Your latest monthly bill is ready to review.','BILL',2,'08:00:00',FALSE UNION ALL
 SELECT 'priya.demo@daily.local','SUBSCRIPTION','Subscription paused','Your Hindustan Times subscription is temporarily paused.','SUBSCRIPTION',3,'09:10:00',FALSE UNION ALL
 SELECT 'rohan.demo@daily.local','REQUEST','Request received','We have received your missed-delivery report and will review it.','REQUEST',1,'10:15:00',FALSE UNION ALL
 SELECT 'ananya.demo@daily.local','DELIVERY','Delivery running late','Your delivery may arrive later than usual today.','DELIVERY',0,'06:45:00',FALSE UNION ALL
 SELECT 'meera.demo@daily.local','PAYMENT','Payment receipt available','Your demo payment receipt is available in Payment History.','PAYMENT',4,'12:00:00',TRUE
) v JOIN users u ON u.email=v.email
WHERE NOT EXISTS (SELECT 1 FROM notifications n WHERE n.user_id=u.user_id AND n.title=v.title AND n.message=v.message);

-- 12) Final data sanity checks
SELECT 'users' table_name,COUNT(*) row_count FROM users
UNION ALL SELECT 'customers',COUNT(*) FROM customers
UNION ALL SELECT 'suppliers',COUNT(*) FROM suppliers
UNION ALL SELECT 'delivery_partners',COUNT(*) FROM delivery_partners
UNION ALL SELECT 'newspapers',COUNT(*) FROM newspapers
UNION ALL SELECT 'subscriptions',COUNT(*) FROM subscriptions
UNION ALL SELECT 'customer_assignments',COUNT(*) FROM customer_assignments
UNION ALL SELECT 'deliveries',COUNT(*) FROM deliveries
UNION ALL SELECT 'delivery_items',COUNT(*) FROM delivery_items
UNION ALL SELECT 'bills',COUNT(*) FROM bills
UNION ALL SELECT 'payments',COUNT(*) FROM payments
UNION ALL SELECT 'customer_requests',COUNT(*) FROM customer_requests
UNION ALL SELECT 'notifications',COUNT(*) FROM notifications;

COMMIT;
