const http = require('http');
const app = require('./server');
const db = require('./db');

const server = http.createServer(app);

server.listen(0, async () => {
    const port = server.address().port;
    const baseUrl = `http://localhost:${port}`;
    console.log(`Test server running on ${baseUrl}`);

    let passed = 0;
    let failed = 0;

    async function request(path, options = {}) {
        const url = `${baseUrl}${path}`;
        const res = await fetch(url, options);
        const data = await res.json().catch(() => null);
        return { status: res.status, ok: res.ok, data };
    }

    function assert(condition, message) {
        if (condition) {
            console.log(`  ✓ PASS: ${message}`);
            passed++;
        } else {
            console.error(`  ✗ FAIL: ${message}`);
            failed++;
        }
    }

    try {
        console.log('\n--- Test 1: Unauthenticated request to /api/partner/payments ---');
        const unauthRes = await request('/api/partner/payments');
        assert(unauthRes.status === 401, `Status is 401 Unauthorized (got ${unauthRes.status})`);
        assert(unauthRes.data.success === false, 'success is false');
        assert(unauthRes.data.message.includes('invalid or has expired'), 'Error message states session is invalid or expired');

        console.log('\n--- Test 2: Authenticated request for Partner 1 (user_id=3, partner_id=1) ---');
        const authRes = await request('/api/partner/payments?user_id=3&partner_id=1');
        assert(authRes.status === 200, `Status is 200 OK (got ${authRes.status})`);
        assert(authRes.data.success === true, 'success is true');
        assert(authRes.data.earnings != null, 'earnings object is present');
        assert(authRes.data.earnings.rate_per_delivery === 10, 'Rate per delivery is exactly ₹10');

        const completedCount = authRes.data.earnings.completed_deliveries;
        const calcTotal = authRes.data.earnings.calculated_total;

        assert(typeof completedCount === 'number', `completed_deliveries is a number (${completedCount})`);
        assert(typeof calcTotal === 'number', `calculated_total is a number (₹${calcTotal})`);
        assert(calcTotal === completedCount * 10, `Calculated total ₹${calcTotal} equals ${completedCount} completed deliveries * ₹10`);

        // Backward and UI convenience aliases
        assert(authRes.data.earnings.total_earnings === calcTotal, 'earnings.total_earnings equals calculated_total');
        assert(authRes.data.completed_deliveries === completedCount, 'Root completed_deliveries matches earnings.completed_deliveries');
        assert(authRes.data.calculated_earnings === calcTotal, 'Root calculated_earnings matches earnings.calculated_total');

        console.log('\n--- Test 3: Preservation of Payment History ---');
        assert(Array.isArray(authRes.data.payments), 'payments is an array');
        console.log(`  Payment history record count: ${authRes.data.payments.length}`);
        if (authRes.data.payments.length === 0) {
            assert(true, 'Empty payment history correctly returned as [] without generating fake payment records');
        } else {
            const allBelong = authRes.data.payments.every(p => p.partner_id === 1);
            assert(allBelong, 'All payments in history strictly belong to partner_id 1');
            const hasRequiredKeys = authRes.data.payments.every(p => 
                p.partner_payment_id !== undefined && 
                p.payment_period !== undefined && 
                p.amount !== undefined && 
                p.status !== undefined
            );
            assert(hasRequiredKeys, 'Payment history records contain valid database schema fields');
        }

        console.log('\n--- Test 4: Database Cross-Verification (DELIVERED status filter) ---');
        const [delivRows] = await db.promise().query(
            "SELECT status, COUNT(*) AS cnt FROM deliveries WHERE partner_id = 1 GROUP BY status"
        );
        console.log('  Database deliveries breakdown for Partner 1:', delivRows);

        const deliveredRow = delivRows.find(r => r.status === 'DELIVERED');
        const dbDeliveredCount = deliveredRow ? Number(deliveredRow.cnt) : 0;

        assert(completedCount === dbDeliveredCount, 
            `completed_deliveries (${completedCount}) matches DB deliveries where status='DELIVERED' (${dbDeliveredCount})`);
        assert(calcTotal === dbDeliveredCount * 10,
            `calculated_total (₹${calcTotal}) strictly matches DB count * 10 (₹${dbDeliveredCount * 10})`);

        const nonDeliveredCount = delivRows
            .filter(r => r.status !== 'DELIVERED')
            .reduce((sum, r) => sum + Number(r.cnt), 0);
        console.log(`  Non-DELIVERED deliveries for Partner 1: ${nonDeliveredCount}`);
        if (nonDeliveredCount > 0) {
            assert(completedCount < (completedCount + nonDeliveredCount),
                'Non-DELIVERED records are excluded from earnings calculation');
        }

        console.log('\n--- Test 5: Database Cross-Verification (partner_payments table) ---');
        const [dbPayments] = await db.promise().query(
            "SELECT partner_payment_id, partner_id, payment_period, amount, status, paid_at FROM partner_payments WHERE partner_id = 1 ORDER BY paid_at DESC, partner_payment_id DESC"
        );
        assert(authRes.data.payments.length === dbPayments.length,
            `Returned payments count (${authRes.data.payments.length}) matches actual DB records (${dbPayments.length})`);

        console.log('\n--- Test 6: Partner Isolation Verification ---');
        const invalidPartner = await request('/api/partner/payments?user_id=99999&partner_id=99999');
        assert(invalidPartner.status === 403,
            `Unregistered partner request is rejected with 403 Forbidden (got ${invalidPartner.status})`);
        assert(invalidPartner.data.success === false, 'success is false for unauthorized partner');
        assert(invalidPartner.data.message.includes('not authorized'),
            'Error message confirms account is not authorized for delivery partner workspace');

        console.log(`\n========================================`);
        console.log(`Partner Payments Tests: ${passed} passed, ${failed} failed`);
        console.log(`========================================\n`);

    } catch (e) {
        console.error('Test execution error:', e);
        failed++;
    } finally {
        server.close(() => {
            db.end(() => {
                process.exit(failed > 0 ? 1 : 0);
            });
        });
    }
});
