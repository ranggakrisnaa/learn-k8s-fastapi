#!/bin/bash

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin123"

echo "Getting Grafana datasources..."
echo ""

# Login
LOGIN=$(curl -s -X POST "$GRAFANA_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"user\":\"$GRAFANA_USER\",\"password\":\"$GRAFANA_PASSWORD\"}")

TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "✗ Login failed"
    exit 1
fi

# Get datasources
echo "Datasources:"
curl -s "$GRAFANA_URL/api/datasources" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for ds in data:
    print(f\"Name: {ds['name']}\")
    print(f\"  Type: {ds['type']}\")
    print(f\"  UID: {ds['uid']}\")
    print(f\"  URL: {ds['url']}\")
    print()
" 2>/dev/null || echo "Error parsing response"
