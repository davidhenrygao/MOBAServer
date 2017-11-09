local cmd = require "proto.cmd"

local function execute_f(req, resp_f)
	local player = req.player
	local card_deck = player:get_card_deck()

	local c2s_change_deck = req.args
	local index = c2s_change_deck.index

	local s2c_change_deck = {
		code = 0,
		index = index,
	}

	s2c_change_deck.code = card_deck:change_cur_deck(index)

	resp_f(s2c_change_deck)
end

return {
    cmd = cmd.CHANGE_DECK, 
    handler = execute_f,
	protoname = "protocol.c2s_change_deck",
	resp_protoname = "protocol.s2c_change_deck",
}
