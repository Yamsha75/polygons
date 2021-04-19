-- this constant is checked by colshape-creator.lua to determine if it is standalone
LOADER_NAME = "polygon-loader"

-- these delays are used to allow other resources to create colshapes before this loader
local CREATE_POLYGONS_DELAY = 1000 -- ms
local allResourcesDelayTimer = nil -- delay after starting this loader
local resourceDelayTimers = {} -- delay after starting each new resource

-- holds each resource's colshapes created by this loader
local resourceColshapes = {}

local thisResource = getThisResource()

local function destroyResourcePolygons(resource)
    local colshapes = resourceColshapes[resource]
    if not colshapes then return end

    outputDebugString(string.format(
        "%s: destroying %d colshapes for stopping resource:%s", LOADER_NAME, #colshapes,
        getResourceName(resource)))

    for _, colshape in ipairs(colshapes) do
        local polygon = getElementParent(colshape)
        removeElementData(polygon, "polygon-colshape")
        destroyElement(colshape)
    end
    resourceColshapes[resource] = nil
end

local function createResourcePolygons(resource)
    if getResourceState(resource) ~= "running" then return end

    local timer = resourceDelayTimers[resource]
    if timer then
        if isTimer(timer) then killTimer(timer) end
        resourceDelayTimers[resource] = nil
    end

    local colshapes = createColshapesFromResource(resource)
    if colshapes then
        resourceColshapes[resource] = colshapes

        outputDebugString(string.format("%s: created %d colshapes for resource:%s",
            LOADER_NAME, #colshapes, getResourceName(resource)))
    end
end

local function createPolygonsForRunningResources()
    outputDebugString(string.format("%s: creating colshapes for all running resources",
        LOADER_NAME))

    for _, resource in ipairs(getResources()) do
        if resource ~= thisResource then createResourcePolygons(resource) end
    end
end

local function onResourceStartHandler(startingResource)
    if startingResource == thisResource then
        allResourcesDelayTimer = setTimer(createPolygonsForRunningResources,
            CREATE_POLYGONS_DELAY, 1)
    else
        resourceDelayTimers[startingResource] =
            setTimer(createResourcePolygons, CREATE_POLYGONS_DELAY, 1, startingResource)
    end
end
addEventHandler("onResourceStart", root, onResourceStartHandler)

local function onResourceStopHandler(stoppingResource)
    if stoppingResource == thisResource then
        -- kill all timers
        if isTimer(allResourcesDelayTimer) then killTimer(allResourcesDelayTimer) end
        for resource, timer in pairs(resourceDelayTimers) do
            if isTimer(timer) then killTimer(timer) end
        end

        -- destroy all colshapes created by this loader
        for resource, _ in pairs(resourceColshapes) do
            destroyResourcePolygons(resource)
        end
    else
        local timer = resourceDelayTimers[stoppingResource]
        if timer and isTimer(timer) then
            -- stoppingResource didn't have its colshapes created, just kill the timer
            killTimer(timer)
            resourceDelayTimers[stoppingResource] = nil
        else
            -- destroy colshapes created for stoppingResource by this loader
            destroyResourcePolygons(stoppingResource)
        end
    end
end
addEventHandler("onResourceStop", root, onResourceStopHandler)
