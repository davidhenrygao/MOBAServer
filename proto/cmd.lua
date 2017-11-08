--[[
-- This file define the cmd code between client and server.
--]]

local CMD = {
-- 0-99 common use
    HEARTBEAT = 1,
    ECHO = 2,
	LOGOUT = 3,

-- 100-199 login server use
    LOGIN_CHALLENGE = 100,
    LOGIN_EXCHANGEKEY= 101,
    LOGIN_HANDSHAKE = 102,
    LOGIN = 103,
    LOGIN_LAUNCH = 104,

-- 1000-1099 card module use
	LOAD_CARDS = 1000,
	LOAD_CARD_DECKS = 1001,
	UP_CARD_LEVEL = 1002,
	CHECK_CARD = 1003,
	CHANGE_DECK = 1004,
	CHANGE_CARD_DECK = 1005,
	UPDATE_CARDS = 1006,
	GM_GET_CARD = 1007,
}

return CMD
