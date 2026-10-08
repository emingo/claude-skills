#!/usr/bin/env bash
# One merge of the swarm merge protocol (swarm.md §3, steps 2-4) in a single call: merge, build, test, standard gates.
# Full output goes to .implement/logs/; only result lines are printed, so the coordinator's context stays small.
#   merge-wp.sh <milestone> <WP id> <branch> "<title>" "<build command>" "<test command>" ["<commit trailer>"]
# Run from the repo root, on the branch the run commits to.
# Exit: 0 clean · 2 merge conflict (left in progress: resolve or `git merge --abort`) · 3 build or tests red · 4 gate hits
set -uo pipefail
[[ $# -ge 6 ]] || { echo "usage: merge-wp.sh <milestone> <WP> <branch> <title> <build cmd> <test cmd> [trailer]"; exit 64; }
m=$1; wp=$2; branch=$3; title=$4; build=$5; test=$6; trailer=${7:-}
logs=.implement/logs; mkdir -p "$logs"
base=$logs/$(tr '[:upper:]' '[:lower:]' <<<"$m")-$wp

[[ -z $(git status --porcelain --untracked-files=no | grep -v '^ M' || true) ]] || { echo "STAGED CHANGES — commit them first; git merge refuses to run over them"; git status --short --untracked-files=no; exit 64; }
pre=$(git rev-parse --short HEAD)
msg="Merge $m $wp: $title"; [[ -z $trailer ]] || msg+=$'\n\n'"$trailer"
if ! git merge --no-ff "$branch" -m "$msg" >"$base-merge.log" 2>&1; then
  echo "MERGE CONFLICT — $branch into $pre (merge left in progress)"
  git diff --name-only --diff-filter=U | sed 's/^/  conflict: /'
  tail -n 3 "$base-merge.log"
  exit 2
fi
echo "MERGED pre=$pre merge=$(git rev-parse --short HEAD) files=$(git diff --name-only "$pre"..HEAD | wc -l)"

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
