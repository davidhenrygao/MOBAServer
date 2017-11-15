local log = require "log"
local context = require "context"
local cmd = require "proto.cmd"
local retcode = require "logic.retcode"
local define = require "logic.module.player.define"
local property_define = define.PROPERTY


local function cal_lv_up_relation(card_lv_cfg, card_lv, up_lv)
	assert(#card_lv_cfg >= card_lv + up_lv)
	local need_gold = 0
	local need_amount = 0
	local exp_award = 0

	for i=1,up_lv do
		local lv = card_lv + i
		local lv_prop = card_lv_cfg[lv]
		need_gold = need_gold + lv_prop["Consume"]
		need_amount = need_amount + lv_prop["CardAmount"]
		exp_award = exp_award + lv_prop["Exp"]
	end

	return need_gold, need_amount, exp_award
end

local function execute_f(req, resp_f)
	local cfg_data = context:get_cfg_data()
	local player = req.player
	local card_set = player:get_card_set()

	local c2s_up_card_level = req.args
	local card_id = c2s_up_card_level.id
	local up_level = c2s_up_card_level.up_level

	local s2c_up_card_level = {
		code = 0,
	}

	local card_cfg_data = cfg_data.card_cfg_data[card_id]
	if card_cfg_data == nil then
		s2c_up_card_level.code = retcode.CARD_ID_NOT_EXIST
		resp_f(s2c_up_card_level)
		return
	end

	local card = card_set:get_card(card_id)
	if card == nil then
		s2c_up_card_level.code = retcode.CARD_IS_NOT_UNLOCK
		resp_f(s2c_up_card_level)
		return
	end

	local card_lv = card:get_level()
	local final_lv = card_lv + up_level
	local lv_prop = card_cfg_data.prop_
	if final_lv > #lv_prop then
		s2c_up_card_level.code = retcode.CARD_LV_EXCEED_MAX_LV
		resp_f(s2c_up_card_level)
		return
	end

	local need_gold, need_amount, exp_award = cal_lv_up_relation(
		lv_prop, card_lv, up_level)

	if need_amount > card:get_amount() then
		s2c_up_card_level.code = retcode.CARD_LV_UP_AMOUNT_NOT_ENOUGH
		resp_f(s2c_up_card_level)
		return
	end

	-- check player's gold if enough
	log("need_gold(%d), need_amount(%d), exp_award(%d).", 
		need_gold, need_amount, exp_award)
	if need_gold > player:get_gold() then
		s2c_up_card_level.code = retcode.CARD_LV_UP_GOLD_NOT_ENOUGH
		resp_f(s2c_up_card_level)
		return
	end

	s2c_up_card_level.info = card_set:up_card_level(
		card_id, up_level, need_amount)

	resp_f(s2c_up_card_level)

	-- Consume gold and get exp
	local modify_props_tbl = {
		[1] = {
			ptype = property_define.GOLD,
			val = need_gold,
			op = "sub",
		},
		[2] = {
			ptype = property_define.EXP,
			val = exp_award,
		},
	}
	player:modify_props(modify_props_tbl)
end

return {
    cmd = cmd.UP_CARD_LEVEL, 
    handler = execute_f,
	protoname = "protocol.c2s_up_card_level",
	resp_protoname = "protocol.s2c_up_card_level",
}
