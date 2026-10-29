#!/bin/sh
# Deploy the opencode setup from this repository onto a new (or this) machine.
# Idempotent: safe to re-run. macOS and Linux (POSIX sh).
set -eu

REPO="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
AGENTS="$HOME/.agents"
OC="$HOME/.config/opencode"
TE_REPO="$HOME/.tokeneconomizer-repo"

echo "source   $REPO"
echo "agents   $AGENTS"
echo "opencode $OC"
echo

# 1. Skills (source of truth: repo skills/) -> ~/.agents/skills
#    ~/.agents/skills is the global skills dir read by opencode and `npx skills`.
mkdir -p "$AGENTS/skills"
cp -R "$REPO/skills/." "$AGENTS/skills/"

# 2. Commands -> ~/.agents/commands
mkdir -p "$AGENTS/commands"
cp -R "$REPO/agents-commands/." "$AGENTS/commands/"

# 3. If the repo is NOT already the live ~/.config/opencode, deploy config there.
#    (On the machine where the repo IS ~/.config/opencode this is a no-op.)
if [ "$REPO" != "$OC" ]; then
  mkdir -p "$OC/plugins"
  for f in opencode.json cli.json opencode-mem.jsonc; do
    [ -f "$REPO/$f" ] && cp "$REPO/$f" "$OC/$f"
  done
  if [ -d "$REPO/plugins" ]; then cp -R "$REPO/plugins/." "$OC/plugins/"; fi
fi

# 4. TokenEconomizer plugin (experimental opencode integration).
#    The clone must live on disk: the plugin resolves ../scripts relative to itself.
#    The `te` wrapper is the CLI the status/config commands run from a terminal.
#    Nothing here needs API keys: TE_* env vars and config live per-repo after first run.
if [ ! -d "$TE_REPO/.git" ]; then
  echo "cloning TokenEconomizer..."
  git clone --depth 1 https://github.com/microsoft/TokenEconomizer.git "$TE_REPO"
fi
mkdir -p "$OC/plugins" "$HOME/.tokeneconomizer/bin"
ln -sf "$TE_REPO/plugin/opencode/tokeneconomizer.ts" "$OC/plugins/tokeneconomizer.ts"
printf '#!/bin/sh\nexec sh %s/plugin/scripts/te "$@"\n' "$TE_REPO" > "$HOME/.tokeneconomizer/bin/te"
chmod +x "$HOME/.tokeneconomizer/bin/te"

# 5. Verify
echo
echo "ok: $(find "$AGENTS/skills" -name SKILL.md | wc -l | tr -d ' ') skills deployed"
echo "ok: commands deployed"
[ -L "$OC/plugins/tokeneconomizer.ts" ] && echo "ok: tokeneconomizer plugin linked"
[ -x "$HOME/.tokeneconomizer/bin/te" ] && echo "ok: te CLI at ~/.tokeneconomizer/bin/te"
echo
echo "Next: start opencode; run 'te --host opencode status' from any repo to see it."
