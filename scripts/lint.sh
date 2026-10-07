#!/usr/bin/env bash
# Check the repo's own rules — CLAUDE.md's "Authoring conventions" and "Cross-file contracts". No Claude run needed.
# Exits 1 if anything fails.
# Names that must stay out of the repo go in .lint-deny (gitignored): one regex per line, # for comments.
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/.."
fails=0
fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }
# front <file> <field>: a frontmatter field's value, empty if absent
front() { awk -v k="$2" 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f && index($0, k":")==1 {sub("^"k":[ \t]*", ""); print; exit}' "$1"; }

coverage=$(sed -n '/^## Coverage/,/^## Test 1/p' tests.md)
for d in skills/*/; do
  d=${d%/}; n=${d##*/}; s=$d/SKILL.md
  [[ -f $s ]] || { fail "$d" "no SKILL.md"; continue; }
  [[ $(front "$s" name) == "$n" ]] || fail "$s" "frontmatter name must match the directory name"
  [[ -n $(front "$s" description) ]] || fail "$s" "no description"
  desc=$(front "$s" description); [[ ${#desc} -le 500 ]] || fail "$s" "description is ${#desc} chars — keep it to 500 (it loads in every session)"
  [[ $coverage == *"\`$n\`"* ]] || fail tests.md "coverage table has no row for \`$n\`"
done

for a in agents/*.md; do
  n=${a##*/}; n=${n%.md}; tools=$(front "$a" tools); model=$(front "$a" model)
  [[ $(front "$a" name) == "$n" ]] || fail "$a" "frontmatter name must match the file name"
  [[ -n $(front "$a" description) ]] || fail "$a" "no description"
  desc=$(front "$a" description); [[ ${#desc} -le 500 ]] || fail "$a" "description is ${#desc} chars — keep it to 500 (it loads in every session)"
  [[ -n $(front "$a" color) ]] || fail "$a" "no color"
  if [[ $n == *reviewer ]]; then
    [[ $tools == "Read, Grep, Glob, Bash" && -z $model ]] || fail "$a" "reviewers have tools: Read, Grep, Glob, Bash (git reads only) and omit model"
    grep -q '^## Getting the change' "$a" || fail "$a" "reviewers need the 'Getting the change' section (git-only Bash, review depth)"
  elif [[ $tools == *Write* || $tools == *Edit* ]]; then
    [[ $model == sonnet ]] || fail "$a" "agents that write files use model: sonnet"
  fi
done

# Reviewer roster: every stack reviewer is named in the global "Agents" section and in reviewer.md's description
roster=$(sed -n '/^## Agents/,/^## /p' main-agent/CLAUDE.md); generic=
if [[ -f agents/reviewer.md ]]; then generic=$(front agents/reviewer.md description); else fail agents/reviewer.md "the generic reviewer is missing"; fi
for a in agents/*-reviewer.md; do
  n=${a##*/}; n=${n%.md}
  [[ $roster == *"\`$n\`"* ]] || fail main-agent/CLAUDE.md "the \"Agents\" section doesn't name \`$n\`"
  [[ $generic == *"$n"* ]] || fail agents/reviewer.md "the description doesn't name $n"
done

# Every ${CLAUDE_SKILL_DIR}/… path a skill mentions exists, resolved from that skill's directory
while IFS=: read -r file ref; do
  d=${file#skills/}; d=skills/${d%%/*}; ref=${ref%.}
  [[ -e $d/${ref#*\}/} ]] || fail "$file" "$ref does not exist"
done < <(grep -ro -E '\$\{CLAUDE_SKILL_DIR\}/[A-Za-z0-9_./-]+' skills | sort -u)

# A bare reference/x.md or templates/x.md may belong to another skill, so it only has to exist in one of them
while IFS=: read -r file ref; do
  compgen -G "skills/*/$ref" >/dev/null || fail "$file" "$ref exists in no skill"
done < <(grep -ro -E '\b(reference|templates)/[a-z0-9-]+\.md' skills agents CLAUDE.md README.md tests.md | sort -u)

if [[ -s .lint-deny ]]; then
  # Trailing whitespace is stripped first: a CRLF-saved file would otherwise match nothing and pass
  mapfile -t deny < <(sed 's/[[:space:]]*$//' .lint-deny | grep -vE '^(#|$)' || true)
  args=(); for p in ${deny[@]+"${deny[@]}"}; do args+=(-e "$p"); done
  if [[ ${#args[@]} -gt 0 ]]; then
    # git grep exits 1 for no match; anything higher (a bad regex) must not read as a pass
    hits=$(git grep --untracked -n -i -I -E "${args[@]}" 2>&1) || { rc=$?; [[ $rc -eq 1 ]] || fail .lint-deny "git grep failed ($rc): ${hits:0:120}"; hits=; }
    [[ -z $hits ]] || while IFS=: read -r file line _; do fail "$file:$line" "matches a .lint-deny pattern"; done <<<"$hits"
  fi
else
  echo "note: no .lint-deny file, so the private-name check was skipped"
fi

[[ $fails -eq 0 ]] || { echo "$fails problem(s)"; exit 1; }
echo "lint ok"
