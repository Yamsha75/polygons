local EDF_ELEMENT_TYPES = {["polygon"] = true, ["vertex"] = true}

local workingDimension = editor_main.getWorkingDimension()
local destroyedElementsDimension = workingDimension + 1
local mapContainer = getElementsByType("mapContainer")[1]

function isElementTypeInThisEDF(elementType)
    return EDF_ELEMENT_TYPES[elementType] == true
end

function getEditorElementsByType(elementType)
    assertType(elementType, "string")

    return getElementsByType(elementType, mapContainer)
end

function isElementDestroyed(element)
    assertElement(element)

    return edf.edfGetElementDimension(element) == destroyedElementsDimension
end

function isEditorElement(element)
    assertElement(element)

    local parent = element.parent
    while parent and parent ~= mapContainer do parent = parent.parent end

    if parent then
        return true
    else
        return false
    end
end

function isElementValid(element)
    return isElement(element) and not isElementDestroyed(element) and
               isEditorElement(element)
end

function getEditorRepresentation(theElement, representationElementType)
    assertElement(theElement, 1)
    assertType(representationElementType, "string", 2)

    for _, element in ipairs(getElementsByType(representationElementType, theElement)) do
        if element ~= edf.edfGetHandle(element) then return element end
    end
    return false
end

function setElementProperty(element, key, value)
    assertElement(element, 1)
    assertType(key, "string", 2)

    if key == "position" then return edf.edfSetElementPosition(element, value) end

    return edf.edfSetElementProperty(element, key, value)
end

function getElementProperty(element, key)
    assertElement(element, 1)
    assertType(key, "string", 2)

    if key == "position" then return edf.edfGetElementPosition(element) end

    return edf.edfGetElementProperty(element, key)
end
