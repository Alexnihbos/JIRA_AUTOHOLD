#!/bin/bash

# === Jira connection ===
BASE_URL="https://mufpm.atlassian.net"

# User & Token harus di-set via env atau langsung di sini (lebih aman via env)
JIRA_USER="${JIRA_USER:-}"   # bisa diisi secrets
JIRA_TOKEN="${JIRA_TOKEN:-}" # bisa diisi secrets

# === Filters ===
FILTERS=(
  "12987:BPI"
  "12988:ICT"
  "12835:BPS"
)
MAX_RESULTS=1000

# === Postman environment vars ===
ISSUE_KEYS="${ISSUE_KEYS:-}"          # default kosong
ISSUE_KEY="${ISSUE_KEY:-}"            # default kosong
HOLD_TRANSITION_ID="${HOLD_TRANSITION_ID:-}"  # default kosong
