function getVariableType(variable)
    local variableType = type(variable)
    if variableType ~= "userdata" then return variableType end

    local variableType = getUserdataType(variable)
    if variableType ~= "element" then return variableType end

    return getElementType(variable)
end

local function failAssert(expected, got, argumentNumber)
    if argumentNumber then
        error(string.format("expected %s at argument %d, got %s", expected,
            argumentNumber, got), 3)
    else
        error(string.format("expected %s as argument, got %s", expected, got), 3)
    end
end

function assertType(variable, expectedType, argumentNumber)
    local variableType = getVariableType(variable)
    if variableType ~= expectedType then
        failAssert(expectedType, variableType, argumentNumber)
    end
end

function assertElement(variable, argNumber)
    if not isElement(variable) then
        failAssert("element", getVariableType(variableType), argumentNumber)
    end
end
