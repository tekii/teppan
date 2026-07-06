#!/usr/bin/env bash
#
# UserPromptSubmit gate for the IQC (Input Quality Check) mandate.
#
# The IQC grammar/spelling gate is meant for genuine human-typed prose only.
# This hook injects the IQC mandate (as UserPromptSubmit additionalContext)
# ONLY when the submitted prompt looks like prose, and stays silent otherwise
# (empty stdout = no additionalContext injected, a safe no-op):
#
#   - slash commands  (prompt begins with '/', e.g. /sitrep) -- a command
#     invocation, not prose to spell/grammar-check;
#   - harness / synthetic turns wrapped in XML (prompt begins with '<', e.g.
#     <task-notification>, <command-*>, <system-reminder>) -- not human-typed.
#
# That UserPromptSubmit fires at all on background / subagent task-notification
# turns is UNDOCUMENTED Claude Code behavior (observed empirically 2026-07-06);
# the '<' guard is a content-shape heuristic, because the UserPromptSubmit
# stdin JSON exposes no field distinguishing a synthetic turn from a human one
# (only session_id, prompt_id, transcript_path, cwd, permission_mode,
# hook_event_name, prompt). A prompt beginning with '/' or '<' is a command or
# markup, never the natural-language prose the check is for.
#
# jq failure or absent stdin falls through to emitting the mandate: better to
# over-apply the check on an unparseable prompt than to silently drop it on
# real prose.

prompt="$(jq -r '.prompt // ""' 2>/dev/null)"

# command ('/') or synthetic/markup ('<') -> no IQC mandate. The ERE is held
# in a variable: an inline '<' inside [[ =~ ]] is mis-parsed by bash as the
# string-comparison operator.
non_prose_re='^[[:space:]]*[/<]'
if [[ "$prompt" =~ $non_prose_re ]]; then
  exit 0
fi

jq -cn '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:"MANDATORY: Your response MUST begin with the exact line IQC: followed immediately by the result of the Input Quality Check. Any tool call or response text before that IQC: line is a violation. Run the Input Quality Check now: detect language; if English, check grammar/spelling and flag ambiguous references. If no errors: write IQC: pass and proceed. If errors found: write IQC: errors found then list them and ask the user to confirm before doing anything else."}}'
