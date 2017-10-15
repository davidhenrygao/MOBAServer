--[[
-- This file define the cmd code between client and server.
--]]

local CMD = {
-- 0-99 common use
    HEARTBEAT = 1,
    ECHO = 2,
-- 100-199 login server use
    LOGIN = 100,
    CHANGENAME = 101,
    GETPLAYERINFO = 102,
}

return CMD
