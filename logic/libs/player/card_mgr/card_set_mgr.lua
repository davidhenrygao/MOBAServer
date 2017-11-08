local skynet = require "skynet"
local log = require "log"
local retcode = require "logic.retcode"

local card = require "logic.libs.player.card_mgr.card"

local card_set_mgr = {}
local M = {}

function card_set_mgr:new()
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
		local card_obj = card:new()
		card_obj:init(c)
		table.insert(self.cards, card_obj)
		self.cardsbyid[card_obj:get_id()] = card_obj
	end
	return retcode.SUCCESS
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

function M:up_card_level(id, up_level)
	local up_level_info = {}
	return retcode.SUCCESS, up_level_info
end

function M:check_card(id)
	return retcode.SUCCESS
end

return card_set_mgr
