local cmd = require "proto.cmd"
--local log = require "log"

local function execute_f(req, resp_f)
	local player = req.player
	local card_set = player:get_card_set()

	local c2s_up_card_level = req.args
	local card_id = c2s_up_card_level.id
	local up_level = c2s_up_card_level.up_level

	local s2c_up_card_level = {
	}
	s2c_up_card_level.code, s2c_up_card_level.info = card_set:up_card_level(card_id, up_level)

	resp_f(s2c_up_card_level)
end

return {
    cmd = cmd.UP_CARD_LEVEL, 
    handler = execute_f,
	protoname = "protocol.c2s_up_card_level",
	resp_protoname = "protocol.s2c_up_card_level",
}
