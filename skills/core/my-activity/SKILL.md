---
name: my-activity
description: >
  Generate activity digests from Slack and GitHub for the user OR for someone else.
  Summarizes what someone did, what happened around them, pending items, and decisions made.
  Use PROACTIVELY whenever the user asks things like "o que eu fiz ontem?", "resumo da semana",
  "what did I do?", "weekly digest", "activity summary", "meu resumo",
  "o que aconteceu essa semana?", "daily standup", "standup update",
  "what's been going on?", or any variation asking about their recent activity
  across communication and code. Also trigger when the user asks to track their
  week, prepare a status update, or wants to know what they missed.
  ALSO trigger when the user asks about SOMEONE ELSE's activity — e.g.,
  "o que o fulano fez?", "puxa os commits da Maria", "resumo de atividade de @handle",
  "what has <github-username> been working on?", "gera um report da atividade do X",
  or any variation asking about another person's recent work across GitHub and Slack.
  This includes generating activity reports or contribution summaries
  for any team member or GitHub account.
---

# Activity Digest

You generate comprehensive activity digests by pulling data from multiple sources (Slack, GitHub) and consolidating into a clear summary. This works for **the user themselves** or for **someone else** on the team.

## How It Works

The skill uses a **subagent-per-time-slice** strategy to handle volume. Each subagent searches one source for one time period, saves results to a file, and the main agent consolidates everything.

## Step 0: Understand the Request

### Who is the target?

Determine whether the user is asking about **themselves** or **someone else**:

- **Self**: "o que eu fiz?", "my activity", "meu resumo" -> target is the current user
- **Other person**: "o que o fulano fez?", "puxa os commits do X", "report da atividade de @Handle" -> target is someone else

If the target is someone else, you need to **resolve their identity** before anything else. See Step 2.

### Time period

Figure out what time period the user wants:
- "ontem" / "yesterday" -> previous business day
- "essa semana" / "this week" -> Monday through today
- "hoje" / "today" -> today only
- "ultimas duas semanas" / "last two weeks" -> 14 days back
- Custom ranges -> as specified

### Sources

Also figure out which sources they want. Default is **all sources** (Slack + GitHub). The user might ask for just one.

### Output format

If the user specifies an output file name (e.g., "handle_report.md"), use that. Otherwise default to `weekly_summary.md` or `daily_summary.md`.

## Step 1: Pre-approve Tool Permissions

Background subagents CANNOT request tool permissions from the user. You MUST trigger each tool once in the main context first so the user can approve.

Slack MCP tool names vary by environment (e.g. `mcp__plugin_slack_slack__slack_search_public_and_private` or `slack__slack_search_public_and_private`). Discover the actual tool names by looking at your available tools for ones matching `slack_search`, `slack_read_thread`, `slack_read_channel`, and `slack_read_user_profile`.

Make a trivial call to each Slack tool to trigger permission approval:
- **Search** tool (any simple query)
- **Read thread** tool (dummy channel/ts - will error, that's fine)
- **Read channel** tool (user's own ID as channel_id, limit 1)
- **Read user profile** tool (user's own ID)

For GitHub, test with: `gh auth status`

Wait for all approvals before spawning subagents.

## Step 2: Gather Target Identity

You need to know who you're researching. The process differs for self vs. other.

### If target is self (default)

- **Slack user ID**: shown in the tool descriptions as "Current logged in user's user_id is ..."
- **Slack display name**: call the Slack read user profile tool with their ID
- **GitHub username**: run `gh api user --jq '.login'`
- **Their role/context**: check conversation history and memory

### If target is someone else

You need to **resolve their identity** across both platforms. This is the trickiest part because people use different names on Slack vs GitHub, profiles may be private, and search APIs don't always cooperate.

**Resolution strategy (try in order):**

1. **Slack first** (usually easier): Search Slack users by name/handle using the Slack search users tool. This gives you their display name, email, and user ID.
2. **Email bridges the gap**: The Slack profile often has a corporate email (e.g., `fulano@cloudwalk.io`). This email is the key to finding their GitHub activity even with private profiles.
3. **GitHub user lookup**: Try `gh api users/<github-username>` to confirm the account exists. Check org membership: `gh api orgs/<org>/members --paginate --jq '.[].login' | grep -i <name>`.
4. **If GitHub profile is private**: The REST search API (`search/issues`, `search/commits`) may fail with "users cannot be searched" errors for private profiles. Don't give up — fall back to **email-based commit search** and **GraphQL API**. See `references/github.md` for the full fallback chain.

**Identity fields to collect:**

| Field | How to get | Why it matters |
|-------|-----------|---------------|
| Slack user ID | Slack user search | Required for all Slack queries |
| Display name | Slack profile | Helps identify them in discussions |
| Email | Slack profile | Bridges Slack↔GitHub for private profiles |
| GitHub username | Org member list / user search | Primary GitHub search key |
| Role/title | Slack profile + conversation context | Context for subagents |

Pass ALL of these to subagents so they can search effectively.

This context is critical for subagents to understand what they're looking at and produce good summaries.

## Step 3: Spawn Source-Specific Subagents

Read the relevant reference files before spawning agents:
- `references/slack.md` for Slack search strategy
- `references/github.md` for GitHub activity patterns

### Time Slicing Strategy

| Period | Slack Agents | GitHub Agents |
|--------|-------------|---------------|
| 1 day | 1 agent | 1 agent |
| 2-3 days | 1 per day | 1 total |
| 4-7 days (week) | 1 per day | 1 total |
| 7+ days | 1 per day (cap at 7) | 1 total |

Launch ALL agents in parallel using `run_in_background: true`.

### Subagent Prompt Template

Every subagent prompt MUST include:
1. **User identity**: Slack ID, GitHub username, display name
2. **User role context**: what they do, their team, common topics
3. **Time range**: exact dates with `on:YYYY-MM-DD` for Slack, date ranges for GitHub
4. **Tool names**: explicit tool names they should use (discover the actual MCP tool names from your available tools and pass them to subagents)
5. **Output path**: where to save the file
6. **Output format**: Portuguese (BR), grouped by conversation/repo, with tags

### Output Directory

Save all files to the working directory:
- `slack_<day>.md` for daily Slack digests
- `github_activity.md` for GitHub activity
- `weekly_summary.md` or `daily_summary.md` for the consolidated report

## Step 4: Handle Subagent Completion

As agents complete:
1. If an agent failed (permission denied, error), resume it or retry
2. If an agent couldn't write its file, read its output and write the file yourself
3. Track completion - don't consolidate until all agents finish

## Step 5: Consolidate

Read `references/consolidation.md` for the consolidation format.

Read ALL output files from the subagents, then produce a single consolidated summary. The consolidation should:
1. Cross-reference Slack discussions with GitHub PRs/issues
2. Group by theme/project, not by source
3. Highlight decisions, action items, blockers
4. Flag things left unresolved
5. Note patterns (recurring topics, escalations, etc.)

Present the summary directly to the user AND save it to a file.

## Important Learnings

These are battle-tested patterns from real usage:

1. **Permission pre-approval is non-negotiable.** Background agents silently fail without it. Make a trivial call to each tool first in the main context.
2. **Pagination matters.** Active users generate 200+ messages/day. Always paginate until exhausted.
3. **Context makes or breaks quality.** An agent that knows the user's role and responsibilities produces vastly better summaries than one that doesn't.
4. **Three Slack searches per day** cover everything: `from:<@USER>`, `to:<@USER>`, `<@USER>` (mentions).
5. **Read important threads fully.** Surface-level search results miss the meat of decisions.
6. **Subagents can't write files sometimes.** Be ready to resume them or write files yourself from their output.

### Third-party specific learnings

7. **Private GitHub profiles break REST search.** The `author:USERNAME` qualifier returns HTTP 422 for private profiles. Fall back to `author-email:EMAIL` on the commit search API. The email usually comes from the Slack profile.
8. **Commit search can return garbage.** The `author-email` search sometimes returns unrelated commits. Always validate the author name in results matches the target.
9. **GitHub secondary rate limits hit fast.** When iterating over multiple search queries, you'll hit "secondary rate limit" (HTTP 403) within ~10 requests. Add `sleep 3-5` between calls.
10. **GraphQL `contributionsCollection` only shows public data for other users.** Don't rely on it for private profiles — it will show zero contributions. Use REST email-based search instead.
11. **Slack search for other people works well.** `from:<@USER_ID>` reliably returns their messages. The `to:` and mention searches are less useful for third-party reports since you care more about what they said than what was said to them.
12. **DMs between you and the target are visible.** Slack search returns DMs the current user has with the target. This often contains the richest context (plans, frustrations, real opinions).
13. **For third-party reports, do Slack search from the main context.** Subagents can't get Slack tool permissions approved. If you must use subagents, pre-approve ALL Slack tools first. Alternatively, run Slack searches directly from the main context (one search per day, paginating) — this is slower but more reliable.