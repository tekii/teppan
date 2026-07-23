dnl firebase-entry.json.m4 -- one firebase.json "hosting" entry for __DOMAIN__
dnl (which must be in scope; sole consumer is __MAKE_PAGE's landing block).
dnl Literal JSON brackets via the meta.json guillemet idiom: quote chars switch
dnl to «» so [ ] pass through as bytes, restored on the last line. File scope
dnl keeps the JSON out of any argument collector (no bracket-balance constraint).
dnl Include at top level / inside a diversion push only -- never nest the
dnl include inside another macro's argument list.
dnl Site ID = dash-substituted domain (same convention as make target names).
dnl "**/*.mk" recursive: deferred per-page .mk files live INSIDE DOC.
dnl cleanUrls false: the generator emits .html links (see firebase-publish note).
m4_changequote(«,»)«»dnl
    {
      "site": "m4_bpatsubst(__DOMAIN__-teppan-site,«\.»,«-»)",
      "public": "DOC/__DOMAIN__",
      "ignore": ["**/.*", "**/*.mk"],
      "cleanUrls": false,
      "trailingSlash": false,
      "headers": [
        {"source": "**/*.@(css|woff2|svg|ico)",
         "headers": [{"key": "Cache-Control", "value": "max-age=31536000, immutable"}]},
        {"source": "**/*.html",
         "headers": [{"key": "Cache-Control", "value": "max-age=0, no-cache, no-store, must-revalidate"}]}
      ]
    }
m4_changequote([,])[]dnl
