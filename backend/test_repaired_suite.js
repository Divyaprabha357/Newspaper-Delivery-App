const http = require('http');
const app = require('./server');
const db = require('./db');

let server;
let baseUrl;

function request(path, options = {}) {
    return new Promise((resolve, reject) => {
        const url = new URL(path, baseUrl);
        const reqOptions = {
            method: options.method || 'GET',
            headers: options.headers || {}
        };
        if (options.body) {
            reqOptions.headers['Content-Type'] = 'application/json';
        }

        const req = http.request(url, reqOptions, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                let parsed = data;
                try {
                    parsed = JSON.parse(data);
                } catch (e) {}
                resolve({ status: res.statusCode, headers: res.headers, data: parsed });
            });
        });

        req.on('error', reject);
        if (options.body) {
            req.write(typeof options.body === 'string' ? options.body : JSON.stringify(options.body));
        }
        req.end();
    });
}

let passed = 0;
let failed = 0;

function assert(condition, message) {
    if (condition) {
        console.log(`  ✓ PASS: ${message}`);
        passed++;
    } else {
        console.error(`  ✗ FAIL: ${message}`);
        failed++;
    }
}

async function run() {
    server = http.createServer(app);
    await new Promise(resolve => server.listen(0, resolve));
    const port = server.address().port;
    baseUrl = `http://localhost:${port}`;
    console.log(`Test server running on ${baseUrl}`);

    try {
        console.log('\n--- 1. Supplier Reports Endpoint ---');
        const repRes = await request('/api/supplier/reports?user_id=5&supplier_id=1');
        assert(repRes.status === 200, `Supplier 1 reports status 200 (got ${repRes.status})`);
        assert(repRes.data.success === true, 'Supplier reports success is true');
        assert(repRes.data.reports != null, 'Supplier reports object returned');
        assert(repRes.data.reports.summary != null, 'Summary metrics present');
        assert(repRes.data.reports.summary.total_subscribers >= 1, `Subscribers count >= 1 (got ${repRes.data.reports.summary.total_subscribers})`);
        assert(repRes.data.reports.deliveries != null, 'Deliveries section present');
        assert(repRes.data.reports.revenue != null, 'Revenue section present');
        assert(Array.isArray(repRes.data.reports.top_newspapers), 'Top newspapers is array');
        assert(repRes.data.reports.top_newspapers.length >= 1, 'At least 1 newspaper listed');

        console.log('\n--- 2. Supplier Notifications & Mark-as-read ---');
        const notifRes = await request('/api/supplier/notifications?user_id=5&supplier_id=1');
        assert(notifRes.status === 200, 'Supplier notifications status 200');
        assert(Array.isArray(notifRes.data.notifications), 'Notifications is an array');

        if (notifRes.data.notifications.length > 0) {
            const firstId = notifRes.data.notifications[0].notification_id;
            const patchRes = await request(`/api/supplier/notifications/${firstId}/read?user_id=5&supplier_id=1`, {
                method: 'PATCH'
            });
            assert(patchRes.status === 200, 'Notification patch status 200');
            assert(patchRes.data.success === true, 'Notification marked as read');
        } else {
            console.log('  (Skipping read patch: no supplier notifications in DB)');
        }

        console.log('\n--- 3. Supplier Profile Update ---');
        const suppProfRes = await request('/api/supplier/profile?user_id=5&supplier_id=1', {
            method: 'PUT',
            body: {
                supplier_name: 'Mumbai Daily Distributors',
                contact_number: '9876543214',
                address: 'Dadar West, Mumbai'
            }
        });
        assert(suppProfRes.status === 200, `Supplier profile update 200 (got ${suppProfRes.status})`);
        assert(suppProfRes.data.success === true, 'Supplier profile update success is true');

        console.log('\n--- 4. Delivery Partner Profile Update ---');
        const partProfRes = await request('/api/partner/profile?user_id=3&partner_id=1', {
            method: 'PUT',
            body: {
                emergency_contact: '9988776655',
                status: 'ACTIVE'
            }
        });
        assert(partProfRes.status === 200, `Partner profile update 200 (got ${partProfRes.status})`);
        assert(partProfRes.data.success === true, 'Partner profile update success is true');

        console.log('\n--- 5. Payment Transactional Verification ---');
        // Test payment on non-existent bill
        const badPay = await request('/api/payments', {
            method: 'POST',
            body: {
                customer_id: 1,
                bill_id: 999999,
                amount: 100
            }
        });
        assert(badPay.status === 404, `Payment with non-existent bill returns 404 (got ${badPay.status})`);

        // Test payment on Bill 1 (already paid)
        const alreadyPaid = await request('/api/payments', {
            method: 'POST',
            body: {
                customer_id: 1,
                bill_id: 1,
                amount: 156.00
            }
        });
        assert(alreadyPaid.status === 400, `Payment on already-paid bill returns 400 (got ${alreadyPaid.status})`);
        assert(alreadyPaid.data.message.includes('already been paid'), 'Error indicates bill already paid');

    } catch (err) {
        console.error('Test execution error:', err);
        failed++;
    } finally {
        server.close();
        console.log(`\n========================================`);
        console.log(`Tests finished: ${passed} passed, ${failed} failed`);
        console.log(`========================================\n`);
        process.exit(failed > 0 ? 1 : 0);
    }
}

run();

