# Convenience targets (Linux/macOS). Windows: run the python commands directly.
PYTHON ?= python3

.PHONY: help tools test test-task1 test-task2 test-task3 test-task4 test-examples lint synth waves \
        boolean truth-tables gate-counts diagrams docs-check check-generated all-checks clean

help:
	@echo "make tools            - report available simulators"
	@echo "make test             - run every testbench"
	@echo "make test-task1..4    - run one task's testbenches (test-examples for generated Boolean tests)"
	@echo "make lint             - compile RTL alone with -Wall, check duplicate module names"
	@echo "make synth            - optional Yosys latch/synthesizability lint"
	@echo "make waves            - run *_wave testbenches, write VCD + SVG waveforms"
	@echo "make boolean          - regenerate Boolean analyses/RTL/tests for config/*.json"
	@echo "make truth-tables     - regenerate reference truth tables"
	@echo "make gate-counts      - regenerate NAND/NOR gate-count report"
	@echo "make diagrams         - regenerate SVG diagrams"
	@echo "make docs-check       - verify Markdown links, paths, commands, SVGs"
	@echo "make check-generated  - fail if any generated file is stale"
	@echo "make all-checks       - lint + tests + generated-file and docs checks"
	@echo "make clean            - remove sim/generated build products"

tools:
	$(PYTHON) scripts/run_tests.py --check-tools

test:
	$(PYTHON) scripts/run_tests.py --report docs/simulation/test_results.md

test-task1:
	$(PYTHON) scripts/run_tests.py --task 1
test-task2 test-examples:
	$(PYTHON) scripts/run_tests.py --task examples
test-task3:
	$(PYTHON) scripts/run_tests.py --task 3
test-task4:
	$(PYTHON) scripts/run_tests.py --task 4

lint:
	$(PYTHON) scripts/run_tests.py --lint

synth:
	$(PYTHON) scripts/synth_check.py

waves:
	$(PYTHON) scripts/make_waveforms.py

boolean:
	@for c in config/*.json; do $(PYTHON) tools/boolean_design/boolean_design.py --config $$c || exit 1; done

truth-tables:
	$(PYTHON) tools/verification/gen_truth_tables.py --write

gate-counts:
	$(PYTHON) tools/verification/gate_count.py --write

diagrams:
	$(PYTHON) scripts/render_diagrams.py

docs-check:
	$(PYTHON) scripts/verify_docs.py

check-generated:
	@for c in config/*.json; do $(PYTHON) tools/boolean_design/boolean_design.py --config $$c --check || exit 1; done
	$(PYTHON) tools/verification/gen_truth_tables.py --check
	$(PYTHON) tools/verification/gate_count.py --check
	$(PYTHON) scripts/render_diagrams.py --check

all-checks: lint test check-generated docs-check

clean:
	rm -rf sim/generated
