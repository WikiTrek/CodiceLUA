-- [P2G] Auto upload by PageToGitHub on 2020-03-28T16:35:55+01:00
-- [P2G] This code from page Modulo:FunzioniGeneriche
-- Keyword: wikitrek
local p = {} --p stands for package

function p.EsempioTemplate(frame)
    local SubPageName
    local SubPageTitle
    local Title
    local pre = mw.html.create('pre')
    local DoubleLF = string.char(10) .. string.char(10)

    if not frame.args[1] then
        SubPageName='Esempio'
    else
        SubPageName=frame.args[1]
    end

    Title =  mw.title.getCurrentTitle()
    SubPageTitle = mw.title.makeTitle(Title.namespace, Title.text .. '/' .. SubPageName)

    local Intro = 'Questo esempio è automaticamente generato tramite script LUA a partire dal codice di esempio presente in <code>[[' .. SubPageTitle.prefixedText .. ']]</code>'
    local CodeString = 'Il codice'
    local ReturnString = 'restituisce'

    pre
       :css( 'width', '65%' )
       :wikitext(mw.text.nowiki(SubPageTitle:getContent()))
    return  Intro .. DoubleLF .. CodeString .. DoubleLF .. tostring(pre) .. DoubleLF  .. ReturnString .. DoubleLF .. frame:expandTemplate{ title = SubPageTitle }
end
function p.TableFromArray(AllRows)
	local Table = mw.html.create('table')
	local First
	local Tr
	local Cell
	
	for _, Row in pairs(AllRows) do
		Tr = mw.html.create('tr')
		First = true
		for _, Field in pairs(Row) do
			if First then
				First = false
				Cell = mw.html.create('th')
				if (type(Field) == "table") then
					Cell
						:attr('id', Field[1])
						:attr('title', Field[1])
						:wikitext(Field[2])
				else
					Cell
						:wikitext(Field)
				end
			else
				Cell = mw.html.create('td')
				if #Field > 1 then
					List = mw.html.create('ul')
					for _, Item in pairs(Field) do
						LI = mw.html.create('li')
						LI:wikitext(Item)
						List:node(LI)
					end
					Cell:node(List)
				else
					Cell
						:wikitext(Field[1])
				end
			end
			
			Tr:node(Cell)
		end
		Table:node(Tr)
	end
	
	--[==[if mw.wikibase.getEntity() then
		Text = "Modifica i dati nella [[:datatrek:Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|pagina della entità]] su ''DataTrek''"
	else
		Text = "Impossibile trovare l'entità collegata"
	end
	
	Table
	   :css('font-size', 'smaller')
       :css('text-align', 'right')
       :css('margin', '1px')
       ]==]
    --return tostring(Table)
    return Table
end
	
function p.NoWiki(frame)
    return mw.text.nowiki(frame.args[1])
end
return p