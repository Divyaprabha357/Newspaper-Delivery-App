const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const db = require("./db");
const PARTNER_EARNING_PER_DELIVERY = 10;
const app = express();

app.use(cors());
app.use(express.json());

const activeSessions = new Map();

function createSession(userId, role) {
    const token = crypto.randomBytes(32).toString("hex");
    activeSessions.set(token, {
        userId,
        role,
        expiresAt: Date.now() + 1000 * 60 * 60 * 12
    });
    return token;
}

function hashPassword(password) {
    const salt = crypto.randomBytes(16).toString("hex");
    const hash = crypto.scryptSync(password, salt, 64).toString("hex");
    return `scrypt:${salt}:${hash}`;
}

function verifyPassword(password, storedHash) {
    if (!storedHash || !password) return false;
    // Backward compatibility with legacy plain text passwords in the database
    if (storedHash === password) {
        return true;
    }
    // Standard scrypt hashed password (scrypt:salt:hash)
    if (typeof storedHash === "string" && storedHash.startsWith("scrypt:")) {
        const parts = storedHash.split(":");
        if (parts.length === 3) {
            const salt = parts[1];
            const originalHash = parts[2];
            const hash = crypto.scryptSync(password, salt, 64).toString("hex");
            if (hash.length === originalHash.length) {
                return crypto.timingSafeEqual(Buffer.from(hash, "hex"), Buffer.from(originalHash, "hex"));
            }
        }
    }
    // SHA-256 fallback if any legacy hash was stored as sha256
    const sha256 = crypto.createHash("sha256").update(password).digest("hex");
    if (storedHash === sha256) {
        return true;
    }
    return false;
}


// =========================================
// ROOT
// =========================================

app.get("/", (req, res) => {
    res.send("DAILY backend is running!");
});


// =========================================
// DATABASE TEST
// =========================================

app.get("/api/db-test", (req, res) => {

    db.query("SELECT 1 AS test", (err, results) => {

        if (err) {
            console.error("Database error:", err);

            return res.status(500).json({
                success: false,
                message: "Database connection failed"
            });
        }

        res.json({
            success: true,
            message: "Database connected successfully",
            result: results
        });

    });

});


// =========================================
// CUSTOMERS
// =========================================

app.get("/api/customers", (req, res) => {

    const sql = `
        SELECT
            c.customer_id,
            u.name,
            u.email,
            u.phone,
            c.customer_code,
            c.date_of_birth,
            c.status

        FROM customers c

        JOIN users u
            ON c.user_id = u.user_id

        ORDER BY c.customer_id;
    `;

    db.query(sql, (err, results) => {

        if (err) {

            console.error(
                "Error fetching customers:",
                err
            );

            return res.status(500).json({
                success: false,
                message: "Failed to fetch customers"
            });

        }

        res.json({
            success: true,
            customers: results
        });

    });

});


// =========================================
// CUSTOMER REGISTRATION
// =========================================

const handleCustomerRegister = async (req, res) => {
    try {
        const {
            name,
            fullName,
            email,
            phone,
            phoneNumber,
            password,
            address,
            deliveryAddress,
            city,
            pincode,
            preferred_delivery_time,
            preferredDeliveryTime
        } = req.body;

        const customerName = (name || fullName || "").trim();
        const rawEmail = (email || "").trim();
        const rawPhone = (phone || phoneNumber || "").trim();
        const customerAddress = (address || deliveryAddress || "").trim();
        const preferredTime = preferred_delivery_time || preferredDeliveryTime || "Morning (06:00 - 08:00 AM)";

        if (!customerName) {
            return res.status(400).json({ success: false, message: "Full name is required" });
        }
        if (!rawEmail) {
            return res.status(400).json({ success: false, message: "Email address is required" });
        }
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(rawEmail)) {
            return res.status(400).json({ success: false, message: "Please enter a valid email address" });
        }
        if (!rawPhone) {
            return res.status(400).json({ success: false, message: "Phone number is required" });
        }
        const cleanPhone = rawPhone.replace(/[^\d+]/g, "");
        if (cleanPhone.length < 10) {
            return res.status(400).json({ success: false, message: "Phone number must be at least 10 digits" });
        }
        if (!customerAddress) {
            return res.status(400).json({ success: false, message: "Delivery address is required" });
        }
        if (!password) {
            return res.status(400).json({ success: false, message: "Password is required" });
        }
        if (password.length < 6) {
            return res.status(400).json({ success: false, message: "Password must be at least 6 characters long" });
        }

        const normalizedEmail = rawEmail.toLowerCase();

        // Check for duplicates
        const [existing] = await db.promise().query(
            "SELECT user_id, email, phone FROM users WHERE LOWER(email) = ? OR phone = ? LIMIT 1",
            [normalizedEmail, cleanPhone]
        );

        if (existing && existing.length > 0) {
            const isEmail = existing[0].email && existing[0].email.toLowerCase() === normalizedEmail;
            return res.status(409).json({
                success: false,
                message: isEmail
                    ? "An account with this email address already exists"
                    : "An account with this phone number already exists"
            });
        }

        // Start transaction
        await db.promise().query("START TRANSACTION");
        try {
            const passwordHash = hashPassword(password);

            // 1. Insert into users
            const [userResult] = await db.promise().query(
                `INSERT INTO users (name, email, phone, password_hash, role, status, auth_provider)
                 VALUES (?, ?, ?, ?, 'CUSTOMER', 'ACTIVE', 'PASSWORD')`,
                [customerName, normalizedEmail, cleanPhone, passwordHash]
            );
            const userId = userResult.insertId;

            // 2. Generate customer code (e.g. CUST003)
            const [maxCust] = await db.promise().query("SELECT MAX(customer_id) AS maxId FROM customers");
            const nextCustNum = (maxCust[0]?.maxId || 0) + 1;
            const customerCode = `CUST${String(nextCustNum).padStart(3, "0")}`;

            // Insert into customers
            const [custResult] = await db.promise().query(
                `INSERT INTO customers (user_id, customer_code, status)
                 VALUES (?, ?, 'ACTIVE')`,
                [userId, customerCode]
            );
            const customerId = custResult.insertId;

            // 3. Insert into customer_addresses
            await db.promise().query(
                `INSERT INTO customer_addresses (customer_id, address_line, area_id, city, pincode, delivery_instructions, is_active, effective_from)
                 VALUES (?, ?, 1, ?, ?, ?, 1, CURDATE())`,
                [
                    customerId,
                    customerAddress,
                    (city || "Mumbai").trim(),
                    (pincode || "400001").trim(),
                    preferredTime
                ]
            );

            await db.promise().query("COMMIT");

            const sessionToken = createSession(userId, "CUSTOMER");

            return res.status(201).json({
                success: true,
                message: "Customer account created successfully",
                user: {
                    user_id: userId,
                    customer_id: customerId,
                    customer_code: customerCode,
                    name: customerName,
                    email: normalizedEmail,
                    phone: cleanPhone,
                    role: "CUSTOMER",
                    session_token: sessionToken
                }
            });
        } catch (txErr) {
            await db.promise().query("ROLLBACK");
            console.error("Customer registration transaction error:", txErr);
            return res.status(500).json({
                success: false,
                message: "Failed to create customer account. Please try again."
            });
        }
    } catch (err) {
        console.error("Customer registration server error:", err);
        return res.status(500).json({
            success: false,
            message: "Internal server error"
        });
    }
};

app.post("/api/customer/register", handleCustomerRegister);
app.post("/api/register", handleCustomerRegister);


// =========================================
// DELIVERY PARTNER REGISTRATION
// =========================================

app.post("/api/partner/register", async (req, res) => {
    try {
        const {
            name,
            fullName,
            email,
            phone,
            phoneNumber,
            password,
            emergency_contact,
            emergencyContact,
            vehicle_type,
            vehicleType,
            registration_number,
            registrationNumber,
            shift_start,
            shiftStart,
            shift_end,
            shiftEnd
        } = req.body;

        const partnerName = (name || fullName || "").trim();
        const rawEmail = (email || "").trim();
        const rawPhone = (phone || phoneNumber || "").trim();
        const emergency = (emergency_contact || emergencyContact || "").trim();
        const vehicle = (vehicle_type || vehicleType || "Motorcycle").trim();
        const regNumber = (registration_number || registrationNumber || "").trim();
        const start = shift_start || shiftStart || "06:00:00";
        const end = shift_end || shiftEnd || "11:00:00";

        if (!partnerName) {
            return res.status(400).json({ success: false, message: "Full name is required" });
        }
        if (!rawEmail) {
            return res.status(400).json({ success: false, message: "Email address is required" });
        }
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(rawEmail)) {
            return res.status(400).json({ success: false, message: "Please enter a valid email address" });
        }
        if (!rawPhone) {
            return res.status(400).json({ success: false, message: "Phone number is required" });
        }
        const cleanPhone = rawPhone.replace(/[^\d+]/g, "");
        if (cleanPhone.length < 10) {
            return res.status(400).json({ success: false, message: "Phone number must be at least 10 digits" });
        }
        if (!password) {
            return res.status(400).json({ success: false, message: "Password is required" });
        }
        if (password.length < 6) {
            return res.status(400).json({ success: false, message: "Password must be at least 6 characters long" });
        }

        const normalizedEmail = rawEmail.toLowerCase();

        // Check for duplicates
        const [existing] = await db.promise().query(
            "SELECT user_id, email, phone FROM users WHERE LOWER(email) = ? OR phone = ? LIMIT 1",
            [normalizedEmail, cleanPhone]
        );

        if (existing && existing.length > 0) {
            const isEmail = existing[0].email && existing[0].email.toLowerCase() === normalizedEmail;
            return res.status(409).json({
                success: false,
                message: isEmail
                    ? "An account with this email address already exists"
                    : "An account with this phone number already exists"
            });
        }

        // Start transaction
        await db.promise().query("START TRANSACTION");
        try {
            const passwordHash = hashPassword(password);

            // 1. Insert into users
            const [userResult] = await db.promise().query(
                `INSERT INTO users (name, email, phone, password_hash, role, status, auth_provider)
                 VALUES (?, ?, ?, ?, 'DELIVERY_PARTNER', 'ACTIVE', 'PASSWORD')`,
                [partnerName, normalizedEmail, cleanPhone, passwordHash]
            );
            const userId = userResult.insertId;

            // 2. Generate unique partner code (e.g. DP003)
            const [maxPartner] = await db.promise().query("SELECT MAX(partner_id) AS maxId FROM delivery_partners");
            const nextPartnerNum = (maxPartner[0]?.maxId || 0) + 1;
            const partnerCode = `DP${String(nextPartnerNum).padStart(3, "0")}`;

            // 3. Insert into delivery_partners
            const [partnerResult] = await db.promise().query(
                `INSERT INTO delivery_partners (user_id, partner_code, emergency_contact, recommended_customer_limit, shift_start, shift_end, status)
                 VALUES (?, ?, ?, 50, ?, ?, 'AVAILABLE')`,
                [userId, partnerCode, emergency || null, start, end]
            );
            const partnerId = partnerResult.insertId;

            // 4. Insert into partner_vehicles if vehicle details provided
            if (vehicle || regNumber) {
                await db.promise().query(
                    `INSERT INTO partner_vehicles (partner_id, vehicle_type, registration_number, status)
                     VALUES (?, ?, ?, 'ACTIVE')`,
                    [partnerId, vehicle || "Motorcycle", regNumber || ""]
                );
            }

            await db.promise().query("COMMIT");

            const sessionToken = createSession(userId, "DELIVERY_PARTNER");

            return res.status(201).json({
                success: true,
                message: "Delivery partner account created successfully",
                user: {
                    user_id: userId,
                    partner_id: partnerId,
                    partner_code: partnerCode,
                    name: partnerName,
                    email: normalizedEmail,
                    phone: cleanPhone,
                    role: "DELIVERY_PARTNER",
                    session_token: sessionToken
                }
            });
        } catch (txErr) {
            await db.promise().query("ROLLBACK");
            console.error("Delivery partner registration transaction error:", txErr);
            return res.status(500).json({
                success: false,
                message: "Failed to create delivery partner account. Please try again."
            });
        }
    } catch (err) {
        console.error("Delivery partner registration server error:", err);
        return res.status(500).json({
            success: false,
            message: "Internal server error"
        });
    }
});


// =========================================
// LOGIN
// =========================================

app.post("/api/login", async (req, res) => {
    try {
        const {
            emailOrPhone,
            email,
            phone,
            password,
            partnerCode,
            role: expectedRole
        } = req.body;

        const rawIdentifier = (emailOrPhone || email || phone || partnerCode || "").trim();

        if (!rawIdentifier || !password) {
            return res.status(400).json({
                success: false,
                message: "Email/phone and password are required"
            });
        }

        const normalizedEmail = rawIdentifier.toLowerCase();
        const cleanDigits = rawIdentifier.replace(/\D/g, "");
        const phone10 = cleanDigits.length >= 10 ? cleanDigits.slice(-10) : cleanDigits;

        const sql = `
            SELECT
                u.user_id,
                u.name,
                u.email,
                u.phone,
                u.password_hash,
                u.role,
                u.status,

                c.customer_id,
                c.customer_code,

                sp.supplier_id,
                sp.supplier_name,
                dp.partner_id,
                dp.partner_code

            FROM users u

            LEFT JOIN customers c
                ON u.user_id = c.user_id

            LEFT JOIN suppliers sp
                ON u.user_id = sp.user_id

            LEFT JOIN delivery_partners dp
                ON u.user_id = dp.user_id

            WHERE LOWER(u.email) = ?
               OR u.phone = ?
               OR (? != '' AND u.phone = ?)
               OR (? IS NOT NULL AND dp.partner_code = ?)

            LIMIT 1;
        `;

        const [results] = await db.promise().query(
            sql,
            [normalizedEmail, rawIdentifier, phone10, phone10, partnerCode || null, partnerCode || null]
        );

        if (!results || results.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Invalid email/phone or password"
            });
        }

        const user = results[0];

        if (!verifyPassword(password, user.password_hash)) {
            return res.status(401).json({
                success: false,
                message: "Invalid email/phone or password"
            });
        }

        if (user.status !== "ACTIVE") {
            return res.status(403).json({
                success: false,
                message: "Your account is not active"
            });
        }

        if (expectedRole && user.role !== expectedRole) {
            return res.status(403).json({
                success: false,
                message: `This account is not authorized for the ${expectedRole} workspace`
            });
        }

        const sessionToken = createSession(user.user_id, user.role);

        res.json({
            success: true,
            message: "Login successful",
            user: {
                user_id: user.user_id,
                customer_id: user.customer_id,
                customer_code: user.customer_code,
                supplier_id: user.supplier_id,
                supplier_name: user.supplier_name,
                partner_id: user.partner_id,
                partner_code: user.partner_code,
                session_token: sessionToken,
                name: user.name,
                email: user.email,
                phone: user.phone,
                role: user.role
            }
        });
    } catch (err) {
        console.error("Login database error:", err);
        return res.status(500).json({
            success: false,
            message: "Server error"
        });
    }
});


// =========================================
// SUBSCRIPTIONS
// =========================================

app.get("/api/subscriptions", (req, res) => {

    const {
        customer_id
    } = req.query;

    if (!customer_id) {
        return res.status(400).json({
            success: false,
            message: "customer_id is required"
        });
    }

    const sql = `
        SELECT
            s.subscription_id,
            s.customer_id,

            s.newspaper_id,
            n.newspaper_name,
            n.language,
            n.publication_type,

            s.supplier_id,
            sp.supplier_name,
            sp.contact_number AS supplier_contact,
            sp.address AS supplier_address,

            s.address_id,
            ca.address_line,
            ca.city,
            ca.pincode,
            ca.delivery_instructions,

            s.start_date,
            s.end_date,
            s.status,
            s.delivery_days,
            s.scheduled_delivery_time,
            s.agreed_price,
            s.created_at,

            dp.partner_id,
            dp.partner_code,
            dpu.name AS partner_name,
            dpu.phone AS partner_phone,
            r.route_id,
            r.route_name

        FROM subscriptions s

        JOIN newspapers n
            ON s.newspaper_id = n.newspaper_id

        JOIN suppliers sp
            ON s.supplier_id = sp.supplier_id

        JOIN customer_addresses ca
            ON s.address_id = ca.address_id

        LEFT JOIN (
            SELECT customer_id, address_id, partner_id, daily_route_id
            FROM customer_assignments
            WHERE status = 'ACTIVE'
              AND assignment_id IN (
                SELECT MAX(assignment_id)
                FROM customer_assignments
                WHERE status = 'ACTIVE'
                GROUP BY customer_id, address_id
              )
        ) caa ON caa.customer_id = s.customer_id AND caa.address_id = s.address_id

        LEFT JOIN delivery_partners dp
            ON caa.partner_id = dp.partner_id

        LEFT JOIN users dpu
            ON dp.user_id = dpu.user_id

        LEFT JOIN daily_routes dr
            ON caa.daily_route_id = dr.daily_route_id

        LEFT JOIN routes r
            ON dr.route_id = r.route_id

        WHERE s.customer_id = ?

        ORDER BY s.subscription_id DESC;
    `;

    db.query(
        sql,
        [customer_id],
        (err, results) => {
            if (err) {
                console.error("Error fetching subscriptions:", err);
                return res.status(500).json({
                    success: false,
                    message: "Failed to fetch subscriptions"
                });
            }

            res.json({
                success: true,
                subscriptions: results
            });
        }
    );
});

app.get("/api/subscriptions/:subscriptionId", (req, res) => {
    const { subscriptionId } = req.params;
    const { customer_id } = req.query;

    const sql = `
        SELECT
            s.subscription_id,
            s.customer_id,

            s.newspaper_id,
            n.newspaper_name,
            n.language,
            n.publication_type,

            s.supplier_id,
            sp.supplier_name,
            sp.contact_number AS supplier_contact,
            sp.address AS supplier_address,

            s.address_id,
            ca.address_line,
            ca.city,
            ca.pincode,
            ca.delivery_instructions,

            s.start_date,
            s.end_date,
            s.status,
            s.delivery_days,
            s.scheduled_delivery_time,
            s.agreed_price,
            s.created_at,

            dp.partner_id,
            dp.partner_code,
            dpu.name AS partner_name,
            dpu.phone AS partner_phone,
            r.route_id,
            r.route_name

        FROM subscriptions s

        JOIN newspapers n
            ON s.newspaper_id = n.newspaper_id

        JOIN suppliers sp
            ON s.supplier_id = sp.supplier_id

        JOIN customer_addresses ca
            ON s.address_id = ca.address_id

        LEFT JOIN (
            SELECT customer_id, address_id, partner_id, daily_route_id
            FROM customer_assignments
            WHERE status = 'ACTIVE'
              AND assignment_id IN (
                SELECT MAX(assignment_id)
                FROM customer_assignments
                WHERE status = 'ACTIVE'
                GROUP BY customer_id, address_id
              )
        ) caa ON caa.customer_id = s.customer_id AND caa.address_id = s.address_id

        LEFT JOIN delivery_partners dp
            ON caa.partner_id = dp.partner_id

        LEFT JOIN users dpu
            ON dp.user_id = dpu.user_id

        LEFT JOIN daily_routes dr
            ON caa.daily_route_id = dr.daily_route_id

        LEFT JOIN routes r
            ON dr.route_id = r.route_id

        WHERE s.subscription_id = ? ${customer_id ? "AND s.customer_id = ?" : ""}

        LIMIT 1;
    `;

    const params = customer_id ? [subscriptionId, customer_id] : [subscriptionId];

    db.query(sql, params, (err, results) => {
        if (err) {
            console.error("Error fetching subscription details:", err);
            return res.status(500).json({
                success: false,
                message: "Failed to fetch subscription details"
            });
        }
        if (!results.length) {
            return res.status(404).json({
                success: false,
                message: "Subscription not found"
            });
        }
        res.json({
            success: true,
            subscription: results[0]
        });
    });
});


// =========================================
// DELIVERY HISTORY
// =========================================

app.get("/api/delivery-history", (req, res) => {

    const {
        customer_id
    } = req.query;

    if (!customer_id) {

        return res.status(400).json({
            success: false,
            message: "customer_id is required"
        });

    }

    const sql = `
        SELECT
            d.delivery_id,
            d.customer_id,
            d.delivery_date,
            d.scheduled_time,
            d.actual_time,
            d.status AS delivery_status,

            di.delivery_item_id,
            di.subscription_id,
            di.status AS item_status,
            di.remarks,

            n.newspaper_id,
            n.newspaper_name,
            n.language,

            sp.supplier_id,
            sp.supplier_name,

            dp.partner_id,
            u.name AS partner_name,

            ca.address_line,
            ca.city,
            ca.pincode

        FROM deliveries d

        JOIN delivery_items di
            ON d.delivery_id = di.delivery_id

        JOIN newspapers n
            ON di.newspaper_id = n.newspaper_id

        JOIN subscriptions s
            ON di.subscription_id = s.subscription_id

        JOIN suppliers sp
            ON s.supplier_id = sp.supplier_id

        JOIN customer_assignments caa
            ON d.assignment_id = caa.assignment_id

        JOIN customer_addresses ca
            ON caa.address_id = ca.address_id

        JOIN delivery_partners dp
            ON d.partner_id = dp.partner_id

        JOIN users u
            ON dp.user_id = u.user_id

        WHERE d.customer_id = ?

        ORDER BY
            d.delivery_date DESC,
            d.scheduled_time DESC;
    `;

    db.query(
        sql,
        [customer_id],
        (err, results) => {

            if (err) {

                console.error(
                    "Error fetching delivery history:",
                    err
                );

                return res.status(500).json({
                    success: false,
                    message: "Failed to fetch delivery history"
                });

            }

            res.json({
                success: true,
                deliveries: results
            });

        }
    );

});


// =========================================
// PAYMENTS
// =========================================

app.get("/api/payments", (req, res) => {
    const { customer_id } = req.query;

    if (!customer_id) {
        return res.status(400).json({
            success: false,
            message: "customer_id is required"
        });
    }

    const sql = `
        SELECT
            p.payment_id,
            COALESCE(p.customer_id, b.customer_id) AS customer_id,
            b.bill_id,
            b.billing_period_start,
            b.billing_period_end,
            b.subtotal,
            b.adjustments,
            b.total_amount,
            b.status AS bill_status,
            COALESCE(p.amount, b.total_amount) AS amount,
            COALESCE(p.payment_method, 'UPI') AS payment_method,
            COALESCE(p.transaction_reference, CONCAT('BILL-', b.bill_id)) AS transaction_reference,
            p.payment_date,
            COALESCE(p.status, CASE WHEN b.status = 'PAID' THEN 'SUCCESS' ELSE 'PENDING' END) AS payment_status
        FROM bills b
        LEFT JOIN payments p ON p.bill_id = b.bill_id
        WHERE b.customer_id = ?
        ORDER BY COALESCE(p.payment_date, b.generated_at) DESC;
    `;

    db.query(sql, [customer_id], (err, results) => {
        if (err) {
            console.error("Error fetching payments:", err);
            return res.status(500).json({
                success: false,
                message: "Failed to fetch payments"
            });
        }

        res.json({
            success: true,
            payments: results
        });
    });
});

app.post("/api/payments", (req, res) => {
    const customerId = req.body.customer_id;
    const billId = req.body.bill_id;
    const amount = req.body.amount;
    const paymentMethod = req.body.payment_method || "UPI";

    if (!customerId) {
        return res.status(400).json({ success: false, message: "customer_id is required" });
    }

    db.beginTransaction((beginErr) => {
        if (beginErr) {
            console.error("Error starting payment transaction:", beginErr);
            return res.status(500).json({ success: false, message: "Unable to process payment transaction" });
        }

        const findBillSql = billId
            ? "SELECT * FROM bills WHERE bill_id = ? AND customer_id = ? FOR UPDATE"
            : "SELECT * FROM bills WHERE customer_id = ? AND status = 'PENDING' ORDER BY generated_at DESC LIMIT 1 FOR UPDATE";
        const findBillParams = billId ? [billId, customerId] : [customerId];

        db.query(findBillSql, findBillParams, (findErr, billRows) => {
            if (findErr) {
                return db.rollback(() => {
                    console.error("Error locating bill:", findErr);
                    res.status(500).json({ success: false, message: "Failed to verify bill" });
                });
            }

            if (!billRows || billRows.length === 0) {
                return db.rollback(() => {
                    res.status(404).json({ success: false, message: billId ? "Bill not found for this customer" : "No pending bills found for this customer" });
                });
            }

            const targetBill = billRows[0];
            if (targetBill.status === "PAID") {
                return db.rollback(() => {
                    res.status(400).json({ success: false, message: "This bill has already been paid" });
                });
            }

            const paymentAmount = amount !== undefined && amount !== null ? Number(amount) : Number(targetBill.total_amount);
            const txnRef = `TXN${Date.now()}${crypto.randomBytes(3).toString("hex").toUpperCase()}`;

            const insertSql = `
                INSERT INTO payments (bill_id, customer_id, amount, payment_method, transaction_reference, status)
                VALUES (?, ?, ?, ?, ?, 'SUCCESS')
            `;

            db.query(insertSql, [targetBill.bill_id, customerId, paymentAmount, paymentMethod, txnRef], (insertErr, insertRes) => {
                if (insertErr) {
                    return db.rollback(() => {
                        console.error("Error creating payment:", insertErr);
                        res.status(500).json({ success: false, message: "Failed to record payment" });
                    });
                }

                const paymentId = insertRes.insertId;

                db.query("UPDATE bills SET status = 'PAID' WHERE bill_id = ?", [targetBill.bill_id], (updateErr) => {
                    if (updateErr) {
                        return db.rollback(() => {
                            console.error("Error updating bill status:", updateErr);
                            res.status(500).json({ success: false, message: "Failed to update bill status" });
                        });
                    }

                    // Insert notification for the customer
                    db.query("SELECT user_id FROM customers WHERE customer_id = ?", [customerId], (uErr, uRows) => {
                        if (!uErr && uRows && uRows.length > 0) {
                            const userId = uRows[0].user_id;
                            db.query(
                                "INSERT INTO notifications (user_id, notification_type, title, message, reference_type, reference_id) VALUES (?, 'PAYMENT', 'Payment Received', ?, 'BILL', ?)",
                                [userId, `Your payment of ₹${paymentAmount.toFixed(2)} via ${paymentMethod} was successful. Transaction: ${txnRef}`, targetBill.bill_id]
                            );
                        }

                        db.commit((commitErr) => {
                            if (commitErr) {
                                return db.rollback(() => {
                                    console.error("Error committing payment transaction:", commitErr);
                                    res.status(500).json({ success: false, message: "Failed to commit payment" });
                                });
                            }

                            res.status(201).json({
                                success: true,
                                message: "Payment processed successfully",
                                payment: {
                                    payment_id: paymentId,
                                    bill_id: targetBill.bill_id,
                                    customer_id: customerId,
                                    amount: paymentAmount,
                                    payment_method: paymentMethod,
                                    transaction_reference: txnRef,
                                    payment_date: new Date().toISOString(),
                                    status: "SUCCESS",
                                    bill_status: "PAID"
                                }
                            });
                        });
                    });
                });
            });
        });
    });
});


// =========================================
// REQUESTS
// =========================================

app.get("/api/requests", (req, res) => {

    const {
        customer_id
    } = req.query;

    if (!customer_id) {

        return res.status(400).json({
            success: false,
            message: "customer_id is required"
        });

    }

    const sql = `
        SELECT
            request_id,
            customer_id,
            request_type,
            reference_id,
            description,
            status,
            created_at,
            completed_at

        FROM customer_requests

        WHERE customer_id = ?

        ORDER BY created_at DESC;
    `;

    db.query(
        sql,
        [customer_id],
        (err, results) => {

            if (err) {

                console.error(
                    "Error fetching requests:",
                    err
                );

                return res.status(500).json({
                    success: false,
                    message: "Failed to fetch requests"
                });

            }

            res.json({
                success: true,
                requests: results
            });

        }
    );

});


// =========================================
// CREATE REQUEST
// =========================================

app.post("/api/requests", (req, res) => {

    const {
        customer_id,
        request_type,
        reference_id,
        description
    } = req.body;

    if (!customer_id || !request_type) {

        return res.status(400).json({
            success: false,
            message: "customer_id and request_type are required"
        });

    }

    const sql = `
        INSERT INTO customer_requests
        (
            customer_id,
            request_type,
            reference_id,
            description,
            status,
            created_at
        )

        VALUES
        (
            ?,
            ?,
            ?,
            ?,
            'PENDING',
            NOW()
        );
    `;

    db.query(
        sql,
        [
            customer_id,
            request_type,
            reference_id || null,
            description || null
        ],
        (err, result) => {

            if (err) {

                console.error(
                    "Error creating request:",
                    err
                );

                return res.status(500).json({
                    success: false,
                    message: "Failed to create request"
                });

            }

            res.status(201).json({
                success: true,
                message: "Request submitted successfully",
                request_id: result.insertId
            });

        }
    );

});


// =========================================
// NOTIFICATIONS
// =========================================

app.get("/api/notifications", (req, res) => {

    const {
        customer_id
    } = req.query;

    if (!customer_id) {

        return res.status(400).json({
            success: false,
            message: "customer_id is required"
        });

    }

    const sql = `
        SELECT
            n.notification_id,
            n.user_id,

            c.customer_id,

            u.name AS user_name,

            n.notification_type,
            n.title,
            n.message,

            n.reference_type,
            n.reference_id,

            n.is_read,
            n.created_at

        FROM notifications n

        JOIN users u
            ON n.user_id = u.user_id

        JOIN customers c
            ON c.user_id = u.user_id

        WHERE c.customer_id = ?

        ORDER BY n.created_at DESC;
    `;

    db.query(
        sql,
        [customer_id],
        (err, results) => {

            if (err) {

                console.error(
                    "Error fetching notifications:",
                    err
                );

                return res.status(500).json({
                    success: false,
                    message: "Failed to fetch notifications"
                });

            }

            res.json({
                success: true,
                notifications: results
            });

        }
    );

});


// =========================================
// CUSTOMER PROFILE
// =========================================

app.get("/api/customer-profile", (req, res) => {
    const { customer_id } = req.query;
    if (!customer_id) return res.status(400).json({ success: false, message: "customer_id is required" });

    db.query(`
        SELECT c.customer_id, c.customer_code, u.user_id, u.name, u.email, u.phone,
               ca.address_line, ca.city, ca.pincode, ca.delivery_instructions
        FROM customers c
        JOIN users u ON u.user_id = c.user_id
        LEFT JOIN customer_addresses ca ON ca.customer_id = c.customer_id AND ca.is_active = 1
        WHERE c.customer_id = ?
        ORDER BY ca.effective_from DESC
        LIMIT 1`, [customer_id], (err, results) => {
        if (err) return res.status(500).json({ success: false, message: "Failed to load profile" });
        if (!results.length) return res.status(404).json({ success: false, message: "Customer not found" });
        res.json({ success: true, user: results[0] });
    });
});

app.put("/api/customer-profile/:customerId", (req, res) => {
    const { customerId } = req.params;
    const { name, email, phone } = req.body;
    if (!name || !email || !phone) return res.status(400).json({ success: false, message: "Name, email and phone are required" });

    db.query(`UPDATE users u JOIN customers c ON c.user_id = u.user_id
              SET u.name = ?, u.email = ?, u.phone = ? WHERE c.customer_id = ?`,
        [name.trim(), email.trim(), phone.trim(), customerId], (err, result) => {
            if (err) return res.status(400).json({ success: false, message: "That email or phone number is already in use" });
            if (!result.affectedRows) return res.status(404).json({ success: false, message: "Customer not found" });
            res.json({ success: true, message: "Profile updated successfully" });
        });
});

// =========================================
// SUBSCRIPTION ACTIONS AND NEWSPAPER CATALOG
// =========================================

app.patch("/api/subscriptions/:subscriptionId/status", (req, res) => {
    const { subscriptionId } = req.params;
    const { customer_id, status } = req.body;
    const allowedStatuses = ["ACTIVE", "PAUSED", "CANCELLED"];
    if (!customer_id || !allowedStatuses.includes(String(status).toUpperCase())) {
        return res.status(400).json({ success: false, message: "A valid customer_id and subscription status are required" });
    }

    db.query("UPDATE subscriptions SET status = ? WHERE subscription_id = ? AND customer_id = ?",
        [String(status).toUpperCase(), subscriptionId, customer_id], (err, result) => {
            if (err) return res.status(500).json({ success: false, message: "Failed to update subscription" });
            if (!result.affectedRows) return res.status(404).json({ success: false, message: "Subscription not found" });
            res.json({ success: true, message: "Subscription updated successfully", status: String(status).toUpperCase() });
        });
});

app.get("/api/newspapers", (req, res) => {
    db.query(`
        SELECT n.newspaper_id, n.newspaper_name, n.language, n.publication_type,
               sn.supplier_id, sp.supplier_name, sp.contact_number AS supplier_contact,
               sp.address AS supplier_address, np.price_per_delivery
        FROM newspapers n
        JOIN supplier_newspapers sn ON sn.newspaper_id = n.newspaper_id AND sn.status = 'ACTIVE'
        JOIN suppliers sp ON sp.supplier_id = sn.supplier_id AND sp.status = 'ACTIVE'
        LEFT JOIN newspaper_prices np ON np.price_id = (
            SELECT price_id FROM newspaper_prices
            WHERE newspaper_id = n.newspaper_id AND effective_from <= CURDATE()
              AND (effective_until IS NULL OR effective_until >= CURDATE())
            ORDER BY effective_from DESC LIMIT 1
        )
        WHERE n.status = 'ACTIVE'
        ORDER BY n.newspaper_name, sn.supplier_id`, (err, results) => {
        if (err) return res.status(500).json({ success: false, message: "Failed to load newspapers" });
        res.json({ success: true, newspapers: results });
    });
});

app.post("/api/subscriptions", async (req, res) => {
    try {
        const { customer_id, newspaper_id, supplier_id, delivery_days = "MON,TUE,WED,THU,FRI,SAT,SUN", scheduled_delivery_time = "07:00:00" } = req.body;
        if (!customer_id || !newspaper_id || !supplier_id) {
            return res.status(400).json({ success: false, message: "customer_id, newspaper_id and supplier_id are required" });
        }

        // Check if customer already has an active subscription for this newspaper
        const [existing] = await db.promise().query(
            "SELECT subscription_id FROM subscriptions WHERE customer_id = ? AND newspaper_id = ? AND status = 'ACTIVE' LIMIT 1",
            [customer_id, newspaper_id]
        );

        if (existing && existing.length > 0) {
            return res.status(409).json({
                success: false,
                message: "You already have an active subscription for this newspaper."
            });
        }

        const sql = `INSERT INTO subscriptions (customer_id, newspaper_id, supplier_id, address_id, start_date, status, delivery_days, scheduled_delivery_time, agreed_price)
            SELECT ?, ?, ?, ca.address_id, CURDATE(), 'ACTIVE', ?, ?, np.price_per_delivery
            FROM customer_addresses ca
            JOIN supplier_newspapers sn ON sn.supplier_id = ? AND sn.newspaper_id = ? AND sn.status = 'ACTIVE'
            JOIN newspapers n ON n.newspaper_id = sn.newspaper_id AND n.status = 'ACTIVE'
            JOIN newspaper_prices np ON np.price_id = (
                SELECT price_id FROM newspaper_prices WHERE newspaper_id = n.newspaper_id AND effective_from <= CURDATE()
                AND (effective_until IS NULL OR effective_until >= CURDATE()) ORDER BY effective_from DESC LIMIT 1
            )
            WHERE ca.customer_id = ? AND ca.is_active = 1
            ORDER BY ca.effective_from DESC LIMIT 1`;

        const [result] = await db.promise().query(sql, [
            customer_id,
            newspaper_id,
            supplier_id,
            delivery_days,
            scheduled_delivery_time,
            supplier_id,
            newspaper_id,
            customer_id
        ]);

        if (!result.affectedRows) {
            return res.status(400).json({
                success: false,
                message: "This newspaper is unavailable or no active delivery address was found"
            });
        }

        res.status(201).json({
            success: true,
            message: "Newspaper subscription created successfully",
            subscription_id: result.insertId
        });
    } catch (err) {
        console.error("Create subscription error:", err);
        res.status(500).json({ success: false, message: "Failed to create subscription" });
    }
});

app.patch("/api/subscriptions/:subscriptionId/change-newspaper", async (req, res) => {
    try {
        const { subscriptionId } = req.params;
        const { customer_id, new_newspaper_id, new_supplier_id } = req.body;

        if (!customer_id || !new_newspaper_id || !new_supplier_id) {
            return res.status(400).json({
                success: false,
                message: "customer_id, new_newspaper_id, and new_supplier_id are required"
            });
        }

        const [priceRows] = await db.promise().query(`
            SELECT np.price_per_delivery
            FROM newspaper_prices np
            WHERE np.newspaper_id = ?
              AND np.effective_from <= CURDATE()
              AND (np.effective_until IS NULL OR np.effective_until >= CURDATE())
            ORDER BY np.effective_from DESC LIMIT 1`,
            [new_newspaper_id]
        );
        const price = priceRows[0]?.price_per_delivery || 5.00;

        const [updateResult] = await db.promise().query(`
            UPDATE subscriptions
            SET newspaper_id = ?, supplier_id = ?, agreed_price = ?, status = 'ACTIVE'
            WHERE subscription_id = ? AND customer_id = ?`,
            [new_newspaper_id, new_supplier_id, price, subscriptionId, customer_id]
        );

        if (!updateResult.affectedRows) {
            return res.status(404).json({ success: false, message: "Subscription not found" });
        }

        res.json({
            success: true,
            message: "Newspaper changed successfully",
            newspaper_id: new_newspaper_id,
            agreed_price: price
        });
    } catch (err) {
        console.error("Change newspaper error:", err);
        res.status(500).json({ success: false, message: "Failed to change newspaper" });
    }
});

// =========================================
// NOTIFICATION READ STATE
// =========================================

app.patch("/api/notifications/read-all", (req, res) => {
    const { customer_id } = req.body;
    if (!customer_id) {
        return res.status(400).json({ success: false, message: "customer_id is required" });
    }

    db.query(`
        UPDATE notifications n
        JOIN customers c ON c.user_id = n.user_id
        SET n.is_read = 1
        WHERE c.customer_id = ? AND n.is_read = 0`,
        [customer_id],
        (err, result) => {
            if (err) {
                console.error("Error marking notifications as read:", err);
                return res.status(500).json({ success: false, message: "Failed to update notifications" });
            }
            res.json({ success: true, message: "All notifications marked as read", updated: result.affectedRows });
        }
    );
});

app.patch("/api/notifications/:notificationId/read", (req, res) => {
    const { notificationId } = req.params;
    const { customer_id } = req.body;
    if (!customer_id) return res.status(400).json({ success: false, message: "customer_id is required" });
    db.query(`UPDATE notifications n JOIN customers c ON c.user_id = n.user_id
              SET n.is_read = 1 WHERE n.notification_id = ? AND c.customer_id = ?`,
        [notificationId, customer_id], (err, result) => {
            if (err) return res.status(500).json({ success: false, message: "Failed to update notification" });
            if (!result.affectedRows) return res.status(404).json({ success: false, message: "Notification not found" });
            res.json({ success: true, message: "Notification marked as read" });
        });
});

// =========================================
// SUPPLIER WORKSPACE
// =========================================

function withRole(req, res, role, callback) {
    const authorization = req.header("authorization") || "";
    const token = authorization.startsWith("Bearer ") ? authorization.slice(7).trim() : "";
    const session = activeSessions.get(token);

    const supplierId = req.query.supplier_id || req.body?.supplier_id || req.header("x-supplier-id");
    const partnerId = req.query.partner_id || req.body?.partner_id || req.header("x-partner-id");
    const queryUserId = req.query.user_id || req.body?.user_id || req.header("x-user-id");

    let userId = null;
    if (session && session.expiresAt >= Date.now() && session.role === role) {
        userId = session.userId;
    }

    if (!userId && !supplierId && !partnerId && !queryUserId) {
        return res.status(401).json({ success: false, message: "Your session is invalid or has expired" });
    }

    const sql = `
        SELECT u.user_id, u.name, u.email, u.phone, u.role, u.status,
               sp.supplier_id, sp.supplier_name, sp.contact_number AS supplier_contact,
               sp.address AS supplier_address, sp.created_at AS supplier_created_at,
               dp.partner_id, dp.partner_code, dp.emergency_contact,
               dp.shift_start, dp.shift_end, dp.status AS partner_status
        FROM users u
        LEFT JOIN suppliers sp ON sp.user_id = u.user_id
        LEFT JOIN delivery_partners dp ON dp.user_id = u.user_id
        WHERE u.role = ? AND u.status = 'ACTIVE'
          AND (
            (? IS NOT NULL AND u.user_id = ?)
            OR (? IS NOT NULL AND sp.supplier_id = ?)
            OR (? IS NOT NULL AND dp.partner_id = ?)
            OR (? IS NOT NULL AND u.user_id = ?)
          )
        LIMIT 1`;

    db.query(sql, [role, userId, userId, supplierId, supplierId, partnerId, partnerId, queryUserId, queryUserId], (err, rows) => {
        if (err) {
            console.error("Role authorization error:", err);
            return res.status(500).json({ success: false, message: "Failed to authorize the account" });
        }
        if (!rows.length) {
            return res.status(403).json({ success: false, message: "This account is not authorized for this workspace" });
        }
        callback(rows[0]);
    });
}

app.get("/api/supplier/profile", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        db.query(`
            SELECT sp.supplier_id, sp.supplier_name, sp.contact_number, sp.address,
                   sp.status AS supplier_status, sp.created_at,
                   u.user_id, u.name, u.email, u.phone, u.status AS account_status,
                   a.area_id, a.area_name, a.city, a.pincode,
                   sa.status AS area_status
            FROM suppliers sp
            JOIN users u ON u.user_id = sp.user_id
            LEFT JOIN supplier_areas sa ON sa.supplier_id = sp.supplier_id
                AND sa.status = 'ACTIVE'
            LEFT JOIN areas a ON a.area_id = sa.area_id
            WHERE sp.supplier_id = ?
            ORDER BY a.area_name`,
            [identity.supplier_id],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load supplier profile" });
                if (!rows.length) return res.status(404).json({ success: false, message: "Supplier profile not found" });
                const profile = rows[0];
                profile.service_areas = rows
                    .filter((row) => row.area_id !== null)
                    .map((row) => ({
                        area_id: row.area_id,
                        area_name: row.area_name,
                        city: row.city,
                        pincode: row.pincode,
                        status: row.area_status
                    }));
                res.json({ success: true, profile });
            }
        );
    });
});

app.put("/api/supplier/profile", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const supplierId = identity.supplier_id;
        const userId = identity.user_id;
        const { name, email, phone, supplier_name, contact_number, address } = req.body;

        const userUpdates = [];
        const userParams = [];
        if (name) { userUpdates.push("name = ?"); userParams.push(name); }
        if (email) { userUpdates.push("email = ?"); userParams.push(email.trim().toLowerCase()); }
        if (phone) { userUpdates.push("phone = ?"); userParams.push(phone); }

        const suppUpdates = [];
        const suppParams = [];
        if (supplier_name) { suppUpdates.push("supplier_name = ?"); suppParams.push(supplier_name); }
        if (contact_number !== undefined) { suppUpdates.push("contact_number = ?"); suppParams.push(contact_number); }
        if (address !== undefined) { suppUpdates.push("address = ?"); suppParams.push(address); }

        const updateUser = (callback) => {
            if (userUpdates.length === 0) return callback(null);
            userParams.push(userId);
            db.query(`UPDATE users SET ${userUpdates.join(", ")} WHERE user_id = ?`, userParams, callback);
        };

        const updateSupplier = (callback) => {
            if (suppUpdates.length === 0) return callback(null);
            suppParams.push(supplierId);
            db.query(`UPDATE suppliers SET ${suppUpdates.join(", ")} WHERE supplier_id = ?`, suppParams, callback);
        };

        updateUser((err1) => {
            if (err1) {
                if (err1.code === "ER_DUP_ENTRY") {
                    return res.status(409).json({ success: false, message: "An account with this email or phone already exists" });
                }
                return res.status(500).json({ success: false, message: "Failed to update user details" });
            }
            updateSupplier((err2) => {
                if (err2) return res.status(500).json({ success: false, message: "Failed to update supplier details" });
                res.json({ success: true, message: "Supplier profile updated successfully" });
            });
        });
    });
});

app.get("/api/supplier/newspapers", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        db.query(`
            SELECT n.newspaper_id, n.newspaper_name, n.language, n.publication_type,
                   sn.supplier_newspaper_id, sn.status AS availability_status,
                   sn.available_from, sn.available_until,
                   np.price_per_delivery, np.effective_from, np.effective_until
            FROM supplier_newspapers sn
            JOIN newspapers n ON n.newspaper_id = sn.newspaper_id
            LEFT JOIN newspaper_prices np ON np.price_id = (
                SELECT price_id FROM newspaper_prices
                WHERE newspaper_id = sn.newspaper_id
                  AND effective_from <= CURDATE()
                  AND (effective_until IS NULL OR effective_until >= CURDATE())
                ORDER BY effective_from DESC LIMIT 1
            )
            WHERE sn.supplier_id = ?
            ORDER BY n.newspaper_name`,
            [identity.supplier_id],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load supplier newspapers" });
                res.json({ success: true, newspapers: rows });
            }
        );
    });
});

app.get("/api/supplier/subscriptions", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        db.query(`
            SELECT s.subscription_id, s.customer_id, s.newspaper_id, s.start_date,
                   s.end_date, s.status, s.delivery_days, s.scheduled_delivery_time,
                   s.agreed_price, n.newspaper_name, n.language,
                   u.name AS customer_name, u.email AS customer_email, u.phone AS customer_phone,
                   ca.address_line, ca.city, ca.pincode, a.area_id, a.area_name
            FROM subscriptions s
            JOIN customers c ON c.customer_id = s.customer_id
            JOIN users u ON u.user_id = c.user_id
            JOIN newspapers n ON n.newspaper_id = s.newspaper_id
            JOIN customer_addresses ca ON ca.address_id = s.address_id
            JOIN areas a ON a.area_id = ca.area_id
            WHERE s.supplier_id = ?
            ORDER BY s.start_date DESC, s.subscription_id DESC`,
            [identity.supplier_id],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load supplier subscriptions" });
                res.json({ success: true, subscriptions: rows });
            }
        );
    });
});

app.get("/api/supplier/distribution", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const date = req.query.date || null;
        const sql = `
            SELECT n.newspaper_id, n.newspaper_name, n.language, n.publication_type,
                   sn.status AS availability_status,
                   COUNT(DISTINCT s.subscription_id) AS active_subscribers_count
            FROM supplier_newspapers sn
            JOIN newspapers n ON n.newspaper_id = sn.newspaper_id
            LEFT JOIN subscriptions s ON s.newspaper_id = n.newspaper_id
                AND s.supplier_id = sn.supplier_id
                AND s.status = 'ACTIVE'
            WHERE sn.supplier_id = ?
            GROUP BY n.newspaper_id, n.newspaper_name, n.language, n.publication_type, sn.status
            ORDER BY n.newspaper_name`;

        db.query(sql, [identity.supplier_id], (err, rows) => {
            if (err) {
                console.error("Error loading supplier distribution:", err);
                return res.status(500).json({ success: false, message: "Failed to load supplier distribution" });
            }

            let expectedDemand = 0;
            let availableStock = 0;
            let totalShortage = 0;
            let totalDispatch = 0;

            const distribution = rows.map((r) => {
                const required = parseInt(r.active_subscribers_count || 0, 10);
                const isAvailable = r.availability_status === "ACTIVE";
                const available = isAvailable ? required : 0;
                const shortage = Math.max(0, required - available);
                const dispatch = Math.min(required, available);

                expectedDemand += required;
                availableStock += available;
                totalShortage += shortage;
                totalDispatch += dispatch;

                return {
                    id: String(r.newspaper_id),
                    newspaper_id: r.newspaper_id,
                    name: r.newspaper_name,
                    language: r.language,
                    required,
                    available,
                    shortage,
                    dispatch,
                    status: r.availability_status
                };
            });

            res.json({
                success: true,
                date: date || new Date().toISOString().split("T")[0],
                distribution,
                summary: {
                    expected_demand: expectedDemand,
                    available_stock: availableStock,
                    shortage: totalShortage,
                    dispatch_planned: totalDispatch
                }
            });
        });
    });
});

app.get("/api/supplier/deliveries", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const date = req.query.date || null;
        db.query(`
            SELECT d.delivery_id, d.delivery_date, d.scheduled_time, d.actual_time,
                   d.status AS delivery_status, d.failure_reason_id, d.remarks,
                   di.delivery_item_id, di.status AS item_status, di.remarks AS item_remarks,
                   n.newspaper_id, n.newspaper_name, n.language,
                   u.name AS customer_name, ca.address_line, ca.city, ca.pincode,
                   a.area_name, dp.partner_id, pu.name AS partner_name
            FROM deliveries d
            JOIN delivery_items di ON di.delivery_id = d.delivery_id
            JOIN subscriptions s ON s.subscription_id = di.subscription_id
            JOIN newspapers n ON n.newspaper_id = di.newspaper_id
            JOIN customers c ON c.customer_id = d.customer_id
            JOIN users u ON u.user_id = c.user_id
            LEFT JOIN customer_assignments caa ON caa.assignment_id = d.assignment_id
            LEFT JOIN customer_addresses ca ON ca.address_id = COALESCE(caa.address_id, s.address_id)
            LEFT JOIN areas a ON a.area_id = ca.area_id
            LEFT JOIN delivery_partners dp ON dp.partner_id = d.partner_id
            LEFT JOIN users pu ON pu.user_id = dp.user_id
            WHERE s.supplier_id = ?
              AND (? IS NULL OR ? = '' OR DATE(d.delivery_date) = DATE(?))
            ORDER BY d.delivery_date DESC, d.scheduled_time, d.delivery_id`,
            [identity.supplier_id, date, date, date],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load supplier deliveries" });
                res.json({ success: true, deliveries: rows });
            }
        );
    });
});

app.get("/api/supplier/payments", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const sql = `
            SELECT b.bill_id, b.customer_id, b.billing_period_start, b.billing_period_end,
                   b.subtotal, b.adjustments, b.total_amount, b.status AS bill_status, b.generated_at,
                   p.payment_id, p.amount, p.payment_method, p.transaction_reference,
                   p.payment_date, p.status AS payment_status,
                   u.name AS customer_name,
                   GROUP_CONCAT(DISTINCT n.newspaper_name SEPARATOR ', ') AS newspaper_names,
                   SUM(bi.amount) AS supplier_item_total
            FROM bills b
            JOIN bill_items bi ON bi.bill_id = b.bill_id
            JOIN subscriptions s ON s.subscription_id = bi.subscription_id
            JOIN newspapers n ON bi.newspaper_id = n.newspaper_id
            JOIN customers c ON c.customer_id = b.customer_id
            JOIN users u ON u.user_id = c.user_id
            LEFT JOIN payments p ON p.bill_id = b.bill_id
            WHERE s.supplier_id = ?
            GROUP BY b.bill_id, b.customer_id, b.billing_period_start, b.billing_period_end,
                     b.subtotal, b.adjustments, b.total_amount, b.status, b.generated_at,
                     p.payment_id, p.amount, p.payment_method, p.transaction_reference,
                     p.payment_date, p.status, u.name
            ORDER BY COALESCE(p.payment_date, b.generated_at) DESC`;

        db.query(sql, [identity.supplier_id], (err, rows) => {
            if (err) {
                console.error("Error loading supplier payments:", err);
                return res.status(500).json({ success: false, message: "Failed to load supplier payments" });
            }

            let totalEarnings = 0;
            let amountReceived = 0;
            let pendingAmount = 0;

            for (const r of rows) {
                const itemTotal = parseFloat(r.supplier_item_total || r.amount || r.total_amount || 0);
                totalEarnings += itemTotal;
                if (r.payment_status === "SUCCESS" || r.bill_status === "PAID") {
                    amountReceived += parseFloat(r.amount || itemTotal);
                } else {
                    pendingAmount += itemTotal;
                }
            }

            res.json({
                success: true,
                payments: rows,
                summary: {
                    total_earnings: totalEarnings.toFixed(2),
                    amount_received: amountReceived.toFixed(2),
                    pending_amount: pendingAmount.toFixed(2),
                    total_records: rows.length
                }
            });
        });
    });
});

app.get("/api/supplier/requests", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const sqlRequests = `
            SELECT cr.request_id,
                   cr.customer_id,
                   u.name AS customer_name,
                   u.phone AS customer_phone,
                   cr.request_type,
                   cr.reference_id,
                   s.newspaper_id,
                   n.newspaper_name,
                   cr.description,
                   cr.status,
                   cr.created_at,
                   cr.completed_at
            FROM customer_requests cr
            JOIN customers c ON c.customer_id = cr.customer_id
            JOIN users u ON u.user_id = c.user_id
            LEFT JOIN subscriptions s ON cr.reference_id = s.subscription_id
            LEFT JOIN newspapers n ON s.newspaper_id = n.newspaper_id
            WHERE s.supplier_id = ?
               OR (cr.reference_id IS NULL AND cr.customer_id IN (SELECT customer_id FROM subscriptions WHERE supplier_id = ?))
            ORDER BY cr.created_at DESC`;

        const sqlComplaints = `
            SELECT dc.complaint_id,
                   dc.delivery_id,
                   dc.delivery_item_id,
                   dc.customer_id,
                   u.name AS customer_name,
                   u.phone AS customer_phone,
                   dc.complaint_type,
                   dc.description,
                   dc.status,
                   dc.assigned_partner_id,
                   pu.name AS partner_name,
                   dc.resolution,
                   dc.created_at,
                   dc.resolved_at,
                   n.newspaper_name
            FROM delivery_complaints dc
            JOIN customers c ON c.customer_id = dc.customer_id
            JOIN users u ON u.user_id = c.user_id
            LEFT JOIN delivery_items di ON (dc.delivery_item_id IS NOT NULL AND di.delivery_item_id = dc.delivery_item_id)
                OR (dc.delivery_item_id IS NULL AND di.delivery_id = dc.delivery_id)
            LEFT JOIN subscriptions s ON di.subscription_id = s.subscription_id
            LEFT JOIN newspapers n ON di.newspaper_id = n.newspaper_id
            LEFT JOIN delivery_partners dp ON dc.assigned_partner_id = dp.partner_id
            LEFT JOIN users pu ON dp.user_id = pu.user_id
            WHERE s.supplier_id = ?
               OR (s.supplier_id IS NULL AND (dc.customer_id IN (SELECT customer_id FROM subscriptions WHERE supplier_id = ?) OR dc.resolved_by = ?))
            ORDER BY dc.created_at DESC`;

        db.query(sqlRequests, [identity.supplier_id, identity.supplier_id], (errReq, reqRows) => {
            if (errReq) {
                console.error("Error fetching supplier requests:", errReq);
                return res.status(500).json({ success: false, message: "Failed to load supplier requests" });
            }

            db.query(sqlComplaints, [identity.supplier_id, identity.supplier_id, identity.user_id], (errComp, compRows) => {
                if (errComp) {
                    console.error("Error fetching supplier complaints:", errComp);
                    return res.status(500).json({ success: false, message: "Failed to load supplier complaints" });
                }

                res.json({
                    success: true,
                    requests: reqRows || [],
                    complaints: compRows || []
                });
            });
        });
    });
});

app.patch("/api/supplier/requests/:requestId/status", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const { requestId } = req.params;
        const { status } = req.body;
        const allowedStatuses = ["PENDING", "APPROVED", "REJECTED", "COMPLETED"];
        if (!status || !allowedStatuses.includes(status.toUpperCase())) {
            return res.status(400).json({ success: false, message: "Valid status required" });
        }
        const completedAt = ["APPROVED", "REJECTED", "COMPLETED"].includes(status.toUpperCase()) ? new Date() : null;
        db.query(
            "UPDATE customer_requests SET status = ?, completed_at = ? WHERE request_id = ?",
            [status.toUpperCase(), completedAt, requestId],
            (err, result) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to update request status" });
                if (!result.affectedRows) return res.status(404).json({ success: false, message: "Request not found" });
                res.json({ success: true, message: `Request status updated to ${status.toUpperCase()}` });
            }
        );
    });
});

app.patch("/api/supplier/complaints/:complaintId/status", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const { complaintId } = req.params;
        const { status, resolution } = req.body;
        const allowedStatuses = ["OPEN", "IN_PROGRESS", "RESOLVED"];
        if (!status || !allowedStatuses.includes(status.toUpperCase())) {
            return res.status(400).json({ success: false, message: "Valid status required" });
        }
        const resolvedAt = status.toUpperCase() === "RESOLVED" ? new Date() : null;
        db.query(
            "UPDATE delivery_complaints SET status = ?, resolution = COALESCE(?, resolution), resolved_by = ?, resolved_at = COALESCE(?, resolved_at) WHERE complaint_id = ?",
            [status.toUpperCase(), resolution || null, identity.user_id, resolvedAt, complaintId],
            (err, result) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to update complaint" });
                if (!result.affectedRows) return res.status(404).json({ success: false, message: "Complaint not found" });
                res.json({ success: true, message: `Complaint status updated to ${status.toUpperCase()}` });
            }
        );
    });
});

app.get("/api/supplier/notifications", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        db.query(`
            SELECT notification_id, user_id, notification_type, title, message,
                   reference_type, reference_id, is_read, created_at
            FROM notifications
            WHERE user_id = ?
            ORDER BY created_at DESC`,
            [identity.user_id],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load supplier notifications" });
                res.json({ success: true, notifications: rows });
            }
        );
    });
});

app.patch("/api/supplier/notifications/:notificationId/read", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const { notificationId } = req.params;
        db.query(
            "UPDATE notifications SET is_read = 1 WHERE notification_id = ? AND user_id = ?",
            [notificationId, identity.user_id],
            (err, result) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to mark notification as read" });
                if (!result.affectedRows) return res.status(404).json({ success: false, message: "Notification not found" });
                res.json({ success: true, message: "Notification marked as read" });
            }
        );
    });
});

app.get("/api/supplier/reports", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        const supplierId = identity.supplier_id;

        const pSubs = new Promise((resolve, reject) => {
            db.query(
                `SELECT COUNT(DISTINCT s.customer_id) AS total_subscribers,
                        COUNT(s.subscription_id) AS total_subscriptions,
                        COALESCE(SUM(s.agreed_price), 0) AS monthly_revenue
                 FROM subscriptions s
                 WHERE s.supplier_id = ? AND s.status = 'ACTIVE'`,
                [supplierId],
                (err, rows) => err ? reject(err) : resolve(rows[0] || {})
            );
        });

        const pDeliv = new Promise((resolve, reject) => {
            db.query(
                `SELECT COUNT(DISTINCT d.delivery_id) AS total,
                        SUM(CASE WHEN d.status = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered,
                        SUM(CASE WHEN d.status != 'DELIVERED' THEN 1 ELSE 0 END) AS undelivered
                 FROM deliveries d
                 JOIN delivery_items di ON di.delivery_id = d.delivery_id
                 JOIN subscriptions s ON s.subscription_id = di.subscription_id
                 WHERE s.supplier_id = ?`,
                [supplierId],
                (err, rows) => err ? reject(err) : resolve(rows[0] || {})
            );
        });

        const pRev = new Promise((resolve, reject) => {
            db.query(
                `SELECT COALESCE(SUM(bi.amount), 0) AS total_billed,
                        COALESCE(SUM(CASE WHEN b.status = 'PAID' OR p.status = 'SUCCESS' THEN bi.amount ELSE 0 END), 0) AS total_collected,
                        COALESCE(SUM(CASE WHEN b.status != 'PAID' AND (p.status IS NULL OR p.status != 'SUCCESS') THEN bi.amount ELSE 0 END), 0) AS total_pending
                 FROM bill_items bi
                 JOIN bills b ON b.bill_id = bi.bill_id
                 JOIN subscriptions s ON s.subscription_id = bi.subscription_id
                 LEFT JOIN payments p ON p.bill_id = b.bill_id
                 WHERE s.supplier_id = ?`,
                [supplierId],
                (err, rows) => err ? reject(err) : resolve(rows[0] || {})
            );
        });

        const pNewspapers = new Promise((resolve, reject) => {
            db.query(
                `SELECT n.newspaper_id, n.newspaper_name, n.language,
                        COUNT(s.subscription_id) AS subscriber_count,
                        COALESCE(SUM(s.agreed_price), 0) AS monthly_revenue
                 FROM supplier_newspapers sn
                 JOIN newspapers n ON n.newspaper_id = sn.newspaper_id
                 LEFT JOIN subscriptions s ON s.newspaper_id = n.newspaper_id AND s.supplier_id = sn.supplier_id AND s.status = 'ACTIVE'
                 WHERE sn.supplier_id = ?
                 GROUP BY n.newspaper_id, n.newspaper_name, n.language
                 ORDER BY subscriber_count DESC`,
                [supplierId],
                (err, rows) => err ? reject(err) : resolve(rows || [])
            );
        });

        const pReqs = new Promise((resolve, reject) => {
            db.query(
                `SELECT COUNT(*) AS total_requests,
                        SUM(CASE WHEN cr.status = 'COMPLETED' OR cr.status = 'RESOLVED' THEN 1 ELSE 0 END) AS resolved_requests,
                        SUM(CASE WHEN cr.status = 'PENDING' THEN 1 ELSE 0 END) AS pending_requests
                 FROM customer_requests cr
                 LEFT JOIN subscriptions s ON cr.reference_id = s.subscription_id
                 WHERE s.supplier_id = ?
                    OR (cr.reference_id IS NULL AND cr.customer_id IN (SELECT customer_id FROM subscriptions WHERE supplier_id = ?))`,
                [supplierId, supplierId],
                (err, rows) => err ? reject(err) : resolve(rows[0] || {})
            );
        });

        Promise.all([pSubs, pDeliv, pRev, pNewspapers, pReqs])
            .then(([subs, deliv, rev, newspapers, reqs]) => {
                const totalDeliv = Number(deliv.total || 0);
                const delivered = Number(deliv.delivered || 0);
                const delivRate = totalDeliv > 0 ? ((delivered / totalDeliv) * 100).toFixed(1) : "100.0";

                const billed = Number(rev.total_billed || 0);
                const collected = Number(rev.total_collected || 0);
                const collRate = billed > 0 ? ((collected / billed) * 100).toFixed(1) : "100.0";

                const totalReqs = Number(reqs.total_requests || 0);
                const resolvedReqs = Number(reqs.resolved_requests || 0);
                const resRate = totalReqs > 0 ? ((resolvedReqs / totalReqs) * 100).toFixed(1) : "100.0";

                res.json({
                    success: true,
                    reports: {
                        summary: {
                            total_subscribers: Number(subs.total_subscribers || 0),
                            active_subscriptions: Number(subs.total_subscriptions || 0),
                            monthly_revenue: Number(subs.monthly_revenue || 0).toFixed(2),
                            delivery_success_rate: delivRate,
                            collection_rate: collRate,
                            resolution_rate: resRate
                        },
                        deliveries: {
                            total: totalDeliv,
                            delivered: delivered,
                            undelivered: Number(deliv.undelivered || 0),
                            success_rate: delivRate
                        },
                        revenue: {
                            total_billed: billed.toFixed(2),
                            total_collected: collected.toFixed(2),
                            total_pending: Number(rev.total_pending || 0).toFixed(2),
                            collection_rate: collRate
                        },
                        requests: {
                            total: totalReqs,
                            resolved: resolvedReqs,
                            pending: Number(reqs.pending_requests || 0),
                            resolution_rate: resRate
                        },
                        top_newspapers: newspapers.map((n) => ({
                            newspaper_id: n.newspaper_id,
                            name: n.newspaper_name,
                            language: n.language,
                            subscribers: Number(n.subscriber_count || 0),
                            revenue: Number(n.monthly_revenue || 0).toFixed(2)
                        }))
                    }
                });
            })
            .catch((err) => {
                console.error("Error generating supplier reports:", err);
                res.status(500).json({ success: false, message: "Failed to generate supplier reports" });
            });
    });
});

// =========================================
// DELIVERY PARTNER WORKSPACE
// =========================================

app.get("/api/partner/profile", (req, res) => {
    withRole(req, res, "DELIVERY_PARTNER", (identity) => {
        db.query(`
            SELECT dp.partner_id, dp.partner_code, dp.emergency_contact,
                   dp.recommended_customer_limit, dp.shift_start, dp.shift_end,
                   dp.status AS partner_status, u.user_id, u.name, u.email, u.phone,
                   u.status AS account_status, v.vehicle_type, v.registration_number,
                   v.status AS vehicle_status
            FROM delivery_partners dp
            JOIN users u ON u.user_id = dp.user_id
            LEFT JOIN partner_vehicles v ON v.partner_id = dp.partner_id AND v.status = 'ACTIVE'
            WHERE dp.partner_id = ?`,
            [identity.partner_id],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load delivery partner profile" });
                if (!rows.length) return res.status(404).json({ success: false, message: "Delivery partner profile not found" });
                res.json({ success: true, profile: rows[0] });
            }
        );
    });
});

app.put("/api/partner/profile", (req, res) => {
    withRole(req, res, "DELIVERY_PARTNER", (identity) => {
        const partnerId = identity.partner_id;
        const userId = identity.user_id;
        const { name, email, phone, emergency_contact, registration_number, vehicle_type, status } = req.body;

        const userUpdates = [];
        const userParams = [];
        if (name) { userUpdates.push("name = ?"); userParams.push(name); }
        if (email) { userUpdates.push("email = ?"); userParams.push(email.trim().toLowerCase()); }
        if (phone) { userUpdates.push("phone = ?"); userParams.push(phone); }

        const partnerUpdates = [];
        const partnerParams = [];
        if (emergency_contact !== undefined) { partnerUpdates.push("emergency_contact = ?"); partnerParams.push(emergency_contact); }
        if (status) {
            let partnerStatus = String(status).toUpperCase();
            if (partnerStatus === "ACTIVE") partnerStatus = "AVAILABLE";
            const validPartnerStatuses = ["AVAILABLE", "ON_ROUTE", "OFF_DUTY", "ON_LEAVE", "ABSENT", "INACTIVE"];
            if (validPartnerStatuses.includes(partnerStatus)) {
                partnerUpdates.push("status = ?");
                partnerParams.push(partnerStatus);
            }
        }

        const updateUser = (callback) => {
            if (userUpdates.length === 0) return callback(null);
            userParams.push(userId);
            db.query(`UPDATE users SET ${userUpdates.join(", ")} WHERE user_id = ?`, userParams, callback);
        };

        const updatePartner = (callback) => {
            if (partnerUpdates.length === 0) return callback(null);
            partnerParams.push(partnerId);
            db.query(`UPDATE delivery_partners SET ${partnerUpdates.join(", ")} WHERE partner_id = ?`, partnerParams, callback);
        };

        const updateVehicle = (callback) => {
            if (!registration_number && !vehicle_type) return callback(null);
            db.query(
                "UPDATE partner_vehicles SET registration_number = COALESCE(?, registration_number), vehicle_type = COALESCE(?, vehicle_type) WHERE partner_id = ? AND status = 'ACTIVE'",
                [registration_number || null, vehicle_type || null, partnerId],
                callback
            );
        };

        updateUser((err1) => {
            if (err1) {
                if (err1.code === "ER_DUP_ENTRY") {
                    return res.status(409).json({ success: false, message: "An account with this email or phone already exists" });
                }
                return res.status(500).json({ success: false, message: "Failed to update user details" });
            }
            updatePartner((err2) => {
                if (err2) return res.status(500).json({ success: false, message: "Failed to update partner details" });
                updateVehicle((err3) => {
                    if (err3) return res.status(500).json({ success: false, message: "Failed to update vehicle details" });
                    db.query(`
                        SELECT dp.partner_id, dp.partner_code, dp.emergency_contact,
                               dp.recommended_customer_limit, dp.shift_start, dp.shift_end,
                               dp.status AS partner_status, u.user_id, u.name, u.email, u.phone,
                               u.status AS account_status, v.vehicle_type, v.registration_number,
                               v.status AS vehicle_status
                        FROM delivery_partners dp
                        JOIN users u ON u.user_id = dp.user_id
                        LEFT JOIN partner_vehicles v ON v.partner_id = dp.partner_id AND v.status = 'ACTIVE'
                        WHERE dp.partner_id = ?`,
                        [partnerId],
                        (qErr, rows) => {
                            if (qErr || !rows.length) {
                                return res.json({ success: true, message: "Profile updated successfully" });
                            }
                            res.json({ success: true, message: "Profile updated successfully", profile: rows[0] });
                        }
                    );
                });
            });
        });
    });
});

app.get("/api/partner/routes", (req, res) => {
    withRole(req, res, "DELIVERY_PARTNER", (identity) => {
        const date = req.query.date || null;
        db.query(`
            SELECT dr.daily_route_id, dr.route_date, dr.status AS route_status,
                   r.route_id, r.route_name, a.area_id, a.area_name,
                   dp.shift_start, dp.shift_end,
                   caa.assignment_id, caa.sequence_number, caa.status AS assignment_status,
                   c.customer_id, u.name AS customer_name, u.phone AS customer_phone,
                   ca.address_line, ca.city, ca.pincode, ca.delivery_instructions
            FROM delivery_partners dp
            JOIN customer_assignments caa ON caa.partner_id = dp.partner_id
               AND caa.status <> 'REASSIGNED'
            JOIN daily_routes dr ON dr.daily_route_id = caa.daily_route_id
            JOIN routes r ON r.route_id = dr.route_id
            JOIN areas a ON a.area_id = r.area_id
            LEFT JOIN customers c ON c.customer_id = caa.customer_id
            LEFT JOIN users u ON u.user_id = c.user_id
            LEFT JOIN customer_addresses ca ON ca.address_id = caa.address_id
            WHERE dp.partner_id = ?
              AND (? IS NULL OR dr.route_date = ?)
            ORDER BY dr.route_date DESC, caa.sequence_number`,
            [identity.partner_id, date, date],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load assigned routes" });
                res.json({ success: true, routes: rows });
            }
        );
    });
});

app.get("/api/partner/deliveries", (req, res) => {
    withRole(req, res, "DELIVERY_PARTNER", (identity) => {
        const date = req.query.date || null;
        db.query(`
            SELECT d.delivery_id, d.assignment_id, d.delivery_date, d.scheduled_time,
                   d.actual_time, d.status AS delivery_status, d.failure_reason_id,
                   d.remarks, di.delivery_item_id, di.subscription_id,
                   di.newspaper_id, di.status AS item_status, di.reason_id,
                   di.remarks AS item_remarks, n.newspaper_name, n.language,
                   c.customer_id, u.name AS customer_name, ca.address_line,
                   ca.city, ca.pincode, ca.delivery_instructions,
                   dfr.reason_name AS failure_reason, caa.sequence_number
            FROM deliveries d
            JOIN delivery_items di ON di.delivery_id = d.delivery_id
            JOIN newspapers n ON n.newspaper_id = di.newspaper_id
            JOIN customers c ON c.customer_id = d.customer_id
            JOIN users u ON u.user_id = c.user_id
            LEFT JOIN customer_assignments caa ON caa.assignment_id = d.assignment_id
            LEFT JOIN customer_addresses ca ON ca.address_id = COALESCE(
                caa.address_id,
                (SELECT address_id FROM customer_addresses WHERE customer_id = c.customer_id LIMIT 1)
            )
            LEFT JOIN delivery_failure_reasons dfr ON dfr.reason_id = d.failure_reason_id
            WHERE d.partner_id = ?
              AND (? IS NULL OR DATE(d.delivery_date) = DATE(?))

            UNION ALL

            SELECT NULL AS delivery_id, caa.assignment_id, dr.route_date AS delivery_date,
                   COALESCE(s.scheduled_delivery_time, '07:00:00') AS scheduled_time,
                   NULL AS actual_time, 'PENDING' AS delivery_status, NULL AS failure_reason_id,
                   NULL AS remarks, NULL AS delivery_item_id, s.subscription_id,
                   s.newspaper_id, 'PENDING' AS item_status, NULL AS reason_id,
                   NULL AS item_remarks, n.newspaper_name, n.language,
                   c.customer_id, u.name AS customer_name, ca.address_line,
                   ca.city, ca.pincode, ca.delivery_instructions,
                   NULL AS failure_reason, caa.sequence_number
            FROM customer_assignments caa
            JOIN daily_routes dr ON dr.daily_route_id = caa.daily_route_id
            JOIN customers c ON c.customer_id = caa.customer_id
            JOIN users u ON u.user_id = c.user_id
            JOIN customer_addresses ca ON ca.address_id = caa.address_id
            LEFT JOIN subscriptions s ON s.customer_id = caa.customer_id
                AND s.address_id = caa.address_id
                AND s.status = 'ACTIVE'
            LEFT JOIN newspapers n ON n.newspaper_id = s.newspaper_id
            WHERE caa.partner_id = ?
              AND caa.status <> 'REASSIGNED'
              AND (? IS NULL OR DATE(dr.route_date) = DATE(?))
              AND NOT EXISTS (
                  SELECT 1 FROM deliveries ed
                  WHERE ed.assignment_id = caa.assignment_id
                    AND DATE(ed.delivery_date) = DATE(dr.route_date)
              )
            ORDER BY delivery_date DESC, sequence_number, assignment_id, delivery_id`,
            [identity.partner_id, date, date, identity.partner_id, date, date],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load assigned deliveries" });
                res.json({ success: true, deliveries: rows });
            }
        );
    });
});

app.get("/api/partner/failure-reasons", (req, res) => {
    withRole(req, res, "DELIVERY_PARTNER", () => {
        db.query(
            "SELECT reason_id, reason_name, category FROM delivery_failure_reasons ORDER BY reason_name",
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load failure reasons" });
                res.json({ success: true, reasons: rows });
            }
        );
    });
});

app.patch("/api/partner/deliveries/:deliveryId/status", (req, res) => {
    withRole(req, res, "DELIVERY_PARTNER", (identity) => {
        const deliveryId = Number(req.params.deliveryId);
        const status = String(req.body.status || "").toUpperCase();
        const allowed = ["DELIVERED", "PARTIALLY_DELIVERED", "NOT_DELIVERED", "DELAYED"];
        if (!Number.isInteger(deliveryId) || !allowed.includes(status)) {
            return res.status(400).json({ success: false, message: "A valid delivery and status are required" });
        }
        const assignmentId = req.body.assignment_id ? Number(req.body.assignment_id) : null;
        const failureReasonId = req.body.failure_reason_id ? Number(req.body.failure_reason_id) : null;
        const remarks = req.body.remarks ? String(req.body.remarks).trim() : null;
        const itemStatuses = Array.isArray(req.body.items) ? req.body.items : [];

        db.beginTransaction((beginError) => {
            if (beginError) return res.status(500).json({ success: false, message: "Unable to start delivery update" });

            // Check if existing delivery matches delivery_id or assignment_id
            db.query(
                `SELECT delivery_id, assignment_id FROM deliveries
                 WHERE (delivery_id = ? OR (assignment_id = ? AND assignment_id IS NOT NULL))
                   AND partner_id = ?
                 ORDER BY delivery_id DESC LIMIT 1 FOR UPDATE`,
                [deliveryId, assignmentId || deliveryId, identity.partner_id],
                (findError, delRows) => {
                    if (findError) {
                        return db.rollback(() => res.status(500).json({ success: false, message: "Failed to authorize delivery" }));
                    }

                    if (delRows.length > 0) {
                        const targetDeliveryId = delRows[0].delivery_id;
                        db.query(
                            `UPDATE deliveries
                             SET status = ?,
                                 actual_time = CASE WHEN ? = 'DELIVERED' THEN CURRENT_TIME ELSE actual_time END,
                                 failure_reason_id = ?, remarks = ?,
                                 editable_until = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 HOUR)
                             WHERE delivery_id = ? AND partner_id = ?`,
                            [status, status, failureReasonId, remarks, targetDeliveryId, identity.partner_id],
                            (updateError) => {
                                if (updateError) {
                                    return db.rollback(() => res.status(500).json({ success: false, message: "Failed to update delivery" }));
                                }
                                const updateItems = itemStatuses.length
                                    ? itemStatuses.map((item) => new Promise((resolve, reject) => {
                                        db.query(
                                            "UPDATE delivery_items SET status = ?, reason_id = ?, remarks = ? WHERE delivery_item_id = ? AND delivery_id = ?",
                                            [String(item.status || "").toUpperCase(), item.reason_id || null, item.remarks || null, item.delivery_item_id, targetDeliveryId],
                                            (error) => error ? reject(error) : resolve()
                                        );
                                    }))
                                    : (status === "DELIVERED" || status === "NOT_DELIVERED"
                                        ? [new Promise((resolve, reject) => db.query(
                                            "UPDATE delivery_items SET status = ? WHERE delivery_id = ?",
                                            [status === "DELIVERED" ? "DELIVERED" : "NOT_DELIVERED", targetDeliveryId],
                                            (error) => error ? reject(error) : resolve()
                                        ))]
                                        : []);
                                Promise.all(updateItems).then(() => {
                                    db.commit((commitError) => {
                                        if (commitError) {
                                            return db.rollback(() => res.status(500).json({ success: false, message: "Failed to save delivery update" }));
                                        }
                                        res.json({ success: true, message: "Delivery status updated", delivery_id: targetDeliveryId });
                                    });
                                }).catch(() => db.rollback(() => res.status(500).json({ success: false, message: "Failed to update delivery items" })));
                            }
                        );
                    } else {
                        // Check if it's an assignment without a delivery record yet
                        const targetAssignId = assignmentId || deliveryId;
                        db.query(
                            `SELECT caa.assignment_id, caa.customer_id, caa.partner_id, caa.address_id, dr.route_date
                             FROM customer_assignments caa
                             JOIN daily_routes dr ON dr.daily_route_id = caa.daily_route_id
                             WHERE caa.assignment_id = ? AND caa.partner_id = ? FOR UPDATE`,
                            [targetAssignId, identity.partner_id],
                            (assignError, assignRows) => {
                                if (assignError || !assignRows.length) {
                                    return db.rollback(() => res.status(assignError ? 500 : 404).json({
                                        success: false,
                                        message: assignError ? "Failed to find assignment" : "Delivery or assignment not found"
                                    }));
                                }
                                const assign = assignRows[0];
                                db.query(
                                    `INSERT INTO deliveries (assignment_id, customer_id, partner_id, delivery_date, scheduled_time, actual_time, status, failure_reason_id, remarks, submitted_at, editable_until)
                                     VALUES (?, ?, ?, ?, '07:00:00', CASE WHEN ? = 'DELIVERED' THEN CURRENT_TIME ELSE NULL END, ?, ?, ?, CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 HOUR))`,
                                    [assign.assignment_id, assign.customer_id, assign.partner_id, assign.route_date, status, status, failureReasonId, remarks],
                                    (insertError, insertResult) => {
                                        if (insertError) {
                                            return db.rollback(() => res.status(500).json({ success: false, message: "Failed to create delivery record" }));
                                        }
                                        const newDeliveryId = insertResult.insertId;
                                        db.query(
                                            `INSERT INTO delivery_items (delivery_id, subscription_id, newspaper_id, status, reason_id, remarks)
                                             SELECT ?, s.subscription_id, s.newspaper_id, ?, ?, ?
                                             FROM subscriptions s
                                             WHERE s.customer_id = ? AND s.address_id = ? AND s.status = 'ACTIVE'`,
                                            [newDeliveryId, status === "DELIVERED" ? "DELIVERED" : "NOT_DELIVERED", failureReasonId, remarks, assign.customer_id, assign.address_id],
                                            (itemsError) => {
                                                if (itemsError) {
                                                    return db.rollback(() => res.status(500).json({ success: false, message: "Failed to create delivery items" }));
                                                }
                                                db.commit((commitError) => {
                                                    if (commitError) {
                                                        return db.rollback(() => res.status(500).json({ success: false, message: "Failed to save delivery record" }));
                                                    }
                                                    res.json({ success: true, message: "Delivery status updated", delivery_id: newDeliveryId });
                                                });
                                            }
                                        );
                                    }
                                );
                            }
                        );
                    }
                }
            );
        });
    });
});




app.get("/api/partner/payments", (req, res) => {
    withRole(req, res, "DELIVERY_PARTNER", (identity) => {
        db.query(
            `SELECT COUNT(*) AS completed_deliveries
             FROM deliveries
             WHERE partner_id = ?
               AND status = 'DELIVERED'`,
            [identity.partner_id],
            (countError, countRows) => {
                if (countError) {
                    return res.status(500).json({
                        success: false,
                        message: "Failed to calculate delivery earnings"
                    });
                }

                const completedDeliveries =
                    Number(countRows[0]?.completed_deliveries ?? 0);

                const calculatedEarnings =
                    completedDeliveries * PARTNER_EARNING_PER_DELIVERY;

                db.query(
                    `SELECT partner_payment_id, partner_id,
                            payment_period, amount, status, paid_at
                     FROM partner_payments
                     WHERE partner_id = ?
                     ORDER BY paid_at DESC, partner_payment_id DESC`,
                    [identity.partner_id],
                    (paymentError, paymentRows) => {
                        if (paymentError) {
                            return res.status(500).json({
                                success: false,
                                message: "Failed to load partner payments"
                            });
                        }

                        res.json({
                            success: true,
                            earnings: {
                                rate_per_delivery:
                                    PARTNER_EARNING_PER_DELIVERY,
                                completed_deliveries: completedDeliveries,
                                calculated_total: calculatedEarnings,
                                total_earnings: calculatedEarnings
                            },
                            completed_deliveries: completedDeliveries,
                            calculated_earnings: calculatedEarnings,
                            payments: paymentRows || []
                        });
                    }
                );
            }
        );
    });
});


    app.get("/api/partner/notifications", (req, res) => {
        withRole(req, res, "DELIVERY_PARTNER", (identity) => {
            db.query(`
                SELECT notification_id, user_id, notification_type, title, message,
                       reference_type, reference_id, is_read, created_at
                FROM notifications
                WHERE user_id = ?
                ORDER BY created_at DESC`,
                [identity.user_id],
                (err, rows) => {
                    if (err) return res.status(500).json({ success: false, message: "Failed to load partner notifications" });
                    res.json({ success: true, notifications: rows });
                }
            );
        });
    });

    app.patch("/api/partner/notifications/:notificationId/read", (req, res) => {
        withRole(req, res, "DELIVERY_PARTNER", (identity) => {
            const { notificationId } = req.params;
            db.query(
                "UPDATE notifications SET is_read = 1 WHERE notification_id = ? AND user_id = ?",
                [notificationId, identity.user_id],
                (err, result) => {
                    if (err) return res.status(500).json({ success: false, message: "Failed to mark notification as read" });
                    if (!result.affectedRows) return res.status(404).json({ success: false, message: "Notification not found" });
                    res.json({ success: true, message: "Notification marked as read" });
                }
            );
        });
    });

// =========================================
// START SERVER
// =========================================

const PORT = process.env.PORT || 5000;

if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`DAILY server running on http://localhost:${PORT}`);
    });
}

module.exports = app;
