# Claude Workflow

## Planning Phase (REQUIRED)

When assigned an issue or mentioned with @claude:

1. Analyze the issue context, problem, and goals
## Tool Usage Best Practices
- **Sequential commands**: Always use separate Bash tool calls instead of chaining with `&&` or `;
- **Background tasks**: Use the `TaskOutput` tool to check output from background tasks
2. Do WebSearch research using Shopify documentation ONLY (with shopify.dev or shopify.com)
3. Before implementing any new feature, section, or component:

**CRITICAL: Evaluate Extension vs New Creation**:

- **ALWAYS prioritize extending existing sections over creating new ones**
- Even when the user says "create a new section", first check if extending an existing section makes more sense
- Ask yourself: "Does an existing section already have 70%+ of this functionality?"
- If yes, propose extending it instead of creating a new one

**Search for existing implementations**:

- Use Grep to search for similar functionality in `sections/` and `snippets/`
- Look for sections with similar features (e.g., search "animation", "rotating", "carousel")
- Example: `grep -r "rotation_speed" sections/` to find animation patterns
- **IMPORTANT**: After finding candidates with Grep, READ THE COMPLETE FILES (not just snippets)

**Specific Search Patterns to Use**:

- For schema settings: `grep -A 15 '"id": "setting_name"' sections/*.liquid`
- For translation usage: `grep -r "t:options.option_name" sections/*.liquid`
- For CSS class patterns: `grep -l "class-name" sections/*.liquid`
- For section width implementation: `grep -A 5 "section--page-width\|section--full-width" sections/*.liquid`
- Always examine 2-3 COMPLETE examples, not just snippets, to understand full implementation patterns

**Examine reference implementations**:

- **Read complete section files** (using Read tool) for 2-3 candidates
- Study their schema structure, block definitions, and settings organization
- Note patterns like parent-child settings relationships
- **Evaluate**: Can I add the missing features to an existing section?
- **Consider**: Would extending this section confuse existing users or break backward compatibility?

**Check for reusable components**:

- Before creating custom blocks, check if `@theme` or `@app` blocks provide the functionality
- Search snippets for reusable components (e.g., `snippets/button.liquid`)
- Prefer rendering existing snippets over duplicating code

**Validate translation infrastructure**:

- Search `locales/en.default.schema.json` for existing translation keys
- Reuse existing keys when possible (e.g., "t:settings.alignment" vs creating new keys)

3. Create a detailed implementation plan and present it **both**:
   - **In the conversation** - with full details
   - **As a GitHub issue comment** - same content (without approval request)

   Include:
   - Summary of the problem
   - Proposed approach
   - Files to be modified/created
   - Testing strategy
   - Potential risks or edge cases

4. End your conversation message with: "Reply 'approve' to proceed with implementation"
5. **STOP and wait for approval in chat. Do NOT implement until approved.**

## Implementation Phase

After receiving `@claude approve`:

1. Implement the planned changes
2. Follow existing code patterns and conventions
3. Follow Prettier formatting (configured in `.prettierrc`) - runs automatically on commit
4. Add/update tests as needed

## Verification Phase (REQUIRED before PR)

Before committing:

### Automated Checks

These checks run automatically via pre-commit hooks, but can also be run manually:

1. Run formatting: `npm run format` (or `npm run format:check` to verify without writing)
2. Run linting: `npm run lint` (or `npm run lint:fix` to auto-fix)
3. Run Shopify theme check: `npm run theme:check` (includes accessibility rules via `.theme-check.yml`)
4. Run build: `npm run build` (requires `npm install` first)
5. Lighthouse performance check: Runs in CI/CD via GitHub Actions on PRs (can also be triggered manually with a preview URL)

### Visual Verification (MANDATORY - DO NOT SKIP)

**CRITICAL: You MUST complete visual verification before creating a PR. Do NOT proceed without it.**

1. Check if a dev server is already running:
   - Look for a running `shopify theme dev` process, or
   - Check if port 9292 is in use: `lsof -i :9292`
2. **If no dev server is running, run `npm run shopify:dev` within the worktree directory and get the preview URL yourself. If you need a password, prompt the user**

   **DO NOT proceed to PR creation. WAIT for the user to provide the preview URL.**

3. Once you have the preview URL, use Chrome DevTools MCP to:
   - **Track MCP usage**: Create `.claude-mcp-tracking.md` in the worktree with PIDs of chrome-devtools-mcp processes
   - Navigate to the preview link
   - Add the relevant section/component via theme customizer
   - Visually verify the changes work as expected
   - Test different settings/configurations
4. If visual issues are found, attempt to fix (up to 3 attempts)
5. After verification is complete:
   - Navigate to `about:blank` to release page resources
   - **Clean up MCP processes**: Kill only the processes tracked in `.claude-mcp-tracking.md`
   - Do NOT stop the dev server (it may be shared with other sessions)

### Failure Handling

If any check fails (automated or visual):

1. Attempt to fix the issue (up to 3 attempts)
2. If still failing after 3 attempts:
   - Commit what you have
   - Document in the PR what failed and what fixes were attempted
   - Include screenshots if visual verification failed
   - Let the human review and address during PR review

**Only proceed with commit/PR after visual verification is complete or failure handling is done.**

## PR Creation

After verification passes:

1. Commit with a clear message referencing the issue
2. Push to a feature branch
3. Create a PR using the PR template format in this repo (from `.github/pull_request_template.md`):

```markdown
## Description

- [Describe what changes are included in this pull request]

## Related ticket

- [Link to GitHub issue or "N/A" if none]

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Additional Notes

- [Any additional context, test results, or comments]
```

When creating PRs, fill in each section appropriately based on the changes made.

## Worktree Cleanup (REQUIRED after PR)

After the PR is created, clean up the worktree:

1. **Clean up MCP processes** (if Chrome DevTools MCP was used):
   - Read PIDs from `<worktree-path>/.claude-mcp-tracking.md`
   - Kill those specific processes: `kill <pids>`
   - Force kill if needed: `kill -9 <pids>`
   - Verify processes are gone: `ps aux | grep <pid>`
2. Note the current worktree path and branch name
3. Change directory back to the main repository (parent of the worktree)
4. Remove the worktree: `git worktree remove <worktree-path>`
5. Delete the local branch: `git branch -d <branch-name>`

### MCP Cleanup Helper

A helper script is available at `.claude/mcp-cleanup-utils.sh` with functions:

- `mcp_track_start <worktree_path> <mcp_instance>` - Initialize tracking
- `mcp_cleanup <worktree_path>` - Clean up tracked processes

**Manual MCP Tracking Example:**

```bash
# When starting Chrome MCP in worktree
worktree_path="~/worktrees/repo-issue-2"
pids=$(ps -eo pid,lstart,command | grep chrome-devtools-mcp | grep -v grep | \
  awk -v cutoff="$(date -v-30S '+%Y %b %d %H:%M:%S')" '$2" "$3" "$4" "$5" "$6 > cutoff {print $1}')

# Save to tracking file
cat > "$worktree_path/.claude-mcp-tracking.md" << EOF
# MCP Session Tracking
**Session Start**: $(date '+%Y-%m-%d %H:%M:%S')
**PIDs**: $pids
EOF

# When done, kill processes
kill $pids
# Force kill if needed: kill -9 $pids
```

# Tool Usage Best Practices

- **Background tasks**: Use the `TaskOutput` tool to check output from background tasks (like `npm run shopify:dev`). Do NOT use `sleep && cat` bash commands to read task output files.

# Code Standards

See .claude/code-standards.md for coding conventions.

# Architecture

See .claude/architecture.md for system design context.
