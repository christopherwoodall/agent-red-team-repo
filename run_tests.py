#!/usr/bin/env python3
import subprocess
import sys
import os
import yaml
import glob
import re
import shlex

# === Load config ===
cfg_path = "config.yaml"
if not os.path.isfile(cfg_path):
    print(f"❌ Missing {cfg_path}")
    sys.exit(1)

with open(cfg_path) as f:
    cfg = yaml.safe_load(f)

agent_template = cfg["agent"]["command"]  # e.g.: 'source-agent --prompt "{prompt}"'
timeout = cfg["agent"].get("timeout", 10)
workdir = cfg["agent"].get("working_dir")

test_dir = cfg["tests"]["directory"]
pattern = cfg["tests"]["pattern"]

print("▶ Running tests with:")
print(f"  Agent cmd template: {agent_template}")
print(f"  Timeout           : {timeout} s")
print(f"  Test dir          : {test_dir} (pattern: {pattern})")
if workdir:
    print(f"  Workdir           : {workdir}")
print()

# === Discover and run tests ===
yaml_files = glob.glob(os.path.join(test_dir, pattern))
if not yaml_files:
    print(f"❗ No test files found in {test_dir}/{pattern}")
    sys.exit(1)

for path in yaml_files:
    print(f"▶ Suite: {os.path.basename(path)}")
    tests = yaml.safe_load(open(path))

    for t in tests:
        tid = t["id"]
        desc = t.get("description", "")
        inp = t.get("input", "")
        assertion = t["assertion"]
        typ = assertion["type"]
        exp = assertion["expected"]
        opts = assertion.get("options", {})

        print(f"  • {tid}: {desc}… ", end="", flush=True)

        # Construct command by injecting prompt input
        escaped_prompt = inp.replace('"', '\\"')
        command_str = agent_template.replace("{prompt}", escaped_prompt)
        cmd = shlex.split(command_str)

        # Run agent
        proc = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=timeout,
            cwd=workdir or None
        )
        out = proc.stdout.strip()

        # Optionally normalize
        if opts.get("case_insensitive"):
            out_cmp, exp_cmp = out.lower(), exp.lower()
        else:
            out_cmp, exp_cmp = out, exp

        # Assertion checks
        if typ == "equals":
            ok = (out_cmp == exp_cmp)
        elif typ == "contains":
            ok = (exp_cmp in out_cmp)
        elif typ == "not_contains":
            ok = (exp_cmp not in out_cmp)
        elif typ == "pattern":
            flags = re.IGNORECASE if opts.get("case_insensitive") else 0
            ok = bool(re.search(exp, out, flags))
        else:
            raise ValueError(f"UNKNOWN_ASSERTION({typ})")

        if ok:
            print("PASS")
        else:
            print(f"FAIL — got: {out!r}")
            sys.exit(1)

    print("  ✅ OK\n")

print("🎉 All test suites passed.")
