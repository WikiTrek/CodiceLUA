-- Upload automatica di PageToGitHub il 2026-10-03T19:15:46+02:00
-- Questo codice proviene da Modulo:wikitrek-ChronoSpine
--[[
Module:ChronoSpine/config
============================

Purpose
-------
Site-specific data for ChronoSpine on wikitrek.org: page/category
names and, in later steps, preset definitions, icon mappings, and so
on. Per the "pure core" design rule (project briefing, sec. 9), only
the renderer (Step 4+) reads this module, and only at the point it is
actually about to produce wikitext that needs a site-specific name --
/entry, /date, /stardate, /manual, and /i18n never reference it.

This file currently holds what Steps 2 and 4 need. Expect it to grow
further once presets (Step 5+) are designed.
--]]

local M = {}

--[[
M.problem_category
--------------------
The maintenance category a page is added to when ChronoSpine detects
at least one problem in a manual entry (see
Module:ChronoSpine/manual and Module:ChronoSpine/i18n for how
problems are produced and worded). Written out in full, including the
"Categoria:" prefix, so the renderer can use it exactly as given,
without having to guess the right namespace prefix itself.
--]]
M.problem_category = "Categoria:Voci con errori ChronoSpine"

--[[
M.year_link_pattern
----------------------
Keyed by `tempo`. The page-naming pattern (a Lua `string.format`
template with one `%d` for the year) that a year-mode group heading
auto-links to -- WikiTrek uses a DIFFERENT prefix for each time mode:
real-world events are indexed on `Eventi YYYY` pages, in-universe
events on `Timeline YYYY` pages.

The renderer looks this up only when `raggruppa == "anno"`; for any
other grouping mode, or for a `tempo` value not listed here (a future
third mode, say), it simply falls back to plain, unlinked text rather
than erroring -- the same graceful-fallback approach as
M.category_icons below.
--]]
M.year_link_pattern = {
	reale     = "Eventi %d",
	narrativo = "Timeline %d",
}

--[[
M.category_icons
-------------------
`categoria` key -> wikitext for that entry's icon (typically a
File:… link). The actual list of icons/categories is still an
open question (project briefing, sec. 8.2) -- these two are
placeholders to exercise the renderer's lookup-and-fallback logic
before the real set is designed.

The renderer falls back to a plain CSS-coloured dot (no file) when an
entry's `categoria` is nil, OR is set but not found here -- a typo in
an editor's `categoria=` value degrades gracefully to a plain dot
rather than a broken image link.
--]]
M.category_icons = {
	militare = "[[File:ChronoSpine icon militare.svg|16px|link=]]",
	politico = "[[File:ChronoSpine icon politico.svg|16px|link=]]",
}

return M