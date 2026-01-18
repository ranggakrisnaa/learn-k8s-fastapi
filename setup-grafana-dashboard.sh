#!/bin/bash
set -e

GRAFANA_URL="http://localhost:3000"
GRAFANA_API_KEY="glsa_SAjgkSvslFYrfxA1Un12XptzqGHEHYfc_b9f4314e"
PROM_UID="PBFA97CFB590B2093"

echo "Creating Grafana Dashboard..."

DASHBOARD_JSON=$(cat <<EOF
{
  "dashboard": {
    "id": null,
    "uid": "fastapi-metrics",
    "title": "FastAPI – Service Metrics",
    "timezone": "browser",
    "schemaVersion": 38,
    "version": 1,
    "refresh": "10s",
    "tags": ["fastapi", "api", "kubernetes"],
    "panels": [

      {
        "type": "stat",
        "title": "Requests / min",
        "gridPos": { "x": 0, "y": 0, "w": 4, "h": 6 },
        "targets": [
          {
            "expr": "sum(rate(fastapi_requests_total[1m])) * 60",
            "refId": "A",
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          }
        ],
        "options": {
          "colorMode": "background",
          "reduceOptions": { "calcs": ["last"] }
        }
      },

      {
        "type": "stat",
        "title": "Latency p95 (ms)",
        "gridPos": { "x": 4, "y": 0, "w": 4, "h": 6 },
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum by (le) (rate(fastapi_request_duration_seconds_bucket[5m]))) * 1000",
            "refId": "A",
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          }
        ],
        "options": {
          "colorMode": "background",
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 300 },
              { "color": "red", "value": 800 }
            ]
          }
        }
      },

      {
        "type": "stat",
        "title": "Error Rate %",
        "gridPos": { "x": 8, "y": 0, "w": 4, "h": 6 },
        "targets": [
          {
            "expr": "(sum(rate(fastapi_requests_total{status=~\"5..\"}[5m])) or vector(0)) / sum(rate(fastapi_requests_total[5m])) * 100",
            "refId": "A",
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          }
        ],
        "options": {
          "colorMode": "background",
          "unit": "percent",
          "thresholds": {
            "steps": [
              { "color": "green", "value": null },
              { "color": "yellow", "value": 1 },
              { "color": "red", "value": 5 }
            ]
          },
          "reduceOptions": { "calcs": ["last"] }
        }
      },

      {
        "type": "timeseries",
        "title": "Requests per second",
        "gridPos": { "x": 0, "y": 6, "w": 12, "h": 8 },
        "targets": [
          {
            "expr": "sum by (method) (rate(fastapi_requests_total[1m]))",
            "legendFormat": "{{method}}",
            "refId": "A",
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          }
        ]
      },

      {
        "type": "timeseries",
        "title": "Latency by quantile",
        "gridPos": { "x": 0, "y": 14, "w": 12, "h": 8 },
        "targets": [
          {
            "expr": "histogram_quantile(0.5, sum by (le) (rate(fastapi_request_duration_seconds_bucket[5m]))) * 1000",
            "legendFormat": "p50",
            "refId": "A",
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          },
          {
            "expr": "histogram_quantile(0.95, sum by (le) (rate(fastapi_request_duration_seconds_bucket[5m]))) * 1000",
            "legendFormat": "p95",
            "refId": "B",
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          },
          {
            "expr": "histogram_quantile(0.99, sum by (le) (rate(fastapi_request_duration_seconds_bucket[5m]))) * 1000",
            "legendFormat": "p99",
            "refId": "C",
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "ms"
          }
        }
      },

      {
        "type": "table",
        "title": "Top Endpoints – Detail",
        "gridPos": { "x": 0, "y": 22, "w": 12, "h": 9 },
        "targets": [
          {
            "refId": "A",
            "expr": "sum by (endpoint, method) (rate(fastapi_requests_total[1m]))",
            "format": "table",
            "instant": true,
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          },
          {
            "refId": "B",
            "expr": "(sum by (endpoint, method) (rate(fastapi_requests_total{status=~\"5..\"}[1m])) or (sum by (endpoint, method) (rate(fastapi_requests_total[1m])) * 0))",
            "format": "table",
            "instant": true,
            "datasource": { "type": "prometheus", "uid": "$PROM_UID" }
          }
        ],
        "transformations": [
          {
            "id": "merge"
          },
          {
            "id": "organize",
            "options": {
              "excludeByName": {
                "Time": true,
                "__name__": true,
                "job": true,
                "instance": true
              },
              "renameByName": {
                "Value #A": "rps",
                "Value #B": "errors_per_sec"
              }
            }
          },
          {
            "id": "calculateField",
            "options": {
              "mode": "binary",
              "binary": {
                "left": "errors_per_sec",
                "operator": "/",
                "right": "rps"
              },
              "replaceFields": false,
              "alias": "error_rate"
            }
          },
          {
            "id": "sortBy",
            "options": {
              "sort": [
                {
                  "field": "rps",
                  "desc": true
                }
              ]
            }
          }
        ],
        "options": {
          "showHeader": true,
          "footer": {
            "show": false
          }
        },
        "fieldConfig": {
          "defaults": {
            "custom": {
              "align": "auto",
              "displayMode": "auto"
            }
          },
          "overrides": [
            {
              "matcher": { "id": "byName", "options": "rps" },
              "properties": [
                { "id": "unit", "value": "reqps" },
                { "id": "decimals", "value": 3 },
                { "id": "custom.displayMode", "value": "lcd-gauge" },
                { "id": "custom.width", "value": 150 }
              ]
            },
            {
              "matcher": { "id": "byName", "options": "errors_per_sec" },
              "properties": [
                { "id": "unit", "value": "reqps" },
                { "id": "decimals", "value": 4 },
                { "id": "custom.width", "value": 120 }
              ]
            },
            {
              "matcher": { "id": "byName", "options": "error_rate" },
              "properties": [
                { "id": "unit", "value": "percentunit" },
                { "id": "decimals", "value": 2 },
                { "id": "custom.displayMode", "value": "color-background" },
                { "id": "custom.width", "value": 100 },
                {
                  "id": "thresholds",
                  "value": {
                    "mode": "absolute",
                    "steps": [
                      { "color": "green", "value": null },
                      { "color": "yellow", "value": 0.01 },
                      { "color": "orange", "value": 0.03 },
                      { "color": "red", "value": 0.05 }
                    ]
                  }
                }
              ]
            },
            {
              "matcher": { "id": "byName", "options": "endpoint" },
              "properties": [
                { "id": "custom.width", "value": 300 }
              ]
            },
            {
              "matcher": { "id": "byName", "options": "method" },
              "properties": [
                { "id": "custom.width", "value": 80 }
              ]
            }
          ]
        }
      }

    ]
  },
  "overwrite": true
}
EOF
)


curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
  -H "Authorization: Bearer $GRAFANA_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$DASHBOARD_JSON"

echo "✓ Dashboard created"