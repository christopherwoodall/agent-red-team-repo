#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["PyYAML"]
# ///
import subprocess
import sys
import os
import yaml
import glob
import re

# === Load config ===
cfg_path = "config.yaml"
if not os.path.isfile(cfg_path):
    print(f"❌ Missing {cfg_path}")
    sys.exit(1)

with open(cfg_path) as f:
    cfg = yaml.safe_load(f)

agent_cmd = cfg["agent"]["command"]
timeout = cfg["agent"].get("timeout", 10)
workdir = cfg["agent"].get("working_dir")

test_dir = cfg["tests"]["directory"]
pattern = cfg["tests"]["pattern"]

print("▶ Running tests with:")
print(f"  Agent cmd: {agent_cmd}")
print(f"  Timeout  : {timeout} s")
print(f"  Test dir : {test_dir} (pattern: {pattern})")
if workdir:
    print(f"  Workdir  : {workdir}")
print()

# === Discover and run tests ===
yaml_files = glob.glob(os.path.join(test_dir, pattern))
if not yaml_files:
    print(f"❗ No test files found in {test_dir}/{pattern}")
    sys.exit(1)

for path in yaml_files:
    suite_name = os.path.basename(path)
    print(f"▶ Suite: {suite_name}")
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

        # Handle different assertion types
        if typ in ["latency_lt", "throughput_gt", "memory_lt", "cpu_lt"]:
            # Performance tests - skip for now as they need special handling
            print("SKIP (performance test)")
            continue

        # Build command properly
        cmd_parts = agent_cmd.format(prompt=inp).split()
        
        try:
            proc = subprocess.run(
                cmd_parts,
                text=True,
                capture_output=True,
                timeout=timeout,
                cwd=workdir or None
            )
            out = proc.stdout.strip()
        except subprocess.TimeoutExpired:
            print("FAIL — timeout")
            sys.exit(1)
        except Exception as e:
            print(f"FAIL — error: {e}")
            sys.exit(1)

        if opts.get("case_insensitive"):
            out_cmp = out.lower()
            exp_cmp = str(exp).lower()
        else:
            out_cmp = out
            exp_cmp = str(exp)

        ok = False
        if typ == "equals":
            ok = (out_cmp == exp_cmp)
        elif typ == "contains":
            ok = (exp_cmp in out_cmp)
        elif typ == "not_contains":
            ok = (exp_cmp not in out_cmp)
        elif typ == "pattern":
            flags = re.IGNORECASE if opts.get("case_insensitive") else 0
            ok = bool(re.search(str(exp), out, flags))
        else:
            print(f"FAIL — unknown assertion type: {typ}")
            sys.exit(1)

        if ok:
            print("PASS")
        else:
            print(f"FAIL — got: {out!r}, expected: {exp!r}")
            sys.exit(1)

    print("  ✅ OK\n")

print("🎉 All test suites passed.")