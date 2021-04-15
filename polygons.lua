local function getFirstVertex(polygon)
    return getElementProperty(polygon, "first", "vertex")
end

local function getNextVertex(vertex)
    return getElementProperty(vertex, "next", "vertex")
end

local function getPolygonVertices(polygon)
    local firstVertex = getFirstVertex(polygon)
    if not firstVertex then return {} end

    local vertices = {firstVertex} -- list of vertices in order from first to last
    local visited = {[firstVertex] = true} -- used to stop while loop from running forever
    local nextVertex = getNextVertex(firstVertex)

    while nextVertex and not visited[nextVertex] do
        visited[nextVertex] = true
        table.insert(vertices, nextVertex)
        nextVertex = getNextVertex(nextVertex)
    end

    return vertices
end

function createPolygonColshape(polygon)
    local vertices = getPolygonVertices(polygon)

    if not vertices or #vertices < 3 then return end

    local x, y = getElementPosition(polygon)
    local colshapePosition = Vector2(x, y) -- colshape's "center" position
    local coords = {} -- colshape's vertices' (x, y) positions
    for index, vertex in ipairs(vertices) do
        x, y = getElementPosition(vertex)
        coords[index] = Vector2(x, y)
    end

    local colshape = createColPolygon(colshapePosition, unpack(coords))
    if not colshape then return end

    setElementParent(colshape, polygon)
end
