local skynet = require "skynet"
require "skynet.manager"

skynet.start(function()
	skynet.error("FYServer start")
	--skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	skynet.uniqueservice("login")
	skynet.uniqueservice("db")
	local gate = skynet.newservice("gate")
	skynet.name(".gate", gate)
	skynet.call(gate, "lua", "start", {})
	skynet.exit()
end)
