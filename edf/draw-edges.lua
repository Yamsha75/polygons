-- BASED ON MTA RACE GAMEMODE EDF BY arc_
------------
-- COLORS --
------------
local SELECTED_COLOR = {getColorFromString("#FE0000EF")}
local DEFAULT_COLOR = {getColorFromString("#1337BEEF")}
local DISCONNECTED_COLOR = {getColorFromString("#000000EF")}
local UPDATE_DELAY = 100 -- ms

-- this timer is used to coalesce multiple calls to updateAllPolygonColors, because
-- in some circumstances it is called multiple times in quick succession; with this
-- timer, each call waits with execution for UPDATE_DELAY, unless a next call appears
-- within this time, which will reset the timer; see updateAllPolygonColors function
local colorUpdateDelayTimer = nil

function updatePolygonColors(polygon, isSelected)
    assertArgumentType(polygon, POLYGON_TYPE, 1)
    if isSelected ~= nil then assertArgumentType(isSelected, "boolean", 2) end

    local color = isSelected and SELECTED_COLOR or DEFAULT_COLOR

    local marker = getEditorRepresentation(polygon, "marker")
    if marker then setMarkerColor(marker, unpack(color)) end

    local vertices = getPolygonVertices(polygon)
    if vertices then
        for _, vertex in ipairs(vertices) do
            local marker = getEditorRepresentation(vertex, "marker")
            if marker then setMarkerColor(marker, unpack(color)) end
        end
    end
end

local function doUpdateAllPolygonColors()
    -- set all vertices color to DISCONNECTED_COLOR
    for _, vertex in ipairs(getElementsByType(VERTEX_TYPE)) do
        local marker = getEditorRepresentation(vertex, "marker")
        if marker then setMarkerColor(marker, unpack(DISCONNECTED_COLOR)) end
    end

    -- update all polygons and their vertices colors to DEFAULT_COLOR
    for _, polygon in ipairs(getElementsByType(POLYGON_TYPE)) do
        if polygon ~= selectedPolygon and isElementValid(polygon) then
            updatePolygonColors(polygon, false)
        end
    end

    -- update selected polygon and its vertices colors to SELECTED_COLOR
    if isElementValid(selectedPolygon) then
        updatePolygonColors(selectedPolygon, true)
    end

    colorUpdateDelayTimer = nil
end

function updateAllPolygonColors()
    -- this function is a proxy for calls to function doUpdateAllPolygonColors
    if colorUpdateDelayTimer and isTimer(colorUpdateDelayTimer) then
        resetTimer(colorUpdateDelayTimer)
    else
        colorUpdateDelayTimer = setTimer(doUpdateAllPolygonColors, UPDATE_DELAY, 1)
    end
end

---------------------
-- PREPARING LINES --
---------------------
local POLYGON_UPDATE_INTERVAL = 125 -- updating polygon and vertex lists interval; ms
local LINE_UPDATES_PER_FRAME = 10 -- number of lines to refresh positions for each frame

local LEFT_DIR = Vector3(0, 0, 1)
local LINE_OFFSET = Vector3(0, 0, 1)

local lineList = {}
local linesCount = 0
local currentLine = 0

local polygons = {}
local polygonsCount = 0
local vertices = {}
local verticesCount = 0

function getValidEditorElementsByType(elementType)
    -- this is a little quicker than getEditorElementsByType + isEditorElement
    -- which is necessary given how frequently this function is called
    local index = 0
    local output = {}

    for _, element in ipairs(getElementsByType(elementType, MAP_CONTAINER)) do
        if not isElementDestroyed(element) then
            index = index + 1
            output[index] = element
        end
    end

    return output, index
end

function updateCompanies()
    polygons, polygonsCount = getValidEditorElementsByType(POLYGON_TYPE)
    vertices, verticesCount = getValidEditorElementsByType(VERTEX_TYPE)

    linesCount = polygonsCount + verticesCount
end
setTimer(updateCompanies, POLYGON_UPDATE_INTERVAL, 0)

function prepareLine(fromElement, toElement)
    local marker = getEditorRepresentation(fromElement, "marker")
    local col = marker and {getMarkerColor(marker)} or DEFAULT_COLOR

    local src = Vector3(edf.edfGetElementPosition(fromElement)) + LINE_OFFSET
    local dst = Vector3(edf.edfGetElementPosition(toElement)) + LINE_OFFSET

    local dir = dst - src
    local len = dir:getLength()
    local mid = src + dir / 2

    dir:normalize()

    local left = dir:cross(LEFT_DIR)

    left.z = 0
    left:normalize()

    local p = dst - dir * 2
    local p1 = p + left
    local p2 = p - left

    return {col = col, src = src, dst = dst, p1 = p1, p2 = p2, mid = mid, len = len}
end

-------------------
-- DRAWING LINES --
-------------------
local LINE_DRAW_DIST = 500

-- drawing lines
function drawConnections()
    while #lineList > linesCount do table.remove(lineList, #lineList) end

    local numberToDo = math.min(linesCount, LINE_UPDATES_PER_FRAME)

    local polygon, vertex, nextVertex
    for _ = 1, numberToDo do
        currentLine = currentLine % linesCount + 1
        lineList[currentLine] = false
        if currentLine <= polygonsCount then
            polygon = polygons[currentLine]
            if isElementValid(polygon) then
                vertex = getFirstVertex(polygon)
                if vertex and not isElementDestroyed(vertex) then
                    lineList[currentLine] = prepareLine(polygon, vertex)
                end
            end
        else
            vertex = vertices[currentLine - polygonsCount]
            if isElementValid(vertex) then
                nextVertex = getNextVertex(vertex)
                if nextVertex and not isElementDestroyed(nextVertex) then
                    lineList[currentLine] = prepareLine(vertex, nextVertex)
                end
            end
        end
    end

    local dist, maxDist, width, color, alpha
    local cam = Vector3(getCameraMatrix())
    for _, line in ipairs(lineList) do
        if line then
            dist = getDistanceBetweenPoints3D(cam, line.mid)
            maxDist = math.max(LINE_DRAW_DIST, line.len / 1.5)
            if dist < maxDist then
                alpha = math.unlerpclamped(maxDist, dist, 300) * 255
                color = tocolor(line.col[1], line.col[2], line.col[3], alpha)

                if dist > 100 then
                    width = 10 + (dist - 100) / 200
                else
                    width = 10
                end

                dxDrawLine3D(line.src, line.dst, color, width, false)
                dxDrawLine3D(line.dst, line.p1, color, width, false)
                dxDrawLine3D(line.dst, line.p2, color, width, false)
            end
        end
    end
end
addEventHandler("onClientHUDRender", root, drawConnections)

-----------
-- MATHS --
-----------
function math.lerp(from, alpha, to)
    return from + (to - from) * alpha
end

function math.unlerp(from, pos, to)
    if (to == from) then return 1 end
    return (pos - from) / (to - from)
end

function math.clamp(low, value, high)
    return math.max(low, math.min(value, high))
end

function math.unlerpclamped(from, pos, to)
    return math.clamp(0, math.unlerp(from, pos, to), 1)
end
