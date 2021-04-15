-- constants
local POLYGON_UPDATE_INTERVAL = 125
local LINE_UPDATES_PER_FRAME = 10

-- colors
local SELECTED_COLOR = {getColorFromString("#FE0000EF")}
local DEFAULT_COLOR = {getColorFromString("#1337BEEF")}
local DISCONNECTED_COLOR = {getColorFromString("#000000EF")}

function updatePolygonColors(polygon, isSelected)
    local color
    if isSelected then
        color = SELECTED_COLOR
    else
        color = DEFAULT_COLOR
    end

    local marker = getEditorRepresentation(polygon, "marker")
    if marker then setMarkerColor(marker, unpack(color)) end

    for _, vertex in ipairs(getPolygonVertices(polygon)) do
        marker = getEditorRepresentation(vertex, "marker")
        if marker then setMarkerColor(marker, unpack(color)) end
    end
end

local refreshTimer = nil

function doUpdateAllPolygonColors()
    local marker
    for _, vertex in ipairs(getElementsByType("vertex")) do
        marker = getEditorRepresentation(vertex, "marker")
        if marker then setMarkerColor(marker, unpack(DISCONNECTED_COLOR)) end
    end

    for _, polygon in ipairs(getElementsByType("polygon")) do
        if polygon ~= selectedPolygon and isElementValid(polygon) then
            updatePolygonColors(polygon, false)
        end
    end
    if isElementValid(selectedPolygon) then
        updatePolygonColors(selectedPolygon, true)
    end
end

function updateAllPolygonColors()
    if refreshTimer and isTimer(refreshTimer) then killTimer(refreshTimer) end
    refreshTimer = setTimer(doUpdateAllPolygonColors, 100, 1)
end

-- preparing lines
local leftDir = Vector3(0, 0, 1)
local posOffset = Vector3(0, 0, 1)

local lineList = {}
local linesCount = 0
local currentLine = 0

function prepareLine(fromElement, toElement)
    local marker = getEditorRepresentation(fromElement, "marker")
    if marker then
        col = {getMarkerColor(marker)}
    else
        col = DEFAULT_COLOR
    end

    local src = Vector3(edf.edfGetElementPosition(fromElement)) + posOffset
    local dst = Vector3(edf.edfGetElementPosition(toElement)) + posOffset

    local dir = dst - src
    local len = dir:getLength()
    local mid = src + dir / 2

    dir:normalize()

    local left = dir:cross(leftDir)

    left.z = 0
    left:normalize()

    local p = dst - dir * 2
    local p1 = p + left
    local p2 = p - left

    return {col = col, src = src, dst = dst, p1 = p1, p2 = p2, mid = mid, len = len}
end

-- updating companies and vertices lists
local polygons = {}
local polygonsCount = 0
local vertices = {}
local verticesCount = 0

function filterEditorElements(list)
    local outList = {}
    for _, element in ipairs(list) do
        if isElementValid(element) then table.insert(outList, element) end
    end

    return outList
end

function updateCompanies()
    polygons = filterEditorElements(getElementsByType("polygon"))
    polygonsCount = #polygons

    vertices = filterEditorElements(getElementsByType("vertex"))
    verticesCount = #vertices

    linesCount = polygonsCount + verticesCount
end
setTimer(updateCompanies, POLYGON_UPDATE_INTERVAL, 0)

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
                if vertex then
                    lineList[currentLine] = prepareLine(polygon, vertex)
                end
            end
        else
            vertex = vertices[currentLine - polygonsCount]
            if isElementValid(vertex) then
                nextVertex = getNextVertex(vertex)
                if nextVertex then
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
            maxDist = math.max(500, line.len / 1.5)
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

-- maths
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
