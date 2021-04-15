local function onMapOpenedHandler()
    local nextVertex
    for _, vertex in ipairs(getEditorElementsByType("vertex")) do
        if isElementValid(vertex) then
            nextVertex = getNextVertex(vertex)
            if nextVertex then
                if isElement(nextVertex) then
                    if nextVertex.type ~= "vertex" then
                        outputDebugString(string.format(
                            "vertex:%s property 'next' value %s:%s is an incorrect " ..
                                "element! Expected vertex!", vertex.id, nextVertex.type,
                            nextVertex.id), 2)
                        setNextVertex(vertex, nil)
                    end
                else
                    outputDebugString(string.format(
                        "vertex:%s property 'next' value is incorrect! Expected " ..
                            "vertex or nil, got string:%s!", vertex.id, nextVertex), 2)
                    setNextVertex(vertex, nil)
                end
            end
        end
    end

    local firstVertex
    for _, polygon in ipairs(getEditorElementsByType("polygon")) do
        if isElementValid(polygon) then
            firstVertex = getFirstVertex(polygon)
            if firstVertex then
                if isElement(firstVertex) then
                    if firstVertex.type == "vertex" then
                        createColshape(polygon)
                    else
                        outputDebugString(string.format(
                            "polygon:%s property 'first' value %s:%s is an incorrect " ..
                                "element! Expected vertex!", polygon.id,
                            firstVertex.type, firstVertex.id), 2)
                        setFirstVertex(polygon, nil)
                    end
                end
            else
                outputDebugString(string.format(
                    "polygon:%s doesn't have a first vertex", polygon.id), 1)
            end
        end
    end

    triggerClientEvent("onClientMapOpened", source)
end
addEventHandler("onMapOpened", root, onMapOpenedHandler)

function onStop()
    for _, polygon in ipairs(getEditorElementsByType("polygon")) do
        destroyColshape(polygon)
    end
end

local function onElementCreateHandler()
    if not isElementTypeInThisEDF(source.type) then return end

    if source.type == "polygon" then
        if isElementValid(getFirstVertex(source)) then recreateAllColshapes() end
    elseif source.type == "vertex" then
        local nextVertex = getNextVertex(source)
        if isElementValid(nextVertex) then
            -- find all vertices with their next set to nextVertex and update their next
            -- to the newly created vertex
            for _, vertex in ipairs(getEditorElementsByType("vertex")) do
                if vertex ~= source and vertex ~= nextVertex and isElementValid(vertex) then
                    if getNextVertex(vertex) == nextVertex then
                        setNextVertex(vertex, source)
                    end
                end
            end
        end
        recreateAllColshapes()
    end

    local creatorClient = edf.edfGetCreatorClient(source)
    if creatorClient then
        triggerClientEvent(creatorClient, "onClientElementPostCreate", source)
    end
end
addEventHandler("onElementCreate", root, onElementCreateHandler)

local function onElementPropertyChanged(propertyName)
    if not isElementTypeInThisEDF(source.type) or not isEditorElement(source) then
        return
    end

    if source.type == "polygon" then
        if propertyName == "first" then
            -- changing any polygon's first vertex forces recreating all colshapes
            recreateAllColshapes()
        end
    elseif source.type == "vertex" then
        if propertyName == "next" then
            -- changing any vertex'es next forces recreating all colshapes
            recreateAllColshapes()
        elseif propertyName == "position" then
            -- changing any vertex'es position forces recreating its polygon's colshape
            local polygon = getVertexPolygon(source)
            if polygon then
                destroyColshape(polygon)
                if isElementValid(polygon) then createColshape(polygon) end
            end
        end
    end
end
addEventHandler("onElementPropertyChanged", root, onElementPropertyChanged)

local function onElementDestroyHandler()
    if not isElementTypeInThisEDF(source.type) or not isEditorElement(source) then
        return
    end

    if source.type == "polygon" then
        destroyColshape(source)
    elseif source.type == "vertex" then
        local nextVertex = getNextVertex(source)
        if isElementValid(nextVertex) then
            -- find source's previous vertices and set their next to source's next
            for _, vertex in ipairs(getEditorElementsByType("vertex")) do
                if vertex ~= source and vertex ~= nextVertex then
                    if getNextVertex(vertex) == source then
                        setNextVertex(vertex, nextVertex)
                    end
                end
            end
        end
        recreateAllColshapes()
    end
end
addEventHandler("onElementDestroy", root, onElementDestroyHandler)
