# .opencode

My complete OpenCode agent setup: config, plugins, global skills, and custom
commands, with `setup.sh` to deploy everything on macOS or Linux.

## Layout

| Path | What it is | Deployed to |
| --- | --- | --- |
| `opencode.json` | OpenCode config: npm plugins | `~/.config/opencode/` |
| `cli.json` | CLI preferences (animations, thinking ticks) | `~/.config/opencode/` |
| `opencode-mem.jsonc` | `opencode-mem` memory config (API keys stay as `env://`) | `~/.config/opencode/` |
| `plugins/` | OpenCode plugin files | `~/.config/opencode/plugins/` |
| `skills/` | Global skills (source of truth) | `~/.agents/skills/` |
| `agents-commands/` | Custom agent commands | `~/.agents/commands/` |
| `setup.sh` | Deploys everything above | — |

`service.json` (per-user service state) and `plugins/tokeneconomizer.ts` (a
symlink created by setup) are gitignored.

## Setup (new machine)

```sh
git clone https://github.com/iamharshil/.opencode.git ~/.config/opencode
sh ~/.config/opencode/setup.sh
```

Then start `opencode`. Optional: `te --host opencode status` from any repo
shows the TokenEconomizer state (cloned and wired by setup.sh).

Updating later:

```sh
git -C ~/.config/opencode pull && sh ~/.config/opencode/setup.sh
```

## Notes

- Skills are plain directories with a `SKILL.md`; add one with
  `npx skills add <repo> --agent opencode --global --copy --yes`, move it into
  `skills/` here, and commit.
- `~/.config/opencode` being the working clone is intentional: `git pull`
  updates the live config directly, and the skills live files are the same
  directory as the repo checkout.
- Never commit: `auth.json`, `service.json`, real API keys, or dotfiles copy
  states. Secrets stay in the environment (`env://KEY_NAME` references).
