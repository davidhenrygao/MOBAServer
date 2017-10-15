local cjson = require "cjson"
local log = require "log"

local proto = {}

proto.serialize = function (code, resp)
    assert(code and type(code) == "number", 
	"serialization arg code is not a number, got" .. type(code))
    local tbl = {
	code = code, 
	body = resp,
    }
    local ok, ret = pcall(cjson.encode, tbl)
    if not ok then
	log("cjson encode error: %s", ret)
        return nil, ret
    end
    return ret
end

proto.unserialize = function (msg)
    assert(msg, "unserialization args is nil")
    local ok, ret = pcall(cjson.decode, msg)
    if not ok then
	log("cjson decode error: %s", ret)
	return nil, ret
    end
    -- TODO
    -- json validation
    return ret.code, ret.body
end

return proto
