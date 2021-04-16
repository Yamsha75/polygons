POLYGON_TYPE = "polygon-center"
VERTEX_TYPE = "polygon-vertex"
local EDF_ELEMENT_TYPES = {[POLYGON_TYPE] = true, [VERTEX_TYPE] = true}

local WORKING_DIMENSION = editor_main.getWorkingDimension()
local DESTROYED_ELEMENTS_DIMENSION = WORKING_DIMENSION + 1
local MAP_CONTAINER = getElementsByType("mapContainer")[1]

function isElementTypeInThisEDF(elementType)
    assertArgumentType(elementType, "string")

    return EDF_ELEMENT_TYPES[elementType] == true
end

function getEditorElementsByType(elementType)
    assertArgumentType(elementType, "string")

    return getElementsByType(elementType, MAP_CONTAINER)
end

function isElementDestroyed(element)
    assertArgumentIsElement(element)

    return edf.edfGetElementDimension(element) == DESTROYED_ELEMENTS_DIMENSION
end

function isEditorElement(element)
    assertArgumentIsElement(element)

    local parent = getElementParent(element)
    while parent and parent ~= MAP_CONTAINER do parent = getElementParent(parent) end

    return parent == MAP_CONTAINER
end

function isElementValid(element)
    return isElement(element) and not isElementDestroyed(element) and
               isEditorElement(element)
end

function getEditorRepresentation(theElement, representationElementType)
    assertArgumentIsElement(theElement, 1)
    assertArgumentType(representationElementType, "string", 2)

    for _, element in ipairs(getElementsByType(representationElementType, theElement)) do
        if element ~= edf.edfGetHandle(element) then return element end
    end
    return false
end

function setElementProperty(element, key, value)
    assertArgumentIsElement(element, 1)
    assertArgumentType(key, "string", 2)

    if key == "position" then return edf.edfSetElementPosition(element, value) end

    return edf.edfSetElementProperty(element, key, value)
end

function getElementProperty(element, key)
    assertArgumentIsElement(element, 1)
    assertArgumentType(key, "string", 2)

    if key == "position" then return edf.edfGetElementPosition(element) end

    return edf.edfGetElementProperty(element, key)
end
