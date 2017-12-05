local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
local log = require "log"
local context = require "context"
local msgsender = require "msgsender"
local handle = require "logic.handle.player"
local retcode = require "logic.retcode"
local command = require "proto.cmd"
local pb = require "protobuf"
local player_mgr = require "logic.module.player.player_mgr"

local define = require "logic.module.player.define"
local player_state_define = define.PLAYER_STATE

local host = ...

-- local db

local CMD = {}

local player
local player_username

function CMD.kick()
	player:clean_battle_info()
	player:save()
	log("save player when be kicked.")
	skynet.fork( function ()
		skynet.exit()
	end)
end

function CMD.launch(dest, username, sess, cmd, uid)
	local cfg_data = sharedata.query("cfg_data")
	context:init(cfg_data)

	local err
	local s2c_launch = {
		code = retcode.SUCCESS,
	}
	if player == nil then
		player = player_mgr.new()
		err = player:init(uid)
		if err ~= retcode.SUCCESS then
			log("Player(%d) agent launch failed: err(%d)!", uid, err)
			s2c_launch.code = err
			return false
		end
	end
	player:set_player_state(player_state_define.NORMAL)

	msgsender:set_dest(dest)
	msgsender:set_pb(pb)
	local resp_f = msgsender:gen_respf(sess, cmd, "protocol.s2c_launch")
	s2c_launch.player = player:get_basic_info()
	resp_f(s2c_launch)

	player_username = username

	return true
end

function CMD.conn_abort()
	player:clean_battle_info()
	player:save()
	log("save player when connection abort.")
	player:set_player_state(player_state_define.UNLAUNCH)
	skynet.call(host, "lua", "conn_abort", player_username)
	return
end

local function logout(source, sess, req_cmd, msg)
	local s2c_logout = {
		code = retcode.SUCCESS,
	}
	local resp_f = msgsender:gen_respf(sess, req_cmd, "protocol.s2c_logout")
	resp_f(s2c_logout)

	skynet.call(host, "lua", "logout", player_username)

	player:clean_battle_info()
	player:save()
	log("save player when logout.")

	skynet.exit()
end

function CMD.dispatch(source, sess, req_cmd, msg)
	if req_cmd == command.LOGOUT then
		logout(source, sess, req_cmd, msg)
		return
	end

	local handleinfo = handle[req_cmd]
	if handleinfo == nil then
		log("Unknown agent service's command : [%d]", req_cmd)
		-- add error response later.
		return
	end
	local protoname = assert(handleinfo.protoname)
	local resp_protoname = assert(handleinfo.resp_protoname)
	local f = assert(handleinfo.handler)
	local args = pb.decode(protoname, msg)

	local resp_f = msgsender:gen_respf(sess, req_cmd, resp_protoname)
	local req = {
		source = source,
		session = sess,
		cmd = req_cmd,
		args = args,
		player = player,
	}
	f(req, resp_f)
end

function CMD.match_update(s2c_match_update)
	msgsender:push(command.MATCH_UPDATE, "protocol.s2c_match_update", 
		s2c_match_update)
end

function CMD.battle_init(s2c_battle_init, battle_server_addr)
	local battle_info = player:get_player_battle_info()
	battle_info:set_in_battle(s2c_battle_init.battle_id, battle_server_addr)
	local matchserver = skynet.localname(".matchserver")
	skynet.call(matchserver, "lua", "finish_match", player:get_id())
	msgsender:push(command.BATTLE_INIT, "protocol.s2c_battle_init", 
		s2c_battle_init)
end

function CMD.battle_start()
	local s2c_battle_start = {}
	msgsender:push(command.BATTLE_START, "protocol.s2c_battle_start", 
		s2c_battle_start)
end

function CMD.battle_frame_update(s2c_battle_frame_update)
	msgsender:push(command.BATTLE_FRAME_UPDATE, 
		"protocol.s2c_battle_frame_update", s2c_battle_frame_update)
end

function CMD.battle_end(result)
	local battle_info = player:get_player_battle_info()
	battle_info:set_free()
	player:set_player_state(player_state_define.NORMAL)
end

skynet.init( function ()
	-- db = skynet.queryservice("db")

	-- use lfs to load later.
	local files = {
		"common/array_elem.pb",
		"common/heartbeat.pb",
		"login/launch.pb",
		"player/echo.pb",
		"player/logout.pb",
		"player/gm_change_player_property.pb",
		"player/update_player_property.pb",
		"card/card.pb",
		"card/card_deck.pb",
		"card/load_cards.pb",
		"card/load_card_decks.pb",
		"card/up_card_level.pb",
		"card/check_card.pb",
		"card/change_deck.pb",
		"card/change_card_deck.pb",
		"card/update_cards.pb",
		"card/gm_get_card.pb",
		"battle/match_start.pb",
		"battle/match_cancel.pb",
		"battle/match_update.pb",
		"battle/battle_init.pb",
		"battle/battle_ready.pb",
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
    skynet.dispatch("lua", function (session, source, cmd, ...)
        local func = CMD[cmd]
	if func then
	    if session == 0 then
	        func(...)
	    else
		skynet.ret(skynet.pack(func(...)))
	    end
	else
	    log("Unknown agent Command : [%s]", cmd)
	    skynet.response()(false)
	end
    end)
end)
