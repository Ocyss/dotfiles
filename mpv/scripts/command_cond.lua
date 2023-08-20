-- command_cond
-- Inspired by input-event(https://github.com/natural-harmonia-gropius/input-event), and using a lot of its code.

local utils = require("mp.utils")
local options = require("mp.options")
local msg = require("mp.msg")
local next = next

local cond_map = {}
local o = {
    configs = "~~/input.conf",
}

function table:isEmpty()
    if next(self) == nil then
        return true
    else
        return false
    end
end

function table:push(element)
    self[#self + 1] = element
    return self
end

function table:filter(filter)
    local nt = {}
    for index, value in ipairs(self) do
        if (filter(index, value)) then
            nt = table.push(nt, value)
        end
    end
    return nt
end

function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end

function string:replace(pattern, replacement)
    local result, n = self:gsub(pattern, replacement)
    return result
end

function string:split(separator)
    local fields = {}
    local separator = separator or ":"
    local pattern = string.format("([^%s]+)", separator)
    local copy = self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

local function command(command)
    local expand = mp.command_native({ 'expand-text', command })
    return mp.command(expand)
end

-- https://github.com/mpv-player/mpv/blob/master/player/lua/auto_profiles.lua
local watched_properties = {}       -- indexed by property name (used as a set)
local cached_properties = {}        -- property name -> last known raw value
-- Cached set of all top-level mpv properities. Only used for extra validation.
local property_set = {}
for _, property in pairs(mp.get_property_native("property-list")) do
    property_set[property] = true
end
local function on_property_change(name, val)
    cached_properties[name] = val
end

local function magic_get(name)
    -- Lua identifiers can't contain "-", so in order to match with mpv
    -- property conventions, replace "_" to "-"
    name = string.gsub(name, "_", "-")
    if not watched_properties[name] then
        watched_properties[name] = true
        local res, err = mp.get_property_native(name)
        -- Property has to not exist and the toplevel of property in the name must also
        -- not have an existing match in the property set for this to be considered an error.
        -- This allows things like user-data/test to still work.
        if err == "property not found" and property_set[name:match("^([^/]+)")] == nil then
            msg.error("Property '" .. name .. "' was not found.")
            return default
        end
        cached_properties[name] = res
        mp.observe_property(name, "native", on_property_change)
    end
    return cached_properties[name]
end

local evil_magic = {}
setmetatable(evil_magic, {
    __index = function(table, key)
        -- interpret everything as property, unless it already exists as
        -- a non-nil global value
        local v = _G[key]
        if type(v) ~= "nil" then
            return v
        end
        return magic_get(key)
    end,
})

p = {}
setmetatable(p, {
    __index = function(table, key)
        return magic_get(key)
    end,
})

local function compile_cond(name, s)
    local code, chunkname = "return " .. s, "Event " .. name .. " condition"
    local chunk, err
    if setfenv then -- lua 5.1
        chunk, err = loadstring(code, chunkname)
        if chunk then
            setfenv(chunk, evil_magic)
        end
    else -- lua 5.2
        chunk, err = load(code, chunkname, "t", evil_magic)
    end
    if not chunk then
        msg.error("Event '" .. name .. "' condition: " .. err)
        chunk = function() return false end
    end
    return chunk
end

local function evaluate(key)
    msg.verbose("Evaluating bind_name: " .. key)
    local seleted = nil
    local actions = cond_map[key]
    if not actions or table.isEmpty(actions) then return end
    for _, action in ipairs(actions) do
        msg.verbose("Evaluating comand: " .. action.cmd)
        if type(action.cond) ~= "function" then
            seleted = action.cmd
            break
        else
            local status, res = pcall(action.cond)
            if not status then
                -- errors can be "normal", e.g. in case properties are unavailable
                msg.verbose("Action condition error on evaluating: " .. res)
                res = false
            end
            res = not not res
            if res then
                seleted = action.cmd
                break
            end
        end
    end

    return seleted
end

local function addItem(key, cmd, cond)
    if cond_map[key] == nil then
        cond_map[key] = {}
    end
    local index = table.isEmpty(cond_map[key]) and 1 or #cond_map[key]+1
    local cond_name = string.format("%s_%d", key, index)
    table.insert(cond_map[key], {
        cmd = cmd, 
        cond = cond ~= nil and compile_cond(cond_name, cond) or nil
    })
end

function handler(key)
    local seleted = evaluate(key)
    if seleted == nil then
        msg.error(string.format("There are no commands associated with the '%s' that satisfy the condition", key))
        return
    end
    return command(seleted)
end

local function bind_from_conf(conf)
    local path = mp.command_native({ "expand-path", conf })
    local meta, meta_error = utils.file_info(path)
    if not meta or not meta.is_file then
        msg.error(path .. " is not a file.")
        return
    end

    for line in io.lines(path) do
        line = line:trim()
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local key, cmd, comment = line:match("%s*([%S]+)%s+(.-)%s+#%s*(.-)%s*$")
            if comment then
                local comments = comment:split("#")
                local statements = table.filter(comments, function(i, v) return v:match("^|") end)
                if statements and #statements > 0 then
                    local cond = statements[1]:match("^|(.*)"):trim()
                    if cond then
                        if cond == "" then cond = nil end
                        addItem(key, cmd, cond)
                    end
                end
            end
        end
    end
end

local function bind_from_options_configs()
    for index, value in ipairs(o.configs:split(",")) do
        local path = value:trim()
        bind_from_conf(path)
    end
    for key,_ in pairs(cond_map) do
        mp.register_script_message(key, function() handler(key) end)
    end
end

options.read_options(o, _)

bind_from_options_configs()

-- cond_map{
--     key: {
--         {cmd = "",cond = function},
--         ...
--     },
--     ...
-- }
