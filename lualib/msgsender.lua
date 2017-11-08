local skynet = require "skynet"
local log = require "log"
local proto = require "protocol"

local msgsender = {}

function msgsender:set_dest(dest)
	self.source = dest
end

function msgsender:set_pb(pb)
	self.pb = pb
end

function msgsender:response(session, cmd, protoname, resp)
	local pb = assert(self.pb)
	local source = assert(self.source)
	local data = pb.encode(protoname, resp)
	local r = proto.serialize(session, cmd, data)
	if not r then
		log("protocol serialization error!")
		return
	end
	skynet.send(source, "lua", "response", session, r)
end

function msgsender:push(cmd, protoname, resp)
	local pb = assert(self.pb)
	local source = assert(self.source)
	local data = pb.encode(protoname, resp)
	local r = proto.serialize(0, cmd, data)
	if not r then
		log("protocol serialization error!")
		return
	end
	skynet.send(source, "lua", "response", 0, r)
end

function msgsender:gen_respf(session, cmd, protoname)
	local pb = assert(self.pb)
	local source = assert(self.source)
    return function (resp)
        local data = pb.encode(protoname, resp)
		--[[
        local function strtohex(str)
            local len = str:len()
            local fmt = "0X"
            for i=1,len do
                fmt = fmt .. string.format("%02x", str:byte(i))
            end
            return fmt
        end
        log("response protobuf encode data: %s.", strtohex(data))
		--]]
        --[[
		local ok, data = pcall(pb.encode, protoname, resp)
		if not ok then
			log("response protobuf encode error!")
			return
		end
        --]]
		local r = proto.serialize(session, cmd, data)
		if not r then
			log("protocol serialization error!")
			return
		end
		skynet.send(source, "lua", "response", session, r)
    end
end

return msgsender
