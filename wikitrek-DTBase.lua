-- [P2G] Auto upload by PageToGitHub on 2022-06-24T15:17:05+02:00
-- [P2G] This code from page Modulo:wikitrek-DTBase
--- This module represent the package containing basic functions to access data from the WikiBase instance DataTrek
-- @module p
-- @author Luca Mauri [[Utente:Lucamauri]]
-- Add other authors below
-- Keyword: wikitrek
local p = {}
function p.Epilogo(frame)
	local DoubleReturn = string.char(10) .. string.char(10)
	
	return frame:expandTemplate{ title = 'paginecheportanoqui' } .. DoubleReturn .. "== Collegamenti esterni ==" .. DoubleReturn .. p.ExtLinks(frame) .. DoubleReturn .. "==" .. frame:expandTemplate{ title = 'Etichetta', args = {Tipo=Annotazioni} } .. "==" .. string.char(10) ..  mw.text.nowiki("<references/>") .. DoubleReturn .. string.char(10) .. frame:expandTemplate{ title = 'NavGlobale' }  .. "categorie"
end
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
		local LinkID
		local LinkWiki
		
		if not LinkStatement['qualifiers']['P19'] then
			LinkWiki = frame:expandTemplate{title='LinkTrek', args={LinkURI, LinkTitle}}
		else
			LinkID = LinkStatement['qualifiers']['P19'][1].datavalue['value']
			LinkWiki = "[" .. LinkURI .. " ''" .. mw.text.nowiki(LinkTitle) .. "''], " .. LinkID
		end
		
		if not AllRows then
			AllRows = "* " .. LinkWiki
		else
			AllRows = AllRows .. string.char(10) .. "* " .. LinkWiki
		end
	end
	
	if not AllRows then
		--AllRows = "''Nessun collegamento generico [[:datatrek:Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|trovato su DataTrek]]''"
		AllRows = "''Nessun collegamento generico trovato su DataTrek''"
	end
		
	--return AllRows .. string.char(10) .. string.char(10) .. "=== Interwiki ===" .. string.char(10) .. "* " .. frame:expandTemplate{title = 'InterlinkMA', args = {Nome=Item:getSitelink("enma")}} .. string.char(10) .. p.SiteLinksInterwiki()
	return AllRows .. string.char(10) .. string.char(10) .. "=== Interwiki ===" .. string.char(10) .. p.SiteLinksInterwiki() .. string.char(10) .. "=== Identificativi esterni ===" .. string.char(10) .. p.ExternalID()
end
function p.Categories(frame)
	local Opening = '[[Category:'
	local CategoryP = 'P30'
	local AbbrP = 'P24'
	local SeriesP = 'P16'
	
	local InstanceQ
	local SeriesQ
	local SeriesItem
	
	local AllCategories = {}
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	--Categories manually inserted into the Item
	local ItemCategories = Item:getAllStatements(CategoryP)
	for _, ItemCategory in pairs(ItemCategories) do
		AllCategories[#AllCategories + 1] = Opening .. ItemCategory.mainsnak.datavalue['value'] .. ']]'
	end
	
	--Categories from the Instance's Item
	InstanceQ = mw.wikibase.getEntity(Item['claims']['P14'][1].mainsnak.datavalue.value['id'])
	local InstanceCategories = InstanceQ:getAllStatements(CategoryP)
	
	local ItemSeries = Item:getAllStatements(SeriesP)
	for _, InstanceCategory in pairs(InstanceCategories) do
		local InstanceValue = InstanceCategory.mainsnak.datavalue['value']
		AllCategories[#AllCategories + 1] = Opening .. InstanceValue .. ']]' --InstanceCategory.mainsnak.datavalue['value'] .. ']]'
		
		--Category generated joining the item's Instance category plus the Series short name IF it exists
		if ItemSeries then
			for _, ItemSer in pairs(ItemSeries) do
				SeriesItem = mw.wikibase.getEntity(ItemSer.mainsnak.datavalue.value['id'])
				AllCategories[#AllCategories + 1] = Opening .. InstanceValue .. " di " .. SeriesItem.claims[AbbrP][1].mainsnak.datavalue['value'] .. ']]' --SeriesItem.labels['it'].value .. ']]'
			end
		end
	end
	
	--Non ha senso aggiungere categoria per la serie perchè diventerebbe troppo grande
	--[=[SeriesQ = mw.wikibase.getEntity(Item['claims']['P16'][1].mainsnak.datavalue.value['id'])
	local SeriesCategories = SeriesQ:getAllStatements(CategoryP)
	for _, SeriesCategory in pairs(SeriesCategories) do
				AllCategories[#AllCategories + 1] = Opening .. InstanceCategory.mainsnak.datavalue['value'] .. " DI " .. SeriesCategory.mainsnak.datavalue['value'] .. ']]'
	end]=]
		
	return table.concat(AllCategories, string.char(10))
end
function p.SiteLinksInterwiki()
	-- Esempio
	-- [[:memoryalpha:{{{Nome}}}|''{{{Nome}}}'']], Memory Alpha
	local AllLinks = {}
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		return "''Nessun collegamento generico trovato su DataTrek''"
	end
	
	local SiteLinks = Item['sitelinks']
	local Titles = {
		wikitrek = 'WikiTrek',
		datatrek = 'DataTrek',
		enma = 'Memory Alpha (inglese)',
		itma = 'Memory Alpha (italiano)',
		enmb = 'Memory Beta (inglese)',
		sto = 'Star Trek Online wiki',
		wikidata = 'Pagina della entità su Wikidata',
		enwiki = 'Wikipedia (inglese)',
		itwiki = 'Wikipedia (italiano)',
		dewiki = 'Wikipedia (tedesco)',
		dema = 'Memory Alpha (tedesco)',
		demb = 'Memory Beta (tedesco)',
		fanlore = 'Fanlore',
		trekipedia = 'Trekipedia'
	}
	
	for _, SiteLink in pairs(SiteLinks) do
		local TitleLabel
		
		TitleLabel = Titles[SiteLink['site']] or SiteLink['site']
		
		if string.find(string.lower(TitleLabel), 'datatrek') then
			-- Un link a DataTrek deve portare alla Entità
			-- Questo non dovrebbe mai esistere lo aggiungo a mano alla fine del ciclo
			AllLinks[#AllLinks + 1] = "* [[:" .. SiteLink['site'] .. ":Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|''" .. SiteLink['title'] .. "'']], Pagina della entità su " .. TitleLabel
		elseif string.find(string.lower(TitleLabel), 'wikitrek') then
			-- Il link a WikiTrek va ignorato perchè è autoreferenziale
		else
			AllLinks[#AllLinks + 1] = "* [[:" .. SiteLink['site'] .. ":" .. SiteLink['title'] .. "|''" .. SiteLink['title'] .. "'']], " .. TitleLabel
		end
	end
	-- Interlink a DataTrek
	AllLinks[#AllLinks + 1] = "* [[" .. 'datatrek' .. ":Item:" .. Item.id .. "|''" .. Item.id .. "'']], Pagina della entità su " .. Titles['datatrek']
	--AllLinks[#AllLinks + 1] = "* [[" .. 'datatrek' .. ":Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "'']], Pagina della entità su " .. Titles['datatrek']
	
	return table.concat(AllLinks, string.char(10))
end
function p.ExternalID()
	local AllExtID = {}
	local Item = mw.wikibase.getEntity()
	local AllP
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	AllP = mw.wikibase.orderProperties(Item:getProperties())
	for _, Property in pairs(AllP) do
		if Item.claims[Property][1].mainsnak.datatype == 'external-id' then
			AllExtID[#AllExtID + 1] = "* ["  .. p.ExtIDLink(Property, Item.claims[Property][1].mainsnak.datavalue.value) .. " ''" .. Item.claims[Property][1].mainsnak.datavalue.value .. "''], " .. (mw.wikibase.getLabelByLang(Property, 'it') or mw.wikibase.getLabel(Property)) -- [[:" .. SiteLink['site'] .. ":" .. SiteLink['title'] .. "|''" .. SiteLink['title'] .. "'']], " .. TitleLabel
		end
	end
	
	return table.concat(AllExtID, string.char(10))
end
function p.ExtIDLink(Property, Value)
	local ExtIDP = 'P5'
	local URL
	
	URL = mw.wikibase.getEntity(Property).claims[ExtIDP][1].mainsnak.datavalue.value
	return string.gsub(URL, '$1', Value)
end
function p.LinkToEntity(frame, AddSemantic)
	-- La URI si otterrebbe con
	-- mw.wikibase.getEntityUrl()
	-- ma noi usiamo uno InterWiki link
	local Text
	local p = mw.html.create('p')
	
	if not AddSemantic then
		AddSemantic = true
	end
	
	if mw.wikibase.getEntity() then
		if AddSemantic then
			Text = "Modifica i dati nella [[DataTrek ID::" .. mw.wikibase.getEntityIdForCurrentPage() .. "|pagina della entità]] su ''DataTrek''"
		else
			Text = "Modifica i dati nella [[datatrek:Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|pagina della entità]] su ''DataTrek''"
		end
	else
		Text = "Impossibile trovare l'entità collegata"
	end
	
	p
	   :css('font-size', 'smaller')
       :css('text-align', 'right')
       :css('margin', '1px')
       :wikitext(Text)
    return  tostring(p)
end
function p.LabelByLang(frame)
	local Item = mw.wikibase.getEntityIdForCurrentPage()
	local Lang = frame.args['Lingua']
	if not Item then
		Item = 'Q1'
	end
	
	return mw.wikibase.getLabelByLang(Item, Lang)
end
function p.LabelByLang2(frame)
	local Lang = frame.args['Lingua']
	local Item = frame.args['Item']
	if not Lang then
		Lang = 'it'
	end
	
	if not Item then
		Item = mw.wikibase.getEntityIdForCurrentPage()
	end
	if not Item then
		Item = 'Q1'
	end
	
	return mw.wikibase.getLabelByLang(Item, Lang)
end
function p.ItemIcon()
	-- |FileIcona=dsg.png
	local IconFileName
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	--SeriesQ = Item['claims']['P16'][1]['mainsnak'].datavalue['value']['id']
	--FileName = mw.wikibase.getEntity(SeriesQ)['claims']['P3'][1]['mainsnak'].datavalue['value']
	IconFileName = Item['claims']['P3'][1].mainsnak.datavalue['value']
	
	return IconFileName
end
function p.ItemIconCascade()
	-- |FileIcona=dsg.png
	local IconFileName
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	if Item['claims']['P3'] then
		-- Item icon has higher priority
		IconFileName = Item['claims']['P3'][1].mainsnak.datavalue['value']
	elseif Item['claims']['P22'] then
		-- Else takes icon from "TIPO"
		IconFileName = mw.wikibase.getEntity(Item['claims']['P22'][1].mainsnak.datavalue.value.id)['claims']['P3'][1].mainsnak.datavalue['value']
	else 
		-- If everything fails, takes icon from "ISTANZA"
		IconFileName = mw.wikibase.getEntity(Item['claims']['P14'][1].mainsnak.datavalue.value.id)['claims']['P3'][1].mainsnak.datavalue['value']
	end
	
	return IconFileName
end
function p.ItemImage()
	local ImageFileName
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	ImageFileName = Item['claims']['P37'][1].mainsnak.datavalue['value']
	
	return ImageFileName
end
function p.GenericValue(Property)
	-- |FileIcona=dsg.png
	local Value
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end

	Value = Item['claims'][Property][1].mainsnak.datavalue['value']
	
	if not Value then
		Value = "''Proprietà non trovata''"
	end
	
	return Value
end
function p.LabelOrLink(QItem, SMWProperty, AddSemantic, ForcedLabel)
	local Label
	local WTLink
	
	if AddSemantic and SMWProperty and (SMWProperty ~= "") then
		AddSemantic = true
	else
		AddSemantic = false
	end
	
	local Item = mw.wikibase.getEntity(QItem)
	if Item == nil then
		return "'''Error'''"
	end
	
	if ForcedLabel ~= "" and ForcedLabel ~= nil then
		Label = ForcedLabel
	elseif not Item['claims'] or not Item['claims']['P20'] then
		Label = Item.labels['it'].value
	else
		Label = Item['claims']['P20'][1].mainsnak.datavalue['value']
	end
	
	if false then
		return Label
	end
	
	if not mw.wikibase.getSitelink(QItem) and string.find(Label, "Categoria:", 1, true) == nil then
		--if mw.wikibase.getSitelink(QItem) == nil or (not mw.wikibase.getSitelink(QItem)) then
		--return Label
		
		--https://wikitrek.org/wiki/Speciale:AboutTopic/Q64
		if AddSemantic then
			mw.smw.set(SMWProperty .. "=" .. Label)
		end
		return "[[Special:AboutTopic/" .. QItem .. "|" .. Label .. "]]"
	else
		if Item.sitelinks == nil then
			WTLink = Label
		else
			WTLink = Item.sitelinks['wikitrek'].title
		end
		if not Label then
			Label = WTLink
		end
		if string.find(WTLink, "Categoria:", 1, true) ~= nil then
			return "[[" .. WTLink .. "]]"
		elseif AddSemantic then
			return "[[" .. SMWProperty .. "::" .. WTLink .. "|" .. Label .. "]]"
		else
			return "[[" .. WTLink .. "|" .. Label .. "]]"
		end
	end
end
--- Three dashes indicate the beginning of a function or field documented
-- using the LDoc format
-- @param Item Father of Previous and Next
-- @param[opt="Navigatore"]
-- @return Table
function p.MakeNavTable(Item, Title)
--[[
<div class="separatorebox">
'''Navigatore episodi'''
</div>
{{{!}} class="wikitable" style="width:100%"
<!-- {{!}}+ Navigatore episodi -->
!< Precedente
!Successivo >
{{!}}-
{{!}} style="text-align:center; width:50%;" {{!}}{{#invoke:DTEpisodio|LinkPrevious}}
{{!}} style="text-align:center;" {{!}}{{#invoke:DTEpisodio|LinkNext}}
{{!}}}
]]
	local Previous
	local Next
	local Table
	
	--Title = Title or "Navigatore"
	if not Item then
		Item = mw.wikibase.getEntity("Q1")
	end
	
	if not Item["P7"] then
		Previous = "''nessuno''"
	elseif Item["P7"][1].mainsnak == nil then
		Previous = p.LabelOrLink(Item["P7"][1].datavalue.value.id)
	else
		Previous = p.LabelOrLink(Item["P7"][1].mainsnak.datavalue.value.id)
	end
	
	if not Item["P23"] then
		Next = "''nessuno''"
	elseif Item["P23"][1].mainsnak == nil then
		Next = p.LabelOrLink(Item["P23"][1].datavalue.value.id)
	else
		Next = p.LabelOrLink(Item["P23"][1].mainsnak.datavalue.value.id)
	end
	
	--Table = "<div class='separatorebox'>'''" .. Title .. "'''</div>"
	--Table = Table .. string.char(10) .. "<table class='wikitable' style='width:100%'>"
	Table = "<table class='wikitable' style='width:100%'>"
	if Title ~= nil then
		Table = Table .. string.char(10) .. "<caption>" .. Title .. "</caption>"
	end
	Table = Table .. string.char(10) .. "<tr><th id='P7' title='P7'>&lt; Precedente</th><th id='P23' title='P23'>Successivo &gt;</th></tr>"
	Table = Table .. string.char(10) .. "<tr><td style='text-align:center; width:50%;'>" .. Previous .. "</td>"
	Table = Table .. string.char(10) .. "<td style='text-align:center; width:50%;'>" .. Next .. "</td></tr>"
	Table = Table .. string.char(10) .. "</table>"
	
	return Table
end
function p.SiteAllP()
	local MaxP = 10
	local AllP = {}
	
	for PNumber = 1, MaxP, 1 do
      if mw.wikibase.entityExists('P' .. PNumber) then
      	AllP[#AllP + 1] = 'P' .. PNumber
      end
    end
	
	return table.concat("* " .. AllP, string.char(10))
end
function p.ListReferences(frame)
	local AllReferences = {}
	local Item = mw.wikibase.getEntityIdForCurrentPage()
	if not Item then
		Item = 'Q1'
	end
	
	local Statements = mw.wikibase.getAllStatements(Item, 'P58')
	if not Statements then
		return "Nessun riferimento trovato"
	else
		for _, Statement in pairs(Statements) do
			local ReferenceItem = Statement.mainsnak.datavalue.value.id
			local Reference = mw.wikibase.getSitelink(ReferenceItem)
			if not Reference then
				--Reference = Statement.mainsnak.datavalue.value.id
				AllReferences[#AllReferences + 1] = "* [[Special:AboutTopic/" .. ReferenceItem .. "]] - " .. ReferenceItem .. " - " .. mw.wikibase.getLabelByLang(mw.wikibase.getEntity(ReferenceItem).claims['P14'][1].mainsnak.datavalue.value.id, "it")
			else
				if frame.args['AddSemantic'] then
					Reference = "Riferimento::" .. Reference
				end
				AllReferences[#AllReferences + 1] = "* [[" .. Reference .. "]] (" .. mw.wikibase.getLabelByLang(mw.wikibase.getEntity(ReferenceItem).claims['P14'][1].mainsnak.datavalue.value.id, "it") .. ")"
			end
		end
		return table.concat(AllReferences, string.char(10))
	end
end
--- generates a list of backlink using SMW query.
-- 
-- @frame Info from MW session
-- @return A bullet list of backlinks
function p.ListBackReferences(frame)
	-- See example here https://github.com/SemanticMediaWiki/SemanticScribunto/blob/master/docs/mw.smw.getQueryResult.md
	-- See also here https://doc.semantic-mediawiki.org/md_content_extensions_SemanticScribunto_docs_mw_8smw_8getQueryResult.html
	local AllBackReferences = {}
	--[=[
	local QueryResult = mw.smw.ask('[[Riferimento::' .. mw.title.getCurrentTitle().text .. ']]|?DataTrek ID|format=broadtable')
	
	if not QueryResult then
		return "''Nessun risultato''"
	else
		for _, Row in pairs(QueryResult) do
			local Items = {}
			for _, Field in pairs(Row) do
				if string.sub(Field, 1, 7) == "[[File:" then
					Items[#Items + 1] = "[[:" .. string.sub(Field, 3)
				else
					Items[#Items + 1] = Field
				end
			end
			AllBackReferences[#AllBackReferences + 1] = "*" .. table.concat(Items, ', ')
		end
		return table.concat(AllBackReferences, string.char(10))
	end
	]=]

	--local QueryResult = mw.smw.getQueryResult('[[Riferimento::' .. mw.title.getCurrentTitle().text .. ']]|?DataTrek ID')
	--local queryResult = mw.smw.getQueryResult( frame.args )
	local QueryResult = mw.smw.getQueryResult('[[Riferimento::' .. mw.title.getCurrentTitle().text .. ']]|?DataTrek ID|?Istanza')
	
    if QueryResult == nil then
        return "''Nessun risultato''"
    end

    if type(QueryResult) == "table" then
        local Row = ""
        for k, v in pairs(QueryResult.results) do
            --[=[if  v.fulltext and v.fullurl then
                myResult = myResult .. k .. " | " .. v.fulltext .. " " .. v.fullurl .. " | " .. "<br/>"
            else
                myResult = myResult .. k .. " | no page title for result set available (you probably specified ''mainlabel=-')"
            end]=]
            if string.sub(v.fulltext, 1, 5) == "File:" then
				Row = "[[:" .. v.fulltext .. "]]" --string.sub(v.fulltext, 3)
			else
				Row = "[[" .. v.fulltext .. "]]"
            end
            if v.printouts['DataTrek ID'][1] ~= nil then
            	Row = Row .. " - " .. v.printouts['DataTrek ID'][1] .. " - " .. v.printouts['Istanza'][1].fulltext
            end
            
			AllBackReferences[#AllBackReferences + 1] = "*" .. Row
        end
        	return table.concat(AllBackReferences, string.char(10))
    else
    	return "''No table''"
    end

    return queryResult
end
--- Writes a gneric UL list from property, adding SMW link if specified
-- 
-- @param PName Info from MW session
-- @param SMWPrefix 
-- @return A bullet list of backlinks
function p.PropertyList(frame)
	--{{#invoke:DTBase|PropertyList|P59|Scritto da}}
	local AllReferences = {}
	local Item = mw.wikibase.getEntityIdForCurrentPage()
	if not Item then
		Item = 'Q1'
	end
	
	local Statements = mw.wikibase.getAllStatements(Item, frame.args["Property"])
	if not Statements then
		return "Nessun riferimento trovato"
	elseif table.getn(Statements) == 1 then
		return p.LabelOrLink(Statements[1].mainsnak.datavalue.value.id, frame.args["SMWPrefix"], true)
	else
		for _, Statement in pairs(Statements) do
			--local ReferenceItem = Statement.mainsnak.datavalue.value.id
			AllReferences[#AllReferences + 1] = "<li>" .. p.LabelOrLink(Statement.mainsnak.datavalue.value.id, frame.args["SMWPrefix"], true) .. "</li>"
		end
		return "<ul>" .. table.concat(AllReferences, string.char(10)) .. "</ul>"
	end
end
return p