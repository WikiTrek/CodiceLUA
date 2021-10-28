-- [P2G] Auto upload by PageToGitHub on 2021-10-28T22:37:40+02:00
-- [P2G] This code from page Modulo:wikitrek-DTSpecific
--- This module represent the package containing specific functions to access data from the WikiBase instance DataTrek
-- @module p
-- @author Luca Mauri [[Utente:Lucamauri]]
-- Add other authors below
-- Keyword: wikitrek
local p = {}
--- generates a list of backlink using SMW query.
-- 
-- @frame Info from MW session
-- @return A bullet list of appearances
function p.ListAppearances(frame)
	-- See example
	--[=[
	{{#ask: [[Interprete::Carl Tart]]
	 |?Carl Tart
	 |?Numero di produzione
	 |?Data di trasmissione
	 |format=ol
	 |sot=Numero di produzione
	 |order=asc
	 |class=sortable wikitable smwtable
	}}
	]=]

	-- See also
	--[=[
	{{#ask: [[Interprete::{{PAGENAME}}]]
	 |?{{PAGENAME}}
	}}
	]=]
	
	
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
	--local QueryResult = mw.smw.getQueryResult('[[Interprete::' .. mw.title.getCurrentTitle().text .. ']]|?DataTrek ID')
	local QueryResult = mw.smw.getQueryResult('[[Riferimento::' .. mw.title.getCurrentTitle().text .. ']]|?' .. mw.title.getCurrentTitle().text)
	
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
            	Row = Row .. " - " .. v.printouts['DataTrek ID'][1]
            end
            
			AllBackReferences[#AllBackReferences + 1] = "*" .. Row
        end
        	return table.concat(AllBackReferences, string.char(10))
    else
    	return "''No table''"
    end

    return queryResult
end
return p