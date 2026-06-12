---
name: add-assertion
description: Add a new __ASSERT_EQ test case to generator_test.m4 for a generator.m4 macro, with an independently-derived expected value, then verify with `make test`.
allowed-tools: Bash(make test) Bash(m4 *) Bash(realpath *) Bash(date *)
---

# Add a macro assertion

Goal: add a regression test for a `generator.m4` macro using the
`__ASSERT_EQ(NAME, ACTUAL, EXPECTED)` helper already defined in
`generator_test.m4`.

## 1. Identify the macro and a concrete call

Find the macro definition in `generator.m4` and pick a representative,
deterministic invocation (fixed arguments — avoid anything that depends on
`$(PWD)` or the checkout location; e.g. prefer paths built from `__DOC__`
since that prefix cancels out in relative-path macros).

## 2. Derive EXPECTED independently — do not just run the macro

This is the important part: the expected value must come from reasoning
about what the macro *should* produce, not from copying the macro's own
output (that would make the assertion tautological and useless for catching
regressions).

- For pure string/m4-substitution macros (e.g. `__LOCALIZE_URL_PATH`,
  `__ESEN`, `__UP`), work out the expected string by hand from the macro
  definition.
- For macros that shell out (e.g. `__HREF`, `__ABSOLUTE` via `realpath`),
  compute the expected value by running the underlying primitive directly
  (e.g. `realpath --canonicalize-missing <path> --relative-to=<base>`), not
  by invoking the macro.

## 3. Add the assertion

In `generator_test.m4`, inside the `TESTS` divert (after the `__ASSERT_EQ`
definition), near related assertions, add:

```
__ASSERT_EQ([<short description>],<MACRO_CALL>,[<expected>])
```

## 4. Verify

Run `make test`. Confirm the new line shows `PASS <description>`. If it
fails, double-check step 2 — the macro may be correct and the expected value
wrong, or vice versa.
