import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Metrics
const errorRate = new Rate('errors');

// Config
const BASE_URL = __ENV.BASE_URL || 'http://localhost:9080';
const API_KEY = __ENV.API_KEY || 'poc-audit-api-key-2024';

export const options = {
  stages: [
    { duration: '30s', target: 100 },   // Ramp up to 100 VUs
    { duration: '1m', target: 500 },    // Ramp up to 500 VUs
    { duration: '2m', target: 1000 },   // Ramp up to 1000 VUs
    { duration: '2m', target: 1000 },   // Stay at 1000 VUs
    { duration: '30s', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(99)<200'], // 99th percentile < 200ms
    errors: ['rate<0.01'],            // Error rate < 1%
  },
};

const singleEventPayload = JSON.stringify({
  actor: { id: 'user-' + Math.random().toString(36).substr(2, 9), type: 'user' },
  action: { name: 'load.test.event' },
  resource: { type: 'test', id: 'resource-' + Math.random().toString(36).substr(2, 9) },
});

export default function () {
  const headers = {
    'Content-Type': 'application/json',
    'X-API-Key': API_KEY,
  };

  // Single event endpoint
  const response = http.post(`${BASE_URL}/v1/events`, singleEventPayload, { headers });

  const success = check(response, {
    'status is 202': (r) => r.status === 202,
    'has event_id': (r) => JSON.parse(r.body).event_id !== undefined,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });

  errorRate.add(!success);
  sleep(0.1); // 100ms between requests per VU
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, opts) {
  const metrics = data.metrics;
  const checks = data.root_group.checks;
  
  let summary = '\n=== LOAD TEST SUMMARY ===\n\n';
  summary += `Total Requests: ${metrics.http_reqs.values.count}\n`;
  summary += `Request Rate: ${metrics.http_reqs.values.rate.toFixed(2)} req/s\n`;
  summary += `Duration p50: ${metrics.http_req_duration.values.med.toFixed(2)}ms\n`;
  summary += `Duration p95: ${metrics.http_req_duration.values['p(95)'].toFixed(2)}ms\n`;
  summary += `Duration p99: ${metrics.http_req_duration.values['p(99)'].toFixed(2)}ms\n`;
  summary += `Error Rate: ${(metrics.errors.values.rate * 100).toFixed(2)}%\n`;
  
  return summary;
}
