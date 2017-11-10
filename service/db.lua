local skynet = require "skynet"
local redis = require "skynet.db.redis"
local log = require "log"
local retcode = require "logic.retcode"
local utils = require "luautils"

local CMD = {}

local db
local PLAYER = "player:"
local CARD = "card:"
local CARD_DECK = "card_deck:"

local function createplayerdbcardsinfo(playerkey)
	local open_card_set = { 1001, 2001, 3001, 4001, 1002, 2002, 3002, 4002 }
	local unlock_card_set = { 1003, 2003, 3003, 4003 }
	local cards = {}
	local card_decks = {
		cur_deck_index = 1,
		decks = {}
	}
	for idx, card_id in ipairs(open_card_set) do
		local card = {
			id = card_id,
			level = 1,
			amount = 1,
			state = 2,
		}
		if idx > 6 then
			card.state = 1
		end
		table.insert(cards, card)
	end
	for _, card_id in ipairs(unlock_card_set) do
		local card = {
			id = card_id,
			level = 1,
			amount = 0,
			state = 0,
		}
		table.insert(cards, card)
	end
	for i=1,3 do
		local card_deck = {
			index = i,
			elems = {},
		}
		for idx,card_id in ipairs(open_card_set) do
			if idx > 6 then
				break
			end
			local elem = {
				id = card_id,
				pos = idx,
			}
			table.insert(card_deck.elems, elem)
		end
		table.insert(card_decks.decks, card_deck)
	end
	local key = CARD .. playerkey
	local cards_str = utils.table_to_str(cards)
	local ret = db:set(key, cards_str)
	if ret == 0 then
		return retcode.CREATE_PLAYER_CARD_INFO_DB_ERR
	end
	key = CARD_DECK .. playerkey
	local card_decks_str = utils.table_to_str(card_decks)
	ret = db:set(key, card_decks_str)
	if ret == 0 then
		return retcode.CREATE_PLAYER_CARD_INFO_DB_ERR
	end
	return retcode.SUCCESS
end

function CMD.launch_player_basic_info(uid)
	local key = PLAYER .. string.format("%d", uid)
	local player_str = db:get(key)
	if player_str == nil then
	    return retcode.ACCOUNT_PLAYER_NOT_EXIST
	end

	local player_basic_info = utils.str_to_table(player_str)

    return retcode.SUCCESS, player_basic_info
end

function CMD.launch_player_cards(uid)
	local ret
	local key = string.format("%d", uid)
	local player_cards_str = db:get(CARD .. key)
	if player_cards_str == nil then
		ret = createplayerdbcardsinfo(key)
		if ret ~= retcode.SUCCESS then
			return ret
		end
	end
	player_cards_str = db:get(CARD .. key)

	local player_cards = utils.str_to_table(player_cards_str)

    return retcode.SUCCESS, player_cards
end

function CMD.launch_player_card_decks(uid)
	local ret
	local key = string.format("%d", uid)
	local player_card_decks_str = db:get(CARD_DECK .. key)
	if player_card_decks_str == nil then
		ret = createplayerdbcardsinfo(key)
		if ret ~= retcode.SUCCESS then
			return ret
		end
	end
	player_card_decks_str = db:get(CARD_DECK .. key)

	local player_card_decks = utils.str_to_table(player_card_decks_str)

    return retcode.SUCCESS, player_card_decks
end

function CMD.save_player_cards(uid, cards)
	local cards_str = utils.table_to_str(cards)
	local key = CARD .. tostring(uid)
	local ret = db:set(key, cards_str)
	if ret == 0 then
		log("save_player_cards failed: ret(%d).", ret)
	end
	return retcode.SUCCESS
end

function CMD.save_player_decks(uid, decks_info)
	local key = CARD_DECK .. tostring(uid)
	local card_decks_str = utils.table_to_str(decks_info)
	local ret = db:set(key, card_decks_str)
	if ret == 0 then
		log("save_player_decks failed: ret(%d).", ret)
	end
	return retcode.SUCCESS
end

skynet.init( function ()
	db = redis.connect {
		host = "127.0.0.1" ,
		port = 6379 ,
		db = 0 ,
	}
end)

skynet.start( function ()
    skynet.dispatch("lua", function (session, source, cmd, ...)
        local func = CMD[cmd]
	if func then
	    if session == 0 then
	        func(...)
	    else
		skynet.ret(skynet.pack(func(...)))
	    end
	else
	    log("Unknown db Command : [%s]", cmd)
	    skynet.response()(false)
	end
    end)
end)
