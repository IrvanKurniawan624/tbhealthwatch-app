# Warp AI Rules — Synapse Project

This project uses Synapse for multi-agent coordination. The following rules apply when you're assisting in any terminal pane.

## .context/ Structure

- `.context/core/` — shared rules and conventions (read-only during work)
- `.context/agents/<id>.md` — per-agent role definition
- `.context/state/TASKS.md` — live task list; each task has an `Owner:` field
- `.context/state/HANDOFF.md` — append-only handoff log (most recent entry = current baton)
- `.context/state/DECISIONS.md` — append-only decision log
- `.context/state/locks/` — task ownership lock files

## Key Commands

| Command | When to use |
| ------- | ----------- |
| `synapse claim <id>` | Before editing files for a task |
| `synapse handoff` | After completing or blocking on a task |
| `synapse ship` | When task is done and ready to push |
| `synapse status` | Check who owns what |
| `synapse doctor` | Validate .context/ health |

## Coordination Rules

1. Check `Owner:` in TASKS.md before working on any task.
2. Run `synapse claim` before editing — this creates a lock file.
3. Run `synapse handoff` when done — this appends to HANDOFF.md.
4. `synapse ship` commits + pushes + opens a PR. It runs a hygiene check before pushing.
