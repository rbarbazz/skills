---
name: stepwise
description: "Implement a ticket, spec, or plan one commit at a time as a walkthrough: announce each step, build it, hand over a digest instead of a diff, so the user understands the final diff without re-reading it."
disable-model-invocation: true
---

# Stepwise

Implement a ticket, spec, or plan as a sequence of small commits, and walk the user through each one as it lands. The goal of the run is the user's understanding: by the last commit the user knows what the diff does and why, and reads the final diff to confirm rather than to discover. Every step is announced before it is built and handed over as a **digest**, a few targeted hunks with the reasoning around them, instead of a diff.

## Input

The work is the argument: a Linear ticket (`IPOD-123`), a spec or plan file path, or the plan already in the conversation. With none, ask for one. Read the work and every file it names before slicing.
## 1. Slice

Cut the work into **steps**. A step is one idea the user can hold in their head, landed as one commit: the tree works after it, its tests pass, and it reads on its own. Two hundred generated lines of migration is one idea; forty lines that touch three concepts is three steps. Order steps the way `~/.claude/docs/git-and-prs.md` orders commits.

Present the slicing as a numbered list headed by the ticket or spec title, one line per step: what it changes and the files it touches. Name the concepts the run introduces (the domain nouns and the pieces being built) in this list, and use the same names in every proposal and digest after: the user's mental model builds on stable names. Then stop and wait. The user merges, splits, reorders, or drops steps in chat. Slicing is complete when the user says go on the list.

The list stays live: when a step teaches something that changes the later steps, re-present the remaining list and wait for go again.

## 2. Loop over steps

### a. Propose

Before any edit, five lines at most, so the user knows what is coming before the diff exists:

- **Goal**: what works after this step that does not work now.
- **Approach**: how, in one sentence.
- **Decisions**: each point where a reasonable engineer could pick differently, the pick, and the alternative set aside. Skip the line when there is none.
- **Files**: the files to touch.
- **Proof**: the test or command that shows the step works, and the seam it tests at.

Ask with AskUserQuestion: `Clear, build it (Recommended)`, `Explain something first`, `Change the approach`. On "explain", answer from the code and the plan, then ask again. On "change", take the user's direction and propose again. Building starts on "Clear, build it".

### b. Build

Implement the step as proposed, running the `mattpocock-skills:tdd` loop at the seam named under Proof. Anything discovered outside the step (a bug nearby, a refactor that begs, a missing test elsewhere) goes on the **parking lot**, a list carried through the run, and the step stays on its goal.

Build is complete when lint, typecheck, and the step's tests pass and the diff touches only the files named under Files. A file the step turns out to need goes into the digest's Decisions, with why.

### c. Hand over

Send the digest, on this template:

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
- `<path>:<line>`: <what this hunk shows that the rest of the digest cannot, one line>

**Checks**: <lint, typecheck, and tests run, and the result>
**Parking lot**: <items added this step>. Or: none.
```

"Worth reading" is the whole reading list, one to three hunks: what the user must see to understand the commit (the core logic, and anything under Decisions or Hesitations). The user opens the rest of the diff when they want it.

Then wait. The user asks questions, requests changes, or says commit. Answer questions from the code, with `file:line`. A question marks a spot the digest missed: cover that kind of point up front in the digests that follow. Apply requested changes, re-run the checks, and send a short delta (what changed since the last digest) instead of a full digest. Hand-over is complete when the user says commit.

### d. Commit

Stage only the files this step touched, by path (`git add -- PATH...`), and commit in the repo's commit style. Return to 2a for the next step.

## 3. Close

After the last commit, run every test file that exercises code the run changed. Then read the ticket (or the spec or plan when there is none) and map every requirement to a commit. A requirement with no commit is a **gap**.

Then report:

- the list of commits (`git log --oneline` for the run);
- a **reading order** for the final diff: which commit to read first and which file to open in each, three lines at most;
- the gaps and the parking lot, with a one-line recommendation per item (a follow-up step now, a ticket, or drop);
- the run's base commit (the parent of the first commit), as the fixed point for `mattpocock-skills:code-review` in a fresh session.

Stop.
