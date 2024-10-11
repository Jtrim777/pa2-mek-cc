local regbus = require("regbus")

local REGISTERS = {
    fuelLevel = 0,
    fuelCapacity = 0,
    coolantLevel = 0,
    coolantCapacity = 0,
    wasteLevel = 0,
    wasteCapacity = 0,
    steamLevel = 0,
    steamCapacity = 0,
    temperature = 0,
    active = false,
    burnRate = 0,
    fuelRate = 0
}

local Reactor = {}

function Reactor:new(name, pfSide, dbHost) 
    if not peripheral.hasType(pfSide, "fissionReactorLogicAdapter") then
        error("Peripheral on side " .. pfSide .. " is not a fissionReactorLogicAdapter")
    end

    control = peripheral.wrap(pfSide)
    db = regbus.init_bridge(dbHost)

    for k, iv in ipairs(REGISTERS) do 
        db.create_register(name .. "." .. k, iv, true)
    end

    db.create_register("fission_reactors", {}, true)

    local registry = db.read("fission_reactors")
    registry[name] = os.getComputerID()
    db.write("fission_reactors", registry)

    o = { 
        name = name,
        control = control,
        db = db
    }

    setmetatable(o, self)
    self.__index = self

    return o
end

function Reactor:syncState(tick, interval)
    state = {
        fuelLevel = self.control.getFuel().amount,
        fuelCapacity = self.control.getFuelCapacity(),

        coolantLevel = self.control.getCoolant().amount,
        coolantCapacity = self.control.getCoolantCapacity(),

        wasteLevel = self.control.getWaste().amount,
        wasteCapacity = self.control.getWasteCapacity(),

        steamLevel = self.control.getHeatedCoolant().amount,
        steamCapacity = self.control.getHeatedCoolantCapacity(),

        active = self.control.getStatus(),
        temperature = self.control.getTemperature() - 273,

        burnRate = self.control.getBurnRate()
    }
    local fuelRate = 0
    if self.last and interval then 
        local lastLevel = self.last.fuelLevel 
        local adj = active and (lastLevel + (state.burnRate * interval)) or lastLevel
        fuelRate = (state.fuelLevel - adj) / interval
    end
    state.fuelRate = fuelRate

    self.last = state

    for k, _ in ipairs(REGISTERS) do
        self.db.write(self.name .. "." .. k, state[k])
    end
end

return { Reactor = Reactor }
