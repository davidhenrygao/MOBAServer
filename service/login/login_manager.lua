local skynet = require "skynet"
local socket = require "skynet.socket"
local cluster = require "skynet.cluster"
require "skynet.manager"
local crypt = require "skynet.crypt"

local server = {
	host = "127.0.0.1",
	port = 8001,
	multilogin = false,	-- disallow multilogin
	name = "login_master",
}

local server_list = {}
local user_online = {}

skynet.start(function()
	skynet.error("Login manager start")
	cluster.register("loginserver")

	cluster.open("loginserver")
end)
