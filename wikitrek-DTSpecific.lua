-- [P2G] Auto upload by PageToGitHub on 2021-11-01T11:02:04+01:00
-- [P2G] This code from page Modulo:wikitrek-DTSpecific
--- This module represent the package containing specific functions to access data from the WikiBase instance DataTrek
-- @module p
-- @author Luca Mauri [[Utente:Lucamauri]]
-- Add other authors below
-- Keyword: wikitrek
local p = {}
local dump
local concat
local print
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
	local AllAppearances = {}
	local Appearances = {}
	local Appearance = {}
	local Episodes = {}
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
	local Actor = mw.title.getCurrentTitle().text
	local QueryResult = mw.smw.getQueryResult('[[Interprete::' .. Actor .. ']]|?' .. Actor)
	
	if QueryResult == nil then
        return "''Nessun risultato''"
    end

    if type(QueryResult) == "table" then
        local Row = ""
        local CurrChar
        for k, v in pairs(QueryResult.results) do
        	-- v.fulltext						represents EPISODE
        	-- v.printouts[Actor][1].fulltext	represents CHARACTER
        	
            --[=[if  v.fulltext and v.fullurl then
                myResult = myResult .. k .. " | " .. v.fulltext .. " " .. v.fullurl .. " | " .. "<br/>"
            else
                myResult = myResult .. k .. " | no page title for result set available (you probably specified ''mainlabel=-')"
            end]=]
            --[=[
            if string.sub(v.fulltext, 1, 5) == "File:" then
				Row = "[[:" .. v.fulltext .. "]]" --string.sub(v.fulltext, 3)
			else
				Row = "[[" .. v.fulltext .. "]]"
            end
            if v.printouts['DataTrek ID'][1] ~= nil then
            	Row = Row .. " - " .. v.printouts['DataTrek ID'][1]
            end
            ]=]
            
            --[=[
            for x, y in pairs(v.printouts) do
            	Row = Row .. k .. " -  " .. v.fulltext .. " - " .. x .. y[1].fulltext
            end
            ]=]
            
            if CurrChar == nil or CurrChar == "" or CurrChar ~= v.printouts[Actor][1].fulltext then
            	if Episodes ~= nil and CurrChar ~= nil then
            		-- episodes list contains data to print out, print it
            		Row = CurrChar .. ": " .. table.concat(Episodes, ", ")
            		Episodes = {}
            	end
        		
        		CurrChar = v.printouts[Actor][1].fulltext
            end
    		Episodes[#Episodes + 1] = v.fulltext
            
            --Row = k .. " -  " .. v.fulltext .. " - " .. v.printouts[Actor][1].fulltext
            
            --[=[
            if Appearance.Character == nil or Appearance.Character[v.fulltext] == nil then
            	Appearance.Character = v.fulltext
            end
        	
        	Appearance.Character[v.fulltext].Episodes[#Appearance.Character[v.fulltext].Episodes + 1] = v.printouts[Actor][1].fulltext
            Appearances[#Appearances + 1] = Appearence
            ]=]
			
			AllAppearances[#AllAppearances + 1] = "*" .. Row
        end
        	if Episodes ~= nil then
        		-- episodes list contains data to print out, print it
            	Row = CurrChar .. ": " .. table.concat(Episodes, ", ")
            	Episodes = {}
        	end
        	AllAppearances[#AllAppearances + 1] = "*" .. Row
        	
            --return '<pre>' .. dump(QueryResult) .. '</pre>'
        	return table.concat(AllAppearances, string.char(10)) --.. string.char(10) .. '<pre>' .. dump(QueryResult) .. '</pre>'
    else
    	return "''No table''"
    end

    return queryResult
end
--- This dumps the variable (converts it into a string representation of itself)
--
-- @param entity mixed, value to dump
-- @param indent string, can bu used to set an indentation
-- @param omitType bool, set to true to omit the (<TYPE>) in front of the value
--
-- @return string
dump = function(entity, indent, omitType)
    local entity = entity
    local indent = indent and indent or ''
    local omitType = omitType
    if type( entity ) == 'table' then
        local subtable
        if not omitType then
            subtable = '(table)[' .. #entity .. ']:'
        end
        indent = indent .. '\t'
        for k, v in pairs( entity ) do
            subtable = concat(subtable, '\n', indent, k, ': ', dump(v, indent, omitType))
        end
        return subtable
    elseif type( entity ) == 'nil' or type( entity ) == 'function' or type( entity ) == 'boolean' then
        return ( not omitType and '(' .. type(entity) .. ') ' or '' ) .. print(entity)
    elseif type( entity ) == 'string' then
        entity = mw.ustring.gsub(mw.ustring.gsub(entity, "\\'", "'"), "'", "\\'")
        return concat(omitType or '(string) ', '\'', entity, '\'')
    else
        -- number value expected
        return concat(omitType or '(' .. type( entity ) .. ') ', entity)
    end
end
--- Concatenates a variable number of strings and numbers to one single string
-- ignores tables, bools, functions, and such and replaces them with the empty string
--
-- What is the benefit of using variable.concat instead of the .. operator?
-- Answer: .. throws an error, when trying to concat bools, tables, functions, etc.
-- This here handels them by converting them to an empty string
--
-- @param ... varaibles to concatenate
--
-- @return string
concat = function(...)
    local args = {...}
    if #args == 0 then
        error('you must supply at least one argument to \'concat\' (got none)')
    end
    local firstArg = table.remove(args, 1)
    if type(firstArg) == 'string' or type(firstArg) == 'number' then
        firstArg = print(firstArg)
    else
        firstArg = ''
    end
    if #args == 0 then
        return firstArg
    else
        return firstArg .. concat(unpack(args))
    end
end
--- This function prints a variable depending on its type:
-- * tables get concatenated by a comma
-- * bools get printed as true or false
-- * strings and numbers get simple returned as string
-- * functions and nils return as emtpy string
-- @return string
print = function(v)
    if type( v ) == 'table' then
        return table.concat(v, ',')
    elseif type( v ) == 'boolean' then
        return ( v and 'true' or 'false' )
    elseif type(v) == 'string' or type(v) == 'number' then
        return tostring(v)
    else
        return ''
    end
end
return p