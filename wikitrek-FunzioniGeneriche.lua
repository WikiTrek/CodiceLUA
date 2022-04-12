-- [P2G] Auto upload by PageToGitHub on 2022-04-12T23:14:35+02:00
-- [P2G] This code from page Modulo:wikitrek-FunzioniGeneriche
-- Keyword: wikitrek
local p = {} --p stands for package

function p.EsempioTemplate(frame)
    local SubPageName
    local SubPageTitle
    local Title
    local Content
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
    local CodeString = '=== Il codice ==='
    local ReturnString = '=== restituisce ==='

	Content = SubPageTitle:getContent()
	
	if not Content then
		return "La pagina <code>[[" .. SubPageTitle.prefixedText .. "]]</code> non esiste: non è possibile estrarre il testo e generare l'esempio"
	else
		pre
			:css( 'width', '65%' )
			:wikitext(mw.text.nowiki(Content))
    	return  Intro .. DoubleLF .. CodeString .. DoubleLF .. tostring(pre) .. DoubleLF  .. ReturnString .. DoubleLF .. frame:expandTemplate{ title = SubPageTitle }
    end
end
function p.EsempioBreve(frame)
	--<code><nowiki>{{DTItem|Q11}}</nowiki></code> → {{DTItem|Q11}}
	local ExampleText
	
	if frame.args[1] == nil then
        Return "Error"
    else
        ExampleText=frame.args[1]
    end

	return "<code><nowiki>" .. mw.text.nowiki(ExampleText) .. "</nowiki></code> → " .. frame:expandTemplate{ title = ExampleText }
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
						:wikitext(Field[2]..":")
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
--- Returns the color to use in CSS for the text depending on the luminance
-- of the background
-- @param BackColor The hex code of the background color
-- @return name of the color
function p.TextColor(frame)
	local hex = string.sub(frame.args[1], 2)
	local R, G, B
	local L
	
    if hex:len() == 3 then
      --return (tonumber("0x"..hex:sub(1,1))*17)/255, (tonumber("0x"..hex:sub(2,2))*17)/255, (tonumber("0x"..hex:sub(3,3))*17)/255
      R = tonumber("0x"..hex:sub(1,1))*17/255
      G = tonumber("0x"..hex:sub(2,2))*17/255
      B = tonumber("0x"..hex:sub(3,3))*17/255
    else
    	R = tonumber("0x"..hex:sub(1,2))/255
    	G = tonumber("0x"..hex:sub(3,4))/255
    	B = tonumber("0x"..hex:sub(5,6))/255
    end
    
    L = (R * 0.299 + G * 0.587 + B * 0.114) --/ 256
    if L < 0.5 then
    	return "white"
    else
    	return "black"
    end
		
end
--- Test function for array manipulation
-- 
-- @param frame
-- @return Processed string
function p.TestArray(frame)
	local TestGroups = {"A", "B", "C", "B", "C"}
	local TestValues = {"Alpha", "Beta"}
	local FinalArray = {}
	local FinalString = ""
	
	for _, Group in pairs(TestGroups) do
		for _, Value in pairs(TestValues) do
			if FinalArray[Group] == nil then
				FinalArray[Group] = {}
			end
			
			table.insert(FinalArray[Group], Value)
		end
	end
	
	for ID, Group in pairs(FinalArray) do
		FinalString = FinalString .. "* " .. ID .. ": " .. table.concat(Group, ", ") .. string.char(10)
	end
	
	--return FinalArray["A"][1]
	return FinalString
end
function p.TestArray2(frame)
	local FinalArray = {}
	local FinalString = ""
	--local Actor = "Annie Wersching"
	local Actor = "Emily Coutts"
	local QueryResult = mw.smw.getQueryResult('[[Interprete::' .. Actor .. ']]|?' .. Actor .. '|sort=Numero di produzione|order=asc')
	
	if QueryResult == nil then
        return "''Nessun risultato''"
    end

    if type(QueryResult) == "table" then
    	for k, v in pairs(QueryResult.results) do
        	-- v.fulltext						represents EPISODE
        	-- v.printouts[Actor][1].fulltext	represents CHARACTER
        	local Episode = v.fulltext
        	local Character
        	
        	if v.printouts[Actor][1] == nil then
        		Character = "''Senza pagina''"
        	else
        		--[==[
        		Character = v.printouts[Actor][1].fulltext
        		if FinalArray[Character] == nil then
        			FinalArray[Character] = {}
        		end
				table.insert(FinalArray[Character], Episode)
				]==]
				for _, CurrChar in pairs(v.printouts[Actor]) do
					Character = CurrChar.fulltext
					if FinalArray[Character] == nil then
						FinalArray[Character] = {}
					end
    				table.insert(FinalArray[Character], Episode)
				end
        	end
        	
    	end
    else
    	return "''Il risultato non è una TABLE''"
    end
	
	for ID, Group in pairs(FinalArray) do
		FinalString = FinalString .. "* [[" .. ID .. "]]: [[" .. table.concat(Group, "]], [[") .. "]]" .. string.char(10)
	end
	
	return FinalString
end
--- Test function for spaces identifiaction
-- using regex
-- @param frame
-- @return Processed string
function p.TestSpaces(frame)
	local TestString = "Seven of Nine"
	
	return string.find(TestString, "[^%s]+$")
end
return p