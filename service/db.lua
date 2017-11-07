local skynet = require "skynet"
local redis = require "skynet.db.redis"
local log = require "log"
local retcode = require "logic.retcode"
local cjson = require "cjson"

local CMD = {}

local db
local PLAYER = "player:"
local CARD = "card@"

local function createplayerdbcardsinfo(playerkey)
	local open_card_set = { 1001, 2001, 3001, 4001, 1002, 2002, 3002, 4002 }
	local unlock_card_set = { 1003, 2003, 3003, 4003 }
	local player_card_info = {
		cards = {},
		card_decks = {},
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
		table.insert(player_card_info.cards, card)
	end
	for _, card_id in ipairs(unlock_card_set) do
		local card = {
			id = card_id,
			level = 0,
			amount = 0,
			state = 0,
		}
		table.insert(player_card_info.cards, card)
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
		table.insert(player_card_info.card_decks, card_deck)
	end
	local key = CARD .. playerkey
	local card_info_str = cjson.encode(player_card_info)
	local ret = db:set(key, card_info_str)
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

	local player_basic_info = cjson.decode(player_str)

    return retcode.SUCCESS, player_basic_info
end

function CMD.launch_player_card_info(uid)
	local ret
	local key = PLAYER .. string.format("%d", uid)
	local player_card_info_str = db:get(CARD .. key)
	if player_card_info_str == nil then
		ret = createplayerdbcardsinfo(key)
		if ret ~= retcode.SUCCESS then
			return ret
		end
	end
	player_card_info_str = db:get(CARD .. key)

	local player_card_info = cjson.decode(player_card_info_str)

    return retcode.SUCCESS, player_card_info
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
