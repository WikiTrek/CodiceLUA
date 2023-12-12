-- [P2G] Auto upload by PageToGitHub on 2023-12-12T23:25:32+01:00
-- [P2G] This code from page Modulo:wikitrek-BeginEndPage
-- <nowiki>
--------------------------------------------------------------------------------
-- This module handles incipit and epilogue of pages.
-- Comments are compatible with LDoc https://github.com/lunarmodules/ldoc
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
function p._BuildShortCode(Series, Season, Episode)
	local Templates = {"S0.E00", " s00e00", "s00e000"}
	local Notations = {}
	
	if Season < 1 or Season > 99 then
		Season = 0
	end
	if Episode < 1 or Episode > 99 then
		Episode = 0
	end
	Series = string.upper(string.sub(Series, 1, 3))
	
	for _, Template in pairs(Templates) do
	end
end









--------------------------------------------------------------------------------
-- Function to launch template for DataBoxes
-- Specific for Template:IncipitUniversale
--
-- @param frame Data from MW session
-- @return String with expanded templates
--------------------------------------------------------------------------------
function p.SecondaryBox(frame)
	local FinalString
	local NSPrefix = "Template:"
	local PropertyNumber = "P177"
	local TemplateName
	
	--FinalString = PropertiesOnTree("P177", 3, false, false, true)[1]
	--FinalString = string.sub(PropertiesOnTree("P177", 3, false, false, true), string.len(NSPrefix))
	TemplateName = PropertiesOnTree(PropertyNumber, 3, false, false, true)
	if type(TemplateName) == "table" or TemplateName == nil or TemplateName == "" then
		FinalString = ""
	else
		FinalString = frame:expandTemplate{title = string.sub(TemplateName, string.len(NSPrefix) + 1)}
	end
	
	return FinalString
end
return p