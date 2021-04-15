function isElementValid(element, elementType)
    -- element type check is skipped if elementType isn't given
    return element and isElement(element) and
               (not elementType or element.type == elementType)
end

function getElementProperty(theElement, key, expectedElementType)
    if not isElement(theElement) then return nil end

    local value = getElementData(theElement, key)
    if not expectedElementType then
        -- expectedElementType not given, skip further checks and return property value
        return value
    end

    if isElement(value) then
        -- property value is an element, ensure its type is correct
        if isElementValid(value, expectedElementType) then
            return value
        else
            outputDebugString(string.format(
                "element '%s' property '%s' value '%s' has incorrect element type! Expected '%s', got '%s'!",
                theElement.id, key, value.id, expectedElementType, value.type), 2)
            return nil
        end
    elseif type(value) == "string" then
        local parent = theElement.parent or theElement
        -- property value is a string, check if its a valid element ID
        for _, element in ipairs(getElementsByType(expectedElementType, parent)) do
            if element.id == value then
                if isElementValid(element, expectedElementType) then
                    -- update element's property to avoid this problem in the future
                    setElementData(theElement, key, element)
                    return element
                else
                    outputDebugString(string.format(
                        "element '%s' property '%s' value '%s' has incorrect element " ..
                            "type! Expected '%s', got '%s'!", theElement.id, key,
                        element.id, expectedElementType, element.type), 2)
                    return nil
                end
            end
        end
        outputDebugString(string.format(
            "element '%s' property '%s' has incorrect value '%s'! Expected an element of '%s' type",
            theElement.id, key, value, expectedElementType), 2)
        return nil
    end
end
