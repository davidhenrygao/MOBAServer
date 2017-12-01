local log = require "log"
local utils = require "luautils"
local retcode = require "logic.retcode"
local context = require "context"

local card_set_mgr = require "logic.module.player.card_mgr.card_set_mgr"
local card_deck_mgr = require "logic.module.player.card_mgr.card_deck_mgr"

local card_data = require "data.lua.Card"
local card_prop_data = require "data.lua.CardLv"

local card_mgr = {}
local M = {}

function card_mgr.new()
	local object = {}
	setmetatable(object, { __index = M, })
	return object
end

function card_mgr.init_cfg_data()
	local data = {}
    local card_cfg_data = utils.copytable(card_data)
    for _,prop in pairs(card_prop_data) do
        local id = prop.CardId
        local level = prop.Lv
        card_cfg_data[id].prop_ = card_cfg_data[id].prop_ or {}
        card_cfg_data[id].prop_[level] = utils.copytable(prop)
    end
	local card_unlock_cfg_data = {}
	for _,card in pairs(card_cfg_data) do
		local unlock_lv = card.UnLock
		card_unlock_cfg_data[unlock_lv] = card_unlock_cfg_data[unlock_lv] or {}
		table.insert(card_unlock_cfg_data[unlock_lv], card)
	end

	data.card_cfg_data = card_cfg_data
	data.card_unlock_cfg_data = card_unlock_cfg_data
	return data
end

function M:init(uid)
	local card_set = card_set_mgr.new()
	local err = card_set:init(uid)
	if err ~= retcode.SUCCESS then
		log("Player(%d) card set init failed: err(%d)!", uid, err)
		return err
	end
	local card_deck = card_deck_mgr.new()
	err = card_deck:init(uid)
	if err ~= retcode.SUCCESS then
		log("Player(%d) card deck init failed: err(%d)!", uid, err)
		return err
	end
	if card_set:size() == 0 then
		local cfg_data = context:get_cfg_data()
		local card_unlock_cfg_data = cfg_data.card_unlock_cfg_data
		local lv_unlock_cards_data = card_unlock_cfg_data[1] or {}
		local card_list = {}
		for _,data in ipairs(lv_unlock_cards_data) do
			table.insert(card_list, data.Id)
		end
		table.sort(card_list)
		card_set:create_init_cards(card_list)
		card_deck:create_init_decks(card_list)
	end
	self.card_set = card_set
	self.card_deck = card_deck
	return retcode.SUCCESS
end

function M:save(id)
	self.card_set:save(id)
	self.card_deck:save(id)
end

function M:get_card_set()
	return self.card_set
end

function M:get_card_deck()
	return self.card_deck
end

function M:get_cur_card_deck_info()
	local cur_card_deck_info = {}
	local cur_deck = self.get_cur_deck()
	assert(cur_deck)
	for _,elem in pairs(cur_deck.elems) do
		local card_id = elem.id
		local pos = elem.pos
		local card = self.card_set:get_card(card_id)
		local info = {
			id = card_id,
			level = card:get_level(),
			pos = pos,
		}
		table.insert(cur_card_deck_info, info)
	end
	return cur_card_deck_info
end

return card_mgr
