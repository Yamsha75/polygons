# What is it
This resource provides an easy way to create colShape polygons using built-in editor. It consists of two things:
- EDF, which does the work in editor
- a loader, which creates actual colShape elements in your server

It works well with Editor's undo/redo function, and supports multiple players, so you can work with friends on your fancy colshapes!

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
3. Go to Map Definitions (this icon: ![definitions](https://user-images.githubusercontent.com/5197581/115040528-d131fe00-9ed1-11eb-8cd4-7c58f20aba54.png))
4. Double-click `polygons` from the list on the left and confirm by clicking OK button (skip this step if map already has this definition enabled)
5. Use mouse scroll until you can see these icons in bottom left corner: ![icons](https://user-images.githubusercontent.com/5197581/115040775-0e968b80-9ed2-11eb-8979-02558d71f255.png)
6. Choose `Polygon center` - this is the starting element of each polygon - and place it where the middle of your polygon will be
7. Choose `Polygon vertex` - this is what defines the shape of each polygon - and place a few (at least 3) around the center. Holding CTRL when placing each vertex will enable you to place many in quick succession
8. Use this command to see your colShapes: `/showpoly`
9. If necessary, modify the polygon, moving center element, vertices or adding more vertices
10. Add more polygons if necessary
11. Save map
12. Done!


### Tips for using in editor
![colors](https://user-images.githubusercontent.com/5197581/115051303-f6783980-9edc-11eb-9402-d98ff92fd54f.png)

- Connections between vertices are drawn as directed arrows
- Colors of marker representations and arrows allow disgtinguishing selected polygons (red) from others (blue) and vertices without `polygon-center` (black)
- Last selected colShape (red) is saved for each player, and every new vertex created by a player will be attached to the last vertex of that player's selected colShape.
- When placing a vertex, hold `LCTRL` to immediately create a new one attached to it. You can easily place multiple vertices this way (shown in video above).
- When creating a new vertex, while having another vertex selected (with red bounding box around it), the new vertex will be inserted after the selected and before selected's next vertex (if it exists).
- You can create loops with vertices, but they are not necessary. The last edge is always there, even if the arrow is not drawn. Use `/showpoly` to see for yourself! If you don't see a yellow colShape outline, remember that every polygon requires a `polygon-center` element and at least 3 vertices!
- Rule of thumb for verifying colShapes, if the colShape (yellow outline with infinite height) is seen, it will be correctly recreated in the server.
- If you destroy a vertex, its previous vertex may have it's "next" property set to that destroyed vertex. This will produce a warning when creating colShapes in server to let you know something is wrong, but it can be easily fixed by simply loading the map in Editor and saving it again. Non-existing pointers to next vertices will be removed! 
## How to use it in server
There are two ways of using created polygons in your server or gamemode. They can even be mixed without any issues! The loader from "The easy way" is smart enough to not duplicate colShapes created by the standalone scripts in maps!

### The easy way:
Using this resource as the loader:

1. Start your map
2. Start this resource
3. Start more maps if necessary, this resource will create colShapes dynamically on each map load!
4. Done!

**NOTE:** as these colshapes' parent resource will be `polygons` (this resource), stopping it will destroy all colshapes created by it. Make sure to always start this resource on your server when using this method!

### Using standalone script:
Using a script from this file in your own map:

1. Copy `colshape-creator.lua` from this resource into your map resource
2. In your map's meta.xml file add:
    ```xml
    <script src="colshape-creator.lua" type="server" />
    ```
3. Start (or restart) your map
4. Done!

## How to use it in scripts
After colShapes are created from maps, you can retrieve the created colShapes in your scripts in a couple of ways. Option 1. requires using standalone script, options 2-4. can be used with the loader

1. If you used standalone script, you can simply use `COLSHAPES` variable in a resource with a map (or more maps). This variable is a table (list) of all colShapes created from polygons in that resource
    ```lua
    -- from the same resource:
    myColshapes = COLSHAPES
    ```

2. The easy way, which requires that the `polygon-center` element's ID is unique across all started maps
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
-- all polygons from a single resource
mapRootElement = getResourceRootElement(getResourceFromName("my-resource"))
mapPolygons = getElementsByType("polygon-center", mapRootElement))
```

3. Using element data, which requires that the polygon's element data at key "polygon-colshape" is not modified by any script:
    ```lua
    myColshape = getElementData(myPolygon, "polygon-colshape")
    ```

4. Using the element tree, which requires that the user doesn't modify colshape's parent or add more colshape elements below myPolygon in the element tree:
    ```lua
    -- this method assumes the user doesn't add more colshapes as myPolygon's children
    myColshape = getElementsByType("colshape", myPolygon)[1]
    ```
# Exporting polygons as Lua code
## *Coming Soon! (probably)*
Exported code will look like this:
```lua
createColPolygon(x, y, 1, 1, 3, 5, 9, 17, ...)
```
# EDF elements explained
Each abstract polygon, which defines the shape of the actual colShape polygon element, consists of one `polygon-center` element and at least three `polygon-vertex` elements.

- `polygon-center` defines the center position of the resulting colShape. It's property
named "first" points to the first `polygon-vertex` element defining the polygon's shape
- `polygon-vertex` defines each vertex (corner) of the resulting colShape. It's property
named "next" points to the next `polygon-vertex` element in that polygon's vertices list.

Together they define an abstract 'polygon', which is used to create the actual colShape.

# Known issues
The Editor plugin and loader script don't check if any vertex belongs to multiple `polygon-center` elements. This can result in "joined" colShapes. Please make sure to inspect your polygons before saving the map.
As Editor's undo/redo is global for the server, one player performing an undo can break other players' polygons. Please be careful with it when working with your friends



# Sources
Line drawing in editor based on MTA Race gamemode EDF by arc_:
https://github.com/multitheftauto/mtasa-resources

EDF element icons: https://materialdesignicons.com/
