POLYGON_TYPE = "polygon-center"
VERTEX_TYPE = "polygon-vertex"

function getElementMapElement(element)
    local parent = getElementParent(element)

    while parent and getElementType(parent) ~= "map" do
        parent = getElementParent(parent)
    end

    return parent
end

function getElementPropertyValue(theElement, propertyName, expectedElementType)
    if not isElement(theElement) then return nil end

    local propertyValue = getElementData(theElement, propertyName)

    if not propertyValue then
        -- unset properties are allowed
        return false
    end

    if not expectedElementType then
        -- expectedElementType not given, skip further checks and return property value
        return propertyValue
    end

    if isElement(propertyValue) then
        if getElementType(propertyValue) == expectedElementType then
            return propertyValue
        else
            outputDebugString(string.format(
                "Element %s:%s property '%s' value is an element of incorrect type! " ..
                    "Expected %s, got %s!", getElementType(theElement),
                getElementID(theElement), propertyName, expectedElementType,
                getElementType(propertyValue)), 1)
        end
    elseif type(propertyValue) == "string" then
        -- property value is a string; check if its a valid element ID; to avoid
        -- uncertainty with multiple elements using same ID, search only through
        -- theElement's parent map's elements
        local mapRootElement = getElementMapElement(theElement)
        for _, element in ipairs(getElementsByType(expectedElementType, mapRootElement)) do
            if getElementID(element) == propertyValue then
                -- found; update theElement's property to the element to skip these
                -- checks next time
                setElementData(theElement, propertyName, propertyValue)
                return element
            end
        end
        outputDebugString(string.format(
            "Element %s:%s property '%s' value '%s' isn't an existing %s element's ID!",
            getElementType(theElement), getElementID(theElement), propertyName,
            propertyValue, expectedElementType), 1)
    else
        outputDebugString(string.format(
            "Element %s:%s property '%s' has an incorrect type! Expected %s, got %s!",
            getElementType(theElement), getElementID(theElement), propertyName,
            expectedElementType, type(propertyValue)), 1)
    end
end

local function getFirstVertex(polygon)
    return getElementPropertyValue(polygon, "first", VERTEX_TYPE)
end

local function getNextVertex(vertex)
    return getElementPropertyValue(vertex, "next", VERTEX_TYPE)
end

local function getPolygonVertices(polygon)
    local firstVertex = getFirstVertex(polygon)
    if not firstVertex then return false end

    local vertices = {firstVertex} -- list of vertices in order from first to last
    local visited = {[firstVertex] = true} -- used to halt while loop if vertices loop
    local nextVertex = getNextVertex(firstVertex)

    while nextVertex and not visited[nextVertex] do
        visited[nextVertex] = true
        table.insert(vertices, nextVertex)
        nextVertex = getNextVertex(nextVertex)
    end

    return vertices
end

local function createPolygonColshape(polygon)
    local vertices = getPolygonVertices(polygon)

    if not vertices or #vertices < 3 then
        outputDebugString("Polygon has less than 3 vertices!", 1)
        return false
    end

    local x, y = getElementPosition(polygon)
    local colshapePosition = Vector2(x, y) -- colshape's "center" position
    local coords = {} -- colshape's vertices' (x, y) positions
    for index, vertex in ipairs(vertices) do
        x, y = getElementPosition(vertex)
        coords[index] = Vector2(x, y)
    end

    local colshape = createColPolygon(colshapePosition, unpack(coords))
    if not colshape then
        outputDebugString("createColPolygon returned false!", 1)
        return false
    end

    setElementData(polygon, "polygon-colshape", colshape)
    setElementParent(colshape, polygon)

    return colshape
end

function createResourcePolygonColshapes(resourceRootElement)
    for _, polygon in ipairs(getElementsByType(POLYGON_TYPE, resourceRootElement)) do
        if not getElementData(polygon, "polygon-colshape") then
            local colshape = createPolygonColshape(polygon)
            if not colshape then
                outputDebugString(string.format(
                    "Could not create colshape using %s:%s from resource:%s!",
                    POLYGON_TYPE, getElementID(polygon),
                    getElementID(resourceRootElement)), 1)
            end
        end
    end
end

local function onThisResourceStartHandler()
    if not IS_EDF_RESOURCE then
        createResourcePolygonColshapes(resourceRoot)
    end
end
addEventHandler("onResourceStart", resourceRoot, onThisResourceStartHandler)
