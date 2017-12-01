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

local CMD = {}

function CMD:create_battle(battle_players)
	local random = math.random(1, 0xffffffff)
	local team_amount = #battle_players / 2
	local battle_id = battle_id_cnt
	battle_id_cnt = battle_id_cnt + 1
	local players_info_record = {}
	local players_info = {}
	for idx,battle_player in ipairs(battle_players) do
		local player_info = battle_player.info
		local team = 0
		if idx > team_amount then
			team = 1
		end
		local battle_player_info = {
			player_id = player_info.id,
			player_level = player_info.level,
			team = team,
			random_cards_info = random_cards(player_info.cards),
		}
		table.insert(players_info, battle_player_info)
		local battle_player_info_record = {
			player_id = player_info.id,
			player_level = player_info.level,
			player_addr = player_info.addr,
			team = team,
			random_cards_info = battle_player_info.random_cards_info,
		}
		players_info_record[player_info.id] = battle_player_info_record
	end
	battles[battle_id] = {
		battle_id = battle_id,
		random = random,
		team_amount = team_amount,
		players_info = players_info_record,
	}
	local s2c_battle_init = {
		battle_id = battle_id,
		random = random,
		team_amount = team_amount,
		players_info = players_info,
	}
	for _,battle_player in ipairs(battle_players) do
		local player_addr = battle_player.addr
		skynet.send(player_addr, "lua", "battle_init", s2c_battle_init)
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
end)
