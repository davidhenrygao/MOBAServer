local cmd = require "proto.cmd"

local function execute_f(req, resp_f)
	local player = req.player
	local card_set = player:get_card_set()
	local card_set_size = card_set:size()

	local s2c_load_cards = {
		code = 0,
	}

	local c2s_load_cards = assert(req.args)
	local begin_index = c2s_load_cards.begin_index
	local pagesz = c2s_load_cards.page_size
	if pagesz == 0 then
		pagesz = card_set_size
	end

	s2c_load_cards.cards = {}
	for _,card in card_set:iterator(begin_index) do
		local c = {
			id = card:get_id(),
			level = card:get_level(),
			amount = card:get_amount(),
			state = card:get_state(),
		}
		table.insert(s2c_load_cards.cards, c)
		pagesz = pagesz - 1
		if pagesz <= 0 then
			break
		end
	end

	resp_f(s2c_load_cards)
end

return {
    cmd = cmd.LOAD_CARDS, 
    handler = execute_f,
	protoname = "protocol.c2s_load_cards",
	resp_protoname = "protocol.s2c_load_cards",
}
