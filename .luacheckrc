-- .luacheckrc
--
-- Luacheck configuration for the Wikitrek CodiceLUA repository.
--
-- WHY THIS FILE EXISTS
-- --------------------
-- This repo contains Lua modules for Scribunto (MediaWiki's Lua
-- scripting engine). Without this file, Luacheck has no idea that
-- `mw` is a legitimate global injected by the MediaWiki/Scribunto
-- runtime at execution time -- so it flags every single use of `mw`
-- as "accessing undefined variable", drowning out real issues.
--
-- This file whitelists the Scribunto-provided globals and sets
-- baseline options so Luacheck's output actually reflects code
-- quality, not environment mismatch.

-- Scribunto runs Lua 5.1 semantics inside MediaWiki's sandbox.
-- Checking against "lua51" avoids false negatives on 5.1-only quirks
-- and false positives on newer-Lua-only features that don't exist here.
std = "lua51"

-- Globals that Scribunto injects into every module's environment.
-- We use `read_globals` (read-only) rather than `globals` (read-write)
-- because legitimate code only ever *calls into* mw (e.g. mw.title.new,
-- mw.wikibase.getEntity), it never reassigns `mw` itself. If some code
-- ever did `mw = ...`, we *want* Luacheck to flag that as suspicious.
read_globals = {
    "mw",
}

-- Keep the default line-length limit. Several files currently exceed
-- it substantially (one line is 381 characters) -- that's a real
-- readability issue to fix, not a rule to relax.
max_line_length = 120

-- Deliberately NOT ignoring "unused variable" / "unused argument"
-- warnings globally: in this codebase a few of them point at actual
-- bugs (e.g. a variable that was clearly meant to be read later but
-- never is, due to a typo or case-mismatch). Suppressing the category
-- would hide exactly the kind of issue we're looking for.

-- The generated documentation folder is build output, not source --
-- no reason to lint generated HTML/CSS or anything under docs/.
exclude_files = {
    "docs/",
}
