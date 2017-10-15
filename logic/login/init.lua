local load_handlers = require "logic.utils.load_handlers"

local paths = {
    "login", 
    "common",
}
local handlers = load_handlers(paths)

return handlers
