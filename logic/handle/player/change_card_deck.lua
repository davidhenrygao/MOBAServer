local context = require "context"
local cmd = require "proto.cmd"
local retcode = require "logic.retcode"

local function execute_f(req, resp_f)
	local cfg_data = context:get_cfg_data()
	local player = req.player
	local card_set = player:get_card_set()
	local card_deck = player:get_card_deck()

	local c2s_change_card_deck = req.args
	local change_info = c2s_change_card_deck.change
	local card_id = change_info.id
	local pos = change_info.pos
	local deck_index = change_info.card_deck_index

	local s2c_change_card_deck = {
		code = 0,
	}

	local card_cfg_data = cfg_data.card_cfg_data[card_id]
	if card_cfg_data == nil then
		s2c_change_card_deck.code = retcode.CARD_ID_NOT_EXIST
		resp_f(s2c_change_card_deck)
		return
	end

	local card = card_set:get_card(card_id)
	if card == nil then
		s2c_change_card_deck.code = retcode.CARD_IS_NOT_UNLOCK
		resp_f(s2c_change_card_deck)
		return
	end
	if card:is_unlock() then
		s2c_change_card_deck.code = retcode.CARD_IS_UNLOCK_STATE
		resp_f(s2c_change_card_deck)
		return
	end

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
