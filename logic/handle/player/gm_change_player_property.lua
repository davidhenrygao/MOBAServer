--local context = require "context"
local cmd = require "proto.cmd"
local retcode = require "logic.retcode"
local define = require "logic.module.player.define"
local property_define = define.PROPERTY
--local log = require "log"

local GM_OPCODE = {
	SET_LEVEL = 1,
	ADD_EXP = 2,
	MODIFY_GOLD = 3,

	EXCEED = 4,
}

local function extract_args(args)
	local array = {}
	for _,arg in ipairs(args) do
		array[arg.pos] = arg.value
	end
	return array
end

local function execute_f(req, resp_f)
	local player = req.player

	local c2s_gm_change_player_property = req.args
	local opcode = c2s_gm_change_player_property.opcode
	local args = extract_args(c2s_gm_change_player_property.args)

	local s2c_gm_change_player_property = {
		code = 0,
	}

	if opcode <= 0 or opcode >= GM_OPCODE.EXCEED then
		s2c_gm_change_player_property.code = retcode.GM_CHANGE_PLAYER_PROPETY_ERR_OPCODE
		resp_f(s2c_gm_change_player_property)
		return
	end

	local modify_props_tbl = {}

	if opcode == GM_OPCODE.SET_LEVEL then
		local level = args[1]
		if level <= 0 then
			s2c_gm_change_player_property.code = 
				retcode.GM_CHANGE_PLAYER_PROPETY_SET_LV_VAL_ERR
			resp_f(s2c_gm_change_player_property)
			return
		end
		local modify_prop = {
			ptype = property_define.LEVEL,
			val = level,
		}
		table.insert(modify_props_tbl, modify_prop)
	end

	if opcode == GM_OPCODE.ADD_EXP then
		local exp = args[1]
		if exp <= 0 then
			s2c_gm_change_player_property.code = 
				retcode.GM_CHANGE_PLAYER_PROPETY_ADD_EXP_VAL_ERR
			resp_f(s2c_gm_change_player_property)
			return
		end
		local modify_prop = {
			ptype = property_define.EXP,
			val = exp,
		}
		table.insert(modify_props_tbl, modify_prop)
	end

	if opcode == GM_OPCODE.MODIFY_GOLD then
		local gold = args[1]
		local op
		local cur_gold = player:get_gold()
		if gold > 0 then
			op = "add"
		else
			op = "sub"
			gold = 0 - gold
			if gold > cur_gold then
				gold = cur_gold
			end
		end
		local modify_prop = {
			ptype = property_define.GOLD,
			val = gold,
			op = op,
		}
		table.insert(modify_props_tbl, modify_prop)
	end

	player:modify_props(modify_props_tbl)
	resp_f(s2c_gm_change_player_property)
end

return {
	cmd = cmd.GM_CHANGE_PLAYER_PROPERTY, 
	handler = execute_f,
	protoname = "protocol.c2s_gm_change_player_property",
	resp_protoname = "protocol.s2c_gm_change_player_property",
}

