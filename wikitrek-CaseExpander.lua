-- [P2G] Auto upload by PageToGitHub on 2026-01-11T21:43:16+01:00
-- [P2G] This code from page Modulo:wikitrek-CaseExpander
--- Module:CaseExpander
-- Central code expansion system for MediaWiki templates
-- Parses a CodesList subpage and provides code expansion and list generation
-- @module CaseExpander
-- @author Luca Mauri
-- @Keyword wikitrek
local p = {}

--- Parses a CasesList page and returns structured case data
-- Reads a template's /CasesList subpage and creates mappings for codes,
-- aliases, and expansions. Supports case-insensitive lookups.
--
-- CasesList format:
--   CODE1, CODE2 = Expansion text for both codes
--   CODE3 = Expansion text for CODE3
--
-- @param templateName string The name of the template (e.g., "Template:Ship")
-- @return table A table with two keys:
--   - mappings: table mapping lowercase codes to expansion text
--   - codeGroups: table of code group tables, each containing:
--     * codes: list of original code names (preserving case)
--     * expansion: the expansion text
--     * primary: the primary (first) code in lowercase
function p.parseCasesList(templateName)
    -- Construct the CasesList page path from the template name
    local casesListPageName = templateName .. "/CasesList"
    
    -- Read the CasesList page directly (not as a template)
    local casesListTitle = mw.title.new(casesListPageName)
    if not casesListTitle or not casesListTitle.exists then
        return {mappings = {}, codeGroups = {}}
    end
    
    local content = casesListTitle:getContent()
    if not content then
        return {mappings = {}, codeGroups = {}}
    end
    
    -- Parse the content into a table
    local mappings = {}      -- maps each code (lowercase) to its expansion
    local codeGroups = {}    -- groups of aliases pointing to same expansion
    
    -- Process each line of the CasesList
    for line in content:gmatch("[^\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")  -- trim whitespace
        
        if line ~= "" and not line:match("^%-%-") then  -- skip empty lines and comments
            -- Parse: "CODE1, CODE2, CODE3 = Expansion text"
            local codesStr, expansion = line:match("^([^=]+)=(.+)$")
            
            if codesStr and expansion then
                expansion = expansion:gsub("^%s+", ""):gsub("%s+$", "")  -- trim expansion
                
                -- Split codes by comma and store them
                local codes = {}
                for code in codesStr:gmatch("[^,]+") do
                    code = code:gsub("^%s+", ""):gsub("%s+$", "")  -- trim each code
                    table.insert(codes, code)
                end
                
                -- Store the group and create mappings
                if #codes > 0 then
                    local primaryCode = codes[1]:lower()
                    table.insert(codeGroups, {
                        codes = codes,
                        expansion = expansion,
                        primary = primaryCode
                    })
                    
                    -- Map all codes (case-insensitive) to expansion
                    for _, code in ipairs(codes) do
                        mappings[code:lower()] = expansion
                    end
                end
            end
        end
    end
    
    return {mappings = mappings, codeGroups = codeGroups}
end

--- Expands a single case/code to its full text
-- Performs case-insensitive lookup of a code and returns its expansion.
-- If the code is not found, returns the default value.
--
-- Usage from template:
--   {{#invoke:CaseExpander|expand|CODENAME|DefaultText}}
-- OR if called from a different context:
--   {{#invoke:CaseExpander|expand|CODENAME|DefaultText|Template:Ship}}
--
-- @param frame frame object from MediaWiki with args:
--   - [1]: the code to expand (required)
--   - [2]: the default text if code not found (optional, default: "Unknown case")
--   - [3]: the template name (optional, auto-detected if not provided)
-- @return string The expansion text or default value
function p.expand(frame)
    local code = frame.args[1] or ""
    local default = frame.args[2] or "Unknown case"
    
    -- Try to get template name from args, otherwise auto-detect
    local templateName = frame.args[3]
    if not templateName or templateName == "" then
        local currentTitle = mw.title.getCurrentTitle()
        templateName = currentTitle.prefixedText
    end
    
    local data = p.parseCasesList(templateName)
    
    local expansion = data.mappings[code:lower()]
    
    if expansion then
        return expansion
    else
        return default
    end
end

--- Generates a formatted list or table of all cases
-- Creates a display of all available cases and their expansions.
-- Can output as a formatted HTML table or a bullet list.
--
-- Usage from template:
--   {{#invoke:CaseExpander|listAll|format=table}}
-- OR if called from a different context:
--   {{#invoke:CaseExpander|listAll|Template:Ship|format=table}}
--
-- @param frame frame object from MediaWiki with args:
--   - [1]: the template name (optional, auto-detected if not provided)
--   - format: output format - "table" or "list" (optional, default: "table")
-- @return string HTML or wikitext formatted list of all cases
function p.listAll(frame)
    -- Try to get template name from args, otherwise auto-detect
    local templateName = frame.args[1]
    if not templateName or templateName == "" then
        local currentTitle = mw.title.getCurrentTitle()
        templateName = currentTitle.prefixedText
    end
    
    local format = frame.args.format or "table"
    
    local data = p.parseCasesList(templateName)
    
    local result = ""
    
    if format == "table" then
        -- Generate HTML table with sortable class
        result = '<table class="wikitable sortable" style="width:80%">\n'
        result = result .. '<tr><th style="width:40%">Valore del parametro</th><th>Testo restituito</th></tr>\n'
        
        for _, group in ipairs(data.codeGroups) do
            local codesDisplay = table.concat(group.codes, ", ")
            result = result .. '<tr><td>' .. codesDisplay .. '</td><td>' .. group.expansion .. '</td></tr>\n'
        end
        
        result = result .. '</table>'
    
    elseif format == "list" then
        -- Generate bullet list
        for _, group in ipairs(data.codeGroups) do
            local codesDisplay = table.concat(group.codes, ", ")
            result = result .. "* " .. codesDisplay .. " - " .. group.expansion .. "\n"
        end
        result = result:gsub("\n$", "")  -- remove trailing newline
    end
    
    return result
end

return p