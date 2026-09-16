---
name: stepwise
description: "Implement a ticket, spec, or plan one commit at a time: propose each step, build it, hand over a digest instead of a diff, commit on the user's go."
disable-model-invocation: true
---

# Stepwise

Implement a ticket, spec, or plan as a sequence of small commits, the user steering between each one. The user outsources the typing and keeps the decisions: every step is approved before it is built and every commit before it lands. Each hand-over is a **digest**, so the user reads a few targeted hunks and asks questions instead of re-reading a whole diff.

## Input

The work is the argument: a ticket in full form (`owner/repo#42` or the URL), a spec or plan file path, or the plan already in the conversation. With none, ask for one. Read the work and every file it names before slicing.

## 1. Slice

Cut the work into **steps**. A step is one commit: the tree works after it, its tests pass, and it reads on its own. Order steps the way `~/.claude/docs/git-and-prs.md` orders commits. Aim for steps under about 150 changed lines: a step that would grow past that is two steps.

Present the slicing as a numbered list headed by the ticket or spec title, one line per step: what it changes and the files it touches. Then stop and wait. The user merges, splits, reorders, or drops steps in chat. Slicing is complete when the user says go on the list.

The list stays live: when a step teaches something that changes the later steps, re-present the remaining list and wait for go again.

## 2. Loop over steps

### a. Propose

Before any edit, five lines at most:

- **Goal**: what works after this step that does not work now.
- **Approach**: how, in one sentence.
- **Decisions**: each point where a reasonable engineer could pick differently, the pick, and the alternative set aside. Skip the line when there is none.
- **Files**: the files to touch.
- **Proof**: the test or command that shows the step works, and the seam it tests at.

Ask with AskUserQuestion: `Go (Recommended)`, `Change the approach`, `Skip this step`. On "change", take the user's direction and propose again. Building starts only on Go.

### b. Build

Implement the step as proposed, running the `mattpocock-skills:tdd` loop at the seam named under Proof. Anything discovered outside the step (a bug nearby, a refactor that begs, a missing test elsewhere) goes on the **parking lot**, a list carried through the run, and the step stays on its goal.

Build is complete when lint, typecheck, and the step's tests pass and the diff touches only the files named under Files. A file the step turns out to need goes into the digest's Decisions, with why.

### c. Hand over

Send the digest, on this template, in the user's reply style:

```markdown
## Step <n>/<total>: <title>

<one sentence: what works now that did not before>

| File | Change |
|------|--------|
| `<path>` | <what it does now, one sentence, behavior not mechanism> |

**Decisions**
- <where it could have gone another way: the pick and why, one or two sentences>

**Hesitations**
- <where confidence is low, and what would confirm it>. Or: none.

**Worth reading**
- `<path>:<line>`: <why this hunk deserves eyes, one line>

**Checks**: <lint and tests run, and the result>
**Parking lot**: <items added this step>. Or: none.
```

"Worth reading" is the whole reading list, one to three hunks: the core logic, and anything under Decisions or Hesitations. The user opens the rest of the diff when they want it.

Then wait. The user asks questions, requests changes, or says commit. Answer questions from the code, with `file:line`. Apply requested changes, re-run the checks, and send a short delta (what changed since the last digest) instead of a full digest. Hand-over is complete when the user says commit.

### d. Commit

Stage only the files this step touched, by path (`git add -- PATH...`), and commit in the repo's commit style. Return to 2a for the next step.

## 3. Close

After the last commit, run the full test suite once. Then read the ticket (or the spec or plan when there is none) and map every requirement to a commit. A requirement with no commit is a **gap**.

Then report: the list of commits (`git log --oneline` for the run), the gaps and the parking lot with a one-line recommendation per item (a follow-up step now, a ticket, or drop), and the run's base commit (the parent of the first commit), as the fixed point for `mattpocock-skills:code-review` in a fresh session. Stop.
