#!/usr/bin/env bash
# One merge of the swarm merge protocol (swarm.md §3, steps 2-4) in a single call: merge, build, test, standard gates.
# Full output goes to .implement/logs/; only result lines are printed, so the coordinator's context stays small.
#   merge-wp.sh [--from <pre sha>] <milestone> <WP id> <branch> '<title>' '<build command>' '<test command>' ['<commit trailer>']
# Run from the repo root, on the branch the run commits to. Single-quote the title and the commands.
# --from <pre sha>: the merge already happened (a conflict resolved by hand, or a run interrupted after merging) —
#   skip it and run build, test and gates on <pre sha>..HEAD.
# Exit: 0 clean · 2 merge conflict (left in progress: resolve or `git merge --abort`) · 3 build or tests red · 4 gate hits
#       5 branch already merged (use --from) · 6 merge failed without starting (bad branch, a file in the way) · 64 usage or staged changes
set -uo pipefail
from=
if [[ ${1:-} == --from ]]; then from=${2:-}; shift 2; fi
[[ $# -ge 6 ]] || { echo "usage: merge-wp.sh [--from <pre sha>] <milestone> <WP> <branch> <title> <build cmd> <test cmd> [trailer]"; exit 64; }
m=$1; wp=$2; branch=$3; title=$4; build=$5; test=$6; trailer=${7:-}
logs=.implement/logs; mkdir -p "$logs"
base=$logs/$(tr '[:upper:]' '[:lower:]' <<<"$m")-${wp//\//-}

if [[ -n $from ]]; then
  pre=$(git rev-parse --short "$from^{commit}" 2>/dev/null) || { echo "BAD --from: $from is not a commit"; exit 64; }
  ! git rev-parse -q --verify MERGE_HEAD >/dev/null || { echo "MERGE IN PROGRESS — commit or abort it before --from"; exit 64; }
  echo "CHECKING pre=$pre head=$(git rev-parse --short HEAD) files=$(git diff --name-only "$pre"..HEAD | wc -l)"
else
  [[ -z $(git status --porcelain --untracked-files=no | grep -v '^ M' || true) ]] || { echo "STAGED CHANGES — commit them first; git merge refuses to run over them"; git status --short --untracked-files=no; exit 64; }
  git rev-parse -q --verify "$branch^{commit}" >/dev/null || { echo "MERGE FAILED — no such branch: $branch"; exit 6; }
  ! git merge-base --is-ancestor "$branch" HEAD || { echo "ALREADY MERGED — $branch is in HEAD; rerun with --from <the sha before that merge> to build, test and gate it"; exit 5; }
  pre=$(git rev-parse --short HEAD)
  msg="Merge $m $wp: $title"; [[ -z $trailer ]] || msg+=$'\n\n'"$trailer"
  if ! git merge --no-ff "$branch" -m "$msg" >"$base-merge.log" 2>&1; then
    if git rev-parse -q --verify MERGE_HEAD >/dev/null; then
      echo "MERGE CONFLICT — $branch into $pre (merge left in progress)"
      git diff --name-only --diff-filter=U | sed 's/^/  conflict: /'
      exit 2
    fi
    echo "MERGE FAILED — nothing was merged:"; tail -n 4 "$base-merge.log" | sed 's/^/  /'
    exit 6
  fi
  echo "MERGED pre=$pre merge=$(git rev-parse --short HEAD) files=$(git diff --name-only "$pre"..HEAD | wc -l)"
fi

red=0
bash -c "$build" >"$base-build.log" 2>&1; b=$?
echo "BUILD exit=$b · $(grep -E 'Warning\(s\)|Error\(s\)|error|warning: ' "$base-build.log" | tail -n 2 | tr -s ' ' | paste -sd'|' -) · log $base-build.log"
if [[ $b -ne 0 ]]; then red=1; else
  bash -c "$test" >"$base-test.log" 2>&1; t=$?
  echo "TEST exit=$t · $(grep -iE 'passed|failed|total|tests? run|summary' "$base-test.log" | tail -n 3 | tr -s ' ' | paste -sd'|' -) · log $base-test.log"
  [[ $t -eq 0 ]] || { red=1; grep -iE '^\s*(failed|error) ' "$base-test.log" | head -n 8 | sed 's/^/  /'; }
fi

# Standard gates on the lines this merge added; milestone-specific convention greps stay with the coordinator.
hits=$(git diff "$pre"..HEAD -- . ':!.implement' ':!docs' | grep -nE '^\+.*(NOTE FOR|COORDINATOR|TODO|FIXME|HACK|FU-TBD)' || true)
if [[ -n $hits ]]; then echo "GATES $(wc -l <<<"$hits") hit(s):"; head -n 12 <<<"$hits" | cut -c1-200 | sed 's/^/  /'; else echo "GATES clean"; fi
reports=$(git diff --name-only "$pre"..HEAD -- .implement/reports | paste -sd' ' -); echo "REPORTS ${reports:-none}"

[[ $red -eq 0 ]] || exit 3
[[ -z $hits ]] || exit 4
exit 0
