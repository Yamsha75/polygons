local gSpacing = 10 -- padding
local screenW, screenH = guiGetScreenSize()

-- gui sizes, positions and text labels
local gCoords = {}

gCoords.buttonDraw = {}
gCoords.buttonDraw.w = 125
gCoords.buttonDraw.h = 45
gCoords.buttonDraw.x = screenW - (gCoords.buttonDraw.w + gSpacing)
gCoords.buttonDraw.y = screenH - (gCoords.buttonDraw.h + 16)
gCoords.buttonDraw.text = "Draw polygon colshapes"

gCoords.buttonShow = {}
gCoords.buttonShow.w = 125
gCoords.buttonShow.h = 45
gCoords.buttonShow.x = gCoords.buttonDraw.x
gCoords.buttonShow.y = gCoords.buttonDraw.y - (gCoords.buttonShow.h + gSpacing)
gCoords.buttonShow.text = "Export selected polygon"

gCoords.window = {}
gCoords.window.w = math.min(512, screenW - 128)
gCoords.window.h = math.min(512, screenH - 128)
gCoords.window.x = (screenW - gCoords.window.w) / 2
gCoords.window.y = (screenH - gCoords.window.h) / 2
gCoords.window.text = "Polygon exporting"

gCoords.buttonClose = {}
gCoords.buttonClose.w = 70
gCoords.buttonClose.h = 25
gCoords.buttonClose.x = gCoords.window.w - (gCoords.buttonClose.w + gSpacing)
gCoords.buttonClose.y = gCoords.window.h - (gCoords.buttonClose.h + gSpacing)
gCoords.buttonClose.text = "Close"

gCoords.buttonCopy = {}
gCoords.buttonCopy.w = 120
gCoords.buttonCopy.h = 25
gCoords.buttonCopy.x = gCoords.buttonClose.x - (gCoords.buttonCopy.w + gSpacing)
gCoords.buttonCopy.y = gCoords.buttonClose.y
gCoords.buttonCopy.text = "Copy to clipboard"

gCoords.buttonExport = {}
gCoords.buttonExport.w = 70
gCoords.buttonExport.h = 25
gCoords.buttonExport.x = gCoords.buttonCopy.x - (gCoords.buttonExport.w + gSpacing)
gCoords.buttonExport.y = gCoords.buttonCopy.y
gCoords.buttonExport.text = "Refresh"

gCoords.memo = {}
gCoords.memo.w = gCoords.window.w - 2 * gSpacing
gCoords.memo.h = gCoords.window.h - (gSpacing + 20) -
                     (gCoords.buttonClose.h + 2 * gSpacing)
gCoords.memo.x = gSpacing
gCoords.memo.y = gSpacing + 20 -- 20 pixels to give space to window title bar
gCoords.memo.text = ""

gCoords.radioPairs = {}
gCoords.radioPairs.w = 45
gCoords.radioPairs.h = 25
gCoords.radioPairs.x = gSpacing
gCoords.radioPairs.y = gCoords.buttonClose.y
gCoords.radioPairs.text = "Pairs"

gCoords.radioVectors = {}
gCoords.radioVectors.w = 60
gCoords.radioVectors.h = 25
gCoords.radioVectors.x = (gCoords.radioPairs.x + gCoords.radioPairs.w) + gSpacing
gCoords.radioVectors.y = gCoords.buttonClose.y
gCoords.radioVectors.text = "Vectors"

gCoords.radioCompact = {}
gCoords.radioCompact.w = 70
gCoords.radioCompact.h = 25
gCoords.radioCompact.x = (gCoords.radioVectors.x + gCoords.radioVectors.w) + gSpacing
gCoords.radioCompact.y = gCoords.buttonClose.y
gCoords.radioCompact.text = "Compact"

-- gui elements
local gui = {}
local guiRadios = {}

local function createGUI()
    gc = gCoords.buttonDraw
    gui.buttonDraw = guiCreateButton(gc.x, gc.y, gc.w, gc.h, gc.text, false)
    addEventHandler("onClientGUIClick", gui.buttonDraw, buttonDrawClickHandler, false)

    gc = gCoords.buttonShow
    gui.buttonShow = guiCreateButton(gc.x, gc.y, gc.w, gc.h, gc.text, false)
    addEventHandler("onClientGUIClick", gui.buttonShow, buttonShowClickHandler, false)

    gc = gCoords.window
    gui.window = guiCreateWindow(gc.x, gc.y, gc.w, gc.h, gc.text, false)
    guiWindowSetSizable(gui.window, false)
    guiSetVisible(gui.window, false)

    gc = gCoords.buttonClose
    gui.buttonClose =
        guiCreateButton(gc.x, gc.y, gc.w, gc.h, gc.text, false, gui.window)
    addEventHandler("onClientGUIClick", gui.buttonClose, buttonCloseClickHandler, false)

    gc = gCoords.buttonCopy
    gui.buttonCopy = guiCreateButton(gc.x, gc.y, gc.w, gc.h, gc.text, false, gui.window)
    addEventHandler("onClientGUIClick", gui.buttonCopy, buttonCopyClickHandler, false)

    gc = gCoords.buttonExport
    gui.buttonExport = guiCreateButton(gc.x, gc.y, gc.w, gc.h, gc.text, false,
        gui.window)
    addEventHandler("onClientGUIClick", gui.buttonExport, exportPolygon, false)

    gc = gCoords.memo
    gui.memo = guiCreateMemo(gc.x, gc.y, gc.w, gc.h, gc.text, false, gui.window)
    guiMemoSetReadOnly(gui.memo, true)

    gc = gCoords.radioPairs
    gui.radioPairs = guiCreateRadioButton(gc.x, gc.y, gc.w, gc.h, gc.text, false,
        gui.window)
    guiRadioButtonSetSelected(gui.radioPairs, true) -- default choice
    addEventHandler("onClientGUIClick", gui.radioPairs, exportPolygon, false)

    gc = gCoords.radioVectors
    gui.radioVectors = guiCreateRadioButton(gc.x, gc.y, gc.w, gc.h, gc.text, false,
        gui.window)
    addEventHandler("onClientGUIClick", gui.radioVectors, exportPolygon, false)

    gc = gCoords.radioCompact
    gui.radioCompact = guiCreateRadioButton(gc.x, gc.y, gc.w, gc.h, gc.text, false,
        gui.window)
    addEventHandler("onClientGUIClick", gui.radioCompact, exportPolygon, false)

    guiRadios = {gui.radioPairs, gui.radioVectors, gui.radioCompact}
end
addEventHandler("onClientEDFStart", root, createGUI)

local function destroyGUI()
    for key, value in pairs(gui) do
        if isElement(value) then destroyElement(value) end
    end

    gui = {}
    guiRadios = {}

    showCol(false)
    setDevelopmentMode(false)
end
addEventHandler("onClientEDFStop", root, destroyGUI)

-- gui utility functions
function getRadioChoice()
    for _, radio in ipairs(guiRadios) do
        if guiRadioButtonGetSelected(radio) then return radio end
    end

    return false
end

function exportPolygon()
    if not selectedPolygon then
        showInfo("You must have a polygon selected (red)!", 255, 0, 0)
        return false
    end

    local colX, colY, _ = edf.edfGetElementPosition(selectedPolygon)
    local vertices = getPolygonVertices(selectedPolygon)
    if not vertices then
        showInfo("Selected polygon must have at least 3 vertices!", 255, 0, 0)
        return false
    end

    local choice = getRadioChoice()

    local format, coordsFormat, concatSep
    if choice == gui.radioPairs then
        format = "local colPosX, colPosY = %.3f, %.3f\n" ..
                     "local coords = {\n    %s\n}\n" ..
                     "local myColshape = createColPolygon(colPosX, colPosY, unpack(coords))\n"
        coordsFormat = "%.3f, %.3f"
        concatSep = ",\n    "
    elseif choice == gui.radioVectors then
        format = "local colshapePos = Vector2(%.3f, %.3f)\n" ..
                     "local coords = {\n    %s\n}\n" ..
                     "local myColshape = createColPolygon(colshapePos, unpack(coords))\n"
        coordsFormat = "Vector2(%.3f, %.3f)"
        concatSep = ",\n    "
    elseif choice == gui.radioCompact then
        format = "local myColshape = createColPolygon(%.3f, %.3f, %s)\n"
        coordsFormat = "%.3f, %.3f"
        concatSep = ", "
    end

    local coords = {}
    for index, vertex in ipairs(vertices) do
        local x, y, _ = edf.edfGetElementPosition(vertex)
        coords[index] = string.format(coordsFormat, x, y)
    end

    local text = string.format(format, colX, colY, table.concat(coords, concatSep)) ..
                     string.format("setElementID(myColshape, \"%s\")\n",
            getElementID(selectedPolygon))

    guiSetText(gui.memo, text)

    return true
end

-- gui event handlers
function buttonDrawClickHandler()
    local enabled = not getDevelopmentMode()

    setDevelopmentMode(enabled)
    showCol(enabled)

    message = "showing colshapes is now " .. (enabled and "enabled" or "disabled")
    showInfo(message)
end

function buttonShowClickHandler()
    if exportPolygon() then guiSetVisible(gui.window, true) end
end

function buttonCopyClickHandler()
    setClipboard(guiGetText(gui.memo))
    showInfo("Polygon export copied to clipboard")
end

function buttonCloseClickHandler()
    guiSetVisible(gui.window, false)
end
