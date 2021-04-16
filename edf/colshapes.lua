local UPDATE_DELAY = 100 -- ms

-- this timer is used to coalesce multiple calls to recreateAllColshapes, because
-- in some circumstances it is called multiple times in quick succession; with this
-- timer, each call waits with execution for UPDATE_DELAY, unless a next call appears
-- within this time, which will reset the timer; see recreateAllColshapes function
local recreateColshapesDelayTimer = nil

function createColshape(polygon)
    assertArgumentType(polygon, POLYGON_TYPE)

    local vertices = getPolygonVertices(polygon)

    -- print(inspect(polygon), inspect(vertices))

    if not vertices or #vertices < 3 then return false end

    local x, y = getElementProperty(polygon, "position") -- colshape's "center" position
    local coords = {} -- list of colshape's vertices' (x, y) positions

    for index, vertex in ipairs(vertices) do
        local x, y = getElementProperty(vertex, "position")
        coords[index * 2 - 1] = x
        coords[index * 2] = y
    end

    local colshape = createColPolygon(x, y, unpack(coords))

    if not colshape then return false end

    setElementParent(colshape, polygon)

    local chain = {}
    local currentElement = colshape
    while currentElement and currentElement ~= root do
        table.insert(chain, inspect(currentElement))
        currentElement = getElementParent(currentElement)
    end

    outputConsole(table.concat(chain, " -> "))

    return colshape
end

function destroyColshape(polygon)
    assertArgumentType(polygon, POLYGON_TYPE)

    for _, colshape in ipairs(getElementsByType("colshape", polygon)) do
        destroyElement(colshape)
    end
end

local function doRecreateAllColshapes()
    for _, polygon in ipairs(getEditorElementsByType(POLYGON_TYPE)) do
        destroyColshape(polygon)
        if isElementValid(polygon) then
            createColshape(polygon)
        end
    end

    recreateColshapesDelayTimer = nil
end

function recreateAllColshapes()
    -- this function is a proxy for calls to function doRecreateAllColshapes
    if recreateColshapesDelayTimer and isTimer(recreateColshapesDelayTimer) then
        resetTimer(recreateColshapesDelayTimer)
    else
        recreateColshapesDelayTimer = setTimer(doRecreateAllColshapes, UPDATE_DELAY, 1)
    end
end
