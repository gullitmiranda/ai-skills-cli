#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT_DIR}/bin/ai-skills"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export AI_SKILLS_HOME="${TMP_DIR}/home"
export HOME="${TMP_DIR}/user-home"
mkdir -p "${AI_SKILLS_HOME}" "${HOME}/.cursor/skills"

cat >"${AI_SKILLS_HOME}/manifest.json" <<'EOF'
{
  "version": 1,
  "agents": ["cursor"],
  "skills": {}
}
EOF

ln -s "${TMP_DIR}/missing-skill" "${HOME}/.cursor/skills/stale-skill"

doctor_output="$(${BIN} doctor 2>&1 || true)"
if [[ ${doctor_output} != *"broken symlink"* ]]; then
	printf "Doctor did not report a dangling skill symlink.\nOutput:\n%s\n" "${doctor_output}" >&2
	exit 1
fi
if [[ ${doctor_output} != *"stale-skill"* ]]; then
	printf "Doctor did not name the dangling skill.\nOutput:\n%s\n" "${doctor_output}" >&2
	exit 1
fi

printf "doctor-broken-symlink: ok\n"
