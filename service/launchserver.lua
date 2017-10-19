local skynet = require "skynet"
local log = require "log"
local crypt = require "skynet.crypt"
local pb = require "protobuf"
local cmd = require "proto.cmd"

local protostr = "login.launch"

local gate = ...

local login_player = {}

local CMD = {}

function CMD.login(subid, username, uid, secret)
	login_player[username] = {
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
	local ok, idx = pcall(tonumber, index)
	if not ok then
		log("Signature format error: index not a number.")
		return false
	end
	if idx <= u.idx then
		log("Signature index expired.")
		return false
	end
	local text = string.format("%s:%s", username, index)
	local v = crypt.hmac_hash(u.secret, text)
	if v ~= hmac then
		log("Signature hmac not match.")
		return false
	end
	return true
end

function CMD.dispatch(source, sess, req_cmd, msg)
	if req_cmd ~= cmd.LOGIN_LAUNCH then
		log("Launch server get unexpected cmd[%d].", req_cmd)
		close_conn(source)
		return
	end
	local ok, result = pcall(pb.decode, protostr, msg)
	if not ok then
		log("Launch server protobuf decode cmd[%d] error.", req_cmd)
		close_conn(source)
		return
	end
	local c2s_launch = result
	local username, index, hmac = string.match(c2s_launch.signature, "([^:]*):([^:]*):([^:]*)")
	ok = verify_signature(username, index, hmac)
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

function CMD.kick(username)
	local login_info = login_player[username]
	if login_info == nil then
		return
	end
	if login_info.conn ~= nil then
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
	local file = skynet.getenv("root") .. "proto/login/launch.pb"
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
