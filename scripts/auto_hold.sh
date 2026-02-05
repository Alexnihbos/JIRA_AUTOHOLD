#!/bin/bash
set -euo pipefail

# ====== CONFIG ======
BASE_URL="https://mufpm.atlassian.net"
JIRA_USER="${JIRA_USER:-}"   # from env
JIRA_TOKEN="${JIRA_TOKEN:-}" # from env
MAX_RESULTS=1000

# Filter list: ID:Name
FILTERS=(
  "12987:BPI"
  "12988:ICT"
  "12835:BPS"
)

# ====== FUNCTIONS ======
auth_header() {
    echo -n "$JIRA_USER:$JIRA_TOKEN" | base64 | tr -d '\n'
}

get_issues() {
    local filter_id=$1
    curl -s -X POST \
      -H "Authorization: Basic $(auth_header)" \
      -H "Content-Type: application/json" \
      "$BASE_URL/rest/api/3/search/jql" \
      -d "{\"jql\":\"filter=$filter_id\",\"fields\":[\"key\"],\"maxResults\":$MAX_RESULTS}"
}

get_transitions() {
    local issue_key=$1
    curl -s -X GET \
      -H "Authorization: Basic $(auth_header)" \
      "$BASE_URL/rest/api/3/issue/$issue_key/transitions"
}

do_transition() {
    local issue_key=$1
    local transition_id=$2
    curl -s -X POST \
      -H "Authorization: Basic $(auth_header)" \
      -H "Content-Type: application/json" \
      "$BASE_URL/rest/api/3/issue/$issue_key/transitions" \
      -d "{\"transition\":{\"id\":\"$transition_id\"}}"
}

# ====== MAIN LOOP ======
for F in "${FILTERS[@]}"; do
    FILTER_ID="${F%%:*}"
    NAME="${F##*:}"
    echo "=== PROCESS $NAME ==="

    ISSUES_JSON=$(get_issues "$FILTER_ID")

    ISSUE_KEYS=$(echo "$ISSUES_JSON" | jq -r '.issues[].key // empty')
    if [ -z "$ISSUE_KEYS" ]; then
        echo "No issues found for $NAME"
        continue
    fi

    for ISSUE in $ISSUE_KEYS; do
        echo "→ $ISSUE"

        TRANS_JSON=$(get_transitions "$ISSUE")

        HOLD_ID=$(echo "$TRANS_JSON" | jq -r '
            .transitions[]?
            | select(.to.name | test("hold"; "i"))
            | select(.to.name | test("pmo"; "i") | not)
            | .id
        ' | head -n 1 || true)

        if [ -n "$HOLD_ID" ]; then
            echo "Holding $ISSUE (transition id $HOLD_ID)"
            do_transition "$ISSUE" "$HOLD_ID"
        else
            echo "No hold transition available for $ISSUE"
        fi
    done
done

echo "✅ All done!"
