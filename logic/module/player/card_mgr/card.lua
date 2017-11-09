local skynet = require "skynet"
local log = require "log"
local retcode = require "logic.retcode"

local CARD_STATE = {
	UNLOCK = 0,
	NEW = 1,
	CHECKED = 2,
}
local CARD_CHANGE_STATE = {
	ORIG = 1,
	ADD = 2,
	MOD = 3,
}

local card = {}
local M = {}

function card.new()
	local object = {}
	setmetatable(object, { __index = M, })
	return object
end

function M:init(card_info)
	assert(card_info and type(card_info) == "table")
	self.id = card_info.id
	self.level = card_info.level
	self.amount = card_info.amount
	self.state = card_info.state
	self.cstate = CARD_CHANGE_STATE.ORIG
end

function M:init_unlock(id)
	self.id = id
	self.level = 1
	self.amount = 0
	self.state = CARD_STATE.UNLOCK
	self.cstate = CARD_CHANGE_STATE.ADD
end

function M:get_id()
	return self.id
end

function M:get_level()
	return self.level
end

function M:get_amount()
	return self.amount
end

function M:get_state()
	return self.state
end

function M:get_update_info()
    local update_info = {
        id = self.id,
        level = self.level,
        amount = self.level,
        state = self.state,
    }
    return update_info
end

function M:is_unlock()
	return self.state == CARD_STATE.UNLOCK
end

function M:is_new()
	return self.state == CARD_STATE.NEW
end

function M:is_checked()
	return self.state == CARD_STATE.CHECKED
end

function M:is_orig()
	return self.cstate == CARD_CHANGE_STATE.ORIG
end

function M:is_add()
	return self.cstate == CARD_CHANGE_STATE.ADD
end

function M:is_mod()
	return self.cstate == CARD_CHANGE_STATE.MOD
end

function M:set_level(lv)
	self.level = lv
end

function M:set_amount(n)
	self.amount = n
end

function M:set_unlock()
	self.state = CARD_STATE.UNLOCK
end

function M:set_new()
	self.state = CARD_STATE.NEW
end

function M:set_checked()
	self.state = CARD_STATE.CHECKED
end

function M:set_orig()
	self.cstate = CARD_CHANGE_STATE.ORIG
end

function M:set_add()
	self.cstate = CARD_CHANGE_STATE.ADD
end

function M:set_mod()
    if self.cstate ~= CARD_CHANGE_STATE.ADD then
        self.cstate = CARD_CHANGE_STATE.MOD
    end
end

return card
