#!/usr/bin/env bash
set -eo pipefail

# 1. Load config
CONFIG="config.yaml"
if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Missing $CONFIG"
  exit 1
fi

# 2. Extract settings via Python
read -r AGENT_CMD TIMEOUT TEST_DIR PATTERN WORKDIR <<<$(python3 - <<'PYCODE'
import yaml, shlex
cfg = yaml.safe_load(open("config.yaml"))
agent = cfg["agent"]
tests = cfg["tests"]

cmd   = agent["command"]
t_out = agent.get("timeout", 10)
tdir  = tests.get("directory", "tests/cases")
pat   = tests.get("pattern", "*.yaml")
wdir  = agent.get("working_dir", "")

# Ensure we output sensible defaults
print(shlex.join(cmd.split()), t_out, tdir, pat, wdir)
PYCODE
)

echo "▶ Running tests with:"
echo "   Agent cmd: $AGENT_CMD"
echo "   Timeout  : $TIMEOUT s"
echo "   Test dir : $TEST_DIR (pattern: $PATTERN)"
if [[ -n "$WORKDIR" ]]; then
  echo "   Workdir  : $WORKDIR"
fi
echo

# 3. Loop over each test file
for file in "$TEST_DIR"/$PATTERN; do
  echo "▶ Suite: $(basename "$file")"
  python3 - <<'PYCODE'
import sys, yaml, subprocess, re, os

agent_cmd, timeout, test_file, workdir = sys.argv[1:]

if workdir:
    os.chdir(workdir)

tests = yaml.safe_load(open(test_file))
for t in tests:
    tid  = t["id"]
    desc = t["description"]
    inp  = t["input"]
    typ  = t["assertion"]["type"]
    exp  = t["assertion"]["expected"]
    opts = t["assertion"].get("options", {})

    print(f"  • {tid}: {desc}… ", end="", flush=True)

    try:
        proc = subprocess.run(
            agent_cmd.split(),
            input=inp,
            text=True,
            capture_output=True,
            timeout=int(timeout)
        )
        out = proc.stdout.strip()
    except Exception as e:
        print(f"ERROR ({e})")
        sys.exit(1)

    # Normalize output for case-insensitive comparisons
    if opts.get("case_insensitive", False):
        out = out.lower()
        exp = exp.lower()

    # Check assertion type
    ok = False
    if typ == "equals":
        ok = (out == exp)
    elif typ == "contains":
        ok = (exp in out)
    elif typ == "not_contains":
        ok = (exp not in out)
    elif typ == "pattern":
        flags = re.IGNORECASE if opts.get("case_insensitive", False) else 0
        try:
            ok = bool(re.search(exp, out, flags))
        except re.error as err:
            print(f"Invalid regex: {err}")
            sys.exit(1)
    else:
        print(f"UNKNOWN_ASSERTION({typ})")
        sys.exit(1)

    if ok:
        print("PASS")
    else:
        print(f"FAIL — got: {out!r}")
        sys.exit(1)

print("  ✅ OK\n")
PYCODE
  -- "$AGENT_CMD" "$TIMEOUT" "$file" "$WORKDIR"
done

echo "🎉 All test suites passed."
