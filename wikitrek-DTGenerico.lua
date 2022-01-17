-- [P2G] Auto upload by PageToGitHub on 2022-01-17T22:33:29+01:00
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
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local Markup
	
	-- TODO
	-- If there are multiple images, then create a carousel
	-- Example from https://data.wikitrek.org/wiki/Item:Q5641
	-- <gallery mode="slideshow" widths=100% heights=350px>
	-- File:Dis1x3 discovery1031.jpg|caption|alt=alt language
	-- File:Dis3x6 discovery1031a.jpg|caption|alt=alt language
	-- </gallery>
	
	if Item['claims']['P37'] then
		local FileTitle
		local FileCaption
		local FileName = Item['claims']['P37'][1].mainsnak.datavalue['value']
		File = mw.title.new( FileName, "File" )
		
		--local FileTitle = "File:" .. Item['claims']['P37'][1].mainsnak.datavalue['value']
		FileTitle = "File:" .. FileName
		if File.exists then
			FileCaption = frame:expandTemplate{title = FileTitle}
		else
			FileCaption = "Immagine da Commons"
		end
		
		--Markup = "<div class='separatorebox'>'''Immagine'''</div>" ..  "<div class='contenitoreimgbox'>[[File:" .. Item['claims']['P37'][1].mainsnak.datavalue['value'] .. "|100%]]</div>"
		--Markup = "<div class='separatorebox'>'''Immagine'''</div>" ..  "<div class='contenitoreimgbox'>[[" .. FileTitle .. "|alt={{" .. FileTitle .. "}}|{{" .. FileTitle .. "}}" .. "]]</div>"
		Markup = "<div class='separatorebox'>'''Immagine'''</div>" ..  "<div class='contenitoreimgbox'>[[" .. FileTitle .. "|alt=" .. FileCaption .. "|" .. FileCaption .. "]]<br /><span style='font-size: smaller;'>" .. FileCaption .. "</span></div>"
	else
		Markup = ""
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
	local ExcludeP = {P3 = true, P7 = true, P14 = false, P21 = true, P23 = true, P26 = true, P30 = true, P37 = true, P58 = true, P68 = true, P52 = true, P79 = true, P90 = true}
	local POnTree = {}
	local Item = mw.wikibase.getEntity()
	local ItemQ = mw.wikibase.getEntityIdForCurrentPage()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	if AddSemantic == nil then
		AddSemantic = true
	end
	
	AllP = mw.wikibase.orderProperties(Item:getProperties())
	--Debug: list unsorted and sorted properties
	--AllRows[#AllRows + 1] = {"getProperties:", Item:getProperties()}
	--AllRows[#AllRows + 1] = {"AllP:", AllP}
	
	PageTitle =  mw.title.getCurrentTitle()
	if (mw.wikibase.getLabelByLang(ItemQ, 'en')) and (mw.wikibase.getLabelByLang(ItemQ, 'en')) ~= PageTitle.text then
		AllRows[#AllRows + 1] = {"In originale:", {mw.wikibase.getLabelByLang(ItemQ, 'en')}}
	end
	if (mw.wikibase.getLabelByLang(ItemQ, 'it')) and (mw.wikibase.getLabelByLang(ItemQ, 'it')) ~= PageTitle.text then
		AllRows[#AllRows + 1] = {"In italiano:", {mw.wikibase.getLabelByLang(ItemQ, 'it')}}
	end
	for _, Property in pairs(AllP) do
		if (not ExcludeP[Property]) and Item.claims[Property][1].mainsnak.datatype ~= 'external-id' then
			if Property == "P46" then
				-- Collection
				CollectionTable = string.char(10) .. MakeNavTable(Item.claims[Property][1].qualifiers, Item.claims[Property][1].mainsnak.datavalue.value)
			elseif (Property == "P7" or Property == "P23") and CollectionTable == '' then
				--Previous or Next
				CollectionTable = string.char(10) .. MakeNavTable(Item.claims, nil)
			elseif Property == "P14" then
				--Instance
				POnTree = {{"P40", 3, false}, {"P41", 3, false}, {"P88", 3, false}}
				for _, Prop in pairs(POnTree) do
					local PropValue = table.concat(PropertiesOnTree(Prop[1], Prop[2], Prop[3], true))
					if (PropValue ~= nil) and (PropValue ~= "") then
						local PropName = mw.wikibase.getLabelByLang(Prop[1], 'it') or mw.wikibase.getLabel(Prop[1])
						AllRows[#AllRows + 1] = {{Prop[1], PropName .. ":"}, {PropValue}}
						if AddSemantic then
							mw.smw.set(PropName .. "=" .. PropValue)
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
			else
				local Header = {Property, (mw.wikibase.getLabelByLang(Property, 'it') or mw.wikibase.getLabel(Property)) .. ":"} -- or {Property, mw.wikibase.getLabel(Property) .. ":"} --'-' .. Property .. ":"}
				local Values = Item['claims'][Property]
				local AccValues = {}
				for _, SnakValue in pairs(Values) do
					local Value = SnakValue.mainsnak.datavalue['value']
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
							local GenericItem
							if AddSemantic then
								GenericItem = LabelOrLink(Value['id'], Header[2], AddSemantic)
							else
								GenericItem = LabelOrLink(Value['id'])
							end
							if SnakValue.qualifiers and SnakValue.qualifiers['P15'] then
								GenericItem = SnakValue.qualifiers['P15'][1].datavalue.value .. " " .. GenericItem
							end
							AccValues[#AccValues + 1] = GenericItem
						elseif SnakValue.mainsnak.datavalue['type'] == 'time' then
							-- "+2367-00-00T00:00:00Z"
							local Instant = Value['time']
							local OutputFormat = "ITMedia"
							local YearLink = ""
							local PrintDate
							
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
							end
							
							if YearLink == "" then
								AccValues[#AccValues + 1] = PrintDate
							else
								AccValues[#AccValues + 1] = YearLink
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
							StringValue = string.format('%u', SnakValue.mainsnak.datavalue.value.amount)
							
							if AddSemantic then
								--mw.smw.set(Header[2] .. "::" .. StringValue)
								mw.smw.set(Header[2] .. "=" .. StringValue)
							end
							
							AccValues[#AccValues + 1] = StringValue
						else
							AccValues[#AccValues + 1] = 'TABLE'
						end
					else
						AccValues[#AccValues + 1] = Value
					end
				end
				AllRows[#AllRows + 1] = {Header, AccValues}
			end
		end
	end
	
	HTMLTable = TableFromArray(AllRows)
	HTMLTable
		:addClass('infobox')
	
	-- return table.concat(AllRows, "<br />" .. string.char(10)) .. string.char(10)
	-- return HTMLTable
	return tostring(HTMLTable) .. CollectionTable
end
function p.ProcessNavigators(frame)
	local CollectionTable
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
		CollectionTable = CollectionTable .. string.char(10) .. MakeNavTable(Item.claims[Property][1].qualifiers, Item.claims[Property][1].mainsnak.datavalue.value)
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
		--DataString = "Informazioni originali lette dal database di '''HyperTrek''' datato " .. frame:expandTemplate{title = 'TimeL', args = {Tipo='ITMedia', Istante=HTNodes.mainsnak.datavalue.value.time}} .. " con i seguenti dettagli: "
		DataString = "Informazioni originali lette dal database di <h2 class='hiddenheaderbold'>HyperTrek</h2> datato " .. frame:expandTemplate{title = 'TimeL', args = {Tipo='ITMedia', Istante=HTNodes.mainsnak.datavalue.value.time}} .. " con i seguenti dettagli: "
		 
		for _, Qualifier in pairs(HTNodes.qualifiers) do
			local QualiProp = Qualifier[1].property
			local QualiName = mw.wikibase.getLabelByLang(QualiProp, 'it')
			local QualiValue = Qualifier[1].datavalue.value
			--QualiString = QualiString .. "<li " .. "title='" .. Qualifier[1].property .. "'>'''" .. mw.wikibase.getLabelByLang(Qualifier[1].property, 'it') .. "''': " .. Qualifier[1].datavalue.value .. "</li>"
			QualiString = QualiString .. "<li " .. "title='" .. QualiProp .. "'>'''" .. QualiName .. "''': " .. QualiValue .. "</li>"
			if AddSemantic then
				mw.smw.set(QualiName .. "=" .. QualiValue)
			end
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