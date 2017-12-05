local skynet = require "skynet"
--local log = require "log"
local cmd = require "proto.cmd"
local retcode = require "logic.retcode"
local define = require "logic.module.player.define"
local player_state_define = define.PLAYER_STATE

local function execute_f(req, resp_f)
	local player = req.player
	local c2s_battle_action = req.args

	local s2c_battle_action = {
		code = 0,
	}

	local player_state = player:get_player_state()
	if player_state ~= player_state_define.BATTLE then
		s2c_battle_action.code = retcode.PLAYER_STATE_ILLEGAL
		resp_f(s2c_battle_action)
		return
	end

	local battle_info = player:get_player_battle_info()
	if battle_info:is_in_battle() ~= true then
		s2c_battle_action.code = retcode.PLAYER_NOT_IN_BATTLE
		resp_f(s2c_battle_action)
		return
	end

	local battleserver = battle_info:get_battle_server_addr()
	skynet.call(battleserver, "lua", "battle_action", 
		battle_info:get_battle_id(), player:get_id(), c2s_battle_action)

	resp_f(s2c_battle_action)
end

return {
    cmd = cmd.BATTLE_ACTION, 
    handler = execute_f,
	protoname = "protocol.c2s_battle_action",
	resp_protoname = "protocol.s2c_battle_action",
}
