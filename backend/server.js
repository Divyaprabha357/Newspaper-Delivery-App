const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const db = require("./db");

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
// LOGIN
// =========================================

app.post("/api/login", (req, res) => {

    const {
        emailOrPhone,
        password,
        partnerCode
    } = req.body;

    if ((!emailOrPhone && !partnerCode) || !password) {

        return res.status(400).json({
            success: false,
            message: "Email/phone and password are required"
        });

    }

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

        WHERE u.email = ?
           OR u.phone = ?
           OR (? IS NOT NULL AND dp.partner_code = ?)

        LIMIT 1;
    `;

    db.query(
        sql,
        [emailOrPhone, emailOrPhone, partnerCode || null, partnerCode || null],
        (err, results) => {

            if (err) {

                console.error(
                    "Login database error:",
                    err
                );

                return res.status(500).json({
                    success: false,
                    message: "Server error"
                });

            }

            if (results.length === 0) {

                return res.status(401).json({
                    success: false,
                    message: "Invalid email/phone or password"
                });

            }

            const user = results[0];


            // Temporary password check
            if (user.password_hash !== password) {

                return res.status(401).json({
                    success: false,
                    message: "Invalid email/phone or password"
                });

            }


            // Check account status
            if (user.status !== "ACTIVE") {

                return res.status(403).json({
                    success: false,
                    message: "Your account is not active"
                });

            }


            const sessionToken = createSession(user.user_id, user.role);

            // Login successful
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

        }
    );

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

            s.supplier_id,
            sp.supplier_name,

            s.address_id,
            ca.address_line,
            ca.city,
            ca.pincode,

            s.start_date,
            s.end_date,
            s.status,
            s.delivery_days,
            s.scheduled_delivery_time,
            s.agreed_price

        FROM subscriptions s

        JOIN newspapers n
            ON s.newspaper_id = n.newspaper_id

        JOIN suppliers sp
            ON s.supplier_id = sp.supplier_id

        JOIN customer_addresses ca
            ON s.address_id = ca.address_id

        WHERE s.customer_id = ?

        ORDER BY s.subscription_id;
    `;

    db.query(
        sql,
        [customer_id],
        (err, results) => {

            if (err) {

                console.error(
                    "Error fetching subscriptions:",
                    err
                );

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
            p.payment_id,
            p.customer_id,

            p.bill_id,

            b.billing_period_start,
            b.billing_period_end,
            b.subtotal,
            b.adjustments,
            b.total_amount,
            b.status AS bill_status,

            p.amount,
            p.payment_method,
            p.transaction_reference,
            p.payment_date,
            p.status AS payment_status

        FROM payments p

        JOIN bills b
            ON p.bill_id = b.bill_id

        WHERE p.customer_id = ?

        ORDER BY p.payment_date DESC;
    `;

    db.query(
        sql,
        [customer_id],
        (err, results) => {

            if (err) {

                console.error(
                    "Error fetching payments:",
                    err
                );

                return res.status(500).json({
                    success: false,
                    message: "Failed to fetch payments"
                });

            }

            res.json({
                success: true,
                payments: results
            });

        }
    );

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
               sn.supplier_id, sp.supplier_name, np.price_per_delivery
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

app.post("/api/subscriptions", (req, res) => {
    const { customer_id, newspaper_id, supplier_id, delivery_days = "MON,TUE,WED,THU,FRI,SAT,SUN", scheduled_delivery_time = "07:00:00" } = req.body;
    if (!customer_id || !newspaper_id || !supplier_id) return res.status(400).json({ success: false, message: "customer_id, newspaper_id and supplier_id are required" });

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
    db.query(sql, [customer_id, newspaper_id, supplier_id, delivery_days, scheduled_delivery_time, supplier_id, newspaper_id, customer_id], (err, result) => {
        if (err) return res.status(500).json({ success: false, message: "Failed to create subscription" });
        if (!result.affectedRows) return res.status(400).json({ success: false, message: "This newspaper is unavailable or no active delivery address was found" });
        res.status(201).json({ success: true, message: "Newspaper subscription created", subscription_id: result.insertId });
    });
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
    if (!session || session.expiresAt < Date.now() || session.role !== role) {
        return res.status(401).json({ success: false, message: "Your session is invalid or has expired" });
    }
    const userId = session.userId;

    const sql = `
        SELECT u.user_id, u.name, u.email, u.phone, u.role, u.status,
               sp.supplier_id, sp.supplier_name, sp.contact_number AS supplier_contact,
               sp.address AS supplier_address, sp.created_at AS supplier_created_at,
               dp.partner_id, dp.partner_code, dp.emergency_contact,
               dp.shift_start, dp.shift_end, dp.status AS partner_status
        FROM users u
        LEFT JOIN suppliers sp ON sp.user_id = u.user_id
        LEFT JOIN delivery_partners dp ON dp.user_id = u.user_id
        WHERE u.user_id = ? AND u.role = ? AND u.status = 'ACTIVE'
        LIMIT 1`;

    db.query(sql, [userId, role], (err, rows) => {
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
            JOIN customer_assignments caa ON caa.assignment_id = d.assignment_id
            JOIN customer_addresses ca ON ca.address_id = caa.address_id
            JOIN areas a ON a.area_id = ca.area_id
            JOIN delivery_partners dp ON dp.partner_id = d.partner_id
            JOIN users pu ON pu.user_id = dp.user_id
            WHERE s.supplier_id = ?
              AND (? IS NULL OR d.delivery_date = ?)
            ORDER BY d.delivery_date DESC, d.scheduled_time, d.delivery_id`,
            [identity.supplier_id, date, date],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load supplier deliveries" });
                res.json({ success: true, deliveries: rows });
            }
        );
    });
});

app.get("/api/supplier/payments", (req, res) => {
    withRole(req, res, "SUPPLIER", (identity) => {
        db.query(`
            SELECT DISTINCT b.bill_id, b.customer_id, b.billing_period_start,
                   b.billing_period_end, b.subtotal, b.adjustments, b.total_amount,
                   b.status AS bill_status, p.payment_id, p.amount,
                   p.payment_method, p.transaction_reference, p.payment_date,
                   p.status AS payment_status, u.name AS customer_name
            FROM bills b
            JOIN bill_items bi ON bi.bill_id = b.bill_id
            JOIN subscriptions s ON s.subscription_id = bi.subscription_id
            JOIN customers c ON c.customer_id = b.customer_id
            JOIN users u ON u.user_id = c.user_id
            LEFT JOIN payments p ON p.bill_id = b.bill_id
            WHERE s.supplier_id = ?
            ORDER BY COALESCE(p.payment_date, b.generated_at) DESC`,
            [identity.supplier_id],
            (err, rows) => {
                if (err) return res.status(500).json({ success: false, message: "Failed to load supplier payments" });
                res.json({ success: true, payments: rows });
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

app.get("/api/partner/routes", (req, res) => {
    withRole(req, res, "DELIVERY_PARTNER", (identity) => {
        const date = req.query.date || null;
        db.query(`
            SELECT dr.daily_route_id, dr.route_date, dr.status AS route_status,
                   r.route_id, r.route_name, a.area_id, a.area_name,
                   rp.shift_start, rp.shift_end,
                   caa.assignment_id, caa.sequence_number, caa.status AS assignment_status,
                   c.customer_id, u.name AS customer_name, u.phone AS customer_phone,
                   ca.address_line, ca.city, ca.pincode, ca.delivery_instructions
            FROM route_partners rp
            JOIN daily_routes dr ON dr.daily_route_id = rp.daily_route_id
            JOIN routes r ON r.route_id = dr.route_id
            JOIN areas a ON a.area_id = r.area_id
            LEFT JOIN customer_assignments caa
                ON caa.daily_route_id = dr.daily_route_id
               AND caa.partner_id = rp.partner_id
               AND caa.status <> 'REASSIGNED'
            LEFT JOIN customers c ON c.customer_id = caa.customer_id
            LEFT JOIN users u ON u.user_id = c.user_id
            LEFT JOIN customer_addresses ca ON ca.address_id = caa.address_id
            WHERE rp.partner_id = ?
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
                   dfr.reason_name AS failure_reason
            FROM deliveries d
            JOIN delivery_items di ON di.delivery_id = d.delivery_id
            JOIN newspapers n ON n.newspaper_id = di.newspaper_id
            JOIN customers c ON c.customer_id = d.customer_id
            JOIN users u ON u.user_id = c.user_id
            JOIN customer_addresses ca ON ca.address_id = (
                SELECT address_id FROM customer_assignments
                WHERE assignment_id = d.assignment_id LIMIT 1
            )
            LEFT JOIN delivery_failure_reasons dfr ON dfr.reason_id = d.failure_reason_id
            WHERE d.partner_id = ?
              AND (? IS NULL OR d.delivery_date = ?)
            ORDER BY d.delivery_date DESC, d.scheduled_time, d.delivery_id`,
            [identity.partner_id, date, date],
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
        const failureReasonId = req.body.failure_reason_id ? Number(req.body.failure_reason_id) : null;
        const remarks = req.body.remarks ? String(req.body.remarks).trim() : null;
        const itemStatuses = Array.isArray(req.body.items) ? req.body.items : [];
        db.beginTransaction((beginError) => {
            if (beginError) return res.status(500).json({ success: false, message: "Unable to start delivery update" });
            db.query(
                "SELECT delivery_id FROM deliveries WHERE delivery_id = ? AND partner_id = ? FOR UPDATE",
                [deliveryId, identity.partner_id],
                (findError, rows) => {
                    if (findError || !rows.length) {
                        return db.rollback(() => res.status(findError ? 500 : 404).json({
                            success: false,
                            message: findError ? "Failed to authorize delivery" : "Delivery not found"
                        }));
                    }
                    db.query(
                        `UPDATE deliveries
                         SET status = ?, actual_time = CASE WHEN ? = 'DELIVERED' THEN CURRENT_TIME ELSE actual_time END,
                             failure_reason_id = ?, remarks = ?
                         WHERE delivery_id = ? AND partner_id = ?
                           AND (editable_until IS NULL OR editable_until >= CURRENT_TIMESTAMP)`,
                        [status, status, failureReasonId, remarks, deliveryId, identity.partner_id],
                        (updateError, updateResult) => {
                            if (updateError) {
                                return db.rollback(() => res.status(500).json({ success: false, message: "Failed to update delivery" }));
                            }
                            if (!updateResult.affectedRows) {
                                return db.rollback(() => res.status(409).json({ success: false, message: "This delivery is no longer editable" }));
                            }
                            const updateItems = itemStatuses.length
                                ? itemStatuses.map((item) => new Promise((resolve, reject) => {
                                    db.query(
                                        "UPDATE delivery_items SET status = ?, reason_id = ?, remarks = ? WHERE delivery_item_id = ? AND delivery_id = ?",
                                        [String(item.status || "").toUpperCase(), item.reason_id || null, item.remarks || null, item.delivery_item_id, deliveryId],
                                        (error) => error ? reject(error) : resolve()
                                    );
                                }))
                                : (status === "DELIVERED" || status === "NOT_DELIVERED"
                                    ? [new Promise((resolve, reject) => db.query(
                                        "UPDATE delivery_items SET status = ? WHERE delivery_id = ?",
                                        [status === "DELIVERED" ? "DELIVERED" : "NOT_DELIVERED", deliveryId],
                                        (error) => error ? reject(error) : resolve()
                                    ))]
                                    : []);
                            Promise.all(updateItems).then(() => {
                                db.commit((commitError) => {
                                    if (commitError) {
                                        return db.rollback(() => res.status(500).json({ success: false, message: "Failed to save delivery update" }));
                                    }
                                    res.json({ success: true, message: "Delivery status updated" });
                                });

                                app.get("/api/partner/payments", (req, res) => {
                                    withRole(req, res, "DELIVERY_PARTNER", (identity) => {
                                        db.query(`
                                            SELECT partner_payment_id, partner_id, payment_period, amount,
                                                   status, paid_at
                                            FROM partner_payments
                                            WHERE partner_id = ?
                                            ORDER BY period_start DESC`,
                                            [identity.partner_id],
                                            (err, rows) => {
                                                if (err) return res.status(500).json({ success: false, message: "Failed to load partner payments" });
                                                res.json({ success: true, payments: rows });
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
                            }).catch(() => db.rollback(() => res.status(500).json({ success: false, message: "Failed to update delivery items" })));
                        }
                    );
                }
            );
        });
    });
});

// =========================================
// START SERVER
// =========================================

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`DAILY server running on http://localhost:${PORT}`);
});
