local skynet = require "skynet"
local log = require "log"

local define = require "logic.module.player.define"
local match_state_define = define.MATCH_STATE

-- constant
local team_amount = 1
local need_player_amount = team_amount * 2

local match_players = {} -- { [player_id] = {...}, ...}
local matching_player_list = {}

local CMD = {}

local function do_match()
	local amount = #matching_player_list
	local s2c_match_update = {
		cur_amount = amount,
		need_amount = need_player_amount,
	}
	for _,id in ipairs(matching_player_list) do
		local player_addr = match_players[id].addr
		skynet.send(player_addr, "lua", "match_update", s2c_match_update)
	end
	if amount >= need_player_amount then
		local battle_players = {}
		for i=1,need_player_amount do
			local id = matching_player_list[1]
			table.remove(matching_player_list, 1)
			match_players[id].state = match_state_define.MATCHED
			table.insert(battle_players, match_players[id])
		end
		local battleserver = skynet.localname(".battleserver")
		skynet.call(battleserver, "lua", "create_battle", battle_players)
		for _,battle_player in ipairs(battle_players) do
			local id = battle_player.info.id
			match_players[id] = nil
		end
	end
end

function CMD.start_match(player_match_info, agent_addr)
	local player_id = player_match_info.id
	match_players[player_id] = {
		addr = agent_addr,
		state = match_state_define.MATCHING,
		info = player_match_info,
	}
	table.insert(matching_player_list, player_id)
	skynet.fork(do_match)
end

skynet.start( function ()
	skynet.dispatch("lua", function (sess, src, command, ...)
		local f = CMD[command]
		if f then
			if sess ~= 0 then
				skynet.ret(skynet.pack(f(...)))
			else
				f(...)
			end
		else
			log("Unknown match server command: %s.", command)
			skynet.response()(false)
		end
	end)
end)
