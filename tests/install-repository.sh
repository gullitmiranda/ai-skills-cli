#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT_DIR}/bin/ai-skills"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export AI_SKILLS_HOME="${TMP_DIR}/home"
export HOME="${TMP_DIR}/user-home"
mkdir -p "${AI_SKILLS_HOME}" "${HOME}" "${TMP_DIR}/repo/skills/pr" "${TMP_DIR}/repo/skills/workflow"

cat >"${TMP_DIR}/repo/skills/pr/SKILL.md" <<'EOF'
---
name: pr
---
# PR
EOF

cat >"${TMP_DIR}/repo/skills/workflow/SKILL.md" <<'EOF'
---
name: workflow
---
# Workflow
EOF

git -C "${TMP_DIR}/repo" init --quiet
git -C "${TMP_DIR}/repo" remote add origin https://github.com/gullitmiranda/gullit-skills.git
git -C "${TMP_DIR}/repo" add .
git -C "${TMP_DIR}/repo" -c user.name=test -c user.email=test@example.com commit --quiet -m init

output="$("${BIN}" --agent cursor install "${TMP_DIR}/repo" 2>&1)"

[[ -L "${HOME}/.cursor/skills/pr" ]] || {
	printf 'Expected pr skill symlink to be installed.\nOutput:\n%s\n' "${output}" >&2
	exit 1
}

[[ -L "${HOME}/.cursor/skills/workflow" ]] || {
	printf 'Expected workflow skill symlink to be installed.\nOutput:\n%s\n' "${output}" >&2
	exit 1
}

manifest_ids="$(jq -r '.skills | keys[]' "${AI_SKILLS_HOME}/manifest.json")"
[[ ${manifest_ids} == *"gullitmiranda/gullit-skills/skills/pr"* ]] || {
	printf 'Expected pr skill in manifest.\nManifest IDs:\n%s\nOutput:\n%s\n' "${manifest_ids}" "${output}" >&2
	exit 1
}

[[ ${manifest_ids} == *"gullitmiranda/gullit-skills/skills/workflow"* ]] || {
	printf 'Expected workflow skill in manifest.\nManifest IDs:\n%s\nOutput:\n%s\n' "${manifest_ids}" "${output}" >&2
	exit 1
}

[[ ${output} == *"Installed 2 skill(s) from gullitmiranda/gullit-skills"* ]] || {
	printf 'Expected install summary for two skills.\nOutput:\n%s\n' "${output}" >&2
	exit 1
}

update_output="$("${BIN}" update gullitmiranda/gullit-skills --dry-run 2>&1)"
[[ ${update_output} == *"gullitmiranda/gullit-skills/skills/pr"* ]] || {
	printf 'Expected repository update to include locally installed pr skill.\nOutput:\n%s\n' "${update_output}" >&2
	exit 1
}

[[ ${update_output} == *"gullitmiranda/gullit-skills/skills/workflow"* ]] || {
	printf 'Expected repository update to include locally installed workflow skill.\nOutput:\n%s\n' "${update_output}" >&2
	exit 1
}

[[ ${update_output} == *"Updated 2 skill(s)"* ]] || {
	printf 'Expected repository update to select two local skills.\nOutput:\n%s\n' "${update_output}" >&2
	exit 1
}

printf 'install-repository: ok\n'
