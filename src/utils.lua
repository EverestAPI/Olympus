require("love.filesystem")
local requestStatus, request = pcall(require, "luajit-request")
local dkjson = require("dkjson")
local tinyyaml = require("tinyyaml")
local fs = require("fs")
local threader = require("threader")
local xml2lua = require("xml2lua")
local xml2luaTree = require("xmlhandler.tree")
local loveSystemAsync = threader.wrap("love.system")

local utils = {}

local uiu = require("ui.utils")
for k, v in pairs(uiu) do
    utils[k] = v
end

function utils.important(size, check)
    return function(el)
        local uie = require("ui.elements")
        local config = require("config")
        if el.style:get("spacing") ~= nil then
            el.style.spacing = 0
        end
        el:addChild(uie.image("important"):with({
            scale = size / 256
        }):hook({
            update = function(orig, self)
                orig(self)
                if uiu.isCallback(check) then
                    self.visible = check()
                end
            end,
            calcSize = function(orig, self)
                self.width = 0
                self.height = 0
            end,
            layoutLate = function(orig, self)
                orig(self)
                self.realX = -8
                self.realY = -8
            end
        }):as("important"))
    end
end

function utils.concat(...)
    local all = {}
    local tables = {...}
    for i = 1, #tables do
        local t = tables[i]
        for j = 1, #t do
            all[#all + 1] = t[j]
        end
    end
    return all
end

function utils.openURL(path)
    require("notify")("Opening " .. path)
    return loveSystemAsync.openURL(path)
end

function utils.openFile(path)
    require("notify")("Opening " .. path)
    return loveSystemAsync.openURL("file://" .. fs.fslash(path))
end

function utils.load(path)
    return love.filesystem.read(path)
end

function utils.download(url, headers)
    if not requestStatus then
        return false, "luajit-request not loaded: " .. tostring(request)
    end

    headers = headers or {
        ["User-Agent"] = "curl/7.64.1",
        ["Accept"] = "*/*"
    }

    local response, error = request.send(url, {
        headers = headers
    })
    if not response then
        return false, error
    end
    local body = response.body
    local code = response.code

    if body and code == 200 then
        return body, code

    elseif code >= 300 and code <= 399 then
        local redirect = request.headers["Location"]:match("^%s*(.*)%s*$")
        headers["Referer"] = url
        return utils.download(redirect, headers)
    end

    return false, code, body
end

function utils.loadJSON(path)
    return utils.fromJSON(utils.load(path))
end

function utils.downloadJSON(url, headers)
    local data, error = utils.download(url, headers)
    if not data then
        return data, error
    end
    return utils.fromJSON(data)
end

function utils.fromJSON(body)
    return dkjson.decode(body)
end

function utils.toJSON(table, state)
    return dkjson.encode(table, state or { indent = true })
end

function utils.loadYAML(path)
    return utils.fromYAML(utils.load(path))
end

function utils.downloadYAML(url, headers)
    local data, error = utils.download(url, headers)
    if not data then
        return data, error
    end
    return utils.fromYAML(data)
end

function utils.fromYAML(body)
    return tinyyaml.parse(body)
end

function utils.toYAML(table)
    error("Encoding Lua tables to YAML currently not supported")
end

function utils.loadXML(path)
    return utils.fromXML(utils.load(path))
end

function utils.downloadXML(url, headers)
    local data, error = utils.download(url, headers)
    if not data then
        return data, error
    end
    return utils.fromXML(data)
end

function utils.fromXML(body)
    local handler = xml2luaTree:new()
    xml2lua.parser(handler):parse(body)
    return handler.root
end

function utils.toXML(table, name)
    if not name then
        for k, v in pairs(table) do
            name = k
            table = v
            break
        end
    end
    return xml2lua.toXml(table, name)
end

-- trim6 from http://lua-users.org/wiki/StringTrim
function utils.trim(s)
    return s:match("^()%s*$") and "" or s:match("^%s*(.*%S)")
end

function utils.dateToTimestamp(dateString)
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+.?%d*)Z"
    local year, month, day, hour, min, sec = dateString:match(pattern)
    local offset = os.time() - os.time(os.date("!*t"))
    return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = sec, isdst = false }) + offset
end

-- Based on https://gist.github.com/HoraceBury/9001099
function utils.cleanHTML(body)
    local rules = {
        { "&amp;", "&" },
        { "&nbsp;", " " },
        { "&#151;", "-" },
        { "&#146;", "'" },
        { "&#147;", "\"" },
        { "&#148;", "\"" },
        { "&#150;", "-" },
        { "&#160;", " " },
        { "<hr ?/?>", "\n" },
        { "</h[0-9]+>", "\n" },
        { "<br ?/?>", "\n" },
        { "<li>", "∙ " },
        { "</li>", "\n" },
        { "<pre>", "\n" },
        { "</p>", "\n" },
        { "(%b<>)", "" },
        { "\r", "\n" },
        { "[\n\n]+", "\n" },
        { "^\n*", "" },
        { "\n*$", "" },
    }

    for i = 1, #rules do
        local rule = rules[i]
        body = string.gsub(body, rule[1], rule[2])
    end

    return body
end

function utils.launch(path, vanilla)
    return threader.routine(function()
        if not path then
            local config = require("config")
            if config then
                path = config.installs[config.install].path
            end
        end

        if not path then
            return
        end

        local sharp = require("sharp")
        local alert = require("alert")

        local launching = sharp.launch(path, vanilla and "--vanilla" or nil)
        local container

        if vanilla then
            container = alert([[
Celeste is now starting in the background.
You can close this window.]])
        else
            container = alert([[
Everest is now starting in the background.
You can close this window.]])
        end

        launching:calls(function(task, rv)
            if rv == "missing" then
                container:close()
                alert([[
Olympus couldn't find the Celeste launch binary.
Please check if the installed version of Celeste matches your OS.
If you are using Lutris or similar, you are on your own.]])
            end
        end)
    end)
end

return utils
