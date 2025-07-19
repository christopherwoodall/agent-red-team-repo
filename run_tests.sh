#!/usr/bin/env bash
set -e

AGENT_CMD="$1"         # e.g. "python3 my_agent.py"
TEST_DIR="tests/cases"

for file in "$TEST_DIR"/*.yaml; do
  echo "▶ Running $(basename "$file")"
  # Use Python to parse YAML and run each test
  python3 - <<'PYCODE'
import sys, subprocess, yaml, re

agent = sys.argv[1]
for file in sys.argv[2:]:
    tests = yaml.safe_load(open(file))
    for t in tests:
        print(f"  • {t['id']}: {t['description']}… ", end='')
        # feed input to agent
        proc = subprocess.run(agent.split(), input=t['input'], text=True,
                              capture_output=True, timeout=10)
        out = proc.stdout.strip()
        typ = t['assertion']['type']
        exp = t['assertion']['expected']
        ok = False
        if typ == 'equals':
            ok = (out == exp)
        elif typ == 'contains':
            ok = (exp in out)
        elif typ == 'not_contains':
            ok = (exp not in out)
        elif typ == 'pattern':
            ok = bool(re.search(exp, out))
        if ok:
            print("PASS")
        else:
            print(f"FAIL (got: {out!r})")
            sys.exit(1)
print("✅ All tests passed.")
PYCODE
done "$AGENT_CMD" "$file"
