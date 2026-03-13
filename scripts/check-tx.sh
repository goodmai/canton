#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/test_transfer.log"
LOG_FILE="$PROJECT_ROOT/logs/test_transfer.log"
JSON_API_URL="http://localhost:7575"

echo "=== Verifying Transaction Result ==="

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found at $LOG_FILE"
    exit 1
fi

# Extract the new Coin Contract ID for Alice (change)
# Log format: "New Coin CID (Bob): (CID_BOB,Some CID_ALICE)"
# We want CID_ALICE which Alice definitely sees.
CID_LINE=$(grep "New Coin CID (Bob):" "$LOG_FILE")
# Extract content between `Some ` and `)`
CID=$(echo "$CID_LINE" | sed -n 's/.*,Some \([^)]*\).*/\1/p')

if [ -z "$CID" ]; then
    echo "Error: Could not extract Alice's Change Contract ID from logs. Maybe no change?"
    # Fallback to Bob's, but it might fail visibility
    CID=$(echo "$CID_LINE" | sed -n 's/.*New Coin CID (Bob): (\([^,]*\),.*/\1/p')
fi

if [ -z "$CID" ]; then
    echo "Error: Could not extract Contract ID from logs."
    exit 1
fi

echo "Extracted Contract ID: $CID"
echo "Extracted Contract ID: $CID"

# Extract Alice Party ID
# Log format: "Alice Party ID: 'Alice::1220...'"
PARTY_LINE=$(grep "Alice Party ID:" "$LOG_FILE")
PARTY_ID=$(echo "$PARTY_LINE" | sed -n "s/.*Alice Party ID: '\([^']*\)'.*/\1/p")
echo "Using Party ID: $PARTY_ID"

if [ -z "$PARTY_ID" ]; then
    echo "Error: Could not extract Alice Party ID from logs."
    exit 1
fi
# Fetch Ledger ID - Fallback to "participant1" if detection fails
# Note: In V2 API, LedgerIdentityService might be missing.
# We will assume "participant1" or try to proceed without specific ID if possible, 
# but usually JWT requires matched ledgerId.
LEDGER_ID="participant1"
echo "Using Ledger ID (Fallback): $LEDGER_ID"

# Generate JWT
HEADER="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
PAYLOAD_JSON="{\"https://daml.com/ledger-api\":{\"ledgerId\":\"$LEDGER_ID\",\"applicationId\":\"check-tx\",\"actAs\":[\"$PARTY_ID\"]},\"exp\":1999999999}"
PAYLOAD=$(echo -n "$PAYLOAD_JSON" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
TOKEN="$HEADER.$PAYLOAD."

echo "Generated Token: $TOKEN"

echo "Querying ledger via gRPC (EventQueryService)..."
# Request format for GetEventsByContractId (V2): 
# { "contract_id": "...", "event_format": { "filters_by_party": { "party": {} }, "verbose": true } }
REQ_JSON="{\"contract_id\": \"$CID\", \"event_format\": {\"filters_by_party\": {\"$PARTY_ID\": {}}, \"verbose\": true}}"
echo "Request: $REQ_JSON"

# Execute grpcurl in container
RESPONSE=$(docker exec canton-node grpcurl -plaintext -H "Authorization: Bearer $TOKEN" -d "$REQ_JSON" localhost:5012 com.daml.ledger.api.v2.EventQueryService/GetEventsByContractId)

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "created"; then
    echo "Verification Success: Contract found via gRPC."
else
    echo "Error: Contract not found or request failed."
    echo "Detail: $RESPONSE"
    exit 1
fi
