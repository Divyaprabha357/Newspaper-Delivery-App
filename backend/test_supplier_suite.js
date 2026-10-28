const http = require('http');
const app = require('./server');

const server = http.createServer(app);

server.listen(0, async () => {
    const port = server.address().port;
    const baseUrl = `http://localhost:${port}`;
    console.log(`Test server running on ${baseUrl}`);

    let testsPassed = 0;
    let testsFailed = 0;

    async function request(path, options = {}) {
        const url = `${baseUrl}${path}`;
        const res = await fetch(url, options);
        const data = await res.json().catch(() => null);
        return { status: res.status, ok: res.ok, data };
    }

    function assert(condition, message) {
        if (condition) {
            console.log(`  ✓ PASS: ${message}`);
            testsPassed++;
        } else {
            console.error(`  ✗ FAIL: ${message}`);
            testsFailed++;
        }
    }

    try {
        console.log('\n--- Test 1: GET /api/supplier/payments for Supplier 1 (Mumbai Daily Admin) ---');
        const payRes1 = await request('/api/supplier/payments?user_id=5&supplier_id=1');
        assert(payRes1.status === 200, `Status is 200 (got ${payRes1.status})`);
        assert(payRes1.data.success === true, 'Response success is true');
        assert(Array.isArray(payRes1.data.payments), 'Payments is an array');
        assert(payRes1.data.payments.length === 2, `Returned 2 payment/bill records (got ${payRes1.data.payments.length})`);
        assert(payRes1.data.summary != null, 'Summary object is returned');
        assert(payRes1.data.summary.total_earnings === '286.00', `Total earnings is 286.00 (got ${payRes1.data.summary.total_earnings})`);
        assert(payRes1.data.summary.amount_received === '156.00', `Amount received is 156.00 (got ${payRes1.data.summary.amount_received})`);
        assert(payRes1.data.summary.pending_amount === '130.00', `Pending amount is 130.00 (got ${payRes1.data.summary.pending_amount})`);

        const p1 = payRes1.data.payments.find(p => p.bill_id === 1);
        assert(p1 != null && p1.customer_name === 'Aarav Sharma', 'Bill 1 customer is Aarav Sharma');
        assert(p1 != null && p1.newspaper_names.includes('Times of India'), 'Bill 1 includes Times of India');

        console.log('\n--- Test 2: GET /api/supplier/requests for Supplier 1 ---');
        const reqRes1 = await request('/api/supplier/requests?user_id=5&supplier_id=1');
        assert(reqRes1.status === 200, `Status is 200 (got ${reqRes1.status})`);
        assert(reqRes1.data.success === true, 'Response success is true');
        assert(Array.isArray(reqRes1.data.requests), 'Requests is an array');
        assert(Array.isArray(reqRes1.data.complaints), 'Complaints is an array');
        assert(reqRes1.data.requests.length >= 4, `Returned at least 4 customer requests (got ${reqRes1.data.requests.length})`);
        assert(reqRes1.data.complaints.length === 1, `Returned 1 delivery complaint (got ${reqRes1.data.complaints.length})`);

        const c1 = reqRes1.data.complaints[0];
        assert(c1.complaint_type === 'MISSED_DELIVERY', 'Complaint 1 is MISSED_DELIVERY');
        assert(c1.customer_name === 'Aarav Sharma', 'Complaint 1 customer is Aarav Sharma');
        assert(c1.resolution.length > 0, 'Complaint 1 has resolution text');

        console.log('\n--- Test 3: Supplier Data Isolation (Supplier 2 - Western News) ---');
        const payRes2 = await request('/api/supplier/payments?user_id=6&supplier_id=2');
        assert(payRes2.status === 200, `Supplier 2 payments status is 200`);
        assert(payRes2.data.payments.length === 0, `Supplier 2 has 0 payment records (no payment leakage)`);
        assert(payRes2.data.summary.total_earnings === '0.00', 'Supplier 2 earnings is 0.00');

        const reqRes2 = await request('/api/supplier/requests?user_id=6&supplier_id=2');
        assert(reqRes2.status === 200, `Supplier 2 requests status is 200`);
        assert(reqRes2.data.complaints.length === 0, `Supplier 2 has 0 complaints (Complaint 1 isolated to Supplier 1)`);
        assert(reqRes2.data.requests.every(r => r.reference_id == null || r.newspaper_id == null), `Supplier 2 does not receive Supplier 1's subscription-specific requests`);

        console.log('\n--- Test 4: PATCH /api/supplier/requests/:id/status ---');
        const patchReq = await request('/api/supplier/requests/4/status', {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'X-User-Id': '5', 'X-Supplier-Id': '1' },
            body: JSON.stringify({ status: 'PENDING' })
        });
        assert(patchReq.status === 200, `PATCH request status is 200`);
        assert(patchReq.data.success === true, 'PATCH request success is true');

        console.log('\n--- Test 5: PATCH /api/supplier/complaints/:id/status ---');
        const patchComp = await request('/api/supplier/complaints/1/status', {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'X-User-Id': '5', 'X-Supplier-Id': '1' },
            body: JSON.stringify({ status: 'RESOLVED', resolution: 'Replacement newspaper scheduled for delivery.' })
        });
        assert(patchComp.status === 200, `PATCH complaint status is 200`);
        assert(patchComp.data.success === true, 'PATCH complaint success is true');

        console.log('\n--- Test 6: GET /api/supplier/distribution for Supplier 1 ---');
        const distRes = await request('/api/supplier/distribution?user_id=5&supplier_id=1');
        assert(distRes.status === 200, `Distribution status is 200 (got ${distRes.status})`);
        assert(distRes.data.success === true, 'Distribution success is true');
        assert(Array.isArray(distRes.data.distribution), 'Distribution list is an array');
        assert(distRes.data.distribution.length > 0, `Returned ${distRes.data.distribution.length} newspaper distribution rows`);
        assert(distRes.data.summary != null, 'Summary object returned');
        assert(typeof distRes.data.summary.expected_demand === 'number', 'Summary has expected_demand number');
        assert(typeof distRes.data.summary.available_stock === 'number', 'Summary has available_stock number');
        assert(typeof distRes.data.summary.shortage === 'number', 'Summary has shortage number');
        assert(typeof distRes.data.summary.dispatch_planned === 'number', 'Summary has dispatch_planned number');

        console.log('\n--- Test 7: GET /api/supplier/deliveries for Supplier 1 ---');
        const delivRes = await request('/api/supplier/deliveries?user_id=5&supplier_id=1');
        assert(delivRes.status === 200, `Deliveries status is 200 (got ${delivRes.status})`);
        assert(delivRes.data.success === true, 'Deliveries success is true');
        assert(Array.isArray(delivRes.data.deliveries), 'Deliveries list is an array');

        console.log('\n--- Test 8: GET /api/supplier/routes for Supplier 1 ---');
        const routesRes = await request('/api/supplier/routes?user_id=5&supplier_id=1');
        assert(routesRes.status === 200, `Routes status is 200 (got ${routesRes.status})`);
        assert(routesRes.data.success === true, 'Routes success is true');
        assert(Array.isArray(routesRes.data.routes), 'Routes is an array');
        assert(routesRes.data.routes.length >= 1, `Returned at least 1 route (got ${routesRes.data.routes.length})`);

        console.log('\n--- Test 9: GET /api/supplier/partners for Supplier 1 ---');
        const partnersRes = await request('/api/supplier/partners?user_id=5&supplier_id=1');
        assert(partnersRes.status === 200, `Partners status is 200 (got ${partnersRes.status})`);
        assert(partnersRes.data.success === true, 'Partners success is true');
        assert(Array.isArray(partnersRes.data.partners), 'Partners is an array');
        assert(partnersRes.data.partners.length >= 1, `Returned at least 1 partner (got ${partnersRes.data.partners.length})`);
        const firstPartner = partnersRes.data.partners[0];
        assert(firstPartner.partner_name != null, 'Partner has partner_name');
        assert(firstPartner.partner_status != null, 'Partner has partner_status');
        assert(typeof firstPartner.delivery_count === 'number', 'Partner has numeric delivery_count');

        console.log(`\n========================================`);
        console.log(`Tests finished: ${testsPassed} passed, ${testsFailed} failed`);
        console.log(`========================================\n`);

    } catch (e) {
        console.error('Test execution error:', e);
        testsFailed++;
    } finally {
        server.close(() => {
            process.exit(testsFailed > 0 ? 1 : 0);
        });
    }
});
