#!/bin/zsh
# Removes unused linked worktrees of the given repos and prunes their stale
# worktree records.
#
# Usage: cleanup-worktrees.sh [--dry-run|-n] [repo ...]
#   repo: path inside a git repository. Defaults to the current directory.
#
# A worktree is removed when:
#   - the PR for its branch is merged or closed (and the PR's head commit is
#     related to the local branch tip, so a reused branch name can't match an
#     old PR), OR
#   - its branch tracked a remote branch that no longer exists, OR
#   - its branch has no upstream but a PR proves it was pushed, and the
#     remote branch no longer exists, OR
#   - its branch was never pushed and holds no commit beyond origin's default
#     branch (created, then left untouched).
#
# A worktree is kept (and logged) when:
#   - it has uncommitted changes,
#   - it is on a detached HEAD, or on a never-pushed branch carrying its own
#     commits,
#   - its repo can't be fetched (offline, auth issue).
#
# Only one instance runs at a time (lock at ~/.cleanup-worktrees.lock).

set -u
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

DRY_RUN=false
REPOS=()
for arg in "$@"; do
  case $arg in
    --dry-run|-n) DRY_RUN=true ;;
    *) REPOS+=("$arg") ;;
  esac
done
(( ${#REPOS} )) || REPOS=("$PWD")

LOCK_DIR="$HOME/.cleanup-worktrees.lock"

log() { print -- "$(date '+%Y-%m-%d %H:%M:%S') $*" }

# Lists what a kept worktree still holds: uncommitted files, then commits not
# yet on the remote. The remote side is the upstream, else origin/<branch>,
# else the default branch (never-pushed branch).
report_changes() {
  local wt=$1 branch=$2 base
  git -C "$wt" status --short 2>/dev/null | sed 's/^/    /'
  for base in "@{upstream}" "refs/remotes/origin/$branch" "refs/remotes/origin/HEAD"; do
    git -C "$wt" rev-parse --verify --quiet "$base" >/dev/null 2>&1 && break
  done
  git -C "$wt" log --oneline "$base..HEAD" 2>/dev/null | sed 's/^/    unpushed: /'
}

# --------------------------------------------------------------------------
# Lock: skip the run if another instance is alive; steal a stale lock.
# --------------------------------------------------------------------------
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  other_pid=$(cat "$LOCK_DIR/pid" 2>/dev/null)
  if [[ -n ${other_pid:-} ]] && kill -0 "$other_pid" 2>/dev/null; then
    log "skip run: another instance (pid $other_pid) is running"
    exit 0
  fi
  rm -rf "$LOCK_DIR"
  mkdir "$LOCK_DIR" 2>/dev/null || exit 1
fi
print $$ > "$LOCK_DIR/pid"
trap 'rm -rf "$LOCK_DIR"' EXIT

log "--- run start ---"

for repo in "${REPOS[@]}"; do
  main_repo=$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)
  if [[ -z $main_repo ]]; then
    log "skip $repo: not a git repository"
    continue
  fi

  # Fetch once per repo so remote-tracking refs are current.
  if ! git -C "$main_repo" fetch --prune --quiet 2>/dev/null; then
    log "skip $main_repo: fetch failed"
    continue
  fi

  # origin/HEAD names the remote default branch; older clones lack it.
  git -C "$main_repo" rev-parse --verify --quiet refs/remotes/origin/HEAD >/dev/null 2>&1 \
    || git -C "$main_repo" remote set-head origin --auto >/dev/null 2>&1
  default_ref=$(git -C "$main_repo" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)

  # ------------------------------------------------------------------------
  # 1. Remove unused linked worktrees (the main worktree is the first entry).
  # ------------------------------------------------------------------------
  git -C "$main_repo" worktree list --porcelain \
    | sed -n 's/^worktree //p' | tail -n +2 | while read -r wt; do
    if [[ ! -d $wt ]]; then
      log "skip $wt: directory missing (prune clears the record)"
      continue
    fi

    branch=$(git -C "$wt" branch --show-current 2>/dev/null)
    if [[ -z $branch ]]; then
      log "skip $wt: detached HEAD"
      continue
    fi

    if [[ -n $(git -C "$wt" status --porcelain 2>/dev/null) ]]; then
      log "skip $wt: uncommitted changes"
      report_changes "$wt" "$branch"
      continue
    fi

    # Look up the PR for this branch. gh matches PRs by head-branch name, so
    # a reused branch name can hit an old PR: only trust the PR if its head
    # commit and the local branch tip are on the same line of history.
    pr_info=$(cd "$wt" && gh pr view "$branch" --json state,headRefOid \
                --jq '.state + " " + .headRefOid' 2>/dev/null)
    pr_state="${pr_info%% *}"
    pr_head="${pr_info##* }"
    tip=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
    pr_matches_branch=false
    if [[ -n $pr_info ]]; then
      if [[ $pr_head == $tip ]] \
         || git -C "$wt" merge-base --is-ancestor "$pr_head" "$tip" 2>/dev/null \
         || git -C "$wt" merge-base --is-ancestor "$tip" "$pr_head" 2>/dev/null; then
        pr_matches_branch=true
      fi
    fi

    # Decide whether the worktree is unused.
    reason=""
    if [[ $pr_matches_branch == true && ($pr_state == MERGED || $pr_state == CLOSED) ]]; then
      reason="PR ${pr_state:l}"
    else
      # "[gone]" means the branch tracked a remote branch that was deleted.
      track=$(git -C "$main_repo" for-each-ref --format='%(upstream:track)' "refs/heads/$branch")
      remote=${$(git -C "$main_repo" config "branch.$branch.remote" 2>/dev/null):-origin}
      if [[ $track == "[gone]" ]]; then
        reason="remote branch deleted"
      elif ! git -C "$main_repo" rev-parse --verify --quiet \
               "refs/remotes/$remote/$branch" >/dev/null; then
        if [[ $pr_matches_branch == true ]]; then
          # No upstream configured, but a PR proves the branch was pushed and
          # the remote copy is gone now.
          reason="remote branch deleted (PR ${pr_state:l})"
        elif [[ -n $default_ref ]] \
             && git -C "$wt" merge-base --is-ancestor HEAD "$default_ref" 2>/dev/null; then
          # Never pushed and every commit is already on the default branch:
          # the worktree was created and left untouched.
          reason="no commits beyond ${default_ref#refs/remotes/}"
        fi
        # A never-pushed branch carrying its own commits stays.
      fi
    fi

    if [[ -z $reason ]]; then
      log "keep $wt: branch '$branch' still active (PR state: ${pr_state:-none})"
      report_changes "$wt" "$branch"
      continue
    fi

    if [[ $DRY_RUN == true ]]; then
      log "would remove $wt ($reason)"
      continue
    fi

    if git -C "$main_repo" worktree remove "$wt" 2>/dev/null; then
      log "removed $wt ($reason)"
      rmdir "${wt:h}" 2>/dev/null
      if git -C "$main_repo" branch -D "$branch" >/dev/null 2>&1; then
        log "deleted local branch '$branch' in $main_repo"
      fi
    else
      log "ERROR: failed to remove $wt"
    fi
  done

  # ------------------------------------------------------------------------
  # 2. Prune stale worktree records.
  # ------------------------------------------------------------------------
  prune_args=(--verbose)
  if [[ $DRY_RUN == true ]]; then
    prune_args+=(--dry-run)
  fi
  git -C "$main_repo" worktree prune $prune_args 2>&1 | while read -r line; do
    log "prune ${main_repo:t}: $line"
  done
done

log "--- run end ---"
