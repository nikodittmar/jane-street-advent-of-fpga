import shutil
import os
import sys
import re

expected_inst_counts = [3888195, 12628457, 1614288]
cpi_test_names = ["bdd", "mmult", "fpmmult"]

def in_range(val, correct, threshold):
  return (correct - threshold) <= val and val <= (correct + threshold)

def output_test_results(base, verbose=False):
    test_results = {}
    with open(f"{base}/run_all_sims_result.txt") as f:
        lines = f.readlines()
        i = 0
        while i < len(lines)-1:
            line = lines[i]
            # Check if line matches "Running make [NAME]:"
            match = re.search(r"Running make (\S+): (\S+)", line)
            if match:
                test_name = match.group(1)
                # Look ahead for Passed or Failed in the following lines
                test_results[test_name] = match.group(2) == "Passed"
            if verbose:
                print(line, end='')
            i += 1
        return test_results, lines[-1] == "All tests passed!"

def output_fom_results(fom_file, verbose=False):
    errors = ""
    lines = {
        "fmax": "Fmax: ",
        "integer_cpi": "Integer CPI: ",
        "fp_cpi": "Floating Point CPI: ",
        "cost": "Cost: ",
        "fom": "FOM: "
    }
    data = dict()
    inst_count_num = 0
    with open(fom_file) as f:
        for line in f:
            if "Please report to TA" in line:
                errors = f"{line[:-2]}, "
            if "ERROR: Negative slack. Timing violated" in line:
                errors = f"{errors}Design has negative slack, "
            if "Timeout" in line:
                errors = f"{errors}CPI tests timed out, "
            if "Error: Integer" in line or "Error: Floating" in line:
                errors = f"{errors}Instruction counter does not match expected results, "
            if line.startswith("Instruction Count: "):
                cc = int(line[len("Instruction Count: "):-1], 16)
                if not in_range(cc, expected_inst_counts[inst_count_num], 5):
                    errors = f"{errors}Instruction count does not match expected results for {cpi_test_names[inst_count_num]} (got {hex(cc)}, expected {hex(expected_inst_counts[inst_count_num])}), "
                inst_count_num += 1
            for k in lines:
                if line.startswith(lines[k]):
                    data[k] = float(line[len(lines[k]):])
    if "fom" not in data:
        errors = f"{errors}FOM was not found, one of the previous steps is failing, "
    else:
        if verbose:
            for k in data:
                print(f"{lines[k]}{data[k]}")
    if len(errors) == 0:
        return (data, False)
    else:
        errors = errors[:-2]
        if verbose:
            print(f"ERRORS: {errors}")
        return (data, errors)
    

if __name__ == "__main__":

    _, errors = output_test_results("./submission", verbose=True)

    errors = errors or output_fom_results("./submission/fom.txt", verbose=True)[1]

    if errors:
        print("WARNING: This submission will NOT pass the Autograder")

