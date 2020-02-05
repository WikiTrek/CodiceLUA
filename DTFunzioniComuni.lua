-- Auto upload by PageToGitHub on 2020-02-06T00:12:18+01:00
-- This code from page Modulo:DTFunzioniComuni
local p = {}
function p.ImmagineDaFile(Frame)
    local item = mw.wikibase.getEntityIdForCurrentPage()
	if not item then return '' end
	
	local results = {}
	local statements = mw.wikibase.getBestStatements(item, 'P3')
	for _, statement in pairs(statements) do
		if statement.mainsnak.snaktype == 'value' then
			local Immagine = statement.mainsnak.datavalue.value
			
			if Immagine then
				results[#results + 1] = '[[File:' .. Immagine .. '|' .. Frame.args.OpzioniImmagine .. ']]'
			else
				results[#results + 1] = 'VUOTO'
			end
		else
			results[#results + 1] = 'ERRORE'
		end
	end
	return table.concat(results, ', ')
end
function p.Date(frame)
	local entity = mw.wikibase.getEntity()
	-- local snak = entity['claims']['P2'][1]

    -- return entity['claims']['P2'][1].value
    return entity.claims['P2'].value
end
function p.Network(frame)
	local entity = mw.wikibase.getEntity()
	local snak = entity['claims']['P2'][1]['qualifiers']['P4'][1]

    return mw.wikibase.renderSnak( snak )
end
function p.URL(frame)
    return mw.wikibase.getEntityUrl()
end
function p.List(frame)
	local entity = mw.wikibase.getEntity()
	local snak = entity['claims']['P2']
	local result = ''
	for index, value in next, snak do
		result = result .. mw.wikibase.renderSnak(value)
	end
end
function p.LinkFromPage(frame)
	local item = mw.wikibase.getEntityIdForCurrentPage()
	if not item then return '' end
	local results = {}
	local statements = mw.wikibase.getBestStatements(item, 'P7')
	for _, statement in pairs(statements) do
		if statement.mainsnak.snaktype == 'value' then
			local value = statement.mainsnak.datavalue.value
			local sitelink = value
			local label = null
			if sitelink then
				if label then
					results[#results + 1] = '[[' .. sitelink .. '|' .. label .. ']]'
				else
					results[#results + 1] = '[[' .. sitelink .. ']]'
				end
			elseif label then
				results[#results + 1] = label
			end
		end
	end
	return table.concat(results, ', ')
end