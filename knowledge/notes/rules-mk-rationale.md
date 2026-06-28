---
type: Design Note
title: Rules.mk recursive sub-make rationale
description: Rationale and merit of having a separate Rules.mk for deferred asset recursive sub-make invocations.
tags: [design-note, makefile, architecture]
timestamp: 2026-06-28
---

# `Rules.mk` recursive sub-make rationale

In this project, custom page assets are deferred using the `__DEFERRED_ASSET2` macro in `generator.m4`. This macro populates page-specific deferred rules into makefiles located at `TEKII_BUILD/DOC/<domain>/<page>.mk`.

To compile or clean these assets, the main `Makefile` invokes a recursive sub-make command targeting the specific page's `.mk` file:
```makefile
$(MAKE) -f Rules.mk -f $(__BUILD_ROOT__)/DOC/<page>.mk cp-deferred-asset
```

The separate `Rules.mk` file is loaded before `<page>.mk` to provide essential runtime context, safety, and performance isolation. Below is the technical rationale for keeping it decoupled from both the main `Makefile` and the generated `<page>.mk` files.

---

## 1. Runtime Context for Directory Creation
To copy deferred assets, the generated `<page>.mk` rules use order-only prerequisites with second expansion for on-demand directory creation:
```makefile
__ROOT__/$1 : __SRC__/$1 | $$(@D)/ ; cp $< $@
```
Because the generated `.mk` contains only these asset-copy declarations, it lacks the general rules and flags needed to build them. `Rules.mk` provides this necessary scaffolding:
* **`.SECONDEXPANSION:`**—Enables Make to resolve `$$(@D)/` (the parent directory) during the second expansion phase.
* **Directory-creation pattern rule:**
  ```makefile
  .PRECIOUS: $(__SRC__)/%/
  $(__SRC__)/%/:
  	mkdir -p $@
  ```
  Without this, the sub-make process would not know how to build the directory prerequisites, causing the copy recipe to fail.

---

## 2. Polymorphic Interface for Asset-less Pages
Many pages do not define any deferred assets. For these pages, the generated `<page>.mk` contains no rules for `cp-deferred-asset`, `gzip-asset`, or `clean-asset`.

If the sub-make were to run on `<page>.mk` alone, GNU Make would immediately abort with a fatal error:
`make: *** No rule to make target 'cp-deferred-asset'. Stop.`

To prevent this, `Rules.mk` defines empty default targets:
```makefile
.PHONY: cp-deferred-asset gzip-asset clean-asset
cp-deferred-asset :
gzip-asset :
clean-asset ::
```
By layering `Rules.mk` first via `-f Rules.mk -f <page>.mk`, GNU Make merges the definitions. If `<page>.mk` does not implement the target, the call falls back to the empty phony rule in `Rules.mk` and exits cleanly.

---

## 3. Decoupling and DRY (Don't Repeat Yourself)
By keeping `Rules.mk` separate and static, the generator does not need to duplicate `.SECONDEXPANSION:`, directory-creation rules, `.PRECIOUS` attributes, and default phony targets inside every single generated `<page>.mk` file. This achieves:
* **Smaller generated `.mk` sizes:** Keeps generated files limited to pure declarative mappings.
* **Maintainability:** Any adjustments to directory-creation flags or sub-make scaffolding can be done inside `Rules.mk` without needing to regenerate all page makefiles.

---

## 4. Sandboxing and Build Performance
Invoking sub-makes with `-f Rules.mk -f <page>.mk` completely isolates the recursive call from the main `Makefile`.
* It avoids the overhead of parsing the larger main `Makefile` on every recursive invocation.
* It prevents platform-dependent shell calculations (like `uname -s` or locating the `m4` binaries) from being re-executed repeatedly.
* It eliminates potential infinite dependency loops and `-include` resolution races.

---

## See Also
* [GNU Makefile code review guidelines](../code-review/makefile.md)
* [`__ASSET` rule duplication](asset-rule-duplication.md)
