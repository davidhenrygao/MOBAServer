local skynet = require "skynet"
local log = require "log"
local retcode = require "logic.retcode"
local cmd = require "proto.cmd"

local card = require "logic.module.player.card_mgr.card"

local msgsender = require "msgsender"

local card_set_mgr = {}
local M = {}

function card_set_mgr.new()
	local object = {}
	setmetatable(object, { __index = M, })
	return object
end

function M:init(uid)
	local db = skynet.queryservice("db")
	local err, player_cards = skynet.call(db, "lua", "launch_player_cards", uid)
	if err ~= retcode.SUCCESS then
		log("Launch db player(%d) card set failed!", uid)
		return err
	end
	self.cards = {}
	self.cardsbyid = {}
	for _,c in ipairs(player_cards) do
		local card_obj = card.new()
		card_obj:init(c)
        self:insert_obj(card_obj)
	end
	return retcode.SUCCESS
end

function M:insert_obj(card_obj)
    assert(card_obj)
    table.insert(self.cards, card_obj)
    self.cardsbyid[card_obj:get_id()] = card_obj
end

function M:save()
	
end

function M:size()
	return #(self.cards)
end

function M:iterator(begin)
	local b = begin or 1
	local f = function (cards, idx)
		if idx > #cards then
			return nil
		end
		local c = cards[idx]
		idx = idx + 1
		return idx, c
	end
	return f, self.cards, b
end

local function update_cards_to_client(card_objs)
    local s2c_update_cards = {
        cards = {},
    }
    for _,card_obj in pairs(card_objs) do
        local update_card_info = card_obj:get_update_info()
        table.insert(s2c_update_cards.cards, update_card_info)
    end
    msgsender:push(cmd.UPDATE_CARDS, "protocol.update_cards", s2c_update_cards)
end

function M:up_card_level(id, up_level, need_amount)
    local card_obj = assert(self.cardsbyid[id])
    local lv = card_obj:get_level()
    local amount = card_obj:get_amount()
    assert(amount >= need_amount)
    card_obj:set_level(lv + up_level)
    card_obj:set_amount(amount - need_amount)
    card_obj:set_mod()

    update_cards_to_client({card_obj})

	local up_level_info = {
        id = id,
        org_level = lv,
        up_level = up_level,
    }
	return up_level_info
end

function M:check_card(id)
	local card_obj = assert(self.cardsbyid[id])
	if card_obj:is_new() == false then
		return retcode.CARD_STATE_IS_NOT_NEW
	end
	card_obj:set_checked()
	card_obj:set_mod()
	update_cards_to_client({card_obj})
	return retcode.SUCCESS
end

function M:is_exist(id)
    return self.cardsbyid[id] ~= nil
end

function M:unlock_cards(id_list)
	assert(id_list and type(id_list) == "table")
	local card_objs = {}
	for _,id in ipairs(id_list) do
		assert(id and type(id) == "number")
		local card_obj = card:new()
		card_obj:init_unlock(id)
		self:insert_obj(card_obj)
		table.insert(card_objs, card_obj)
	end
    update_cards_to_client(card_objs)
end

function M:add_cards(add_list)
	assert(add_list and type(add_list) == "table")
	local card_objs = {}
	for _,elem in ipairs(add_list) do
		local id = assert(elem.id)
		local amount = assert(elem.amount)
		local card_obj = assert(self.cardsbyid[id])
		local orig_amount = card_obj:get_amount()
		card_obj:set_amount(orig_amount + amount)
		card_obj:set_mod()
		table.insert(card_objs, card_obj)
	end
    update_cards_to_client(card_objs)
end

return card_set_mgr
