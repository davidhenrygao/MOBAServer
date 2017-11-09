local cmd = require "proto.cmd"
local cfg_data = require "logic.cfg_data"
local retcode = require "logic.retcode"

local function execute_f(req, resp_f)
	local player = req.player
	local card_set = player:get_card_set()

	local c2s_check_card = req.args
	local card_id = c2s_check_card.id

	local s2c_check_card = {
		code = 0,
	}

	local card_cfg_data = cfg_data.card_cfg_data[card_id]
	if card_cfg_data == nil then
		s2c_check_card.code = retcode.CARD_ID_NOT_EXIST
		resp_f(s2c_check_card)
		return
	end

	if card_set:is_exist(card_id) == false then
		s2c_check_card.code = retcode.CARD_IS_NOT_UNLOCK
		resp_f(s2c_check_card)
		return
	end

	s2c_check_card.code = card_set:check_card(card_id)

	resp_f(s2c_check_card)
end

return {
    cmd = cmd.CHECK_CARD, 
    handler = execute_f,
	protoname = "protocol.c2s_check_card",
	resp_protoname = "protocol.s2c_check_card",
}
