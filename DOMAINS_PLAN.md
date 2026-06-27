# Domains Plan

The domain reorganisation is implemented — see
[`knowledge/architecture/domains.md`](knowledge/architecture/domains.md)
for the shipped state. This file tracks what remains open.

## Pending: HTTPS / hosting migration

The current hosting environment does not support HTTPS. Converting it is
complex enough to deserve its own plan (not yet written). It has a direct
impact on the domains plan — once HTTPS is in place, redirect targets should
be updated from `http://` to `https://`.

## Pending: DNS zone update mechanism

DNS zones are currently managed in a mix of Google and Squarespace DNS,
depending on the registrar. A programmatic mechanism to update zones for
each domain would be a significant improvement.

### Research finding: Squarespace has no public DNS API

Squarespace's developer APIs cover Commerce features only (Orders, Inventory,
Products, etc.). DNS records can only be managed through the manual web UI.

**The only viable path to automation** is migrating those domains' nameservers
to an API-capable provider (Cloudflare is the pairing Squarespace's own docs
describe). Once nameservers point elsewhere, Squarespace's DNS panel becomes
inert for the domain, and every existing record (MX/TXT/CNAME for email, etc.)
must be re-created at the new provider. After that, programmatic DNS management
(Cloudflare API, Route 53, etc.) is straightforward.

A DNS-level redirect (registrar URL forwarding, or CNAME/ALIAS plus redirect
rule at the DNS/hosting layer) was considered as an alternative to the
app-level `redirect-to-*.in.html` mechanism — but dropped because Squarespace
has no API to automate it, and the manual-UI path doesn't scale. Worth
revisiting if/when nameservers are migrated to an API-capable provider.

Sources:
[Developer Tools APIs at Squarespace](https://support.squarespace.com/hc/en-us/articles/41325887099533-Developer-Tools-APIs-at-Squarespace),
[Edit your domain's DNS records](https://support.squarespace.com/hc/en-us/articles/360002101888-Adding-DNS-records-to-your-domain),
[Using Cloudflare with Squarespace](https://support.squarespace.com/hc/en-us/articles/213469948-Using-Cloudflare-with-Squarespace),
[Making changes to nameservers](https://support.squarespace.com/hc/en-us/articles/4404183898125-Making-changes-to-nameservers).

## Pending: cross-domain linking

There is a possibility of cross-site links between `tekii.ar` and `tekii.us`.
Deferred to the `NAVIGATION_PHASE` work.

## Pending: redirect domain list completeness

The redirect alias lists may be incomplete.

`redirect-to-tekii-ar.in.html` currently covers:
`tekii.com.ar`, `www.tekii.com.ar`, `tekii.srl`, `teky.com.ar`, `teky.ar`

- `teki.com.ar` (one `k`) was mentioned as a candidate — not yet added;
  needs a decision.

`redirect-to-tekii-us.in.html` currently covers:
`tekii.com`, `tekii.llc`, `tekii.info`, `tekii.biz`, `tekii.co`, `tekii.net`

- Review whether this list is complete.
