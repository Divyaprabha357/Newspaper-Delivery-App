USE newspaper_delivery;
SELECT DATABASE();

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('CUSTOMER', 'SUPPLIER', 'DELIVERY_PARTNER') NOT NULL,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE areas (
    area_id INT AUTO_INCREMENT PRIMARY KEY,
    area_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE'
);

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    customer_code VARCHAR(20) NOT NULL UNIQUE,
    date_of_birth DATE,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    supplier_name VARCHAR(150) NOT NULL,
    contact_number VARCHAR(15),
    address TEXT,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id)
);



CREATE TABLE customer_addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    address_line TEXT NOT NULL,
    area_id INT NOT NULL,
    city VARCHAR(100) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    delivery_instructions TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE NOT NULL,

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (area_id) REFERENCES areas(area_id)
);

CREATE TABLE supplier_areas (
    supplier_area_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    area_id INT NOT NULL,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',

    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (area_id) REFERENCES areas(area_id),

    UNIQUE (supplier_id, area_id)
);

CREATE TABLE newspapers (
    newspaper_id INT AUTO_INCREMENT PRIMARY KEY,
    newspaper_name VARCHAR(150) NOT NULL,
    language VARCHAR(50),
    publication_type VARCHAR(50),
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE'
);

CREATE TABLE supplier_newspapers (
    supplier_newspaper_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    newspaper_id INT NOT NULL,
    status ENUM(
        'ACTIVE',
        'TEMPORARILY_UNAVAILABLE',
        'INACTIVE'
    ) DEFAULT 'ACTIVE',
    available_from DATE,
    available_until DATE,

    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (newspaper_id) REFERENCES newspapers(newspaper_id),

    UNIQUE (supplier_id, newspaper_id)
);

CREATE TABLE newspaper_prices (
    price_id INT AUTO_INCREMENT PRIMARY KEY,
    newspaper_id INT NOT NULL,
    price_per_delivery DECIMAL(10,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (newspaper_id) REFERENCES newspapers(newspaper_id)
);

CREATE TABLE subscriptions (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    newspaper_id INT NOT NULL,
    supplier_id INT NOT NULL,
    address_id INT NOT NULL,

    start_date DATE NOT NULL,
    end_date DATE,

    status ENUM('ACTIVE', 'PAUSED', 'CANCELLED') DEFAULT 'ACTIVE',

    delivery_days VARCHAR(50) NOT NULL,
    scheduled_delivery_time TIME NOT NULL,

    agreed_price DECIMAL(10,2) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (newspaper_id) REFERENCES newspapers(newspaper_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (address_id) REFERENCES customer_addresses(address_id)
);

CREATE TABLE subscription_pauses (
    pause_id INT AUTO_INCREMENT PRIMARY KEY,
    subscription_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
);

CREATE TABLE delivery_partners (
    partner_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    partner_code VARCHAR(20) NOT NULL UNIQUE,
    emergency_contact VARCHAR(15),
    recommended_customer_limit INT NOT NULL DEFAULT 50,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    status ENUM(
        'AVAILABLE',
        'ON_ROUTE',
        'OFF_DUTY',
        'ON_LEAVE',
        'ABSENT',
        'INACTIVE'
    ) DEFAULT 'AVAILABLE',

    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE partner_vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    partner_id INT NOT NULL,
    vehicle_type VARCHAR(50),
    registration_number VARCHAR(30),
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',

    FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id)
);

CREATE TABLE partner_leave (
    leave_id INT AUTO_INCREMENT PRIMARY KEY,
    partner_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    leave_type VARCHAR(50) DEFAULT 'REGULAR',
    status ENUM('APPROVED', 'CANCELLED') DEFAULT 'APPROVED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id)
);

CREATE TABLE routes (
    route_id INT AUTO_INCREMENT PRIMARY KEY,
    area_id INT NOT NULL,
    route_name VARCHAR(100) NOT NULL,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',

    FOREIGN KEY (area_id) REFERENCES areas(area_id)
);

CREATE TABLE daily_routes (
    daily_route_id INT AUTO_INCREMENT PRIMARY KEY,
    route_id INT NOT NULL,
    route_date DATE NOT NULL,
    status ENUM(
        'GENERATED',
        'ACTIVE',
        'COMPLETED'
    ) DEFAULT 'GENERATED',
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (route_id) REFERENCES routes(route_id),

    UNIQUE (route_id, route_date)
);

CREATE TABLE route_partners (
    route_partner_id INT AUTO_INCREMENT PRIMARY KEY,
    daily_route_id INT NOT NULL,
    partner_id INT NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,

    FOREIGN KEY (daily_route_id) REFERENCES daily_routes(daily_route_id),
    FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id),

    UNIQUE (daily_route_id, partner_id)
);

CREATE TABLE customer_assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    daily_route_id INT NOT NULL,
    partner_id INT NOT NULL,
    customer_id INT NOT NULL,
    address_id INT NOT NULL,

    sequence_number INT NOT NULL,

    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    status ENUM(
        'ACTIVE',
        'REASSIGNED',
        'COMPLETED'
    ) DEFAULT 'ACTIVE',

    FOREIGN KEY (daily_route_id) REFERENCES daily_routes(daily_route_id),
    FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (address_id) REFERENCES customer_addresses(address_id)
);

CREATE TABLE delivery_failure_reasons (
    reason_id INT AUTO_INCREMENT PRIMARY KEY,
    reason_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    charge_customer BOOLEAN DEFAULT FALSE
);

CREATE TABLE deliveries (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    assignment_id INT NOT NULL,
    customer_id INT NOT NULL,
    partner_id INT NOT NULL,

    delivery_date DATE NOT NULL,
    scheduled_time TIME NOT NULL,
    actual_time TIME,

    status ENUM(
        'DELIVERED',
        'PARTIALLY_DELIVERED',
        'NOT_DELIVERED',
        'DELAYED'
    ) NOT NULL DEFAULT 'NOT_DELIVERED',

    failure_reason_id INT,
    remarks TEXT,

    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    editable_until TIMESTAMP,

    FOREIGN KEY (assignment_id) REFERENCES customer_assignments(assignment_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id),
    FOREIGN KEY (failure_reason_id) REFERENCES delivery_failure_reasons(reason_id),

    UNIQUE (assignment_id, delivery_date)
);

CREATE TABLE delivery_items (
    delivery_item_id INT AUTO_INCREMENT PRIMARY KEY,
    delivery_id INT NOT NULL,
    subscription_id INT NOT NULL,
    newspaper_id INT NOT NULL,

    status ENUM(
        'DELIVERED',
        'NOT_DELIVERED',
        'NOT_SUPPLIED'
    ) NOT NULL DEFAULT 'DELIVERED',

    reason_id INT,
    remarks TEXT,

    FOREIGN KEY (delivery_id) REFERENCES deliveries(delivery_id),
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id),
    FOREIGN KEY (newspaper_id) REFERENCES newspapers(newspaper_id),
    FOREIGN KEY (reason_id) REFERENCES delivery_failure_reasons(reason_id)
);

SHOW TABLES;

CREATE TABLE delivery_confirmations (
    confirmation_id INT AUTO_INCREMENT PRIMARY KEY,
    delivery_id INT NOT NULL,
    customer_id INT NOT NULL,

    status ENUM(
        'PENDING',
        'CONFIRMED'
    ) DEFAULT 'PENDING',

    confirmed_at TIMESTAMP NULL,

    FOREIGN KEY (delivery_id) REFERENCES deliveries(delivery_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),

    UNIQUE (delivery_id)
);

CREATE TABLE delivery_complaints (
    complaint_id INT AUTO_INCREMENT PRIMARY KEY,

    delivery_id INT NOT NULL,
    delivery_item_id INT,
    customer_id INT NOT NULL,

    complaint_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,

    status ENUM(
        'OPEN',
        'IN_PROGRESS',
        'RESOLVED'
    ) DEFAULT 'OPEN',

    assigned_partner_id INT,
    resolved_by INT,

    resolution TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,

    FOREIGN KEY (delivery_id) REFERENCES deliveries(delivery_id),
    FOREIGN KEY (delivery_item_id) REFERENCES delivery_items(delivery_item_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (assigned_partner_id) REFERENCES delivery_partners(partner_id),
    FOREIGN KEY (resolved_by) REFERENCES users(user_id)
);

CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,

    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,

    reference_type VARCHAR(50),
    reference_id INT,

    is_read BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE bills (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,

    customer_id INT NOT NULL,

    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,

    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    adjustments DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    status ENUM(
        'PENDING',
        'PAID',
        'PARTIAL'
    ) DEFAULT 'PENDING',

    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE bill_items (
    bill_item_id INT AUTO_INCREMENT PRIMARY KEY,

    bill_id INT NOT NULL,
    subscription_id INT NOT NULL,
    newspaper_id INT NOT NULL,

    delivery_days INT NOT NULL DEFAULT 0,
    rate_per_delivery DECIMAL(10,2) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (bill_id) REFERENCES bills(bill_id),
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id),
    FOREIGN KEY (newspaper_id) REFERENCES newspapers(newspaper_id)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,

    bill_id INT NOT NULL,
    customer_id INT NOT NULL,

    amount DECIMAL(10,2) NOT NULL,

    payment_method VARCHAR(50),
    transaction_reference VARCHAR(100),

    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    status ENUM(
        'SUCCESS',
        'FAILED',
        'PENDING'
    ) DEFAULT 'PENDING',

    FOREIGN KEY (bill_id) REFERENCES bills(bill_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE partner_payments (
    partner_payment_id INT AUTO_INCREMENT PRIMARY KEY,

    partner_id INT NOT NULL,

    payment_period VARCHAR(20) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,

    status ENUM(
        'PENDING',
        'PAID'
    ) DEFAULT 'PENDING',

    paid_at TIMESTAMP NULL,

    FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id)
);

CREATE TABLE customer_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,

    customer_id INT NOT NULL,

    request_type VARCHAR(100) NOT NULL,
    reference_id INT,

    description TEXT NOT NULL,

    status ENUM(
        'PENDING',
        'APPROVED',
        'REJECTED',
        'COMPLETED'
    ) DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

SHOW TABLES;
SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'newspaper_delivery';

DESCRIBE users;
DESCRIBE customers;
DESCRIBE subscriptions;
DESCRIBE deliveries;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'newspaper_delivery'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;

SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'newspaper_delivery';

USE newspaper_delivery;
SHOW TABLES;

SELECT
    TABLE_NAME
FROM information_schema.tables
WHERE TABLE_SCHEMA = 'newspaper_delivery'
ORDER BY TABLE_NAME;

DESCRIBE customer;
DESCRIBE delivery;
DESCRIBE newspaper;

USE newspaper_delivery;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'newspaper_delivery'
  AND REFERENCED_TABLE_NAME IN (
      'customer',
      'delivery',
      'newspaper',
      'delivery_person',
      'payment',
      'subscription',
      'supplier',
      'complaint',
      'employee',
      'department'
  );
  
  SELECT 'customer' AS table_name, COUNT(*) AS records FROM customer
UNION ALL
SELECT 'delivery', COUNT(*) FROM delivery
UNION ALL
SELECT 'delivery_person', COUNT(*) FROM delivery_person
UNION ALL
SELECT 'newspaper', COUNT(*) FROM newspaper
UNION ALL
SELECT 'payment', COUNT(*) FROM payment
UNION ALL
SELECT 'subscription', COUNT(*) FROM subscription
UNION ALL
SELECT 'supplier', COUNT(*) FROM supplier
UNION ALL
SELECT 'complaint', COUNT(*) FROM complaint
UNION ALL
SELECT 'employee', COUNT(*) FROM employee
UNION ALL
SELECT 'department', COUNT(*) FROM department;

USE newspaper_delivery;

RENAME TABLE
    complaint TO legacy_complaint,
    customer TO legacy_customer,
    delivery TO legacy_delivery,
    delivery_person TO legacy_delivery_person,
    department TO legacy_department,
    employee TO legacy_employee,
    newspaper TO legacy_newspaper,
    payment TO legacy_payment,
    subscription TO legacy_subscription,
    supplier TO legacy_supplier;
    
SHOW TABLES;

USE newspaper_delivery;

INSERT INTO users
(name, email, phone, password_hash, role)
VALUES
('Aarav Sharma', 'aarav@gmail.com', '9876543210', 'demo_hash_123', 'CUSTOMER'),
('Priya Deshmukh', 'priya@gmail.com', '9876543211', 'demo_hash_123', 'CUSTOMER'),
('Rahul Patil', 'rahul@daily.com', '9876543212', 'demo_hash_123', 'DELIVERY_PARTNER'),
('Amit Kulkarni', 'amit@daily.com', '9876543213', 'demo_hash_123', 'DELIVERY_PARTNER'),
('Mumbai Daily Admin', 'admin@mumbaidaily.com', '9876543214', 'demo_hash_123', 'SUPPLIER');

INSERT INTO areas
(area_name, city, pincode)
VALUES
('Dadar West', 'Mumbai', '400028'),
('Dadar East', 'Mumbai', '400014'),
('Matunga', 'Mumbai', '400019'),
('Bandra West', 'Mumbai', '400050'),
('Andheri West', 'Mumbai', '400058');

SELECT user_id, name, role
FROM users;

INSERT INTO customers
(user_id, customer_code, date_of_birth)
VALUES
(1, 'CUST001', '2004-05-15'),
(2, 'CUST002', '2003-11-22');

INSERT INTO suppliers
(user_id, supplier_name, contact_number, address)
VALUES
(5, 'Mumbai Daily Distributors', '9876543214',
 'Dadar West, Mumbai');
 
 INSERT INTO delivery_partners
(
    user_id,
    partner_code,
    emergency_contact,
    recommended_customer_limit,
    shift_start,
    shift_end
)
VALUES
(
    3,
    'DP001',
    '9876500011',
    50,
    '06:00:00',
    '11:00:00'
),
(
    4,
    'DP002',
    '9876500012',
    60,
    '06:00:00',
    '11:00:00'
);

SELECT * FROM customers;
SELECT * FROM suppliers;
SELECT * FROM delivery_partners;

INSERT INTO supplier_areas
(supplier_id, area_id)
VALUES
(1, 1),
(1, 2),
(1, 3),
(1, 4),
(1, 5);

SELECT
    sa.supplier_area_id,
    s.supplier_name,
    a.area_name,
    a.city,
    a.pincode,
    sa.status
FROM supplier_areas sa
JOIN suppliers s
    ON sa.supplier_id = s.supplier_id
JOIN areas a
    ON sa.area_id = a.area_id;
    
USE newspaper_delivery;

INSERT INTO newspapers
(newspaper_name, language, publication_type)
VALUES
('The Times of India', 'English', 'National'),
('Hindustan Times', 'English', 'National'),
('Loksatta', 'Marathi', 'Regional'),
('Mumbai Chronicle', 'English', 'Local'),
('Maharashtra Today', 'Marathi', 'Regional'),
('City Morning', 'English', 'Local'),
('The Daily Herald', 'English', 'National');

SELECT
    newspaper_id,
    newspaper_name,
    language,
    publication_type,
    status
FROM newspapers;

INSERT INTO newspaper_prices
(newspaper_id, price_per_delivery, effective_from)
VALUES
(1, 6.00, '2026-01-01'),
(2, 5.00, '2026-01-01'),
(3, 5.00, '2026-01-01'),
(4, 4.00, '2026-01-01'),
(5, 5.00, '2026-01-01'),
(6, 4.00, '2026-01-01'),
(7, 6.00, '2026-01-01');

INSERT INTO supplier_newspapers
(supplier_id, newspaper_id, status, available_from)
VALUES
(1, 1, 'ACTIVE', '2026-01-01'),
(1, 2, 'ACTIVE', '2026-01-01'),
(1, 3, 'ACTIVE', '2026-01-01'),
(1, 4, 'ACTIVE', '2026-01-01'),
(1, 5, 'ACTIVE', '2026-01-01'),
(1, 6, 'ACTIVE', '2026-01-01'),
(1, 7, 'ACTIVE', '2026-01-01');

SELECT
    n.newspaper_id,
    n.newspaper_name,
    n.language,
    n.publication_type,
    np.price_per_delivery,
    sn.status AS supplier_status
FROM newspapers n
JOIN newspaper_prices np
    ON n.newspaper_id = np.newspaper_id
JOIN supplier_newspapers sn
    ON n.newspaper_id = sn.newspaper_id
WHERE sn.supplier_id = 1
ORDER BY n.newspaper_id;

INSERT INTO customer_addresses
(
    customer_id,
    address_line,
    area_id,
    city,
    pincode,
    delivery_instructions,
    is_active,
    effective_from
)
VALUES
(
    1,
    '12 Shivaji Park Road',
    1,
    'Mumbai',
    '400028',
    'Leave the newspaper near the main door.',
    TRUE,
    '2026-01-01'
),
(
    2,
    '45 Tilak Road',
    2,
    'Mumbai',
    '400014',
    'Place the newspaper inside the newspaper box.',
    TRUE,
    '2026-01-01'
);

SELECT
    ca.address_id,
    c.customer_code,
    u.name AS customer_name,
    ca.address_line,
    a.area_name,
    ca.city,
    ca.pincode,
    ca.is_active
FROM customer_addresses ca
JOIN customers c
    ON ca.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN areas a
    ON ca.area_id = a.area_id;

INSERT INTO subscriptions
(
    customer_id,
    newspaper_id,
    supplier_id,
    address_id,
    start_date,
    status,
    delivery_days,
    scheduled_delivery_time,
    agreed_price
)
VALUES
(
    1,
    1,
    1,
    1,
    '2026-09-01',
    'ACTIVE',
    'MON,TUE,WED,THU,FRI,SAT',
    '07:00:00',
    6.00
);

INSERT INTO subscriptions
(
    customer_id,
    newspaper_id,
    supplier_id,
    address_id,
    start_date,
    status,
    delivery_days,
    scheduled_delivery_time,
    agreed_price
)
VALUES
(
    2,
    3,
    1,
    2,
    '2026-09-01',
    'ACTIVE',
    'MON,TUE,WED,THU,FRI,SAT',
    '06:45:00',
    5.00
);

SELECT 
    s.subscription_id,
    u.name AS customer,
    n.newspaper_name,
    sup.supplier_name,
    s.start_date,
    s.status,
    s.delivery_days,
    s.scheduled_delivery_time,
    s.agreed_price
FROM
    subscriptions s
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    users u ON c.user_id = u.user_id
        JOIN
    newspapers n ON s.newspaper_id = n.newspaper_id
        JOIN
    suppliers sup ON s.supplier_id = sup.supplier_id;
    
SELECT * FROM routes;

INSERT INTO daily_routes
(route_id, route_date, status)
VALUES
(1, '2026-09-08', 'GENERATED');

USE newspaper_delivery;

INSERT INTO routes
(area_id, route_name)
VALUES
(1, 'Dadar West Morning Route');

SELECT * FROM routes;

INSERT INTO daily_routes
(route_id, route_date, status)
VALUES
(1, '2026-09-08', 'GENERATED');

SELECT * FROM daily_routes;

INSERT INTO route_partners
(
    daily_route_id,
    partner_id,
    shift_start,
    shift_end
)
VALUES
(
    1,
    1,
    '06:00:00',
    '11:00:00'
);

SELECT
    rp.route_partner_id,
    r.route_name,
    u.name AS delivery_partner,
    rp.shift_start,
    rp.shift_end
FROM route_partners rp
JOIN daily_routes dr
    ON rp.daily_route_id = dr.daily_route_id
JOIN routes r
    ON dr.route_id = r.route_id
JOIN delivery_partners dp
    ON rp.partner_id = dp.partner_id
JOIN users u
    ON dp.user_id = u.user_id;
    
INSERT INTO customer_assignments
(
    daily_route_id,
    partner_id,
    customer_id,
    address_id,
    sequence_number,
    status
)
VALUES
(
    1,
    1,
    1,
    1,
    1,
    'ACTIVE'
);
SELECT
    ca.assignment_id,
    u.name AS customer,
    ca.sequence_number,
    a.area_name,
    ca.status,
    up.name AS delivery_partner
FROM customer_assignments ca
JOIN customers c
    ON ca.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN customer_addresses addr
    ON ca.address_id = addr.address_id
JOIN areas a
    ON addr.area_id = a.area_id
JOIN delivery_partners dp
    ON ca.partner_id = dp.partner_id
JOIN users up
    ON dp.user_id = up.user_id;
    
INSERT INTO deliveries
(
    assignment_id,
    customer_id,
    partner_id,
    delivery_date,
    scheduled_time,
    actual_time,
    status,
    remarks,
    submitted_at,
    editable_until
)
VALUES
(
    1,
    1,
    1,
    '2026-09-08',
    '07:00:00',
    '07:02:00',
    'DELIVERED',
    'Delivered successfully.',
    NOW(),
    DATE_ADD(NOW(), INTERVAL 30 MINUTE)
);

SELECT
    d.delivery_id,
    u.name AS customer,
    n.newspaper_name,
    d.delivery_date,
    d.scheduled_time,
    d.actual_time,
    d.status,
    d.remarks
FROM deliveries d
JOIN customers c
    ON d.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN subscriptions s
    ON d.customer_id = s.customer_id
JOIN newspapers n
    ON s.newspaper_id = n.newspaper_id
WHERE d.delivery_date = '2026-09-08';

INSERT INTO delivery_items
(
    delivery_id,
    subscription_id,
    newspaper_id,
    status
)
VALUES
(
    1,
    1,
    1,
    'DELIVERED'
);

SELECT
    di.delivery_item_id,
    u.name AS customer,
    n.newspaper_name,
    di.status
FROM delivery_items di
JOIN deliveries d
    ON di.delivery_id = d.delivery_id
JOIN customers c
    ON d.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN newspapers n
    ON di.newspaper_id = n.newspaper_id;
    
INSERT INTO delivery_confirmations
(
    delivery_id,
    customer_id,
    status
)
VALUES
(
    1,
    1,
    'PENDING'
);

SELECT
    dc.confirmation_id,
    u.name AS customer,
    dc.delivery_id,
    dc.status,
    dc.confirmed_at
FROM delivery_confirmations dc
JOIN customers c
    ON dc.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id;
    
INSERT INTO delivery_failure_reasons
(
    reason_name,
    category,
    charge_customer
)
VALUES
('Customer not available', 'CUSTOMER', FALSE),
('Address inaccessible', 'DELIVERY', FALSE),
('Newspaper damaged', 'DELIVERY', FALSE),
('Delivery partner issue', 'DELIVERY', FALSE),
('Newspaper not supplied by supplier', 'SUPPLIER', FALSE),
('Other delivery issue', 'OTHER', FALSE);

SELECT
    reason_id,
    reason_name,
    category,
    charge_customer
FROM delivery_failure_reasons;

INSERT INTO deliveries
(
    assignment_id,
    customer_id,
    partner_id,
    delivery_date,
    scheduled_time,
    status,
    failure_reason_id,
    remarks,
    editable_until
)
VALUES
(
    1,
    1,
    1,
    '2026-09-09',
    '07:00:00',
    'NOT_DELIVERED',
    1,
    'Customer was not available.',
    DATE_ADD(NOW(), INTERVAL 30 MINUTE)
);

SELECT
    d.delivery_id,
    u.name AS customer,
    n.newspaper_name,
    d.delivery_date,
    d.status,
    d.remarks,
    d.failure_reason_id
FROM deliveries d
JOIN customers c
    ON d.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN delivery_items di
    ON d.delivery_id = di.delivery_id
JOIN newspapers n
    ON di.newspaper_id = n.newspaper_id
WHERE d.delivery_date = '2026-09-09';

INSERT INTO delivery_items
(
    delivery_id,
    subscription_id,
    newspaper_id,
    status,
    reason_id,
    remarks
)
VALUES
(
    2,
    1,
    1,
    'NOT_DELIVERED',
    1,
    'Customer was not available.'
);

SELECT
    d.delivery_id,
    d.delivery_date,
    n.newspaper_name,
    di.status,
    r.reason_name,
    di.remarks
FROM deliveries d
JOIN delivery_items di
    ON d.delivery_id = di.delivery_id
JOIN newspapers n
    ON di.newspaper_id = n.newspaper_id
LEFT JOIN delivery_failure_reasons r
    ON di.reason_id = r.reason_id
ORDER BY d.delivery_date;

INSERT INTO delivery_complaints
(
    delivery_id,
    delivery_item_id,
    customer_id,
    complaint_type,
    description,
    status
)
VALUES
(
    2,
    2,
    1,
    'MISSED_DELIVERY',
    'The Times of India was not delivered today.',
    'OPEN'
);

SELECT
    dc.complaint_id,
    u.name AS customer,
    dc.complaint_type,
    dc.description,
    dc.status,
    dc.created_at
FROM delivery_complaints dc
JOIN customers c
    ON dc.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id;
    
UPDATE delivery_complaints
SET
    assigned_partner_id = 1,
    status = 'IN_PROGRESS'
WHERE complaint_id = 1;

SELECT
    dc.complaint_id,
    u.name AS customer,
    up.name AS delivery_partner,
    dc.complaint_type,
    dc.status
FROM delivery_complaints dc
JOIN customers c
    ON dc.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
LEFT JOIN delivery_partners dp
    ON dc.assigned_partner_id = dp.partner_id
LEFT JOIN users up
    ON dp.user_id = up.user_id;

UPDATE delivery_complaints
SET
    status = 'RESOLVED',
    resolved_by = 5,
    resolution = 'Replacement newspaper scheduled for delivery.',
    resolved_at = CURRENT_TIMESTAMP
WHERE complaint_id = 1;

SELECT
    dc.complaint_id,
    u.name AS customer,
    up.name AS delivery_partner,
    dc.status,
    dc.resolution,
    dc.resolved_at
FROM delivery_complaints dc
JOIN customers c
    ON dc.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
LEFT JOIN delivery_partners dp
    ON dc.assigned_partner_id = dp.partner_id
LEFT JOIN users up
    ON dp.user_id = up.user_id
LEFT JOIN users ru
    ON dc.resolved_by = ru.user_id;
    
INSERT INTO notifications
(
    user_id,
    notification_type,
    title,
    message,
    reference_type,
    reference_id
)
VALUES
(
    1,
    'REQUEST',
    'Delivery Issue Resolved',
    'Your missed delivery complaint has been resolved. A replacement newspaper has been scheduled.',
    'COMPLAINT',
    1
);

SELECT
    notification_id,
    title,
    message,
    notification_type,
    is_read,
    created_at
FROM notifications
WHERE user_id = 1
ORDER BY created_at DESC;

INSERT INTO bills
(
    customer_id,
    billing_period_start,
    billing_period_end,
    subtotal,
    adjustments,
    total_amount,
    status
)
VALUES
(
    1,
    '2026-09-01',
    '2026-09-30',
    156.00,
    0.00,
    156.00,
    'PENDING'
);

SELECT
    bill_id,
    customer_id,
    billing_period_start,
    billing_period_end,
    subtotal,
    adjustments,
    total_amount,
    status
FROM bills
WHERE customer_id = 1;

INSERT INTO bill_items
(
    bill_id,
    subscription_id,
    newspaper_id,
    delivery_days,
    rate_per_delivery,
    amount
)
VALUES
(
    1,
    1,
    1,
    26,
    6.00,
    156.00
);

SELECT
    bi.bill_item_id,
    n.newspaper_name,
    bi.delivery_days,
    bi.rate_per_delivery,
    bi.amount
FROM bill_items bi
JOIN newspapers n
    ON bi.newspaper_id = n.newspaper_id
WHERE bi.bill_id = 1;

INSERT INTO payments
(
    bill_id,
    customer_id,
    amount,
    payment_method,
    transaction_reference,
    status
)
VALUES
(
    1,
    1,
    156.00,
    'UPI',
    'UPI202609080001',
    'SUCCESS'
);

SELECT
    payment_id,
    bill_id,
    amount,
    payment_method,
    transaction_reference,
    payment_date,
    status
FROM payments
WHERE bill_id = 1;

UPDATE bills
SET
    status = 'PAID'
WHERE bill_id = 1
  AND total_amount = 156.00;
  
SELECT
    bill_id,
    total_amount,
    status
FROM bills
WHERE bill_id = 1;

INSERT INTO notifications
(
    user_id,
    notification_type,
    title,
    message,
    reference_type,
    reference_id
)
VALUES
(
    1,
    'PAYMENT',
    'Payment Successful',
    'Your payment of ₹156.00 for The Times of India subscription was successful.',
    'PAYMENT',
    1
);

SELECT
    notification_id,
    notification_type,
    title,
    message,
    is_read,
    created_at
FROM notifications
WHERE user_id = 1
ORDER BY created_at DESC;

INSERT INTO bills
(
    customer_id,
    billing_period_start,
    billing_period_end,
    subtotal,
    adjustments,
    total_amount,
    status
)
VALUES
(
    2,
    '2026-09-01',
    '2026-09-30',
    130.00,
    0.00,
    130.00,
    'PENDING'
);

SELECT
    bill_id,
    customer_id,
    billing_period_start,
    billing_period_end,
    total_amount,
    status
FROM bills
WHERE customer_id = 2;

INSERT INTO bill_items
(
    bill_id,
    subscription_id,
    newspaper_id,
    delivery_days,
    rate_per_delivery,
    amount
)
VALUES
(
    2,
    2,
    3,
    26,
    5.00,
    130.00
);

SELECT
    bi.bill_item_id,
    n.newspaper_name,
    bi.delivery_days,
    bi.rate_per_delivery,
    bi.amount
FROM bill_items bi
JOIN newspapers n
    ON bi.newspaper_id = n.newspaper_id
WHERE bi.bill_id = 2;

SELECT
    b.bill_id,
    u.name AS customer,
    b.billing_period_start,
    b.billing_period_end,
    b.total_amount,
    b.status
FROM bills b
JOIN customers c
    ON b.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
WHERE b.customer_id = 2;

INSERT INTO payments
(
    bill_id,
    customer_id,
    amount,
    payment_method,
    transaction_reference,
    status
)
VALUES
(
    2,
    2,
    130.00,
    'UPI',
    'UPI202609080002',
    'FAILED'
);

SELECT
    payment_id,
    bill_id,
    customer_id,
    amount,
    payment_method,
    transaction_reference,
    status
FROM payments
WHERE bill_id = 2;

INSERT INTO customer_requests
(
    customer_id,
    request_type,
    reference_id,
    description,
    status
)
VALUES
(
    1,
    'CHANGE_ADDRESS',
    1,
    'Request to change the newspaper delivery address to 25 Senapati Bapat Road, Dadar West.',
    'PENDING'
);

SELECT
    request_id,
    customer_id,
    request_type,
    description,
    status,
    created_at
FROM customer_requests
WHERE customer_id = 1;

INSERT INTO customer_requests
(
    customer_id,
    request_type,
    reference_id,
    description,
    status
)
VALUES
(
    1,
    'CHANGE_DELIVERY_TIME',
    1,
    'Request to change the newspaper delivery time from 7:00 AM to 7:30 AM.',
    'PENDING'
);
SELECT
    request_id,
    customer_id,
    request_type,
    description,
    status,
    created_at
FROM customer_requests
WHERE customer_id = 1
ORDER BY request_id;

INSERT INTO customer_requests
(
    customer_id,
    request_type,
    reference_id,
    description,
    status
)
VALUES
(
    1,
    'REPORT_MISSED_DELIVERY',
    2,
    'The Times of India was not delivered on September 9, 2026.',
    'PENDING'
);

SELECT
    request_id,
    request_type,
    reference_id,
    description,
    status,
    created_at
FROM customer_requests
WHERE customer_id = 1
ORDER BY request_id;

UPDATE customer_requests
SET
    status = 'APPROVED'
WHERE request_id = 1
  AND status = 'PENDING';
  
  SELECT
    request_id,
    request_type,
    status,
    created_at,
    completed_at
FROM customer_requests
WHERE request_id = 1;

INSERT INTO customer_addresses
(
    customer_id,
    address_line,
    area_id,
    city,
    pincode,
    delivery_instructions,
    is_active,
    effective_from
)
VALUES
(
    1,
    '25 Senapati Bapat Road',
    1,
    'Mumbai',
    '400028',
    'Leave the newspaper near the main door.',
    TRUE,
    '2026-09-10'
);

UPDATE customer_addresses
SET is_active = FALSE
WHERE address_id = 1
  AND customer_id = 1;
  
UPDATE customer_requests
SET
    status = 'COMPLETED',
    completed_at = CURRENT_TIMESTAMP
WHERE request_id = 1
  AND status = 'APPROVED';
  
SELECT
    request_id,
    request_type,
    status,
    completed_at
FROM customer_requests
WHERE request_id = 1;

SELECT
    address_id,
    address_line,
    is_active,
    effective_from
FROM customer_addresses
WHERE customer_id = 1
ORDER BY address_id;

INSERT INTO subscription_pauses
(
    subscription_id,
    start_date,
    end_date,
    reason
)
VALUES
(
    1,
    '2026-09-10',
    '2026-09-12',
    'Customer requested a temporary pause.'
);

UPDATE subscriptions
SET status = 'PAUSED'
WHERE subscription_id = 1
  AND status = 'ACTIVE';
  
SELECT
    s.subscription_id,
    u.name AS customer,
    n.newspaper_name,
    s.status,
    sp.start_date AS pause_start,
    sp.end_date AS pause_end,
    sp.reason
FROM subscriptions s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN newspapers n
    ON s.newspaper_id = n.newspaper_id
JOIN subscription_pauses sp
    ON s.subscription_id = sp.subscription_id
WHERE s.subscription_id = 1;

UPDATE subscriptions
SET status = 'ACTIVE'
WHERE subscription_id = 1
  AND status = 'PAUSED';

SELECT
    subscription_id,
    customer_id,
    newspaper_id,
    status
FROM subscriptions
WHERE subscription_id = 1;

SELECT
    pause_id,
    subscription_id,
    start_date,
    end_date,
    reason
FROM subscription_pauses
WHERE subscription_id = 1;

UPDATE subscriptions
SET
    status = 'CANCELLED',
    end_date = '2026-09-08'
WHERE subscription_id = 1
  AND status = 'ACTIVE';
  
SELECT
    subscription_id,
    customer_id,
    newspaper_id,
    start_date,
    end_date,
    status
FROM subscriptions
WHERE subscription_id = 1;

INSERT INTO subscriptions
(
    customer_id,
    newspaper_id,
    supplier_id,
    address_id,
    start_date,
    status,
    delivery_days,
    scheduled_delivery_time,
    agreed_price
)
VALUES
(
    1,
    2,
    1,
    3,
    '2026-09-09',
    'ACTIVE',
    'MON,TUE,WED,THU,FRI,SAT',
    '07:00:00',
    5.00
);

SELECT
    subscription_id,
    customer_id,
    newspaper_id,
    status,
    agreed_price
FROM subscriptions
WHERE customer_id = 1;

SELECT
    subscription_id,
    customer_id,
    newspaper_id,
    status,
    agreed_price
FROM subscriptions
WHERE customer_id = 1;

INSERT INTO deliveries
(
    assignment_id,
    customer_id,
    partner_id,
    delivery_date,
    scheduled_time,
    actual_time,
    status,
    remarks,
    editable_until
)
VALUES
(
    1,
    1,
    1,
    '2026-09-10',
    '07:00:00',
    '07:03:00',
    'PARTIALLY_DELIVERED',
    'One newspaper was not supplied by the supplier.',
    DATE_ADD(NOW(), INTERVAL 30 MINUTE)
);

SELECT
    delivery_id,
    customer_id,
    partner_id,
    delivery_date,
    status,
    remarks
FROM deliveries
WHERE delivery_date = '2026-09-10';

INSERT INTO delivery_items
(
    delivery_id,
    subscription_id,
    newspaper_id,
    status
)
VALUES
(
    3,
    1,
    1,
    'DELIVERED'
),
(
    3,
    3,
    2,
    'NOT_SUPPLIED'
);

SELECT
    di.delivery_item_id,
    di.delivery_id,
    n.newspaper_name,
    di.status,
    r.reason_name
FROM delivery_items di
JOIN newspapers n
    ON di.newspaper_id = n.newspaper_id
LEFT JOIN delivery_failure_reasons r
    ON di.reason_id = r.reason_id
WHERE di.delivery_id = 3;

UPDATE delivery_items
SET
    reason_id = 5,
    remarks = 'Newspaper was not supplied by the supplier.'
WHERE delivery_item_id = 4;

SELECT
    delivery_item_id,
    newspaper_id,
    status,
    reason_id,
    remarks
FROM delivery_items
WHERE delivery_id = 3;

SELECT
    notification_id,
    title,
    is_read,
    created_at
FROM notifications
WHERE user_id = 1
ORDER BY notification_id;

UPDATE notifications
SET is_read = TRUE
WHERE notification_id = 2
  AND user_id = 1;
  
SELECT
    notification_id,
    title,
    is_read
FROM notifications
WHERE user_id = 1
ORDER BY notification_id;

UPDATE customer_requests
SET status = 'APPROVED'
WHERE request_id = 2
  AND status = 'PENDING';
  
UPDATE subscriptions
SET scheduled_delivery_time = '07:30:00'
WHERE subscription_id = 3
  AND status = 'ACTIVE';
  
UPDATE customer_requests
SET
    status = 'COMPLETED',
    completed_at = CURRENT_TIMESTAMP
WHERE request_id = 2
  AND status = 'APPROVED';
  
  SELECT
    request_id,
    request_type,
    status,
    completed_at
FROM customer_requests
WHERE request_id = 2;

SELECT
    subscription_id,
    newspaper_id,
    scheduled_delivery_time,
    status
FROM subscriptions
WHERE subscription_id = 3;

UPDATE delivery_partners
SET status = 'ABSENT'
WHERE partner_id = 1;

UPDATE customer_assignments
SET
    partner_id = 2,
    status = 'REASSIGNED'
WHERE assignment_id = 1
  AND partner_id = 1
  AND status = 'ACTIVE';
  
INSERT INTO customer_assignments
(
    daily_route_id,
    partner_id,
    customer_id,
    address_id,
    sequence_number,
    status
)
VALUES
(
    1,
    2,
    1,
    3,
    1,
    'ACTIVE'
);

SELECT
    ca.assignment_id,
    u.name AS delivery_partner,
    c.customer_id,
    ca.address_id,
    ca.sequence_number,
    ca.status
FROM customer_assignments ca
JOIN delivery_partners dp
    ON ca.partner_id = dp.partner_id
JOIN users u
    ON dp.user_id = u.user_id
JOIN customers c
    ON ca.customer_id = c.customer_id
WHERE ca.customer_id = 1
ORDER BY ca.assignment_id;

INSERT INTO users
(
    name,
    email,
    phone,
    password_hash,
    role
)
VALUES
(
    'Western News Admin',
    'admin@westernnews.com',
    '9876543215',
    'demo_hash_456',
    'SUPPLIER'
);

INSERT INTO suppliers
(
    user_id,
    supplier_name,
    contact_number,
    address
)
VALUES
(
    6,
    'Western News Distributors',
    '9876543215',
    'Bandra West, Mumbai'
);

SELECT
    supplier_id,
    supplier_name,
    status
FROM suppliers;

INSERT INTO supplier_areas
(
    supplier_id,
    area_id,
    status
)
VALUES
(2, 4, 'ACTIVE'),
(2, 1, 'ACTIVE');

INSERT INTO supplier_newspapers
(
    supplier_id,
    newspaper_id,
    status,
    available_from
)
VALUES
(
    2,
    1,
    'ACTIVE',
    '2026-01-01'
);

SELECT
    s.supplier_name,
    a.area_name,
    n.newspaper_name,
    sn.status
FROM supplier_newspapers sn
JOIN suppliers s
    ON sn.supplier_id = s.supplier_id
JOIN newspapers n
    ON sn.newspaper_id = n.newspaper_id
JOIN supplier_areas sa
    ON sa.supplier_id = s.supplier_id
JOIN areas a
    ON sa.area_id = a.area_id
WHERE s.supplier_id = 2;

UPDATE supplier_newspapers
SET status = 'TEMPORARILY_UNAVAILABLE'
WHERE supplier_id = 1
  AND newspaper_id = 1;
  
SELECT
    supplier_id,
    newspaper_id,
    status
FROM supplier_newspapers
WHERE newspaper_id = 1;

INSERT INTO subscriptions
(
    customer_id,
    newspaper_id,
    supplier_id,
    address_id,
    start_date,
    status,
    delivery_days,
    scheduled_delivery_time,
    agreed_price
)
VALUES
(
    1,
    1,
    2,
    3,
    '2026-09-09',
    'ACTIVE',
    'MON,TUE,WED,THU,FRI,SAT',
    '07:00:00',
    6.00
);

SELECT
    s.subscription_id,
    u.name AS customer,
    n.newspaper_name,
    sp.supplier_name,
    s.status,
    s.agreed_price
FROM subscriptions s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN newspapers n
    ON s.newspaper_id = n.newspaper_id
JOIN suppliers sp
    ON s.supplier_id = sp.supplier_id
WHERE s.customer_id = 1
  AND s.newspaper_id = 1
  AND s.status = 'ACTIVE';
  
SELECT
    customer_id,
    newspaper_id,
    COUNT(*) AS active_subscriptions
FROM subscriptions
WHERE status = 'ACTIVE'
GROUP BY customer_id, newspaper_id
HAVING COUNT(*) > 1;

SELECT
    s.subscription_id,
    u.name AS customer,
    n.newspaper_name,
    sp.supplier_name,
    s.status
FROM subscriptions s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN newspapers n
    ON s.newspaper_id = n.newspaper_id
JOIN suppliers sp
    ON s.supplier_id = sp.supplier_id
ORDER BY s.subscription_id;

SELECT
    d.delivery_id,
    d.delivery_date,
    cu.name AS customer,
    dp.name AS delivery_partner,
    n.newspaper_name,
    di.status AS newspaper_status,
    d.status AS overall_delivery_status
FROM deliveries d
JOIN customers c
    ON d.customer_id = c.customer_id
JOIN users cu
    ON c.user_id = cu.user_id
JOIN delivery_partners p
    ON d.partner_id = p.partner_id
JOIN users dp
    ON p.user_id = dp.user_id
JOIN delivery_items di
    ON d.delivery_id = di.delivery_id
JOIN newspapers n
    ON di.newspaper_id = n.newspaper_id
ORDER BY d.delivery_date, d.delivery_id;

SHOW TABLES;

SELECT 'Subscriptions' AS table_name, COUNT(*) AS orphan_count
FROM subscriptions s
LEFT JOIN customers c ON s.customer_id = c.customer_id
LEFT JOIN newspapers n ON s.newspaper_id = n.newspaper_id
LEFT JOIN suppliers sp ON s.supplier_id = sp.supplier_id
WHERE c.customer_id IS NULL
   OR n.newspaper_id IS NULL
   OR sp.supplier_id IS NULL

UNION ALL

SELECT 'Customer Assignments', COUNT(*)
FROM customer_assignments ca
LEFT JOIN customers c ON ca.customer_id = c.customer_id
LEFT JOIN delivery_partners dp ON ca.partner_id = dp.partner_id
LEFT JOIN daily_routes dr ON ca.daily_route_id = dr.daily_route_id
WHERE c.customer_id IS NULL
   OR dp.partner_id IS NULL
   OR dr.daily_route_id IS NULL

UNION ALL

SELECT 'Deliveries', COUNT(*)
FROM deliveries d
LEFT JOIN customer_assignments ca ON d.assignment_id = ca.assignment_id
LEFT JOIN customers c ON d.customer_id = c.customer_id
LEFT JOIN delivery_partners dp ON d.partner_id = dp.partner_id
WHERE ca.assignment_id IS NULL
   OR c.customer_id IS NULL
   OR dp.partner_id IS NULL;
   
SELECT
    c.customer_id,
    u.name AS customer,
    n.newspaper_name,
    COUNT(*) AS active_subscriptions
FROM subscriptions s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN users u
    ON c.user_id = u.user_id
JOIN newspapers n
    ON s.newspaper_id = n.newspaper_id
WHERE s.status = 'ACTIVE'
GROUP BY c.customer_id, u.name, n.newspaper_id, n.newspaper_name
HAVING COUNT(*) > 1;

SELECT
    'Users' AS table_name, COUNT(*) AS records FROM users
UNION ALL
SELECT 'Customers', COUNT(*) FROM customers
UNION ALL
SELECT 'Suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'Newspapers', COUNT(*) FROM newspapers
UNION ALL
SELECT 'Subscriptions', COUNT(*) FROM subscriptions
UNION ALL
SELECT 'Delivery Partners', COUNT(*) FROM delivery_partners
UNION ALL
SELECT 'Deliveries', COUNT(*) FROM deliveries
UNION ALL
SELECT 'Payments', COUNT(*) FROM payments
UNION ALL
SELECT 'Requests', COUNT(*) FROM customer_requests
UNION ALL
SELECT 'Notifications', COUNT(*) FROM notifications;

USE newspaper_delivery;
USE newspaper_delivery;

DESCRIBE newspapers;
DESCRIBE suppliers;
DESCRIBE customer_addresses;

DESCRIBE newspapers;
DESCRIBE suppliers;

DESCRIBE newspapers;

USE newspaper_delivery;

DESCRIBE deliveries;

USE newspaper_delivery;

DESCRIBE customer_assignments;
USE newspaper_delivery;

DESCRIBE daily_routes;
USE newspaper_delivery;

DESCRIBE routes;
USE newspaper_delivery;

DESCRIBE delivery_items;
USE newspaper_delivery;

DESCRIBE payments;

USE newspaper_delivery;
USE newspaper_delivery;

DESCRIBE customer_requests;
DESCRIBE notifications;

USE newspaper_delivery;

UPDATE users
SET password_hash = '123456'
WHERE email = 'aarav@example.com';

SELECT user_id, name, email, phone, role, status
FROM users;

USE newspaper_delivery;

SELECT
    user_id,
    name,
    email,
    phone,
    role,
    status
FROM users;

USE newspaper_delivery;

UPDATE users
SET password_hash = '123456'
WHERE email = 'aarav@gmail.com';

USE newspaper_delivery;

ALTER TABLE deliveries
MODIFY COLUMN status ENUM(
    'DELIVERED',
    'PARTIALLY_DELIVERED',
    'NOT_DELIVERED',
    'DELAYED',
    'RESCHEDULED'
) NOT NULL DEFAULT 'NOT_DELIVERED';

ALTER TABLE deliveries
ADD COLUMN original_scheduled_time TIME NULL AFTER scheduled_time,
ADD COLUMN rescheduled_date DATE NULL AFTER delivery_date,
ADD COLUMN rescheduled_time TIME NULL AFTER original_scheduled_time;

INSERT INTO daily_routes
(route_id, route_date, status)
VALUES
(1, '2026-09-09', 'GENERATED'),
(1, '2026-09-10', 'GENERATED');

SELECT
    daily_route_id,
    route_id,
    route_date,
    status
FROM daily_routes
ORDER BY route_date;

UPDATE customer_assignments
SET
    partner_id = 1,
    address_id = 1,
    status = 'COMPLETED'
WHERE assignment_id = 1;

INSERT INTO customer_assignments
(
    daily_route_id,
    partner_id,
    customer_id,
    address_id,
    sequence_number,
    status
)
VALUES
(
    3,
    2,
    1,
    3,
    1,
    'ACTIVE'
);

SELECT
    di.delivery_item_id,
    di.delivery_id,
    di.subscription_id,
    n.newspaper_name,
    d.delivery_date,
    di.status
FROM delivery_items di
JOIN deliveries d
    ON di.delivery_id = d.delivery_id
JOIN newspapers n
    ON di.newspaper_id = n.newspaper_id
WHERE di.subscription_id = 1
ORDER BY d.delivery_date;

SELECT
    subscription_id,
    customer_id,
    newspaper_id,
    supplier_id,
    address_id,
    start_date,
    end_date,
    status,
    delivery_days,
    scheduled_delivery_time,
    agreed_price
FROM subscriptions
WHERE customer_id = 1
ORDER BY subscription_id;

SELECT
    delivery_item_id,
    delivery_id,
    subscription_id,
    newspaper_id,
    status,
    reason_id,
    remarks
FROM delivery_items
ORDER BY delivery_item_id;

USE newspaper_delivery;

DELETE FROM delivery_items
WHERE delivery_id = 3;

DELETE FROM deliveries
WHERE delivery_id = 3;

SELECT *
FROM deliveries
ORDER BY delivery_id;

SELECT *
FROM delivery_items
ORDER BY delivery_item_id;

ALTER TABLE users
MODIFY COLUMN email VARCHAR(150) NULL UNIQUE,
MODIFY COLUMN phone VARCHAR(15) NULL UNIQUE,
MODIFY COLUMN password_hash VARCHAR(255) NULL,
ADD COLUMN auth_provider ENUM(
    'PASSWORD',
    'GOOGLE'
) NOT NULL DEFAULT 'PASSWORD',
ADD COLUMN provider_user_id VARCHAR(255) NULL;



SHOW INDEX FROM users;
USE newspaper_delivery;

DROP INDEX email_2 ON users;
DROP INDEX phone_2 ON users;