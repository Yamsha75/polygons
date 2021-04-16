local INTERFACES = {"edf", "editor_gui", "editor_main"}

local INTERFACE_MT = {
    __index = function(table, key)
        return function(...)
            return call(table.resource, key, ...)
        end
    end,
}

for _, name in ipairs(INTERFACES) do
    _G[name] = setmetatable({resource = getResourceFromName(name)}, INTERFACE_MT)
end
