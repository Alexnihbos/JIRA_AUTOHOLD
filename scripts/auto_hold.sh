#!/bin/bash
set -e

source scripts/config.sh
AUTH=$(echo -n "$JIRA_USER:$JIRA_TOKEN" | base64)

for F in "${FILTERS[@]}"; do
  FILTER_ID="${F%%:*}"
  NAME="${F##*:}"
  echo "=== PROCESS $NAME ==="

  ISSUES=$(curl -s -X POST \
    -H "Authorization: Basic $AUTH" \
    -H "Content-Type: application/json" \
    "$BASE_URL/rest/api/3/search/jql" \
    -d "{\"jql\":\"filter=$FILTER_ID\",\"fields\":[\"key\"],\"maxResults\":$MAX_RESULTS}")

  echo "$ISSUES" | jq -r '.issues[].key' | while read ISSUE; do
    echo "→ $ISSUE"

    TRANS=$(curl -s \
      -H "Authorization: Basic $AUTH" \
      "$BASE_URL/rest/api/3/issue/$ISSUE/transitions")

    HOLD_ID=$(echo "$TRANS" | jq -r '
      .transitions[]
      | select(.to.name | test("hold"; "i"))
      | select(.to.name | test("pmo"; "i") | not)
      | .id
    ' | head -n 1)

    if [ -n "$HOLD_ID" ]; then
      curl -s -X POST \
        -H "Authorization: Basic $AUTH" \
        -H "Content-Type: application/json" \
        "$BASE_URL/rest/api/3/issue/$ISSUE/transitions" \
        -d "{\"transition\":{\"id\":\"$HOLD_ID\"}}"
    fi
  done
done