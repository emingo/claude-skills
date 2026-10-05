#!/usr/bin/env bash
# Start a smoke test from tests.md: pick the model, print the test's section as guidance, and on a keypress open an
# interactive Claude session in the scratch folder with the test's first prompt (the first untagged code block in
# its section). When the session ends, check-test.sh checks what it left on disk and prints the run-log row.
#   smoke.sh <test> [--model <alias|id>] [--dir <folder>] [--dry-run]
# Folder: --dir, else $SMOKE_DIR, else ../scratch-plantest next to this repo. Test 1 creates it; Tests 2 and 5–10
# build on it. Tests 3, 4 and 11 run in another repo or clone, so they need --dir. Tests kept in the untracked
# tests.local.md are found there first.
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
usage() { echo "usage: $0 <test number> [--model <alias|id>] [--dir <folder>] [--dry-run]" >&2; exit 2; }
[[ ${1:-} =~ ^[0-9]+$ ]] || usage
t=$1; shift; model=; picked=; dir=${SMOKE_DIR:-}; dry=
while [[ $# -gt 0 ]]; do
  case $1 in
    --model) [[ -n ${2:-} ]] || usage; model=$2; picked=1; shift 2 ;;
    --dir) [[ -n ${2:-} ]] || usage; dir=$2; shift 2 ;;
    --dry-run) dry=1; shift ;;
    *) usage ;;
  esac
done
if [[ -z $dir ]]; then
  case $t in 3|4|11) echo "Test $t runs in another repo or clone, not the scratch folder — pass --dir <that folder>" >&2; exit 1 ;; esac
  dir=$REPO/../scratch-plantest
fi

# A test's section runs to the next ## heading outside a code block (Test 8's setup has ## lines inside one)
section() { [[ -f $1 ]] && awk -v h="^## Test $t:" '$0 ~ h {f=1; print; next} /^```/ {c=!c} f && !c && /^## / {exit} f' "$1"; }
guide=$(section "$REPO/tests.local.md" || true); [[ -n $guide ]] || guide=$(section "$REPO/tests.md" || true)
[[ -n $guide ]] || { echo "no Test $t in tests.md or tests.local.md" >&2; exit 1; }
guide=${guide//$'\r'/}
# First untagged code block; ```powershell and other tagged blocks are setup, not prompts
prompt=$(awk '/^```/ { if (inb) { if (plain) exit; inb=0 } else { inb=1; plain=($0 == "```") } next } inb && plain' <<<"$guide")

if [[ -z $picked ]]; then
  echo "Model for this run (it goes in the run log; a pass on a cheaper model doesn't carry over):"
  echo "  1) your default   2) opus   3) sonnet   4) haiku   — or type a model id"
  read -r -p "> " m
  case $m in ""|1) model= ;; 2) model=opus ;; 3) model=sonnet ;; 4) model=haiku ;; *) model=$m ;; esac
fi

if [[ $t == 1 ]]; then
  [[ -z $(ls -A "$dir" 2>/dev/null | grep -vx .git) ]] \
    || { echo "Test 1 needs a fresh scratch folder, but $dir already has files. Delete it or pass --dir." >&2; exit 1; }
  if [[ -z $dry ]]; then
    mkdir -p "$dir"; [[ -d $dir/.git ]] || git -C "$dir" init -q
    # The empty commit matters: the skills record the commit each doc was written against
    git -C "$dir" rev-parse -q --verify HEAD >/dev/null 2>&1 || git -C "$dir" commit -q --allow-empty -m init
  fi
elif [[ ! -d $dir ]]; then
  echo "no folder at $dir — run Test 1 first, or pass --dir" >&2; exit 1
fi

echo; echo "$guide"; echo
echo "────────────────────────────────────────────────────────"
drift=$(bash "$REPO/scripts/sync.sh" status | grep -E '^(new|repo-newer|live-newer) ' || true)
skills=$(grep -vF '[--global]' <<<"$drift" || true)
if [[ -n $skills ]]; then
  echo "WARNING: the deployed config differs from this repo, so the session tests what is deployed, not this commit."
  echo "Run scripts/sync.sh apply first, or carry on knowingly:"; echo "$skills"; echo
fi
# The global CLAUDE.md differs on any machine but the author's, so only mention it where a test depends on it
if [[ $drift == *'[--global]'* && ( $t == 10 || $t == 11 ) ]]; then
  echo "NOTE: the deployed global CLAUDE.md differs from main-agent/CLAUDE.md, and Test $t checks rules that live in it."; echo
fi
echo "Folder: $dir"
echo "Model:  ${model:-your default}"
echo "Skills: $(git -C "$REPO" rev-parse --short HEAD)$([[ -z $(git -C "$REPO" status --porcelain) ]] || echo ' + uncommitted changes')"
if [[ $prompt == *"<"*">"* ]]; then
  echo "The first prompt has placeholders: $prompt"
  [[ -n $dry ]] || read -r -p "Type the prompt to send: " prompt
fi
echo "First prompt: ${prompt:-none — the session opens empty; follow the steps above}"

# Git Bash rewrites an argument that starts with / into a Windows path before a native program sees it
# (/implement M0 → C:/…/Git/implement M0). Excluding only the prompt's first word leaves real paths alone, in
# this command and in the session that inherits the variable; outside Git Bash it is ignored.
[[ $prompt != /* ]] || export MSYS2_ARG_CONV_EXCL="${MSYS2_ARG_CONV_EXCL:+$MSYS2_ARG_CONV_EXCL;}${prompt%% *}"
cmd=(claude); [[ -z $model ]] || cmd+=(--model "$model"); [[ -z $prompt ]] || cmd+=("$prompt")
if [[ -n $dry ]]; then printf 'dry run, would run in %s:\n ' "$dir"; printf ' %q' "${cmd[@]}"; echo; exit 0; fi
read -r -n1 -s -p "Press any key to start the session (Ctrl+C to cancel) " _; echo
(cd "$dir" && "${cmd[@]}") || true

echo; echo "Session ended."
bash "$REPO/scripts/check-test.sh" "$t" "$dir" --model "${model:-default}" || true
