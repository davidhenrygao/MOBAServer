local skynet = require "skynet"
local log = require "log"
local proto = require "protocol"
-- local retcode = require "logic.retcode"

local function response(source, pb, session, cmd, protoname)
    return function (resp)
		local ok, data = pcall(pb.encode, protoname, resp)
		if not ok then
			log("response protobuf encode error!")
			return
		end
		local r = proto.serialize(session, cmd, data)
		if not r then
			log("protocol serialization error!")
			return
		end
		skynet.send(source, "lua", "response", session, r)
    end
end

return response
