#!/usr/bin/env bash
#
# mayhem/test.sh — RUN this repo's OWN functional test suite (already built by mayhem/build.sh).
# exit 0 = pass. PATCH-grade oracle: after an agent patches the source, the grader
# rebuilds (build.sh) then runs this.
#
# Runs zola's ENTIRE upstream test suite (upstream CI: `cargo test --all`) — unit tests
# in every workspace crate plus the functional/integration tests (components/site,
# components/markdown snapshot tests over test_site, etc.). build.sh pre-compiled the
# suite with `cargo test --workspace --no-run`, so this only runs it.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
: "${MAYHEM_JOBS:=$(nproc)}"
cd "$SRC"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
# Writes a CTRF report (file + stdout `CTRF {...}` marker) and returns non-zero iff failed>0.
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

LOG=/tmp/cargo-test-output.log
cargo test --workspace --no-fail-fast 2>&1 | tee "$LOG"

# Sum every `test result:` line: "test result: ok. 26 passed; 0 failed; 0 ignored; ..."
read -r PASSED FAILED IGNORED <<< "$(awk '/^test result:/ {
  for (i=1;i<=NF;i++) { if ($(i+1)=="passed;") p+=$i; if ($(i+1)=="failed;") f+=$i; if ($(i+1)=="ignored;") g+=$i }
} END { printf "%d %d %d", p, f, g }' "$LOG")"

emit_ctrf "cargo-test" "$PASSED" "$FAILED" "$IGNORED"
