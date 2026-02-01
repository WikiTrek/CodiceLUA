-- [P2G] Auto upload by PageToGitHub on 2026-02-01T18:16:18+01:00
-- [P2G] This code from page Modulo:wikitrek-Stardate
--- Converts between real-world Gregorian dates and Star Trek TNG-era stardates.
--
-- Convention used (widely accepted TNG baseline):
--   Stardate 41000.0  =  1 January 2364
--   1000 stardate units span one full year
--   Each stardate unit therefore equals 1/1000 of a year
--
-- The module also exposes internal functions (_toStardate, _toRealDate)
-- so that other Lua modules can require() it and call those directly
-- without needing a frame object.
--
-- @module Stardate
-- @author Luca Mauri
-- @license GPLv2
-- @Keyword wikitrek

local p = {}

--- Constants
-- Epoch: Stardate 41000.0 = 1 January 2364 (day 1 of the year)
local EPOCH_YEAR      = 2364
local EPOCH_STARDATE  = 41000.0

--- Private helpers
--- Return true when y is a leap year.
-- @private
-- @param  y  Year to test (number).
-- @return boolean  True if y is a leap year.
local function isLeapYear(y)
    return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
end

--- Total days in a given year (365 or 366).
-- @private
-- @param  y  Year (number).
-- @return number  365 for a common year, 366 for a leap year.
local function daysInYear(y)
    return isLeapYear(y) and 366 or 365
end

--- Days in each month for a common year [1] and a leap year [2].
-- @private
-- @type  table
local DAYS_IN_MONTH = {
    { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },   -- [1] common
    { 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }    -- [2] leap
}

--- Return the day-of-year (1-based) for a given date.
-- @private
-- @param  y    Year (number).
-- @param  m    Month, 1-12 (number).
-- @param  d    Day of month, 1-31 (number).
-- @return number  Day of year (1 = Jan 1).
local function dayOfYear(y, m, d)
    local idx   = isLeapYear(y) and 2 or 1
    local total = 0
    for i = 1, m - 1 do
        total = total + DAYS_IN_MONTH[idx][i]
    end
    return total + d
end

--- Given a year and a 1-based day-of-year, return the month and day.
-- @private
-- @param  y    Year (number).
-- @param  doy  Day of year, 1-based (number).
-- @return number  Month (1-12).
-- @return number  Day of month (1-31).
local function monthDayFromDOY(y, doy)
    local idx       = isLeapYear(y) and 2 or 1
    local remaining = doy
    for m = 1, 12 do
        if remaining <= DAYS_IN_MONTH[idx][m] then
            return m, remaining
        end
        remaining = remaining - DAYS_IN_MONTH[idx][m]
    end
    -- Safety fallback (should never be reached with valid input)
    return 12, 31
end

--- Zero-pad a number to a given width.
-- @private
-- @param  n      Number to pad (number).
-- @param  width  Minimum character width (number).
-- @return string  Zero-padded string representation.
local function zeroPad(n, width)
    local s = tostring(math.floor(n))
    while #s < width do
        s = "0" .. s
    end
    return s
end

--- Trim whitespace from a string; return nil if the result is empty.
-- @private
-- @param  s  Input value (any type).
-- @return string|nil  Trimmed string, or nil if s is not a string or is blank.
local function trimOrNil(s)
    if type(s) ~= "string" then return nil end
    s = s:match("^%s*(.-)%s*$")
    return s ~= "" and s or nil
end

-- ─── Core conversion logic ───────────────────────────────────────────────────

--- Convert a Gregorian date to a TNG stardate.
-- Each completed year from the epoch contributes exactly 1000 units;
-- the position within the current year is expressed as a 0-1 fraction
-- of that year's actual day-count (correctly handling leap years).
-- @private
-- @param  y  Year (number).
-- @param  m  Month, 1-12 (number).
-- @param  d  Day of month, 1-31 (number).
-- @return number  Stardate value (e.g. 41153.0).
local function dateToStardate(y, m, d)
    local units      = (y - EPOCH_YEAR) * 1000
    local fracInYear = (dayOfYear(y, m, d) - 1) / daysInYear(y)
    return EPOCH_STARDATE + units + fracInYear * 1000
end

--- Convert a TNG stardate to a Gregorian date.
-- Walks whole-year blocks of 1000 units to find the target year, then
-- maps the remaining fractional units back to a day-of-year using rounding
-- (not truncation) so that the last day of every year survives the round-trip.
-- @private
-- @param  sd  Stardate value (number), e.g. 41153.7.
-- @return number  Year.
-- @return number  Month (1-12).
-- @return number  Day of month (1-31).
local function stardateToDate(sd)
    local y         = EPOCH_YEAR
    local remaining = sd - EPOCH_STARDATE   -- total stardate units from epoch

    -- Walk forward or backward by whole years
    if remaining >= 0 then
        while remaining >= 1000 do
            remaining = remaining - 1000
            y = y + 1
        end
    else
        while remaining < 0 do
            y = y - 1
            remaining = remaining + 1000
        end
    end

    -- remaining is now in [0, 1000) — the fractional units within year y.
    -- Map to a 1-based day-of-year using rounding to avoid off-by-one
    -- on dates that sit at or very near a day boundary.
    local fracInYear = remaining / 1000
    local doy        = math.floor(fracInYear * daysInYear(y) + 0.5) + 1

    -- Clamp to valid range for the year
    if doy < 1                then doy = 1                end
    if doy > daysInYear(y)    then doy = daysInYear(y)    end

    local m, d = monthDayFromDOY(y, doy)
    return y, m, d
end

-- ─── Input validation ────────────────────────────────────────────────────────

--- Validate and parse a date string in yyyy-mm-dd format.
-- @private
-- @param  dateStr  Date string to parse (string).
-- @return number|nil  Year on success, or nil on failure.
-- @return number|string  Month on success, or an error message string on failure.
-- @return number|nil  Day on success, or nil on failure.
local function parseDate(dateStr)
    if not dateStr then
        return nil, "Missing 'date' parameter."
    end

    local y, m, d = dateStr:match("^(%d+)-(%d+)-(%d+)$")
    if not y then
        return nil, "Invalid date format '" .. dateStr ..
            "'. Expected yyyy-mm-dd (e.g. 2364-03-15)."
    end

    y, m, d = tonumber(y), tonumber(m), tonumber(d)

    if m < 1 or m > 12 then
        return nil, "Month must be between 1 and 12 (got " .. m .. ")."
    end

    local idx    = isLeapYear(y) and 2 or 1
    local maxDay = DAYS_IN_MONTH[idx][m]
    if d < 1 or d > maxDay then
        return nil, "Day must be between 1 and " .. maxDay ..
            " for month " .. m .. " of " .. y .. " (got " .. d .. ")."
    end

    return y, m, d
end

--- Validate and parse a stardate string.
-- @private
-- @param  sdStr  Stardate string to parse (string).
-- @return number|nil  Stardate as a number on success, or nil on failure.
-- @return string|nil  Error message on failure, or nil on success.
local function parseStardate(sdStr)
    if not sdStr then
        return nil, "Missing 'stardate' parameter."
    end

    local sd = tonumber(sdStr)
    if not sd then
        return nil, "Invalid stardate '" .. sdStr ..
            "'. Must be a number (e.g. 41153.7)."
    end

    if sd < 0 then
        return nil, "Stardate cannot be negative (got " .. sdStr .. ")."
    end

    return sd
end

--- Validate the format parameter.
-- @private
-- @param  fmtStr  Format string to validate (string or nil).
-- @return string|nil  Validated format ("full" or "year"), or nil on failure.
-- @return string|nil  Error message on failure, or nil on success.
local function parseFormat(fmtStr)
    local fmt = fmtStr or "full"
    if fmt ~= "full" and fmt ~= "year" then
        return nil, "Invalid format '" .. fmt ..
            "'. Allowed values: 'full' (default) or 'year'."
    end
    return fmt
end

-- ─── Internal API (callable from other Lua modules via require) ──────────────

--- Convert a date to a formatted stardate string.
-- @param  y       Year (number).
-- @param  m       Month, 1-12 (number).
-- @param  d       Day of month, 1-31 (number).
-- @param  format  Output format: "full" for one-decimal stardate, "year" for
--                 millennium prefix only (string).
-- @return string  Formatted stardate (e.g. "41202.2" or "41000x").
function p._toStardate(y, m, d, format)
    local sd = dateToStardate(y, m, d)

    if format == "year" then
        -- Return the millennium prefix with a trailing 'x' (e.g. "41000x")
        local prefix = math.floor(sd / 1000) * 1000
        return tostring(prefix) .. "x"
    else
        return string.format("%.1f", sd)
    end
end

--- Convert a stardate to a formatted real date string.
-- @param  sd      Stardate value (number), e.g. 41153.7.
-- @param  format  Output format: "full" for yyyy-mm-dd, "year" for year only
--                 (string).
-- @return string  Formatted date (e.g. "2364-02-26" or "2364").
function p._toRealDate(sd, format)
    local y, m, d = stardateToDate(sd)

    if format == "year" then
        return tostring(y)
    else
        return zeroPad(y, 4) .. "-" .. zeroPad(m, 2) .. "-" .. zeroPad(d, 2)
    end
end

-- ─── Public entry points (called via {{#invoke:}}) ──────────────────────────
-- Arguments are read from the *parent* frame (i.e. the template that contains
-- the #invoke call), which is the standard Scribunto pattern when the module
-- is meant to be wrapped in a template.

--- Convert a real date to a TNG-era stardate.
-- Reads named parameters from the calling template's frame.
-- @param  frame  Scribunto frame object (provided automatically by MediaWiki).
-- @return string  The computed stardate, or an HTML error span on invalid input.
-- @usage
-- From a wrapper template:
--   <nowiki>{{#invoke:Stardate | toStardate | date=2364-03-15 }}</nowiki>
--   <nowiki>{{#invoke:Stardate | toStardate | date=2364-03-15 | format=year }}</nowiki>
function p.toStardate(frame)
    local args  = frame:getParent().args
    local date  = trimOrNil(args["date"])
    local fmt   = trimOrNil(args["format"])

    local format, fmtErr = parseFormat(fmt)
    if not format then
        return '<span class="error">Stardate error: ' .. fmtErr .. '</span>'
    end

    local y, m, d = parseDate(date)
    if not y then
        -- When parseDate fails, y is nil and m holds the error string
        return '<span class="error">Stardate error: ' .. m .. '</span>'
    end

    return p._toStardate(y, m, d, format)
end

--- Convert a TNG-era stardate to a real date.
-- Reads named parameters from the calling template's frame.
-- @param  frame  Scribunto frame object (provided automatically by MediaWiki).
-- @return string  The computed date, or an HTML error span on invalid input.
-- @usage
-- From a wrapper template:
--   <nowiki>{{#invoke:Stardate | toRealDate | stardate=41153.7 }}</nowiki>
--   <nowiki>{{#invoke:Stardate | toRealDate | stardate=41153.7 | format=year }}</nowiki>
function p.toRealDate(frame)
    local args  = frame:getParent().args
    local sdStr = trimOrNil(args["stardate"])
    local fmt   = trimOrNil(args["format"])

    local format, fmtErr = parseFormat(fmt)
    if not format then
        return '<span class="error">Stardate error: ' .. fmtErr .. '</span>'
    end

    local sd, sdErr = parseStardate(sdStr)
    if not sd then
        return '<span class="error">Stardate error: ' .. sdErr .. '</span>'
    end

    return p._toRealDate(sd, format)
end

return p