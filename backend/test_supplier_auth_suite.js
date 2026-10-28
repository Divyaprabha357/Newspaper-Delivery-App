const http = require("http");
const app = require("./server");
const db = require("./db");

let server;
const PORT = 5056;

function request(path, method = "GET", body = null) {
    return new Promise((resolve, reject) => {
        const payload = body ? JSON.stringify(body) : null;
        const options = {
            hostname: "localhost",
            port: PORT,
            path,
            method,
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

async function runSupplierAuthTests() {
    console.log("=== STARTING DAILY SUPPLIER AUTH TEST SUITE ===\n");
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

    server = http.createServer(app);
    await new Promise((resolve) => server.listen(PORT, resolve));
    console.log(`Test server running on port ${PORT}\n`);

    const timestamp = Date.now();
    const testEmail = `test.supplier.${timestamp}@daily.test`;
    const testPhone = `982${String(timestamp).slice(-7)}`;
    let testUserId = null;
    let testSupplierId = null;

    try {
        // --- 1. Validation: Missing supplier_name ---
        console.log("--- TEST 1: Validation - Missing Supplier Name ---");
        const res1 = await request("/api/supplier/register", "POST", {
            name: "Rajesh Sharma",
            email: testEmail,
            phone: testPhone,
            address: "Dadar West, Mumbai",
            password: "password123"
        });
        assert(res1.statusCode === 400, `Missing supplier name rejected with 400 (got ${res1.statusCode})`);
        assert(res1.body.message.includes("Supplier or business name is required"), "Clear validation message for supplier name");

        // --- 2. Validation: Invalid Email ---
        console.log("\n--- TEST 2: Validation - Invalid Email Format ---");
        const res2 = await request("/api/supplier/register", "POST", {
            supplier_name: "Test Logistics",
            name: "Rajesh Sharma",
            email: "not-an-email",
            phone: testPhone,
            address: "Dadar West, Mumbai",
            password: "password123"
        });
        assert(res2.statusCode === 400, `Invalid email rejected with 400 (got ${res2.statusCode})`);
        assert(res2.body.message.includes("valid email"), "Clear email format validation message");

        // --- 3. Validation: Short Password ---
        console.log("\n--- TEST 3: Validation - Short Password ---");
        const res3 = await request("/api/supplier/register", "POST", {
            supplier_name: "Test Logistics",
            name: "Rajesh Sharma",
            email: testEmail,
            phone: testPhone,
            address: "Dadar West, Mumbai",
            password: "123"
        });
        assert(res3.statusCode === 400, `Short password rejected with 400 (got ${res3.statusCode})`);
        assert(res3.body.message.includes("at least 6 characters"), "Clear password length message");

        // --- 4. Validation: Duplicate existing user (admin@mumbaidaily.com) ---
        console.log("\n--- TEST 4: Duplicate Email Prevention ---");
        const res4 = await request("/api/supplier/register", "POST", {
            supplier_name: "Duplicate Dist",
            name: "Mumbai Admin",
            email: "admin@mumbaidaily.com",
            phone: testPhone,
            address: "Dadar West, Mumbai",
            password: "password123"
        });
        assert(res4.statusCode === 409, `Duplicate email rejected with 409 (got ${res4.statusCode})`);
        assert(res4.body.message.includes("already exists"), "Duplicate message returned");

        // --- 5. Successful Supplier Registration ---
        console.log("\n--- TEST 5: Successful Supplier Registration ---");
        const res5 = await request("/api/supplier/register", "POST", {
            supplier_name: `Test Press Supply ${timestamp}`,
            name: "Test Partner FullName",
            email: testEmail,
            phone: testPhone,
            address: "Unit 10, Dadar West, Mumbai",
            password: "SecurePassword123!",
            area_names: ["Dadar West", "Matunga"]
        });
        assert(res5.statusCode === 201, `Registration returned 201 Created (got ${res5.statusCode})`);
        assert(res5.body.success === true, "success is true");
        assert(res5.body.user != null, "user object returned");
        assert(res5.body.user.role === "SUPPLIER", "Role is 'SUPPLIER'");
        assert(res5.body.user.supplier_id != null, "Valid supplier_id returned");

        testUserId = res5.body.user.user_id;
        testSupplierId = res5.body.user.supplier_id;

        // Verify database records
        const [userRows] = await db.promise().query("SELECT * FROM users WHERE user_id = ?", [testUserId]);
        assert(userRows.length === 1, "User record exists in MySQL users table");
        assert(userRows[0].role === "SUPPLIER", "User role in DB is SUPPLIER");
        assert(userRows[0].password_hash.startsWith("scrypt:"), "Password hashed securely with scrypt");
        assert(!userRows[0].password_hash.includes("SecurePassword123!"), "Plaintext password never stored");

        const [suppRows] = await db.promise().query("SELECT * FROM suppliers WHERE supplier_id = ?", [testSupplierId]);
        assert(suppRows.length === 1, "Supplier record exists in suppliers table");
        assert(suppRows[0].supplier_name === `Test Press Supply ${timestamp}`, "Supplier name matches");
        assert(suppRows[0].user_id === testUserId, "Supplier user_id foreign key matches");

        // --- 6. Duplicate Prevention for Newly Registered Account ---
        console.log("\n--- TEST 6: Prevent Duplicate on Newly Registered Phone ---");
        const res6 = await request("/api/supplier/register", "POST", {
            supplier_name: "Another Supplier",
            name: "Another Name",
            email: `another.${timestamp}@daily.test`,
            phone: testPhone,
            address: "Dadar East, Mumbai",
            password: "password123"
        });
        assert(res6.statusCode === 409, `Duplicate phone rejected with 409 (got ${res6.statusCode})`);

        // --- 7. Login with Registered Supplier Account ---
        console.log("\n--- TEST 7: Login with Registered Supplier Credentials ---");
        const loginRes = await request("/api/login", "POST", {
            emailOrPhone: testEmail,
            password: "SecurePassword123!"
        });
        assert(loginRes.statusCode === 200, `Supplier login returned 200 (got ${loginRes.statusCode})`);
        assert(loginRes.body.success === true, "Login success is true");
        assert(loginRes.body.user.role === "SUPPLIER", "Login role is SUPPLIER");
        assert(loginRes.body.user.supplier_id === testSupplierId, "Login returns correct supplier_id");

        // --- 8. GET /api/areas ---
        console.log("\n--- TEST 8: GET /api/areas ---");
        const areasRes = await request("/api/areas", "GET");
        assert(areasRes.statusCode === 200, `Areas status is 200 (got ${areasRes.statusCode})`);
        assert(Array.isArray(areasRes.body.areas), "areas is an array");
        assert(areasRes.body.areas.length > 0, "Returns active service areas");

    } catch (err) {
        console.error("Test execution error:", err);
        failed++;
    } finally {
        // Cleanup test data safely
        if (testSupplierId) {
            await db.promise().query("DELETE FROM supplier_areas WHERE supplier_id = ?", [testSupplierId]).catch(() => {});
            await db.promise().query("DELETE FROM suppliers WHERE supplier_id = ?", [testSupplierId]).catch(() => {});
        }
        if (testUserId) {
            await db.promise().query("DELETE FROM users WHERE user_id = ?", [testUserId]).catch(() => {});
        }
        console.log("\n--- CLEANUP COMPLETE: Test records removed safely ---");
        server.close();
        console.log(`\n========================================`);
        console.log(`Supplier Auth Tests: ${passed} passed, ${failed} failed`);
        console.log(`========================================\n`);
        process.exit(failed > 0 ? 1 : 0);
    }
}

runSupplierAuthTests();

