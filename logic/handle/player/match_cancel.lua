local skynet = require "skynet"
--local log = require "log"
local cmd = require "proto.cmd"
local retcode = require "logic.retcode"
local define = require "logic.module.player.define"
local player_state_define = define.PLAYER_STATE

local function execute_f(req, resp_f)
	local player = req.player

	local s2c_match_cancel = {
		code = 0,
	}

	local player_state = player:get_player_state()
	if player_state ~= player_state_define.BATTLE then
		s2c_match_cancel.code = retcode.PLAYER_STATE_ILLEGAL
		resp_f(s2c_match_cancel)
		return
	end

	local battle_info = player:get_player_battle_info()
	if battle_info:is_free() then
		s2c_match_cancel.code = retcode.PLAYER_NOT_IN_MATCHING
		resp_f(s2c_match_cancel)
		return
	end
	if battle_info:is_in_battle() then
		s2c_match_cancel.code = retcode.PLAYER_ALREADY_IN_BATTLE
		resp_f(s2c_match_cancel)
		return
	end

	local matchserver = skynet.localname(".matchserver")
	local ret, err = skynet.call(matchserver, "lua", "cancel_match", player:get_id())
	if ret ~= true then
		s2c_match_cancel.code = err
		resp_f(s2c_match_cancel)
		return
	end

	battle_info:set_free()
	
	player:set_player_state(player_state_define.NORMAL)

	resp_f(s2c_match_cancel)
end

return {
    cmd = cmd.MATCH_CANCEL, 
    handler = execute_f,
	protoname = "protocol.c2s_match_cancel",
	resp_protoname = "protocol.s2c_match_cancel",
}
