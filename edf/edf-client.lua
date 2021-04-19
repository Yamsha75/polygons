addEvent("onClientEDFStart")
addEvent("onClientEDFStop")
addEvent("onClientMapOpened", true)
addEvent("onClientElementPostCreate", true)

local previousElement = nil
selectedPolygon = nil

local function onClientMapOpenedHandler()
    updateAllPolygonColors()
end
addEventHandler("onClientMapOpened", root, onClientMapOpenedHandler)

function onStart()
    triggerEvent("onClientEDFStart", localPlayer)
end

function onStop()
    previousElement = nil
    selectedPolygon = nil

    triggerEvent("onClientEDFStop", localPlayer)
end

local function onClientElementSelectHandler()
    local element = edf.edfGetAncestor(source) or source
    if not isElement(element) then return end

    local elementType = getElementType(element)
    if not isElementValid(element) or not isElementTypeInThisEDF(elementType) then
        return
    end

    local previousSelectedPolygon = selectedPolygon

    if elementType == POLYGON_TYPE then
        selectedPolygon = element
    elseif elementType == VERTEX_TYPE then
        selectedPolygon = getVertexPolygon(element)
    end

    if previousSelectedPolygon ~= selectedPolygon then updateAllPolygonColors() end
end
addEventHandler("onClientElementSelect", root, onClientElementSelectHandler)

local function onClientElementPreCreateHandler(
    elementType, resourceName, initialParameters, ...
)
    if not isElementTypeInThisEDF(elementType) then return end

    if previousElement then
        -- previous element creation hasn't finished yet; cancel event to avoid unwanted
        -- consequences
        cancelEvent()
        return
    end

    -- table for overwriting default initialParameters
    local overwriteParameters = {}

    local selectedElement = editor_main.getSelectedElement()
    local selectedElementType = false
    if selectedElement then selectedElementType = getElementType(selectedElement) end

    if elementType == POLYGON_TYPE then
        if not selectedPolygon and selectedElementType == VERTEX_TYPE then
            -- creating a polygon with a vertex selected; the vertex doesn't belong
            -- to any polygon; set the vertex as new polygon's first
            overwriteParameters.first = selectedElement
        end
    elseif elementType == VERTEX_TYPE then
        if selectedElementType == VERTEX_TYPE then
            -- creating a vertex with a vertex selected; check selected vertex'es next
            local nextVertex = getNextVertex(selectedElement)
            if isElementValid(nextVertex) then
                -- set new vertex'ex next to nextVertex; onElementCreated handler in
                -- edf-server.lua will set selected vertex'es next to the new vertex
                overwriteParameters.next = nextVertex
            else
                -- set selected vertex'es next to new vertex in
                -- onClientElementPostCreate event handler
                previousElement = selectedElement
            end
        elseif isElementValid(selectedPolygon) then
            -- creating a vertex with selectedPolygon existing; attach new vertex at end
            -- of polygons's vertices list
            local vertices = getPolygonVertices(selectedPolygon)
            if not vertices then
                -- set new vertex as polygon's first
                previousElement = selectedPolygon
            else
                -- attach at end of vertices list
                local lastVertex = vertices[#vertices]
                local nextVertex = getNextVertex(lastVertex)
                if isElementValid(nextVertex) then
                    -- list is a loop; nextVertex is the first vertex in list
                    overwriteParameters.next = nextVertex
                else
                    -- list is not a loop
                    previousElement = lastVertex
                end
            end
        end
    end

    if next(overwriteParameters) then
        -- at least one paremeter has been overwritten; modify initialParameters,
        -- cancelEvent and trigger serverside event "doCreateElement" using modified 
        -- initialParameters; the event would have been triggered had this event not
        -- been cancelled
        for key, value in pairs(overwriteParameters) do
            initialParameters[key] = value
        end

        cancelEvent()
        triggerServerEvent("doCreateElement", localPlayer, elementType, resourceName,
            initialParameters, ...)
    end
end
addEventHandler("onClientElementPreCreate", root, onClientElementPreCreateHandler)

local function onClientElementPostCreateHandler()
    local sourceElementType = getElementType(source)
    if not isElementTypeInThisEDF(sourceElementType) or not isElementValid(source) then
        return
    end

    if sourceElementType == VERTEX_TYPE then
        if isElementValid(previousElement) then
            local previousElementType = getElementType(previousElement)
            if previousElementType == POLYGON_TYPE then
                setFirstVertex(previousElement, source)
            elseif previousElementType == VERTEX_TYPE then
                setNextVertex(previousElement, source)
            end
        elseif isElementValid(selectedPolygon) then
            local isSourceFirstVertex = false
            for _, polygon in ipairs(getEditorElementsByType(POLYGON_TYPE)) do
                if source == getFirstVertex(polygon) then
                    -- source is some polygon's first vertex, so we shouldn't put it 
                    -- after the same polygon's last vertex; if it's a loop, it is
                    -- already handled in serverside onElementCreate handler
                    isSourceFirstVertex = true
                    break
                end
            end
            if not isSourceFirstVertex then
                local previousVertex
                for _, vertex in ipairs(getEditorElementsByType(VERTEX_TYPE)) do
                    if getNextVertex(vertex) == source then
                        previousVertex = vertex
                        break
                    end
                end
                if not previousVertex then
                    local vertices = getPolygonVertices(selectedPolygon)
                    local lastVertex = vertices[#vertices]
                    setNextVertex(lastVertex, source)
                end
            end
        end
    end

    previousElement = false
end
addEventHandler("onClientElementPostCreate", root, onClientElementPostCreateHandler)

local function onClientElementCreateHandler()
    if not isElementTypeInThisEDF(getElementType(source)) then return end

    updateAllPolygonColors()
end
addEventHandler("onClientElementCreate", root, onClientElementCreateHandler)

local function onClientElementPropertyChanged(propertyName)
    local sourceElementType = getElementType(source)
    if not isElementTypeInThisEDF(sourceElementType) or isElementDestroyed(source) then
        return
    end

    if sourceElementType == POLYGON_TYPE then
        if propertyName == "first" then updateAllPolygonColors() end
    elseif sourceElementType == VERTEX_TYPE then
        if propertyName == "next" then updateAllPolygonColors() end
    end
end
addEventHandler("onClientElementPropertyChanged", root, onClientElementPropertyChanged)

local function onClientElementDestroy()
    local sourceElementType = getElementType(source)
    if not isElementTypeInThisEDF(sourceElementType) or not isEditorElement(source) then
        return
    end

    if sourceElementType == POLYGON_TYPE then
        if source == selectedPolygon then selectedPolygon = false end
    end

    updateAllPolygonColors()
end
addEventHandler("onClientElementDestroyed", root, onClientElementDestroy)

function showInfo(message, r, g, b)
    r = tonumber(r) or 0
    g = tonumber(g) or 255
    b = tonumber(b) or 0
    message = "INFO: polygons: " .. message
    outputChatBox(message, r, g, b)
    editor_gui.outputMessage(message, r, g, b, 5000)
end
setTimer(showInfo, 5000, 1, "Use command 'showpoly' to see colshapes")

local function showPolyCommandHandler()
    local enabled = not getDevelopmentMode()

    setDevelopmentMode(enabled)
    showCol(enabled)

    message = "showing colshapes is now " .. (enabled and "enabled" or "disabled")
    showInfo(message)
end
addCommandHandler("showpoly", showPolyCommandHandler)
