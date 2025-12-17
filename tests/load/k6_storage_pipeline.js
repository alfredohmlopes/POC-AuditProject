import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const eventLatency = new Trend('event_latency');

// Configuration
const BASE_URL = __ENV.BASE_URL || 'http://localhost:9080';
const API_KEY = __ENV.API_KEY || 'poc-audit-api-key-2024';

export const options = {
    scenarios: {
        // Ramp up to 5000 req/s target
        sustained_load: {
            executor: 'ramping-arrival-rate',
            startRate: 100,
            timeUnit: '1s',
            preAllocatedVUs: 500,
            maxVUs: 2000,
            stages: [
                { duration: '30s', target: 1000 },   // Ramp to 1000 req/s
                { duration: '1m', target: 2500 },    // Ramp to 2500 req/s
                { duration: '2m', target: 5000 },    // Ramp to 5000 req/s
                { duration: '2m', target: 5000 },    // Hold at 5000 req/s
                { duration: '30s', target: 0 },      // Ramp down
            ],
        },
    },
    thresholds: {
        http_req_duration: ['p(99)<200'],  // 99th percentile < 200ms
        errors: ['rate<0.01'],              // Error rate < 1%
        event_latency: ['p(95)<100'],       // 95th percentile latency < 100ms
    },
};

// Generate random event payload
function generateEvent() {
    const userId = `user-${Math.random().toString(36).substr(2, 9)}`;
    const actions = ['user.login', 'user.logout', 'document.create', 'document.update', 'admin.action'];
    const resourceTypes = ['user', 'document', 'organization', 'role'];

    return JSON.stringify({
        actor: { id: userId, type: 'user', email: `${userId}@example.com` },
        action: { name: actions[Math.floor(Math.random() * actions.length)] },
        resource: {
            type: resourceTypes[Math.floor(Math.random() * resourceTypes.length)],
            id: `res-${Math.random().toString(36).substr(2, 9)}`
        },
        timestamp: new Date().toISOString(),
        result: { success: Math.random() > 0.1 },  // 90% success rate
        context: {
            ip: `10.0.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}`,
            user_agent: 'k6-load-test/1.0'
        }
    });
}

const headers = {
    'Content-Type': 'application/json',
    'X-API-Key': API_KEY,
};

export default function () {
    const start = Date.now();
    const payload = generateEvent();

    const response = http.post(`${BASE_URL}/v1/events`, payload, { headers });

    const latency = Date.now() - start;
    eventLatency.add(latency);

    const success = check(response, {
        'status is 202': (r) => r.status === 202,
        'has event_id': (r) => {
            try {
                return JSON.parse(r.body).event_id !== undefined;
            } catch {
                return false;
            }
        },
        'latency < 200ms': () => latency < 200,
    });

    errorRate.add(!success);
}

export function handleSummary(data) {
    const reqRate = data.metrics.http_reqs?.values?.rate || 0;
    const p99 = data.metrics.http_req_duration?.values?.['p(99)'] || 0;
    const errors = data.metrics.errors?.values?.rate || 0;

    console.log('\n========================================');
    console.log('       LOAD TEST SUMMARY');
    console.log('========================================');
    console.log(`Request Rate:  ${reqRate.toFixed(2)} req/s`);
    console.log(`p99 Latency:   ${p99.toFixed(2)}ms`);
    console.log(`Error Rate:    ${(errors * 100).toFixed(2)}%`);
    console.log('========================================\n');

    return {
        stdout: JSON.stringify({
            passed: reqRate >= 4500 && p99 < 200 && errors < 0.01,
            request_rate: reqRate,
            p99_latency: p99,
            error_rate: errors
        }, null, 2)
    };
}
