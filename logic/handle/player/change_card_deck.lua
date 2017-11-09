local cmd = require "proto.cmd"

local function execute_f(req, resp_f)
	local player = req.player
	local card_deck = player:get_card_deck()

	local c2s_change_card_deck = req.args
	local change_info = c2s_change_card_deck.change
	local card_id = change_info.id
	local pos = change_info.pos
	local deck_index = change_info.card_deck_index

	local s2c_change_card_deck = {
		code = 0,
	}

	s2c_change_card_deck.code, s2c_change_card_deck.change = card_deck:change_card_deck(
		deck_index, card_id, pos)

	resp_f(s2c_change_card_deck)
end

return {
    cmd = cmd.CHANGE_CARD_DECK, 
    handler = execute_f,
	protoname = "protocol.c2s_change_card_deck",
	resp_protoname = "protocol.s2c_change_card_deck",
}
