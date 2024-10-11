local rmod = require("lib/reactor")

rednet.open("right")

local reactor = rmod.Reactor:new("reactor1", "left", "database")

reactor:syncState(0)
