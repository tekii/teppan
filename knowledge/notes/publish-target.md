---
type: Design Note
title: make publish — intended gsutil publish flow (incomplete)
description: The publish target and its gsutil-based per-file upload flow are stubbed; documents the intended design, the GSUTIL_EXTRA_FLAGS per-file override pattern, and what remains to be implemented.
tags: [design-note, makefile, publish]
timestamp: 2026-06-28
---

# `make publish` — intended gsutil publish flow (incomplete)

The `publish` target and the `do-publish` recipe are currently stubbed —
`publish:` has no prerequisites wired up and `do-publish` only echoes the
command it *would* run:

```makefile
define do-publish
    @echo "++++++ gsutil $(GSUTIL_EXTRA_FLAGS) -h "Content-Encoding:gzip" \
        cp -a public-read -r $<  gs://$@"
endef
```

## Prototype per-domain publish rule (removed from Makefile)

An earlier prototype wired per-domain publish via a pattern rule:

```makefile
example.com/% : $(__ZIP__)/%
    @echo "gsutil $(GSUTIL_EXTRA_FLAGS) \
        -h "Content-Encoding:gzip" \
        -h "Content-Type:$(shell mimetype --brief $< | tr -d '\n')" \
        cp -a public-read -r $<  gs://$@"
```

The target `example.com/<path>` maps directly to a `gs://example.com/<path>`
bucket object. `$(__ZIP__)/%` provides the gzip-compressed source. The recipe
was echo-only (never executed a real upload). The `mimetype --brief` shell
call computes the Content-Type header per file.

## Intended design

Each per-page `<domain>/<stem>.html` phony target (emitted by `__MAKE_PAGE`
in `generator.m4`'s `MAKEFILE` diversion) is intended to:

1. Depend on the corresponding gzip'd output under `$(__BUILD_ROOT__)/ZIP/`.
2. Set per-file `GSUTIL_EXTRA_FLAGS` target-specific variables (e.g.
   `-h "Cache-Control:public,max-age=86400"`, `-h "Content-Type:..."`).
3. Invoke `do-publish`, which calls `gsutil` with `Content-Encoding:gzip`
   and the accumulated `GSUTIL_EXTRA_FLAGS`.

The `GSUTIL_EXTRA_FLAGS` variable is reset to empty at the top of the
Makefile (`GSUTIL_EXTRA_FLAGS:=`) and accumulated per-target so that
different files can carry different Cache-Control or Content-Type headers.

## Per-file Cache-Control overrides

The pattern for overriding Cache-Control on specific assets (e.g. long-lived
images) was intended to be:

```makefile
$(__BUILD_ROOT__)/ZIP/domain/img/logo.png: GSUTIL_EXTRA_FLAGS=-h "Cache-Control:public,max-age=3600"
```

This is the approach used in `__MAKE_PAGE`'s `PUBLISH` section for HTML
pages (already wired up in the generated `.mk` output); the same idiom would
apply to individual assets once the publish pipeline is completed.

## Bucket setup commands (reference)

```sh
gsutil -m rsync -ndr ../bucket/ gs://www.teky.io
gsutil web set -m en/index.html -e en/404.html gs://www.teky.io
gsutil acl ch -r -u AllUsers:R gs://www.teky.io/
# check content-type: mimetype --brief /tmp/bucketgz/favicon.ico | tr -d '\n'
```

## What remains

- Wire `publish:` prerequisites to the per-page phony targets.
- Implement `do-publish` beyond the echo stub (real `gsutil cp` invocation).
- Decide per-asset Cache-Control policy and emit the target-specific
  `GSUTIL_EXTRA_FLAGS` overrides from the appropriate macro.

## Post-publish verification (future)

Once real uploads happen, a plain `curl` check (status code, headers like
`Content-Encoding`/`Cache-Control`) only confirms the bucket served
*something* — it can't catch a broken render, a missing asset that 404s
only after the page tries to load it, or JS/console errors. The
`chrome-devtools` MCP server (see the `build-preview` skill) can complement
that: actually navigate to the live published URL and check real rendering
(`take_screenshot`/`take_snapshot`) and network activity
(`list_network_requests`/`list_console_messages`) against the deployed
site, not just the local `file://` preview. `curl` stays the fast first
check; the browser is for the deeper, slower pass once `curl` is clean.

See also: [Build & test commands](../build/commands.md),
[GNU Makefile code review guidelines](../code-review/makefile.md).