local skynet = require "skynet"
local log = require "log"

local define = require "logic.module.player.define"

local battle_id_cnt = 1
local battles = {}

local function random_array(size)
	assert(size and type(size) == "number")
	local array = {}
	for i=1,size do
		array[i] = i
	end
	for i=1,size do
		local idx = size - i + 1
		local r = math.random(idx)
		local temp = array[idx]
		array[idx] = array[r]
		array[r] = temp
	end
	return array
end

local function random_cards(cards)
	local size = define.CARD_DECK_SIZE
	assert(#cards == size)
	local array = random_array(size)
	local random_cards_info = {}
	for i=1,size do
		local idx = array[i]
		local card = cards[idx]
		local battle_card_info = {
			card_id = card.id,
			level = card.level,
			pos = i,
		}
		table.insert(random_cards_info, battle_card_info)
	end
	return random_cards_info
end

local post_frame
local FRAME_INTERVAL = 20
local CHECK_INTERVAL = 1
-- Note: slot must an integer.
local slot = FRAME_INTERVAL / CHECK_INTERVAL
local time_slot = {}
local temp_list = {}
local start_time

local function battle_end_routine(battle_id)
	assert(battle_id and battles[battle_id])
	local battle = assert(battles[battle_id])
	for player_id,player_info in pairs(battle.players_info) do
		skynet.send(player_info.player_addr, "lua", "battle_end", 
			player_info.result)
	end
	battles[battle_id] = nil
end

local function post_frame_routine(battle_id)
	local battle = assert(battles[battle_id])
	local s2c_battle_frame_update = {
		frame_id = battle.frame_id,
		battle_actions = {},
	}
	battle.frame_id = battle.frame_id + 1
	for _,player_info in pairs(battle.players_info) do
		local player_id = player_info.player_id
		local action_list = battle.player_actions[player_id]
		if action_list == nil then
			action_list = {
				{
					class_id = 0,
					action = "",
				},
			}
		end
		local battle_action = {
			player_id = player_id,
			actions = action_list,
		}
		table.insert(s2c_battle_frame_update.battle_actions, battle_action)
		battle.player_actions[player_id] = nil
	end
	for _,player_info in pairs(battle.players_info) do
		if player_info.endflag == nil then
			skynet.send(player_info.player_addr, "lua", "battle_frame_update", 
				s2c_battle_frame_update)
		end
	end
end

post_frame = function ()
	skynet.timeout(CHECK_INTERVAL, post_frame)
	local cur_time = skynet.now()
	local interval = cur_time - start_time
	-- interval begin from 1 and we need index from 1 to slot
	local index = (interval / CHECK_INTERVAL) % slot
	if index == 0 then
		index = slot
	end
	local idx = 1
	while idx <= #time_slot[index] do
		local battle_id = time_slot[index][idx]
		local battle = assert(battles[battle_id])
		if battle.endflag then
			table.remove(time_slot[index], idx)
			battle_end_routine(battle_id)
		else
			idx = idx + 1
			post_frame_routine(battle_id)
		end
	end
	while true do
		local battle_id = temp_list[1]
		if battle_id == nil then
			break
		end
		local battle = assert(battles[battle_id])
		battle.frame_id = 1
		battle.start_time = cur_time
		table.insert(time_slot[index], battle_id)
		table.remove(temp_list, 1)
	end
end

local function battle_routine(battle_id)
	assert(battle_id and battles[battle_id])
	table.insert(temp_list, battle_id)
end

local CMD = {}

function CMD.create_battle(battle_players)
	local random = math.random(1, 0xffffffff)
	local team_amount = #battle_players / 2
	local battle_id = battle_id_cnt
	battle_id_cnt = battle_id_cnt + 1
	local players_info_record = {}
	local players_info = {}
	for idx,battle_player in ipairs(battle_players) do
		local player_info = battle_player.info
		local player_addr = battle_player.addr
		local random_player_cards = random_cards(player_info.cards)
		local team = 0
		if idx > team_amount then
			team = 1
		end
		local battle_player_info = {
			player_id = player_info.id,
			player_level = player_info.level,
			team = team,
			random_cards_info = random_player_cards,
		}
		table.insert(players_info, battle_player_info)
		local battle_player_info_record = {
			player_id = player_info.id,
			player_level = player_info.level,
			player_addr = player_addr,
			team = team,
			random_cards_info = random_player_cards,
		}
		players_info_record[player_info.id] = battle_player_info_record
	end
	battles[battle_id] = {
		battle_id = battle_id,
		random = random,
		team_amount = team_amount,
		players_info = players_info_record,
		ready_player_cnt = 0,
		end_player_cnt = 0,
		start_time = 0,
		frame_id = 0,
		player_actions = {},
	}
	local s2c_battle_init = {
		battle_id = battle_id,
		random = random,
		team_amount = team_amount,
		players_info = players_info,
	}
	for _,battle_player in ipairs(battle_players) do
		local player_addr = battle_player.addr
		skynet.send(player_addr, "lua", "battle_init", 
			s2c_battle_init, skynet.self())
	end
end

function CMD.battle_ready(battle_id, player_id)
	assert(battle_id and player_id)
	local battle = assert(battles[battle_id])
	local players_info = battle.players_info
	local battle_player = assert(players_info[player_id])
	if battle_player.ready == nil then
		battle_player.ready = true
		battle.ready_player_cnt = battle.ready_player_cnt + 1
		if battle.ready_player_cnt == battle.team_amount * 2 then
			for _,player_info in pairs(players_info) do
				skynet.send(player_info.player_addr, "lua", "battle_start")
			end
			skynet.fork(battle_routine, battle_id)
		end
	end
end

function CMD.battle_action(battle_id, player_id, action)
	assert(battle_id and player_id and action)
	local battle = assert(battles[battle_id])
	if battle.player_actions[player_id] == nil then
		battle.player_actions[player_id] = {}
	end
	table.insert(battle.player_actions[player_id], action)
end

function CMD.battle_end(battle_id, player_id, result)
	local battle = assert(battles[battle_id])
	local players_info = battle.players_info
	local battle_player = assert(players_info[player_id])
	if battle_player.endflag== nil then
		battle_player.endflag = true
		battle_player.end_result = result
		battle.end_player_cnt = battle.end_player_cnt + 1
		if battle.end_player_cnt == battle.team_amount * 2 then
			battle.endflag = true
		end
	end
end

skynet.init( function ()
	math.randomseed(os.time())
end)

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
			log("Unknown battle server command: %s.", command)
			skynet.response()(false)
		end
	end)
	start_time = skynet.now()
	for i=1,slot do
		time_slot[i] = {}
	end
	skynet.timeout(CHECK_INTERVAL, post_frame)
end)
