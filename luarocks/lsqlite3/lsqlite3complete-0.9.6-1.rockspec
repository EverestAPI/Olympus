package = "lsqlite3complete"
version = "0.9.6-1"
source = {
    url = "https://raw.githubusercontent.com/EverestAPI/Olympus/refs/heads/main/luarocks/lsqlite3/lsqlite3_v096.zip",
    file = "lsqlite3_v096.zip",
}
description = {
    summary = "A binding for Lua to the SQLite3 database library",
    detailed = [[
        lsqlite3complete is a thin wrapper around the public domain SQLite3 database engine. 
        SQLite3 is included and statically linked. (The dynamically linked alternative is lsqlite3).
        The lsqlite3complete module supports the creation and manipulation of SQLite3 databases. 
        Most sqlite3 functions are called via an object-oriented interface to either database
        or SQL statement objects.
    ]],
    license = "MIT",
    homepage = "http://lua.sqlite.org/",
}
dependencies = {
    "lua >= 5.1, < 5.5",
}
build = {
    type = "builtin",
    modules = {
        lsqlite3complete = {
            sources = { "lsqlite3.c", "sqlite3.c" },
            defines = {'LSQLITE_VERSION="0.9.6"', 'luaopen_lsqlite3=luaopen_lsqlite3complete'},
        },
    },
    platforms = {
        unix = {
            modules = {
                lsqlite3complete = {
                    libraries = { "pthread", "m", "dl" },
                },
            },
        },
    },
    copy_directories = { 'doc', 'examples' }
}
