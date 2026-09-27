-- Upload automatica di PageToGitHub il 2026-09-27T17:32:55+02:00
-- Questo codice proviene da Modulo:wikitrek-ChronoSpine
--[[
Module:ChronoSpine/selftest
=============================

Purpose
-------
A small, self-contained test harness for Module:ChronoSpine/date and
Module:ChronoSpine/stardate, usable while it is still unknown whether
ScribuntoUnit (or a `/testcases` convention) is available on
wikitrek.org (project briefing, open question #4).

Usage
-----
On any sandbox page:

    {{#invoke:ChronoSpine/selftest|run}}

This prints a wikitext report (an HTML table, per house style) listing
every test case, whether it passed, and -- for failures -- exactly
what was expected versus what the parser actually returned.

If ScribuntoUnit later turns out to be available, the `DATE_CASES` /
`STARDATE_CASES` data below can be ported over largely as-is; the
comparison logic (`compare_fields`) is the only part specific to this
harness.

Note on scope
-------------
This module is a development tool, not part of the ChronoSpine core
pipeline described in the briefing. It is not "pure core" in the same
sense as /entry, /date, /stardate: it is expected to grow and change
freely as more parsers/adapters are added, without needing the same
design care as the modules it tests.
--]]

local p = {}

local date_parser = require("Module:ChronoSpine/date")
local stardate_parser = require("Module:ChronoSpine/stardate")

--[[
compare_fields(actual, expected, path)
----------------------------------------
Recursively checks that every key in `expected` exists in `actual`
with an equal value. This is a deliberately PARTIAL comparison: a test
case only lists the fields it cares about (e.g. a success case for
"2257" does not have to repeat `circa = false, incerta = false`), and
anything present in `actual` but not mentioned in `expected` is simply
not checked.

Nested tables (namely `fine`) are compared recursively, so a case can
say `expect = { anno = 2256, fine = { anno = 2257 } }` and only those
two leaf values are checked.

Parameters:
  actual   (table)      -- the real value returned by the parser
  expected (table)      -- the subset of fields this test case expects
  path     (string|nil) -- internal only, used to build a readable
                            mismatch message for nested fields (e.g.
                            "fine.anno"); omit when calling from
                            outside this function

Returns:
  ok       (boolean)     -- true if every expected field matched
  mismatch (string|nil)  -- human-readable description of the first
                            field that did not match; nil when ok
--]]
local function compare_fields(actual, expected, path)
	path = path or ""
	for key, expected_value in pairs(expected) do
		local field_path = (path == "") and tostring(key) or (path .. "." .. tostring(key))
		local actual_value = actual and actual[key]

		if type(expected_value) == "table" then
			if type(actual_value) ~= "table" then
				return false, field_path .. ": expected a table, got " .. tostring(actual_value)
			end
			local ok, mismatch = compare_fields(actual_value, expected_value, field_path)
			if not ok then
				return false, mismatch
			end
		elseif actual_value ~= expected_value then
			return false, field_path .. ": expected " .. tostring(expected_value)
				.. ", got " .. tostring(actual_value)
		end
	end
	return true, nil
end

--[[
Test cases for Module:ChronoSpine/date.

Each case is either:
  * a SUCCESS case:  { input = "...", expect_ok = true,  expect = {...} }
  * a FAILURE case:  { input = "...", expect_ok = false, expect_code = "..." }

The en dash used as the preferred range separator is written here as
explicit UTF-8 bytes (\226\128\147), exactly as in
Module:ChronoSpine/date itself, for the same encoding-safety reason.
--]]
local DATE_CASES = {
	-- -- valid inputs --
	{ input = "2257",                              expect_ok = true, expect = { anno = 2257 } },
	{ input = "2022-05",                           expect_ok = true, expect = { anno = 2022, mese = 5 } },
	{ input = "2022-05-05",                        expect_ok = true, expect = { anno = 2022, mese = 5, giorno = 5 } },
	{ input = "  2257  ",                          expect_ok = true, expect = { anno = 2257 } },
	{ input = "c. 2150",                           expect_ok = true, expect = { circa = true, anno = 2150 } },
	{ input = "c.2150",                            expect_ok = true, expect = { circa = true, anno = 2150 } },
	{ input = "?",                                 expect_ok = true, expect = { incerta = true } },
	{ input = "2256\226\128\1472257",              expect_ok = true, expect = { anno = 2256, fine = { anno = 2257 } } },
	{ input = "2256--2257",                        expect_ok = true, expect = { anno = 2256, fine = { anno = 2257 } } },
	{ input = "c. 2150\226\128\1472200",           expect_ok = true, expect = { circa = true, anno = 2150, fine = { anno = 2200, circa = false } } },
	{ input = "2024-02-29",                        expect_ok = true, expect = { anno = 2024, mese = 2, giorno = 29 } }, -- 2024 is a leap year

	-- -- invalid inputs --
	{ input = "",                                  expect_ok = false, expect_code = "empty" },
	{ input = "abc",                               expect_ok = false, expect_code = "bad-format" },
	{ input = "2022-13-01",                        expect_ok = false, expect_code = "bad-month" },
	{ input = "2022-04-31",                        expect_ok = false, expect_code = "bad-day" }, -- April has 30 days
	{ input = "2023-02-29",                        expect_ok = false, expect_code = "bad-day" }, -- 2023 is not a leap year
	{ input = "2257--2256",                        expect_ok = false, expect_code = "range-order" },
	{ input = "2150--?",                           expect_ok = false, expect_code = "bad-range" }, -- "?" can't be a range endpoint
	{ input = "2150--2200--2300",                  expect_ok = false, expect_code = "bad-range" }, -- nested range
	{ input = "2150-2200-2300",                    expect_ok = false, expect_code = "bad-format" }, -- single hyphens only: not recognised as a range
}

--[[
Test cases for Module:ChronoSpine/stardate. Same case shape as above.
--]]
local STARDATE_CASES = {
	-- -- valid inputs --
	{ input = "4789.6",     expect_ok = true, expect = { value = 4789.6 } },
	{ input = "4789,6",     expect_ok = true, expect = { value = 4789.6 } },
	{ input = "DS 4789.6",  expect_ok = true, expect = { value = 4789.6 } },
	{ input = "SD4789.6",   expect_ok = true, expect = { value = 4789.6 } },
	{ input = " 4789.6 ",   expect_ok = true, expect = { value = 4789.6 } },

	-- -- invalid inputs --
	{ input = "",           expect_ok = false, expect_code = "empty" },
	{ input = "DS",         expect_ok = false, expect_code = "bad-format" }, -- prefix with nothing after it
	{ input = "abc",        expect_ok = false, expect_code = "bad-format" },
	{ input = "4.789,6",    expect_ok = false, expect_code = "bad-format" }, -- dot already present: comma is not touched
}

--[[
run_case(parser, case)
------------------------
Private helper. Runs a single test case against `parser` (either
date_parser or stardate_parser) and reports whether it passed.

Parameters:
  parser (table) -- a module with a `.parse(raw)` function, following
                    the { ok = ..., ... } / { ok = false, code = ... }
                    convention shared by /date and /stardate.
  case   (table) -- one entry from DATE_CASES or STARDATE_CASES.

Returns:
  (table) { input, expected (string, for display), passed (boolean),
            mismatch (string|nil) }
--]]
local function run_case(parser, case)
	local result = parser.parse(case.input)
	local passed, mismatch

	if case.expect_ok then
		if not result.ok then
			passed = false
			mismatch = "expected success, got error code '" .. tostring(result.code) .. "'"
		else
			passed, mismatch = compare_fields(result, case.expect)
		end
	else
		if result.ok then
			passed = false
			mismatch = "expected failure ('" .. tostring(case.expect_code) .. "'), got success"
		elseif result.code ~= case.expect_code then
			passed = false
			mismatch = "expected error code '" .. tostring(case.expect_code)
				.. "', got '" .. tostring(result.code) .. "'"
		else
			passed = true
		end
	end

	return {
		input = case.input,
		expected = case.expect_ok and "success" or ("error: " .. tostring(case.expect_code)),
		passed = passed,
		mismatch = mismatch,
	}
end

--[[
p.run_all()
------------
Runs every test case for both parsers.

Returns:
  (table) -- a list of { module_name, info } entries, where `info` is
             the table returned by run_case().
--]]
function p.run_all()
	local results = {}

	for _, case in ipairs(DATE_CASES) do
		table.insert(results, { module_name = "date", info = run_case(date_parser, case) })
	end

	for _, case in ipairs(STARDATE_CASES) do
		table.insert(results, { module_name = "stardate", info = run_case(stardate_parser, case) })
	end

	return results
end

--[[
p.format_results(results)
---------------------------
Turns the list produced by p.run_all() into a wikitext report: a
summary line plus an HTML `<table>` (per house style: HTML tables,
never wikitext pipe syntax), one row per test case. Built with
`mw.html` rather than raw string concatenation, both for safety
(automatic escaping) and because it is the same approach the future
renderer (Step 4) will use.

Parameters:
  results (table) -- as returned by p.run_all().

Returns:
  (string) -- wikitext ready to be returned from an #invoke.
--]]
function p.format_results(results)
	local passed_count = 0
	for _, r in ipairs(results) do
		if r.info.passed then
			passed_count = passed_count + 1
		end
	end

	local root = mw.html.create()

	root:tag("p")
		:wikitext(string.format(
			"'''ChronoSpine self-test: %d / %d passed.'''",
			passed_count, #results
		))

	local result_table = root:tag("table"):addClass("wikitable")

	local header_row = result_table:tag("tr")
	header_row:tag("th"):wikitext("Module")
	header_row:tag("th"):wikitext("Input")
	header_row:tag("th"):wikitext("Expected")
	header_row:tag("th"):wikitext("Result")
	header_row:tag("th"):wikitext("Details")

	for _, r in ipairs(results) do
		local row = result_table:tag("tr")
		if not r.info.passed then
			row:addClass("chronospine-selftest-fail")
		end

		row:tag("td"):wikitext(r.module_name)
		-- mw.text.nowiki() so a raw "?" or "c." in the input column is
		-- displayed literally and never accidentally parsed as wikitext.
		row:tag("td"):tag("code"):wikitext(mw.text.nowiki(r.info.input))
		row:tag("td"):wikitext(r.info.expected)
		row:tag("td"):wikitext(r.info.passed and "PASS" or "'''FAIL'''")
		row:tag("td"):wikitext(r.info.mismatch and mw.text.nowiki(r.info.mismatch) or "")
	end

	return tostring(root)
end

--[[
p.run(frame)
-------------
The #invoke entry point: {{#invoke:ChronoSpine/selftest|run}}.
Ignores `frame` entirely (this harness takes no parameters) but keeps
the standard signature so it can be invoked from wikitext.
--]]
function p.run(frame)
	return p.format_results(p.run_all())
end

return p