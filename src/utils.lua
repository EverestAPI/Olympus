local request = require("luajit-request")
local dkjson = require("dkjson")

local utils = {}

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
    local body = utils.download(url, headers)
    return dkjson.decode(body)
end

function utils.trim(s)
    -- trim6 from http://lua-users.org/wiki/StringTrim
    return s:match("^()%s*$") and "" or s:match("^%s*(.*%S)")
end

return utils
