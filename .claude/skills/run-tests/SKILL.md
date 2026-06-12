---
name: run-tests
description: Run `make test`, summarize the __ASSERT_EQ PASS/FAIL results from generator_test.m4, and help debug any failures.
allowed-tools: Bash(make test)
---

# Run generator tests

Goal: run the m4 generator test suite and give a clear pass/fail summary.

## 1. Run the suite

```
make test
```

`make test` writes the full m4 output to `/tmp/generator_test.out`, prints
it, and fails (`! grep -q '^FAIL'`) if any `__ASSERT_EQ` assertion failed.

## 2. Summarize

- Count lines starting with `PASS` and `FAIL` in the output.
- If `make test` exited 0: report "<N> assertions passed" — done.
- If it exited non-zero:
  - If there are `FAIL <name>: got <X> expected <Y>` lines, list each one.
    For each failure, look at the matching `__ASSERT_EQ(...)` call in
    `generator_test.m4` and the macro it exercises in `generator.m4` to
    explain *why* the actual value differs from the expected one.
  - If there are no PASS/FAIL lines at all, the failure happened before the
    TESTS divert was emitted — this is an m4-level error (e.g. `m4_fatal`,
    syntax error, missing include). Show the relevant `error:`/`m4_fatal`
    line(s) from the output instead.

## 3. Next step

If something failed, suggest the fix (don't apply it unless asked) and offer
to re-run `make test` afterwards.
