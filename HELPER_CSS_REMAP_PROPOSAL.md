# `helper-css-remap` — M4/M4sugar-only replacement

**Status: implemented** as `__CSS_REMAP_URLS` (`generator.m4`), wired into
`configure-fontawesome.m4`, with `__ASSERT_EQ` coverage in
`generator_test.m4`. `configure-fontawesome.m4` itself remains
`dnl`-disabled (see below) — merge this branch whenever FontAwesome
self-hosting is actually needed.

## What it did

`helper/helper.py` (removed in `4952d91`, "python dependency stripped")
defined a Click command registered as `helper-css-remap`:

```python
@click.command()
@click.option('--base', 'base_', required=True, ...)
@click.argument('input', type=click.File('r'))
@click.argument('output', type=click.File('w'))
def css_remap(base_, input_, output):
    def do_remap(mo):
        p = mo.group(0)
        return path.relpath(p, base_)
    input_css = input_.read()
    pattern = re.compile(r'(?<=url\(\").+?(?=\"\))')
    output_css = re.sub(pattern, do_remap, input_css)
    output.write(output_css)
```

i.e.: read a CSS file, find every `url("...")` path, and rewrite it as the
path *relative to* `--base`.

## Current status: dead code, not on the critical path

Its only caller is `configure-fontawesome.m4:26`:

```m4
m4_divert_push([CUSTOM_STYLES])dnl
/** helper-css-remap --base __TDIR__ __VENDOR__/fontawesome-free-5.13.0-web/css/all.css **/
m4_esyscmd(helper-css-remap --base __TDIR__ __VENDOR__/fontawesome-free-5.13.0-web/css/all.css - )dnl
m4_divert_pop([CUSTOM_STYLES])dnl
```

but `layout.html:1` has:

```m4
dnl m4_include(./configure-fontawesome.m4)dnl
```

— `configure-fontawesome.m4` is **not currently included** in the build at
all. So `helper-css-remap` going missing breaks nothing today; nothing in
`make build`/`make test` exercises this path (confirmed: both pass on
`css-cleanup` with the file's diversion already renamed to `CUSTOM_STYLES`).

## A second problem, independent of the missing tool

Even a faithful port wouldn't produce a *working* URL as-is:
`--base __TDIR__` makes the rewritten path relative to the page's output
directory (e.g. `TEPPAN_BUILD/DOC/www.tekii.com.ar/en/`), but the `url("...")`
targets (`__VENDOR__/fontawesome-free-5.13.0-web/webfonts/*`) point into
`VENDOR/`, which is gitignored/un-published and never copied into
`TEPPAN_BUILD/DOC`. I confirmed this with a working prototype of the mechanism
below — it correctly computes e.g.
`../../../../VENDOR/fontawesome-free-5.13.0-web/webfonts/fa-solid-900.woff2`,
which is the *right relative-path math* but points at a directory that
doesn't exist in the published site. Reviving this tool usefully requires
also `__CP_ASSET`-ing the webfont files into `TEPPAN_BUILD/DOC` and rewriting
`url(...)` to point *there* instead — i.e. "port the regex tool" alone isn't
enough; the icon-delivery story needs deciding first (see "Recommendation"
below).

## M4/M4sugar-only mechanism

The project already has a relpath primitive — `__HREF` (`generator.m4:67`),
which wraps `realpath --canonicalize-missing ... --relative-to=...` (a
standard coreutils tool, same class of dependency as the `wget`/`unzip`
already used in `configure-fontawesome.m4`'s Makefile rules — not a bespoke
Python package).

The missing piece is *per-match* regex substitution: `m4_bpatsubst`'s
replacement argument is normally static text with `\N` backreferences. The
trick is that `m4_bpatsubst`'s *result*, if left unquoted, is **rescanned**
by m4 — so a replacement template containing `__HREF([...\N...])` gets each
`__HREF` call expanded independently per match, with that match's own `\N`.

```m4
#
# CSS_REMAP_URLS(CSS-TEXT, CSS-SRC-DIR) MACRO
# rewrites every url("...")/url(...) path in CSS-TEXT -- each interpreted
# relative to CSS-SRC-DIR -- to a path relative to __TDIR__ via __HREF,
# preserving whichever quote style (or lack of one) the source used.
# CSS-TEXT should be read as plain text (e.g. m4_esyscmd_s([cat FILE])),
# not m4_include'd, since third-party CSS isn't safe to parse as m4.
# Two passes (quoted urls, then bare urls) so the "?"-free regexes stay
# within GNU m4's regex dialect; m4_dquote re-quotes the first pass's
# result so commas in the rewritten CSS don't get mistaken for argument
# separators by the second pass, and m4_unquote forces a final rescan so
# the second pass's __HREF calls get expanded too.
#
m4_define([__CSS_REMAP_URLS],[dnl
m4_unquote(m4_bpatsubst(m4_dquote(m4_bpatsubst([$1],[url("\([^"]*\)")],[url("__HREF([$2/\1])")])),dnl
[url(\([^"')]*\))],[url(__HREF([$2/\1]))]))])
```

Usage (`configure-fontawesome.m4:24-27`):

```m4
m4_divert_push([CUSTOM_STYLES])dnl
__CSS_REMAP_URLS(m4_esyscmd_s([cat ]__VENDOR__/fontawesome-free-5.13.0-web/css/all.css),
                 __VENDOR__/fontawesome-free-5.13.0-web/css)[]dnl
m4_divert_pop([CUSTOM_STYLES])dnl
```

Notes:
- `m4_esyscmd_s` (not `m4_include`) reads the vendor CSS as a plain string —
  safer than `m4_include`ing third-party CSS as m4 source (no risk of CSS
  tokens colliding with defined macro names).
- Handles both quoted (`url("...")`) and bare (`url(...)`) forms, and
  multiple matches (including a mix of both styles) in one string —
  `m4_bpatsubst` replaces all matches, each `\1` correctly bound to its own
  match when rescanned.
- Covered by three `__ASSERT_EQ`s in `generator_test.m4` (quoted, bare,
  mixed), run via `make test`. Full `make clean && make build` and
  `make test-with-xxx-macros` also pass (configure-fontawesome.m4 stays
  inert either way, see below).

## Recommendation

`CSS_PLAN.md`'s component inventory already lists "Footer: logo + social
icons (FontAwesome `tky-iconfont fa-*`)" as in-scope for the rebuild. That
decision — self-hosted webfont (needs `__CP_ASSET` wiring + the macro
above), SVG sprite, system/CDN font, etc. — determines whether
`__CSS_REMAP_URLS` is needed at all:

- **If self-hosting FontAwesome (or any vendored CSS with relative
  `url(...)` assets) stays in the plan**: `__CSS_REMAP_URLS` above is a
  drop-in, dependency-free replacement for `helper-css-remap`'s text
  transform — but still needs `__CP_ASSET` calls for the referenced font
  files alongside it, which `helper-css-remap` never had either.
- **If icons move to SVG/inline-sprite/system fonts**: this whole mechanism
  (and `configure-fontawesome.m4`'s vendor-zip Makefile rules) can likely be
  deleted outright rather than revived.

Either way, this is independent of the `CUSTOM_STYLES` diversion rename
already on `css-cleanup` — `configure-fontawesome.m4` was updated for that
rename for consistency, but remains `dnl`-disabled either way.
