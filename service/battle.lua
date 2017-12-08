local skynet = require "skynet"
local log = require "log"
local pb = require "protobuf"
local proto = require "protocol"

local cmd = require "proto.cmd"

local battle

local function response(source, session, command, protoname, resp)
	local data = pb.encode(protoname, resp)
	local r = proto.serialize(session, command, data)
	if not r then
		log("protocol serialization error!")
		return
	end
	skynet.send(source, "lua", "response", session, r)
end

local function push(source, command, protoname, resp)
	response(source, 0, command, protoname, resp)
end

local post_frame
local FRAME_INTERVAL = 20

local function battle_end_routine()
	for player_id,player_info in pairs(battle.players_info) do
		skynet.send(player_info.player_addr, "lua", "battle_end", 
			player_info.result)
	end
	skynet.exit()
end

local function post_frame_routine()
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
	local end_player_cnt = 0
	for _,player_info in pairs(battle.players_info) do
		if player_info.endflag == nil and player_info.conn then
			push(player_info.conn, cmd.BATTLE_FRAME_UPDATE, 
				"protocol.s2c_battle_frame_update", 
				s2c_battle_frame_update)
		else
			end_player_cnt = end_player_cnt + 1
		end
	end
	if end_player_cnt == battle.team_amount * 2 then
		battle.endflag = true
	end
end

post_frame = function ()
	if battle.endflag then
		battle_end_routine()
		return
	end
	skynet.timeout(FRAME_INTERVAL, post_frame)
	post_frame_routine()
end

local CMD = {}

function CMD.ready(_, conn, player_id)
	local player_info = assert(battle.players_info[player_id])
	player_info.ready = true
	player_info.conn = conn
end

function CMD.start()
	battle.start_time = skynet.now()
	battle.frame_id = 1
	battle.player_actions = {}
	skynet.timeout(FRAME_INTERVAL, post_frame)
	local s2c_battle_start = {}
	for player_id,player_info in pairs(battle.players_info) do
		push(player_info.conn, cmd.BATTLE_START, 
			"protocol.s2c_battle_start", s2c_battle_start)
	end
end

local function handle_battle_action(source, sess, req_cmd, msg, player_info)
	local args, err = pb.decode("protocol.c2s_battle_action", msg)
	if args == false then
		log("protobuf decode error: %s.", err)
		return
	end
	local player_id = player_info.player_id
	local action = {
		class_id = args.class_id,
		action = args.action,
	}
	local s2c_battle_action = {
		code = 0,
	}
	if battle.player_actions[player_id] == nil then
		battle.player_actions[player_id] = {}
	end
	table.insert(battle.player_actions[player_id], action)
	response(source, sess, req_cmd, 
		"protocol.s2c_battle_action", s2c_battle_action)
end

local function handle_battle_end(source, sess, req_cmd, msg, player_info)
	local args, err = pb.decode("protocol.c2s_battle_end", msg)
	if args == false then
		log("protobuf decode error: %s.", err)
		return
	end
	local result = args.result
	local s2c_battle_end = {
		code = 0,
	}
	if player_info.endflag== nil then
		player_info.endflag = true
		player_info.end_result = result
	end
	response(source, sess, req_cmd, 
		"protocol.s2c_battle_end", s2c_battle_end)
end

function CMD.dispatch(_, source, sess, req_cmd, msg)
	if battle.start_time == nil then
		log("Receive data when battle service not start.")
		return
	end
	local player = nil
	for player_id,player_info in pairs(battle.players_info) do
		if player_info.conn == source then
			player = player_info
		end
	end
	if player == nil then
		log("Battle service did not found player with conn(%d).", source)
		skynet.call(source, "lua", "force_close")
		return
	end
	if req_cmd ~= cmd.BATTLE_ACTION and req_cmd ~= cmd.BATTLE_END then
		log("Battle service get unexpected cmd[%d].", req_cmd)
		player.endflag = true
		player.end_result = 1
		player.conn = nil
		skynet.call(source, "lua", "force_close")
		return
	end
	if req_cmd == cmd.BATTLE_ACTION then
		handle_battle_action(source, sess, req_cmd, msg, player)
	end
	if req_cmd == cmd.BATTLE_END then
		handle_battle_end(source, sess, req_cmd, msg, player)
	end
end

function CMD.conn_abort(source)
	local player = nil
	for player_id,player_info in pairs(battle.players_info) do
		if player_info.conn == source then
			player = player_info
		end
	end
	if player ~= nil then
		player.endflag = true
		player.end_result = 1
		player.conn = nil
	end
	return
end

function CMD.init(_, battle_info)
	battle = battle_info
end

skynet.init( function ()
	local files = {
		"battle/battle_start.pb",
		"battle/battle_end.pb",
		"battle/battle_frame_update.pb",
		"battle/battle_action.pb",
	}
	for _,file in ipairs(files) do
		pb.register_file(skynet.getenv("root") .. "proto/" .. file)
	end
end)

skynet.start( function ()
	skynet.dispatch("lua", function (sess, src, command, ...)
		local f = CMD[command]
		if f then
			skynet.ret(skynet.pack(f(src, ...)))
		else
			log("Unknown battle command: %s.", command)
			skynet.response()(false)
		end
	end)
end)
