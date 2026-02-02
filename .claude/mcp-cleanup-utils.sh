#!/bin/bash
# MCP Cleanup Utilities
# Helper functions for tracking and cleaning up MCP server processes per worktree

# Initialize MCP tracking for current worktree
# Usage: mcp_track_start <worktree_path> <mcp_instance_name>
mcp_track_start() {
    local worktree_path="$1"
    local mcp_instance="$2"
    local tracking_file="${worktree_path}/.claude-mcp-tracking.md"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Get recent chrome-devtools-mcp processes (started in last 30 seconds)
    local recent_pids=$(ps -eo pid,lstart,command | grep chrome-devtools-mcp | grep -v grep | \
        awk -v cutoff="$(date -v-30S '+%Y %b %d %H:%M:%S')" '$2" "$3" "$4" "$5" "$6 > cutoff {print $1}' | tr '\n' ' ')

    cat > "$tracking_file" << EOF
# MCP Session Tracking

**MCP Instance**: ${mcp_instance}
**Session Start**: ${timestamp}
**Worktree**: ${worktree_path}

## Process IDs

\`\`\`
${recent_pids}
\`\`\`

## Status

- [ ] In use
- [ ] Cleaned up
EOF

    echo "MCP tracking initialized at: ${tracking_file}"
    echo "Tracking PIDs: ${recent_pids}"
}

# Clean up MCP processes for current worktree
# Usage: mcp_cleanup <worktree_path>
mcp_cleanup() {
    local worktree_path="$1"
    local tracking_file="${worktree_path}/.claude-mcp-tracking.md"

    if [[ ! -f "$tracking_file" ]]; then
        echo "No MCP tracking file found at: ${tracking_file}"
        return 1
    fi

    # Extract PIDs from tracking file
    local pids=$(sed -n '/^```$/,/^```$/p' "$tracking_file" | grep -v '```' | tr '\n' ' ')

    if [[ -z "$pids" ]]; then
        echo "No PIDs found in tracking file"
        return 1
    fi

    echo "Killing MCP processes: ${pids}"

    # Try graceful kill first
    kill $pids 2>/dev/null
    sleep 1

    # Force kill any remaining processes
    for pid in $pids; do
        if ps -p $pid > /dev/null 2>&1; then
            echo "Force killing stubborn process: $pid"
            kill -9 $pid 2>/dev/null
        fi
    done

    # Update tracking file
    sed -i '' 's/- \[ \] In use/- [x] In use/' "$tracking_file"
    sed -i '' 's/- \[ \] Cleaned up/- [x] Cleaned up/' "$tracking_file"
    echo "Session cleanup timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$tracking_file"

    echo "MCP cleanup complete for: ${worktree_path}"
}

# Export functions
export -f mcp_track_start
export -f mcp_cleanup
