-- [P2G] Auto upload by PageToGitHub on 2023-12-08T18:31:38+01:00
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
-- Function to construct content for Box Secondario
-- Specific for Template:IncipitUniversale
--
-- @param frame Data from MW session
-- @return String with HTML content
--------------------------------------------------------------------------------
function p.BoxSecContent(frame)
	local FinalString
	
	FinalString = "<span class='titoletto'>Primo</span>Test 1<hr /><span class='titoletto'>Altri</span>Test 2"
	
	return FinalString
end
return p