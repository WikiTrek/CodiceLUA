-- [P2G] Auto upload by PageToGitHub on 2024-07-25T23:11:39+02:00
-- [P2G] This code from page Modulo:wikitrek-Images
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
-- Take parameters out of the frame and pass them to p._buildUniversalIncipit().
-- Return the populated <gallery> element.
-- See https://www.mediawiki.org/wiki/Help:Images#Rendering_a_gallery_of_images
--
-- Example:
-- If there are multiple images, then create a carousel
-- Example from https://data.wikitrek.org/wiki/Item:Q5641
-- <gallery mode="slideshow" widths=100% heights=350px>
-- File:Dis1x3 discovery1031.jpg|caption|alt=alt language
-- File:Dis3x6 discovery1031a.jpg|caption|alt=alt language
-- </gallery>
--
-- @param {imagesList} Array containing images names
-- @return {string} The full incipit wikitext
--------------------------------------------------------------------------------
function p.buildCarousel(imagesList)
	local GalleryTag = mw.html.create('gallery')
	local FilesList
	
	for _, Image in pairs(imagesList) do
		File = mw.title.new(Image, "File")
		
		FileTitle = "File:" .. FileName
		if File.exists then
			FileCaption = frame:expandTemplate{title = FileTitle}
		else
			FileCaption = "Immagine da Commons"
		end
		
		FilesList = FilesList .. FileTitle .. "|" .. FileCaption .. "|alt=" .. FileCaption .. string.char(10)

	end
	
	GalleryTag
		:attr('mode', 'slideshow')
		:attr('widths', '100%')
		:attr('heights', '350px')
		--:wikitext(ImageString .. DataString .. "<ul>" .. QualiString .. "</ul>" .. "[[Categoria:Pagine originariamente convertite da HT]]" .. "[[Categoria:Nuovo box HT]]") --.. string.char(10) .. "[[Categoria:Pagine originariamente convertite da HT]]")
		:wikitext(filesList)
	
	return tostring(galleryTag)
end
return p