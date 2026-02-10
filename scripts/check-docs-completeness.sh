#!/usr/bin/env bash
# check-docs-completeness.sh -- Verify every tool script has a docs page
set -euo pipefail

SCRIPTS_DIR="scripts"
DOCS_DIR="site/src/content/docs/tools"
errors=0

for examples_sh in "$SCRIPTS_DIR"/*/examples.sh; do
  tool_dir=$(dirname "$examples_sh")
  tool_name=$(basename "$tool_dir")

  if [[ ! -f "$DOCS_DIR/${tool_name}.md" ]] && [[ ! -f "$DOCS_DIR/${tool_name}.mdx" ]]; then
    echo "ERROR: No docs page for scripts/${tool_name}/examples.sh"
    echo "  Expected: $DOCS_DIR/${tool_name}.md or $DOCS_DIR/${tool_name}.mdx"
    ((errors++)) || true
  fi
done

if [[ $errors -gt 0 ]]; then
  echo ""
  echo "FAILED: $errors tool(s) missing documentation pages"
  exit 1
else
  echo "OK: All $(ls "$SCRIPTS_DIR"/*/examples.sh | wc -l | tr -d ' ') tools have documentation pages"
fi
