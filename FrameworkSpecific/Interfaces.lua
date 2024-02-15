Strategy = {
  execute = nil
}

-- Strategy interface
function Strategy:new(strategyFunction)
  local newObj = {}
  setmetatable(newObj, self)
  self.__index = self
  newObj.execute = strategyFunction
  
  return newObj
end