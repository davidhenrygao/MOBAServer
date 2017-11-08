local log = require "log"
local retcode = require "logic.retcode"

local card_set_mgr = require "logic.libs.player.card_mgr.card_set_mgr"
local card_deck_mgr = require "logic.libs.player.card_mgr.card_deck_mgr"

local card_mgr = {}
local M = {}

function card_mgr:new()
	local object = {}
	setmetatable(object, { __index = M, })
	return object
end

function M:init(uid)
	local card_set = card_set_mgr:new()
	local err = card_set:init(uid)
	if err ~= retcode.SUCCESS then
		log("Player(%d) card set init failed: err(%d)!", uid, err)
		return err
	end
	local card_deck = card_deck_mgr:new()
	err = card_deck:init(uid)
	if err ~= retcode.SUCCESS then
		log("Player(%d) card deck init failed: err(%d)!", uid, err)
		return err
	end
	self.card_set = card_set
	self.card_deck = card_deck
	return retcode.SUCCESS
end

function M:save()
	self.card_set:save()
	self.card_deck:save()
end

function M:get_card_set()
	return self.card_set
end

function M:get_card_deck()
	return self.card_deck
end

return card_mgr
