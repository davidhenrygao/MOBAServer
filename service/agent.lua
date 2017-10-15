local skynet = require "skynet"
local log = require "log"
local proto = require "protocol"
local response = require "response"
local handle = require "logic.player"
local retcode = require "logic.retcode"

local CMD = {}

local player_info

function CMD.start(playerinfo)
    player_info = playerinfo
end

function CMD.dispatch(source, sess, msg)
    local resp_f = response(source, sess)
    local cmd, args = proto.unserialize(msg)
    if not cmd then
        log("protocol unserialization error, json msg: %s", msg)
	resp_f(retcode.PROTO_UNSERIALIZATION_FAILED)
	return
    end
    local f = handle[cmd]
    if not f then
        log("Unknown agent service's command : [%d]", cmd)
	resp_f(retcode.UNKNOWN_CMD)
	return
    end
    local req = {
	source = source,
	session = sess,
	cmd = cmd,
	args = args,
	playerinfo = player_info
    }
    f(req, resp_f)
end

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
