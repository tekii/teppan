# CSS Cleanup Plan

Branch: `css-cleanup`. Scope: discard all current CSS (AMP-related or not —
see "Component inventory" below, it's a rebranded template, not a design
system worth keeping) and rebuild it, while preserving the *mechanism* that
lets `generator.m4`/page sources include a stylesheet and push page-specific
CSS fragments into it.

## Current CSS-related diversion mechanism (what to preserve/repurpose)

- `generator.m4` defines diversion slots `AMP_CUSTOM_STYLES` (5) and
  `AMP_CUSTOM_ELEMENTS` (6), both `m4_cleardivert`-ed per page
  (generator.m4:9-10,365-366). Only `AMP_CUSTOM_STYLES` is CSS;
  `AMP_CUSTOM_ELEMENTS` is HTML markup (amp-img fallbacks etc.) and belongs
  to the separate AMP-removal/HTML effort, not this plan.
- `configure.m4` defines two `__MAGIC_COMMENT_TO_AVOID_MESSING_WITH_CSS_HIGHLIGHT_WHILE_*`
  macros (configure.m4:12-15): one `__INCL([amp-custom.css])`s the whole
  file, the other `m4_undivert([AMP_CUSTOM_STYLES])`s the per-page fragments.
- `layout.html`'s `<style amp-custom>` block (layout.html:27-31) textually
  concatenates both via those macros — the combined CSS is repeated inline,
  verbatim, on every generated page.
- Contributors that currently push into `AMP_CUSTOM_STYLES`:
  `configure-fontawesome.m4` (remapped FontAwesome icon CSS via
  `helper-css-remap`), `contact.in.html`, `srl-default.in.html`
  (page-specific rules).

### Repurposing sketch (subject to revision below)

- Replace the inline `<style amp-custom>` concatenation with a single
  `<link rel="stylesheet" href="...">` to one site-wide CSS file, delivered
  through the existing `__ASSET`/`__CP_ASSET`/`__DEFERRED_ASSET` pipeline
  (hashed for cache-busting).
- Keep a diversion (renamed — e.g. `CUSTOM_STYLES`) that pages/macros can
  still push small page-specific CSS fragments into, for cases that
  genuinely need per-page rules.
- The "magic comment" CSS-syntax-highlighting workaround
  (configure.m4:11-15) may no longer be needed if the combined-stylesheet
  approach moves to a `.css`-suffixed source file instead of inline m4 text
  — TBD.

## Component inventory (current site — all in scope for replacement)

From `layout.html` / `fragment-*.html` / `contact.in.html` /
`srl-default.in.html`:

- Header: inline SVG logo using `var(--logo-text-color)`/`var(--logo-bird-color)`
- Hamburger + desktop sidebar / off-canvas nav (currently `<amp-sidebar>`-based)
- Language dropdown (`lang-dd`)
- Nav items / "selected" state
- Footer: logo + social icons (FontAwesome `tky-iconfont fa-*`)
- Grid system: `tky-row`, `tky-col-sm-*`/`tky-col-md-*`/`tky-col-lg-*`,
  `tky-justify-content-*`
- Cards: `card`, `card-box`, `card-img`, `card-title`, `card-wrapper`
- Buttons: `btn btn-lg ... btn-white`
- Section typography: `tky-section-title`, `tky-text`, `display-2`..`display-7`
- Banner/overlay: `tky-overlay`, `tky-section-btn`
- Contact icons: Bootstrap-style `glyphicon glyphicon-*`
- Scroll-to-top (`scrollToTop`, `target`, `target-anchor`)
- Spinner (`spinner`)

The `tky-*` naming mirrors Bootstrap 3/4 (`col-sm-12`, `row
justify-content-center`, `display-*`, `glyphicon`) — this looks like a
rebranded premium AMP template, not an intentional design system. None of it
is assumed worth keeping as-is.

## Framework vs. from-scratch — research notes

### Classless / semantic micro-frameworks (Pico CSS, Simple.css, Water.css)
Style raw semantic HTML with no/minimal classes, single small file (Water.css
~2KB gzipped, no build step). Pico CSS is actively maintained, ships
light/dark themes via CSS custom properties, and covers cards/accordions/
dropdowns/tooltips with plain HTML. Good as a *base layer* for typography,
forms, basic layout — but **navbar/off-canvas-sidebar/footer-with-social-icons
are not really their job**; those components would still need to be built.

### Component frameworks (Bulma, Bootstrap)
CDN-ready, single `<link>`, no build step (Bulma ~20KB min, Flexbox-based, no
JS required; Bootstrap similar with optional JS). Ship ready-made navbar,
dropdown, card, button, hero/banner components — closer to today's actual
needs (nav, language-switcher dropdown, cards, buttons, banners). Tradeoff:
still "someone else's design system" to theme/override — a less janky
version of the position the site is already in with the rebranded `tky-*`
template — and ships more CSS than the site's small component set strictly
needs.

### Utility-first (Tailwind CSS)
Best CSS-size story (~10KB gzipped) but only *after* a build/purge step —
doesn't fit the "no application server, everything rendered ahead of time by
m4+make" architecture without adding a Node toolchain (the standalone
Tailwind CLI binary could be wired in as a Make step, but that's a new
dependency class for this project).

### Design-token libraries (Open Props [+ Open Props UI])
Not a UI framework — a curated set of CSS custom properties (spacing, color,
type, shadow, animation scales). Pairs naturally with the project's existing
`var(--logo-text-color)`/`var(--logo-bird-color)` pattern
(amp-custom.css:43-50). Open Props UI (beta) layers copy-paste, CSS-only
components on top, targeting modern browsers (Chrome 90+ / Firefox 88+ /
Safari 14+) — a reasonable 2026 baseline.

### Hand-rolled components
Modern CSS-only patterns exist for off-canvas/hamburger nav: the classic
checkbox-hack (`:checked` + sibling selectors, no JS) or a newer
`:has()`-based approach — either avoids JS and avoids `<amp-sidebar>`. The
AMP-removal effort (see memory) already pointed at "CSS-only checkbox-hack
drawers" for the `layout.html` rewrite, which is consistent with hand-rolling
this component. Buttons/cards/banners/footer are straightforward with
flexbox/grid + custom-property theming — the site only has ~6 component
types total, so the hand-rolled surface area is small.

### Read (recommendation, not a decision)

Given (1) no build pipeline beyond m4/make, (2) a small fixed component set,
(3) the project already uses the CSS-custom-properties theming pattern, and
(4) the AMP-removal direction already points at hand-rolled checkbox-hack/
`:has()` nav — a **design-token base (Open Props, or a small hand-written
`:root` token set) plus hand-rolled components** seems to fit better than
adopting a component framework's opinions wholesale. It avoids Tailwind's
build-step problem and avoids the classless frameworks' "doesn't cover
nav/sidebar" gap. A component framework (Bulma) is the fallback if the
from-scratch component work turns out larger than expected.

### Sources
- [Comparing classless CSS frameworks — LogRocket](https://blog.logrocket.com/comparing-classless-css-frameworks/)
- [20 Best Lightweight CSS Frameworks for Fast Loading Websites in 2025 — CSSAuthor](https://cssauthor.com/lightweight-css-frameworks-for-fast-loading-websites/)
- [Surveying the landscape of CSS micro-frameworks — blakewatson.com](https://blakewatson.com/journal/surveying-the-landscape-of-css-micro-frameworks/)
- [Bulma vs Tailwind CSS — StackShare](https://stackshare.io/stackups/bulma-vs-tailwind-css)
- [Bulma vs. Tailwind CSS: Bootstrap alternatives — LogRocket](https://blog.logrocket.com/bulma-vs-tailwind-css-better-bootstrap-alternative/)
- [Open Props](https://open-props.style/)
- [Open Props review — ramigs.dev](https://ramigs.dev/blog/open-props-review/)
- [Open Props UI — CSS Script](https://www.cssscript.com/open-props-ui/)
- [The "Checkbox Hack" (and things you can do with it) — CSS-Tricks](https://css-tricks.com/the-checkbox-hack/)

## Overall view (user)

<!-- fill in -->
