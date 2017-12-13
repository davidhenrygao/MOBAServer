local skynet = require "skynet"
local log = require "log"
local pb = require "protobuf"
local proto = require "protocol"

local cmd = require "proto.cmd"
local retcode = require "logic.retcode"

local define = require "logic.module.player.define"

local ip, port = ...
local server_addr = ip .. ":" .. tostring(port)

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

local function response(source, session, command, protoname, resp)
	local data = pb.encode(protoname, resp)
	local r = proto.serialize(session, command, data)
	if not r then
		log("protocol serialization error!")
		return
	end
	skynet.send(source, "lua", "response", session, r)
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
			player_name = player_info.name,
			team = team,
			random_cards_info = random_player_cards,
		}
		table.insert(players_info, battle_player_info)
		local battle_player_info_record = {
			player_id = player_info.id,
			player_level = player_info.level,
			player_name = player_info.name,
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
	}
	local s2c_battle_init = {
		battle_id = battle_id,
		random = random,
		server_addr = server_addr,
		team_amount = team_amount,
		players_info = players_info,
	}

	local battle_service = skynet.newservice("battle")
	skynet.call(battle_service, "lua", "init", battles[battle_id])
	battles[battle_id].service = battle_service

	for _,battle_player in ipairs(battle_players) do
		local player_addr = battle_player.addr
		skynet.send(player_addr, "lua", "battle_init", s2c_battle_init)
	end
end

function CMD.dispatch(source, sess, req_cmd, msg)
	if req_cmd ~= cmd.BATTLE_READY then
		log("Battle server get unexpected cmd[%d].", req_cmd)
		--skynet.call(source, "lua", "force_close")
		return
	end
	local args, err = pb.decode("protocol.c2s_battle_ready", msg)
	if args == false then
		log("protobuf decode error: %s.", err)
		return
	end
	local s2c_battle_ready = {
		code = 0,
	}
	local battle_id = args.battle_id
	local player_id = args.player_id
	local battle = battles[battle_id]
	if battle == nil then
		log("Battle(%d) not found.", battle_id)
		s2c_battle_ready.code = retcode.BATTLE_NOT_FOUND
		response(source, sess, req_cmd, 
			"protocol.s2c_battle_ready", s2c_battle_ready)
		return
	end
	local battle_player = battle.players_info[player_id]
	if battle_player == nil then
		log("Player(%d) not in Battle(%d).", player_id, battle_id)
		s2c_battle_ready.code = retcode.PLAYER_NOT_IN_BATTLE
		response(source, sess, req_cmd, 
			"protocol.s2c_battle_ready", s2c_battle_ready)
		return
	end

	response(source, sess, req_cmd, 
		"protocol.s2c_battle_ready", s2c_battle_ready)

	if battle_player.ready == nil then
		battle_player.ready = true
		skynet.call(source, "lua", "change_dest", battle.service)
		skynet.send(battle.service, "lua", "ready", source, player_id)
	end
end

function CMD.conn_abort()
	return
end

skynet.init( function ()
	math.randomseed(os.time())
	local files = {
		"battle/battle_ready.pb",
	}
	for _,file in ipairs(files) do
		pb.register_file(skynet.getenv("root") .. "proto/" .. file)
	end
end)

skynet.start( function ()
	skynet.dispatch("lua", function (sess, src, command, ...)
		local f = CMD[command]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			log("Unknown battle server command: %s.", command)
			skynet.response()(false)
		end
	end)
end)
