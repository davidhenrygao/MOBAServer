local skynet = require "skynet"
local log = require "log"
local retcode = require "logic.retcode"

local M = {}

function M:new()
	local object = {}
	setmetatable(object, { __index = self, })
	return object
end

function M:init(uid)
	local db = skynet.queryservice("db")
	local err, player_card_info = skynet.call(db, "lua", "launch_player_card_info", uid)
	if err ~= retcode.SUCCESS then
		log("Launch player(%d) card info failed!", uid)
		return err
	end
	self.cards = player_card_info.cards
	self.card_decks = player_card_info.card_decks
	return retcode.SUCCESS
end

function M:save()
	
end

function M:get_cards()
	return self.cards
end

function M:get_card_decks()
	return self.card_decks
end

return M
