local skynet = "skynet"
local log = require "log"
local cmd = require "proto.cmd"
local retcode = require "logic.retcode"
local define = require "logic.module.player.define"
local player_state_define = define.PLAYER_STATE

local function execute_f(req, resp_f)
	local player = req.player

	local c2s_match_start = req.args

	local s2c_match_start = {
		code = 0,
	}

	-- TODO: check c2s_match_start.type
	local matchtype = c2s_match_start.type
	log("match start type: %d.", matchtype)

	local player_state = player:get_player_state()
	if player_state ~= player_state_define.NORMAL then
		s2c_match_start.code = retcode.PLAYER_STATE_ILLEGAL
		resp_f(s2c_match_start)
		return
	end

	local battle_info = player:get_player_battle_info()
	if battle_info:is_matching() then
		s2c_match_start.code = retcode.PLAYER_ALREADY_IN_MATCHING
		resp_f(s2c_match_start)
		return
	end
	if battle_info:is_in_battle() then
		s2c_match_start.code = retcode.PLAYER_ALREADY_IN_BATTLE
		resp_f(s2c_match_start)
		return
	end

	battle_info:set_matching()
	
	local player_match_info = {
		id = player:get_id(),
		level = player:get_level(),
		cards = player:get_cur_card_deck_info(),
		type = matchtype,
	}

	local matchserver = skynet.localname(".matchserver")
	skynet.call(matchserver, "lua", "start_match", 
		player_match_info, skynet.self())

	player:set_player_state(player_state_define.BATTLE)

	resp_f(s2c_match_start)
end

return {
    cmd = cmd.MATCH_START, 
    handler = execute_f,
	protoname = "protocol.c2s_match_start",
	resp_protoname = "protocol.s2c_match_start",
}
