reactor = peripheral.wrap("fissionReactorLogicAdapter_0")
matrix = peripheral.wrap("inductionPort_0")
screen = peripheral.wrap("top")

term.redirect(screen)
screen.setTextScale(0.5)

function updateDisplay()
    reactorOn = reactor.getStatus()
    reactorFuelLevel = reactor.getFuel().amount 
    reactorFuelPercent = reactor.getFuelFilledPercentage()

    matrixLevel = matrix.getEnergy()
    matrixSourceRate = matrix.getLastInput()
    matrixSinkRate = matrix.getLastOutput()

    screen.setBackgroundColor(colors.black)
    screen.clear()
    screen.setCursorPos(1, 1)

    screen.setTextColor(colors.white)
    screen.write("Main Reactor is ")
    screen.setTextColor(reactorOn and colors.green or colors.red)
    screen.write(reactorOn and "ON  " or "OFF ")
    screen.setTextColor(colors.white)

    screen.setCursorPos(1, 2)
    screen.write("Fuel ")

    fuelBoxes = reactorFuelPercent * 10
    paintutils.drawFilledBox(6, 2, 6 + fuelBoxes, 2, colors.orange)
    screen.setBackgroundColor(colors.black)
    paintutils.drawBox(6 + fuelBoxes + 1, 2, 16, 2, colors.orange)
    screen.setBackgroundColor(colors.black)
    screen.setCursorPos(17, 2)
    screen.write(("%.2f B"):format(reactorFuelLevel/1000.0))
end

while true do 
    updateDisplay()
    os.sleep(0.5)
end

