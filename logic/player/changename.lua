local skynet = require "skynet"
local retcode = require "logic.retcode"
local cmd = require "proto.cmd"

local function execute_f(req, resp_f)
    local dbservice = skynet.queryservice("db")
    local player = req.playerinfo
    local name = assert(req.args.name)
    local ret = skynet.call(dbservice, "lua", "changename", player.id, name)
    if ret ~= retcode.SUCCESS then
        resp_f(ret)
	return
    end
    player.name = name
    resp_f(retcode.SUCCESS)
end

return {
    cmd = cmd.CHANGENAME, 
    handler = execute_f,
}
