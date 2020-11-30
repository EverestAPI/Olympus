local fs = require("fs")
local utils = require("utils")

local configData = {}

local mtConfig = {
    __index = configData,
    __newindex = configData
}

local config = {}

function config.getName()
    return "config.json"
end

function config.getPath()
    return fs.joinpath(fs.getStorageDir(), config.getName())
end

function config.load()
    local path = config.getPath()
    local pathTmp = path .. ".saving"

    local exists = fs.isFile(pathTmp)
    local existsTmp = fs.isFile(path)

    if existsTmp then
        if exists then
            os.remove(pathTmp)
        else
            os.rename(pathTmp, path)
        end
    end

    local content = fs.read(path)
    if not content then
        return
    end

    local data = utils.fromJSON(content)
    configData = data
    mtConfig.__index = data
    mtConfig.__newindex = data

    data.installs = data.installs or {}

    local csd = os.getenv("OLYMPUS_CSD")
    if csd == "1" then
        data.csd = true
    elseif csd == "0" then
        data.csd = false
    elseif data.csd == nil then
        data.csd = false
    end

    local vsync = os.getenv("OLYMPUS_VSYNC")
    if vsync == "1" then
        data.vsync = true
    elseif vsync == "0" then
        data.vsync = false
    elseif data.vsync == nil then
        data.vsync = true
    end

    local themeOlympus = os.getenv("OLYMPUS_THEME")
    local themeOlympUI = os.getenv("OLYMPUI_THEME")
    if themeOlympus and #themeOlympus > 0 then
        data.theme = themeOlympus
    elseif themeOlympUI and #themeOlympUI > 0 then
        data.theme = themeOlympUI
    elseif data.theme == nil then
        data.theme = "default"
    end

    data.bg = data.bg or 0
end

function config.save()
    local path = config.getPath()
    local pathTmp = path .. ".saving"

    local content = utils.toJSON(configData)

    os.remove(pathTmp)
    fs.write(pathTmp, content)
    os.remove(path)
    os.rename(pathTmp, path)
    os.remove(pathTmp)
end

config = setmetatable(config, mtConfig)

config.load()

return config
