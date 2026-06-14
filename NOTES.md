# Notes

## `__ASSET` rule duplication (e.g. `img/logo.png` in `news.mk`)

`generator.m4`'s `__ASSET` macro (around line 226) pushes a full
`## ... ASSET BEGINS/ENDS ##` block into the `MAKEFILE` diversion on
*every invocation*, regardless of whether the same asset was already
emitted earlier in the same page. `layout.html` calls
`__ASSET([img/logo.png])` twice (once for the AMP `<amp-img>`, once for
its `<img>` fallback — generator.m4:137/139), so `news.mk` ends up with
two identical `## img/logo.png ASSET BEGINS/ENDS ##` blocks, each
containing:

- `BUILD/DOC/.../img/logo.png : __SRC__/img/logo.png` (prerequisite-only;
  the actual copy recipe comes from the `%.png:` pattern rule in
  `Makefile`)
- `clean-asset :: ; -rm -f BUILD/DOC/.../img/logo.png`
- `BUILD/DOC/.../es/news.html : BUILD/DOC/.../img/logo.png`

Agreed: this is not a bug per se.

- The `target : prereq` lines (single-colon) for the same target just
  accumulate duplicate prerequisite entries on one target node — GNU Make
  merges multiple rules for the same target and only builds/checks it
  once, so duplicate identical prereqs are harmless.
- The `clean-asset :: ; -rm -f <path>` lines are double-colon rules.
  Unlike single-colon rules, GNU Make does **not** merge double-colon
  rules for the same target — each occurrence is a distinct rule, and
  (since `clean-asset` is phony/always-out-of-date) each runs its own
  recipe. So `rm -f <path>` for `logo.png` literally executes twice
  during `make clean`. This is harmless only because `-f` makes `rm`
  idempotent (no error on a missing file), not because Make deduplicated
  it.

Net effect: no build-correctness issue, just redundant generated
Makefile text and a couple of harmless extra `rm -f` calls per repeated
`__ASSET` invocation of the same file. Not worth fixing unless the
generated `.mk` size/readability becomes a real concern.

## Code Review Role — GNU Makefile (CLAUDE.md addition)

It's tailored to patterns already present in this project's
`Makefile`/`Rules.mk`/generated `.mk` files: `:=` vs `=` (esp.
`$(shell which m4)`), `.PHONY`, double-colon `::` rule semantics (ties back
to the `logo.png`/`clean-asset` finding in `NOTES.md`), order-only `|`
prerequisites (ties to the `cd11eed` fix), `.SECONDEXPANSION`/`$$`
expansion, `-include`'d generated `.mk` bootstrapping, and recursive
`$(MAKE)` variable propagation — plus style and common-bugs checklists in
the same format as the M4 section.

Sources:
- [Recursive Make Considered Harmful (Peter Miller)](https://aegis.sourceforge.net/auug97.pdf)
- [Makefile Conventions — GNU Coding Standards](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html)
- [Makefile Tutorial by Example](https://makefiletutorial.com/)
- [GNU Makefiles - best practices](http://rahul.gopinath.org/post/2025/10/17/makefiles/)
- [Makefile Best Practices — Cloud Posse](https://docs.cloudposse.com/best-practices/developer/makefile/)
