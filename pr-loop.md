# PR loop: shared steps

Steps shared by `babysit-pr` and `greploop`. Each skill names the section it reaches for; that section is the single source of truth for the step.

## Target

- No argument → the open PR for the current branch (`gh pr view --json number,url,state,isDraft,headRefName`).
- A number or URL → that PR.
- Several PRs match the branch → ask which one.
- PR merged or closed → say so and stop.

Then confirm the local checkout is on the PR head branch with a clean working tree, and pull if behind. A dirty tree or wrong branch stops here: ask the user to stash, commit, or check out before the loop starts.

Target is complete when the PR is resolved and the checkout sits on its head.

## Threads

Fetch every review thread with its resolved state. Resolved and outdated state lives only in GraphQL, and the GraphQL endpoint is POST-only: this read does not take `--method GET`, but it is still read-only. While `hasNextPage` is true, repeat with `-F cursor=<endCursor>`. The snapshot is complete only when every page is in.

```bash
gh api graphql -F owner='{owner}' -F repo='{repo}' -F pr=<number> -f query='
query($owner:String!, $repo:String!, $pr:Int!, $cursor:String) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:100, after:$cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id isResolved isOutdated path line
          comments(first:50) { nodes { author { login } body url } }
        }
      }
    }
  }
}'
```

Parse with `jq`: it runs without a permission prompt, so each pass stays hands-off.

## Triage

Every code change goes through the user. Walk the findings one at a time, file order. For each finding:

1. Quote the comment with its `file:line` and the relevant hunk.
2. Work out the fix options you see.
3. Ask with AskUserQuestion, one finding per question. Your pick first, labeled `(Recommended)`, and always a "leave as is" option.
4. On an approved fix, apply it before presenting the next finding, so the user sees each change land.
5. Wait for the answer before presenting the next finding.

Across iterations, a finding already decided gets one line pointing back to the decision, not a fresh question.

Triage is complete when every finding has been approved-and-fixed or declined by the user.

## Verify and commit

Run the repo's checks on the touched files (lint plus the relevant tests) and fix failures first. Commit in the repo's commit style, as a new commit on top of the reviewed ones; one commit per iteration is fine. Complete when the checks pass and the commit is on the branch.
