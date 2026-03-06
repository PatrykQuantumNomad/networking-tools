---
name: scope
description: Define and manage target scope for pentesting engagements
argument-hint: "<add|remove|show|clear|init> [target]"
disable-model-invocation: true
---

# Scope Management

Manage the target scope file at `.pentest/scope.json`. All pentesting commands validate targets against this file via the PreToolUse hook.

## How to use

Parse the first argument from $ARGUMENTS to determine the operation. Remaining arguments are the target(s).

Detect context and run the portable scope script:

```bash
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/netsec-scope.sh" <operation> [target]
else
  bash netsec-skills/scripts/netsec-scope.sh <operation> [target]
fi
```

## Operations

### show (default)

Display the current scope. This is the default when no operation is specified.

```bash
netsec-scope.sh show
```

### add <target>

Always confirm with the user first before modifying the scope file.

Example confirmation: "Add [target] to the scope in `.pentest/scope.json`? (yes/no)"

Only proceed after the user confirms. Then add the target:

```bash
netsec-scope.sh add TARGET
```

Show the updated scope after adding.

### remove <target>

Always confirm with the user first before modifying the scope file.

Example confirmation: "Remove [target] from the scope in `.pentest/scope.json`? (yes/no)"

Only proceed after the user confirms. Then remove the target:

```bash
netsec-scope.sh remove TARGET
```

Show the updated scope after removing.

### init

Create the scope file with safe default targets:

```bash
netsec-scope.sh init
```

Show the created scope file and explain that targets must be in this file before pentesting commands will execute.

### clear

Always confirm with the user first before modifying the scope file.

Example confirmation: "Clear all targets from `.pentest/scope.json`? This will block all pentesting commands until new targets are added. (yes/no)"

Only proceed after the user confirms. Then reset the scope:

```bash
netsec-scope.sh clear
```

Show the cleared scope and remind the user to add targets before running pentesting commands.

## Important

- Always confirm with the user before modifying scope (add, remove, clear)
- Default safe targets: localhost, 127.0.0.1
- Lab targets to suggest adding: localhost (covers all lab ports on 8080, 3030, 8888, 8180)
- The `.pentest/` directory is gitignored
- Scope file format: `{"targets": ["target1", "target2"]}`
