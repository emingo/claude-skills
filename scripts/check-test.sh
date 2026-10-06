#!/usr/bin/env bash
# Check what a smoke test left on disk: the checkboxes in tests.md that grep and git can answer. What Claude asked,
# when it paused and how its pickers looked stay manual. Prints the row for the run log. Exits 1 if a check fails.
#   check-test.sh <test> [scratch dir] [--model <name>]
# Scratch dir: the argument, else $SMOKE_DIR, else ../scratch-plantest next to this repo.
set -uo pipefail
shopt -s nullglob
REPO=$(cd "$(dirname "$0")/.." && pwd)
usage() { echo "usage: $0 <test number> [scratch dir] [--model <name>]" >&2; exit 2; }
[[ ${1:-} =~ ^[0-9]+$ ]] || usage
t=$1; shift; dir=${SMOKE_DIR:-$REPO/../scratch-plantest}; model="<model>"
while [[ $# -gt 0 ]]; do
  case $1 in --model) [[ -n ${2:-} ]] || usage; model=$2; shift 2 ;; -*) usage ;; *) dir=$1; shift ;; esac
done
cd "$dir" 2>/dev/null || { echo "no scratch folder at $dir" >&2; exit 2; }

pass=0; fails=0
ok() { echo "  ok    $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL  $1${2:+ — $2}"; fails=$((fails + 1)); }
# check <description> <command…>: passes when the command succeeds; its output becomes the failure detail
check() { local d=$1 out; shift; if out=$("$@" 2>&1); then ok "$d"; else out=${out//$'\n'/ }; bad "$d" "${out:0:200}"; fi; }

PLAN=docs/implementation-plan.md; MS=docs/milestones; LEDGER=docs/follow-ups.md; FU=docs/fu
docs=("$MS"/M[0-9]*-*.md)
nofence() { awk '/^```/ {f=!f; next} !f' "$1"; }   # a doc without its code blocks, so sample Markdown isn't checked
# absent <regex> <files…>: nothing matches; an unreadable file is a failure, not a pass
absent() { local out rc; out=$(grep -nE "$@" 2>&1); rc=$?; [[ $rc -eq 1 ]] || { echo "$out"; return 1; }; }
# has <file> <regex…>: every regex matches somewhere in the file
has() { local f=$1 r; shift; for r in "$@"; do grep -qE "$r" "$f" || { echo "nothing matches $r"; return 1; }; done; }
count() { grep -cE "$1" <(nofence "$2"); }
# no_comments <files…>: no line opens an HTML comment outside a code block (prose may still mention <!-- inline)
no_comments() {
  local f hit out=
  for f in "$@"; do hit=$(nofence "$f" | grep -E '^[[:space:]]*<!--' | head -2); [[ -z $hit ]] || out+=" ${f##*/}: $hit"; done
  [[ -z $out ]] || { echo "$out"; return 1; }
}
# field <doc> <name>: a header field, minus its parenthetical notes (nested ones too) — they name other milestones
field() { grep -m1 -E "^\*\*$2:\*\*" "$1" | sed -e ':a' -e 's/([^()]*)//g' -e 'ta'; }
doc_id() { local b=${1##*/}; echo "${b%%-*}"; }
# ids <text>: the milestone ids it names, with ranges like M2–M5 expanded
ids() {
  local s=$1 r i
  while [[ $s =~ M([0-9]+)[[:space:]]*(–|-|to)[[:space:]]*M([0-9]+) ]]; do
    r=; for ((i = BASH_REMATCH[1]; i <= BASH_REMATCH[3]; i++)); do r+=" M$i"; done
    s=${s/"${BASH_REMATCH[0]}"/$r}
  done
  grep -oE '\bM[0-9]+[a-z]?\b' <<<"$s" | sort -u
}
# lacking <regex>: fails listing the milestone docs that don't match it
lacking() { local f out=; for f in "${docs[@]}"; do grep -qE "$1" "$f" || out+=" ${f##*/}"; done; [[ -z $out ]] || { echo "missing in:$out"; return 1; }; }
separators() { [[ $(count '^---[[:space:]]*$' "$PLAN") -ge $(($(count '^## [0-9]+\. ' "$PLAN") - 1)) ]]; }
verify_register() {
  grep -F '[VERIFY]' "$PLAN" | grep -qv 'marks an unconfirmed assumption' || { echo "no [VERIFY] tag beyond the rule in §0"; return 1; }
  grep -qE '^\|[[:space:]]*Q[0-9]+[[:space:]]*\|.*\bM[0-9]' "$PLAN" || { echo "no Q<n> register row with an owning milestone"; return 1; }
}
no_status_column() {
  local hdr; hdr=$(sed -n '/^## Documents/,/^## Dependency/p' "$MS/README.md" | grep '^|' | head -1)
  [[ -n $hdr ]] || { echo "no Documents table"; return 1; }
  ! grep -qi status <<<"$hdr"
}
wps_have_after() {
  local f out=
  for f in "${docs[@]}"; do [[ $(count '^### WP[0-9]+[a-z]?\.[0-9]+' "$f") -eq $(count '^\*\*After:\*\*' "$f") ]] || out+=" ${f##*/}"; done
  [[ -z $out ]] || { echo "work packages without After:$out"; return 1; }
}
# linked <field> <back field>: every id in <field> names a doc whose <back field> names this one.
# A split parent (M6 for M6a/M6b) counts on either side. Prose such as "all later milestones" can't be resolved.
linked() {
  local f id other o hit out=
  for f in "${docs[@]}"; do
    id=$(doc_id "$f")
    for other in $(ids "$(field "$f" "$1")"); do
      hit=
      for o in "$MS/$other"-*.md "$MS/$other"[a-z]-*.md; do
        ids "$(field "$o" "$2")" | grep -qE "^($id|${id%[a-z]})\$" && hit=1
      done
      [[ -n $hit ]] || out+=" $id→$other"
    done
  done
  [[ -z $out ]] || { echo "no matching '$2' for:$out"; return 1; }
}
projected() {
  local f out=
  for f in "${docs[@]}"; do field "$f" 'Depends on' | grep -qE '\bM[0-9]' && ! grep -q 'Projected' "$f" && out+=" ${f##*/}"; done
  [[ -z $out ]] || { echo "not marked Projected:$out"; return 1; }
}
gates() {   # gates <regex>: the plan line linking each doc matches it
  local f out=
  for f in "${docs[@]}"; do grep -F "milestones/${f##*/}" "$PLAN" | grep -qE "$1" || out+=" ${f##*/}"; done
  [[ -z $out ]] || { echo "plan gate wrong or missing for:$out"; return 1; }
}

# Test 1 — as it leaves the folder, before Test 2 commits or refreshes anything
test_1() {
  check "plan exists at $PLAN" test -f "$PLAN"
  [[ -f $PLAN ]] || return
  check "plan header has Execution: guided" grep -qE '^\*\*Execution:\*\* guided\b' "$PLAN"
  check "every ## section of the plan is numbered" absent '^## [^0-9]' <(nofence "$PLAN")
  check "plan sections are separated by ---" separators
  check "no <!-- guidance comments left in the plan" no_comments "$PLAN"
  check "decisions are Rejected/Chosen with a Cost line" has "$PLAN" '^### .*Rejected' '^### .*Chosen' '\*\*Cost:\*\*'
  check "a [VERIFY] item has a row in the assumption register, with an owner" verify_register
  check "the skill made no commits" test "$(git rev-list --count HEAD 2>/dev/null)" = 1

  check "milestone docs exist in $MS" test "${#docs[@]}" -gt 0
  [[ ${#docs[@]} -gt 0 ]] || return
  [[ ${#docs[@]} -ge 4 ]] || echo "  note  only ${#docs[@]} milestone docs, so parallel drafting did not trigger (fine; Test 3 covers it)"
  check "every doc: Status proposed" lacking '^\*\*Status:\*\* proposed'
  check "every doc: Depends on" lacking '^\*\*Depends on:\*\*'
  check "every doc: Blocks" lacking '^\*\*Blocks:\*\*'
  check "every doc: Can run alongside" lacking '^\*\*Can run alongside:\*\*'
  check "every doc: Execution: guided" lacking '^\*\*Execution:\*\* guided\b'
  check "every doc: Work packages count" lacking '^\*\*Work packages:\*\* [0-9]+'
  check "every doc: Written against a commit sha" lacking '^\*\*Written against:\*\* `[0-9a-f]{7,}`'
  check "every work package has an After: line" wps_have_after
  check "docs with unlanded dependencies mark What exists as Projected" projected
  check "Depends on is mirrored by Blocks" linked 'Depends on' Blocks
  check "Blocks is mirrored by Depends on" linked Blocks 'Depends on'
  check "no <!-- guidance comments left in the milestone docs" no_comments "${docs[@]}"
  check "each plan gate links its doc and shows proposed" gates 'proposed'

  check "index exists at $MS/README.md" test -f "$MS/README.md"
  if [[ -f $MS/README.md ]]; then
    check "index has the mermaid graph" grep -q '^```mermaid' "$MS/README.md"
    check "index has the full protocol, through its last rule" grep -q 'Workers never edit docs or the ledger' "$MS/README.md"
    check "index has Execution modes and Section profile" has "$MS/README.md" '^## Execution modes' '^## Section profile'
    check "index Documents table has no status column" no_status_column
  fi

  check "ledger entries exist in $FU" compgen -G "$FU/FU-*.md"
  check "index at $LEDGER is generated" grep -q '^<!-- GENERATED by fu-index' "$LEDGER"
  check "ledger entries carry kind: in front matter" grep -qE '^kind: ' "$FU"/FU-*.md
  check "milestone docs link entries as ../fu/FU-….md" grep -qE '\]\(\.\./fu/FU-[0-9]+\.md\)' "${docs[@]}"
  check "no ./follow-ups.md links from inside $MS" absent '\]\((\./)?follow-ups\.md' "$MS"/*.md
}

# wp_sync <milestone>: every work package with a code commit has a later "Sync docs for <M> <WP> (" commit
wp_sync() {
  local subjects wp last sync out=
  subjects=$(git log --reverse --format=%s)
  [[ -n $(grep -F "($1 WP" <<<"$subjects") ]] || { echo "no '($1 WPx.y)' commits found"; return 1; }
  for wp in $(grep -oE "\($1 WP[0-9a-z.]+\)\$" <<<"$subjects" | grep -oE 'WP[0-9a-z.]+' | sort -u); do
    last=$(grep -nF "($1 $wp)" <<<"$subjects" | tail -1 | cut -d: -f1)
    sync=$(grep -nF "Sync docs for $1 $wp (" <<<"$subjects" | tail -1 | cut -d: -f1)
    [[ -n $sync && $sync -gt $last ]] || out+=" $wp"
  done
  [[ -z $out ]] || { echo "no sync commit after:$out"; return 1; }
}
wps_landed() { [[ $(count '^### WP[0-9]+[a-z]?\.[0-9]+' "$1") -eq $(count '^\*\*Status: ☑ landed\*\*' "$1") ]]; }
clean_tree() { local out; out=$(git status --porcelain); [[ -z $out ]] || { echo "$out"; return 1; }; }
# One ledger entry that is both Kind compromise and has Why accepted
compromise() { local f; for f in "$FU"/FU-*.md; do grep -qE '^kind: *compromise' "$f" && grep -q '\*\*Why accepted:\*\*' "$f" && return 0; done; return 1; }

# Test 5 — after M0's last work package
test_5() {
  local m0=("$MS"/M0-*.md)
  check "M0 doc exists" test "${#m0[@]}" -gt 0
  [[ ${#m0[@]} -gt 0 ]] || return
  check "approval commit 'Approve the M0 milestone doc'" grep -qxF 'Approve the M0 milestone doc' <(git log --format=%s)
  check "every M0 work package commit is followed by its own Sync docs commit" wp_sync M0
  check "M0 doc is ☑ landed with a date and sha" grep -qE '^\*\*Status:\*\* ☑ landed \([0-9]{4}-[0-9]{2}-[0-9]{2}, `?[0-9a-f]{7,}' "${m0[0]}"
  check "every M0 work package is marked ☑ landed" wps_landed "${m0[0]}"
  check "As-built record is filled in" absent '^_Not implemented yet\._' "${m0[0]}"
  docs=("${m0[@]}"); check "plan gate for M0 says landed" gates 'landed \('
  check "the declined finding became a compromise follow-up with Why accepted" compromise
  check "working tree is clean" clean_tree
  check "no .implement/ folder left" test ! -e .implement
  check "no FU-TBD placeholder left in the code" absent 'FU-TBD' <(git grep -n FU-TBD -- . ':!docs' ':!.claude' || true)
}

echo "Test $t in $(pwd)"
if declare -F "test_$t" >/dev/null; then
  "test_$t"
  echo "On-disk checks: $pass passed, $fails failed. The behavioral checkboxes in tests.md are still yours to tick."
  note="on-disk checks $pass/$((pass + fails))"
else
  echo "  no on-disk checks for Test $t yet; tick its checkboxes in tests.md by hand"
  note=
fi
sha=$(git -C "$REPO" rev-parse --short HEAD); [[ -z $(git -C "$REPO" status --porcelain) ]] || sha+=" + uncommitted"
echo
echo "Run-log row (set the result once the manual checks are done):"
echo "| $(date +%F) | $t | \`$sha\` | $model | <pass/fail> | $note |"
[[ $fails -eq 0 ]]
