-- this constant is checked by colshape-creator.lua to determine if it is standalone
IS_EDF_RESOURCE = true

-- this delay is used to allow other resources create colshapes before this laoder does
local CREATE_POLYGONS_DELAY = 1000 -- ms

local thisResource = getThisResource()

local function wasElementCreatedByThisResource(element)
    while element ~= resourceRoot and element ~= root do
        element = getElementParent(element)
    end

    return element == resourceRoot
end

local function destroyResourcePolygons(resourceRootElement)
    for _, polygon in ipairs(getElementsByType(POLYGON_TYPE, resourceRootElement)) do
        local colshape = getElementData(polygon, "polygon-colshape")
        if colshape and wasElementCreatedByThisResource(colshape) then
            destroyElement(colshape)
        end
    end
end

local function createPolygonsForRunningResources()
    for _, resource in ipairs(getResources()) do
        if resource ~= thisResource and getResourceState(resource) == "running" then
            createResourcePolygonColshapes(getResourceRootElement(resource))
        end
    end
end

local function onResourceStartHandler(startingResource)
    if startingResource == thisResource then
        setTimer(createPolygonsForRunningResources, 1000, 1)
    else
        createResourcePolygonColshapes(source)
    end
end
addEventHandler("onResourceStart", root, onResourceStartHandler)

local function onResourceStopHandler(stoppingResource)
    if stoppingResource == thisResource then
        -- all polygons will be destroyed automatically, because they were created by
        -- thisResource
    else
        destroyResourcePolygons(source)
    end
end
addEventHandler("onResourceStop", root, onResourceStopHandler)
