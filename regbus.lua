
local regbus = {}

function regbus.init_host(name) 
    local host = {
        name = name
    }

    local registers = {}
    host.registers = registers

    local artificialRegisters = {}
    host.artificialRegisters = artificialRegisters

    local hooks = {}
    host.hooks = hooks

    function host.read(rname)
        if registers[rname] then
            return registers[rname]
        end

        if artificialRegisters[rname] then
            return artificialRegisters[rname]()
        end

        return nil
    end
    
    function host.write(rname, value)    
        local og = registers[rname]
        registers[rname] = value
    
        return og
    end

    function host.setupDNS()
        rednet.host("regbus", host.name)
    end

    function host.createRegister(rname, init)
        if registers[rname] or artificialRegisters[rname] then
            error("register already exists")
        end

        if init == nil then
            error("cannot set register to nil")
        end

        registers[rname] = init
    end

    function host.createArtificialRegister(rname, gen)
        if registers[rname] or artificialRegisters[rname] then
            error("register already exists")
        end

        artificialRegisters[rname] = gen
    end

    function host.hook(rname, fn)
        if hooks[rname] then
            cch = hooks[rname]
            function nhook(v, ov)
                cch(v, ov)
                fn(v, ov)
            end
            hooks[rname] = nhook
        else
            hooks[rname] = fn
        end
    end

    function host.on_rcv(sender, message)
        local response = { success = true }

        if message.cmd == "READ" then 
            if registers[message.register] then 
                response.value = registers[message.register]
            elseif artificialRegisters[message.register] then 
                response.value = artificialRegisters[message.register]()
                response.generated = true 
            else
                response.success = false
                response.error = "No such register with name " .. message.register 
            end
        elseif message.cmd == "WRITE" then 
            if registers[message.register] then
                if message.value == nil then 
                    response.success = false
                    response.error = "Cannot write nil to a register"
                else 
                    response.value = host.write(message.register, message.value)
                    
                    if hooks[message.register] then 
                        hooks[message.register](message.value, response.value)
                    end
                end
            else
                response.success = false
                response.error = "No writable register with name " .. message.register 
            end
        elseif message.cmd == "NEW" then
            if (registers[message.register] or artificialRegisters[message.register]) and not message.allowExists then 
                response.success = false 
                response.error = "Register with that name already exists"
            elseif message.value == nil then
                response.success = false 
                response.error = "Missing initial value for register"
            else 
                host.createRegister(message.register, message.value)
            end
        else 
            response.success = false
            response.error = "No such regbus command" .. message.cmd 
        end 
            
        rednet.send(sender, response, "regbus")
    end

    function host.listen()
        while true do
            local sender, message = rednet.receive("regbus")

            host.on_rcv(sender, message)
        end
    end

    return host
end

function regbus.init_bridge(hostname) 
    local bridge = {
        hostname = hostname
    }

    local cid = rednet.lookup("regbus", hostname)

    if not cid then 
        error("No registered regbus host with name " .. hostname)
    end 

    bridge.hostId = cid

    function bridge.read(rname)    
        rednet.send(bridge.hostId, { cmd = "READ", register = rname }, "regbus")
    
        local _, response = rednet.receive("regbus", 5)
    
        if not response then
            error("regbus host did not reply")
        end
    
        if not response.success then 
            error("regbus cmd failed with error: " .. response.error)
        end
    
        return response.value 
    end
    
    function bridge.write(rname, value, faf)
        rednet.send(bridge.hostId, { cmd = "WRITE", register = rname, value = value }, "regbus")
    
        if faf then
            return nil
        end
    
        local _, response = rednet.receive("regbus", 5)
    
        if not response then
            error("regbus host did not reply")
        end
    
        if not response.success then 
            error("regbus cmd failed with error: " .. response.error)
        end
    
        return response.value 
    end

    function bridge.create_register(rname, init, allowExists)
        rednet.send(bridge.hostId, { cmd = "NEW", register = rname, value = init, allowExists = allowExists }, "regbus")
    
        local _, response = rednet.receive("regbus", 5)
    
        if not response then
            error("regbus host did not reply")
        end
    
        if not response.success then 
            error("regbus cmd failed with error: " .. response.error)
        end
    
        return response.value 
    end

    return bridge
end

return regbus