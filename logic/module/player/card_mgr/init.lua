local log = require "log"
local utils = require "luautils"
local retcode = require "logic.retcode"

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
    local card_cfg_data = utils.copytable(card_data)
    for _,prop in pairs(card_prop_data) do
        local id = prop.CardId
        local level = prop.Lv
        card_cfg_data[id].prop_ = card_cfg_data[id].prop_ or {}
        card_cfg_data[id].prop_[level] = utils.copytable(prop)
    end
	return card_cfg_data
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

return card_mgr
