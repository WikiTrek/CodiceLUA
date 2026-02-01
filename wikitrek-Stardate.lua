-- [P2G] Auto upload by PageToGitHub on 2026-02-01T11:59:58+01:00
-- [P2G] This code from page Modulo:wikitrek-Stardate
--- Module:Stardate
-- Bidirectional conversion between Gregorian dates and Star Trek TNG-era stardates.
-- @module Stardate
-- @author Luca Mauri
-- @license GPLv2
-- @Keyword wikitrek
local p = {}

-- Days in each month (non-leap year)
local DAYS_IN_MONTH = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
local REFERENCE_YEAR = 2323  -- Stardate year 0
local DAYS_PER_YEAR = 365.25
local STARDATE_MULTIPLIER = 1000

--- Check if year is leap year
-- @param year number Year to check
-- @treturn boolean True if leap year
local function _isLeapYear(year)
    return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

--- Get days in month accounting for leap years
-- @param month number 1-12
-- @param year number
-- @treturn number Days in month
local function _getDaysInMonth(month, year)
    if month == 2 and _isLeapYear(year) then return 29 end
    return DAYS_IN_MONTH[month]
end

--- Calculate day of year (1-366)
-- @param year number
-- @param month number 1-12  
-- @param day number 1-max
-- @treturn number Day of year
local function _dayOfYear(year, month, day)
    local doy = day
    for m = 1, month - 1 do
        doy = doy + _getDaysInMonth(m, year)
    end
    return doy
end

--- Parse date string (ISO, English, Italian formats)
-- @param dateStr string Date string to parse
-- @treturn[1] table|nil {year, month, day} or nil on error
-- @treturn[2] string|nil Error message or nil
local function _parseDate(dateStr)
    if not dateStr or dateStr == "" then
        return nil, "Nessuna data fornita"
    end
    
    dateStr = mw.ustring.gsub(dateStr, "^%s*(.-)%s*$", "%1")
    
    -- ISO: YYYY-MM-DD or YYYY/MM/DD
    local y, m, d = mw.ustring.match(dateStr, "^(%d{4})[-/](%d{1,2})[-/](%d{1,2})$")
    if y then
        return {year=tonumber(y), month=tonumber(m), day=tonumber(d)}, nil
    end
    
    -- Day Month Year (English/Italian): 31 January 2024, 31 gennaio 2024
    local dayStr, monthStr, yearStr = mw.ustring.match(dateStr, "^(%d{1,2})%s+([%wàèìòùáéíóú]+)%s+(%d{4})$")
    if dayStr then
        local monthNum = _parseMonth(monthStr:lower())
        if monthNum then
            return {year=tonumber(yearStr), month=monthNum, day=tonumber(dayStr)}, nil
        end
    end
    
    return nil, "Formato non valido. Usa: YYYY-MM-DD o '31 gennaio 2024'"
end

--- Parse month name (English/Italian, full/abbrev)
-- @param monthStr string Month name
-- @treturn number|nil Month number 1-12 or nil
local function _parseMonth(monthStr)
    local months = {
        gen=1, feb=2, mar=3, apr=4, mag=5, giu=6, lug=7, 
        ago=8, set=9, ott=10, nov=11, dic=12,
        jan=1, feb=2, mar=3, apr=4, may=5, jun=6, jul=7,
        aug=8, sep=9, oct=10, nov=11, dec=12
    }
    return months[monthStr:sub(1,3)]
end

--- Validate date components
-- @param year number
-- @param month number 1-12
-- @param day number 1-max
-- @treturn[1] boolean True if valid
-- @treturn[2] string|nil Error message or nil
local function _validateDate(year, month, day)
    if year < 1900 or year > 3000 or month < 1 or month > 12 then
        return false, "Data fuori range (1900-3000)"
    end
    if day < 1 or day > _getDaysInMonth(month, year) then
        return false, "Giorno non valido"
    end
    return true, nil
end

--- Date to stardate using TNG formula
-- @param year number
-- @param month number 1-12
-- @param day number 1-31
-- @treturn number Stardate
local function _dateToStardate(year, month, day)
    local doy = _dayOfYear(year, month, day)
    local yearsSinceRef = year - REFERENCE_YEAR
    return (yearsSinceRef + doy / DAYS_PER_YEAR) * STARDATE_MULTIPLIER
end

--- Stardate to date
-- @param stardate number
-- @treturn table {year, month, day}
local function _stardateToDate(stardate)
    local yearsSinceRef = math.floor(stardate / STARDATE_MULTIPLIER)
    local yearFrac = (stardate / STARDATE_MULTIPLIER) - yearsSinceRef
    local year = REFERENCE_YEAR + yearsSinceRef
    local doy = math.floor(yearFrac * DAYS_PER_YEAR) + 1
    
    local month = 1
    local day = doy
    while day > _getDaysInMonth(month, year) do
        day = day - _getDaysInMonth(month, year)
        month = month + 1
    end
    
    return {year=year, month=month, day=day}
end

--- Format date for output
-- @param date table {year, month, day}
-- @param lang string "en" or "it" (default "en")
-- @treturn string Formatted date
local function _formatDate(date, lang)
    local months = lang == "it" and {
        "gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno",
        "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"
    } or {
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    }
    local monthName = months[date.month]
    if lang == "it" then
        return string.format("%d %s %d", date.day, monthName, date.year)
    else
        return string.format("%s %d, %d", monthName, date.day, date.year)
    end
end

--[[
Convert real date to stardate

@param frame table MediaWiki frame object
@tparam[opt=date] string frame.args.date|frame.args[1] Date string
@treturn string Stardate (1 decimal) or HTML error message

Usage:
{{#invoke:Stardate|dateToStardate|2024-01-31}}
{{#invoke:Stardate|dateToStardate|date=31 gennaio 2024}}
]]
function p.dateToStardate(frame)
    local args = frame.args
    local dateStr = args.date or args[1] or ""
    
    local date, err = _parseDate(dateStr)
    if not date then
        return '<span style="color:#d00;font-weight:bold">ERRORE: ' .. err .. '</span>'
    end
    
    local valid, valErr = _validateDate(date.year, date.month, date.day)
    if not valid then
        return '<span style="color:#d00;font-weight:bold">ERRORE: ' .. valErr .. '</span>'
    end
    
    return string.format("%.1f", _dateToStardate(date.year, date.month, date.day))
end

--[[
Convert stardate to real date

@param frame table MediaWiki frame object
@tparam[opt=stardate] string frame.args.stardate|frame.args[1] Stardate number
@tparam[opt=lang] string frame.args.lang Output language ("en"|"it")
@treturn string Formatted date or HTML error message

Usage:
{{#invoke:Stardate|stardateToDate|47532.5}}
{{#invoke:Stardate|stardateToDate|stardate=47532.5|lang=it}}
]]
function p.stardateToDate(frame)
    local args = frame.args
    local stardateStr = args.stardate or args[1] or ""
    local lang = args.lang or "en"
    
    local stardate = tonumber(stardateStr)
    if not stardate then
        return '<span style="color:#d00;font-weight:bold">ERRORE: Stardate non numerica</span>'
    end
    
    local date = _stardateToDate(stardate)
    return _formatDate(date, lang)
end

return p