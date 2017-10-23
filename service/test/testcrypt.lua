local skynet = require "skynet"
require "skynet.manager"
local log = require "log"
local crypt = require "skynet.crypt"

local function strtohex(str)
	local len = str:len()
	local fmt = "0X"
	for i=1,len do
		fmt = fmt .. string.format("%02x", str:byte(i))
	end
	return fmt
end
skynet.start(function()
	skynet.error("crypt test start")
	if not skynet.getenv "daemon" then
		skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)

	local challenge = "!@#$%^&*"
	local clientkey = "12345678"
	local serverkey = "abcdefgh"

	log("challenge: %s.", challenge)
	log("clientkey: %s.", clientkey)
	log("serverkey: %s.", serverkey)
	log("base64(challenge): %s.", crypt.base64encode(challenge))
	log("base64(clientkey): %s.", crypt.base64encode(clientkey))
	log("base64(serverkey): %s.", crypt.base64encode(serverkey))

	local exck = crypt.dhexchange(clientkey)
	local exsk = crypt.dhexchange(serverkey)
	log("dhexchange(clientkey): %s.", strtohex(exck))
	log("dhexchange(serverkey): %s.", strtohex(exsk))

	local secret1 = crypt.dhsecret(exsk, clientkey)
	local secret2 = crypt.dhsecret(exck, serverkey)
	log("dhsecret(exsk, clientkey): %s.", strtohex(secret1))
	log("dhsecret(exck, serverkey): %s.", strtohex(secret2))
	local handshake_md5 = crypt.hmac64_md5(challenge, secret1)
	log("hmac64_md5(challenge, secret): %s.", strtohex(handshake_md5))

	local key = "abcdefghijklmn1234567890"
	log("key: %s.", key)
	log("hashkey(key): %s.", strtohex(crypt.hashkey(key)))

	local token = crypt.base64encode("david")
	local platform = crypt.base64encode("finyin")
	local tp = token .. "@" .. platform
	local etp = crypt.desencode(secret1, tp)
	log("base64(DES(secret, base64(token)+\"@\"+base64(platform))): %s.", 
		crypt.base64encode(etp))
	local dtp = crypt.desdecode(secret1, etp)
	log("DES(secret, etp) decode: %s.", dtp)

	skynet.exit()
end)
