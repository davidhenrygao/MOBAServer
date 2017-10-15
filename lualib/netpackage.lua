local socket = require "skynet.socket"
local log = require "log"

-- constant
local PACKAGE_HEAD_LEN = 2
local MAX_PACKAGE_SIZE = 4096

local netpackage = {}

function netpackage.read(fd)
    local str = socket.read(fd, PACKAGE_HEAD_LEN)
    if not str then
        log("package socket[%d] read msg head error.", fd)
	return false
    end
    local len = string.unpack(">H", str)
    if len > MAX_PACKAGE_SIZE then
        log("package length[%d] exceed %d bytes.", len, MAX_PACKAGE_SIZE)
	return false
    end
    local msg = socket.read(fd, len)
    if not msg then
        log("package socket[%d] read msg body error.", fd)
	return false
    end
    return true, msg
end

function netpackage.write(fd, msg)
    local len = string.len(msg)
    local sendmsg = string.pack(">H", len) .. msg
    return socket.write(fd, sendmsg)
end

return netpackage
