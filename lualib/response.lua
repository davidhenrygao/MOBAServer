local skynet = require "skynet"
local log = require "log"
local proto = require "protocol"
local retcode = require "logic.retcode"

local function response(source, session)
    return function (code, resp)
	assert(code, "response function's code can not be nil!")
	-- TODO
	-- check the resp validation.
	local r, errmsg = proto.serialize(code, resp)
	if not r then
	    log("protocol serialization error: %s", errmsg)
	    r = proto.serialize(retcode.INTERNAL)
	    assert(r, "fatal error in protocol serialization!")
	end
	skynet.send(source, "lua", "response", session, r)
    end
end

return response
