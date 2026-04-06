import os
import subprocess
import sys

PASS_TOKENS = [
    "PASS",
    "Passed",
    "Your Design Passed",
    "Your design passed",
    "===========Your Design Passed==========="
]

def run(cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr

def compile_with_icarus(design_file, testbench_file, out_exe="lab_sim"):
    cmd = ["iverilog", "-g2012", "-o", out_exe, design_file, testbench_file]
    rc, out, err = run(cmd)
    return rc == 0, (out + err)

def simulate_with_vvp(out_exe="lab_sim"):
    cmd = ["vvp", out_exe]
    rc, out, err = run(cmd)
    return rc == 0, (out + err)

def contains_pass(output):
    return any(tok in output for tok in PASS_TOKENS)

def grade(design_file, testbench_file):

    # Compile
    compiled, comp_msg = compile_with_icarus(design_file, testbench_file)
    if compiled:
        print("Compile: OK")
    else:
        print("Compile: FAIL")
        if comp_msg.strip():
            print(comp_msg.strip())
        return

    # Simulation
    sim_ok, sim_output = simulate_with_vvp()
    if sim_ok and contains_pass(sim_output):
        print("Simulation: PASS")
    else:
        print("Simulation: FAIL")
        if sim_output.strip():
            print(sim_output.strip())

    # Cleanup
    if os.path.exists("lab_sim"):
        os.remove("lab_sim")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 lab_grader.py <design.v> <testbench.v>")
        sys.exit(1)

    grade(sys.argv[1], sys.argv[2])