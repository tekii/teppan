# CSS Plan

> **Status (2026-07-21): substantially implemented.** The 2026-07-05 plan's
> goal — discard the rebranded `tky-*` template CSS and rebuild on a light,
> token-driven, no-toolchain base — has landed, via a longer route than the
> plan recommended (AMP removal → Water.css interim → **Pico.css classless**
> + `custom.css`, commit `c36d4c8`). Current review guidance:
> [knowledge/code-review/css.md](knowledge/code-review/css.md); framework
> trace: [knowledge/notes/water-to-pico-migration.md](knowledge/notes/water-to-pico-migration.md).
> The original research/rationale text lives in this file's git history.
>
> **Erratum:** the original plan listed `contact.in.html` as a
> `CUSTOM_STYLES` contributor — it never was. The error propagated into
> `css.md` and was corrected there on 2026-07-21; marked here so the source
> is on record.

## Implemented (done — kept as the scorecard)

- ✅ **Single external stylesheet** replacing the inline
  `<style amp-custom>` concatenation: `custom.css`, delivered per-domain
  via `__DASSET` `<link>`, layered after Pico (cascade order load-bearing).
- ✅ **Diversion preserved and renamed** `AMP_CUSTOM_STYLES` →
  `CUSTOM_STYLES`, magic-comment plumbing intact (`configure.m4:11-14`,
  `layout.html:33`). **Deliberately kept although currently userless** (the
  only pusher, `configure-fontawesome.m4`, is `dnl`-disabled): it remains
  the sanctioned mechanism for genuine per-page CSS tweaks, so a future
  page doesn't have to reinvent it.
- ✅ **Hand-rolled nav** exactly as sketched: CSS-only checkbox +
  `:has()` drawer below 768px, fixed rail above; no JS anywhere.
- ✅ **Design-token pattern without toolchain** — satisfied by Pico's
  `--pico-*` custom properties plus the brand pair at `:root`
  (`--footer-bg`/`--footer-fg`; billboard, monochrome logo, and
  scroll-to-top all re-theme from that one two-line point), in lieu of the
  originally proposed Open Props. Light/dark ride Pico's scheme handling +
  exact pair inversion.
- ✅ **Mobile-friendly** — drawer nav, `svh`-based full-viewport footer,
  logical properties throughout.

## Remaining (live)

### Fragment rewiring (register: knowledge/notes/deferred-work.md)

`fragment-home.html`, `fragment-services.html`, `fragment-customers.html`
are unwired (no `__INCL` anywhere) and still carry the pre-Pico class soup.
Whoever wires one in must rewrite it to the classless + `custom.css` idiom;
under classless Pico those classes style nothing. Checklist of what still
sits in them (2026-07-21 audit): `container`, `tky-row`/`tky-col-*` grid,
`card*` set, `btn*` set, `display-*`/`tky-section-*` typography,
`tky-overlay`, FontAwesome `fa-*` icons (the fontawesome pipeline is
`dnl`-disabled — icons should become inline SVG symbols per the layout's
pattern). Customer/sponsor logos need descriptive `alt` (css.md/html.md).

### Class hygiene (in flight)

The three defect-tier findings of the 2026-07-21 class audit — dead
`.link`/`.nav-item` emissions, `.nav-toggle` redundant with `#nav-toggle`,
`.selected` duplicating `aria-current` — travel as
`.handoff/draft-class-hygiene.md` (apply pending).

## Parked: semantic-selector options (folded from SEMANTIC_CSS_PLAN.md)

Style-tier candidates — classes that work correctly today but have
arguably better semantic (element/attribute/structural) forms. Parked, not
scheduled.

| Class | Semantic form | Note |
|---|---|---|
| `.topbar` | `body > header` | It IS the page header, a direct body child; Pico's own vocabulary; custom-after-Pico wins ties. Cleanest of the four. |
| `.nav-open`, `.nav-close` | `label[for="nav-toggle"]`, split by context: `body > header label[for="nav-toggle"]` / `#sidebar label[for="nav-toggle"]` | The `for` attribute is functionally required, so styling keyed to it can never drift from behavior — a class can be forgotten on a new label; the attribute cannot. |
| `label.nav-backdrop` | `#nav-toggle ~ label` | The only label-sibling of the toggle. At (1,0,1) it outranks Pico's `[type=checkbox] ~ label` outright, retiring the load-bearing `label.` qualifier and its long comment — the selector states the mechanism itself. |
| `.scroll-to-top` | `body > a[href="#top"]` | Functional attribute. Caveat: welds styling to the `#top` navigation mechanism, which the modernize tape deliberately left open — decide the mechanism first. |
| `.lang-flag` | `#sidebar nav a > img` today; better: add `hreflang` to the locale anchors and key `a[hreflang] img` | Putting `hreflang` on visible locale links is independently good practice (today only the `<link rel=alternate>` head entries carry it) — the styling hook falls out of a semantic enrichment. |

**Audited KEEP (do not convert):**

- `.text-isologo` — names content semantics ("this text is the brand
  wordmark") as a deliberate opt-in for arbitrary future sites; the most
  defensible class in the file.
- `.layout-logo` — replaceable structurally (`#sidebar > svg`,
  `body > footer svg`) but names one shared role across two contexts;
  structural forms would state the sizing intent twice.

**Trade-offs (why parked):** For converting — the file's two historical
specificity battles (the click-swallowing backdrop, the link-blue selected
locale) were both caused by mixing vocabularies, project classes fighting
Pico's attribute/element selectors; adopting Pico's own vocabulary makes
cascade order (custom-after-Pico, the stated contract) the only variable,
and in a repo whose stylesheet and markup are co-owned and single-sourced
the "classes decouple styling from structure" defense is at its weakest.
Against converting — structural selectors couple CSS to DOM shape and this
layout reshuffles often (the language switch was rebuilt twice on
2026-07-21 alone); id-anchored forms (`#nav-toggle ~ label`, 1,0,1)
ratchet specificity above everything; and the churn resets a
well-commented, battle-annotated file's provenance for modest functional
gain.

**Trigger to revisit:** a layout epoch where the nav markup is being
reshaped anyway (the conversions ride an already-open surgery), or a third
specificity battle traced to vocabulary mixing.
