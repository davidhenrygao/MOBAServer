local define = require "logic.module.player.define"
local player_battle_state_define = define.PLAYER_BATTLE_STATE

local battle_mgr = {}
local M = {}

function battle_mgr.new()
	local obj = setmetatable({}, {__index = M, })
	return obj
end

function M:init()
	self.state = player_battle_state_define.FREE
end

function M:is_free()
	return (self.state == player_battle_state_define.FREE)
end

function M:is_matching()
	return (self.state == player_battle_state_define.MATCHING)
end

function M:is_in_battle()
	return (self.state == player_battle_state_define.FIGHTING)
end

function M:set_free()
	self.state = player_battle_state_define.FREE
	self.battle_id = nil
end

function M:set_matching()
	self.state = player_battle_state_define.MATCHING
end

function M:set_in_battle(battle_id)
	self.state = player_battle_state_define.FIGHTING
	self.battle_id = assert(battle_id)
end

function M:get_battle_id()
	return assert(self.battle_id)
end

return battle_mgr
