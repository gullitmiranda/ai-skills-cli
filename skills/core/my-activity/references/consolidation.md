# Consolidation Strategy

## Reading Source Files

After all subagents complete, read every output file they produced:
- `slack_*.md` files (one per day)
- `github_activity.md` (one total)

## Cross-Referencing

Look for connections between sources:
- PRs mentioned in Slack discussions -> link them
- Issues created that relate to Slack threads (incidents, vulnerabilities, requests)
- Reviews done on PRs that were discussed in channels
- Repos that appear in both Slack and GitHub activity

## Consolidation Structure

The final summary should be organized by THEME, not by source. Group related Slack conversations and GitHub activity together.

```markdown
# Activity Digest - [Period]

## Numeros
- **X mensagens** no Slack (enviadas + recebidas)
- **Y conversas** distintas
- **Z PRs** (abertos: A, mergeados: B)
- **W issues** criadas
- **V reviews** realizados

---

## Grandes Temas

### 1. [Theme Name]
**Resumo:** [2-3 sentences]

**Slack:**
- [Channel/DM]: [what happened]
- [Channel/DM]: [what happened]

**GitHub:**
- [PR/Issue]: [link and context]

**Status:** [Resolved / Em andamento / Pendente]
**Action Items:** [if any]

---

[Repeat for each major theme]

## O Que Voce Fez (Highlights)

### [Category 1 - e.g., Security]
- [Bullet point of action taken]

### [Category 2 - e.g., Engineering]
- [Bullet point of action taken]

### [Category 3 - e.g., Management]
- [Bullet point of action taken]

## Pendencias

### Alta Prioridade
1. **[Item]** - [context, owner, deadline if known]

### Media Prioridade
2. **[Item]** - [context]

### Baixa Prioridade
3. **[Item]** - [context]

## Padroes e Observacoes
- [Recurring themes, escalations, risks worth noting]
```

## Tone and Language

- Write in Portuguese (BR) by default, unless the user asks otherwise
- Be direct and factual - this is a work report, not a narrative
- Use tags for scannability: [Security], [Incidente], [Team], etc.
- Don't editorialize - report what happened, let the user draw conclusions
- Include links where available (PR URLs, issue URLs)

## Single-Day Digests

For "o que eu fiz ontem?" style requests, the format is simpler:

```markdown
# O que voce fez em [Date]

## Slack ([X conversations])
[Bullet list of conversations and what you did in each]

## GitHub ([Y activities])
- PRs: [list]
- Issues: [list]
- Reviews: [list]

## Pendencias do dia
1. [Item]
```

Keep it concise for single-day requests. The user wants a quick picture, not an essay.

## Third-Party Reports

When the report is about someone else (not the current user), the format shifts from "o que voce fez" to a profile-style report. The structure should be:

```markdown
# [Report Name] - [Person Name] (@handle)

**Periodo:** [Start Date] - [End Date]
**GitHub:** [github-username] | **Email:** [email] | **Slack:** @[display-name]
**Cargo:** [Title from Slack profile]

---

## Resumo Executivo

[2-3 sentences summarizing the person's focus areas and key accomplishments in the period]

1. **[Project/Theme 1]** - [One-line description]
2. **[Project/Theme 2]** - [One-line description]
[...]

---

## Metricas

| Metrica | Valor |
|---|---|
| Commits (GitHub) | X |
| PRs abertos | X |
| PRs mergeados | X |
| Repos ativos | X (list) |
| Canais Slack ativos | ~X canais |
| Dias com atividade Slack | X de Y dias |

---

## Timeline Diaria (GitHub + Slack)

### [Date] ([Day of week])

**GitHub:**
- [Commits/PRs for the day]

**Slack:**
- `#channel-name` - [Summary of what they discussed/did]
- DMs - [Summary if relevant, skip trivial chat]

---

[Repeat for each day with activity]

---

## Projetos Detalhados (GitHub)

### 1. [Project Name] (`org/repo`)
**O que e:** [Description]
**Destaques do Slack:** [Context from Slack that doesn't appear in GitHub]

[Repeat for each project]

---

## Pull Requests

### Mergeados (X)
| Repo | PR | Data |
|------|----|------|
| org/repo | [title](url) | YYYY-MM-DD |

### Abertos (X)
| Repo | PR | Data | Status |
|------|----|------|--------|
| org/repo | [title](url) | YYYY-MM-DD | Em review |

---

## Canais Slack com Participacao

| Canal | Tipo | Topicos |
|---|---|---|
| #channel | Time/Org/Vuln/Pentest | Brief description |

---

## Observacoes
- [Notable patterns, absences, highlights]
- [Data limitations (private profile, missing repos, etc.)]

---

*Gerado em [date] via GitHub API + Slack Search API*
```

### Key differences from self-reports:
- **Header includes identity info** (GitHub, email, Slack, role) — the reader may not know who this person is
- **Daily timeline merges both sources** — instead of separate Slack/GitHub sections, combine per-day for a chronological narrative
- **Detailed project sections** cross-reference GitHub and Slack — context from Slack fills gaps that GitHub alone can't show
- **Channel participation table** — shows breadth of engagement across the org
- **Data limitation notes** — always mention if the profile was private, if you used email fallback, etc.