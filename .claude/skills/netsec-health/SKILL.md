---
name: netsec-health
description: Check that all pentesting safety hooks are installed and working
disable-model-invocation: false
---

# Netsec Health Check

Run the safety architecture health check to verify all hooks are installed, registered, and functioning.

## How to use

Run the health check script:

```bash
bash .claude/hooks/netsec-health.sh
```

Review the output and report results to the user. The script checks five categories:

1. **Hook Files** -- Whether the PreToolUse and PostToolUse hook scripts exist and are executable
2. **Hook Registration** -- Whether hooks are registered in `.claude/settings.json`
3. **Scope Configuration** -- Whether `.pentest/scope.json` exists with a valid targets array
4. **Audit Infrastructure** -- Whether the `.pentest/` directory exists, is writable, and is gitignored
5. **Dependencies** -- Whether `jq` is installed and bash version supports associative arrays

## Interpreting failures

If any checks fail, explain what the failure means:

- **Hook files missing**: The hook scripts need to be created. This is unusual if the skill pack was installed correctly.
- **Hooks not executable**: Run `chmod +x .claude/hooks/netsec-pretool.sh .claude/hooks/netsec-posttool.sh`
- **Hooks not registered**: The `.claude/settings.json` file is missing hook registrations.
- **Scope file missing**: No target scope is defined. All pentesting commands will be blocked until you create `.pentest/scope.json` with your allowed targets.
- **Audit directory issues**: The `.pentest/` directory needs to be created or is not writable.

If all checks pass, confirm to the user that the safety architecture is operational and all pentesting commands will be validated against the scope file.
