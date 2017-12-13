local skynet = require "skynet"
local log = require "log"
local msgsender = require "msgsender"
local cmd = require "proto.cmd"
local retcode = require "logic.retcode"
local context = require "context"
local utils = require "luautils"

local card_mgr = require "logic.module.player.card_mgr"
local battle_mgr = require "logic.module.player.battle_mgr"
local define = require "logic.module.player.define"
local property_define = define.PROPERTY
local update_property_define = define.UPDATE_PROPERTY
local player_state_define = define.PLAYER_STATE

local account_lv_data = require "data.lua.AccountLVL"

local player_mgr = {}
local M = {}

function player_mgr.new()
	local object = {}
	setmetatable(object, { __index = M, })
	return object
end

function player_mgr.init_cfg_data()
	local data = {}
    local lv_data  = utils.copytable(account_lv_data)
	data.lv_data = lv_data
	return data
end

function M:init(uid)
	local db = skynet.queryservice("db")
	local err, player_basic_info = skynet.call(db, "lua", "launch_player_basic_info", uid)
	if err ~= retcode.SUCCESS then
		log("Launch player(%d) basic info failed!", uid)
		return err
	end
	self.basic_info = player_basic_info
	self.state = player_state_define.UNLAUNCH

	local card_info = card_mgr.new()
	err = card_info:init(uid)
	if err ~= retcode.SUCCESS then
		log("Launch player(%d) card info failed!", uid)
		return err
	end
	self.card_info = card_info

	self.battle_info = battle_mgr.new()
	self.battle_info:init()

	return retcode.SUCCESS
end

function M:save()
	local db = skynet.queryservice("db")
	skynet.call(db, "lua", "save_player_basic_info", self.basic_info)
	local id = self.basic_info.id
	self.card_info:save(id)
end

function M:get_basic_info()
	return self.basic_info
end

function M:get_card_set()
	return self.card_info:get_card_set()
end

function M:get_card_deck()
	return self.card_info:get_card_deck()
end

function M:get_cur_card_deck_info()
	return self.card_info:get_cur_card_deck_info()
end

function M:is_exist(id)
	if self.cardsbyid[id] ~= nil then
		return true
	end
	return false
end

function M:get_gold()
	return self.basic_info.gold
end

function M:get_id()
	return self.basic_info.id
end

function M:get_level()
	return self.basic_info.level
end

function M:get_name()
	return self.basic_info.name
end

function M:get_player_state()
	return self.state
end

function M:set_player_state(state)
	assert(state)
	self.state = state
end

function M:get_player_battle_info()
	return self.battle_info
end

function M:modify_props(props)
	local update_props = {}
	local update_prop
	for _,prop in ipairs(props) do
		repeat
			if assert(prop.ptype) == property_define.LEVEL then
				update_prop = self:set_level(assert(prop.val))
				break
			end
			if assert(prop.ptype) == property_define.EXP then
				update_prop = self:add_exp(assert(prop.val))
				break
			end
			if assert(prop.ptype) == property_define.GOLD then
				update_prop = self:modify_gold(assert(prop.op), assert(prop.val))
				break
			end
		until true
		if update_prop ~= nil then
			table.insert(update_props, update_prop)
			update_prop = nil
		end
	end

    local s2c_update_player_property = {
        props = update_props,
    }
    msgsender:push(cmd.UPDATE_PLAYER_PROPERTYS, 
		"protocol.s2c_update_player_property", s2c_update_player_property)
end

local function gen_update_prop(utype, ...)
	local property  = {
		key = utype,
		vals = {},
	}
	assert(select('#', ...) > 0)
	for idx,arg in pairs({...}) do
		local val = {
			value = assert(arg),
			pos = idx,
		}
		table.insert(property.vals, val)
	end
	return property
end

function M:set_level(lv)
	assert(lv and type(lv) == "number" and lv > 0)
	local cfg_data = context:get_cfg_data()
	local player_lv_data = assert(cfg_data.player_lv_data)
	local max_lv = #player_lv_data
	if lv > max_lv then
		lv = max_lv
	end
	self.basic_info.level = lv
	self.basic_info.exp = 0
	return gen_update_prop(update_property_define.LV_EXP, lv, 0)
end

local function unlock_cards(card_set, orig_lv, lv_up)
	local cfg_data = context:get_cfg_data()
	local card_unlock_cfg_data = cfg_data.card_unlock_cfg_data
	local unlock_list = {}
	--log("orig_lv: %d, lv_up: %d.", orig_lv, lv_up)
	for i=1,lv_up do
		local lv_unlock_cards_data = card_unlock_cfg_data[orig_lv+i] or {}
		for _,card_data in ipairs(lv_unlock_cards_data) do
			local id = card_data.Id
			if card_set:is_exist(id) == false then
				table.insert(unlock_list, id)
			end
		end
	end
	--log("#unlock_list : %d.", #unlock_list)
	--utils.logtable(unlock_list)
	if #unlock_list > 0 then
		card_set:unlock_cards(unlock_list)
	end
end

function M:add_exp(exp)
	assert(exp and type(exp) == "number" and exp > 0)
	local cfg_data = context:get_cfg_data()
	local player_lv_data = assert(cfg_data.player_lv_data)
	local cur_level = self.basic_info.level
	local cur_exp = self.basic_info.exp
	local max_lv = #player_lv_data
	local lv_up = 0
	local add_exp_left = exp
	local lv_data
	while add_exp_left > 0 do
		if cur_level >= max_lv then
			cur_exp = cur_exp + add_exp_left
			break
		end
		lv_data = player_lv_data[cur_level + 1]
		if cur_exp + add_exp_left >= lv_data["exp"] then
			add_exp_left = cur_exp + add_exp_left - lv_data["exp"]
			cur_exp = 0
			cur_level = cur_level + 1
			lv_up = lv_up + 1
		else
			cur_exp = cur_exp + add_exp_left
			add_exp_left = 0
		end
	end
	if lv_up > 0 then
		unlock_cards(self:get_card_set(), self.basic_info.level, lv_up)
		self.basic_info.level = cur_level
	end
	self.basic_info.exp = cur_exp
	return gen_update_prop(update_property_define.LV_EXP, cur_level, cur_exp)
end

function M:modify_gold(op, gold)
	assert(op and type(op) == "string" and (op == "add" or op == "sub"))
	assert(gold and type(gold) == "number" and gold > 0)
	local cur_gold = self.basic_info.gold
	if op == "sub" then
		assert(cur_gold >= gold)
		cur_gold = cur_gold - gold
	end
	if op == "add" then
		cur_gold = cur_gold + gold
	end
	self.basic_info.gold = cur_gold
	return gen_update_prop(update_property_define.GOLD, cur_gold)
end

function M:clean_battle_info()
	if self.state == player_state_define.BATTLE then
		if self.battle_info:is_matching() then
			local matchserver = skynet.localname(".matchserver")
			skynet.send(matchserver, "lua", "cancel_match_force", 
				self:get_id())
		end
		self.battle_info:set_free()
	end
	self.state = player_state_define.NORMAL
end

return player_mgr
