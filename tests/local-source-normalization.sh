#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT_DIR}/bin/ai-skills"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export AI_SKILLS_HOME="${TMP_DIR}/home"
export HOME="${TMP_DIR}/user-home"
mkdir -p "${AI_SKILLS_HOME}" "${HOME}"

REPO_DIR="${TMP_DIR}/source-repo"
mkdir -p "${REPO_DIR}/skills/example"
cat >"${REPO_DIR}/skills/example/SKILL.md" <<'EOF'
---
name: example
---
# Example
EOF

git -C "${REPO_DIR}" init --quiet
git -C "${REPO_DIR}" add .
git -C "${REPO_DIR}" -c user.name=test -c user.email=test@example.com commit --quiet -m init

output="$(${BIN} --agent cursor add "local:${REPO_DIR}" 2>&1)"
[[ -L "${HOME}/.cursor/skills/example" ]] || {
	printf "Expected local skill symlink.\nOutput:\n%s\n" "${output}" >&2
	exit 1
}
link_target="$(readlink "${HOME}/.cursor/skills/example")"
[[ ${link_target} == "${REPO_DIR}/skills/example" ]] || {
	printf "Expected direct-link installation.\nOutput:\n%s\n" "${output}" >&2
	exit 1
}

mkdir -p "${AI_SKILLS_HOME}/profiles"
cat >"${AI_SKILLS_HOME}/config.json" <<EOF
{
  "version": 1,
  "default_profile": "work",
  "profiles": {
    "work": {
      "repos_dir": "${TMP_DIR}/repos"
    }
  }
}
EOF
cat >"${AI_SKILLS_HOME}/profiles/work.yaml" <<EOF
version: 1
profile: work
defaults:
  backend: legacy
  scope: global
  agents:
    - cursor
    - claude
skills:
  - source: ${REPO_DIR}
EOF

sync_output="$(${BIN} sync --profile work --dry-run 2>&1)"
if [[ ${sync_output} == *"Unknown backend"* ]]; then
	printf "Sync misparsed an empty ref field.\nOutput:\n%s\n" "${sync_output}" >&2
	exit 1
fi

sync_output="$(${BIN} sync --profile work 2>&1)"
if ! jq -e --arg source "local:${REPO_DIR}" '
	any(.skills[]; .source == $source and
		((.agents | index("cursor")) != null) and
		((.agents | index("claude")) != null))
' "${AI_SKILLS_HOME}/manifest.json" >/dev/null; then
	printf "Manifest did not preserve all agents for a local source.\nOutput:\n%s\n" "${sync_output}" >&2
	exit 1
fi

[[ -L "${HOME}/.claude/skills/example" ]] || {
	printf "Expected local skill symlink for Claude.\nOutput:\n%s\n" "${sync_output}" >&2
	exit 1
}

doctor_output="$(${BIN} doctor 2>&1 || true)"
if [[ ${doctor_output} == *"Installed source not represented in profile specs: local:${REPO_DIR}"* ]]; then
	printf "Doctor reported false local-source drift.\nOutput:\n%s\n" "${doctor_output}" >&2
	exit 1
fi

printf "local-source-normalization: ok\n"
