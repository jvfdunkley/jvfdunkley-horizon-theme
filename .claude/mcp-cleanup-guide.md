# MCP Cleanup Guide

This guide explains how to track and clean up Chrome DevTools MCP processes on a per-worktree basis.

## Why Per-Worktree Tracking?

- Each worktree represents a different issue/task
- Multiple agents can work concurrently without conflicts
- Tracking file gets cleaned up automatically with the worktree
- Only kills processes for your specific session, not other concurrent agents

## Quick Start

### 1. When Starting Visual Verification

After Chrome DevTools MCP starts, immediately track the processes:

```bash
# Your worktree path
worktree_path="~/Desktop/mosaic-demo-feb-2/worktrees/jvfdunkley-claude-workflow-test-issue-2-contact-form-section"

# Get PIDs of chrome-devtools-mcp processes started in last 30 seconds
pids=$(ps -eo pid,lstart,command | grep chrome-devtools-mcp | grep -v grep | \
  awk -v cutoff="$(date -v-30S '+%Y %b %d %H:%M:%S')" '$2" "$3" "$4" "$5" "$6 > cutoff {print $1}' | tr '\n' ' ')

# Create tracking file in worktree
cat > "$worktree_path/.claude-mcp-tracking.md" << EOF
# MCP Session Tracking

**MCP Instance**: chrome-1
**Session Start**: $(date '+%Y-%m-%d %H:%M:%S')
**Worktree**: $worktree_path

## Process IDs

\`\`\`
$pids
\`\`\`

## Status

- [x] In use
- [ ] Cleaned up
EOF

echo "Tracking PIDs: $pids"
```

### 2. After Visual Verification

Clean up the specific processes for your worktree:

````bash
# Your worktree path
worktree_path="~/Desktop/mosaic-demo-feb-2/worktrees/jvfdunkley-claude-workflow-test-issue-2-contact-form-section"

# Read PIDs from tracking file
pids=$(sed -n '/^```$/,/^```$/p' "$worktree_path/.claude-mcp-tracking.md" | grep -v '```' | tr '\n' ' ')

# Graceful kill
kill $pids 2>/dev/null
sleep 1

# Force kill any stubborn processes
for pid in $pids; do
    if ps -p $pid > /dev/null 2>&1; then
        echo "Force killing: $pid"
        kill -9 $pid 2>/dev/null
    fi
done

# Verify all processes are gone
ps aux | grep -E "$(echo $pids | tr ' ' '|')" | grep -v grep

# Update tracking file
sed -i '' 's/- \[ \] Cleaned up/- [x] Cleaned up/' "$worktree_path/.claude-mcp-tracking.md"
echo "Cleanup timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$worktree_path/.claude-mcp-tracking.md"
````

## Using Helper Functions

Source the helper script for convenience:

```bash
source .claude/mcp-cleanup-utils.sh

# Start tracking
mcp_track_start "$worktree_path" "chrome-1"

# Later, cleanup
mcp_cleanup "$worktree_path"
```

## Workflow Integration

### In Visual Verification Phase:

1. **Before** using Chrome DevTools MCP:

   ```bash
   # Note: MCP starts automatically when you use Chrome tools
   # Track it immediately after first use
   ```

2. **Right after** first Chrome MCP interaction:

   ```bash
   # Create tracking file with recent PIDs
   mcp_track_start "$worktree_path" "chrome-1"
   ```

3. **During** verification:
   - Use Chrome DevTools MCP normally
   - Navigate, test, verify changes

4. **After** verification complete:
   ```bash
   # Navigate to about:blank (via Chrome MCP tools)
   # Then cleanup processes
   mcp_cleanup "$worktree_path"
   ```

### In Worktree Cleanup Phase:

Before removing the worktree:

```bash
# 1. Clean up MCP processes (if not already done)
if [ -f "$worktree_path/.claude-mcp-tracking.md" ]; then
    mcp_cleanup "$worktree_path"
fi

# 2. Remove worktree
cd ~/Desktop/mosaic-demo-feb-2/jvfdunkley-claude-workflow-test
git worktree remove "$worktree_path"

# 3. Delete branch
git branch -d <branch-name>
```

## Troubleshooting

### Can't find PIDs in tracking file

The tracking file may not have been created, or PIDs weren't captured properly.

**Manual approach:**

```bash
# Find all chrome-devtools-mcp processes
ps aux | grep chrome-devtools-mcp | grep -v grep

# Identify which ones belong to your session (look at start times)
ps -eo pid,lstart,command | grep chrome-devtools-mcp | grep -v grep

# Kill specific PIDs manually
kill <pid1> <pid2> <pid3>
```

### Processes won't die

Some processes may be stubborn. Use force kill:

```bash
kill -9 <pid>
```

### Accidentally killed other agents' processes

Unfortunately, this requires being careful with PIDs. Always verify:

- Check process start times
- Only kill recent processes (within your session timeframe)
- Use the tracking file to be certain

## Best Practices

1. ✅ **Always create tracking file immediately** after first Chrome MCP use
2. ✅ **Only track recent processes** (within last 30-60 seconds)
3. ✅ **Clean up before removing worktree**
4. ✅ **Verify processes are gone** after cleanup
5. ❌ **Don't kill all chrome-devtools-mcp processes** - other agents may be using them
6. ❌ **Don't forget to create tracking file** - you'll lose track of PIDs
