--[[----------------------------------------------------------------------------

  Application Name:
  IOLink

  Summary:
  Connecting and communicating to IO-Link device

  Description:
  This sample shows how to connect to an IO-Link device and write data.

  How to run:
  This sample can be run on any AppSpace device which can act as an IO-Link master,
  e.g. SIM family. The IO-Link device must be properly connected to a port which
  supports IO-Link. If the port is configured as IO-Link master, see script, the
  power LED blinks slowly. When a IO-Link device is successfully connected the
  LED blinks rapidly.

  More Information:
  See device manual of IO-Link master for according ports. See manual of IO-Link
  device for further IO-Link specific description and device specific commands.

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------

-- Enable power on S1 port, must be adapted if another port is used
-- luacheck: globals gPwr
gPwr = Connector.Power.create('S1')
gPwr:enable(true)

-- Creating IO-Link device handle for S1 port, must be adapted if another port is used
-- Now S1 port is configured as an IO-Link master.
local deviceHandle = IOLink.RemoteDevice.create('S1')

-- Creating timer to cyclicly read process data
local tmr = Timer.create()
tmr:setExpirationTime(1000)
tmr:setPeriodic(true)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

--@handleOnConnected()
local function handleOnConnected()
  print('IO-Link device connected')

  -- Reading product name and other product related data
  local productName = deviceHandle:getProductName()
  print('Product Name: ' .. productName)
  local productText = deviceHandle:readData(20, 0) -- index 20, Product Text
  print('Product Text: ' .. productText)
  local firmwareVersion = deviceHandle:readData(23, 0) -- index 23, Firmware Version
  print('Firmware Version: ' .. firmwareVersion)

  -- Writing and reading application specific tag, index 24
  -- The function calls also return a message whether the action was successful
  deviceHandle:writeData(24, 0, 'IOLink Sample Application')
  local applicationSpecificTag,
    returnRead = deviceHandle:readData(24, 0)
  print('Written application specific tag: ' .. applicationSpecificTag)
  print('Write Message: ' .. returnRead .. '; Read Message: ' .. returnRead)

  --Starting timer after successfull connection
  tmr:start()
end
IOLink.RemoteDevice.register(deviceHandle, 'OnConnected', handleOnConnected)

-- Stopping timer when IO-Link device gets disconnected
--@handleOnDisconnected()
local function handleOnDisconnected()
  tmr:stop()
  print('IO-Link device disconnected')
end
IOLink.RemoteDevice.register( deviceHandle, 'OnDisconnected', handleOnDisconnected )

--@handleOnPowerFault()
local function handleOnPowerFault()
  print('Power fault')
  tmr:stop()
end
IOLink.RemoteDevice.register(deviceHandle, 'OnPowerFault', handleOnPowerFault)

-- On every expiration of the timer, the process data is read
--@handleOnExpired()
local function handleOnExpired()
  -- Reading process data, needs to be adapted to the IO-Link device,
  -- see device manual for further information
  local data, dataValid = deviceHandle:readProcessData()
  print('Valid: ' .. dataValid .. '  Length: ' .. #data)
  if dataValid == 'PI_STATUS_VALID' then
    local QQ = string.byte(data, 2) & 0x03
    local Q2 = (QQ >> 0) & 0x01
    local Q1 = (QQ >> 1) & 0x01
    print('Q1 = ' .. Q1)
    print('Q2 = ' .. Q2)
  end
end
Timer.register(tmr, 'OnExpired', handleOnExpired)

--End of Function and Event Scope-----------------------------------------------
