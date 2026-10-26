-- DAILY Database Backup
-- Database: newspaper_delivery
-- Timestamp: 2026-10-26T03:41:12.375Z

SET FOREIGN_KEY_CHECKS = 0;

-- Table structure for: areas
CREATE TABLE "areas" (
  "area_id" int NOT NULL AUTO_INCREMENT,
  "area_name" varchar(100) NOT NULL,
  "city" varchar(100) NOT NULL,
  "pincode" varchar(10) NOT NULL,
  "status" enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  PRIMARY KEY ("area_id")
);

-- Data for table: areas (5 rows)
INSERT INTO `areas` (`area_id`, `area_name`, `city`, `pincode`, `status`) VALUES
(1, 'Dadar West', 'Mumbai', '400028', 'ACTIVE'),
(2, 'Dadar East', 'Mumbai', '400014', 'ACTIVE'),
(3, 'Matunga', 'Mumbai', '400019', 'ACTIVE'),
(4, 'Bandra West', 'Mumbai', '400050', 'ACTIVE'),
(5, 'Andheri West', 'Mumbai', '400058', 'ACTIVE');

-- Table structure for: bill_items
CREATE TABLE "bill_items" (
  "bill_item_id" int NOT NULL AUTO_INCREMENT,
  "bill_id" int NOT NULL,
  "subscription_id" int NOT NULL,
  "newspaper_id" int NOT NULL,
  "delivery_days" int NOT NULL DEFAULT '0',
  "rate_per_delivery" decimal(10,2) NOT NULL,
  "amount" decimal(10,2) NOT NULL,
  PRIMARY KEY ("bill_item_id"),
  KEY "bill_id" ("bill_id"),
  KEY "subscription_id" ("subscription_id"),
  KEY "newspaper_id" ("newspaper_id"),
  CONSTRAINT "bill_items_ibfk_1" FOREIGN KEY ("bill_id") REFERENCES "bills" ("bill_id"),
  CONSTRAINT "bill_items_ibfk_2" FOREIGN KEY ("subscription_id") REFERENCES "subscriptions" ("subscription_id"),
  CONSTRAINT "bill_items_ibfk_3" FOREIGN KEY ("newspaper_id") REFERENCES "newspapers" ("newspaper_id")
);

-- Data for table: bill_items (2 rows)
INSERT INTO `bill_items` (`bill_item_id`, `bill_id`, `subscription_id`, `newspaper_id`, `delivery_days`, `rate_per_delivery`, `amount`) VALUES
(1, 1, 1, 1, 26, '6.00', '156.00'),
(2, 2, 2, 3, 26, '5.00', '130.00');

-- Table structure for: bills
CREATE TABLE "bills" (
  "bill_id" int NOT NULL AUTO_INCREMENT,
  "customer_id" int NOT NULL,
  "billing_period_start" date NOT NULL,
  "billing_period_end" date NOT NULL,
  "subtotal" decimal(10,2) NOT NULL DEFAULT '0.00',
  "adjustments" decimal(10,2) NOT NULL DEFAULT '0.00',
  "total_amount" decimal(10,2) NOT NULL DEFAULT '0.00',
  "status" enum('PENDING','PAID','PARTIAL') DEFAULT 'PENDING',
  "generated_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("bill_id"),
  KEY "customer_id" ("customer_id"),
  CONSTRAINT "bills_ibfk_1" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id")
);

-- Data for table: bills (2 rows)
INSERT INTO `bills` (`bill_id`, `customer_id`, `billing_period_start`, `billing_period_end`, `subtotal`, `adjustments`, `total_amount`, `status`, `generated_at`) VALUES
(1, 1, '2026-08-31 18:30:00', '2026-09-29 18:30:00', '156.00', '0.00', '156.00', 'PAID', '2026-09-08 12:20:20'),
(2, 2, '2026-08-31 18:30:00', '2026-09-29 18:30:00', '130.00', '0.00', '130.00', 'PENDING', '2026-09-08 12:24:18');

-- Table structure for: customer_addresses
CREATE TABLE "customer_addresses" (
  "address_id" int NOT NULL AUTO_INCREMENT,
  "customer_id" int NOT NULL,
  "address_line" text NOT NULL,
  "area_id" int NOT NULL,
  "city" varchar(100) NOT NULL,
  "pincode" varchar(10) NOT NULL,
  "latitude" decimal(10,8) DEFAULT NULL,
  "longitude" decimal(11,8) DEFAULT NULL,
  "delivery_instructions" text,
  "is_active" tinyint(1) DEFAULT '1',
  "effective_from" date NOT NULL,
  PRIMARY KEY ("address_id"),
  KEY "customer_id" ("customer_id"),
  KEY "area_id" ("area_id"),
  CONSTRAINT "customer_addresses_ibfk_1" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id"),
  CONSTRAINT "customer_addresses_ibfk_2" FOREIGN KEY ("area_id") REFERENCES "areas" ("area_id")
);

-- Data for table: customer_addresses (3 rows)
INSERT INTO `customer_addresses` (`address_id`, `customer_id`, `address_line`, `area_id`, `city`, `pincode`, `latitude`, `longitude`, `delivery_instructions`, `is_active`, `effective_from`) VALUES
(1, 1, '12 Shivaji Park Road', 1, 'Mumbai', '400028', NULL, NULL, 'Leave the newspaper near the main door.', 0, '2025-12-31 18:30:00'),
(2, 2, '45 Tilak Road', 2, 'Mumbai', '400014', NULL, NULL, 'Place the newspaper inside the newspaper box.', 1, '2025-12-31 18:30:00'),
(3, 1, '25 Senapati Bapat Road', 1, 'Mumbai', '400028', NULL, NULL, 'Leave the newspaper near the main door.', 1, '2026-09-09 18:30:00');

-- Table structure for: customer_assignments
CREATE TABLE "customer_assignments" (
  "assignment_id" int NOT NULL AUTO_INCREMENT,
  "daily_route_id" int NOT NULL,
  "partner_id" int NOT NULL,
  "customer_id" int NOT NULL,
  "address_id" int NOT NULL,
  "sequence_number" int NOT NULL,
  "assigned_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "status" enum('ACTIVE','REASSIGNED','COMPLETED') DEFAULT 'ACTIVE',
  PRIMARY KEY ("assignment_id"),
  KEY "daily_route_id" ("daily_route_id"),
  KEY "partner_id" ("partner_id"),
  KEY "customer_id" ("customer_id"),
  KEY "address_id" ("address_id"),
  CONSTRAINT "customer_assignments_ibfk_1" FOREIGN KEY ("daily_route_id") REFERENCES "daily_routes" ("daily_route_id"),
  CONSTRAINT "customer_assignments_ibfk_2" FOREIGN KEY ("partner_id") REFERENCES "delivery_partners" ("partner_id"),
  CONSTRAINT "customer_assignments_ibfk_3" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id"),
  CONSTRAINT "customer_assignments_ibfk_4" FOREIGN KEY ("address_id") REFERENCES "customer_addresses" ("address_id")
);

-- Data for table: customer_assignments (3 rows)
INSERT INTO `customer_assignments` (`assignment_id`, `daily_route_id`, `partner_id`, `customer_id`, `address_id`, `sequence_number`, `assigned_at`, `status`) VALUES
(1, 1, 1, 1, 1, 1, '2026-09-08 12:09:24', 'COMPLETED'),
(2, 1, 2, 1, 3, 1, '2026-09-08 12:48:38', 'ACTIVE'),
(3, 3, 2, 1, 3, 1, '2026-10-01 12:19:58', 'ACTIVE');

-- Table structure for: customer_requests
CREATE TABLE "customer_requests" (
  "request_id" int NOT NULL AUTO_INCREMENT,
  "customer_id" int NOT NULL,
  "request_type" varchar(100) NOT NULL,
  "reference_id" int DEFAULT NULL,
  "description" text NOT NULL,
  "status" enum('PENDING','APPROVED','REJECTED','COMPLETED') DEFAULT 'PENDING',
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "completed_at" timestamp NULL DEFAULT NULL,
  PRIMARY KEY ("request_id"),
  KEY "customer_id" ("customer_id"),
  CONSTRAINT "customer_requests_ibfk_1" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id")
);

-- Data for table: customer_requests (5 rows)
INSERT INTO `customer_requests` (`request_id`, `customer_id`, `request_type`, `reference_id`, `description`, `status`, `created_at`, `completed_at`) VALUES
(1, 1, 'CHANGE_ADDRESS', 1, 'Request to change the newspaper delivery address to 25 Senapati Bapat Road, Dadar West.', 'COMPLETED', '2026-09-08 12:28:58', '2026-09-08 12:32:30'),
(2, 1, 'CHANGE_DELIVERY_TIME', 1, 'Request to change the newspaper delivery time from 7:00 AM to 7:30 AM.', 'COMPLETED', '2026-09-08 12:29:41', '2026-09-08 12:47:21'),
(3, 1, 'REPORT_MISSED_DELIVERY', 2, 'The Times of India was not delivered on September 9, 2026.', 'PENDING', '2026-09-08 12:30:24', NULL),
(4, 1, 'Change Delivery Time', NULL, '7.30 am', 'PENDING', '2026-10-14 01:05:31', NULL),
(5, 1, 'Change Newspaper', NULL, 'i want to change the newspaper', 'PENDING', '2026-10-19 05:05:01', NULL);

-- Table structure for: customers
CREATE TABLE "customers" (
  "customer_id" int NOT NULL AUTO_INCREMENT,
  "user_id" int NOT NULL,
  "customer_code" varchar(20) NOT NULL,
  "date_of_birth" date DEFAULT NULL,
  "status" enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("customer_id"),
  UNIQUE KEY "user_id" ("user_id"),
  UNIQUE KEY "customer_code" ("customer_code"),
  CONSTRAINT "customers_ibfk_1" FOREIGN KEY ("user_id") REFERENCES "users" ("user_id")
);

-- Data for table: customers (2 rows)
INSERT INTO `customers` (`customer_id`, `user_id`, `customer_code`, `date_of_birth`, `status`, `created_at`) VALUES
(1, 1, 'CUST001', '2004-05-14 18:30:00', 'ACTIVE', '2026-09-08 11:50:54'),
(2, 2, 'CUST002', '2003-11-21 18:30:00', 'ACTIVE', '2026-09-08 11:50:54');

-- Table structure for: daily_routes
CREATE TABLE "daily_routes" (
  "daily_route_id" int NOT NULL AUTO_INCREMENT,
  "route_id" int NOT NULL,
  "route_date" date NOT NULL,
  "status" enum('GENERATED','ACTIVE','COMPLETED') DEFAULT 'GENERATED',
  "generated_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("daily_route_id"),
  UNIQUE KEY "route_id" ("route_id","route_date"),
  CONSTRAINT "daily_routes_ibfk_1" FOREIGN KEY ("route_id") REFERENCES "routes" ("route_id")
);

-- Data for table: daily_routes (3 rows)
INSERT INTO `daily_routes` (`daily_route_id`, `route_id`, `route_date`, `status`, `generated_at`) VALUES
(1, 1, '2026-09-07 18:30:00', 'GENERATED', '2026-09-08 12:03:17'),
(2, 1, '2026-09-08 18:30:00', 'GENERATED', '2026-10-01 12:18:00'),
(3, 1, '2026-09-09 18:30:00', 'GENERATED', '2026-10-01 12:18:00');

-- Table structure for: deliveries
CREATE TABLE "deliveries" (
  "delivery_id" int NOT NULL AUTO_INCREMENT,
  "assignment_id" int NOT NULL,
  "customer_id" int NOT NULL,
  "partner_id" int NOT NULL,
  "delivery_date" date NOT NULL,
  "rescheduled_date" date DEFAULT NULL,
  "scheduled_time" time NOT NULL,
  "original_scheduled_time" time DEFAULT NULL,
  "rescheduled_time" time DEFAULT NULL,
  "actual_time" time DEFAULT NULL,
  "status" enum('DELIVERED','PARTIALLY_DELIVERED','NOT_DELIVERED','DELAYED','RESCHEDULED') NOT NULL DEFAULT 'NOT_DELIVERED',
  "failure_reason_id" int DEFAULT NULL,
  "remarks" text,
  "submitted_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "editable_until" timestamp NULL DEFAULT NULL,
  PRIMARY KEY ("delivery_id"),
  UNIQUE KEY "assignment_id" ("assignment_id","delivery_date"),
  KEY "customer_id" ("customer_id"),
  KEY "partner_id" ("partner_id"),
  KEY "failure_reason_id" ("failure_reason_id"),
  CONSTRAINT "deliveries_ibfk_1" FOREIGN KEY ("assignment_id") REFERENCES "customer_assignments" ("assignment_id"),
  CONSTRAINT "deliveries_ibfk_2" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id"),
  CONSTRAINT "deliveries_ibfk_3" FOREIGN KEY ("partner_id") REFERENCES "delivery_partners" ("partner_id"),
  CONSTRAINT "deliveries_ibfk_4" FOREIGN KEY ("failure_reason_id") REFERENCES "delivery_failure_reasons" ("reason_id")
);

-- Data for table: deliveries (2 rows)
INSERT INTO `deliveries` (`delivery_id`, `assignment_id`, `customer_id`, `partner_id`, `delivery_date`, `rescheduled_date`, `scheduled_time`, `original_scheduled_time`, `rescheduled_time`, `actual_time`, `status`, `failure_reason_id`, `remarks`, `submitted_at`, `editable_until`) VALUES
(1, 1, 1, 1, '2026-09-07 18:30:00', NULL, '07:00:00', NULL, NULL, '07:02:00', 'DELIVERED', NULL, 'Delivered successfully.', '2026-09-08 12:10:32', '2026-09-08 12:40:32'),
(2, 1, 1, 1, '2026-09-08 18:30:00', NULL, '07:00:00', NULL, NULL, '18:48:57', 'DELIVERED', NULL, 'Delivered successfully.', '2026-09-08 12:15:26', '2026-10-13 15:18:57');

-- Table structure for: delivery_complaints
CREATE TABLE "delivery_complaints" (
  "complaint_id" int NOT NULL AUTO_INCREMENT,
  "delivery_id" int NOT NULL,
  "delivery_item_id" int DEFAULT NULL,
  "customer_id" int NOT NULL,
  "complaint_type" varchar(100) NOT NULL,
  "description" text NOT NULL,
  "status" enum('OPEN','IN_PROGRESS','RESOLVED') DEFAULT 'OPEN',
  "assigned_partner_id" int DEFAULT NULL,
  "resolved_by" int DEFAULT NULL,
  "resolution" text,
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "resolved_at" timestamp NULL DEFAULT NULL,
  PRIMARY KEY ("complaint_id"),
  KEY "delivery_id" ("delivery_id"),
  KEY "delivery_item_id" ("delivery_item_id"),
  KEY "customer_id" ("customer_id"),
  KEY "assigned_partner_id" ("assigned_partner_id"),
  KEY "resolved_by" ("resolved_by"),
  CONSTRAINT "delivery_complaints_ibfk_1" FOREIGN KEY ("delivery_id") REFERENCES "deliveries" ("delivery_id"),
  CONSTRAINT "delivery_complaints_ibfk_2" FOREIGN KEY ("delivery_item_id") REFERENCES "delivery_items" ("delivery_item_id"),
  CONSTRAINT "delivery_complaints_ibfk_3" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id"),
  CONSTRAINT "delivery_complaints_ibfk_4" FOREIGN KEY ("assigned_partner_id") REFERENCES "delivery_partners" ("partner_id"),
  CONSTRAINT "delivery_complaints_ibfk_5" FOREIGN KEY ("resolved_by") REFERENCES "users" ("user_id")
);

-- Data for table: delivery_complaints (1 rows)
INSERT INTO `delivery_complaints` (`complaint_id`, `delivery_id`, `delivery_item_id`, `customer_id`, `complaint_type`, `description`, `status`, `assigned_partner_id`, `resolved_by`, `resolution`, `created_at`, `resolved_at`) VALUES
(1, 2, 2, 1, 'MISSED_DELIVERY', 'The Times of India was not delivered today.', 'RESOLVED', 1, 5, 'Replacement newspaper scheduled for delivery.', '2026-09-08 12:17:05', '2026-10-26 03:20:05');

-- Table structure for: delivery_confirmations
CREATE TABLE "delivery_confirmations" (
  "confirmation_id" int NOT NULL AUTO_INCREMENT,
  "delivery_id" int NOT NULL,
  "customer_id" int NOT NULL,
  "status" enum('PENDING','CONFIRMED') DEFAULT 'PENDING',
  "confirmed_at" timestamp NULL DEFAULT NULL,
  PRIMARY KEY ("confirmation_id"),
  UNIQUE KEY "delivery_id" ("delivery_id"),
  KEY "customer_id" ("customer_id"),
  CONSTRAINT "delivery_confirmations_ibfk_1" FOREIGN KEY ("delivery_id") REFERENCES "deliveries" ("delivery_id"),
  CONSTRAINT "delivery_confirmations_ibfk_2" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id")
);

-- Data for table: delivery_confirmations (1 rows)
INSERT INTO `delivery_confirmations` (`confirmation_id`, `delivery_id`, `customer_id`, `status`, `confirmed_at`) VALUES
(1, 1, 1, 'PENDING', NULL);

-- Table structure for: delivery_failure_reasons
CREATE TABLE "delivery_failure_reasons" (
  "reason_id" int NOT NULL AUTO_INCREMENT,
  "reason_name" varchar(100) NOT NULL,
  "category" varchar(50) DEFAULT NULL,
  "charge_customer" tinyint(1) DEFAULT '0',
  PRIMARY KEY ("reason_id")
);

-- Data for table: delivery_failure_reasons (6 rows)
INSERT INTO `delivery_failure_reasons` (`reason_id`, `reason_name`, `category`, `charge_customer`) VALUES
(1, 'Customer not available', 'CUSTOMER', 0),
(2, 'Address inaccessible', 'DELIVERY', 0),
(3, 'Newspaper damaged', 'DELIVERY', 0),
(4, 'Delivery partner issue', 'DELIVERY', 0),
(5, 'Newspaper not supplied by supplier', 'SUPPLIER', 0),
(6, 'Other delivery issue', 'OTHER', 0);

-- Table structure for: delivery_items
CREATE TABLE "delivery_items" (
  "delivery_item_id" int NOT NULL AUTO_INCREMENT,
  "delivery_id" int NOT NULL,
  "subscription_id" int NOT NULL,
  "newspaper_id" int NOT NULL,
  "status" enum('DELIVERED','NOT_DELIVERED','NOT_SUPPLIED') NOT NULL DEFAULT 'DELIVERED',
  "reason_id" int DEFAULT NULL,
  "remarks" text,
  PRIMARY KEY ("delivery_item_id"),
  KEY "delivery_id" ("delivery_id"),
  KEY "subscription_id" ("subscription_id"),
  KEY "newspaper_id" ("newspaper_id"),
  KEY "reason_id" ("reason_id"),
  CONSTRAINT "delivery_items_ibfk_1" FOREIGN KEY ("delivery_id") REFERENCES "deliveries" ("delivery_id"),
  CONSTRAINT "delivery_items_ibfk_2" FOREIGN KEY ("subscription_id") REFERENCES "subscriptions" ("subscription_id"),
  CONSTRAINT "delivery_items_ibfk_3" FOREIGN KEY ("newspaper_id") REFERENCES "newspapers" ("newspaper_id"),
  CONSTRAINT "delivery_items_ibfk_4" FOREIGN KEY ("reason_id") REFERENCES "delivery_failure_reasons" ("reason_id")
);

-- Data for table: delivery_items (2 rows)
INSERT INTO `delivery_items` (`delivery_item_id`, `delivery_id`, `subscription_id`, `newspaper_id`, `status`, `reason_id`, `remarks`) VALUES
(1, 1, 1, 1, 'DELIVERED', NULL, NULL),
(2, 2, 1, 1, 'DELIVERED', 1, 'Customer was not available.');

-- Table structure for: delivery_partners
CREATE TABLE "delivery_partners" (
  "partner_id" int NOT NULL AUTO_INCREMENT,
  "user_id" int NOT NULL,
  "partner_code" varchar(20) NOT NULL,
  "emergency_contact" varchar(15) DEFAULT NULL,
  "recommended_customer_limit" int NOT NULL DEFAULT '50',
  "shift_start" time NOT NULL,
  "shift_end" time NOT NULL,
  "status" enum('AVAILABLE','ON_ROUTE','OFF_DUTY','ON_LEAVE','ABSENT','INACTIVE') DEFAULT 'AVAILABLE',
  PRIMARY KEY ("partner_id"),
  UNIQUE KEY "user_id" ("user_id"),
  UNIQUE KEY "partner_code" ("partner_code"),
  CONSTRAINT "delivery_partners_ibfk_1" FOREIGN KEY ("user_id") REFERENCES "users" ("user_id")
);

-- Data for table: delivery_partners (2 rows)
INSERT INTO `delivery_partners` (`partner_id`, `user_id`, `partner_code`, `emergency_contact`, `recommended_customer_limit`, `shift_start`, `shift_end`, `status`) VALUES
(1, 3, 'DP001', '9988776655', 50, '06:00:00', '11:00:00', 'AVAILABLE'),
(2, 4, 'DP002', '9876500012', 60, '06:00:00', '11:00:00', 'AVAILABLE');

-- Table structure for: legacy_complaint
CREATE TABLE "legacy_complaint" (
  "complaint_id" int NOT NULL AUTO_INCREMENT,
  "customer_id" int DEFAULT NULL,
  "complaint_text" varchar(500) DEFAULT NULL,
  "complaint_date" date DEFAULT NULL,
  "status" varchar(20) DEFAULT NULL,
  PRIMARY KEY ("complaint_id"),
  KEY "customer_id" ("customer_id"),
  CONSTRAINT "legacy_complaint_ibfk_1" FOREIGN KEY ("customer_id") REFERENCES "legacy_customer" ("customer_id")
);

-- Data for table: legacy_complaint (7 rows)
INSERT INTO `legacy_complaint` (`complaint_id`, `customer_id`, `complaint_text`, `complaint_date`, `status`) VALUES
(1, 1, 'Newspaper was delivered late.', '2026-08-11 18:30:00', 'Resolved'),
(2, 2, 'Newspaper was not delivered.', '2026-08-14 18:30:00', 'Resolved'),
(3, 3, 'Newspaper was damaged.', '2026-08-15 18:30:00', 'Resolved'),
(4, 5, 'Delivery person missed the delivery.', '2026-08-16 18:30:00', 'Pending'),
(6, 1, 'Temporary complaint for DELETE demonstration.', '2026-08-17 18:30:00', 'Pending'),
(7, 1, 'Temporary complaint for DELETE demonstration.', '2026-08-17 18:30:00', 'Pending'),
(8, 1, 'Temporary complaint for DELETE demonstration.', '2026-08-17 18:30:00', 'Pending');

-- Table structure for: legacy_customer
CREATE TABLE "legacy_customer" (
  "customer_id" int NOT NULL AUTO_INCREMENT,
  "name" varchar(100) NOT NULL,
  "phone" varchar(15) DEFAULT NULL,
  "email" varchar(100) DEFAULT NULL,
  "address" varchar(255) DEFAULT NULL,
  PRIMARY KEY ("customer_id")
);

-- Data for table: legacy_customer (5 rows)
INSERT INTO `legacy_customer` (`customer_id`, `name`, `phone`, `email`, `address`) VALUES
(1, 'Aarav Sharma', '9876500000', 'aarav@gmail.com', 'Wadala, Mumbai'),
(2, 'Riya Patil', '9876543211', 'riya@gmail.com', 'Dadar, Mumbai'),
(3, 'Kabir Mehta', '9876543212', 'kabir@gmail.com', 'Sion, Mumbai'),
(4, 'Ananya Joshi', '9876543213', 'ananya@gmail.com', 'Matunga, Mumbai'),
(5, 'Vihaan Shah', '9876543214', 'vihaan@gmail.com', 'Kurla, Mumbai');

-- Table structure for: legacy_delivery
CREATE TABLE "legacy_delivery" (
  "delivery_id" int NOT NULL AUTO_INCREMENT,
  "subscription_id" int DEFAULT NULL,
  "delivery_person_id" int DEFAULT NULL,
  "delivery_date" date DEFAULT NULL,
  "delivery_status" varchar(20) DEFAULT NULL,
  PRIMARY KEY ("delivery_id"),
  KEY "subscription_id" ("subscription_id"),
  KEY "delivery_person_id" ("delivery_person_id"),
  CONSTRAINT "legacy_delivery_ibfk_1" FOREIGN KEY ("subscription_id") REFERENCES "legacy_subscription" ("subscription_id"),
  CONSTRAINT "legacy_delivery_ibfk_2" FOREIGN KEY ("delivery_person_id") REFERENCES "legacy_delivery_person" ("delivery_person_id")
);

-- Data for table: legacy_delivery (5 rows)
INSERT INTO `legacy_delivery` (`delivery_id`, `subscription_id`, `delivery_person_id`, `delivery_date`, `delivery_status`) VALUES
(1, 1, 1, '2026-08-17 18:30:00', 'Delivered'),
(2, 2, 2, '2026-08-17 18:30:00', 'Delivered'),
(3, 3, 3, '2026-08-17 18:30:00', 'Pending'),
(4, 4, 1, '2026-08-17 18:30:00', 'Paused'),
(5, 5, 2, '2026-08-17 18:30:00', 'Delivered');

-- Table structure for: legacy_delivery_person
CREATE TABLE "legacy_delivery_person" (
  "delivery_person_id" int NOT NULL AUTO_INCREMENT,
  "name" varchar(100) NOT NULL,
  "phone" varchar(15) DEFAULT NULL,
  "address" varchar(255) DEFAULT NULL,
  PRIMARY KEY ("delivery_person_id")
);

-- Data for table: legacy_delivery_person (3 rows)
INSERT INTO `legacy_delivery_person` (`delivery_person_id`, `name`, `phone`, `address`) VALUES
(1, 'Rahul More', '9988776655', 'Wadala, Mumbai'),
(2, 'Sneha Kulkarni', '9988776656', 'Dadar, Mumbai'),
(3, 'Amit Yadav', '9988776657', 'Sion, Mumbai');

-- Table structure for: legacy_department
CREATE TABLE "legacy_department" (
  "department_id" int NOT NULL,
  "department_name" varchar(100) NOT NULL,
  PRIMARY KEY ("department_id")
);

-- Data for table: legacy_department (4 rows)
INSERT INTO `legacy_department` (`department_id`, `department_name`) VALUES
(1, 'HR'),
(2, 'IT'),
(3, 'Marketing'),
(4, 'Finance');

-- Table structure for: legacy_employee
CREATE TABLE "legacy_employee" (
  "emp_id" int NOT NULL,
  "emp_name" varchar(100) NOT NULL,
  "salary" decimal(10,2) DEFAULT NULL,
  "department_id" int DEFAULT NULL,
  PRIMARY KEY ("emp_id"),
  KEY "fk_department" ("department_id"),
  CONSTRAINT "fk_department" FOREIGN KEY ("department_id") REFERENCES "legacy_department" ("department_id"),
  CONSTRAINT "chk_salary" CHECK ((`salary` > 0))
);

-- Data for table: legacy_employee (10 rows)
INSERT INTO `legacy_employee` (`emp_id`, `emp_name`, `salary`, `department_id`) VALUES
(101, 'Amit', '30000.00', 1),
(102, 'Rahul', '45000.00', 2),
(103, 'Priya', '40000.00', 3),
(104, 'Neha', '50000.00', 3),
(105, 'Rohan', '35000.00', 2),
(106, 'Sneha', '55000.00', 3),
(107, 'Vikas', '25000.00', 1),
(108, 'Anjali', '60000.00', 4),
(109, 'Karan', '42000.00', 3),
(110, 'Pooja', '38000.00', 3);

-- Table structure for: legacy_newspaper
CREATE TABLE "legacy_newspaper" (
  "newspaper_id" int NOT NULL AUTO_INCREMENT,
  "newspaper_name" varchar(100) NOT NULL,
  "language" varchar(50) DEFAULT NULL,
  "price" decimal(10,2) DEFAULT NULL,
  PRIMARY KEY ("newspaper_id")
);

-- Data for table: legacy_newspaper (5 rows)
INSERT INTO `legacy_newspaper` (`newspaper_id`, `newspaper_name`, `language`, `price`) VALUES
(1, 'Times of India', 'English', '6.00'),
(2, 'Hindustan Times', 'English', '5.00'),
(3, 'Loksatta', 'Marathi', '5.00'),
(4, 'Maharashtra Times', 'Marathi', '6.00'),
(5, 'The Hindu', 'English', '7.00');

-- Table structure for: legacy_payment
CREATE TABLE "legacy_payment" (
  "payment_id" int NOT NULL AUTO_INCREMENT,
  "customer_id" int DEFAULT NULL,
  "amount" decimal(10,2) DEFAULT NULL,
  "payment_date" date DEFAULT NULL,
  "payment_status" varchar(20) DEFAULT NULL,
  PRIMARY KEY ("payment_id"),
  KEY "customer_id" ("customer_id"),
  CONSTRAINT "legacy_payment_ibfk_1" FOREIGN KEY ("customer_id") REFERENCES "legacy_customer" ("customer_id")
);

-- Data for table: legacy_payment (5 rows)
INSERT INTO `legacy_payment` (`payment_id`, `customer_id`, `amount`, `payment_date`, `payment_status`) VALUES
(1, 1, '180.00', '2026-07-31 18:30:00', 'Paid'),
(2, 2, '150.00', '2026-07-31 18:30:00', 'Paid'),
(3, 3, '150.00', '2026-08-04 18:30:00', 'Paid'),
(4, 4, '180.00', '2026-08-09 18:30:00', 'Pending'),
(5, 5, '210.00', '2026-07-31 18:30:00', 'Paid');

-- Table structure for: legacy_subscription
CREATE TABLE "legacy_subscription" (
  "subscription_id" int NOT NULL AUTO_INCREMENT,
  "customer_id" int DEFAULT NULL,
  "newspaper_id" int DEFAULT NULL,
  "start_date" date DEFAULT NULL,
  "end_date" date DEFAULT NULL,
  "status" varchar(20) DEFAULT NULL,
  PRIMARY KEY ("subscription_id"),
  KEY "customer_id" ("customer_id"),
  KEY "newspaper_id" ("newspaper_id"),
  CONSTRAINT "legacy_subscription_ibfk_1" FOREIGN KEY ("customer_id") REFERENCES "legacy_customer" ("customer_id"),
  CONSTRAINT "legacy_subscription_ibfk_2" FOREIGN KEY ("newspaper_id") REFERENCES "legacy_newspaper" ("newspaper_id")
);

-- Data for table: legacy_subscription (5 rows)
INSERT INTO `legacy_subscription` (`subscription_id`, `customer_id`, `newspaper_id`, `start_date`, `end_date`, `status`) VALUES
(1, 1, 1, '2026-07-31 18:30:00', '2026-08-30 18:30:00', 'Paused'),
(2, 2, 3, '2026-07-31 18:30:00', '2026-08-30 18:30:00', 'Active'),
(3, 3, 2, '2026-08-04 18:30:00', '2026-09-04 18:30:00', 'Active'),
(4, 4, 4, '2026-08-09 18:30:00', '2026-09-09 18:30:00', 'Paused'),
(5, 5, 5, '2026-07-31 18:30:00', '2026-08-30 18:30:00', 'Active');

-- Table structure for: legacy_supplier
CREATE TABLE "legacy_supplier" (
  "supplier_id" int NOT NULL AUTO_INCREMENT,
  "name" varchar(100) NOT NULL,
  "phone" varchar(15) DEFAULT NULL,
  "email" varchar(100) DEFAULT NULL,
  PRIMARY KEY ("supplier_id")
);

-- Data for table: legacy_supplier (3 rows)
INSERT INTO `legacy_supplier` (`supplier_id`, `name`, `phone`, `email`) VALUES
(1, 'Mumbai News Agency', '9123456780', 'mumbainews@gmail.com'),
(2, 'Daily Press Suppliers', '9123456781', 'dailypress@gmail.com'),
(3, 'City Newspaper Hub', '9123456782', 'cityhub@gmail.com');

-- Table structure for: newspaper_prices
CREATE TABLE "newspaper_prices" (
  "price_id" int NOT NULL AUTO_INCREMENT,
  "newspaper_id" int NOT NULL,
  "price_per_delivery" decimal(10,2) NOT NULL,
  "effective_from" date NOT NULL,
  "effective_until" date DEFAULT NULL,
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("price_id"),
  KEY "newspaper_id" ("newspaper_id"),
  CONSTRAINT "newspaper_prices_ibfk_1" FOREIGN KEY ("newspaper_id") REFERENCES "newspapers" ("newspaper_id")
);

-- Data for table: newspaper_prices (7 rows)
INSERT INTO `newspaper_prices` (`price_id`, `newspaper_id`, `price_per_delivery`, `effective_from`, `effective_until`, `created_at`) VALUES
(1, 1, '6.00', '2025-12-31 18:30:00', NULL, '2026-09-08 11:55:13'),
(2, 2, '5.00', '2025-12-31 18:30:00', NULL, '2026-09-08 11:55:13'),
(3, 3, '5.00', '2025-12-31 18:30:00', NULL, '2026-09-08 11:55:13'),
(4, 4, '4.00', '2025-12-31 18:30:00', NULL, '2026-09-08 11:55:13'),
(5, 5, '5.00', '2025-12-31 18:30:00', NULL, '2026-09-08 11:55:13'),
(6, 6, '4.00', '2025-12-31 18:30:00', NULL, '2026-09-08 11:55:13'),
(7, 7, '6.00', '2025-12-31 18:30:00', NULL, '2026-09-08 11:55:13');

-- Table structure for: newspapers
CREATE TABLE "newspapers" (
  "newspaper_id" int NOT NULL AUTO_INCREMENT,
  "newspaper_name" varchar(150) NOT NULL,
  "language" varchar(50) DEFAULT NULL,
  "publication_type" varchar(50) DEFAULT NULL,
  "status" enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  PRIMARY KEY ("newspaper_id")
);

-- Data for table: newspapers (7 rows)
INSERT INTO `newspapers` (`newspaper_id`, `newspaper_name`, `language`, `publication_type`, `status`) VALUES
(1, 'The Times of India', 'English', 'National', 'ACTIVE'),
(2, 'Hindustan Times', 'English', 'National', 'ACTIVE'),
(3, 'Loksatta', 'Marathi', 'Regional', 'ACTIVE'),
(4, 'Mumbai Chronicle', 'English', 'Local', 'ACTIVE'),
(5, 'Maharashtra Today', 'Marathi', 'Regional', 'ACTIVE'),
(6, 'City Morning', 'English', 'Local', 'ACTIVE'),
(7, 'The Daily Herald', 'English', 'National', 'ACTIVE');

-- Table structure for: notifications
CREATE TABLE "notifications" (
  "notification_id" int NOT NULL AUTO_INCREMENT,
  "user_id" int NOT NULL,
  "notification_type" varchar(50) NOT NULL,
  "title" varchar(150) NOT NULL,
  "message" text NOT NULL,
  "reference_type" varchar(50) DEFAULT NULL,
  "reference_id" int DEFAULT NULL,
  "is_read" tinyint(1) DEFAULT '0',
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("notification_id"),
  KEY "user_id" ("user_id"),
  CONSTRAINT "notifications_ibfk_1" FOREIGN KEY ("user_id") REFERENCES "users" ("user_id")
);

-- Data for table: notifications (3 rows)
INSERT INTO `notifications` (`notification_id`, `user_id`, `notification_type`, `title`, `message`, `reference_type`, `reference_id`, `is_read`, `created_at`) VALUES
(1, 1, 'REQUEST', 'Delivery Issue Resolved', 'Your missed delivery complaint has been resolved. A replacement newspaper has been scheduled.', 'COMPLAINT', 1, 1, '2026-09-08 12:19:26'),
(2, 1, 'PAYMENT', 'Payment Successful', 'Your payment of ₹156.00 for The Times of India subscription was successful.', 'PAYMENT', 1, 1, '2026-09-08 12:23:24'),
(3, 1, 'PAYMENT', 'Payment Successful', 'Your payment of ₹156.00 for The Times of India subscription was successful.', 'PAYMENT', 1, 1, '2026-09-08 12:24:18');

-- Table structure for: partner_leave
CREATE TABLE "partner_leave" (
  "leave_id" int NOT NULL AUTO_INCREMENT,
  "partner_id" int NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "leave_type" varchar(50) DEFAULT 'REGULAR',
  "status" enum('APPROVED','CANCELLED') DEFAULT 'APPROVED',
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("leave_id"),
  KEY "partner_id" ("partner_id"),
  CONSTRAINT "partner_leave_ibfk_1" FOREIGN KEY ("partner_id") REFERENCES "delivery_partners" ("partner_id")
);

-- Table structure for: partner_payments
CREATE TABLE "partner_payments" (
  "partner_payment_id" int NOT NULL AUTO_INCREMENT,
  "partner_id" int NOT NULL,
  "payment_period" varchar(20) NOT NULL,
  "amount" decimal(10,2) NOT NULL,
  "status" enum('PENDING','PAID') DEFAULT 'PENDING',
  "paid_at" timestamp NULL DEFAULT NULL,
  PRIMARY KEY ("partner_payment_id"),
  KEY "partner_id" ("partner_id"),
  CONSTRAINT "partner_payments_ibfk_1" FOREIGN KEY ("partner_id") REFERENCES "delivery_partners" ("partner_id")
);

-- Table structure for: partner_vehicles
CREATE TABLE "partner_vehicles" (
  "vehicle_id" int NOT NULL AUTO_INCREMENT,
  "partner_id" int NOT NULL,
  "vehicle_type" varchar(50) DEFAULT NULL,
  "registration_number" varchar(30) DEFAULT NULL,
  "status" enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  PRIMARY KEY ("vehicle_id"),
  KEY "partner_id" ("partner_id"),
  CONSTRAINT "partner_vehicles_ibfk_1" FOREIGN KEY ("partner_id") REFERENCES "delivery_partners" ("partner_id")
);

-- Table structure for: payments
CREATE TABLE "payments" (
  "payment_id" int NOT NULL AUTO_INCREMENT,
  "bill_id" int NOT NULL,
  "customer_id" int NOT NULL,
  "amount" decimal(10,2) NOT NULL,
  "payment_method" varchar(50) DEFAULT NULL,
  "transaction_reference" varchar(100) DEFAULT NULL,
  "payment_date" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "status" enum('SUCCESS','FAILED','PENDING') DEFAULT 'PENDING',
  PRIMARY KEY ("payment_id"),
  KEY "bill_id" ("bill_id"),
  KEY "customer_id" ("customer_id"),
  CONSTRAINT "payments_ibfk_1" FOREIGN KEY ("bill_id") REFERENCES "bills" ("bill_id"),
  CONSTRAINT "payments_ibfk_2" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id")
);

-- Data for table: payments (2 rows)
INSERT INTO `payments` (`payment_id`, `bill_id`, `customer_id`, `amount`, `payment_method`, `transaction_reference`, `payment_date`, `status`) VALUES
(1, 1, 1, '156.00', 'UPI', 'UPI202609080001', '2026-09-08 12:21:49', 'SUCCESS'),
(2, 2, 2, '130.00', 'UPI', 'UPI202609080002', '2026-09-08 12:28:07', 'FAILED');

-- Table structure for: route_partners
CREATE TABLE "route_partners" (
  "route_partner_id" int NOT NULL AUTO_INCREMENT,
  "daily_route_id" int NOT NULL,
  "partner_id" int NOT NULL,
  "shift_start" time NOT NULL,
  "shift_end" time NOT NULL,
  PRIMARY KEY ("route_partner_id"),
  UNIQUE KEY "daily_route_id" ("daily_route_id","partner_id"),
  KEY "partner_id" ("partner_id"),
  CONSTRAINT "route_partners_ibfk_1" FOREIGN KEY ("daily_route_id") REFERENCES "daily_routes" ("daily_route_id"),
  CONSTRAINT "route_partners_ibfk_2" FOREIGN KEY ("partner_id") REFERENCES "delivery_partners" ("partner_id")
);

-- Data for table: route_partners (1 rows)
INSERT INTO `route_partners` (`route_partner_id`, `daily_route_id`, `partner_id`, `shift_start`, `shift_end`) VALUES
(1, 1, 1, '06:00:00', '11:00:00');

-- Table structure for: routes
CREATE TABLE "routes" (
  "route_id" int NOT NULL AUTO_INCREMENT,
  "area_id" int NOT NULL,
  "route_name" varchar(100) NOT NULL,
  "status" enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  PRIMARY KEY ("route_id"),
  KEY "area_id" ("area_id"),
  CONSTRAINT "routes_ibfk_1" FOREIGN KEY ("area_id") REFERENCES "areas" ("area_id")
);

-- Data for table: routes (1 rows)
INSERT INTO `routes` (`route_id`, `area_id`, `route_name`, `status`) VALUES
(1, 1, 'Dadar West Morning Route', 'ACTIVE');

-- Table structure for: subscription_pauses
CREATE TABLE "subscription_pauses" (
  "pause_id" int NOT NULL AUTO_INCREMENT,
  "subscription_id" int NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "reason" varchar(255) DEFAULT NULL,
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("pause_id"),
  KEY "subscription_id" ("subscription_id"),
  CONSTRAINT "subscription_pauses_ibfk_1" FOREIGN KEY ("subscription_id") REFERENCES "subscriptions" ("subscription_id")
);

-- Data for table: subscription_pauses (1 rows)
INSERT INTO `subscription_pauses` (`pause_id`, `subscription_id`, `start_date`, `end_date`, `reason`, `created_at`) VALUES
(1, 1, '2026-09-09 18:30:00', '2026-09-11 18:30:00', 'Customer requested a temporary pause.', '2026-09-08 12:33:43');

-- Table structure for: subscriptions
CREATE TABLE "subscriptions" (
  "subscription_id" int NOT NULL AUTO_INCREMENT,
  "customer_id" int NOT NULL,
  "newspaper_id" int NOT NULL,
  "supplier_id" int NOT NULL,
  "address_id" int NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date DEFAULT NULL,
  "status" enum('ACTIVE','PAUSED','CANCELLED') DEFAULT 'ACTIVE',
  "delivery_days" varchar(50) NOT NULL,
  "scheduled_delivery_time" time NOT NULL,
  "agreed_price" decimal(10,2) NOT NULL,
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("subscription_id"),
  KEY "customer_id" ("customer_id"),
  KEY "newspaper_id" ("newspaper_id"),
  KEY "supplier_id" ("supplier_id"),
  KEY "address_id" ("address_id"),
  CONSTRAINT "subscriptions_ibfk_1" FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id"),
  CONSTRAINT "subscriptions_ibfk_2" FOREIGN KEY ("newspaper_id") REFERENCES "newspapers" ("newspaper_id"),
  CONSTRAINT "subscriptions_ibfk_3" FOREIGN KEY ("supplier_id") REFERENCES "suppliers" ("supplier_id"),
  CONSTRAINT "subscriptions_ibfk_4" FOREIGN KEY ("address_id") REFERENCES "customer_addresses" ("address_id")
);

-- Data for table: subscriptions (12 rows)
INSERT INTO `subscriptions` (`subscription_id`, `customer_id`, `newspaper_id`, `supplier_id`, `address_id`, `start_date`, `end_date`, `status`, `delivery_days`, `scheduled_delivery_time`, `agreed_price`, `created_at`) VALUES
(1, 1, 1, 1, 1, '2026-08-31 18:30:00', '2026-09-07 18:30:00', 'CANCELLED', 'MON,TUE,WED,THU,FRI,SAT', '07:00:00', '6.00', '2026-09-08 11:57:36'),
(2, 2, 3, 1, 2, '2026-08-31 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT', '06:45:00', '5.00', '2026-09-08 11:58:13'),
(3, 1, 2, 1, 3, '2026-09-08 18:30:00', NULL, 'CANCELLED', 'MON,TUE,WED,THU,FRI,SAT', '07:30:00', '5.00', '2026-09-08 12:36:48'),
(4, 1, 1, 2, 3, '2026-09-08 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT', '07:00:00', '6.00', '2026-09-08 12:52:39'),
(5, 1, 3, 1, 3, '2026-09-29 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT,SUN', '07:00:00', '5.00', '2026-09-30 00:30:04'),
(6, 1, 2, 1, 3, '2026-09-30 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT,SUN', '07:00:00', '5.00', '2026-10-01 11:34:39'),
(7, 1, 6, 1, 3, '2026-10-13 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT,SUN', '07:00:00', '4.00', '2026-10-13 22:50:25'),
(8, 1, 6, 1, 3, '2026-10-13 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT,SUN', '07:00:00', '4.00', '2026-10-13 22:56:34'),
(9, 2, 5, 1, 2, '2026-10-13 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT,SUN', '07:00:00', '5.00', '2026-10-14 01:58:01'),
(10, 2, 7, 1, 2, '2026-10-13 18:30:00', NULL, 'PAUSED', 'MON,TUE,WED,THU,FRI,SAT,SUN', '07:00:00', '6.00', '2026-10-14 01:58:39'),
(11, 1, 6, 1, 3, '2026-10-18 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT,SUN', '07:00:00', '4.00', '2026-10-19 05:04:11'),
(12, 1, 3, 1, 3, '2026-10-18 18:30:00', NULL, 'ACTIVE', 'MON,TUE,WED,THU,FRI,SAT,SUN', '07:00:00', '5.00', '2026-10-19 05:08:59');

-- Table structure for: supplier_areas
CREATE TABLE "supplier_areas" (
  "supplier_area_id" int NOT NULL AUTO_INCREMENT,
  "supplier_id" int NOT NULL,
  "area_id" int NOT NULL,
  "status" enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  PRIMARY KEY ("supplier_area_id"),
  UNIQUE KEY "supplier_id" ("supplier_id","area_id"),
  KEY "area_id" ("area_id"),
  CONSTRAINT "supplier_areas_ibfk_1" FOREIGN KEY ("supplier_id") REFERENCES "suppliers" ("supplier_id"),
  CONSTRAINT "supplier_areas_ibfk_2" FOREIGN KEY ("area_id") REFERENCES "areas" ("area_id")
);

-- Data for table: supplier_areas (7 rows)
INSERT INTO `supplier_areas` (`supplier_area_id`, `supplier_id`, `area_id`, `status`) VALUES
(1, 1, 1, 'ACTIVE'),
(2, 1, 2, 'ACTIVE'),
(3, 1, 3, 'ACTIVE'),
(4, 1, 4, 'ACTIVE'),
(5, 1, 5, 'ACTIVE'),
(6, 2, 4, 'ACTIVE'),
(7, 2, 1, 'ACTIVE');

-- Table structure for: supplier_newspapers
CREATE TABLE "supplier_newspapers" (
  "supplier_newspaper_id" int NOT NULL AUTO_INCREMENT,
  "supplier_id" int NOT NULL,
  "newspaper_id" int NOT NULL,
  "status" enum('ACTIVE','TEMPORARILY_UNAVAILABLE','INACTIVE') DEFAULT 'ACTIVE',
  "available_from" date DEFAULT NULL,
  "available_until" date DEFAULT NULL,
  PRIMARY KEY ("supplier_newspaper_id"),
  UNIQUE KEY "supplier_id" ("supplier_id","newspaper_id"),
  KEY "newspaper_id" ("newspaper_id"),
  CONSTRAINT "supplier_newspapers_ibfk_1" FOREIGN KEY ("supplier_id") REFERENCES "suppliers" ("supplier_id"),
  CONSTRAINT "supplier_newspapers_ibfk_2" FOREIGN KEY ("newspaper_id") REFERENCES "newspapers" ("newspaper_id")
);

-- Data for table: supplier_newspapers (8 rows)
INSERT INTO `supplier_newspapers` (`supplier_newspaper_id`, `supplier_id`, `newspaper_id`, `status`, `available_from`, `available_until`) VALUES
(1, 1, 1, 'TEMPORARILY_UNAVAILABLE', '2025-12-31 18:30:00', NULL),
(2, 1, 2, 'ACTIVE', '2025-12-31 18:30:00', NULL),
(3, 1, 3, 'ACTIVE', '2025-12-31 18:30:00', NULL),
(4, 1, 4, 'ACTIVE', '2025-12-31 18:30:00', NULL),
(5, 1, 5, 'ACTIVE', '2025-12-31 18:30:00', NULL),
(6, 1, 6, 'ACTIVE', '2025-12-31 18:30:00', NULL),
(7, 1, 7, 'ACTIVE', '2025-12-31 18:30:00', NULL),
(8, 2, 1, 'ACTIVE', '2025-12-31 18:30:00', NULL);

-- Table structure for: suppliers
CREATE TABLE "suppliers" (
  "supplier_id" int NOT NULL AUTO_INCREMENT,
  "user_id" int NOT NULL,
  "supplier_name" varchar(150) NOT NULL,
  "contact_number" varchar(15) DEFAULT NULL,
  "address" text,
  "status" enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("supplier_id"),
  UNIQUE KEY "user_id" ("user_id"),
  CONSTRAINT "suppliers_ibfk_1" FOREIGN KEY ("user_id") REFERENCES "users" ("user_id")
);

-- Data for table: suppliers (2 rows)
INSERT INTO `suppliers` (`supplier_id`, `user_id`, `supplier_name`, `contact_number`, `address`, `status`, `created_at`) VALUES
(1, 5, 'Mumbai Daily Distributors', '9876543214', 'Dadar West, Mumbai', 'ACTIVE', '2026-09-08 11:51:19'),
(2, 6, 'Western News Distributors', '9876543215', 'Bandra West, Mumbai', 'ACTIVE', '2026-09-08 12:49:20');

-- Table structure for: users
CREATE TABLE "users" (
  "user_id" int NOT NULL AUTO_INCREMENT,
  "name" varchar(100) NOT NULL,
  "email" varchar(150) DEFAULT NULL,
  "phone" varchar(15) DEFAULT NULL,
  "password_hash" varchar(255) DEFAULT NULL,
  "role" enum('CUSTOMER','SUPPLIER','DELIVERY_PARTNER') NOT NULL,
  "status" enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "auth_provider" enum('PASSWORD','GOOGLE') NOT NULL DEFAULT 'PASSWORD',
  "provider_user_id" varchar(255) DEFAULT NULL,
  PRIMARY KEY ("user_id"),
  UNIQUE KEY "email" ("email"),
  UNIQUE KEY "phone" ("phone")
);

-- Data for table: users (6 rows)
INSERT INTO `users` (`user_id`, `name`, `email`, `phone`, `password_hash`, `role`, `status`, `created_at`, `auth_provider`, `provider_user_id`) VALUES
(1, 'Aarav Sharma', 'aarav@gmail.com', '9876543210', '123456', 'CUSTOMER', 'ACTIVE', '2026-09-08 11:48:36', 'PASSWORD', NULL),
(2, 'Priya Deshmukh', 'priya@gmail.com', '9876543211', 'demo_hash_123', 'CUSTOMER', 'ACTIVE', '2026-09-08 11:48:36', 'PASSWORD', NULL),
(3, 'Rahul Patil', 'rahul@daily.com', '9876543212', 'demo_hash_123', 'DELIVERY_PARTNER', 'ACTIVE', '2026-09-08 11:48:36', 'PASSWORD', NULL),
(4, 'Amit Kulkarni', 'amit@daily.com', '9876543213', 'demo_hash_123', 'DELIVERY_PARTNER', 'ACTIVE', '2026-09-08 11:48:36', 'PASSWORD', NULL),
(5, 'Mumbai Daily Admin', 'admin@mumbaidaily.com', '9876543214', 'demo_hash_123', 'SUPPLIER', 'ACTIVE', '2026-09-08 11:48:36', 'PASSWORD', NULL),
(6, 'Western News Admin', 'admin@westernnews.com', '9876543215', 'demo_hash_456', 'SUPPLIER', 'ACTIVE', '2026-09-08 12:49:11', 'PASSWORD', NULL);

SET FOREIGN_KEY_CHECKS = 1;
-- Backup Completed Successfully
