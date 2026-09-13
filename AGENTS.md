# eva_arch project context

This repository is Gary's dotfiles for CachyOS/Arch Linux and Windows 11, with `/home/aris` itself as the Git worktree. Everything under `$HOME` that is not explicitly tracked is a user file, not repository content.

## Ignore rules

- There is intentionally **no `.gitignore` in the home directory**. It would defeat `rg`/`fd` gitignore-aware traversal for the whole home tree. Do not recreate one.
- `.eva.gitignore` is the only ignore file, wired via `git config core.excludesFile .eva.gitignore` (see `README.md`). It is a whitelist: `/*` ignores everything, then `!` entries opt files and directories back in. Nested directories follow the same pattern (`!dir`, `dir/*`, `!dir/file`).
- To track a new file, add the matching `!` entries to `.eva.gitignore` in the relevant section instead of using `git add -f`. To ignore a file inside a tracked directory, add a plain pattern next to that directory's entries (for example `.claude/settings.local.json`).
- Verify with `git check-ignore -v <path>` and `git status --short` before committing.

## Layout

- `.config/`: per-application configs (`hypr`, `kanata`, `kitty`, `tmux`, `win11`, `DankMaterialShell` plugins, `scripts`, ...). Only the whitelisted subdirectories are tracked.
- `bin/`: tracked user scripts, including the Wallpaper Engine entry points. `.local/bin` is untracked.
- `wiki/`: the LLM Wiki (public, sourced knowledge only).
- `.claude/CLAUDE.md` and `.codex/AGENTS.md`: tracked agent instructions; the rest of `.claude/` and `.codex/` is local state and stays ignored.
- `README.md` holds the bootstrap procedure and screenshots.

## Working rules

- Make targeted changes; preserve unrelated user files and the existing dotfile/symlink layout.
- Do not run the destructive bootstrap commands from `README.md` (`rm -fr .git`, `git reset --hard`) unless Gary explicitly requests a reinstall.
- Never use blanket clean/reset operations (`git clean`, `git checkout .`, `git stash -u`) against the home worktree.
- Use `trash-put` instead of `rm` for files that must be removed from the working tree.
- Commit messages follow Conventional Commits with a component scope, e.g. `fix(hyprland): ...`, `feat(win11): ...`.
- Pre-commit hooks (`.pre-commit-config.yaml`) enforce symlink checks, whitespace, Black/Ruff for Python, and `commit-msg` checks; run `pre-commit run --files <changed>` before committing.
- Validate the affected configuration (reload Hyprland, kanata, tmux, etc.) and report the resulting Git diff and uncommitted state.
- Global EVA persona, memory, and skills are runtime context, not project rules.
