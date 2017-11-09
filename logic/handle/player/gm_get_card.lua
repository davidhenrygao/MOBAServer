local cmd = require "proto.cmd"
local cfg_data = require "logic.cfg_data"
local retcode = require "logic.retcode"
--local log = require "log"

local function execute_f(req, resp_f)
	local player = req.player
	local card_set = player:get_card_set()

	local c2s_gm_get_card = req.args
	local card_id = c2s_gm_get_card.id
	local amount = c2s_gm_get_card.amount

	local s2c_gm_get_card = {
		code = 0,
	}

	local card_cfg_data = cfg_data.card_cfg_data[card_id]
	if card_cfg_data == nil then
		s2c_gm_get_card.code = retcode.CARD_ID_NOT_EXIST
		resp_f(s2c_gm_get_card)
		return
	end

	local flag = card_set:is_exist(card_id)
	if flag == false then
		card_set:unlock_cards({card_id})
	end
	local add_list = {
		[1] = {
			id = card_id,
			amount = amount,
		},
	}
	card_set:add_cards(add_list)

	resp_f(s2c_gm_get_card)
end

return {
    cmd = cmd.GM_GET_CARD, 
    handler = execute_f,
	protoname = "protocol.c2s_gm_get_card",
	resp_protoname = "protocol.s2c_gm_get_card",
}
