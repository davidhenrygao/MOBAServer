local skynet = require "skynet"
local log = require "log"
local msgsender = require "msgsender"
local handle = require "logic.handle.player"
local retcode = require "logic.retcode"
local command = require "proto.cmd"
local pb = require "protobuf"
local player_mgr = require "logic.module.player.player_mgr"

local host = ...

-- local db

local CMD = {}

local player
local player_username

function CMD.kick()
	skynet.fork( function ()
		skynet.exit()
	end)
end

function CMD.launch(dest, username, sess, cmd, uid)
	local err
	local s2c_launch = {
		code = retcode.SUCCESS,
	}
	player = player_mgr.new()
	err = player:init(uid)
	if err ~= retcode.SUCCESS then
		log("Player(%d) agent launch failed: err(%d)!", uid, err)
		s2c_launch.code = err
		return false
	end

	msgsender:set_dest(dest)
	msgsender:set_pb(pb)
	local resp_f = msgsender:gen_respf(sess, cmd, "protocol.s2c_launch")
	s2c_launch.player = player:get_basic_info()
	resp_f(s2c_launch)

	player_username = username

	return true
end

function CMD.conn_abort()
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

	player:save()
	log("save player.")

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
		player = player
	}
	f(req, resp_f)
end

skynet.init( function ()
	-- db = skynet.queryservice("db")

	-- use lfs to load later.
	local files = {
		"login/launch.pb",
		"player/echo.pb",
		"player/logout.pb",
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
