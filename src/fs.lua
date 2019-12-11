-- Based on filesystem.lua from Lönn
-- TODO: Create a common repo for things shared between Lönn and Olympus?

require("love_filesystem_unsandboxing")
local lfs = require("lfs_ffi")
local nfd = require("nfd")
local physfs = require("physfs")
local threader = require("threader")

local fs = {}

fs.mkdir = lfs.mkdir
fs.chdir = lfs.chdir
fs.dir = lfs.dir
fs.rmdir = lfs.rmdir
fs.rmdir = lfs.rmdir
fs.getcwd = lfs.currentdir

fs.remove = os.remove

function fs.filename(path, sep)
    sep = sep or physfs.getDirSeparator()

    return path:match("[^" .. sep .. "]+$")
end

function fs.dirname(path, sep)
    sep = sep or physfs.getDirSeparator()

    return path:match("(.*" .. sep .. ")"):gsub("([^/\\])[/\\]$", "%1")
end

-- TODO - Sanitize parts with leading/trailing separator
-- IE {"foo", "/bar/"} becomes "foo//bar", expected "foo/bar"
function fs.joinpath(...)
    local parts = {...}
    local sep = physfs.getDirSeparator()
    return table.concat(parts, sep)
end

function fs.splitpath(path)
    local sep = physfs.getDirSeparator()
    return string.split(path, sep)
end

function fs.normalize(path)
    path = path:gsub("([^/\\])[/\\]$", "%1")
    local sep = physfs.getDirSeparator()

    local fixed = ""
    local real = true
    for part in path:gmatch("([^/\\]*)") do
        if #part == 0 then
            if #fixed == 0 then
                goto add
            end
            goto skip
        end

        if #fixed ~= 0 and real then
            local partLow = part:lower()
            real = false
            for realpart in fs.dir(fixed) do
                if realpart:lower() == partLow then
                    real = realpart
                    break
                end
            end
            part = real or part
        end

        ::add::
        fixed = fixed .. part .. sep
        ::skip::
    end

    return fixed:sub(1, #fixed - 1)
end

function fs.fileExtension(path)
    return path:match("[^.]+$")
end

function fs.stripExtension(path)
    return path:sub(1, #path - #fs.fileExtension(path) - 1)
end

function fs.isFile(path)
    if not path then
        return false
    end
    local attrs = lfs.attributes(path)
    return attrs and attrs.mode == "file" and path
end

function fs.isDirectory(path)
    if not path then
        return false
    end
    path = path:gsub("([^/\\])[/\\]$", "%1")
    local attrs = lfs.attributes(path)
    return attrs and attrs.mode == "directory" and path
end

function fs.read(path)
    local fh = io.open(path, "rb")
    if not fh then
        return
    end

    local content = fh:read("*a")
    fh:close()

    return content
end

function fs.write(path, content)
    fs.mkdir(fs.dirname(path))

    local fh = io.open(path, "wb")
    if not fh then
        return
    end

    fh:write(content)
    fh:close()
end

function fs.saveDialog(filter, path)
    return threader.run(function()
        return require("nfd").save(filter, nil, path)
    end)
end

function fs.openDialog(filter, path)
    return threader.run(function()
        return require("nfd").open(filter, nil, path)
    end)
end

function fs.copyFromLove(mountPoint, output, folder)
    local filesTablePath = folder and fs.joinpath(mountPoint, folder) or mountPoint
    local filesTable = love.filesystem.getDirectoryItems(filesTablePath)

    local outputTarget = folder and fs.joinpath(output, folder) or output
    fs.mkdir(outputTarget)

    for i, file in pairs(filesTable) do
        local path = folder and fs.joinpath(folder, file) or file
        local mountPath = fs.joinpath(mountPoint, path)
        local info = love.filesystem.getInfo(mountPath)

        if info.type == "file" then
            local fh = io.open(fs.joinpath(output, path), "wb")

            if fh then
                local data = love.filesystem.read(mountPath)

                fh:write(data)
                fh:close()
            end

        elseif info.type == "directory" then
            fs.copyFromLove(mountPoint, output, path)
        end
    end
end

-- Unzip using phyfs unsandboxed mount system, and then manually copying out files
function fs.unzip(zipPath, outputDir)
    local tmp = "tmp-zip-" .. tostring(love.timer.getTime())

    love.filesystem.mountUnsandboxed(zipPath, tmp .. "/", 0)

    fs.copyFromLove(tmp, outputDir)

    love.filesystem.unmount(tmp)
end

function fs.getStorageDir()
    local name = "Olympus"

    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return fs.joinpath(os.getenv("LocalAppData"), name)

    elseif userOS == "Linux" then
        return fs.joinpath(os.getenv("XDG_CONFIG_HOME") or fs.joinpath(os.getenv("HOME"), ".config"), name)

    elseif userOS == "OS X" then
        return fs.joinpath(os.getenv("HOME"), "Library", "Application Support", name)

    elseif userOS == "Android" then
        -- TODO

    elseif userOS == "iOS" then
        -- TODO
    end
end

return fs