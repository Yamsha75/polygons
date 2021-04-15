local function createPolygonColshape(polygon, coords)
    local x, y = getElementPosition(polygon)
    return createColPolygon(x, y, unpack(coords))
end

local function createMapPolygons(resourceRootElement, resourceName)
    local coords
    for _, polygon in ipairs(getElementsByType("polygon", resourceRootElement)) do
        coords = preparePolygonColshape(polygon)
        if coords then
            colshape = createColPolygon(unpack(coords))
            if colshape then

            end
        end
    end
end

local function destroyMapPolygons(resourceRootElement)
    for _, polygon in ipairs(getElementsByType("polygon", resourceRootElement)) do
        destroyElement(polygon)
    end
end

local thisResource = getThisResource()
local function onResourceStartHandler(startingResource)
    if startingResource == thisResource then
        local resourceRootElement
        for _, resource in ipairs(getResources()) do
            if resource ~= thisResource and resource.state == "running" then
                createMapPolygons(resource.rootElement, resource.id)
            end
        end
    else
        createMapPolygons(source, startingResource.id)
    end
end
addEventHandler("onResourceStart", root, onResourceStartHandler)

local function onResourceStopHandler(stoppingResource)
    if stoppingResource ~= thisResource then destroyMapPolygons(source) end
end
addEventHandler("onResourceStop", root, onResourceStopHandler)
