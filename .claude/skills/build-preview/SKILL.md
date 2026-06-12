---
name: build-preview
description: Build the static site with `make build` and serve BUILD/DOC locally so the user can preview the generated pages in a browser.
disable-model-invocation: true
allowed-tools: Bash(make build) Bash(make build *) Bash(ls BUILD/DOC*) Bash(python3 -m http.server*) Bash(pkill *)
---

# Build & preview the site

Goal: produce a fresh build and let the user browse it locally.

## 1. Build

Run from the project root:

```
make build
```

If the command fails (non-zero exit), show the relevant error output (usually
an `m4_fatal` or a missing-file error from one of the `m4` invocations) and
stop here — do not start a preview server against a stale/partial build.

## 2. Discover what got built

```
ls BUILD/DOC
```

Each top-level entry under `BUILD/DOC` is a domain root (e.g.
`www.tekii.com.ar`, `tekii.us`, `tekii.ar`). The main site
(`www.tekii.com.ar`) has language subdirs `en/`, `es/`, `br/`, each with their
own `index.html`, plus a root `index.html` and `404.html`. The other domains
(`tekii.us`, `tekii.ar`) just contain a `redirect.html`.

## 3. Serve it

Pick a port: use the one the user gave as an argument, otherwise default to
`8000`. Start a static file server rooted at `BUILD/DOC`, in the background so
it doesn't block:

```
python3 -m http.server 8080 --directory BUILD/DOC
```

Use `run_in_background: true` for this Bash call.

## 4. Report preview URLs

Tell the user the base URL (`http://localhost:8080/`) and the most useful
entry points, e.g.:

- `http://localhost:8080/www.tekii.com.ar/index.html`
- `http://localhost:8080/www.tekii.com.ar/en/index.html`
- `http://localhost:8080/www.tekii.com.ar/es/index.html`
- `http://localhost:8080/www.tekii.com.ar/br/index.html`
- `http://localhost:8080/tekii.us/redirect.html`
- `http://localhost:8080/tekii.ar/redirect.html`

## 5. Cleanup

Remind the user the server keeps running in the background. To stop it:

```
pkill -f "http.server 8080"
```
