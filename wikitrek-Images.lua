-- Upload automatica di PageToGitHub il 2026-07-12T23:18:10+02:00
-- Questo codice proviene da Modulo:wikitrek-Images
-- <nowiki>
--------------------------------------------------------------------------------
-- This module handles image manipulation
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
-- Build a <gallery> element ("carousel") from a list of image (File:) names.
-- For each image, expands the wiki's caption template for that file (via
-- frame:expandTemplate) to build its caption, then assembles the wikitext
-- for MediaWiki's <gallery> tag.
-- See https://www.mediawiki.org/wiki/Help:Images#Rendering_a_gallery_of_images
--
-- Example output:
-- <gallery mode="slideshow" widths=100% heights=350px>
-- File:Dis1x3 discovery1031.jpg|caption|alt=alt language
-- File:Dis3x6 discovery1031a.jpg|caption|alt=alt language
-- </gallery>
--
-- @param {table} imagesList Array of image names (without the "File:" prefix)
-- @param {Frame} [frame] Optional MediaWiki frame, used to expand the caption
--   template for each file. Defaults to the current frame if not supplied,
--   so this function works both as a template entry point and as a plain
--   helper called from other Lua modules.
-- @return {string} The wikitext for the populated <gallery> element
--------------------------------------------------------------------------------
function p.buildCarousel(imagesList, frame)
	-- Fall back to the current frame so this still works if a caller
	-- forgets to pass one, or calls this as a pure helper function.
	frame = frame or mw.getCurrentFrame()

	local galleryTag = mw.html.create('gallery')

	-- Start as an empty string, not nil: the original code declared this
	-- with no initial value, so the very first ".." concatenation in the
	-- loop below would fail with "attempt to concatenate a nil value".
	local filesList = ''

	for _, imageName in pairs(imagesList) do
		-- 'local' here matters: without it, these become true Lua
		-- globals shared by the whole module environment, which can
		-- leak stale values into unrelated calls on the same page.
		local file = mw.title.new(imageName, "File")
		local fileTitle = "File:" .. imageName

		local fileCaption
		if file.exists then
			fileCaption = frame:expandTemplate{title = fileTitle}
		else
			fileCaption = "Immagine da Commons"
		end

		filesList = filesList .. fileTitle .. "|" .. fileCaption .. "|alt=" .. fileCaption .. string.char(10)
	end

	galleryTag
		:attr('mode', 'slideshow')
		:attr('widths', '100%')
		:attr('heights', '350px')
		:wikitext(filesList)

	return tostring(galleryTag)
end

return p