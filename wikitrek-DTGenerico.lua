-- [P2G] Auto upload by PageToGitHub on 2021-02-27T15:19:04+01:00
-- [P2G] This code from page Modulo:wikitrek-DTGenerico
-- Keyword: wikitrek
local TableFromArray = require('Modulo:FunzioniGeneriche').TableFromArray
local LabelOrLink = require('Modulo:DTBase').LabelOrLink
local GenericValue = require('Modulo:DTBase').GenericValue
local MakeNavTable = require('Modulo:DTBase').MakeNavTable

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
	if Item['claims']['P37'] then
		local FileTitle = "File:" .. Item['claims']['P37'][1].mainsnak.datavalue['value']
		local FileCaption = frame:expandTemplate{title = FileTitle}
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
	
	--ItemQ = Item['claims']['P14'][1].mainsnak.datavalue['value']['id']
	ItemQ = p.QFromP('P14')
	--SeriesQ = Item['claims']['P16'][1]['mainsnak'].datavalue['value']['id']
	--FileName = mw.wikibase.getEntity(SeriesQ)['claims']['P3'][1]['mainsnak'].datavalue['value']
	--IconFileName = Item['claims']['P3'][1].mainsnak.datavalue['value']
	--return ItemQ
	--return mw.wikibase.getEntity(ItemQ)['claims']['P3'][1].mainsnak.datavalue['value']
	
	TitleText = mw.wikibase.getLabelByLang(ItemQ, 'it')
	mw.smw.set("Istanza=" .. TitleText)

	return TitleText
end
function p.ListAllP(frame)
	local AllP
	local AllRows = {}
	local HTMLTable
	local CollectionTable = ''
	local ExcludeP = {P3 = true, P14 = true, P26 = true, P30 = true, P37 = true, P58 = true, P68 = true, P52 = true, P79 = true, P90 = true}
	local Item = mw.wikibase.getEntity()
	local ItemQ = mw.wikibase.getEntityIdForCurrentPage()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	if not AddSemantic then
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
				CollectionTable = string.char(10) .. MakeNavTable(Item.claims, Item.claims[Property][1].mainsnak.datavalue.value)
			else
				local Header = {Property, (mw.wikibase.getLabelByLang(Property, 'it') or mw.wikibase.getLabel(Property)) .. ":"} -- or {Property, mw.wikibase.getLabel(Property) .. ":"} --'-' .. Property .. ":"}
				local Values = Item['claims'][Property]
				local AccValues = {}
				for _, SnakValue in pairs(Values) do
					local Value = SnakValue.mainsnak.datavalue['value']
					if (type(Value) == "table") then
						if Property == "P72" then --CASE Assigments
							local Assignment = ""
							if SnakValue.qualifiers['P73'] then --Year
								Assignment = LabelOrLink(SnakValue.qualifiers['P73'][1].datavalue.value['id']) .. " "
							end
							
							if SnakValue.qualifiers['P15'] then
								Assignment = Assignment .. SnakValue.qualifiers['P15'][1].datavalue.value .. " "
							end
							
							Assignment = Assignment .. LabelOrLink(Value['id'])
							
							if SnakValue.qualifiers['P76'] then --Rank
								Assignment = Assignment .. ", " .. LabelOrLink(SnakValue.qualifiers['P76'][1].datavalue.value['id'])
							end
							if SnakValue.qualifiers['P77'] then --Occupation
								Assignment = Assignment .. ", " .. LabelOrLink(SnakValue.qualifiers['P77'][1].datavalue.value['id'])
							end
							--AccValues[#AccValues + 1] = LabelOrLink(SnakValue.qualifiers['P73'][1].datavalue.value['id']) .. " " .. LabelOrLink(Value['id']) .. ", " .. LabelOrLink(SnakValue.qualifiers['P76'][1].datavalue.value['id']) .. ", " .. LabelOrLink(SnakValue.qualifiers['P77'][1].datavalue.value['id'])
							AccValues[#AccValues + 1] = Assignment
						elseif Value['entity-type'] == 'item' then
							local GenericItem
							if AddSemantic then
								GenericItem = LabelOrLink(Value['id'], Header[2])
							else
								GenericItem = LabelOrLink(Value['id'])
							end
							if SnakValue.qualifiers and SnakValue.qualifiers['P15'] then
								GenericItem = SnakValue.qualifiers['P15'][1].datavalue.value .. " " .. GenericItem
							end
							AccValues[#AccValues + 1] = GenericItem
						elseif SnakValue.mainsnak.datavalue['type'] == 'time' then
							if AddSemantic then
								AccValues[#AccValues + 1] = "[[" .. Header[2] .. "::" .. Value['time'] .. "|" .. frame:expandTemplate{title = 'TimeL', args = {Tipo='ITEstesa', Istante=Value['time']}} .. "]]"
							else
								AccValues[#AccValues + 1] = frame:expandTemplate{title = 'TimeL', args = {Tipo='ITEstesa', Istante=Value['time']}}
							end
						elseif SnakValue.mainsnak.datavalue.type == 'quantity' then
							local StringValue
							StringValue = string.format('%u', SnakValue.mainsnak.datavalue.value.amount)
							
							if AddSemantic then
								mw.smw.set(Header[2] .. "::" .. StringValue)
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
function p.Incipit(frame)
	if not mw.wikibase.getDescription() then
		if not mw.wikibase.getEntity().claims['P20'] then
		return "'''" .. mw.title.getCurrentTitle().text .. "''' è un " .. mw.wikibase.getLabelByLang(p.QFromP('P14'), 'it') .. string.char(10)
	else
		return "'''" .. mw.title.getCurrentTitle().text .. "''' è " .. 	mw.wikibase.getEntity().claims['P20'][1].mainsnak.datavalue['value'] .. string.char(10)
	end
	else
		return "'''''" .. mw.title.getCurrentTitle().text .. "'''''" .. " è " .. mw.wikibase.getDescription() .. string.char(10)
	end
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
		DataString = "Informazioni originali lette dal database di '''HyperTrek''' datato " .. frame:expandTemplate{title = 'TimeL', args = {Tipo='ITMedia', Istante=HTNodes.mainsnak.datavalue.value.time}} .. " con i seguenti dettagli: "
		
		for _, Qualifier in pairs(HTNodes.qualifiers) do
			QualiString = QualiString .. "<li " .. "title='" .. Qualifier[1].property .. "'>'''" .. mw.wikibase.getLabelByLang(Qualifier[1].property, 'it') .. "''': " .. Qualifier[1].datavalue.value .. "</li>" 
		end
		
		DIV
			:attr('id', 'htdata')
			:addClass('htcontainer')
			:wikitext(ImageString .. DataString .. "<ul>" .. QualiString .. "</ul>" .. "[[Categoria:Pagine originariamente convertite da HT]]") --.. string.char(10) .. "[[Categoria:Pagine originariamente convertite da HT]]")
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