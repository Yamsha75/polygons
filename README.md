# Polygons
This resource provides an easy way to create colShape polygons using built-in editor. It
consists of two things:
- EDF, which does the work in editor
- a loader, which creates actual colShape elements in your server

It works well with Editor's undo/redo function, and supports multiple players, so you
can work with friends on your fancy colshapes!
# Example of using it in editor
https://user-images.githubusercontent.com/5197581/115022024-17309700-9ebd-11eb-9464-1ee0b7008fd4.mp4
# Getting started
## How to install it
1. Download the latest release from [releases](https://github.com/Yamsha75/polygons/releases)
2. Add the .zip file to your server resources, found in your MTA installation folder, for example:

    `C:\MTA San Andreas 1.5\server\mods\deathmatch\resources`
3. Done!
## How to use it in editor
1. Launch MTA and choose MAP EDITOR
2. Load an existing map or start a new map
3. Go to Map Definitions (this icon:
![definitions](https://user-images.githubusercontent.com/5197581/115040528-d131fe00-9ed1-11eb-8cd4-7c58f20aba54.png))
4. Double-click `polygons` from the list on the left and confirm by clicking OK button
(skip this step if map already has this definition enabled)
5. Use mouse scroll until you can see these icons in bottom left corner:
![icons](https://user-images.githubusercontent.com/5197581/115040775-0e968b80-9ed2-11eb-8979-02558d71f255.png)
6. Choose `Polygon center` - this is the starting element of each polygon - and place it
where the middle of your polygon will be
7. Choose `Polygon vertex` - this is what defines the shape of each polygon - and place
a few (at least 3) around the center. Holding CTRL when placing each vertex will enable
you to place many in quick succession
8. To see created colshapes shaped by vertices, click the `Draw polygon colshapes`
button in bottom right corner.
9. If necessary, modify the polygon, moving center element, vertices or adding more
vertices
10. Add more polygons if necessary
11. There are two ways to use created polygons:
    - export selected polygon as Lua code, by clicking the `Export selected polygon`
    button in bottom right corner, and use it however you desire!
    - save the map, and use it directly on your server; actual colshapes will be created
    by the provided manager or loader! More on that in "How to use it in server" section.
12. Done!
### Tips for using in editor
![colors](https://user-images.githubusercontent.com/5197581/115051303-f6783980-9edc-11eb-9402-d98ff92fd54f.png)

- Connections between vertices are drawn as directed arrows, as shown above
- Colors of marker representations and arrows allow disgtinguishing selected polygons
(red) from others (blue) and vertices without `polygon-center` (black), as shown above
- Last selected colShape (red) is saved for each player, and every new vertex created by
a player will be attached to the last vertex of that player's selected colShape.
- When placing a vertex, hold `LCTRL` to immediately create a new one attached to it.
You can easily place multiple vertices this way (shown in video above). The same applies
to copying existing connected vertices.
- When creating a new vertex, while having another vertex selected (with red bounding
box around it), the new vertex will be inserted after the selected and before selected's
next vertex (if it exists).
- You can create loops with vertices, but they are not necessary. The last edge is
always there, even if the arrow is not drawn. Click the `Draw polygon colshapes` button
in bottom right corner to see for yourself! If you don't see a yellow colShape outline,
remember that every polygon requires a `polygon-center` element and at least 3 vertices!
- Rule of thumb for verifying colShapes: if the colShape (yellow outline with infinite
height) is seen, it will be correctly exported or recreated by the manager or loader in
the server.
- If you destroy a vertex, its previous vertex may have its "next" property set to that
destroyed vertex and while loader will correctly recreate this colshape, it will produce
a warning. It can be easily fixed by simply loading the map in Editor and saving it
again. Non-existing pointers to next vertices will be removed! This is an unfortunate
side effect of working with undo/redo and it doesn't affect exported colshapes.
# How to use it in server
There are three ways of using created polygons in your server or gamemode. They can even
be mixed without any issues! Here are explanations and below you can see steps how to
use each of them:
1. Exporting polygon as Lua code straight from Map Editor - selected polygon (red) can
be easily exported as Lua code with `createColPolygon` function and used in your scripts
in any way you like, but if you need to modify it afterwards, it must be done by hand
(unless you also save the map for later use)
2. Using the manager - this resource can be started on your server and it will create
colShapes for every polygon in every map started before and after starting this resource.
It will even destroy the corresponding colShapes on map resource stop. The drawback is
that the parent resource that "owns" the colShape elements will be this resource, which
means it must be running alongside your maps, otherwise the colShapes will not be
recreated.
3. Using the loader - it does the same job but only for its own map (or set of maps) in
its resource. This loader can be used alongside the manager and they won't collide or
duplicate colShapes!
## 1. Exporting as Lua code
Using polygons exported as lua code:

1. While editing the map, simply select your polygon and click the `Export selected
polygon` button in bottom right corner
2. Choose your code flavour - "Pairs", "Vectors" or "Compact"
3. Click `Copy to clipboard`
4. Paste it in your scripts
5. Done!
## 2. Using the manager
Using this resource as the manager:

1. Create and save your map
2. Start your map and this resource on your server - order doesn't matter
3. Start more maps if necessary, this resource will create colShapes dynamically for
each map on map load
4. Done!

**NOTE:** as these colshapes' parent resource will be `polygons` (this resource),
stopping it will destroy all colshapes created by it. Make sure to always start this
resource on your server when using this method!
## 3. Using the loader
Using a script from this file in your own map:

1. Create and save your map
2. Copy `loader.lua` from this resource into your map resource
2. In your map resource's meta.xml file add:
    ```xml
    <script src="loader.lua" type="server" />
    ```
3. Start (or restart) your map on your server
4. Done!
# How to use it in scripts
This sections does not apply to exported colShapes, as they are created directly in
scripts.

After colShapes are created from maps by the manager or loader, you can retrieve the
created colShapes in your scripts in a couple of ways. Option 1. requires the loader,
options 2-4. can be used with the manager or the loader

1. If you use the loader, you can simply use `COLSHAPES` variable in the resource with
the map (or more maps). This variable is a table (list) of all colShapes created from
polygons in that resource
    ```lua
    -- from the same resource as the loader:
    myColshapes = COLSHAPES
    ```
2. You can easily retrive the created colShape by using its `polygon-center` element's
ID, provided it is unique across all started maps
    ```lua
    -- uses elementID of the "polygon-center" from the map, adding " colshape" after it
    -- for elementID "my-polygon", it would be:
    myColshape = getElementData("my-polygon colshape")
    ```

Next options require retrieving the `polygon-center` element first, for example:
```lua
-- single chosen polygon (make sure its ID is unique across all maps!)
myPolygon = getElementByID("my-polygon")
-- all polygons from every map and resource
polygons = getElementsByType("polygon-center")
-- all polygons from a single resource (for loader only)
mapRootElement = getResourceRootElement(getResourceFromName("my-resource"))
mapPolygons = getElementsByType("polygon-center", mapRootElement))
```
3. Using element data, which requires that the polygon's element data at key
"polygon-colshape" is not modified by any script:
    ```lua
    myColshape = getElementData(myPolygon, "polygon-colshape")
    ```
4. Using the element tree, which requires that the user doesn't modify colshape's parent
or add more colshape elements below myPolygon in the element tree:
    ```lua
    -- this method assumes the user doesn't add more colshapes as myPolygon's children
    myColshape = getElementsByType("colshape", myPolygon)[1]
    ```
# More on exporting polygons as Lua code
After choosing a valid `polygon-center` (with at least 3 vertices) you can press the
`Export selected polygon` button in bottom right corner to export the code that will
create the colShape based on the shape of the selected polygon. You can click `Copy to
clipboard` button to quickly copy the exported code and then paste it in your script.
There are three flavors of the exported code. Choose the one that best suits your
personal preferences and needs. Examples can be seen below:
```lua
-- Pairs
local colPosX, colPosY = 2504.800, -1664.500
local coords = {
    2506.400, -1675.500,
    2493.900, -1675.000,
    2491.700, -1658.200,
    2511.601, -1660.400
}
local myColshape = createColPolygon(colPosX, colPosY, unpack(coords))
setElementID(myColshape, "polygon-center (1)")
```
```lua
-- Vectors
local colshapePos = Vector2(2504.800, -1664.500)
local coords = {
    Vector2(2506.400, -1675.500),
    Vector2(2493.900, -1675.000),
    Vector2(2491.700, -1658.200),
    Vector2(2511.601, -1660.400)
}
local myColshape = createColPolygon(colshapePos, unpack(coords))
setElementID(myColshape, "polygon-center (1)")
```
```lua
-- Compact
local myColshape = createColPolygon(2504.800, -1664.500, 2506.400, -1675.500, 2493.900, -1675.000, 2491.700, -1658.200, 2511.601, -1660.400)
setElementID(myColshape, "polygon-center (1)")
```
**NOTE**: using `CTRL+C` while having an element selected will create a copy of that
element, because pressing `C` in editor clones the selected element. It can be avoided
by dropping the selected element or using the `Copy to clipboard` button 
# EDF elements explained
Each abstract polygon, which defines the shape of the actual colShape polygon element,
consists of one `polygon-center` element and at least three `polygon-vertex` elements.

- `polygon-center` defines the center position of the resulting colShape. Its property
named "first" points to the first `polygon-vertex` element defining the polygon's shape
- `polygon-vertex` defines each vertex (corner) of the resulting colShape. Its property
named "next" points to the next `polygon-vertex` element in that polygon's vertices list.

Together they define an abstract 'polygon', which is used to create the actual colShape.
# Known issues
- The Editor plugin and loader script don't check if any vertex belongs to multiple
`polygon-center` elements. This can result in "joined" colShapes. Please make sure to
inspect your polygons before saving the map.
- As Editor's undo/redo is global for the server, one player performing an undo can break
other players' polygons. Please be careful with it when working with your friends
# Sources
Line drawing in editor based on MTA Race gamemode EDF by arc_:
https://github.com/multitheftauto/mtasa-resources

EDF element icons: https://materialdesignicons.com/
