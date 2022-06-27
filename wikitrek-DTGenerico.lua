-- [P2G] Auto upload by PageToGitHub on 2022-06-27T12:08:26+02:00
-- [P2G] This code from page Modulo:wikitrek-DTGenerico
-- Keyword: wikitrek
local TableFromArray = require('Modulo:FunzioniGeneriche').TableFromArray
local LabelOrLink = require('Modulo:DTBase').LabelOrLink
local GenericValue = require('Modulo:DTBase').GenericValue
local MakeNavTable = require('Modulo:DTBase').MakeNavTable
--local AffiliationTree = require('Modulo:DTFunzioniComuni').AffiliationTree
--local OperatorTree = require('Modulo:DTFunzioniComuni').OperatorTree
local PropertiesOnTree = require('Modulo:DTFunzioniComuni').PropertiesOnTree

local p = {}
function p.QFromP(Property)
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	return Item['claims'][Property][1].mainsnak.datavalue['value']['id']
end
function p.DIVImage(frame)
	local ImageFileName
	local ImageProperties = {"P11", "P37"}
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local Markup = ""
	
	-- TODO
	-- If there are multiple images, then create a carousel
	-- Example from https://data.wikitrek.org/wiki/Item:Q5641
	-- <gallery mode="slideshow" widths=100% heights=350px>
	-- File:Dis1x3 discovery1031.jpg|caption|alt=alt language
	-- File:Dis3x6 discovery1031a.jpg|caption|alt=alt language
	-- </gallery>
	
	for _, Property in pairs(ImageProperties) do
	if Item['claims'][Property] then
		local FileTitle
		local FileCaption
		local FileName = Item['claims'][Property][1].mainsnak.datavalue['value']
		File = mw.title.new( FileName, "File" )
		
		FileTitle = "File:" .. FileName
		if File.exists then
			FileCaption = frame:expandTemplate{title = FileTitle}
		else
			FileCaption = "Immagine da Commons"
		end
		
		Markup = Markup .. "<div class='separatorebox'>'''Immagine'''</div>" ..  "<div class='contenitoreimgbox'>[[" .. FileTitle .. "|alt=" .. FileCaption .. Property .. "|" .. FileCaption .. "]]<br /><span style='font-size: smaller;'>" .. FileCaption .. "</span></div>"
	end
	end
	
	return Markup
end
function p.Title(frame)
	-- |FileIcona=dsg.png
	local ItemQ
	local TitleText
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	ItemQ = p.QFromP('P14')
	
	TitleText = mw.wikibase.getLabelByLang(ItemQ, 'it')
	if TitleText == nil then
		--Return Q item in case of error processing the label to troubleshoot
		TitleText = ItemQ
	end
	mw.smw.set("Istanza=" .. TitleText)

	return TitleText
end
function p.ListAllP(frame)
	local AllP
	local AllRows = {}
	local HTMLTable
	local CollectionTable = ''
	local ExcludeP = {}
	local POnTree = {}
	local Item = mw.wikibase.getEntity()
	local ItemQ = mw.wikibase.getEntityIdForCurrentPage()
	local IsEpisode = false
	local OperatorName = ""
	local AstroRA = nil
	local AstroD = nil
	local ListProp = {}
	
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	if AddSemantic == nil then
		AddSemantic = true
	end
	
	if frame.args['IsEpisode'] ~= nil then
		IsEpisode = frame.args['IsEpisode']
	end
	
	ExcludeP = {P3 = true, P7 = true, P8 = true, P11 = true, P21 = IsEpisode, P23 = true, P26 = true, P37 = true,  P46 = true, P58 = true, P68 = true, P52 = true, P79 = true, P90 = true}
	
	AllP = mw.wikibase.orderProperties(Item:getProperties())
	--Debug: list unsorted and sorted properties
	--AllRows[#AllRows + 1] = {"getProperties:", Item:getProperties()}
	--AllRows[#AllRows + 1] = {"AllP:", AllP}
	
	PageTitle =  mw.title.getCurrentTitle()
	if (mw.wikibase.getLabelByLang(ItemQ, 'en')) and (mw.wikibase.getLabelByLang(ItemQ, 'en')) ~= PageTitle.text then
		AllRows[#AllRows + 1] = {"In originale:", {mw.wikibase.getLabelByLang(ItemQ, 'en')}}
	end
	if (mw.wikibase.getLabelByLang(ItemQ, 'it')) then
		local ITLabel
		local ITValue
		if IsEpisode or IsBook or IsFilm then
			ITLabel = "Titolo italiano"
		else
			ITLabel = "In italiano"
		end
		ITValue = mw.wikibase.getLabelByLang(ItemQ, 'it')
		if AddSemantic then
			mw.smw.set(ITLabel .. "=" .. ITValue)
		end
		if (mw.wikibase.getLabelByLang(ItemQ, 'it')) ~= PageTitle.text then
			AllRows[#AllRows + 1] = {ITLabel .. ":", {ITValue}}
		end
	end
	
	--Process AKA
	if Item.aliases ~= nil and Item.aliases["it"] ~= nil then
		local AccValues = {}
		for _, Alias in pairs(Item.aliases["it"]) do
			table.insert(AccValues, Alias.value)
		end
		table.insert(AllRows, {"Alias:", AccValues})
	end
	
	--mw.smw.set("AllP=" .. table.concat(AllP, ","))
	for _, Property in ipairs(AllP) do
		table.insert(ListProp, Property)
		if (not ExcludeP[Property]) and Item.claims[Property][1].mainsnak.datatype ~= 'external-id' then
			if Property == "P46" then
				-- Collection
				CollectionTable = string.char(10) .. MakeNavTable(Item.claims[Property][1].qualifiers, Item.claims[Property][1].mainsnak.datavalue.value)
			elseif (Property == "P7" or Property == "P23") and CollectionTable == '' then
				--Previous or Next
				CollectionTable = string.char(10) .. MakeNavTable(Item.claims, nil)
			elseif (Property == "P80" or Property == "P82") then
				--Right Ascension or Declination
				if Property == "P80" then
					--Right ascension
					AstroRA = Item.claims[Property][1].mainsnak.datavalue.value.amount
				else
					--Declination
					AstroD = Item.claims[Property][1].mainsnak.datavalue.value.amount
				end
				
				if (AstroRA ~= nil and AstroD ~= nil) then
					AllRows[#AllRows + 1] = {{"P80 e P82", "Coordinate celesti"}, {p.SkyMapLink(AstroRA, AstroD)}}
				end
			elseif Property == "P14" then
				--Instance
				POnTree = {{"P40", 3, false}, {"P41", 3, false}, {"P88", 3, false}}
				for _, Prop in pairs(POnTree) do
					local PropValue = table.concat(PropertiesOnTree(Prop[1], Prop[2], Prop[3], true))
					if (PropValue ~= nil) and (PropValue ~= "") then
						local PropName = mw.wikibase.getLabelByLang(Prop[1], 'it') or mw.wikibase.getLabel(Prop[1])
						--AllRows[#AllRows + 1] = {{Prop[1], PropName .. ":"}, {PropValue}}
						AllRows[#AllRows + 1] = {{Prop[1], PropName}, {PropValue}}
						if Prop[1] == "P41" then
							--String to be used with P88 Naval Class
							--OperatorName = string.sub(PropValue, 2, -2)
							--OperatorName = string.sub("[[Flotta Stellare]]", 3, -3)
							--OperatorName = string.gsub("[[Flotta Stellare|Flotta Stellare]]", "|.+]]", ""):gsub("%[%[", "") .. " - "
							OperatorName = string.gsub(PropValue, "|.+]]", ""):gsub("%[%[", "") .. " - "
							--mw.smw.set("OperatorName1=" .. OperatorName)
						end
						if AddSemantic then
							--mw.smw.set(PropName .. "=" .. PropValue)
						end
					end
				end
				
				--[==[AllRows[#AllRows + 1] = {{"P40", "Affiliazione:"}, {AffiliationTree(frame)}}
				AllRows[#AllRows + 1] = {{"P41", "Operatore:"}, {OperatorTree(frame)}}
				AllRows[#AllRows + 1] = {{"P88", "Classe navale:"}, {table.concat(PropertiesOnTree("P88", 3, false))}}
				if AddSemantic then
					mw.smw.set("Affiliazione=" .. AffiliationTree(frame))
					mw.smw.set("Operatore=" .. OperatorTree(frame))
				end]==]
				--mw.smw.set("OperatorName2=" .. OperatorName)
			else
				-- Unspecified Property
				local Header = {Property, (mw.wikibase.getLabelByLang(Property, 'it') or mw.wikibase.getLabel(Property))} -- .. ":"} -- or {Property, mw.wikibase.getLabel(Property) .. ":"} --'-' .. Property .. ":"}
				local Values = Item['claims'][Property]
				local AccValues = {}
				--mw.smw.set("OperatorName3=" .. OperatorName)
				for _, SnakValue in pairs(Values) do
					local Value = SnakValue.mainsnak.datavalue['value']
					--mw.smw.set("OperatorName4=" .. OperatorName)
					if (type(Value) == "table") then
						if Property == "P72" then --CASE Assigments
							local Assignment = ""
							if SnakValue.qualifiers ~= nil then
								-- Timeline year
								if SnakValue.qualifiers['P73'] ~= nil then
									Assignment = LabelOrLink(SnakValue.qualifiers['P73'][1].datavalue.value['id']) .. " "
								end
							
								-- Prefix
								if SnakValue.qualifiers['P15'] ~= nil then
									Assignment = Assignment .. SnakValue.qualifiers['P15'][1].datavalue.value .. " "
								end
							end
							
							if AddSemantic then
								Assignment = Assignment .. LabelOrLink(Value['id'], "Assegnazione", true)
							else
								Assignment = Assignment .. LabelOrLink(Value['id'])
							end
							
							-- Suffix
							if SnakValue.qualifiers['P19'] ~= nil then
								Assignment = Assignment .. " " .. SnakValue.qualifiers['P19'][1].datavalue.value --.. " "
							end
							
							if SnakValue.qualifiers ~= nil then
								-- Rank
								if SnakValue.qualifiers['P76'] then
									Assignment = Assignment .. ", " .. LabelOrLink(SnakValue.qualifiers['P76'][1].datavalue.value['id'])
								end
								
								--Occupation
								if SnakValue.qualifiers['P77'] then
									Assignment = Assignment .. ", " .. LabelOrLink(SnakValue.qualifiers['P77'][1].datavalue.value['id'])
								end
							end
							--AccValues[#AccValues + 1] = LabelOrLink(SnakValue.qualifiers['P73'][1].datavalue.value['id']) .. " " .. LabelOrLink(Value['id']) .. ", " .. LabelOrLink(SnakValue.qualifiers['P76'][1].datavalue.value['id']) .. ", " .. LabelOrLink(SnakValue.qualifiers['P77'][1].datavalue.value['id'])
							AccValues[#AccValues + 1] = Assignment
						elseif Value['entity-type'] == 'item' then
							--mw.smw.set("OperatorName5=" .. OperatorName)
							-- Process a generic Item
							local GenericItem
							if AddSemantic then
								GenericItem = LabelOrLink(Value['id'], Header[2], true)
							else
								GenericItem = LabelOrLink(Value['id'])
							end
							--mw.smw.set("OperatorName6=" .. OperatorName)
							-- Prefix
							if SnakValue.qualifiers and SnakValue.qualifiers['P15'] then
								GenericItem = SnakValue.qualifiers['P15'][1].datavalue.value .. " " .. GenericItem
							end
							--mw.smw.set("OperatorName7=" .. OperatorName .. " ( " .. Property)
							--Naval class
							if Property == "P88" then
								--mw.smw.set("OperatorName8=" .. OperatorName .. " ( " .. Property)
								GenericItem = GenericItem .. "[[Category:" .. OperatorName .. mw.wikibase.getEntity(Value['id']).labels['it'].value .. "]]"
								--GenericItem = mw.text.nowiki(GenericItem) .. " -" .. mw.text.nowiki(OperatorName) .. "- "
							end
							--mw.smw.set("OperatorName9=" .. OperatorName)
							--P141 - Related Category
							--Category needs to be linked, not added to the page
							if Property == "P141" then
								GenericItem = string.gsub(GenericItem, "%[%[", "[[:")
							end
							
							-- Suffix
							if SnakValue.qualifiers and SnakValue.qualifiers['P19'] then
								GenericItem = GenericItem .. " " .. SnakValue.qualifiers['P19'][1].datavalue.value
							end
				
							AccValues[#AccValues + 1] = GenericItem --.. "|" .. Header[2] .. "|" .. tostring(AddSemantic)
						elseif SnakValue.mainsnak.datavalue['type'] == 'time' then
							-- "+2367-00-00T00:00:00Z"
							--local Instant = Value['time']
							local Instant = string.sub(Value['time'], 1, 11)
							local OutputFormat = "ITMedia"
							local YearLink = ""
							local PrintDate
							local QualiString = ""
							
							if string.sub(Instant, 7, 8) == "00" or string.sub(Instant, 10, 11) == "00" then
								Instant = Instant:sub(1, 5) .. "-01-01"
								OutputFormat = "SoloAnno"
							end
							
							PrintDate = frame:expandTemplate{title = 'TimeL', args = {Tipo=OutputFormat, Istante=Instant}}
							
							if SnakValue.qualifiers ~= nil then
								if SnakValue.qualifiers['P73'] ~= nil then
									--P73 - Timeline
									YearLink = LabelOrLink(SnakValue.qualifiers['P73'][1].datavalue.value['id'], nil, nil, PrintDate)
									--mw.smw.set("Anno della timeline=" .. Instant)
								elseif SnakValue.qualifiers['P74'] ~= nil then
									--P74 - Event
									YearLink = LabelOrLink(SnakValue.qualifiers['P74'][1].datavalue.value['id'], nil, nil, PrintDate)
								end
								QualiString = " " .. "(" .. p.ProcessQualifiers(SnakValue) .. ")"
							end
							
							if YearLink == "" then
								AccValues[#AccValues + 1] = PrintDate .. QualiString
							else
								AccValues[#AccValues + 1] = YearLink .. QualiString
							end
							
							if AddSemantic then
								--AccValues[#AccValues + 1] = "[[" .. Header[2] .. "::" .. Value['time'] .. "|" .. frame:expandTemplate{title = 'TimeL', args = {Tipo='ITEstesa', Istante=Value['time']}} .. "]]"
								--AccValues[#AccValues + 1] = "[[" .. Header[2] .. "::" .. Instant .. "|" .. frame:expandTemplate{title = 'TimeL', args = {Tipo=OutputFormat, Istante=Instant}} .. "]]"
								--AccValues[#AccValues + 1] = "[[" .. Header[2] .. "::" .. Instant .. "|" .. PrintDate .. "]]"
								mw.smw.set(Header[2] .. "=" .. Instant)
							--else
								--AccValues[#AccValues + 1] = frame:expandTemplate{title = 'TimeL', args = {Tipo='ITEstesa', Istante=Value['time']}}
								--AccValues[#AccValues + 1] = frame:expandTemplate{title = 'TimeL', args = {Tipo=OutputFormat, Istante=Instant}}
								--AccValues[#AccValues + 1] = PrintDate
							end
						elseif SnakValue.mainsnak.datavalue.type == 'quantity' then
							local StringValue
							StringValue = string.format('%G', SnakValue.mainsnak.datavalue.value.amount)
							
							if AddSemantic then
								mw.smw.set(Header[2] .. "=" .. StringValue)
							end
							
							local Unit = SnakValue.mainsnak.datavalue.value.unit
							if string.len(Unit) > 5 then
								StringValue = StringValue .. " " .. LabelOrLink(string.sub(Unit, string.find(Unit, "Q"), -1))
							end
							
							AccValues[#AccValues + 1] = StringValue
						elseif SnakValue.mainsnak.datavalue.type == 'string' then
							-- String values
							local StringValue
							StringValue = SnakValue.mainsnak.datavalue.value.amount
							
							if AddSemantic then
								mw.smw.set(Header[2] .. "=" .. StringValue)
							end
							
							AccValues[#AccValues + 1] = StringValue
						else
							AccValues[#AccValues + 1] = 'Unspecified TABLE'
						end
					else
						-- String items
						AccValues[#AccValues + 1] = Value
						if AddSemantic then
							mw.smw.set(Header[2] .. "=" .. Value)
						end
					end
				end
				AllRows[#AllRows + 1] = {Header, AccValues}
			end
		end
	end
	
	mw.smw.set("ListProp=" .. table.concat(ListProp, ", "))
	
	HTMLTable = TableFromArray(AllRows)
	HTMLTable
		:addClass('infobox')
	
	-- return table.concat(AllRows, "<br />" .. string.char(10)) .. string.char(10)
	-- return HTMLTable
	return tostring(HTMLTable) .. CollectionTable
end
function p.ProcessNavigators(frame)
	local CollectionTable = nil
	local Item = mw.wikibase.getEntity()
	local ItemQ = mw.wikibase.getEntityIdForCurrentPage()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	if Item.claims['P7'] or Item.claims['P23'] then
		--Previous or Next
		CollectionTable = MakeNavTable(Item.claims, nil)
	end
	
	if Item.claims['P46'] then
		-- Arc
		if CollectionTable == nil then
			CollectionTable = ""
		end
		CollectionTable = CollectionTable .. string.char(10) .. MakeNavTable(Item.claims["P46"][1].qualifiers, "Arco: " .. Item.claims["P46"][1].mainsnak.datavalue.value)
	end
	
	if CollectionTable ~= nil then
		CollectionTable = "<div class='separatorebox'>'''Navigatore'''</div>" .. CollectionTable
	end
	
	return CollectionTable
end
function p.Incipit(frame)
	if not mw.wikibase.getDescription() then
		if not mw.wikibase.getEntity().claims['P20'] then
		return "'''" .. mw.title.getCurrentTitle().text .. "''' è un " .. mw.wikibase.getLabelByLang(p.QFromP('P14'), 'it') .. string.char(10)
	else
		return "'''" .. mw.title.getCurrentTitle().text .. "''' è " .. 	mw.wikibase.getEntity().claims['P20'][1].mainsnak.datavalue['value'] .. string.char(10)
	end
	else
		--return "'''''" .. mw.title.getCurrentTitle().text .. "'''''" .. " è " .. mw.wikibase.getDescription() .. string.char(10)
		return "'''''" .. mw.title.getCurrentTitle().text .. "'''''" .. " è " .. p.DescrWithTemplate(frame) .. string.char(10)
	end
end
--- Function to expand template contained within description,
-- if present
-- @param frame Data from MW session
-- @return String Text containing URL to SkyMap
function p.SkyMapLink(RA, D)
	-- Example
	-- http://my.sky-map.org/v2?ra=0.709946185638474&de=41.22867547300068&zoom=5&show_grid=1&show_constellation_lines=1&show_constellation_boundaries=1&show_const_names=0&show_galaxies=1&show_box=1&box_ra=0.71166664&box_de=41.266666&box_width=682.6667008&box_height=682.6667008&box_var_size=1
	-- https://secure.sky-map.org/v2
	-- return "https://secure.sky-map.org/v2?ra=" .. RA .. "&de=" .. D
	local URI
	local Int
	local Frac
	local DMS = {}
	
	-- Zoom value 7 is the standard one when searching object in WikiSky
	URI = "http://www.wikisky.org/v2?ra=" .. RA .. "&de=" .. D .. "&zoom=7"
	
	for _, Coord in pairs({RA, D}) do
		Int, Frac = math.modf(Coord)
		table.insert(DMS, Int)
		Int, Frac = math.modf(math.abs(Frac) * 60)
		table.insert(DMS, Int)
		Int, Frac = math.modf(math.abs(Frac) * 60)
		if Frac > 0.5 then
			Int = Int + 1
		end
		
		table.insert(DMS, Int)
	end
	
	--return "[" .. URI .. " " ..  table.concat(DMS, "<sup>s</sup> ") .. "]"
	return "[" .. URI .. " " .. DMS[1] .. "<sup>h</sup> " .. DMS[2] .. "<sup>m</sup> " .. DMS[3] .. "<sup>s</sup>, " .. DMS[4] .. "° " .. DMS[5] .. "′ " .. DMS[6] .. "″]"
end
--- Function to expand template contained within description,
-- if present
-- @param frame Data from MW session
-- @return String Text containing expanded template
function p.DescrWithTemplate(frame)
	local RawDescription = mw.wikibase.getDescription()
	local Pattern = "{{.*}}"
	
	--[==[
	local FinalString = ">"
	for w in string.gfind(RawDescription, Pattern) do
		w = string.gsub(string.gsub(w, "}", ""), "{", "")
      FinalString = FinalString .. w
    end
	return FinalString .. "<"
	]==]
	
	--return string.gsub(RawDescription, Pattern, function (Name) frame:expandTemplate{title = string.gsub(string.gsub(Name, "}", ""), "{", "")} end)
	return string.gsub(RawDescription, Pattern, function (Name) return frame:expandTemplate{title = string.gsub(string.gsub(Name, "}", ""), "{", "")} end)
	--[=[if string.find(RawDescription, '{{') then
		return string.gsub(RawDescription, Pattern, "TEMPLATE")
	else
		return RawDescription
	end]=]
end

function ExpTemplHelper(match, frame)
	return frame:expandTemplate{title = match}
end
--- Function to query for HyperTrek migration data and to construct a proper box
-- to show them, if present
-- @param Snak The Snak the qualifiers belongs to
-- @return String or link with qualifiers value processed
function p.ProcessQualifiers(SnakValue)
	local QualiValue = {}
	
	for _, Qualifier in pairs(SnakValue.qualifiers) do
		
		if Qualifier[1].property == "P4" then
			--Broadcaster
			QualiValue[#QualiValue + 1] = Qualifier[1].datavalue.value
		end
	end
	
	return table.concat(QualiValue, ", ") --string.char(10))
	
	--[=[
	if SnakValue.qualifiers['P73'] ~= nil then
									--P73 - Timeline
									YearLink = LabelOrLink(SnakValue.qualifiers['P73'][1].datavalue.value['id'], nil, nil, PrintDate)
									--mw.smw.set("Anno della timeline=" .. Instant)
								elseif SnakValue.qualifiers['P74'] ~= nil then
									--P74 - Event
									YearLink = LabelOrLink(SnakValue.qualifiers['P74'][1].datavalue.value['id'], nil, nil, PrintDate)
								end
	]=]
end

--- Function to query for HyperTrek migration data and to construct a proper box
-- to show them, if present
-- @param frame Data from MW session
-- @param AddSemantic Boolean value to instruct about adding SMW prefix
-- @return DIV with HT migration in it or empty string
function p.ListHTData(frame)
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	if AddSemantic == nil then
		AddSemantic = true
	end
	
	if Item.claims['P79'] then
		local DIV = mw.html.create('div')
		local DataString
		local ImageString
		local QualiString = ""
		local HTNodes = Item.claims['P79'][1]
		
		ImageString = "[[File:Menu.png|left|middle|30px|HyperTrek logo]]"
		DataString = "Informazioni originali lette dal database di <h2 class='hiddenheaderbold'>HyperTrek</h2> datato " .. frame:expandTemplate{title = 'TimeL', args = {Tipo='ITMedia', Istante=HTNodes.mainsnak.datavalue.value.time}} .. " con i seguenti dettagli: "
		 
		for _, Qualifier in pairs(HTNodes.qualifiers) do
			local QualiProp = Qualifier[1].property
			local QualiName = mw.wikibase.getLabelByLang(QualiProp, 'it')
			local QualiValue = Qualifier[1].datavalue.value
			--QualiString = QualiString .. "<li " .. "title='" .. Qualifier[1].property .. "'>'''" .. mw.wikibase.getLabelByLang(Qualifier[1].property, 'it') .. "''': " .. Qualifier[1].datavalue.value .. "</li>"
			if QualiProp == "P84" then
				--Istante di importazione
				QualiValue = frame:expandTemplate{title = 'TimeL', args = {Tipo='ITEstesa', Istante=QualiValue}}
			end
			
			if AddSemantic then
				mw.smw.set(QualiName .. "=" .. QualiValue)
			end
			--QualiString = QualiString .. "<li " .. "title='" .. QualiProp .. "'>'''" .. QualiName .. "''': " .. QualiValue .. "</li>"
			QualiString = QualiString .. "<li " .. "title='" .. QualiProp .. "'>'''" .. string.gsub(QualiName, "HyperTrek", "HT") .. "''': " .. QualiValue .. "</li>"
		end
		
		DIV
			:attr('id', 'htdata')
			:addClass('htcontainer')
			:wikitext(ImageString .. DataString .. "<ul>" .. QualiString .. "</ul>" .. "[[Categoria:Pagine originariamente convertite da HT]]" .. "[[Categoria:Nuovo box HT]]") --.. string.char(10) .. "[[Categoria:Pagine originariamente convertite da HT]]")
		return tostring(DIV)
	else
		return ""
	end
end

--[==[
function p.ExtLinks(frame)
	local AllRows
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local LinksStatements = Item:getAllStatements('P26')
	for _, LinkStatement in pairs(LinksStatements) do
		local LinkURI = LinkStatement.mainsnak.datavalue['value']
		local LinkTitle = LinkStatement['qualifiers']['P20'][1].datavalue['value']
		local LinkID = LinkStatement['qualifiers']['P19'][1].datavalue['value']
		local LinkWiki = "[" .. LinkURI .. " ''" .. mw.text.nowiki(LinkTitle) .. "''], " .. LinkID
		
		if not AllRows then
			AllRows = "* " .. LinkWiki
		else
			AllRows = AllRows .. string.char(10) .. "* " .. LinkWiki
		end
	end
	
	return AllRows .. string.char(10) .. string.char(10) .. "=== Interwiki ===" .. string.char(10) .. "* " .. frame:expandTemplate{title = 'InterlinkMA', args = {Nome=Item:getSitelink("enma")}} .. string.char(10) .. p.SiteLinksInterwiki()
end
function p.Categories(frame)
	local Opening = '[[Categoria:'
	local CategoryP = 'P30'
	
	local InstanceQ
	local SeriesQ
	
	local AllCategories = {}
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local ItemCategories = Item:getAllStatements(CategoryP)
	for _, ItemCategory in pairs(ItemCategories) do
		AllCategories[#AllCategories + 1] = Opening .. ItemCategory.mainsnak.datavalue['value'] .. ']]'
	end
	
	InstanceQ = mw.wikibase.getEntity(Item['claims']['P14'][1].mainsnak.datavalue.value['id'])
	local InstanceCategories = InstanceQ:getAllStatements(CategoryP)
	for _, InstanceCategory in pairs(InstanceCategories) do
		AllCategories[#AllCategories + 1] = Opening .. InstanceCategory.mainsnak.datavalue['value'] .. ']]'
	end
	
	--Non ha senso aggiungere categoria per la serie perchè diventerebbe troppo grande
	--[===[
	SeriesQ = mw.wikibase.getEntity(Item['claims']['P16'][1].mainsnak.datavalue.value['id'])
	local SeriesCategories = SeriesQ:getAllStatements(CategoryP)
	for _, SeriesCategory in pairs(SeriesCategories) do
		AllCategories[#AllCategories + 1] = Opening .. SeriesCategory.mainsnak.datavalue['value'] .. ']]'
	end
	]===]

	return table.concat(AllCategories, string.char(10))
end
function p.SiteLinksInterwiki()
	-- Example
	-- [[:memoryalpha:{{{Nome}}}|''{{{Nome}}}'']], Memory Alpha
	local AllLinks = {}
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local SiteLinks = Item['sitelinks']
	local Titles = {
		wikitrek = 'WikiTrek',
		datatrek = 'DataTrek',
		enma = 'Memory Alpha (inglese)',
		itma = 'Memory Alpha (italiano)',
		enmb = 'Memory Beta (inglese)',
		sto = 'Star Trek Online wiki',
		enwiki = 'Wikipedia (inglese)',
		itwiki = 'Wikipedia (inglese)'
	}
	for _, SiteLink in pairs(SiteLinks) do
		local TitleLabel
		--[===[
		if not Titles[SiteLink['site']] then
			TitleLabel = SiteLink['site']
		else
			TitleLabel = Titles[SiteLink['site']]
		end
		]===]
		TitleLabel = Titles[SiteLink['site']] or SiteLink['site']
		
		if string.find(string.lower(TitleLabel), 'datatrek') then
			-- Un link a DataTrek deve portare alla Entità
			AllLinks[#AllLinks + 1] = "* [[:" .. SiteLink['site'] .. ":Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|''" .. SiteLink['title'] .. "'']], Pagina della entità su " .. TitleLabel
		elseif string.find(string.lower(TitleLabel), 'wikitrek') then
			-- Il link a WikiTrek va ignorato perchè è autoreferenziale
		else
			AllLinks[#AllLinks + 1] = "* [[:" .. SiteLink['site'] .. ":" .. SiteLink['title'] .. "|''" .. SiteLink['title'] .. "'']], " .. TitleLabel
		end
	end
	
	return table.concat(AllLinks, string.char(10))
end
function p.LinkToEntity(frame)
	-- La URI si otterrebbe con
	-- mw.wikibase.getEntityUrl()
	-- ma noi usiamo uno InterWiki link
	local Text
	local p = mw.html.create('p')
	
	if mw.wikibase.getEntity() then
		Text = "Modifica i dati nella pagina [[:datatrek-loc:Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|della entità su ''DataTrek'']]"
	else
		Text = "Impossibile trovare l'entità collegata"
	end
	
	p
       :css('line-height', '2')
       :css('alignment', 'right')
       :wikitext(Text)
    return  tostring(p)
end]==]
return p