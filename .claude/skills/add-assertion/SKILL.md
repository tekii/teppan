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
`$(PWD)` or the checkout location; e.g. for path macros, build inputs from
`__BUILD_ROOT__/DOC/...` the way the existing `__ABSOLUTE` assertions do,
rather than a real filesystem path).

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

In `generator_test.m4`, find the existing `m4_divert_push([TESTS])dnl ...
m4_divert_pop([TESTS])dnl` group for the related macro and add a line inside
it:

```
__ASSERT_EQ([<short description>],<MACRO_CALL>,[<expected>])
```

If no related group exists yet, add a new one — **the assertion must sit
inside its own `m4_divert_push([TESTS])dnl ... m4_divert_pop([TESTS])dnl`
pair**, not bare at the top level. The top level of this file stays in
`KILL`-diversion context; an `__ASSERT_EQ` call placed outside any `TESTS`
push silently never appears in `make test`'s output (no error, just
missing) — see [testing conventions](../../../knowledge/testing/conventions.md).

Precede a new group with a `#` comment explaining what the macro does and
why these particular assertions exercise it — every existing group has one
(e.g. the `__FNAME`/`__ABSOLUTE` groups). This sits between the previous
group's `m4_divert_pop` and the new `m4_divert_push`, i.e. in `KILL`
context, so `#` is safe there (see
[M4 comment style](../../../knowledge/conventions/m4-comment-style.md)).
Box it with a bare `#` line above and below only if it's multi-line; a
one-line description stays bare, no box.

## 4. Verify

Run `make test`. Confirm the new line shows `PASS <description>`. If it
fails, double-check step 2 — the macro may be correct and the expected value
wrong, or vice versa.
