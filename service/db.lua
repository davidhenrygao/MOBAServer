local skynet = require "skynet"
local redis = require "skynet.db.redis"
local log = require "log"
local retcode = require "logic.retcode"
local cjson = require "cjson"

local CMD = {}

local db
local ACCOUNT = "account"
local PLAYER = "player:"

local player_login = {}
local player_info = {}

local id_counter = 1

function CMD.login(account, passwd)
    if player_login[account] ~= nil then
        return retcode.SUCCESS, player_login[account]
    end
    local ret = db:hexists(ACCOUNT, account)
    local account_info
    local account_info_str
    local player
    local player_str
    local key
    if ret == 0 then
        -- register
	account_info = {
	    passwd = passwd, 
	    id = id_counter,
	}
	id_counter = id_counter + 1
	account_info_str = cjson.encode(account_info)
	ret = db:hset(ACCOUNT, account, account_info_str)
	if ret == 0 then
	    return retcode.REGISTER_DB_ERR
	end
	player = {
	    id = account_info.id, 
	    name = "player" .. tostring(os.time()),
	    level = 1,
	    gold = 0,
	    exp = 0,
	}
	player_str = cjson.encode(player)
	key = PLAYER .. tostring(account_info.id)
	ret = db:setnx(key, player_str)
	if ret == 0 then
	    return retcode.CREATE_PLAYER_DB_ERR
	end
    else
        -- login
	account_info_str = db:hget(ACCOUNT, account)
	account_info = cjson.decode(account_info_str)
	key = PLAYER .. string.format("%d", account_info.id)
	player_str = db:get(key)
	if player_str == nil then
	    return retcode.ACCOUNT_PLAYER_NOT_EXIST
	end
	player = cjson.decode(player_str)
    end
    if account_info.passwd ~= passwd then
	return retcode.WRONG_PASSWORD
    end
    player_login[account] = player
    player_info[player.id] = player
    return retcode.SUCCESS, player
end

function CMD.query_player_info(id)
    if player_info[id] == nil then
        return retcode.PLAYER_NOT_LOGIN
    end
    return retcode.SUCCESS, player_info[id]
end

function CMD.changename(id, name)
    if player_info[id] == nil then
        return retcode.PLAYER_NOT_LOGIN
    end
    player_info[id].name = name
    local player_str = cjson.encode(player_info[id])
    local key = PLAYER .. string.format("%d", id)
    local ret = db:set(key, player_str)
    if ret == nil then
        return retcode.CHANGE_PLAYER_NAME_DB_ERR
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
