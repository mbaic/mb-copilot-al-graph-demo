#!/bin/bash
# Blocks al_build after 3 attempts per chat session, for the AL delivery graph's Verify station.
# Also writes the current station, attempt count, and result to state.json, so the graph can resume correctly.
LIMIT=3
STATE_DIR="${TMPDIR:-/tmp}/mb-al-graph-demo"
mkdir -p "$STATE_DIR"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
WORKSPACE_ROOT=$(echo "$INPUT" | jq -r '.cwd // "."')

if [ "$TOOL_NAME" != "al_build" ]; then
  echo '{"hookSpecificOutput":{"permissionDecision":"allow"}}'
  exit 0
fi

COUNT_FILE="$STATE_DIR/$SESSION_ID.count"
COUNT=0
if [ -f "$COUNT_FILE" ]; then
  COUNT=$(cat "$COUNT_FILE")
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNT_FILE"

STATE_FILE="$WORKSPACE_ROOT/state.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ "$COUNT" -gt "$LIMIT" ]; then
  echo "{\"node\": \"verify\", \"result\": \"blocked\", \"attempt\": $COUNT, \"limit\": $LIMIT, \"commit\": null, \"updated\": \"$TIMESTAMP\"}" > "$STATE_FILE"
  echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Attempt limit ($LIMIT) reached. The graph stopped at Verify. Review the last error and fix it by hand.\"}}"
  exit 0
fi

echo "{\"node\": \"verify\", \"result\": \"pending\", \"attempt\": $COUNT, \"limit\": $LIMIT, \"commit\": null, \"updated\": \"$TIMESTAMP\"}" > "$STATE_FILE"
echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"allow\",\"additionalContext\":\"Attempt $COUNT of $LIMIT.\"}}"
exit 0
