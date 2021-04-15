function setFirstVertex(polygon, vertex)
    assertType(polygon, "polygon", 1)
    if vertex then assertType(vertex, "vertex", 2) end

    return setElementProperty(polygon, "first", vertex)
end

function getFirstVertex(polygon)
    assertType(polygon, "polygon")

    return getElementProperty(polygon, "first")
end

function setNextVertex(vertex, nextVertex)
    assertType(vertex, "vertex", 1)
    if nextVertex then assertType(nextVertex, "vertex", 2) end

    return setElementProperty(vertex, "next", nextVertex)
end

function getNextVertex(vertex)
    assertType(vertex, "vertex")

    return getElementProperty(vertex, "next")
end

function getPolygonVertices(polygon)
    assertType(polygon, "polygon")

    local firstVertex = getFirstVertex(polygon)
    if not isElementValid(firstVertex) then return false end

    local vertices = {firstVertex} -- list of vertices in order from first to last
    local visited = {[firstVertex] = true} -- used to stop loop from running forever
    local nextVertex = getNextVertex(firstVertex)

    while isElementValid(nextVertex) and not visited[nextVertex] do
        visited[nextVertex] = true
        table.insert(vertices, nextVertex)
        nextVertex = getNextVertex(nextVertex)
    end

    return vertices
end

function getVertexPolygon(theVertex)
    assertType(theVertex, "vertex")

    local vertices
    for _, polygon in ipairs(getEditorElementsByType("polygon")) do
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
