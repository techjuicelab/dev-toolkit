---
name: merge-worktree
description: Squash-merge the current git worktree branch into its target branch (default main/master) with a researched Conventional-Commits message. Use when finishing work in a worktree and merging it back. Stops on conflict, never force-pushes, never skips hooks.
argument-hint: "[target-branch] [--pr]"
disable-model-invocation: true
---

# Merge Worktree

Squash-merge the current worktree branch back into the target branch with a comprehensive, structured commit message — or open a PR with `--pr`.

## Current context

- Git dir: `!git rev-parse --git-dir`
- Common dir: `!git rev-parse --git-common-dir`
- Current branch: `!git branch --show-current`
- Recent commits: `!git log --oneline -20`
- Working tree status: `!git status --short`

## Instructions

Follow these phases exactly, in order. Do NOT skip phases.

---

### Phase 1: Validation

1. **Verify worktree**: `git rev-parse --git-dir` must contain `/worktrees/` (native Claude Code worktrees live under `.claude/worktrees/`). If it does not, **stop** and tell the user: "This skill must be run from inside a git worktree."

2. **Identify the worktree branch**: `git branch --show-current`.

3. **Resolve the target branch**:
   - If an argument (other than `--pr`) is provided, use it.
   - Otherwise detect the default branch: prefer `origin/HEAD` (`git symbolic-ref --short refs/remotes/origin/HEAD | sed 's@^origin/@@'`); fall back to `main`, then `master`. If none exists, stop and ask.

4. **Find the original repo working dir**: `git rev-parse --git-common-dir` points at the main repo's `.git`; its parent is the original repo working directory. Call it `<repo>`.

5. **Clean working tree**: `git status --porcelain` must be empty. If not, stop and tell the user to commit or stash first.

6. **Ahead-of-target guard**: Run `git rev-list --count <target>..HEAD`. If `0`, the branch has nothing to merge — **stop** and say so (no-op merge). 

7. **Target-not-checked-out-elsewhere guard**: Run `git -C <repo> worktree list`. If `<target>` is checked out in a DIFFERENT worktree than `<repo>`, stop and tell the user (you cannot safely check it out in two places).

---

### Phase 2: Research (most critical — do this thoroughly)

1. **Commits**: `git log --oneline <target>..HEAD`.
2. **File summary**: `git diff <target>...HEAD --stat`.
3. **Full diff**: `git diff <target>...HEAD` — read it carefully.
4. **Read key files**: Use the Read tool on the most significantly changed/new/deleted files for full context, not just diff lines.
5. **Categorize**: features / fixes / refactors / tests / docs / config-chore.
6. **Dominant type**: pick the single Conventional-Commits type (`feat`, `fix`, `refactor`, `docs`, `chore`, `test`) that best represents the work.

---

### Phase 3: Target preparation

1. **Fetch latest** (if a remote exists): `git -C <repo> fetch origin <target> 2>/dev/null` (do not fail if no remote).
2. **Inspect target**: `git -C <repo> log --oneline -10 <target>`.
3. **Stray WIP guard**: If the target has obvious auto-generated commits (messages starting `wip:`, `WIP`, `auto-commit`), warn and ask whether to reset to the last clean commit before merging.
4. **Rebase onto fresh target** (avoid merging stale work): from the worktree, run `git rebase <target>` (or `origin/<target>` if fetched). If it conflicts, **stop** and report — do not auto-resolve.

---

### Phase 4: Merge

**If `--pr` was passed** (PR-based flow, preferred for shared branches): push the worktree branch and open a PR:
```bash
git push -u origin <worktree-branch>
gh pr create --base <target> --head <worktree-branch> --fill
```
Then skip to Phase 6 (the squash happens at PR merge time, e.g. `gh pr merge --squash`). Do not run the local checkout-and-commit below.

**Otherwise** (local squash-merge):
1. Check out the target in the original repo: `git -C <repo> checkout <target>`.
2. Squash-merge: `git -C <repo> merge --squash <worktree-branch>`.
3. **Conflicts**: if reported, list the conflicted files, show the markers, **stop and report** — never auto-resolve. Tell the user to resolve in `<repo>` and re-run.
4. On success, continue to Phase 5.

---

### Phase 5: Commit message and commit

Write the message from your Phase 2 research, using this **exact structure**:

```
<type>: <imperative summary, under 72 chars, no period>

<2-4 sentence paragraph: WHAT was done and WHY — motivation and high-level
approach, not implementation details.>

Changes:
- <grouped bullets, most important first>
- <sub-bullets for details within a group>
```

**Rules:**
- `<type>` ∈ `feat | fix | refactor | docs | chore | test`; use the dominant one if mixed.
- Summary: imperative mood, no period, ≤72 chars.
- Body: explain the *why*, not just the *what*.
- Do **not** invent a `Co-Authored-By` trailer. If the repo's convention is to add one, append the trailer the user/repo actually uses — never a hardcoded model string.

**Create the commit** in the original repo via heredoc:
```bash
git -C <repo> commit -m "$(cat <<'EOF'
<your commit message here>
EOF
)"
```

---

### Phase 6: Verification

1. **PR flow**: show the PR URL from `gh pr create`.
2. **Local flow**: `git -C <repo> log --oneline -3`; report the commit hash, summary line, and target branch.
3. **Cleanup offer**: the worktree branch still exists — offer to remove it with `git -C <repo> worktree remove <worktree-path>` (and delete the branch) when no longer needed.
4. **Push reminder**: remind the user to `git -C <repo> push` if they want to push the local-merge result.

---

## Important notes

- **Never force-push** or use destructive git operations without explicit user confirmation.
- **Never skip hooks** (`--no-verify`).
- If anything unexpected happens at any phase, **stop and explain** rather than guessing.
- Commit-message quality is paramount — invest the time in Phase 2.
