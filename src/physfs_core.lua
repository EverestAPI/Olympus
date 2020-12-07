-- Inspired by phsyfs.lua from Lönn
-- Note: This file must stay the same thanks to Olympus self updating.
-- TODO: Create a common repo for things shared between Lönn and Olympus?

-- Definitions taken from https://hg.icculus.org/icculus/physfs/file/default/src/physfs.h

local physfs = {}

local ffi = require("ffi")
local l = ffi.os == "Windows" and ffi.load("love") or ffi.C

ffi.cdef [[
    int PHYSFS_mount(const char *newDir, const char *mountPoint, int appendToPath);
    int PHYSFS_unmount(const char *oldDir);
    int PHYSFS_mkdir(const char *dirName);
    bool PHYSFS_isDirectory(const char *fname);
    const char *PHYSFS_getDirSeparator();
    const char *PHYSFS_getMountPoint(const char *dir);
    char** PHYSFS_getSearchPath();
    void PHYSFS_freeList(void *listVar);
    int PHYSFS_init();
]]

l.PHYSFS_init()

physfs.mount = l.PHYSFS_mount
physfs.unmount = l.PHYSFS_unmount
physfs.mkdir = l.PHYSFS_mkdir
physfs.isDirectory = l.PHYSFS_isDirectory

function physfs.getDirSeparator()
    return ffi.string(l.PHYSFS_getDirSeparator())
end

function physfs.getMountPoint(dir)
    return ffi.string(l.PHYSFS_getMountPoint(dir))
end

function physfs.getSearchPath()
    local raw = l.PHYSFS_getSearchPath()
    local list = {}
    local i = 0
    while raw[i] ~= nil do
        list[i + 1] = ffi.string(raw[i])
        i = i + 1
    end

    l.PHYSFS_freeList(raw)
    return list
end

return physfs