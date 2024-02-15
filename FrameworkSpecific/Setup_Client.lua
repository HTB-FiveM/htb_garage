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

function FrameworkContext:RunStartupStuff(args)
  return self.strategies[GetFunctionName(2)].execute(args)
end

function FrameworkContext:ShowNotification(msg)
  return self.strategies[GetFunctionName(2)].execute(msg)
end

function FrameworkContext:GetPlayerData()
  return self.strategies[GetFunctionName(2)].execute()
end

--------------------------------------
-- Wire up the framework functions
--------------------------------------
local mapping = {
  esx = EsxStrategy,
  qbcore = QBCoreStrategy,
  none = NoneStrategy
}

local fwFunctions = mapping[Config.RolePlayFramework]
FrameworkCtx = FrameworkContext:new(fwFunctions)
