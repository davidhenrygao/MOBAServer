local skynet = require "skynet"
require "skynet.manager"
local sharedata = require "skynet.sharedata"

local card_mgr = require "logic.module.player.card_mgr"

local log = require "log"

local CMD = {}

function CMD.load()
	local cfg_data = {}
	local card_cfg_data = card_mgr.init_cfg_data()
	cfg_data.card_cfg_data = card_cfg_data
	sharedata.new("cfg_data", cfg_data)
end

skynet.start(function()
	skynet.error("configure data loader start")
	
	skynet.dispatch("lua", function (sess, src, cmd, ...)
		local f = CMD[cmd]
		if f then
			if sess ~= 0 then
				skynet.ret(skynet.pack(f(...)))
			else
				f(...)
			end
		else
			log("Unknown configure data loader command: %s.", cmd)
			skynet.response()(false)
		end
	end)
end)
