import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const successCount = new Counter('success_count');
const latencyTrend = new Trend('latency_ms');

// Test configuration
export const options = {
    scenarios: {
        query_list: {
            executor: 'constant-vus',
            vus: 20,
            duration: '30s',
            exec: 'queryList',
        },
        query_aggregations: {
            executor: 'constant-vus',
            vus: 10,
            duration: '30s',
            exec: 'queryAggregations',
            startTime: '35s',
        },
        event_ingestion: {
            executor: 'constant-vus',
            vus: 15,
            duration: '30s',
            exec: 'ingestEvent',
            startTime: '70s',
        },
    },
    thresholds: {
        http_req_duration: ['p(95)<500'],
        errors: ['rate<0.1'],
    },
};

const QUERY_API_URL = __ENV.QUERY_API_URL || 'http://localhost:8091';
const EVENT_GATEWAY_URL = __ENV.EVENT_GATEWAY_URL || 'http://localhost:8090';

export function queryList() {
    const res = http.get(`${QUERY_API_URL}/v1/events?limit=20`, {
        headers: { 'X-Consumer-Name': 'audit-producer' },
    });

    const success = check(res, {
        'status is 200': (r) => r.status === 200,
        'has data': (r) => r.json('data') !== undefined,
    });

    errorRate.add(!success);
    if (success) successCount.add(1);
    latencyTrend.add(res.timings.duration);

    sleep(0.1);
}

export function queryAggregations() {
    const res = http.get(`${QUERY_API_URL}/v1/events/aggregations`, {
        headers: { 'X-Consumer-Name': 'audit-producer' },
    });

    const success = check(res, {
        'status is 200': (r) => r.status === 200,
    });

    errorRate.add(!success);
    if (success) successCount.add(1);
    latencyTrend.add(res.timings.duration);

    sleep(0.2);
}

export function ingestEvent() {
    const payload = JSON.stringify({
        event_id: `k6-test-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        event_date: new Date().toISOString().split('T')[0],
        actor: { id: 'k6-load-tester', email: 'k6@test.com' },
        action: { name: 'load-test' },
        resource: { type: 'test', id: `resource-${Date.now()}` },
        result: { success: true },
    });

    const res = http.post(`${EVENT_GATEWAY_URL}/v1/events`, payload, {
        headers: {
            'Content-Type': 'application/json',
            'X-Consumer-Name': 'audit-producer',
        },
    });

    const success = check(res, {
        'status is 200 or 202': (r) => r.status === 200 || r.status === 202,
        'has event_id': (r) => r.json('event_id') !== undefined,
    });

    errorRate.add(!success);
    if (success) successCount.add(1);
    latencyTrend.add(res.timings.duration);

    sleep(0.05);
}

export function handleSummary(data) {
    return {
        'stdout': textSummary(data, { indent: ' ', enableColors: true }),
        'results/load-test-summary.json': JSON.stringify(data, null, 2),
    };
}

function textSummary(data, options) {
    return `
=== Load Test Summary ===
Total Requests: ${data.metrics.http_reqs.values.count}
Success Rate: ${((1 - data.metrics.errors.values.rate) * 100).toFixed(2)}%
Avg Latency: ${data.metrics.http_req_duration.values.avg.toFixed(2)}ms
P95 Latency: ${data.metrics.http_req_duration.values['p(95)'].toFixed(2)}ms
P99 Latency: ${data.metrics.http_req_duration.values['p(99)'].toFixed(2)}ms
`;
}
