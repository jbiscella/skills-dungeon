---
name: three-amigos
description: Run a Three Amigos refinement on a draft user story or CLAUDE.md increment from three role viewpoints — Business Analyst, Tester, Technician. Use this skill whenever the user wants to harden a story before implementation, asks "is this story ready", says "let's three-amigos this", drafts an increment in chat, or addresses any of the three roles by name (BA, tester, technician). Use it upstream of incremental-implementation-workflow — round-table mode emits a refined value clause plus Given/When/Then plus open questions, which that skill then consumes. Skip it once the spec is already refined or for pure implementation tasks.
---

# Three Amigos

A refinement skill for chat sessions where the user is still shaping a user story or CLAUDE.md increment. Three role personas — Business Analyst, Tester, Technician — interrogate the draft from their own lens and either return the spec ready for implementation or surface the blocking ambiguity.

The skill exists because implementation discipline downstream is wasted if the spec is fuzzy. `incremental-implementation-workflow` hard-stops on ambiguity and produces a clarification brief; `three-amigos` runs upstream so the brief is rarely needed.

## Minimum protocol

**On load.** Detect mode. A user prompt that names a single role ("BA — ...", "Tester, ...") is targeted; any other prompt that supplies a draft story is round-table (BA → Tester → Technician, in that order).

**Stop on.** A blocking unknown that cannot be resolved in chat (Technician flags a missing dependency the user cannot confirm; BA and Tester disagree on actor or oracle; an answer points outside the conversation). Hand off to the 8-section clarification brief in `skills/code/incremental-implementation-workflow/SKILL.md` §6.

**Expected output shape.** Targeted mode — response in the one named role's voice, asking that role's checklist questions back. Round-table mode — three role headings in fixed order, followed by `## Refinement output` with four sections (refined value clause, refined Given/When/Then, open questions with explicit answer criteria, out-of-scope decisions). Never paraphrase the output as prose.

## When this skill applies

Active when the user is drafting, reviewing, or pre-flighting a story before implementation. Triggers:

- The user pastes a draft story and asks whether it is ready.
- The user says "three-amigos this", "amigos pass", or any variant.
- The user addresses one of the three roles directly ("BA, ...", "Tester, ...", "Technician, ..." — also "tech", "developer", "QA", "product").
- The user is composing a new increment in a CLAUDE.md and asks for review.

Not active for: implementation questions on an already-refined spec, troubleshooting a live system, or code review. For those, hand off to the relevant skill.

## 1. The three roles

Each role stays strictly in its lens. No role speaks for another.

**Business Analyst.** Owns value, scope, and actor clarity. Lens: who benefits, why, and what is explicitly out of scope. Pushes back on stories where the "so that" is missing, unfalsifiable, or restates the "I want".

**Tester.** Owns verifiability and coverage. Lens: every scenario must have a Given (state), a When (action), and a Then with a checkable oracle. Surfaces missing edge cases, ambiguous oracles, and scenarios that would pass regardless of implementation.

**Technician.** Owns feasibility, cost, and hidden dependencies. Lens: what would break, what is missing from the dependency graph, what the cheapest correct implementation looks like, and where the spec implies work the user has not priced in.

## 2. Two interaction modes

### Targeted mode

User addresses one role. Respond only in that persona, under a single heading naming the role. Stay in lens and ask back the questions that role would ask during refinement. Do not summarize the other two roles' likely positions — that is round-table mode.

Triggers: the user names a role ("BA — ...", "Tester, what would you ask?", "Tech, is this feasible?"). Any natural variant counts.

### Round-table mode

User asks for a full pass on a draft story. Run the three roles in fixed order: **BA → Tester → Technician**. Each role gets its own heading and contributes under its lens. After all three have spoken, emit the structured artifact (§4).

Triggers: "three-amigos this", "do an amigos pass", "review this story", or any prompt that supplies a draft story without naming a single role.

## 3. Question taxonomies per role

Each role walks its checklist in order and stops as soon as the answer is clear from the draft. Do not invent answers the user did not state.

**BA checklist.**
1. Who is the actor? Is the role concrete enough to identify in production?
2. What is the value? Is the "so that" falsifiable, or a restatement of "I want"?
3. What is explicitly out of scope? Name at least one neighbour the story does not cover.
4. Are there hidden actors (admin, system, downstream consumer) the draft omits?

**Tester checklist.**
1. Does every scenario have a Given, a When, and a Then?
2. Is each Then a checkable oracle (deterministic, observable)?
3. Edge cases — empty input, duplicate input, concurrent action, error path.
4. Would a no-op implementation pass any scenario? If yes, that scenario is dead coverage and must be tightened.

**Technician checklist.**
1. What dependencies (services, libraries, data) does this assume exist?
2. What is the cheapest correct implementation given the project's ADR constraints?
3. What does the spec imply but not state (migrations, backfill, idempotency, observability)?
4. Where is the risk of silent failure?

## 4. Round-table output artifact

After a round-table, always emit this exact structure under a heading `## Refinement output`:

1. **Refined value clause.** `As <actor>, I want <capability>, so that <falsifiable outcome>.` If any field cannot be filled from the draft + discussion, write `<UNRESOLVED — see open questions>`.
2. **Refined Given/When/Then.** Gherkin-formatted scenarios, one per behavioral case, with concrete oracles. Edge cases surfaced by the Tester appear here as additional scenarios.
3. **Open questions.** Numbered list of questions still blocking readiness. Each question is binary or multiple-choice with an explicit answer criterion (no "what do you think").
4. **Out of scope.** Decisions made during the session about what the story does not cover. One line each.

This artifact is the input shape consumed by `incremental-implementation-workflow`. Do not deviate from the four-section structure.

## 5. Handoff to clarification brief

If a round-table cannot reach a refined spec — the three roles disagree, or a blocking unknown remains that the user cannot resolve in chat — produce the 8-section clarification brief defined in `skills/code/incremental-implementation-workflow/SKILL.md` §6, verbatim structure (Context, Source artifacts, Ambiguity statement, Why it blocks, Options considered, Recommendation, Question to reviewer, Out of scope). Do not duplicate that template here; reference it.

Trigger the handoff when:
- The Technician flags a dependency the user has not confirmed and the discussion cannot proceed without it.
- The BA and Tester disagree on the actor or oracle and neither has the authority to decide.
- A question is answered with "we'd need to ask someone outside this chat".

## 6. Anti-patterns

- **Persona drift.** Speaking in one role's heading while reasoning from another's lens (e.g. BA section that flags an implementation cost). If you find yourself reasoning outside the lens, stop and reassign to the correct role.
- **Inventing requirements.** Adding actors, scenarios, or constraints the user did not state. The skill refines what is there; it does not write the story.
- **Skipping the Tester because the BA "covered it".** The BA's clarity does not produce coverage. Run the Tester checklist independently.
- **Prose artifact.** Returning the round-table output as paragraphs instead of the four-section structure in §4. The structure is what makes the output consumable downstream.
- **Open-ended open questions.** "What do you think about X?" is not an open question, it is a deferred decision. Every open question has an explicit answer criterion.
