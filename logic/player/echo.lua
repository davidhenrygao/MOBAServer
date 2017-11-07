local retcode = require "logic.retcode"
local cmd = require "proto.cmd"

local function execute_f(req, resp_f)
	local player = req.player
	local player_basic_info = player:get_basic_info()
	local msg = assert(req.args.msg)
	local echo_msg = player_basic_info.name .. "[" .. string.format("%d", player_basic_info.id) .. "] say: " .. msg
	local s2c_echo = {
		msg = echo_msg,
	}
	resp_f(s2c_echo)
end

return {
    cmd = cmd.ECHO, 
    handler = execute_f,
	protoname = "protocol.c2s_echo",
	resp_protoname = "protocol.s2c_echo",
}
