local skynet = require "skynet"
local socket = require "skynet.socket"
local log = require "log"
local pb = require "protobuf"

-- constant

local CMD = {}
local data = {}
local conns = {}

local function accept_cb(fd, ip)
    log("testserver accept connection[%d] from ip[%s]", fd, ip)
    local conn = skynet.newservice("connection")
    skynet.call(conn, "lua", "start", {
	fd = fd,
	host = skynet.self(),
	dest = skynet.self(),
    })
    conns[conn] = fd
end

function CMD.start(conf)
    assert(conf and type(conf) == "table")
    assert(data.fd == nil, "testserver already start")
    local ip = skynet.getenv("ip") or conf.ip or "127.0.0.1"
    local port = skynet.getenv("port") or conf.port or 10000
    data.fd = socket.listen(ip, port)
    data.ip = ip
    data.port = port
    socket.start(data.fd, accept_cb)
    log("testserver start: listen ip[%s]:port[%d]", ip, port)
end

function CMD.close_conn(conn_info)
    assert(conn_info and conn_info.conn)
    log("testserver close connection[%d]", conn_info.conn)
    conns[conn_info.conn] = nil
end

local function msgUnpack(msg)
    local sess, cmd, len, checksum, pos = string.unpack(">i4 i4 i2 i4", msg)
    log("Receive msg, head info: session[%d], cmd[%d], len[%d], checksum[%s]", 
	sess, cmd, len, checksum)
    local req_data = string.sub(msg, pos)
    local msghead = {
	session = sess,
	cmd = cmd,
	len = len,
	checksum = checksum,
    }
    local req, err = pb.decode("test.Req", req_data)
    return msghead, req, err
end

local function handleRequest(cmd, req)
    log("%s login process.", req.account)
    local resp = {}
    if req.password ~= "fuck you" then
	log("password(%s) error.", req.password)
        resp.rc = 2
    else
	log("password(%s) correct.", req.password)
	resp.rc = 0
	resp.resp_body = {}
	if req.token ~= nil then
	    log("req.token(%s).", req.token)
	    resp.resp_body.secrect = "12345"
	end
	if req.msg ~= nil then
	    log("req.msg(%s).", req.msg)
	    resp.resp_body.msg_back = req.msg
	end
	if req.gameserver_id ~= nil then
	    log("req.gameserver_id(%d).", req.gameserver_id)
	    resp.resp_body.options = {10,9,8,7,6}
	end
	resp.infos = {}
	log("req.infos len: %d.", #req.infos)
	for idx,info in ipairs(req.infos) do
	    log("info[%d] major[%d] minor[%d].", idx, info.major, info.minor)
	    resp.infos[idx] = {
		major = info.major,
		minor = info.minor,
	    }
	end
    end
    return resp
end

local function msgPack(msghead, resp)
    local resp_data = pb.encode("test.Resp", resp) 
    msghead.len = string.len(resp_data)
    local head = string.pack(">i4 i4 i2 i4", msghead.session, msghead.cmd, msghead.len, 
	msghead.checksum)
    local msg = head .. resp_data
    log("resp encode stream(%q).", msg)
    return msg
end

function CMD.dispatch(source, sess, msg)
    local msghead, req, err = msgUnpack(msg)
    local resp
    if err ~= nil then
	log("msgUnpack error: %s.", err)
	resp = {}
	resp.rc = 1
    else
	resp = handleRequest(msghead.cmd, req)
    end
    local retmsg = msgPack(msghead, resp)
    skynet.call(source, "lua", "response", sess, retmsg)
end

skynet.init( function ()
    local import_pbfile = skynet.getenv("root") .. "proto/common/extrainfo.pb"
    local pbfile = skynet.getenv("root") .. "proto/test/test.pb"
    pb.register_file(import_pbfile)
    pb.register_file(pbfile)
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
