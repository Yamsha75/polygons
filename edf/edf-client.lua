addEvent("onClientMapOpened", true)
addEvent("onClientElementPostCreate", true)

local previousElement = nil
selectedPolygon = nil

local function onClientMapOpenedHandler()
    updateAllPolygonColors()
end
addEventHandler("onClientMapOpened", root, onClientMapOpenedHandler)

function onStop()
    previousElement = false
    selectedPolygon = false
end

local function onClientElementSelectHandler()
    local element = edf.edfGetAncestor(source) or source
    if not isElementValid(element) or not isElementTypeInThisEDF(element.type) then
        return
    end

    if element.type == "polygon" then
        selectedPolygon = element
    elseif element.type == "vertex" then
        selectedPolygon = getVertexPolygon(element)
    end

    updateAllPolygonColors()
end
addEventHandler("onClientElementSelect", root, onClientElementSelectHandler)

local function onClientElementPreCreateHandler(
    elementType, resourceName, initialParameters, ...
)
    if not isElementTypeInThisEDF(elementType) then return end

    if previousElement then
        -- previous creation hasn't finished yet; cancel event to avoid unwanted
        -- consequences
        cancelEvent()
        return
    end

    -- table for overwriting default initialParameters
    local overwriteParameters = {}

    local selectedElement = editor_main.getSelectedElement()

    if elementType == "polygon" then
        if not selectedPolygon and selectedElement and selectedElement.type == "vertex" then
            -- creating a polygon with a vertex selected; the vertex doesn't belong
            -- to a polygon; set the vertex as new polygon's first
            overwriteParameters.first = selectedElement
        end
    elseif elementType == "vertex" then
        if selectedElement and selectedElement.type == "vertex" then
            -- creating a vertex with a vertex selected; check selected vertex'es next
            local nextVertex = getNextVertex(selectedElement)
            if isElementValid(nextVertex) then
                -- set new vertex'ex next to nextVertex; onElementCreated handler in
                -- edf-server.lua will set selected vertex'es next to new vertex
                overwriteParameters.next = nextVertex
            else
                -- set selected vertex'es next to new vertex in
                -- onClientElementPostCreate event handler
                previousElement = selectedElement
            end
        elseif isElementValid(selectedPolygon) then
            -- creating a vertex with selectedPolygon existing; attach new vertex at end
            -- of company's boundary vertices list
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
        -- modify initialParameters, cancelEvent and trigger serverside doCreateElement
        -- which would have been triggered had this event not been cancelled
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
    if not isElementTypeInThisEDF(source.type) or not isElementValid(source) then
        return
    end

    if source.type == "vertex" then
        if isElementValid(previousElement) then
            if previousElement.type == "polygon" then
                setFirstVertex(previousElement, source)
            elseif previousElement.type == "vertex" then
                setNextVertex(previousElement, source)
            end
        elseif isElementValid(selectedPolygon) then
            local isSourceFirstVertex = false
            for _, polygon in ipairs(getEditorElementsByType("polygon")) do
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
                for _, vertex in ipairs(getEditorElementsByType("vertex")) do
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
    if not isElementTypeInThisEDF(source.type) then return end

    updateAllPolygonColors()
end
addEventHandler("onClientElementCreate", root, onClientElementCreateHandler)

local function onClientElementPropertyChanged(propertyName)
    if not isElementTypeInThisEDF(source.type) or isElementDestroyed(source) then
        return
    end

    if source.type == "polygon" then
        if propertyName == "first" then updateAllPolygonColors() end
    elseif source.type == "vertex" then
        if propertyName == "next" then updateAllPolygonColors() end
    end
end
addEventHandler("onClientElementPropertyChanged", root, onClientElementPropertyChanged)

local function onClientElementDestroy()
    if not isElementTypeInThisEDF(source.type) or not isEditorElement(source) then
        return
    end

    if source.type == "polygon" then
        if source == selectedPolygon then selectedPolygon = false end
        updateAllCompanyColors()
    elseif source.type == "vertex" then
        updateAllCompanyColors()
    end
end
addEventHandler("onClientElementDestroyed", root, onClientElementDestroy)
