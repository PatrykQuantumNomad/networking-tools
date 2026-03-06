---
name: netsec-health
description: Check that all pentesting safety hooks are installed and working
disable-model-invocation: false
---

# Netsec Health Check

Run the safety architecture health check to verify all hooks are installed, registered, and functioning. The script auto-detects whether it is running in plugin context or in-repo context and adapts its checks accordingly.

## How to use

Detect context and run the health check script:

```bash
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  bash "${CLAUDE_PLUGIN_ROOT}/hooks/netsec-health.sh"
else
  bash .claude/hooks/netsec-health.sh
fi
```

For JSON output, pass `-j`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/netsec-health.sh" -j
```

Review the output and report results to the user. The script checks five categories:

1. **Hook Files** -- Whether the PreToolUse and PostToolUse hook scripts exist and are executable. In plugin context, checks `$CLAUDE_PLUGIN_ROOT/hooks/`. In-repo, checks `.claude/hooks/`.
2. **Hook Registration** -- Whether hooks are registered. In plugin context, checks `hooks.json`. In-repo, checks `.claude/settings.json`.
3. **Scope Configuration** -- Whether `.pentest/scope.json` exists with a valid targets array (same in both contexts).
4. **Audit Infrastructure** -- Whether the `.pentest/` directory exists, is writable, and is gitignored (same in both contexts).
5. **Dependencies** -- Whether `jq` is installed. Reports bash version for informational purposes (bash 4.0+ is no longer required).

## Interpreting failures

If any checks fail, explain what the failure means:

- **Hook files missing (plugin)**: The hook scripts are missing from the plugin's hooks directory. Reinstall the plugin.
- **Hook files missing (in-repo)**: The hook scripts need to be created at `.claude/hooks/`. This is unusual if the skill pack was installed correctly.
- **Hooks not executable (in-repo)**: Run `chmod +x .claude/hooks/netsec-pretool.sh .claude/hooks/netsec-posttool.sh`
- **Hooks not executable (plugin)**: Hook permissions are managed by the plugin system. Reinstall if this occurs.
- **Hooks not registered**: The hook configuration file is missing registrations. In plugin context, check `hooks.json`. In-repo, check `.claude/settings.json`.
- **Scope file missing**: No target scope is defined. All pentesting commands will be blocked until you create `.pentest/scope.json` with your allowed targets.
- **Audit directory issues**: The `.pentest/` directory needs to be created or is not writable.

If all checks pass, confirm to the user that the safety architecture is operational and all pentesting commands will be validated against the scope file.
