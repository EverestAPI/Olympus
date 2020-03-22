local request = require("luajit-request")
local dkjson = require("dkjson")
local tinyyaml = require("tinyyaml")

local utils = {}

local uiu = require("ui.utils")
for k, v in pairs(uiu) do
    utils[k] = v
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

function utils.download(url, headers)
    headers = headers or {
        ["User-Agent"] = "curl/7.64.1",
        ["Accept"] = "*/*"
    }

    local response = request.send(url, {
        headers = headers
    })
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

function utils.downloadJSON(url, headers)
    return utils.fromJSON(utils.download(url, headers))
end

function utils.fromJSON(body)
    return dkjson.decode(body)
end

function utils.toJSON(table)
    return dkjson.encode(table, { indent = true })
end

function utils.downloadYAML(url, headers)
    return utils.fromYAML(utils.download(url, headers))
end

function utils.fromYAML(body)
    return tinyyaml.parse(body)
end

function utils.toYAML(table)
    error("Encoding Lua tables to YAML currently not supported")
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
        { "&#151;", "-" },
        { "&#146;", "'" },
        { "&#147;", "\"" },
        { "&#148;", "\"" },
        { "&#150;", "-" },
        { "&#160;", " " },
        { "<br ?/?>", "\n" },
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

return utils
