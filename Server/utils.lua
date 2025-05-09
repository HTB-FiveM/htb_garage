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

--- Checks whether a given model hash represents an imported (add-on) vehicle.
-- @param modelHash number|string The vehicle model hash (numeric or hex string, e.g. 0xB779A091 or "0xB779A091")
-- @return boolean true if it's a valid vehicle not in the base game/CD image (i.e. an add-on), false otherwise
function IsImportVehicle(modelHash)
  -- allow passing hex string too
  local hash = tonumber(modelHash) or tonumber(modelHash, 16)
  if not hash then
      return false
  end

  -- must be a valid model
  if not IsModelValid(hash) then
      return false
  end

  -- must be a vehicle
  if not IsModelAVehicle(hash) then
      return false
  end

  -- if it's NOT in the game’s CD image, it's an add-on/import
  return not IsModelInCdimage(hash)
end
  