local function onMapOpenedHandler()
    for _, vertex in ipairs(getEditorElementsByType(VERTEX_TYPE)) do
        if isElementValid(vertex) then
            local nextVertex = getNextVertex(vertex)
            if nextVertex then
                if isElement(nextVertex) then
                    if getElementType(nextVertex) ~= VERTEX_TYPE then
                        setNextVertex(vertex, nil)
                        outputDebugString(string.format(
                            "%s:%s property 'next' value %s:%s is an incorrect " ..
                                "element! Expected %s!", VERTEX_TYPE,
                            getElementID(vertex), getElementType(nextVertex),
                            getElementID(nextVertex), VERTEX_TYPE), 2)
                    end
                else
                    setNextVertex(vertex, nil)
                    outputDebugString(string.format(
                        "%s:%s property 'next' value is incorrect! Expected %s or " ..
                            "nil, got string:%s!", VERTEX_TYPE, getElementID(vertex),
                        VERTEX_TYPE, nextVertex), 2)
                end
            end
        end
    end

    for _, polygon in ipairs(getEditorElementsByType(POLYGON_TYPE)) do
        if isElementValid(polygon) then
            local firstVertex = getFirstVertex(polygon)
            if firstVertex then
                if isElement(firstVertex) then
                    if getElementType(firstVertex) == VERTEX_TYPE then
                        createColshape(polygon)
                    else
                        setFirstVertex(polygon, nil)
                        outputDebugString(string.format(
                            "%s:%s property 'first' value %s:%s is an incorrect " ..
                                "element! Expected %s!", POLYGON_TYPE,
                            getElementID(polygon), getElementType(firstVertex),
                            getElementID(firstVertex), VERTEX_TYPE), 2)
                    end
                end
            else
                outputDebugString(string.format("%s:%s doesn't have a first vertex",
                    POLYGON_TYPE, getElementID(polygon)), 1)
            end
        end
    end

    triggerClientEvent("onClientMapOpened", source)
end
addEventHandler("onMapOpened", root, onMapOpenedHandler)

function onStop()
    for _, polygon in ipairs(getEditorElementsByType(POLYGON_TYPE)) do
        destroyColshape(polygon)
    end
end

local function onElementCreateHandler()
    local sourceElementType = getElementType(source)
    if not isElementTypeInThisEDF(sourceElementType) then return end

    if sourceElementType == POLYGON_TYPE then
        if isElementValid(getFirstVertex(source)) then recreateAllColshapes() end
    elseif sourceElementType == VERTEX_TYPE then
        local nextVertex = getNextVertex(source)
        if isElementValid(nextVertex) then
            -- check if nextVertex is some polygon's 'first'
            for _, polygon in ipairs(getEditorElementsByType(POLYGON_TYPE)) do
                if getFirstVertex(polygon) == nextVertex then
                    setFirstVertex(polygon, source)
                end
            end

            -- find all vertices with their 'next' set to nextVertex and update their
            -- 'next' to the newly created vertex
            for _, vertex in ipairs(getEditorElementsByType(VERTEX_TYPE)) do
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
    local sourceElementType = getElementType(source)
    if not isElementTypeInThisEDF(sourceElementType) or not isEditorElement(source) then
        return
    end

    if sourceElementType == POLYGON_TYPE then
        if propertyName == "first" then
            -- changing any polygon's 'first' forces recreating all colshapes
            recreateAllColshapes()
        end
    elseif sourceElementType == VERTEX_TYPE then
        if propertyName == "next" then
            -- changing any vertex'es 'next' forces recreating all colshapes
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
    local sourceElementType = getElementType(source)
    if not isElementTypeInThisEDF(sourceElementType) or not isEditorElement(source) then
        return
    end

    if sourceElementType == POLYGON_TYPE then
        destroyColshape(source)
    elseif sourceElementType == VERTEX_TYPE then
        local nextVertex = getNextVertex(source)
        if isElementValid(nextVertex) then
            -- check if source was some polygon's 'first'
            for _, polygon in ipairs(getEditorElementsByType(POLYGON_TYPE)) do
                if getFirstVertex(polygon) == source then
                    setFirstVertex(polygon, nextVertex)
                end
            end

            -- find source's previous vertices and set their 'next' to source's 'next'
            local previousFound = false
            for _, vertex in ipairs(getEditorElementsByType(VERTEX_TYPE)) do
                if vertex ~= source and vertex ~= nextVertex then
                    if getNextVertex(vertex) == source then
                        previousFound = true
                        setNextVertex(vertex, nextVertex)
                    end
                end
            end
        end
        recreateAllColshapes()
    end
end
addEventHandler("onElementDestroy", root, onElementDestroyHandler)
