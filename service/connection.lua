local skynet = require "skynet"
local socket = require "skynet.socket"
local log = require "log"
local netpackage = require "netpackage"

-- constant
local STATE = {
    INIT = 1,
    LOGIN = 2,
    DISCONNECT = 3,
}
local TIMEOUT = {
    INIT = 30,
    LOGIN = 30,
}

local CMD = {}
local data = {}

local function main_loop()
    local ok
    local msg
    local session = 0
    while true do
        ok, msg = netpackage.read(data.fd)
	if not ok then
	    log("netpackage read failed: connection[%d] aborted.", data.fd)
	    socket.close(data.fd)
	    break
	end
	data.time = skynet.time()
	session = session + 1
	skynet.send(data.dest, "lua", "dispatch", skynet.self(), session, msg)
    end
    skynet.call(data.host, "lua", "close_conn", {
	conn = skynet.self(),
    })
    socket.close(data.fd)
    skynet.exit()
end

local function init_state_selfcheck()
    local interval = skynet.time() - data.time
    if interval > TIMEOUT.INIT then
	log("fd[%d] connection init timeout[%d].", data.fd, interval)
        skynet.call(data.host, "lua", "close_conn", {
	    conn = skynet.self(),
	})
	socket.close(data.fd)
    end
end

local function login_state_selfcheck()
    -- TODO
end

function CMD.start(conf)
    assert(conf and conf.fd and conf.host and conf.dest, 
	"connection start function's arguments error")
    data.fd = conf.fd
    data.host = conf.host
    data.dest = conf.dest
    data.state = STATE.INIT
    data.time = skynet.time()

    socket.start(data.fd)
    skynet.fork(main_loop)
end

function CMD.selfcheck()
    if data.state == STATE.INIT then
        init_state_selfcheck()
    end
    if data.state == STATE.LOGIN then
        login_state_selfcheck()
    end
end

function CMD.response(sess, resp)
    assert(type(resp) == "string", 
        "CMD.response got resp is not json string!")
    log("session[%d] response json string[%s].", sess, resp)
    netpackage.write(data.fd, resp)
end

function CMD.change_dest(dest)
    log("change_dest from [%d] to [%d].", data.dest, dest)
    data.dest = dest
end

skynet.start( function ()
    skynet.dispatch("lua", function (session, _, cmd, ...)
        local func = CMD[cmd]
	if func then
	    if session == 0 then
	        func(...)
	    else
		skynet.ret(skynet.pack(func(...)))
	    end
	else
	    log("Unknown connection Command : [%s]", cmd)
	    skynet.response()(false)
	end
    end)
end)
