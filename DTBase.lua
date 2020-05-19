-- [P2G] Auto upload by PageToGitHub on 2020-05-20T01:28:57+02:00
-- [P2G] This code from page Modulo:DTBase
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
		AllRows = "''Nessun collegamento generico [[:datatrek:Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|trovato su DataTrek]]''"
	end
		
	--return AllRows .. string.char(10) .. string.char(10) .. "=== Interwiki ===" .. string.char(10) .. "* " .. frame:expandTemplate{title = 'InterlinkMA', args = {Nome=Item:getSitelink("enma")}} .. string.char(10) .. p.SiteLinksInterwiki()
	return AllRows .. string.char(10) .. string.char(10) .. "=== Interwiki ===" .. string.char(10) .. p.SiteLinksInterwiki() .. string.char(10) .. "=== Identificativi esterni ===" .. string.char(10) .. p.ExternalID()
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
	-- Esempio
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
			Text = "Modifica i dati nella [[DataTrek ID::Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|pagina della entità]] su ''DataTrek''"
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
function p.LabelOrLink(QItem)
	local Label
	local WTLink
	
	local Item = mw.wikibase.getEntity(QItem)
	if not Item then
		return "''Elemento non trovato''"
	end
	
	if not Item['claims'] or not Item['claims']['P20'] then
		Label = Item.labels['it'].value
	else
		Label = Item['claims']['P20'][1].mainsnak.datavalue['value']
	end
	
	if false then
		return Label
	end
	
	if not mw.wikibase.getSitelink(QItem) then
		return Label
	else
		WTLink = Item.sitelinks['wikitrek'].title
		if not Label then
			Label = WTLink
		end
		return "[[" .. WTLink .. "|" .. Label .. "]]"
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
	
	Title = Title or "Navigatore"
	if not Item then
		Item = mw.wikibase.getEntity("Q1")
	end
	
	if not Item["P7"] then
		Previous = "no prev"
	else
		Previous = p.LabelOrLink(Item["P7"][1].datavalue.value.id)
	end
	
	if not Item["P23"] then
		Next = "no next"
	else
		Next = p.LabelOrLink(Item["P23"][1].datavalue.value.id)
	end
	
	Table = "<div class='separatorebox'>'''" .. Title .. "'''</div>"
	Table = Table .. string.char(10) .. "<table class='wikitable' style='width:100%'>"
	Table = Table .. string.char(10) .. "<tr><th>&lt; Precedente</th><th>Successivo &gt;</th></tr>"
	Table = Table .. string.char(10) .. "<tr><td style='text-align:center; width:50%;'>" .. Previous .. "</td>"
	Table = Table .. string.char(10) .. "<td style='text-align:center; width:50%;'>" .. Next .. "</td></tr>"
	Table = Table .. string.char(10) .. "</table>"
	
	return Table
end
return p