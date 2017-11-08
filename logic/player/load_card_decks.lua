local cmd = require "proto.cmd"
--local log = require "log"

local function execute_f(req, resp_f)
	local player = req.player
	local card_deck = player:get_card_deck()

	local s2c_load_card_decks = {
		code = 0,
		current_index = card_deck:get_current_deck_index(),
		decks = {},
	}

	for _,deck in pairs(card_deck:get_decks()) do
		local d = {
			index = deck.index,
			elems = {},
		}
		for _,elem in pairs(deck.elems) do
			local e = {
				id = elem.id,
				pos = elem.pos,
			}
			table.insert(d.elems, e)
		end
		table.insert(s2c_load_card_decks.decks, d)
	end

	resp_f(s2c_load_card_decks)
end

return {
    cmd = cmd.LOAD_CARD_DECKS, 
    handler = execute_f,
	protoname = "protocol.c2s_load_card_decks",
	resp_protoname = "protocol.s2c_load_card_decks",
}
