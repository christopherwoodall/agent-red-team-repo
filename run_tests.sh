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

# Read args from outer shell
agent_cmd, timeout, test_file, workdir = sys.argv[1:]

# Change working directory if specified
if workdir:
    os.chdir(workdir)

# Load the YAML tests
tests = yaml.safe_load(open(test_file))
for t in tests:
    tid  = t["id"]
    desc = t["description"]
    inp  = t["input"]
    typ  = t["assertion"]["type"]
    exp  = t["assertion"]["expected"]

    print(f"  • {tid}: {desc}… ", end="", flush=True)

    # Run the agent
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

    # Check assertion
    ok = False
    if typ == "equals":
        ok = (out == exp)
    elif typ == "contains":
        ok = (exp in out)
    elif typ == "not_contains":
        ok = (exp not in out)
    elif typ == "pattern":
        ok = bool(re.search(exp, out))
    else:
        print(f"UNKNOWN_ASSERTION({typ})")
        sys.exit(1)

    if ok:
        print("PASS")
    else:
        print(f"FAIL — got: {out!r}")
        sys.exit(1)

# All tests in this file passed
print("  ✅ OK\n")
PYCODE
  -- "$AGENT_CMD" "$TIMEOUT" "$file" "$WORKDIR"
done

echo "🎉 All test suites passed."
