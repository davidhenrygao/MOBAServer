local cmd = require "proto.cmd"

local function execute_f(req, resp_f)
	local player = req.player
	local card_set = player:get_card_set()

	local s2c_check_card = {
		code = 0,
	}

	local c2s_check_card = req.args
	local card_id = c2s_check_card.id

	s2c_check_card.code = card_set:check_card(card_id)

	resp_f(s2c_check_card)
end

return {
    cmd = cmd.CHECK_CARD, 
    handler = execute_f,
	protoname = "protocol.c2s_check_card",
	resp_protoname = "protocol.s2c_check_card",
}
