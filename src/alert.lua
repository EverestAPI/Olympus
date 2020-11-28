
local alert = {}


function alert.show()

end


local mtAlert = {
    __call = alert.show
}

setmetatable(alert, mtAlert)

return alert
