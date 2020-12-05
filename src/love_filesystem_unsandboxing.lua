-- Based on love_filesystem_unsandboxing.lua from Lönn
-- TODO: Create a common repo for things shared between Lönn and Olympus?

local physfsStatus, physfs = pcall(require, "physfs")
require("love.filesystem")

if not physfsStatus then
    love.filesystem.createDirectoryUnsandboxed = physfs.mkdir
    love.filesystem.mountUnsandboxed = physfs.mount
    love.filesystem.isDirectoryUnsandboxed = physfs.isDirectory

else
    local function nop()
    end

    love.filesystem.createDirectoryUnsandboxed = nop
    love.filesystem.mountUnsandboxed = nop
    love.filesystem.isDirectoryUnsandboxed = nop
end
