require("dotenv").config({ path: __dirname + "/.env" });
const http = require("http");
const app = require("./server");
const db = require("./db");

let server;
const PORT = 5055;

function makeRequest(method, path, body = null) {
    return new Promise((resolve, reject) => {
        const payload = body ? JSON.stringify(body) : null;
        const options = {
            hostname: "localhost",
            port: PORT,
            path: path,
            method: method,
            headers: {
                "Content-Type": "application/json",
                ...(payload ? { "Content-Length": Buffer.byteLength(payload) } : {})
            }
        };

        const req = http.request(options, (res) => {
            let data = "";
            res.on("data", (chunk) => data += chunk);
            res.on("end", () => {
                let parsed = null;
                try {
                    parsed = JSON.parse(data);
                } catch (_) {
                    parsed = data;
                }
                resolve({ statusCode: res.statusCode, headers: res.headers, body: parsed });
            });
        });

        req.on("error", reject);
        if (payload) req.write(payload);
        req.end();
    });
}

async function runTests() {
    console.log("=== STARTING DAILY AUTH TEST SUITE ===\n");
    let passed = 0;
    let failed = 0;

    const assert = (condition, message) => {
        if (condition) {
            console.log(`  [PASS] ${message}`);
            passed++;
        } else {
            console.error(`  [FAIL] ${message}`);
            failed++;
        }
    };

    await new Promise((res) => {
        server = app.listen(PORT, () => {
            console.log(`Test server running on port ${PORT}`);
            res();
        });
    });

    const timestamp = Date.now();
    const testCustomerEmail = `test.cust.${timestamp}@dailytest.com`;
    const testCustomerPhone = `91${String(timestamp).slice(-8)}`;
    const testPartnerEmail = `test.partner.${timestamp}@dailytest.com`;
    const testPartnerPhone = `92${String(timestamp).slice(-8)}`;

    let createdCustomerId = null;
    let createdCustomerUserId = null;
    let createdPartnerId = null;
    let createdPartnerUserId = null;

    try {
        // -------------------------------------------------------------
        // TEST 1: Customer Registration (Valid details)
        // -------------------------------------------------------------
        console.log("\n--- TEST 1: Customer Registration ---");
        const regCustRes = await makeRequest("POST", "/api/customer/register", {
            name: "Test Customer One",
            email: testCustomerEmail,
            phone: testCustomerPhone,
            address: "Flat 101, Palm Beach Road, Vashi",
            password: "CustPassword123!",
            preferred_delivery_time: "Morning (06:30 AM)"
        });

        assert(regCustRes.statusCode === 201, `Customer registration returns 201 Created (got ${regCustRes.statusCode})`);
        assert(regCustRes.body.success === true, "Customer registration returns success: true");
        assert(regCustRes.body.user && regCustRes.body.user.role === "CUSTOMER", "Returned user has role 'CUSTOMER'");
        assert(Boolean(regCustRes.body.user.customer_id), "Returned user has valid customer_id");
        assert(Boolean(regCustRes.body.user.customer_code), `Customer code generated: ${regCustRes.body.user?.customer_code}`);
        assert(Boolean(regCustRes.body.user.session_token), "Customer session token issued");

        createdCustomerUserId = regCustRes.body.user?.user_id;
        createdCustomerId = regCustRes.body.user?.customer_id;

        // Verify in DB directly
        const [custUserDb] = await db.promise().query("SELECT * FROM users WHERE user_id = ?", [createdCustomerUserId]);
        assert(custUserDb.length === 1, "User record exists in MySQL users table");
        assert(custUserDb[0].password_hash.startsWith("scrypt:"), "Password hashed securely with scrypt");
        assert(custUserDb[0].email === testCustomerEmail.toLowerCase(), "Email stored normalized in lowercase");

        const [custAddrDb] = await db.promise().query("SELECT * FROM customer_addresses WHERE customer_id = ?", [createdCustomerId]);
        assert(custAddrDb.length === 1, "Customer address record created in customer_addresses");
        assert(custAddrDb[0].address_line.includes("Palm Beach Road"), "Customer address stored correctly");

        // -------------------------------------------------------------
        // TEST 2: Customer Login (Registered credentials)
        // -------------------------------------------------------------
        console.log("\n--- TEST 2: Customer Login ---");
        const loginCustRes = await makeRequest("POST", "/api/login", {
            emailOrPhone: testCustomerEmail,
            password: "CustPassword123!"
        });
        assert(loginCustRes.statusCode === 200, `Login returns 200 OK (got ${loginCustRes.statusCode})`);
        assert(loginCustRes.body.success === true, "Login returns success: true");
        assert(loginCustRes.body.user?.customer_id === createdCustomerId, "Login returns correct customer_id");
        assert(loginCustRes.body.user?.role === "CUSTOMER", "Login returns role: 'CUSTOMER'");

        // -------------------------------------------------------------
        // TEST 3: Customer Login (Invalid Password)
        // -------------------------------------------------------------
        console.log("\n--- TEST 3: Customer Login with Invalid Password ---");
        const loginCustBadRes = await makeRequest("POST", "/api/login", {
            emailOrPhone: testCustomerEmail,
            password: "WrongPassword999"
        });
        assert(loginCustBadRes.statusCode === 401, `Invalid password rejected with 401 Unauthorized (got ${loginCustBadRes.statusCode})`);
        assert(loginCustBadRes.body.success === false, "Returns success: false");

        // -------------------------------------------------------------
        // TEST 4: Customer Duplicate Registration Rejection
        // -------------------------------------------------------------
        console.log("\n--- TEST 4: Duplicate Customer Registration ---");
        const dupCustRes = await makeRequest("POST", "/api/customer/register", {
            name: "Duplicate User",
            email: testCustomerEmail,
            phone: `91${String(timestamp + 1).slice(-8)}`,
            address: "Different Address",
            password: "CustPassword123!"
        });
        assert(dupCustRes.statusCode === 409, `Duplicate email rejected with 409 Conflict (got ${dupCustRes.statusCode})`);
        assert(dupCustRes.body.message.includes("already exists"), `Error message is clear: "${dupCustRes.body.message}"`);

        // -------------------------------------------------------------
        // TEST 5: Delivery Partner Registration
        // -------------------------------------------------------------
        console.log("\n--- TEST 5: Delivery Partner Registration ---");
        const regPartnerRes = await makeRequest("POST", "/api/partner/register", {
            name: "Test Partner One",
            email: testPartnerEmail,
            phone: testPartnerPhone,
            password: "PartnerPassword456!",
            emergency_contact: "9876543299",
            vehicle_type: "Motorcycle",
            registration_number: "MH 02 XY 9999",
            shift_start: "06:00:00",
            shift_end: "11:00:00"
        });

        assert(regPartnerRes.statusCode === 201, `Partner registration returns 201 Created (got ${regPartnerRes.statusCode})`);
        assert(regPartnerRes.body.success === true, "Partner registration returns success: true");
        assert(regPartnerRes.body.user?.role === "DELIVERY_PARTNER", "Returned role is 'DELIVERY_PARTNER'");
        assert(Boolean(regPartnerRes.body.user?.partner_id), "Valid partner_id returned");
        assert(Boolean(regPartnerRes.body.user?.partner_code), `Auto-assigned partner_code: ${regPartnerRes.body.user?.partner_code}`);

        createdPartnerUserId = regPartnerRes.body.user?.user_id;
        createdPartnerId = regPartnerRes.body.user?.partner_id;

        // Verify in DB directly
        const [partnerUserDb] = await db.promise().query("SELECT * FROM users WHERE user_id = ?", [createdPartnerUserId]);
        assert(partnerUserDb.length === 1, "User record exists for delivery partner");
        assert(partnerUserDb[0].password_hash.startsWith("scrypt:"), "Partner password hashed securely with scrypt");

        const [partnerDb] = await db.promise().query("SELECT * FROM delivery_partners WHERE partner_id = ?", [createdPartnerId]);
        assert(partnerDb.length === 1, "Delivery partner record exists in delivery_partners table");
        assert(partnerDb[0].user_id === createdPartnerUserId, "Foreign key user_id correctly matches");

        const [vehicleDb] = await db.promise().query("SELECT * FROM partner_vehicles WHERE partner_id = ?", [createdPartnerId]);
        assert(vehicleDb.length === 1, "Partner vehicle record created in partner_vehicles");
        assert(vehicleDb[0].registration_number === "MH 02 XY 9999", "Vehicle registration recorded accurately");

        // -------------------------------------------------------------
        // TEST 6: Delivery Partner Login (Email and Password ONLY — NO Partner Code)
        // -------------------------------------------------------------
        console.log("\n--- TEST 6: Delivery Partner Login (Email and Password Only) ---");
        const partnerLoginRes = await makeRequest("POST", "/api/login", {
            emailOrPhone: testPartnerEmail,
            password: "PartnerPassword456!"
            // NOTE: NO partnerCode sent!
        });
        assert(partnerLoginRes.statusCode === 200, `Partner login succeeds with email + password (got ${partnerLoginRes.statusCode})`);
        assert(partnerLoginRes.body.success === true, "Login returns success: true");
        assert(partnerLoginRes.body.user?.partner_id === createdPartnerId, "Returns correct partner_id");
        assert(partnerLoginRes.body.user?.role === "DELIVERY_PARTNER", "Role is 'DELIVERY_PARTNER'");
        assert(partnerLoginRes.body.user?.partner_code === regPartnerRes.body.user?.partner_code, "Partner code returned in user info");

        // -------------------------------------------------------------
        // TEST 7: Delivery Partner Login with Invalid Password
        // -------------------------------------------------------------
        console.log("\n--- TEST 7: Partner Login with Invalid Password ---");
        const partnerBadPass = await makeRequest("POST", "/api/login", {
            emailOrPhone: testPartnerEmail,
            password: "WrongPassword123"
        });
        assert(partnerBadPass.statusCode === 401, `Partner invalid password rejected with 401 (got ${partnerBadPass.statusCode})`);

        // -------------------------------------------------------------
        // TEST 8: Customer Credentials Cannot Login as Delivery Partner
        // -------------------------------------------------------------
        console.log("\n--- TEST 8: Cross-Role Protection ---");
        const crossRoleRes = await makeRequest("POST", "/api/login", {
            emailOrPhone: testCustomerEmail,
            password: "CustPassword123!",
            role: "DELIVERY_PARTNER"
        });
        assert(crossRoleRes.statusCode === 403, `Customer blocked from Delivery Partner role login with 403 (got ${crossRoleRes.statusCode})`);

        // -------------------------------------------------------------
        // TEST 9: Existing Demo User Backward Compatibility
        // -------------------------------------------------------------
        console.log("\n--- TEST 9: Backwards Compatibility with Existing Demo Accounts ---");
        const aaravLogin = await makeRequest("POST", "/api/login", {
            emailOrPhone: "aarav@gmail.com",
            password: "123456"
        });
        assert(aaravLogin.statusCode === 200, `Aarav Sharma login succeeds (got ${aaravLogin.statusCode})`);
        assert(aaravLogin.body.user?.customer_id === 1, "Aarav customer_id is 1");

        const rahulLogin = await makeRequest("POST", "/api/login", {
            emailOrPhone: "rahul@daily.com",
            password: "demo_hash_123"
        });
        assert(rahulLogin.statusCode === 200, `Rahul Patil (Partner) login succeeds via EMAIL (got ${rahulLogin.statusCode})`);
        assert(rahulLogin.body.user?.partner_id === 1, "Rahul partner_id is 1");
        assert(rahulLogin.body.user?.partner_code === "DP001", "Rahul partner_code is DP001");

    } finally {
        // Clean up test records
        console.log("\n--- CLEANING UP TEST DATA ---");
        try {
            if (createdCustomerId) {
                await db.promise().query("DELETE FROM customer_addresses WHERE customer_id = ?", [createdCustomerId]);
                await db.promise().query("DELETE FROM customers WHERE customer_id = ?", [createdCustomerId]);
            }
            if (createdCustomerUserId) {
                await db.promise().query("DELETE FROM users WHERE user_id = ?", [createdCustomerUserId]);
            }
            if (createdPartnerId) {
                await db.promise().query("DELETE FROM partner_vehicles WHERE partner_id = ?", [createdPartnerId]);
                await db.promise().query("DELETE FROM delivery_partners WHERE partner_id = ?", [createdPartnerId]);
            }
            if (createdPartnerUserId) {
                await db.promise().query("DELETE FROM users WHERE user_id = ?", [createdPartnerUserId]);
            }
            console.log("  [INFO] Test data cleaned up successfully. Database preserved.");
        } catch (cleanupErr) {
            console.error("  [WARN] Cleanup error:", cleanupErr.message);
        }

        server.close();
        db.end();
    }

    console.log(`\n=== TEST SUITE COMPLETE: ${passed} PASSED, ${failed} FAILED ===\n`);
    process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(err => {
    console.error("Fatal test error:", err);
    if (server) server.close();
    db.end();
    process.exit(1);
});

