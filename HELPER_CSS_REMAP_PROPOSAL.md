# `helper-css-remap` — M4/M4sugar-only replacement proposal

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
directory (e.g. `BUILD/DOC/www.tekii.com.ar/en/`), but the `url("...")`
targets (`__VENDOR__/fontawesome-free-5.13.0-web/webfonts/*`) point into
`VENDOR/`, which is gitignored/un-published and never copied into
`BUILD/DOC`. I confirmed this with a working prototype of the mechanism
below — it correctly computes e.g.
`../../../../VENDOR/fontawesome-free-5.13.0-web/webfonts/fa-solid-900.woff2`,
which is the *right relative-path math* but points at a directory that
doesn't exist in the published site. Reviving this tool usefully requires
also `__CP_ASSET`-ing the webfont files into `BUILD/DOC` and rewriting
`url(...)` to point *there* instead — i.e. "port the regex tool" alone isn't
enough; the icon-delivery story needs deciding first (see "Recommendation"
below).

## Proposed M4/M4sugar-only mechanism (prototyped, works)

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
dnl __CSS_REMAP_URLS(CSS-TEXT, CSS-SRC-DIR)
dnl Rewrites every url("...") / url(...) path in CSS-TEXT — interpreted
dnl relative to CSS-SRC-DIR — to a path relative to __TDIR__, via __HREF.
m4_define([__CSS_REMAP_URLS],[dnl
m4_bpatsubst([$1],[url(\("\)?\([^"')]*\)\1)],[url(\1__HREF([$2/\2])\1)])])
```

Usage (replacing `configure-fontawesome.m4:24-27`):

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
- Prototyped both quoted (`url("...")`) and bare (`url(...)`) forms, and
  multiple matches in one string — `m4_bpatsubst` replaces all matches, each
  `\2` correctly bound to its own match when rescanned.
- The `\("\)?` group handles both quote styles so the output preserves
  whichever style the source used.

I verified this end-to-end with a standalone `m4 -R m4sugar.m4f` test
(diverted to `0`/DEFAULT, since m4sugar's init otherwise suppresses direct
output) — happy to fold it into `generator_test.m4` as a real
`__ASSERT_EQ` once we land on the approach.

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
