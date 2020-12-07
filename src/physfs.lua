-- This exists to update require("physfs") without breaking Olympus self-updating.
-- Any future extensions to physfs go in here.

local physfs = require("physfs_core")
local ffi = require("ffi")
local l = ffi.os == "Windows" and ffi.load("love") or ffi.C


return physfs
