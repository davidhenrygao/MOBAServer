local skynet = require "skynet"
local log = require "log"
local retcode = require "logic.retcode"

local card_deck_mgr = {}
local M = {}

function card_deck_mgr.new()
	local object = {}
	setmetatable(object, { __index = M, })
	return object
end

function M:init(uid)
	local db = skynet.queryservice("db")
	local err, player_card_decks = skynet.call(db, "lua", "launch_player_card_decks", uid)
	if err ~= retcode.SUCCESS then
		log("Launch db player(%d) card set failed!", uid)
		return err
	end
	self.cur_deck_index = player_card_decks.cur_deck_index
	self.decks = {}
	for _,deck in ipairs(player_card_decks.decks) do
		local d = {
			index = deck.index,
			elems = {},
		}
		for _,elem in pairs(deck.elems) do
			local e = {
				id = elem.id,
				pos = elem.pos,
			}
			d.elems[elem.pos] = e
		end
		self.decks[deck.index] = d
	end
	return retcode.SUCCESS
end

function M:save()
	
end

function M:get_current_deck_index()
	return self.cur_deck_index
end

function M:get_decks()
	return self.decks
end

function M:check_deck_index(index)
	if index <= 0 or index > 3  then
		return false
	end
	return true
end

function M:check_pos(pos)
	if pos < 1 or pos > 6 then
		return false
	end
	return true
end

function M:change_cur_deck(index)
	if self:check_deck_index(index) then
		self.cur_deck_index = index
	end
end

function M:change_card_deck(index, id, pos)
	if index == 0 then
		index = self.cur_deck_index
	end
	if self:check_deck_index(index) == false then
		return retcode.CARD_DECK_INDEX_ILLEGAL
	end
	if self:check_pos(pos) == false then
		return retcode.CARD_DECK_POS_ILLEGAL
	end

	local deck = self.decks[index]
	for p,elem in pairs(deck.elems) do
		if elem.id == id then
			return retcode.CARD_ALREADY_IN_CARD_DECK
		end
	end
	local e = deck.elems[pos]
	e.id = id

	local change_info = {
		id = id,
		pos = pos,
		card_deck_index = index,
	}
	return retcode.SUCCESS, change_info
end

return card_deck_mgr
