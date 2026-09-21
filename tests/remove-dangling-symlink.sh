#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT_DIR}/bin/ai-skills"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export AI_SKILLS_HOME="${TMP_DIR}/home"
export HOME="${TMP_DIR}/user-home"
mkdir -p "${AI_SKILLS_HOME}" "${HOME}/.cursor/skills"

sid="example/skills/skills/stale-skill"
cat >"${AI_SKILLS_HOME}/manifest.json" <<EOF
{
  "version": 1,
  "agents": ["cursor"],
  "skills": {
    "${sid}": {
      "source": "github.com/example/skills",
      "path": "skills/stale-skill",
      "ref": "main",
      "agents": ["cursor"]
    }
  }
}
EOF

ln -s "${TMP_DIR}/missing-skill" "${HOME}/.cursor/skills/stale-skill"
[[ -L ${HOME}/.cursor/skills/stale-skill ]] || {
	printf "Setup failed: expected dangling symlink.\n" >&2
	exit 1
}

remove_output="$(${BIN} remove "${sid}" 2>&1)"
if [[ -L ${HOME}/.cursor/skills/stale-skill || -e ${HOME}/.cursor/skills/stale-skill ]]; then
	printf "Remove left a dangling skill symlink in place.\nOutput:\n%s\n" "${remove_output}" >&2
	exit 1
fi

if jq -e --arg sid "${sid}" '.skills[$sid]' "${AI_SKILLS_HOME}/manifest.json" >/dev/null; then
	printf "Remove left the stale skill in the manifest.\nOutput:\n%s\n" "${remove_output}" >&2
	exit 1
fi

printf "remove-dangling-symlink: ok\n"
