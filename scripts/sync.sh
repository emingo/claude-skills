#!/usr/bin/env bash
# Sync this repo with the live Claude Code config ($CLAUDE_CONFIG_DIR, default ~/.claude).
#   status (default)  list files that differ between repo and live
#   diff              unified diff, live → repo
#   apply [--force]   copy repo → live; refuses if a live file is newer (edited outside the repo) unless --force
#   pull [--force]    copy live → repo, including files that exist only live; skips repo files that are newer
#                     or have uncommitted changes unless --force
# apply and pull leave the global CLAUDE.md alone unless --global is passed.
# Every overwritten file is first backed up to .sync-backup/<timestamp>/{live,repo}/.
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/.."
LIVE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# Backslash paths break the globs below without erroring
command -v cygpath >/dev/null && LIVE=$(cygpath -u "$LIVE")
GLOBAL=main-agent/CLAUDE.md
STAMP=$(date +%Y%m%d-%H%M%S)

usage() { echo "usage: $0 [status|diff|apply [--force] [--global]|pull [--force] [--global]]" >&2; exit 2; }
mode="${1:-status}"; force=; global=
for a in "${@:2}"; do case $a in --force) force=1 ;; --global) global=1 ;; *) usage ;; esac; done
case $mode in status|diff) [[ -z $force$global ]] || usage ;; apply|pull) ;; *) usage ;; esac

live_path() { [[ $1 == "$GLOBAL" ]] && echo "$LIVE/CLAUDE.md" || echo "$LIVE/$1"; }

# Repo-relative paths that differ, tagged: new | repo-newer | live-newer | live-only
drift() {
  local f dst a s d n
  while IFS= read -r f; do
    dst=$(live_path "$f")
    if [[ ! -e $dst ]]; then echo "new $f"
    elif ! cmp -s "$f" "$dst"; then [[ $dst -nt $f ]] && echo "live-newer $f" || echo "repo-newer $f"; fi
  done < <(echo "$GLOBAL"; find agents skills -type f | sort)
  for a in "$LIVE"/agents/*.md; do [[ -e agents/${a##*/} ]] || echo "live-only agents/${a##*/}"; done
  # Only top-level skill dirs with a SKILL.md; skips synced/ (managed by claude.ai) and .trash/
  for s in "$LIVE"/skills/*/SKILL.md; do
    d=${s%/SKILL.md}; n=${d##*/}
    if [[ ! -e skills/$n ]]; then echo "live-only skills/$n/"; continue; fi
    while IFS= read -r a; do [[ -e ${a#"$LIVE"/} ]] || echo "live-only ${a#"$LIVE"/}"; done < <(find "$d" -type f | sort)
  done
}

# copy <src> <dst> <side>: backs up an existing dst under .sync-backup/<stamp>/<side>/
copy() {
  if [[ -e $2 ]]; then
    local bak=".sync-backup/$STAMP/$3/${2#"$LIVE"/}"
    mkdir -p "$(dirname "$bak")"; cp -rp "$2" "$bak"
  fi
  mkdir -p "$(dirname "$2")"; cp -r "$1" "$2"
}

dirty() { [[ -n $(git status --porcelain -- "$1") ]]; }

mapfile -t items < <(drift)
[[ ${#items[@]} -eq 0 ]] && { echo "in sync"; exit 0; }

# The global CLAUDE.md is personal to one machine's owner: never swap it in either direction by default
if [[ $mode != status && $mode != diff && -z $global ]]; then
  kept=()
  for it in "${items[@]}"; do
    if [[ ${it#* } == "$GLOBAL" ]]; then echo "skip  $GLOBAL (global CLAUDE.md; pass --global to sync it)"; else kept+=("$it"); fi
  done
  [[ ${#kept[@]} -eq 0 ]] && exit 0
  items=("${kept[@]}")
fi

case $mode in
  status) printf '%s\n' "${items[@]}" | sed "s|$GLOBAL\$|& [--global]|" | column -t ;;
  diff)
    for it in "${items[@]}"; do
      read -r tag f <<<"$it"
      case $tag in new) echo "--- new in repo: $f" ;; live-only) echo "--- only live: $f" ;; *) diff -u --label "live/$f" --label "repo/$f" "$(live_path "$f")" "$f" || true ;; esac
    done ;;
  apply)
    if [[ -z $force ]] && printf '%s\n' "${items[@]}" | grep -q '^live-newer'; then
      echo "live files edited outside the repo — run 'pull' first, or 'apply --force' to overwrite:" >&2
      printf '%s\n' "${items[@]}" | grep '^live-newer' >&2; exit 1
    fi
    for it in "${items[@]}"; do
      read -r tag f <<<"$it"
      if [[ $tag == live-only ]]; then echo "skip  $f (only live)"; continue; fi
      copy "$f" "$(live_path "$f")" live; echo "apply $f"
    done ;;
  pull)
    for it in "${items[@]}"; do
      read -r tag f <<<"$it"
      case $tag in
        new) echo "skip  $f (not live yet)" ;;
        live-only) copy "$LIVE/${f%/}" "${f%/}" repo; echo "pull  $f" ;;
        *)
          if [[ -z $force && $tag == repo-newer ]]; then echo "skip  $f (repo is newer; pull --force to overwrite)"
          elif [[ -z $force ]] && dirty "$f"; then echo "skip  $f (uncommitted repo changes; pull --force to overwrite)"
          else copy "$(live_path "$f")" "$f" repo; echo "pull  $f"
          fi ;;
      esac
    done ;;
esac
