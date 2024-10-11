local regbus = require("regbus")

rednet.open("right")
local host = regbus.init_host("database")
host.setupDNS()

host.listen()
