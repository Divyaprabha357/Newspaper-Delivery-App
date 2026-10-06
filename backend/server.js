const express = require("express");
const cors = require("cors");
const db = require("./db");

const app = express();

app.use(cors());
app.use(express.json());


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
        password
    } = req.body;

    if (!emailOrPhone || !password) {

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
            c.customer_code

        FROM users u

        LEFT JOIN customers c
            ON u.user_id = c.user_id

        WHERE u.email = ?
           OR u.phone = ?

        LIMIT 1;
    `;

    db.query(
        sql,
        [emailOrPhone, emailOrPhone],
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


            // Login successful
            res.json({
                success: true,
                message: "Login successful",

                user: {
                    user_id: user.user_id,
                    customer_id: user.customer_id,
                    customer_code: user.customer_code,
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
// START SERVER
// =========================================

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`DAILY server running on http://localhost:${PORT}`);
});
