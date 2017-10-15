local skynet = require "skynet"
require "skynet.manager"

skynet.start(function()
	skynet.error("FYServer start")
	--skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	local testserver = skynet.newservice("testserver")
	skynet.name(".testserver", testserver)
	skynet.call(testserver, "lua", "start", {})
	skynet.exit()
end)
