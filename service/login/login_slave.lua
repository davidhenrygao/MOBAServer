local skynet = require "skynet"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"
local log = require "log"
local pb = require "protobuf"
local net = require "netpackage"
local protocol = require "protocol"
local cmd = require "proto.cmd"

local id = ...

local Context = {}

local function read_cmd_msg(fd, expect_cmd, protostr)
	local sess
	local req_cmd
	local data
	local ok
	local msg
	local result
	ok, msg = net.read(fd)
	if not ok then
		log("cmd[%d] netpackage read failed: connection[%d] aborted.", 
			expect_cmd, fd)
		return false
	end
	ok, sess, req_cmd, data = protocol.unserialize(msg)
	if not ok then
		log("cmd[%d] Connection[%d] protocol unserialize error.", 
			expect_cmd, fd)
		return false
	end
	if req_cmd ~= expect_cmd then
		log("Expect cmd[%d], get cmd[%d].", expect_cmd, req_cmd)
		return false
	end
	ok, result = pcall(pb.decode, protostr, data)
	if not ok then
		log("cmd[%d] protobuf decode error.", expect_cmd)
		return false
	end
	Context[fd].session = sess
	Context[fd].time = skynet.time()
	Context[fd].cmd = req_cmd
	return true, result
end

local function write_cmd_msg(fd, proto_cmd, protostr, orgdata)
	local data = pb.encode(protostr, orgdata)
	local msg = protocol.serialize(Context[fd].session, proto_cmd, data)
	net.write(fd, msg)
end

local function handshake(fd)
	local data
	local ok
	local msg
	local result

	local challenge = crypt.randomkey()
	local s2c_challenge = {
		challenge = crypt.base64encode(challenge),
	}
	data = pb.encode("login.s2c_challenge", s2c_challenge)
	msg = protocol.serialize(0, cmd.LOGIN_CHALLENGE, data)
	net.write(fd, msg)

	ok, result = read_cmd_msg(fd, cmd.LOGIN_EXCHANGEKEY, "login.c2s_clientkey")
	if not ok then
		return false
	end
	local clientkey = crypt.base64decode(result.clientkey)
	local serverkey = crypt.randomkey()
	local s2c_serverkey = {
		serverkey = crypt.base64encode(crypt.dhexchange(serverkey)),
	}
	write_cmd_msg(fd, cmd.LOGIN_EXCHANGEKEY, "login.s2c_serverkey", s2c_serverkey)

	local secret = crypt.dhsecret(clientkey, serverkey)
	ok, result = read_cmd_msg(fd, cmd.LOGIN_HANDSHAKE, "login.c2s_handshake")
	if not ok then
		return false
	end
	local clientkey = crypt.base64decode(result.clientkey)
	local serverkey = crypt.randomkey()
	local s2c_serverkey = {
		serverkey = crypt.base64encode(crypt.dhexchange(serverkey)),
	}
	write_cmd_msg(fd, cmd.LOGIN_EXCHANGEKEY, "login.s2c_serverkey", s2c_serverkey)

	return true
end

local function handle(fd)
	Context[fd] = {
		session = 0,
		time = skynet.time(),
	}
	socket.start(fd)
end

local CMD = {}

function CMD.handle(fd)
	skynet.fork(handle, fd)
end

skynet.init( function ()
	local load_file = {
	}
	for _,file in ipairs(load_file) do
		pb.register_file(skynet.getenv("root") .. "proto/" .. file)
	end
end)

skynet.start( function ()
	skynet.dispatch("lua", function (sess, src, cmd, ...)
		local f = CMD[cmd]
		if f then
			if sess ~= 0 then
				skynet.ret(skynet.pack(f(...)))
			else
				f(...)
			end
		else
			log("Unknown login slave command: %s.", cmd)
			skynet.response()(false)
		end
	end)
end)
