local log  = require "log"

local utils = {}

local copytable
copytable = function (st)  
    local tab = {}  
    for k, v in pairs(st or {}) do  
        if type(v) ~= "table" then  
            tab[k] = v  
        else  
            tab[k] = copytable(v)  
        end  
    end  
    return tab  
end 
utils.copytable = copytable

local logtable
logtable = function (t, indent)
    indent = indent or "  "
    for name,val in pairs(t) do
        log("%sname: %s, val: %s", indent, name, val)
        if type(val) == "table" then
            logtable(val, indent .. "  ")
        end
    end
end
utils.logtable = logtable

return utils
