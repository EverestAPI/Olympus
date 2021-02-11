require("love.filesystem")
local requestStatus, request = pcall(require, "luajit-request")
if not requestStatus then
    print("luajit-request not loaded")
    print(request)
    request = nil
end
local dkjson = require("dkjson")
local yaml = require("yaml")
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

function utils._important(name)
    return function(size, check)
        return function(el)
            local uie = require("ui.elements")

            el.clip = false
            if el.style:get("spacing") ~= nil then
                el.style.spacing = 0
            end

            el:addChild(uie.image(name):with({
                check = check,
                time = love.math.random() * 0.3,
                scale = size / 256,
                updateHidden = true
            }):hook({
                update = function(orig, self, dt)
                    orig(self, dt)

                    local check = self.check
                    if uiu.isCallback(check) then
                        local visible = check(self) and true or false
                        if visible ~= self.visible then
                            self.visible = visible
                            self:reflow()
                            if not self.visible then
                                self.time = love.math.random() * 0.3
                            end
                        end
                    end

                    if self.visible then
                        local time = self.time + dt
                        if time >= 1 then
                            time = time - 1
                        end
                        self.time = time
                        self:repaint()
                    end
                end,

                calcSize = function(orig, self)
                    self.width = 0
                    self.height = 0
                end,
                layoutLateLazy = function(orig, self)
                    self:layoutLate()
                end,
                layoutLate = function(orig, self)
                    orig(self)
                    self.realX = -8
                    self.realY = -8
                end,

                draw = function(orig, self)
                    if self.visible then
                        local time = self.time
                        self.realY = -4 + -8 * math.abs(math.sin(time * time * math.pi * 4)) * (1 - time)
                        orig(self)
                    end
                end
            }):as(name))
        end
    end
end

utils.important = utils._important("important")
utils.importantPin = utils._important("importantPin")

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

function utils.toURLComponent(value)
    return value and value:gsub("([^%w _%%%-%.~])", function(c) return string.format("%%%02X", string.byte(c)) end):gsub(" ", "+")
end

function utils.fromURLComponent(value)
    return value and value:gsub("+", " "):gsub("%%(%x%x)", function(c) return string.char(tonumber(c, 16)) end)
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
    if not request then
        if headers then
            return false, "luajit-request not loaded: " .. tostring(request)
        end

        local status, data = pcall(function(url)
            return require("sharp")._run("webGet", url)
        end, url)

        if status then
            return data
        end
        return false, 0, data
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
        return body

    elseif code >= 300 and code <= 399 then
        -- "Location" is correct but "location" is what curl sometimes spits out.
        local redirect = (response.headers["Location"] or response.headers["location"] or ""):match("^%s*(.*)%s*$")
        if not redirect then
            return false, code, body
        end
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
    local status, rv = pcall(utils.fromJSON, data)
    if not status then
        return status, rv
    end
    return rv
end

function utils.fromJSON(body)
    return body and dkjson.decode(body)
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
    local status, rv = pcall(utils.fromYAML, data)
    if not status then
        return status, rv
    end
    return rv
end

function utils.fromYAML(body)
    return body and yaml.eval(body)
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
    local status, rv = pcall(utils.fromXML, data)
    if not status then
        return status, rv
    end
    return rv
end

function utils.fromXML(body)
    if not body then
        return false
    end
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
    return s and (s:match("^()%s*$") and "" or s:match("^%s*(.*%S)"))
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

        local rv = launching:result()
        if rv == "missing" then
            container:close()
            alert([[
Olympus couldn't find the Celeste launch binary.
Please check if the installed version of Celeste matches your OS.
If you are using Lutris or similar, you are on your own.]])
            return false
        end

        return true
    end)
end

return utils
