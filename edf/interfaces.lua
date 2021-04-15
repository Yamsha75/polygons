local interfaces = {"edf", "editor_gui", "editor_main"}

local interface_mt = {
    __index = function(table, key)
        return function(...)
            return call(table.resource, key, ...)
        end
    end,
}

function import(name)
    _G[name] = setmetatable({resource = getResourceFromName(name)}, interface_mt)
end

for _, name in ipairs(interfaces) do import(name) end
