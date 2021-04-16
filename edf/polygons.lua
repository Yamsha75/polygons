function setFirstVertex(polygon, vertex)
    assertArgumentType(polygon, POLYGON_TYPE, 1)
    if vertex ~= nil then assertArgumentType(vertex, VERTEX_TYPE, 2) end

    return setElementProperty(polygon, "first", vertex)
end

function getFirstVertex(polygon)
    assertArgumentType(polygon, POLYGON_TYPE)

    return getElementProperty(polygon, "first")
end

function setNextVertex(vertex, nextVertex)
    assertArgumentType(vertex, VERTEX_TYPE, 1)
    if nextVertex ~= nil then assertArgumentType(nextVertex, VERTEX_TYPE, 2) end

    return setElementProperty(vertex, "next", nextVertex)
end

function getNextVertex(vertex)
    assertArgumentType(vertex, VERTEX_TYPE)

    return getElementProperty(vertex, "next")
end

function getPolygonVertices(polygon)
    assertArgumentType(polygon, POLYGON_TYPE)

    local firstVertex = getFirstVertex(polygon)
    if not isElementValid(firstVertex) then return false end

    local vertices = {firstVertex} -- list of vertices in order from first to last
    local visited = {[firstVertex] = true} -- used to halt while loop if vertices loop
    local nextVertex = getNextVertex(firstVertex)

    while isElementValid(nextVertex) and not visited[nextVertex] do
        visited[nextVertex] = true
        table.insert(vertices, nextVertex)
        nextVertex = getNextVertex(nextVertex)
    end

    return vertices
end

function getVertexPolygon(theVertex)
    assertArgumentType(theVertex, VERTEX_TYPE)

    local vertices
    for _, polygon in ipairs(getEditorElementsByType(POLYGON_TYPE)) do
        if isElementValid(polygon) then
            vertices = getPolygonVertices(polygon)
            if vertices then
                for _, vertex in ipairs(vertices) do
                    if vertex == theVertex then return polygon end
                end
            end
        end
    end

    return false
end
