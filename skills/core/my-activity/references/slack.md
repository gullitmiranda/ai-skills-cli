# Slack Search Strategy

## Tools Available

You need five Slack MCP tools. The exact tool names vary by environment — discover them from your available tools by searching for these patterns:

- **Search** (matches `slack_search_public_and_private` or similar) - Search across ALL channels (public, private, DMs, group DMs)
- **Search users** (matches `slack_search_users`) - Find users by name, email, or handle
- **Read thread** (matches `slack_read_thread`) - Read full thread replies
- **Read channel** (matches `slack_read_channel`) - Read channel history
- **Read user profile** (matches `slack_read_user_profile`) - Get user profile info

Pass the discovered tool names to subagents explicitly so they know what to call.

## Finding the Target User

### Self
The current user's Slack ID is in the tool descriptions ("Current logged in user's user_id is ...").

### Someone else
Use the **Search users** tool to find them by name or handle:
```
query: "fulano rosa"
limit: 5
```

This returns their user ID, display name, email, title, and timezone. The **user ID** (format `U0XXXXXXXXX`) is what you need for all search queries. The **email** bridges to GitHub identity.

## Search Pattern: Three Queries Per Day

For comprehensive coverage, run these three searches for each day:

### 1. Messages FROM the user
```
query: "from:<@USER_ID> on:YYYY-MM-DD"
sort: "timestamp"
sort_dir: "asc"
limit: 100
include_context: true
response_format: "detailed"
```
This catches everything the user wrote - in channels, DMs, threads.

### 2. Messages TO the user
```
query: "to:<@USER_ID> on:YYYY-MM-DD"
sort: "timestamp"
sort_dir: "asc"
limit: 100
include_context: true
response_format: "detailed"
```
This catches DMs sent to the user and direct replies.

### 3. @Mentions of the user
```
query: "<@USER_ID> on:YYYY-MM-DD"
sort: "timestamp"
sort_dir: "asc"
limit: 100
include_context: true
response_format: "detailed"
```
This catches mentions in channels and threads where the user was tagged but didn't necessarily respond.

## Pagination

Each search returns up to 100 results per page. ALWAYS paginate using the `cursor` field until no more results:

```
cursor: "value-from-previous-response"
```

Active users can have 200+ messages per day, meaning 10+ pages per search query. Don't stop early.

## Thread Expansion

After searching, identify threads worth reading in full:
- Threads with decisions or action items
- Incident discussions
- Architecture/design debates
- Anything with 5+ replies in the search context

Use `slack_read_thread` with the channel_id and message_ts from the search results:
```
channel_id: "C12345"
message_ts: "1234567890.123456"
limit: 100
response_format: "detailed"
```

## Deduplication

The three searches will have overlap (e.g., a message FROM the user that also mentions them). Deduplicate by channel + timestamp when consolidating.

## Output Format

Write the digest as markdown, grouped by channel/DM:

```markdown
# Slack Digest - [Day], [Date]

## Visao Geral
[1-2 sentence overview of the day's activity]

---

## 1. #channel-name [Tags]
**Contexto:** [What this channel/conversation is about]

**O que foi discutido:**
- [Summary of the discussion]

**O que [User] disse/fez:**
- [Specific actions, opinions, decisions]

**Decisoes/Action Items:**
- [Any decisions made or tasks assigned]

**Status:** [Resolved / Pendente / Em andamento]

---

[Repeat for each conversation]

## Resumo de Pendencias
1. **[Item]** - [context and owner]
```

## Tags

Tag each conversation for easy scanning. Derive tags from the user's actual activity and role context. Examples:
- Work categories: [Engineering], [Design], [Product], [Support], [Sales]
- Activity types: [Incidente], [Code Review], [Planning], [1:1], [Team]
- Status: [Urgente], [Bloqueado], [Em andamento]
- Custom tags based on what the user actually works on