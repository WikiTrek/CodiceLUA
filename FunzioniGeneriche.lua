-- Auto upload by PageToGitHub2020-02-05
-- This code from page Modulo:FunzioniGeneriche
-- Questo codice proviene dal Modulo:FunzioniGeneriche

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
    local CodeString = 'Il codice:'
    local ReturnString = 'restituisce'

    pre
       :css( 'width', '65%' )
       :wikitext(mw.text.nowiki(SubPageTitle:getContent()))
    return  Intro .. DoubleLF .. CodeString .. DoubleLF .. tostring(pre) .. DoubleLF  .. ReturnString .. DoubleLF .. frame:expandTemplate{ title = SubPageTitle }
end

return p