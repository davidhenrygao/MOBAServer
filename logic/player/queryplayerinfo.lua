local skynet = require "skynet"
local retcode = require "logic.retcode"
local cmd = require "proto.cmd"

local function execute_f(req, resp_f)
    local dbservice = skynet.queryservice("db")
    local player = req.playerinfo
    local ret, playerinfo = skynet.call(dbservice, "lua", "query_player_info", player.id)
    if ret ~= retcode.SUCCESS then
        resp_f(ret)
	return
    end
    resp_f(retcode.SUCCESS, playerinfo)
end

return {
    cmd = cmd.GETPLAYERINFO, 
    handler = execute_f,
}
