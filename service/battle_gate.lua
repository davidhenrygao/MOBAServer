local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local log = require "log"

local CMD = {}
local data = {}
local conns = {}
local battleserver

local function accept_cb(fd, ip)
	log("battle_gate accept connection[%d] from ip[%s]", fd, ip)
	local conn = skynet.newservice("connection")
	skynet.call(conn, "lua", "start", {
		fd = fd,
		host = skynet.self(),
		dest = battleserver,
	})
	conns[conn] = fd
end

function CMD.start(conf)
    assert(conf and type(conf) == "table")
    assert(data.fd == nil, "battle gate already start")
    local ip = skynet.getenv("ip") or conf.ip or "127.0.0.1"
    local port = skynet.getenv("battle_gate_port") or conf.port or 10000
    data.fd = socket.listen(ip, port)
    data.ip = ip
    data.port = port

	battleserver = skynet.newservice("battle_server", ip, port)
	skynet.name(".battleserver", battleserver)

    socket.start(data.fd, accept_cb)
    log("battle gate start: listen ip[%s]:port[%d]", ip, port)
end

function CMD.close_conn(conn_info)
    assert(conn_info and conn_info.conn)
    conns[conn_info.conn] = nil
end

skynet.start( function ()
    skynet.dispatch("lua", function (_, _, cmd, ...)
        local func = CMD[cmd]
	if func then
	    skynet.ret(skynet.pack(func(...)))
	else
	    log("Unknown gate Command : [%s]", cmd)
	    skynet.response()(false)
	end
    end)
end)
