function PlayerIdentifiers(serverId)
    -- Sometimes license2: comes up so it's important to add the : suffix
    local idPrefix = Config.PlayerIdentifierType .. ":"
    local identifier = nil

    -- Loop over all identifiers
    for k,id in pairs(GetPlayerIdentifiers(serverId)) do
      if string.match(id, idPrefix) then
        identifier = id
        break
      end

    end


    if Config.ExcludeIdentifierPrefix == true then
      identifier = identifier:gsub(idPrefix, "")
    end

    return identifier
end

--------------------------------------------
-- Binary Tree implementation from
-- https://exercism.io/tracks/lua/exercises/binary-search-tree/solutions/d50c611a3f264409aa778bad5b06cda2
-- Adapted to do the sorting based on a root 'key' so 
-- that more complex data can be included 
--------------------------------------------
function NewBinaryTree(firstItem)
    local BinarySearchTree = {}
    BinarySearchTree.__index = BinarySearchTree
  
    function BinarySearchTree:new(value)
      return setmetatable({ value = value }, self)
    end
  
    function BinarySearchTree:insert(value)
      local hand = value.key > self.value.key and 'right' or 'left'
  
      if self[hand] then return self[hand]:insert(value) end
  
      self[hand] = BinarySearchTree:new(value)
    end
  
    function BinarySearchTree:from_list(list)
      assert(#list > 0, 'list must contain at least 1 element')
  
      local tree = BinarySearchTree:new(list[1])
      for i = 2, #list do tree:insert(list[i]) end
  
      return tree
    end
  
    function BinarySearchTree:values()
      return coroutine.wrap(function()
        if self.left then
          for value in self.left:values() do coroutine.yield(value) end
        end
  
        coroutine.yield(self.value)
  
        if self.right then
          for value in self.right:values() do coroutine.yield(value) end
        end
      end)
    end
  
    return BinarySearchTree:new(firstItem)
  end

function GetGameTimePlus(n)
  -- fetch current in‑game time
  local h = GetClockHours()
  local m = GetClockMinutes()
  local s = GetClockSeconds()

  -- total seconds since midnight
  local currentSec = h * 3600 + m * 60 + s
  local addSec     = math.floor(n * 3600)
  local totalSec   = currentSec + addSec

  -- compute overflow days and wrap‑around seconds
  local dayOverflow = math.floor(totalSec / (24 * 3600))
  local wrapSec     = totalSec % (24 * 3600)

  -- convert back to h:m:s
  local newH = math.floor(wrapSec / 3600)
  local newM = math.floor((wrapSec % 3600) / 60)
  local newS = wrapSec % 60

  return {
      hours       = newH,
      minutes     = newM,
      seconds     = newS,
      dayOverflow = dayOverflow,  -- how many days you rolled past
  }
end
