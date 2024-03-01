SQL = {}

-----------------------------------------------------------------
-- Setup specific framework vesions of functions as a "Strategy"
-----------------------------------------------------------------
local ShowNotificationEsx = Strategy:new(function()
  print("ShowNotification from ESX")
end)

-- Concrete Strategy implementation for subtraction
local ShowNotificationQbCore = Strategy:new(function()
  print("ShowNotification from QB Core")
end)

local showNotificationMapping = {
  esx = ShowNotificationEsx,
  qb = ShowNotificationQbCore
}

-----------------------------------------------------------------------------------------
-- Setup strategies Context for the database calls to support the various frameworks
-----------------------------------------------------------------------------------------
local FrameworkContext = {}

function FrameworkContext:new(strategies)
  local o = setmetatable({}, self)
  self.__index = self
  o.strategies = strategies
  return o
end

function FrameworkContext:RunStartupStuff()
  self.strategies[GetFunctionName(2)].execute()
end

function FrameworkContext:GetAllPlayerNames()
  return self.strategies[GetFunctionName(2)].execute()
end

function FrameworkContext:GetPlayerIdentifierFromId(source)
  return self.strategies[GetFunctionName(2)].execute(source)
end

function FrameworkContext:MakePayment(source, account, amount)
  self.strategies[GetFunctionName(2)].execute(source, account, amount)
end

--------------------------------------
-- Wire up the framework functions
--------------------------------------
local mapping = {
  esx = EsxStrategy,
  qbcore = QBCoreStrategy
}

local fwFunctions = mapping[Config.RolePlayFramework]
FrameworkCtx = FrameworkContext:new(fwFunctions)
