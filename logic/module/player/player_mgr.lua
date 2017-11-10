local skynet = require "skynet"
local log = require "log"
local retcode = require "logic.retcode"

local card_mgr = require "logic.module.player.card_mgr"

local player_mgr = {}
local M = {}

function player_mgr.new()
	local object = {}
	setmetatable(object, { __index = M, })
	return object
end

function M:init(uid)
	local db = skynet.queryservice("db")
	local err, player_basic_info = skynet.call(db, "lua", "launch_player_basic_info", uid)
	if err ~= retcode.SUCCESS then
		log("Launch player(%d) basic info failed!", uid)
		return err
	end
	self.basic_info = player_basic_info

	local card_info = card_mgr.new()
	err = card_info:init(uid)
	if err ~= retcode.SUCCESS then
		log("Launch player(%d) card info failed!", uid)
		return err
	end
	self.card_info = card_info

	return retcode.SUCCESS
end

function M:save()
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

function M:is_exist(id)
	if self.cardsbyid[id] ~= nil then
		return true
	end
	return false
end

function M:unlock_card(id)
	
end

function M:add_card(id, amount)
	
end

return player_mgr
