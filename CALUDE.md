# Wikitrek CodiceLUA — Project Context

## What this project is

A collection of **Lua modules for Scribunto** (MediaWiki's Lua scripting
engine), used by the Wikitrek wiki (https://wikitrek.org).

The code in this GitHub repository (`WikiTrek/CodiceLUA`) is **not the
source of truth** — it is an automatically generated mirror. The real
source of truth is the wiki itself:

```
Wiki page (Modulo:XXX)  --[PageToGitHub export]-->  GitHub repo (.lua file)
```

**This flow is one-directional.** Editing a `.lua` file in this repo and
pushing it does nothing to the wiki. Any accepted fix must be manually
applied by the maintainer on the corresponding `Modulo:XXX` wiki page;
the next PageToGitHub sync will then update the repo file to match.

Consequence for how we work: Claude (in chat or via Claude Code) should
treat this repo as **read/analyze/propose**, never as a place to commit
final fixes and consider the job done.

## Environment constraints (Scribunto sandbox)

- Only the `mw` library and a restricted set of standard Lua libraries
  are available. No `io`, no `os` file/network access, no arbitrary
  `require` of non-wiki modules.
- MediaWiki enforces a **Lua execution time / memory limit** per page
  render. Expensive loops, repeated frame expansions, or heavy string
  concatenation in loops are real risks, not just style issues.
- Modules depend on each other via `require('Modulo:XXX')`. Changing a
  module's exposed function signatures can silently break others —
  check callers before changing a public function's contract.

## Code conventions already in use

- **Public/private split:** `p.functionName(frame)` extracts
  `frame.args` and delegates to a private `p._functionName(args)` that
  contains the real logic. This split is intentional — it allows
  testing `_functionName` without a live `frame` object — and should be
  preserved and encouraged, not "simplified away."
- **LDoc comments:** the codebase uses LDoc-style comments (`@module`,
  @param`, `@return`, `@author`, `@keyword`, etc.), and a GitHub Action
  auto-publishes HTML docs from them. Any comment reformatting must
  keep these tags valid.
- **Luacheck:** a GitHub Action runs Luacheck on the repo. If a
  `.luacheckrc` config exists, it defines what "clean" means here —
  style suggestions should align with it rather than invent new rules.

## Things to never touch / change automatically

- The `-- [P2G] Auto upload by PageToGitHub on ...` header comment and
  any `-- <nowiki>` markers — these are metadata inserted by the export
  tool itself.
- LDoc tag structure (see above).
- Anything that would change a module's public function signature
  without checking all known callers first.

## Language/naming convention (decided)

The wiki content is in Italian, but going forward **new and refactored
code should use English identifiers, function names, and comments**
for maximum reusability and to align with the broader Lua/Scribunto
ecosystem. This is a deliberate, forward-looking standardization — not
something to impose retroactively across the whole codebase without
review. Existing Italian identifiers (e.g. `SubPageName`,
`ExampleText`) should be flagged and renamed opportunistically —
in a single module at a time, verified against callers — rather than in
one large repo-wide rename.

## Working model

1. Analyze / review code (in chat or via Claude Code) here in this
   repo mirror.
2. Propose fixes, with clear explanation of *why* (bug, performance,
   readability, sandbox-safety).
3. Maintainer applies the accepted fix manually on the wiki page.
4. PageToGitHub re-syncs the repo automatically, closing the loop.