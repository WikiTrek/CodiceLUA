-- Upload automatica di PageToGitHub il 2026-10-03T19:17:41+02:00
-- Questo codice proviene da Modulo:wikitrek-ChronoSpine
--[[
Module:ChronoSpine/selftest
=============================

Purpose
-------
A small, self-contained test harness for Module:ChronoSpine/date,
Module:ChronoSpine/stardate, Module:ChronoSpine/manual,
Module:ChronoSpine/group, the formatting functions in
Module:ChronoSpine/i18n, and Module:ChronoSpine/render, usable while
it is still unknown whether ScribuntoUnit (or a `/testcases`
convention) is available on wikitrek.org (project briefing, open
question #4).

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
local manual_adapter = require("Module:ChronoSpine/manual")
local entry = require("Module:ChronoSpine/entry")
local group_module = require("Module:ChronoSpine/group")
local i18n = require("Module:ChronoSpine/i18n")
local config_module = require("Module:ChronoSpine/config")
local render_module = require("Module:ChronoSpine/render")

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
check_absent(actual, fields)
------------------------------
Private helper, used only by the /manual test cases below. Checks
that every field named in `fields` is nil on `actual`.

This exists because compare_fields() cannot express "this field must
be absent": a test case writing `expect = { stellare = nil }` would
not work, since a Lua table simply never stores a key whose value is
nil, so `pairs(expected)` would never even see a `stellare` key to
check in the first place. Listing the field name as a plain string
here sidesteps that.

Parameters:
  actual (table) -- the value to check (a normalised entry).
  fields (table|nil) -- a list of field names that must be nil.

Returns:
  ok       (boolean)
  mismatch (string|nil)
--]]
local function check_absent(actual, fields)
	for _, field in ipairs(fields or {}) do
		if actual[field] ~= nil then
			return false, field .. ": expected absent, got " .. tostring(actual[field])
		end
	end
	return true, nil
end

--[[
Test cases for Module:ChronoSpine/manual.

Unlike DATE_CASES/STARDATE_CASES (one raw string in, one parsed value
out), each case here is a whole simulated template call (`args`, a
table shaped like frame:getParent().args) in, and TWO lists out:
`entries` and `problems`. So the case shape is necessarily different:

  {
    name            = "...",                 -- shown in the report
    args            = { data1 = "...", ... }, -- simulated frame args
    expect_entries  = { {...}, ... },         -- one per expected entry,
                                               -- in expected order;
                                               -- same partial-match
                                               -- convention as
                                               -- DATE_CASES' `expect`.
                                               -- A `__absent` key,
                                               -- e.g. { __absent =
                                               -- { "stellare" } },
                                               -- checks fields that
                                               -- must be nil (see
                                               -- check_absent above).
    expect_problems = { { ordine = N, code = "..." }, ... },
  }
--]]
local MANUAL_CASES = {
	{
		name = "basic valid entry (Italian params)",
		args = { data1 = "2257", voce1 = "Primo contatto" },
		expect_entries = { { anno = 2257, voce = "Primo contatto", ordine = 1 } },
		expect_problems = {},
	},
	{
		name = "basic valid entry (English aliases)",
		args = { date1 = "2022-05-05", item1 = "First contact" },
		expect_entries = { { anno = 2022, mese = 5, giorno = 5, voce = "First contact", ordine = 1 } },
		expect_problems = {},
	},
	{
		name = "missing date is fatal",
		args = { voce1 = "Solo testo, niente data" },
		expect_entries = {},
		expect_problems = { { ordine = 1, code = "missing-date" } },
	},
	{
		name = "missing label is fatal",
		args = { data1 = "2257" },
		expect_entries = {},
		expect_problems = { { ordine = 1, code = "missing-label" } },
	},
	{
		name = "unparseable date is fatal",
		args = { data1 = "2022-13-01", voce1 = "Testo" },
		expect_entries = {},
		expect_problems = { { ordine = 1, code = "date:bad-month" } },
	},
	{
		name = "unparseable stardate is non-fatal",
		args = { data1 = "2257", voce1 = "Testo", stellare1 = "abc" },
		expect_entries = { { anno = 2257, voce = "Testo", ordine = 1, __absent = { "stellare" } } },
		expect_problems = { { ordine = 1, code = "stardate:bad-format" } },
	},
	{
		name = "entirely blank numbered set is skipped silently",
		args = { data1 = "2257", voce1 = "Testo", data5 = "", voce5 = "   " },
		expect_entries = { { anno = 2257, voce = "Testo", ordine = 1 } },
		expect_problems = {},
	},
	{
		name = "gap-tolerant numbering (1 and 9, nothing between)",
		args = { data1 = "2257", voce1 = "Uno", data9 = "2300", voce9 = "Nove" },
		expect_entries = {
			{ anno = 2257, voce = "Uno", ordine = 1 },
			{ anno = 2300, voce = "Nove", ordine = 9 },
		},
		expect_problems = {},
	},
	{
		name = "discovery is not limited to the date field",
		args = { voce7 = "Solo voce, indice scoperto tramite un altro campo" },
		expect_entries = {},
		expect_problems = { { ordine = 7, code = "missing-date" } },
	},
	{
		name = "alias conflict: Italian wins over English",
		args = { data5 = "2257", date5 = "1999", voce5 = "Testo" },
		expect_entries = { { anno = 2257, voce = "Testo", ordine = 5 } },
		expect_problems = {},
	},
	{
		name = "uncertain date passes through the adapter",
		args = { data1 = "?", voce1 = "Battaglia di J'Gal" },
		expect_entries = { { incerta = true, voce = "Battaglia di J'Gal", ordine = 1 } },
		expect_problems = {},
	},
	{
		name = "approximate range passes through the adapter",
		args = { data1 = "c. 2150--2200", voce1 = "Guerra dimenticata" },
		expect_entries = {
			{ anno = 2150, circa = true, voce = "Guerra dimenticata", ordine = 1,
				fine = { anno = 2200, circa = false } },
		},
		expect_problems = {},
	},
}

--[[
Test cases for Module:ChronoSpine/group.

Each case provides a list of already-normalised entries (built with
entry.new, deliberately in SCRAMBLED input order, to make sure the
module's own sorting -- not accidental input order -- is what
produces the expected result) and a `raggruppa` mode, and expects a
specific ordered list of groups back.

  {
    name      = "...",
    raggruppa = "anno" | "mese" | "giorno" | "stagione" | <anything else> | nil,
    entries   = { entry.new({...}), ... },
    expect    = {
      { key = {...}, kind = "normal"|"incerta", voce_order = { "...", ... } },
      ...
    },
  }

`voce_order` is the authoritative check on a group's contents: the
exact list of labels expected in that group, IN ORDER. This both
confirms which entries landed in which bucket and that they are
correctly sorted within it, in one check.
--]]
local GROUP_CASES = {
	{
		name = "anno mode: basic grouping, chronological order",
		raggruppa = "anno",
		entries = {
			entry.new({ anno = 2257, voce = "B", ordine = 2 }),
			entry.new({ anno = 2256, voce = "A", ordine = 1 }),
			entry.new({ anno = 2257, voce = "C", ordine = 3 }),
		},
		expect = {
			{ key = { anno = 2256 }, kind = "normal", voce_order = { "A" } },
			{ key = { anno = 2257 }, kind = "normal", voce_order = { "B", "C" } },
		},
	},
	{
		name = "mese mode: a year-only entry gets its own bucket, sorted before any month",
		raggruppa = "mese",
		entries = {
			entry.new({ anno = 2022, mese = 5, voce = "May", ordine = 1 }),
			entry.new({ anno = 2022, voce = "YearOnly", ordine = 2 }),
			entry.new({ anno = 2022, mese = 3, voce = "March", ordine = 3 }),
		},
		expect = {
			{ key = { anno = 2022 }, kind = "normal", voce_order = { "YearOnly" } },
			{ key = { anno = 2022, mese = 3 }, kind = "normal", voce_order = { "March" } },
			{ key = { anno = 2022, mese = 5 }, kind = "normal", voce_order = { "May" } },
		},
	},
	{
		name = "giorno mode: cascades one level deeper (month-only before any day)",
		raggruppa = "giorno",
		entries = {
			entry.new({ anno = 2022, mese = 5, giorno = 5, voce = "FullDate", ordine = 1 }),
			entry.new({ anno = 2022, mese = 5, voce = "MonthOnly", ordine = 2 }),
		},
		expect = {
			{ key = { anno = 2022, mese = 5 }, kind = "normal", voce_order = { "MonthOnly" } },
			{ key = { anno = 2022, mese = 5, giorno = 5 }, kind = "normal", voce_order = { "FullDate" } },
		},
	},
	{
		name = "stagione mode: a non-contiguous (interleaved) season is still merged into one bucket",
		raggruppa = "stagione",
		entries = {
			entry.new({ anno = 2257, mese = 3, gruppo = "Stagione 1", voce = "Ep2", ordine = 3 }),
			entry.new({ anno = 2257, mese = 1, gruppo = "Stagione 1", voce = "Ep1", ordine = 1 }),
			entry.new({ anno = 2257, mese = 2, gruppo = "Stagione A", voce = "OtherEp1", ordine = 2 }),
		},
		expect = {
			-- "Stagione 1" comes first because its FIRST (chronologically
			-- earliest) member, Ep1, precedes "Stagione A"'s only member --
			-- even though Ep2 (also "Stagione 1") sorts AFTER it.
			{ key = { gruppo = "Stagione 1" }, kind = "normal", voce_order = { "Ep1", "Ep2" } },
			{ key = { gruppo = "Stagione A" }, kind = "normal", voce_order = { "OtherEp1" } },
		},
	},
	{
		name = "stagione mode: entries with no gruppo share one ungrouped bucket",
		raggruppa = "stagione",
		entries = {
			entry.new({ anno = 2257, mese = 3, voce = "NoGroup2", ordine = 3 }),
			entry.new({ anno = 2257, mese = 1, voce = "NoGroup1", ordine = 1 }),
			entry.new({ anno = 2257, mese = 2, gruppo = "Stagione X", voce = "Grouped", ordine = 2 }),
		},
		expect = {
			{ key = {}, kind = "normal", voce_order = { "NoGroup1", "NoGroup2" } },
			{ key = { gruppo = "Stagione X" }, kind = "normal", voce_order = { "Grouped" } },
		},
	},
	{
		name = "incerta entries are always last, in their own order, regardless of raggruppa",
		raggruppa = "anno",
		entries = {
			entry.new({ incerta = true, voce = "Uncertain2", ordine = 5 }),
			entry.new({ anno = 2257, voce = "Certain", ordine = 1 }),
			entry.new({ incerta = true, voce = "Uncertain1", ordine = 2 }),
		},
		expect = {
			{ key = { anno = 2257 }, kind = "normal", voce_order = { "Certain" } },
			{ key = {}, kind = "incerta", voce_order = { "Uncertain1", "Uncertain2" } },
		},
	},
	{
		name = "unrecognised raggruppa value falls back to anno behaviour",
		raggruppa = "not-a-real-mode",
		entries = {
			entry.new({ anno = 2257, voce = "X", ordine = 1 }),
			entry.new({ anno = 2256, voce = "Y", ordine = 2 }),
		},
		expect = {
			{ key = { anno = 2256 }, kind = "normal", voce_order = { "Y" } },
			{ key = { anno = 2257 }, kind = "normal", voce_order = { "X" } },
		},
	},
	{
		name = "nil raggruppa (not given at all) also falls back to anno behaviour",
		raggruppa = nil,
		entries = {
			entry.new({ anno = 2257, voce = "X", ordine = 1 }),
			entry.new({ anno = 2256, voce = "Y", ordine = 2 }),
		},
		expect = {
			{ key = { anno = 2256 }, kind = "normal", voce_order = { "Y" } },
			{ key = { anno = 2257 }, kind = "normal", voce_order = { "X" } },
		},
	},
}

--[[
Test cases for the formatting functions in Module:ChronoSpine/i18n
(M.format_date, M.format_stardate, M.group_label).

Unlike the other case tables, these call THREE different functions
with different signatures, so each case names which one via `fn` and
packs that function's arguments into `input` accordingly:

  fn = "format_date"     -> input = <date_fields table>
  fn = "format_stardate" -> input = <number>
  fn = "group_label"     -> input = { key = {...}, raggruppa = "...", kind = "..." }

These are plain string-in/string-out functions, so (unlike DATE_CASES
etc.) an exact match against `expect` is both simple and appropriate
-- no partial-match or fragment logic needed.
--]]
local I18N_CASES = {
	{ name = "format_date: year only", fn = "format_date",
		input = { anno = 2257 }, expect = "2257" },
	{ name = "format_date: year + month", fn = "format_date",
		input = { anno = 2022, mese = 5 }, expect = "maggio 2022" },
	{ name = "format_date: full date", fn = "format_date",
		input = { anno = 2022, mese = 5, giorno = 5 }, expect = "5 maggio 2022" },
	{ name = "format_date: circa", fn = "format_date",
		input = { anno = 2150, circa = true }, expect = "c. 2150" },
	{ name = "format_date: range", fn = "format_date",
		input = { anno = 2256, fine = { anno = 2257 } },
		expect = "2256\226\128\1472257" },
	{ name = "format_date: range, only the start is approximate", fn = "format_date",
		input = { anno = 2150, circa = true, fine = { anno = 2200, circa = false } },
		expect = "c. 2150\226\128\1472200" },
	{ name = "format_date: range, only the end is approximate", fn = "format_date",
		input = { anno = 2150, circa = false, fine = { anno = 2200, circa = true } },
		expect = "2150\226\128\147c. 2200" },

	{ name = "format_stardate: basic", fn = "format_stardate",
		input = 4789.6, expect = "DS 4789.6" },

	{ name = "group_label: anno mode", fn = "group_label",
		input = { key = { anno = 2257 }, raggruppa = "anno", kind = "normal" },
		expect = "2257" },
	{ name = "group_label: mese mode, month present", fn = "group_label",
		input = { key = { anno = 2022, mese = 5 }, raggruppa = "mese", kind = "normal" },
		expect = "maggio 2022" },
	{ name = "group_label: mese mode, year-only bucket", fn = "group_label",
		input = { key = { anno = 2022 }, raggruppa = "mese", kind = "normal" },
		expect = "2022" },
	{ name = "group_label: giorno mode, full date", fn = "group_label",
		input = { key = { anno = 2022, mese = 5, giorno = 5 }, raggruppa = "giorno", kind = "normal" },
		expect = "5 maggio 2022" },
	{ name = "group_label: stagione mode, with gruppo", fn = "group_label",
		input = { key = { gruppo = "Stagione 3" }, raggruppa = "stagione", kind = "normal" },
		expect = "Stagione 3" },
	{ name = "group_label: stagione mode, ungrouped", fn = "group_label",
		input = { key = {}, raggruppa = "stagione", kind = "normal" },
		expect = "Senza gruppo" },
	{ name = "group_label: incerta overrides raggruppa entirely", fn = "group_label",
		input = { key = {}, raggruppa = "anno", kind = "incerta" },
		expect = "Data incerta" },
}

--[[
Test cases for Module:ChronoSpine/render.

The output here is wikitext, not structured data -- exact-string
comparison would be brittle (renaming a CSS class would break every
case). So each case instead provides a `call` (a zero-argument
function invoking M.render or M.problems_notice with hand-built
fixtures) and checks for the PRESENCE or ABSENCE of specific
substrings, per the Step 4 design discussion's §10:

  {
    name                = "...",
    call                = function() return render_module.xxx(...) end,
    expect_contains     = { "substring", ... },  -- all must be present
    expect_not_contains = { "substring", ... },  -- none must be present
    expect_nil          = true,                   -- OR: call() must return nil
                                                    -- (mutually exclusive with
                                                    -- the two lists above)
  }

Group/entry fixtures are built by hand (plain tables matching
Module:ChronoSpine/group's and /entry's shapes) rather than going
through M.group()/M.build() -- this keeps each case's input minimal
and focused on exactly what it is testing.
--]]
local RENDER_CASES = {
	{
		name = "anno mode + narrativo: year heading links to Timeline YYYY",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "Primo contatto", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno" })
		end,
		expect_contains = { "[[Timeline 2257|2257]]", "Primo contatto" },
		expect_not_contains = { "[[Eventi" },
	},
	{
		name = "anno mode + reale: year heading links to Eventi YYYY instead",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "Primo contatto", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "reale", raggruppa = "anno" })
		end,
		expect_contains = { "[[Eventi 2257|2257]]" },
		expect_not_contains = { "[[Timeline" },
	},
	{
		name = "stagione mode: heading is the gruppo text, not auto-linked",
		call = function()
			local groups = {
				{ key = { gruppo = "Stagione 3" }, kind = "normal", entries = {
					entry.new({ anno = 2257, mese = 1, gruppo = "Stagione 3", voce = "Ep1", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "stagione" })
		end,
		expect_contains = { "Stagione 3" },
		expect_not_contains = { "[[Eventi", "[[Timeline" },
	},
	{
		name = "incerta group: dashed class, fixed heading, no date line on its entry",
		call = function()
			local groups = {
				{ key = {}, kind = "incerta", entries = {
					entry.new({ incerta = true, voce = "Battaglia di J'Gal", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno" })
		end,
		expect_contains = { "chronospine-group--incerta", "Data incerta", "Battaglia di J'Gal" },
		expect_not_contains = { "chronospine-entry-date" },
	},
	{
		name = "stardate line shown in narrativo",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "Evento", stellare = 4789.6, ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno" })
		end,
		expect_contains = { "DS 4789.6" },
	},
	{
		name = "stardate line hidden in reale, even if stellare is set",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "Evento", stellare = 4789.6, ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "reale", raggruppa = "anno" })
		end,
		expect_not_contains = { "DS 4789.6" },
	},
	{
		name = "announced entry gets the hollow-dot class",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "X", stato = "annunciato", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno" })
		end,
		expect_contains = { "chronospine-entry--hollow" },
	},
	{
		name = "mapped categoria renders its configured icon wikitext",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "X", categoria = "militare", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno" })
		end,
		expect_contains = { config_module.category_icons.militare },
	},
	{
		name = "unmapped categoria renders no File link at all",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "X", categoria = "chiave-inesistente", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno" })
		end,
		expect_not_contains = { "[[File:" },
	},
	{
		name = "allinea = sinistra adds the left-float modifier class",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "X", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno", allinea = "sinistra" })
		end,
		expect_contains = { "chronospine-box--left" },
	},
	{
		name = "default alignment omits the left-float modifier class",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "X", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno" })
		end,
		expect_not_contains = { "chronospine-box--left" },
	},
	{
		name = "titolo given renders the title band",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "X", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno", titolo = "Cronologia" })
		end,
		expect_contains = { "chronospine-title", "Cronologia" },
	},
	{
		name = "no titolo given omits the title band entirely",
		call = function()
			local groups = {
				{ key = { anno = 2257 }, kind = "normal", entries = {
					entry.new({ anno = 2257, voce = "X", ordine = 1 }),
				} },
			}
			return render_module.render(groups, { tempo = "narrativo", raggruppa = "anno" })
		end,
		expect_not_contains = { "chronospine-title" },
	},
	{
		name = "problems_notice: empty list returns nil (nothing to show)",
		call = function()
			return render_module.problems_notice({})
		end,
		expect_nil = true,
	},
	{
		name = "problems_notice: non-empty list includes category and message",
		call = function()
			return render_module.problems_notice({
				{ ordine = 1, field = "date", code = "missing-date", raw = nil },
			})
		end,
		expect_contains = {
			"[[" .. config_module.problem_category .. "]]",
			"Manca la data nel set numerato 1",
		},
	},
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
run_manual_case(case)
------------------------
Private helper. Runs a single MANUAL_CASES entry against
Module:ChronoSpine/manual's M.build(), and checks BOTH halves of its
result: the `entries` list (partial field match per entry, via
compare_fields/check_absent) and the `problems` list (exact
`{ordine, code}` match per problem, in order).

Checking problems by `{ordine, code}` only (not `raw`, not `field`) is
a deliberate simplification for this harness: the parser-level test
cases already cover exactly which raw input produces which code, so
re-asserting `raw` here would just duplicate that without adding
confidence that /manual itself is wired correctly.

Returns:
  (table) { input, expected (string, for display), passed (boolean),
            mismatch (string|nil) } -- same shape as run_case(), so
            both fit in one report table.
--]]
local function run_manual_case(case)
	local result = manual_adapter.build(case.args)
	local mismatches = {}

	if #result.entries ~= #case.expect_entries then
		table.insert(mismatches, string.format(
			"entries: expected %d, got %d", #case.expect_entries, #result.entries
		))
	else
		for i, expected_entry in ipairs(case.expect_entries) do
			-- `__absent` is metadata for THIS harness, not a field to
			-- compare -- strip it before handing the rest to
			-- compare_fields(), then check it separately.
			local absent_fields = expected_entry.__absent
			local expected_clean = {}
			for key, value in pairs(expected_entry) do
				if key ~= "__absent" then
					expected_clean[key] = value
				end
			end

			local ok, mismatch = compare_fields(result.entries[i], expected_clean)
			if ok and absent_fields then
				ok, mismatch = check_absent(result.entries[i], absent_fields)
			end
			if not ok then
				table.insert(mismatches, "entries[" .. i .. "]." .. mismatch)
			end
		end
	end

	if #result.problems ~= #case.expect_problems then
		table.insert(mismatches, string.format(
			"problems: expected %d, got %d", #case.expect_problems, #result.problems
		))
	else
		for i, expected_problem in ipairs(case.expect_problems) do
			local actual = result.problems[i]
			if actual.ordine ~= expected_problem.ordine or actual.code ~= expected_problem.code then
				table.insert(mismatches, string.format(
					"problems[%d]: expected {ordine=%s, code=%s}, got {ordine=%s, code=%s}",
					i, tostring(expected_problem.ordine), tostring(expected_problem.code),
					tostring(actual.ordine), tostring(actual.code)
				))
			end
		end
	end

	return {
		input = case.name,
		expected = string.format(
			"%d entries, %d problems", #case.expect_entries, #case.expect_problems
		),
		passed = (#mismatches == 0),
		mismatch = (#mismatches > 0) and table.concat(mismatches, "; ") or nil,
	}
end

--[[
labels_of(group)
------------------
Private helper, used only by run_group_case(). Extracts a group's
entries as a plain list of `voce` labels, in order, for comparison
against a case's `voce_order`.
--]]
local function labels_of(group)
	local labels = {}
	for _, e in ipairs(group.entries) do
		table.insert(labels, e.voce)
	end
	return labels
end

--[[
labels_match(actual_labels, expected_labels)
-----------------------------------------------
Private helper, used only by run_group_case(). Exact, order-sensitive
comparison of two label lists.

Returns:
  ok       (boolean)
  mismatch (string|nil)
--]]
local function labels_match(actual_labels, expected_labels)
	if #actual_labels ~= #expected_labels then
		return false, string.format(
			"entries: expected %d, got %d", #expected_labels, #actual_labels
		)
	end
	for i, expected_label in ipairs(expected_labels) do
		if actual_labels[i] ~= expected_label then
			return false, string.format(
				"entries[%d]: expected voce=%s, got voce=%s",
				i, tostring(expected_label), tostring(actual_labels[i])
			)
		end
	end
	return true, nil
end

--[[
run_group_case(case)
----------------------
Private helper. Runs a single GROUP_CASES entry against
Module:ChronoSpine/group's M.group(), checking the number of groups,
each group's `kind`, each group's `key` fields (partial match, via
compare_fields -- see its docstring), and each group's contents
(exact, order-sensitive label match, via labels_match()).

Returns:
  (table) { input, expected (string, for display), passed (boolean),
            mismatch (string|nil) } -- same shape as run_case() and
            run_manual_case(), so all three fit in one report table.
--]]
local function run_group_case(case)
	local groups = group_module.group(case.entries, case.raggruppa)
	local mismatches = {}

	if #groups ~= #case.expect then
		table.insert(mismatches, string.format(
			"groups: expected %d, got %d", #case.expect, #groups
		))
	else
		for i, expected_group in ipairs(case.expect) do
			local actual_group = groups[i]

			if actual_group.kind ~= expected_group.kind then
				table.insert(mismatches, string.format(
					"groups[%d].kind: expected %s, got %s",
					i, tostring(expected_group.kind), tostring(actual_group.kind)
				))
			end

			local key_ok, key_mismatch = compare_fields(actual_group.key, expected_group.key)
			if not key_ok then
				table.insert(mismatches, "groups[" .. i .. "].key." .. key_mismatch)
			end

			local labels_ok, labels_mismatch = labels_match(
				labels_of(actual_group), expected_group.voce_order
			)
			if not labels_ok then
				table.insert(mismatches, "groups[" .. i .. "]." .. labels_mismatch)
			end
		end
	end

	return {
		input = case.name,
		expected = string.format("%d groups", #case.expect),
		passed = (#mismatches == 0),
		mismatch = (#mismatches > 0) and table.concat(mismatches, "; ") or nil,
	}
end

--[[
run_i18n_case(case)
---------------------
Private helper. Dispatches to whichever Module:ChronoSpine/i18n
function `case.fn` names, with `case.input` as its argument(s), and
checks the result against `case.expect` with plain equality.

Returns:
  (table) -- same shape as the other run_*_case() functions.
--]]
local function run_i18n_case(case)
	local actual
	if case.fn == "format_date" then
		actual = i18n.format_date(case.input)
	elseif case.fn == "format_stardate" then
		actual = i18n.format_stardate(case.input)
	elseif case.fn == "group_label" then
		actual = i18n.group_label(case.input.key, case.input.raggruppa, case.input.kind)
	else
		actual = nil
	end

	local passed = (actual == case.expect)

	return {
		input = case.name,
		expected = case.expect,
		passed = passed,
		mismatch = (not passed) and
			("expected '" .. tostring(case.expect) .. "', got '" .. tostring(actual) .. "'") or nil,
	}
end

--[[
run_render_case(case)
------------------------
Private helper. Calls `case.call()` and checks its result the way
described in RENDER_CASES' header comment above: either it must be
`nil` (`case.expect_nil`), or every substring in
`case.expect_contains` must be present and every substring in
`case.expect_not_contains` must be absent.

Returns:
  (table) -- same shape as the other run_*_case() functions.
--]]
local function run_render_case(case)
	local actual = case.call()
	local mismatches = {}

	if case.expect_nil then
		if actual ~= nil then
			table.insert(mismatches, "expected nil, got a non-nil result")
		end
	else
		actual = actual or ""
		for _, substring in ipairs(case.expect_contains or {}) do
			if not actual:find(substring, 1, true) then
				table.insert(mismatches, "missing expected substring: " .. substring)
			end
		end
		for _, substring in ipairs(case.expect_not_contains or {}) do
			if actual:find(substring, 1, true) then
				table.insert(mismatches, "unexpectedly contains: " .. substring)
			end
		end
	end

	return {
		input = case.name,
		expected = case.expect_nil and "nil" or string.format(
			"%d substring(s) present, %d absent",
			#(case.expect_contains or {}), #(case.expect_not_contains or {})
		),
		passed = (#mismatches == 0),
		mismatch = (#mismatches > 0) and table.concat(mismatches, "; ") or nil,
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

	for _, case in ipairs(MANUAL_CASES) do
		table.insert(results, { module_name = "manual", info = run_manual_case(case) })
	end

	for _, case in ipairs(GROUP_CASES) do
		table.insert(results, { module_name = "group", info = run_group_case(case) })
	end

	for _, case in ipairs(I18N_CASES) do
		table.insert(results, { module_name = "i18n", info = run_i18n_case(case) })
	end

	for _, case in ipairs(RENDER_CASES) do
		table.insert(results, { module_name = "render", info = run_render_case(case) })
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