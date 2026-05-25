#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT_DIR}/bin/ai-skills"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export AI_SKILLS_HOME="${TMP_DIR}/home"
export HOME="${TMP_DIR}/user-home"
mkdir -p "${AI_SKILLS_HOME}" "${HOME}"

make_skill_repo() {
	local repo_dir="$1"
	mkdir -p "${repo_dir}/skills/pr" "${repo_dir}/skills/workflow"
	printf '%s\n' 'name: pr' >"${repo_dir}/skills/pr/SKILL.md"
	printf '%s\n' 'name: workflow' >"${repo_dir}/skills/workflow/SKILL.md"
}

write_manifest() {
	local skill_repo="$1"
	mkdir -p "${AI_SKILLS_HOME}"
	cat >"${AI_SKILLS_HOME}/manifest.json" <<JSON
{
  "version": 1,
  "agents": [],
  "skills": {
    "gullitmiranda/gullit-skills/skills/pr": {
      "source": "github.com/gullitmiranda/gullit-skills",
      "path": "skills/pr",
      "ref": "main",
      "agents": ["cursor"],
      "installed_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-01T00:00:00Z"
    },
    "gullitmiranda/gullit-skills/skills/workflow": {
      "source": "github.com/gullitmiranda/gullit-skills",
      "path": "skills/workflow",
      "ref": "main",
      "agents": ["cursor"],
      "installed_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-01T00:00:00Z"
    },
    "other/repo/skills/other": {
      "source": "github.com/other/repo",
      "path": "skills/other",
      "ref": "main",
      "agents": ["cursor"],
      "installed_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-01T00:00:00Z"
    }
  }
}
JSON

	cat >"${AI_SKILLS_HOME}/config.json" <<JSON
{
  "default_profile": "personal",
  "profiles": {
    "personal": {
      "repos_dir": "${TMP_DIR}/repos"
    }
  }
}
JSON

	mkdir -p "${TMP_DIR}/repos/gullitmiranda"
	rm -f "${TMP_DIR}/repos/gullitmiranda/gullit-skills"
	ln -s "${skill_repo}" "${TMP_DIR}/repos/gullitmiranda/gullit-skills"
}

assert_contains() {
	local haystack="$1"
	local needle="$2"
	[[ ${haystack} == *"${needle}"* ]] || {
		printf 'Expected output to contain: %s\nOutput:\n%s\n' "${needle}" "${haystack}" >&2
		return 1
	}
}

assert_not_contains() {
	local haystack="$1"
	local needle="$2"
	[[ ${haystack} != *"${needle}"* ]] || {
		printf 'Expected output not to contain: %s\nOutput:\n%s\n' "${needle}" "${haystack}" >&2
		return 1
	}
}

skill_repo="${TMP_DIR}/source-repos/gullit-skills"
make_skill_repo "${skill_repo}"
git -C "${skill_repo}" init --quiet
git -C "${skill_repo}" add .
git -C "${skill_repo}" -c user.name=test -c user.email=test@example.com commit --quiet -m init

write_manifest "${skill_repo}"
output="$("${BIN}" --dry-run update gullitmiranda/gullit-skills 2>&1)"
assert_contains "${output}" "gullitmiranda/gullit-skills/skills/pr"
assert_contains "${output}" "gullitmiranda/gullit-skills/skills/workflow"
assert_not_contains "${output}" "other/repo/skills/other"
assert_contains "${output}" "Updated 2 skill(s)"

write_manifest "${skill_repo}"
output="$("${BIN}" update gullitmiranda/gullit-skills --dry-run 2>&1)"
assert_contains "${output}" "gullitmiranda/gullit-skills/skills/pr"
assert_contains "${output}" "gullitmiranda/gullit-skills/skills/workflow"
assert_not_contains "${output}" "other/repo/skills/other"
assert_contains "${output}" "Updated 2 skill(s)"

write_manifest "${skill_repo}"
output="$("${BIN}" --dry-run update gullitmiranda/gullit-skills/skills/pr 2>&1)"
assert_contains "${output}" "gullitmiranda/gullit-skills/skills/pr"
assert_not_contains "${output}" "gullitmiranda/gullit-skills/skills/workflow"
assert_contains "${output}" "Updated 1 skill(s)"

write_manifest "${skill_repo}"
if output="$("${BIN}" --dry-run update unknown/repo 2>&1)"; then
	printf 'Expected unknown repository selector to fail.\nOutput:\n%s\n' "${output}" >&2
	exit 1
fi
assert_contains "${output}" "Skill not found in manifest: unknown/repo"

printf 'update-repository-selector: ok\n'
