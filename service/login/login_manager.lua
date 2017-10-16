local skynet = require "skynet"
local socket = require "skynet.socket"
local cluster = require "skynet.cluster"
require "skynet.manager"
local crypt = require "skynet.crypt"

local log = require "log"

local server = {
	host = "127.0.0.1",
	port = 8001,
	multilogin = false,	-- disallow multilogin
	name = "login_master",
	slave = 8,
}

local server_list = {}
local slave_list = {}
local user_online = {}

local CMD = {}

function CMD.register_gate(name, addr)
	server_list[name] = addr
end

local balance = 1
local function accept(fd, ip)
	log("Accept connection(%d) from ip(%s).", fd, ip)
	local s = slave_list[balance]
	balance = balance + 1
	if balance > #slave_list then
		balance = 1
	end
	skynet.call(s, "lua", "handle", fd)
end

skynet.start(function()
	skynet.error("Login manager start")
	cluster.register("loginserver")
	
	skynet.dispatch("lua", function (sess, src, cmd, ...)
		local f = CMD[cmd]
		if f then
			if sess ~= 0 then
				skynet.ret(skynet.pack(f(...)))
			else
				f(...)
			end
		else
			log("Unknown loginserver command: %s.", cmd)
			skynet.response()(false)
		end
	end)

	local slave = server.slave or 8
	for i=1,slave do
		table.insert(slave_list, skynet.newservice("login_slave", i))
	end

	local ip = skynet.getenv("ip") or server.host
	local port = skynet.getenv("port") or server.port
	local fd = socket.listen(ip, port)
	socket.start(fd, accept)

	cluster.open("loginserver")
end)
