-- [P2G] Auto upload by PageToGitHub on 2023-12-02T10:23:40+01:00
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
	return p._main(args)
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
-- Function to launch template for DataBoxes
-- Specific for Template:IncipitUniversale
--
-- @param frame Data from MW session
-- @return String with expanded templates
--------------------------------------------------------------------------------
function p.UniversalBoxes(frame)
	local FinalString
	
	FinalString = frame:expandTemplate{title = 'BoxSecInstallazioni'}
	
	return FinalString
end
return p