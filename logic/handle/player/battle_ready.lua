local skynet = require "skynet"
--local log = require "log"
local cmd = require "proto.cmd"
local retcode = require "logic.retcode"
local define = require "logic.module.player.define"
local player_state_define = define.PLAYER_STATE

local function execute_f(req, resp_f)
	local player = req.player

	local s2c_battle_ready = {
		code = 0,
	}

	local player_state = player:get_player_state()
	if player_state ~= player_state_define.BATTLE then
		s2c_battle_ready.code = retcode.PLAYER_STATE_ILLEGAL
		resp_f(s2c_battle_ready)
		return
	end

	local battle_info = player:get_player_battle_info()
	if battle_info:is_in_battle() ~= true then
		s2c_battle_ready.code = retcode.PLAYER_NOT_IN_BATTLE
		resp_f(s2c_battle_ready)
		return
	end

	local battleserver = battle_info:get_battle_server_addr()
	skynet.call(battleserver, "lua", "battle_ready", 
		battle_info:get_battle_id(), player:get_id())

	resp_f(s2c_battle_ready)
end

return {
    cmd = cmd.BATTLE_READY, 
    handler = execute_f,
	protoname = "protocol.c2s_battle_ready",
	resp_protoname = "protocol.s2c_battle_ready",
}
