# GitHub Activity Strategy

## Tools Available

Use the `gh` CLI (GitHub CLI) for all GitHub operations — both REST and GraphQL APIs.

## Identifying the Target

### Self (default)
```bash
gh api user --jq '.login'
```

### Someone else
When searching for another person's GitHub activity, the main challenge is **private profiles**. GitHub's search API often returns "The listed users cannot be searched" for users with private contribution settings.

**Resolution chain (try in order):**

1. **Confirm the account exists:**
```bash
gh api users/<username> --jq '{login, name, email, bio, company}'
```

2. **Confirm org membership** (if searching within an org):
```bash
gh api orgs/<org>/members --paginate --jq '.[].login' | grep -i <name>
```

3. **Try REST search** (works for public profiles):
```bash
gh api search/issues --method GET \
  -f q='author:<username> type:pr created:>=YYYY-MM-DD' \
  -f per_page=100 --jq '.total_count'
```

4. **If REST search fails** with 422 "users cannot be searched": use the **email-based fallback** (see below).

## REST API: Standard Queries (Public Profiles)

These work when the target has public contributions or you're searching your own activity.

### 1. Pull Requests Authored

```bash
gh api search/issues --method GET \
  -f q='author:USERNAME type:pr created:>=YYYY-MM-DD' \
  -f per_page=100 \
  --jq '.items[] | {
    title,
    repo: (.repository_url | split("/") | .[-2:] | join("/")),
    created_at,
    state,
    url: .html_url,
    body: (.body | if . then .[0:200] else "" end)
  }'
```

Also check for PRs merged in the period (created earlier but merged now):
```bash
gh api search/issues --method GET \
  -f q='author:USERNAME type:pr merged:>=YYYY-MM-DD' \
  -f per_page=100 \
  --jq '.items[] | {
    title,
    repo: (.repository_url | split("/") | .[-2:] | join("/")),
    created_at,
    state,
    url: .html_url
  }'
```

### 2. Issues Created

```bash
gh api search/issues --method GET \
  -f q='author:USERNAME type:issue created:>=YYYY-MM-DD' \
  -f per_page=100 \
  --jq '.items[] | {
    title,
    repo: (.repository_url | split("/") | .[-2:] | join("/")),
    created_at,
    state,
    url: .html_url,
    labels: [.labels[].name]
  }'
```

### 3. PRs Reviewed / Commented On

PRs where the user left reviews:
```bash
gh api search/issues --method GET \
  -f q='reviewed-by:USERNAME type:pr updated:>=YYYY-MM-DD' \
  -f per_page=100 \
  --jq '.items[] | {
    title,
    repo: (.repository_url | split("/") | .[-2:] | join("/")),
    created_at,
    state,
    url: .html_url
  }'
```

PRs where the user commented (not authored):
```bash
gh api search/issues --method GET \
  -f q='commenter:USERNAME type:pr updated:>=YYYY-MM-DD -author:USERNAME' \
  -f per_page=100 \
  --jq '.items[] | {
    title,
    repo: (.repository_url | split("/") | .[-2:] | join("/")),
    url: .html_url
  }'
```

### 4. Issues Commented On (not authored)

```bash
gh api search/issues --method GET \
  -f q='commenter:USERNAME type:issue updated:>=YYYY-MM-DD -author:USERNAME' \
  -f per_page=100 \
  --jq '.items[] | {
    title,
    repo: (.repository_url | split("/") | .[-2:] | join("/")),
    url: .html_url
  }'
```

### 5. Commits (optional, for extra detail)

If the user wants commit-level detail:
```bash
gh api search/commits --method GET \
  -f q='author:USERNAME author-date:>=YYYY-MM-DD' \
  -f per_page=100 \
  --jq '.items[] | {
    message: (.commit.message | split("\n") | .[0]),
    repo: (.repository.full_name),
    date: .commit.author.date,
    url: .html_url
  }'
```

## Private Profiles: Email-Based Commit Search

When the REST `author:USERNAME` search fails (HTTP 422), fall back to searching by email. The target's email usually comes from their Slack profile (e.g., `fulano@cloudwalk.io`).

```bash
gh api search/commits --method GET \
  -f q='author-email:EMAIL committer-date:>YYYY-MM-DD' \
  -f sort=committer-date \
  -f order=desc \
  -f per_page=50 \
  --jq '.items[] | {
    author: .commit.author.name,
    date: .commit.author.date,
    message: (.commit.message | split("\n") | .[0]),
    repo: .repository.full_name,
    sha: .sha[0:7]
  }'
```

**Important:** The commit search API can return unrelated results if the email is common or if the API doesn't filter correctly. Always validate that the `author` field matches the expected name.

### Getting repos from commits, then PRs from repos

Once you have commits, extract the unique repos:
```bash
gh api search/commits --method GET \
  -f q='author-email:EMAIL committer-date:>YYYY-MM-DD' \
  -f sort=committer-date -f order=desc -f per_page=50 \
  --jq '[.items[].repository.full_name] | unique | .[]'
```

Then for each repo, fetch PRs by the user:
```bash
for repo in org/repo1 org/repo2; do
  echo "=== $repo ==="
  gh api repos/$repo/pulls \
    --method GET -f state=all -f per_page=30 \
    --jq ".[] | select(.user.login == \"USERNAME\") | {
      title, state, number,
      created: .created_at,
      merged: .merged_at,
      url: .html_url
    }"
done
```

## GraphQL API

The GraphQL API is useful when you need data that REST doesn't expose well, or when you want to make fewer requests. Use it as a complement, not a replacement.

### User's recent contributions (public only)

```bash
gh api graphql -f query='
{
  user(login: "USERNAME") {
    contributionsCollection(from: "YYYY-MM-DDT00:00:00Z", to: "YYYY-MM-DDT23:59:59Z") {
      totalCommitContributions
      totalPullRequestContributions
      totalPullRequestReviewContributions
      totalIssueContributions
      totalRepositoryContributions
    }
  }
}'
```

**Caveat:** `contributionsCollection` only shows public contributions for other users. For private contributions, you need the email-based commit search above.

### Repos the user contributed to (org-scoped)

```bash
gh api graphql -f query='
{
  search(query: "org:ORG author:USERNAME", type: REPOSITORY, first: 20) {
    repositoryCount
    nodes {
      ... on Repository {
        nameWithOwner
        description
        updatedAt
      }
    }
  }
}'
```

### PRs by user in a specific repo (useful after discovering repos via commits)

```bash
gh api graphql -f query='
{
  search(query: "repo:ORG/REPO author:USERNAME type:pr", type: ISSUE, first: 50) {
    issueCount
    nodes {
      ... on PullRequest {
        title
        number
        state
        createdAt
        mergedAt
        url
      }
    }
  }
}'
```

### Token scope gotcha

GraphQL queries for email require `user:email` or `read:user` scopes. If you get `INSUFFICIENT_SCOPES` errors, drop the email field from the query and get it from Slack instead.

## Rate Limits

- **REST Search API**: 30 requests per minute for authenticated users.
- **GraphQL API**: 5000 points per hour. Simple queries cost 1 point each.
- **Secondary rate limits**: If you get HTTP 403 with "secondary rate limit", wait 5-10 seconds and retry. This happens when you make too many search requests in quick succession.

The standard queries use at most 6-8 calls, well within limits. If paginating heavily or iterating over many repos, add a small delay between requests (`sleep 1`).

## Output Format

```markdown
# GitHub Activity - [Date Range]

## PRs Abertos (X)
| Repo | PR | Status | Data |
|------|----|--------|------|
| org/repo-name | [feat: add feature](url) | Open | 2026-03-12 |

## PRs Mergeados (X)
| Repo | PR | Data Merge |
|------|----|-----------|
| org/repo-name | [fix: resolve issue](url) | 2026-03-12 |

## Issues Criadas (X)
| Repo | Issue | Labels | Data |
|------|-------|--------|------|
| org/repo-name | [Bug report title](url) | bug | 2026-03-12 |

## Reviews Feitos (X)
| Repo | PR | Autor |
|------|----|-------|
| org/repo-name | [fix: something](url) | someone |

## Commits (X) [se solicitado]
| Data | Repo | SHA | Mensagem |
|------|------|----|----------|
| 2026-03-11 | org/repo-name | `abc1234` | feat: add dashboard |

## Resumo
- **X PRs** abertos, **Y mergeados**
- **Z issues** criadas
- **W reviews** realizados
- Repos mais ativos: repo1, repo2, repo3
```