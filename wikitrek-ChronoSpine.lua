-- Upload automatica di PageToGitHub il 2026-09-30T23:51:44+02:00
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

This file currently holds only what Step 2 needs. Expect it to grow
substantially once icon mappings and presets (Step 5+) are designed.
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

return M