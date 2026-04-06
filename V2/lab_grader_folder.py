import os
import subprocess

PASS_TOKENS = ["PASS", "Pass", "passed"]


def run(cmd, timeout=5):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout + p.stderr, False
    except subprocess.TimeoutExpired as e:
        out = ""
        if e.stdout:
            out += e.stdout
        if e.stderr:
            out += e.stderr
        return -1, out, True


def contains_pass(output):
    return any(tok in output for tok in PASS_TOKENS)


def cleanup():
    if os.path.exists("sim.out"):
        try:
            os.remove("sim.out")
        except:
            pass


def test_design(design, tb):
    result = {
        "name": design,
        "compile": "",
        "simulation": "",
        "message": ""
    }

    # Compile
    rc, out, timed_out = run(["iverilog", "-g2012", "-o", "sim.out", design, tb], timeout=5)
    if timed_out:
        result["compile"] = "FAIL"
        result["simulation"] = "NOT RUN"
        result["message"] = "Compile timeout"
        cleanup()
        return result

    if rc != 0:
        result["compile"] = "FAIL"
        result["simulation"] = "NOT RUN"
        result["message"] = out.strip()
        cleanup()
        return result

    result["compile"] = "OK"

    # Simulation
    rc, sim_out, timed_out = run(["vvp", "sim.out"], timeout=5)
    if timed_out:
        result["simulation"] = "FAIL (Endless loop probability)"
        result["message"] = sim_out.strip() if sim_out.strip() else "No output before timeout."
        cleanup()
        return result

    if contains_pass(sim_out):
        result["simulation"] = "PASS"
    else:
        result["simulation"] = "FAIL"
        result["message"] = sim_out.strip()

    cleanup()
    return result


def main():
    files = os.listdir(".")
    v_files = sorted([f for f in files if f.endswith(".v")])
    tb_files = sorted([f for f in files if f.endswith(".tb")])

    total_v = len(v_files)
    total_tb = len(tb_files)

    passed_list = []
    failed_list = []
    skipped_list = []

    for design in v_files:
        name = os.path.splitext(design)[0]
        tb = name + ".tb"
        if not os.path.exists(tb):
            skipped_list.append(design)
            continue

        result = test_design(design, tb)

        print(f"{design}")
        print(f"  Compile:    {result['compile']}")
        print(f"  Simulation: {result['simulation']}")
        if result["message"]:
            print("  Message:")
            print(result["message"])
        print("-" * 50)

        if result["compile"] == "OK" and result["simulation"] == "PASS":
            passed_list.append(design)
        else:
            failed_list.append((design, result["message"]))

    # --- Detailed Lists ---
    print("\nPASSED FILES")
    print("-" * 50)
    if passed_list:
        for f in passed_list:
            print(f"  {f}")
    else:
        print("  None")

    print("\nFAILED FILES")
    print("-" * 50)
    if failed_list:
        for f, msg in failed_list:
            print(f"  {f}")
            if msg:
                print(f"    Message: {msg[:120]}")
    else:
        print("  None")

    if skipped_list:
        print("\nSKIPPED (no .tb found)")
        print("-" * 50)
        for f in skipped_list:
            print(f"  {f}")

    # --- Summary Report ---
    tested = len(passed_list) + len(failed_list)
    print("\n" + "=" * 50)
    print("  SUMMARY REPORT")
    print("=" * 50)
    print(f"  .v  files found : {total_v}")
    print(f"  .tb files found : {total_tb}")
    print(f"  Tested          : {tested}")
    print(f"  Skipped (no tb) : {len(skipped_list)}")
    print(f"  Passed          : {len(passed_list)}")
    print(f"  Failed          : {len(failed_list)}")
    if tested > 0:
        rate = len(passed_list) / tested * 100
        print(f"  Pass rate       : {rate:.1f}%")
    else:
        print(f"  Pass rate       : N/A")
    print("=" * 50)


if __name__ == "__main__":
    main()