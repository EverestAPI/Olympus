-- Based on love_filesystem_unsandboxing.lua from Lönn
-- TODO: Create a common repo for things shared between Lönn and Olympus?

local physfs = require("physfs")
require("love.filesystem")

love.filesystem.createDirectoryUnsandboxed = physfs.mkdir
love.filesystem.mountUnsandboxed = physfs.mount
love.filesystem.isDirectoryUnsandboxed = physfs.isDirectory
