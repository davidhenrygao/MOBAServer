local skynet = require "skynet"
local log = require "log"
local crypt = require "skynet.crypt"
local pb = require "protobuf"
local cmd = require "proto.cmd"
local proto = require "protocol"
local retcode = require "logic.retcode"

local protostr = "protocol.c2s_launch"

local gate = ...

local login_player = {}

local CMD = {}

function CMD.login(account, subid, username, uid, secret)
	login_player[username] = {
		account = account,
		subid = subid, 
		secret = secret,
		uid = uid,
		idx = 0,
	}
	return
end

-- There is a problem, the conn send another dispatch launch msg when call!
local function close_conn(conn)
	skynet.call(gate, "lua", "force_close_conn", conn)
end

local function verify_signature(username, index, hmac)
	local u = login_player[username]
	if u == nil then
		log("User haven't login.")
		return false
	end
	local idxStr = crypt.base64decode(index)
	local idx = tonumber(idxStr)
	if not idx then
		log("Signature format error: index not a number.")
		return false
	end
	if idx <= u.idx then
		log("Signature index expired.")
		return false
	end
	local text = string.format("%s:%s", username, index)
	local hashkey = crypt.hashkey(text)
	local v = crypt.base64encode(crypt.hmac64_md5(hashkey, u.secret))
	--[[
	local function strtohex(str)
		local len = str:len()
		local fmt = "0X"
		for i=1,len do
			fmt = fmt .. string.format("%02x", str:byte(i))
		end
		return fmt
	end
	log("token: %s.", text)
	log("secret: %s.", strtohex(u.secret))
	log("hashkey: %s.", strtohex(hashkey))
	log("hmac: %s.", hmac)
	log("v: %s.", v)
	--]]
	if v ~= hmac then
		log("Signature hmac not match.")
		return false
	end
	return true
end

local function send_message(source, sess, command, resp_proto_str, data)
	local result, err = pb.encode(resp_proto_str, data)
	if err ~= nil then
		log("Launch server protobuf encode cmd[%d] error(%s).", command, err)
		return false
	end
	local r = proto.serialize(sess, command, result)
	if not r then
		log("Launch server protocol serialization error!")
		return false
	end
	skynet.send(source, "lua", "response", sess, r)
	return true
end

function CMD.dispatch(source, sess, req_cmd, msg)
	if req_cmd == cmd.HEARTBEAT then
		local s2c_heartbeat = {
			cur_timestamp = skynet.time(),
		}
		local ret = send_message(source, sess, req_cmd, 
			"protocol.s2c_heartbeat", s2c_heartbeat) 
		if ret == false then
			return false
		end
		return
	end
	if req_cmd ~= cmd.LOGIN_LAUNCH then
		log("Launch server get unexpected cmd[%d].", req_cmd)
		close_conn(source)
		return
	end
	local result, err = pb.decode(protostr, msg)
	if err ~= nil then
		log("Launch server protobuf decode cmd[%d] error(%s).", req_cmd, err)
		close_conn(source)
		return false
	end
	local c2s_launch = result
	local username, index, hmac = string.match(c2s_launch.signature, "([^:]*):([^:]*):([^:]*)")
	local ok = verify_signature(username, index, hmac)
	if not ok then
		log("Launch server cmd[%d] verify signature error.", req_cmd)
		close_conn(source)
		return
	end
	local u = login_player[username]
	if u.launch ~= nil then
		log("Another client had been lauch!")
		close_conn(source)
		return
	end
	u.launch = "launching"
	local agent = u.agent
	if agent == nil then
		agent = skynet.newservice("agent", skynet.self())
		u.agent = agent
	end
	ok = skynet.call(agent, "lua", "launch", source, username, sess, req_cmd, u.uid)
	if not ok then
		u.launch = nil
	else
		u.launch = "launch"
	end

	skynet.call(source, "lua", "change_dest", agent)
	u.conn = source

	u.idx = u.idx + 1
end

function CMD.conn_abort(username)
	if username ~= nil then
		local u = login_player[username]
		if u ~= nil then
			u.launch = nil
			u.conn = nil
		end
	end
	return
end

function CMD.kick(username)
	local login_info = login_player[username]
	if login_info == nil then
		return
	end
	if login_info.conn ~= nil then
		local s2c_kick_out_player = {
			code = retcode.USER_RELOGIN_IN_OTHER_PLACE,
		}
		send_message(login_info.conn, 0, cmd.KICK_OUT_PLAYER, 
			"protocol.s2c_kick_out_player", s2c_kick_out_player)
		close_conn(login_info.conn)
	end
	if login_info.agent ~= nil then
		skynet.call(login_info.agent, "lua", "kick")
	end
	login_player[username] = nil
end

function CMD.logout(username)
	local login_info = login_player[username]
	if login_info == nil then
		return
	end
	if login_info.conn ~= nil then
		close_conn(login_info.conn)
	end
	skynet.call(gate, "lua", "logout", login_info.account)
	login_player[username] = nil
end

skynet.init( function ()
	local file = skynet.getenv("root") .. "proto/common/heartbeat.pb"
	pb.register_file(file)
	file = skynet.getenv("root") .. "proto/login/launch.pb"
	pb.register_file(file)
	file = skynet.getenv("root") .. "proto/player/kick_out_player.pb"
	pb.register_file(file)
end)

skynet.start( function ()
	skynet.dispatch("lua", function (session, source, command, ...)
		local func = CMD[command]
		if func then
			if session == 0 then
				func(...)
			else
				skynet.ret(skynet.pack(func(...)))
			end
		else
			log("Unknown login Command : [%s]", command)
			skynet.response()(false)
		end
	end)
end)
