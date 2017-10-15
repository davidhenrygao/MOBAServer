local skynet = require "skynet"
local socket = require "skynet.socket"
local log = require "log"

-- constant
local TIMER_INTERVAL = 500

local CMD = {}
local data = {}
local conns = {}

local function accept_cb(fd, ip)
    log("gate accept connection[%d] from ip[%s]", fd, ip)
    local conn = skynet.newservice("connection")
    skynet.call(conn, "lua", "start", {
	fd = fd,
	host = skynet.self(),
	dest = data.login,
    })
    conns[conn] = fd
end

local function timer_func()
    skynet.timeout(TIMER_INTERVAL, timer_func)
    for conn,_ in pairs(conns) do
        skynet.send(conn, "lua", "selfcheck")
    end
end

function CMD.start(conf)
    assert(conf and type(conf) == "table")
    assert(data.fd == nil, "gate already start")
    local ip = skynet.getenv("ip") or conf.ip or "127.0.0.1"
    local port = skynet.getenv("port") or conf.port or 10000
    data.fd = socket.listen(ip, port)
    data.ip = ip
    data.port = port
    socket.start(data.fd, accept_cb)
    skynet.timeout(TIMER_INTERVAL, timer_func)
    log("gate start: listen ip[%s]:port[%d]", ip, port)
end

function CMD.close_conn(conn_info)
    assert(conn_info and conn_info.conn)
    conns[conn_info.conn] = nil
end

skynet.init( function ()
    data.login = skynet.queryservice("login")
    skynet.queryservice("db")
end)

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
