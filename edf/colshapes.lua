local refreshTimer = nil

function createColshape(polygon)
    assertType(polygon, "polygon")

    local vertices = getPolygonVertices(polygon)

    if not vertices or #vertices < 3 then return false end

    local x, y = getElementProperty(polygon, "position")
    local colshapePosition = Vector2(x, y) -- colshape's "center" position
    local coords = {} -- list of colshape's vertices' (x, y) positions

    for index, vertex in ipairs(vertices) do
        x, y = getElementProperty(vertex, "position")
        coords[index] = Vector2(x, y)
    end

    local colshape = createColPolygon(colshapePosition, unpack(coords))

    if not colshape then return false end

    setElementParent(colshape, polygon)
    return colshape
end

function destroyColshape(polygon)
    assertType(polygon, "polygon")

    for _, colshape in ipairs(getElementsByType("colshape"), polygon) do
        if colshape.shapeType == 4 then destroyElement(colshape) end
    end
end

local function doRecreateAllColshapes()
    for _, polygon in ipairs(getEditorElementsByType("polygon")) do
        destroyColshape(polygon)
        if isElementValid(polygon) then createColshape(polygon) end
    end
end

function recreateAllColshapes()
    if refreshTimer and isTimer(refreshTimer) then killTimer(refreshTimer) end
    refreshTimer = setTimer(doRecreateAllColshapes, 100, 1)
end
