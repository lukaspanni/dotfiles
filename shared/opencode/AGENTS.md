# AGENTS.MD

Work style: telegraph; noun-phrases ok; drop grammar; min tokens.

## Agent Protocol

- Focused, early commits
- New features on new branches
- New deps: quick health check (recent releases/commits, adoption)

## Flow & Runtime
- Use repo's package manager/runtime
- Follow existing patterns

## Build / Test
Before handoff: run full gate (lint/typecheck/tests) see repo docs for how to run

## Git
- Big review: `git --no-pager diff --color=never`.
- Multi-agent: check `git status/diff` before commiting

## Critical Thinking
- Fix root cause (not band-aid)
- Unsure: read more code; if still stuck, ask
- Conflicts: call out; pick safer path
- Unrecognized changes: assume other agent or user; keep going; focus your changes. If it causes issues, stop + ask user

## Frontend aesthetics
Avoid "AI slop" UI. Be opinionated + distinctive.
