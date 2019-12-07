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
            os.delete(pathTmp)
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
end

function config.save()
    local path = config.getPath()
    local pathTmp = path .. ".saving"

    local content = utils.toJSON(configData)

    fs.write(pathTmp, content)
    os.rename(pathTmp, path)
    os.remove(path)
end

config = setmetatable(config, mtConfig)

config.load()

return config
