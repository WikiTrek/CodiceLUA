-- [P2G] Auto upload by PageToGitHub on 2024-02-25T23:19:20+01:00
-- [P2G] This code from page Modulo:wikitrek-Locations
-- <nowiki>
--------------------------------------------------------------------------------
-- This module handles printout and semantic property for location of objects
-- Comments are compatible with LDoc https://github.com/lunarmodules/ldoc
--
-- Conceptual model
-- Quadrant
-- |
-- - Sector
--   |
--   - Star system
--     |
--     - Planet
--
-- @module p
-- @author Luca Mauri [[Utente:Lucamauri]]
-- @keyword: wikitrek
-- Keyword: wikitrek
--------------------------------------------------------------------------------

local PropertiesOnTree = require('Modulo:DTFunzioniComuni').PropertiesOnTree

local p = {}

--------------------------------------------------------------------------------
-- Take parameters out of the frame and pass them to p._buildUniversalIncipit().
-- Return the result.
--
-- @param {Frame} Info from MW session
-- @return {string} The full incipit wikitext
--------------------------------------------------------------------------------
function p.buildUniversalIncipit(frame)
	local args = frame:getParent().args
	return p._buildUniversalIncipit(args)
end

--------------------------------------------------------------------------------
-- Build and return the page incipit wikitext.
--
-- @param {Frame} Info from MW session
-- @return {string} The full incipit wikitext
--------------------------------------------------------------------------------
function p._buildUniversalIncipit(args)
	local ret = {}
	local fullUrl = mw.uri.fullUrl
	local format = string.format
	for i, username in ipairs(args) do
		local url = fullUrl(mw.site.namespaces.User.name .. ':' .. username)
		url = tostring(url)
		local label = args['label' .. tostring(i)]
		url = format('[%s %s]', url, label or username)
		ret[#ret + 1] = url
	end
	ret = mw.text.listToText(ret)
	ret = '<span class="plainlinks">' .. ret .. '</span>'
	return ret
end

--------------------------------------------------------------------------------
-- Build and return the list of shortcodes for series, season and episode
--
-- @param {Frame} Info from MW session
-- @return {string} The full incipit wikitext
--------------------------------------------------------------------------------
function p.BuildShortCode(frame)
	local args = frame:getParent().args
	return p._BuildShortCode(args)
end

--------------------------------------------------------------------------------
-- Build and return the list of shortcodes for series, season and episode
--
-- @param {Frame} Info from MW session
-- @return {string} The full incipit wikitext
--------------------------------------------------------------------------------
function p.ShortCodeFromProdNo(frame)
	local ProdNo = frame.args[1]
	
	p._BuildShortCode("", tonumber(string.sub(ProdNo, 1, 1)), tonumber(string.sub(ProdNo, 2)))
end

--------------------------------------------------------------------------------
-- Gets episode's data from DataTrek and passes them
--
-- @param {Frame} Info from MW session
--------------------------------------------------------------------------------
function p.ShortCodeFromDT(frame)
	local CurrentEntity = mw.wikibase.getEntity()
	local Acronym
	local Season
	local Episode
	
	if CurrentEntity.claims['P18'] == nil then
		return ""
	else
		Acronym = PropertiesOnTree("P25", 3, false, false, true) or "Err"
		Season = tonumber(CurrentEntity.claims['P18'][1].mainsnak.datavalue.value['amount'])
		Episode = tonumber(CurrentEntity.claims['P178'][1].mainsnak.datavalue.value['amount'])
		return p._BuildShortCode(Acronym, Season, Episode)
	end
end

--------------------------------------------------------------------------------
-- Set the Semantic property related to episode shortcodes for
-- series, season and episode
--
-- @param {Series} Acronym of the series' name
-- @param {Season} Ordinal of the season
-- @param {Season} Ordinal of the episode in the season
--------------------------------------------------------------------------------
function p._BuildShortCode(Series, Season, Episode)
	--local Templates = {"S0.E00", " s00e00", "s00e000"}
	local Templates = {"%dx%02d", "S%d.E%02d", " s%02de%02d", "s%02de%03d"}
	
	if Season < 1 or Season > 99 then
		Season = 0
	end
	if Episode < 1 or Episode > 99 then
		Episode = 0
	end
	Series = string.upper(string.sub(Series, 1, 3))
	
	for _, Template in pairs(Templates) do
		mw.smw.set("Codice breve=" .. Series .. " " .. string.format(Template, Season, Episode)) 
	end
end
return p