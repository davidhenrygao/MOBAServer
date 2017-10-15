local retcode = require "logic.retcode"
local cmd = require "proto.cmd"

local function execute_f(req, resp_f)
    local player = req.playerinfo
    local echo_msg = assert(req.args.msg)
    local resp = {
	msg = player.name .. "[" .. string.format("%d", player.id) .. "] say: " .. echo_msg,
    }
    resp_f(retcode.SUCCESS, resp)
end

return {
    cmd = cmd.ECHO, 
    handler = execute_f,
}
