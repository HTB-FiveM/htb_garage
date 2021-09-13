function PlayerIdentifiers(serverId)
    -- local identifiers = {
    --     steam = "",
    --     ip = "",
    --     discord = "",
    --     license = "",
    --     license2 = "",
    --     xbl = "",
    --     live = ""
    -- }
    
    -- Sometimes license2: comes up so it's important to add the : suffix
    local idType = Config.PlayerIdentifierType .. ":"
    local identifier = nil

    -- Loop over all identifiers
    for k,id in pairs(GetPlayerIdentifiers(serverId)) do
      if string.match(id, idType) then
        identifier = id
        break
      end

        -- -- Convert it to a nice table.
        -- if string.find(id, "steam:") then
        --     identifiers.steam = id
        -- elseif string.find(id, "ip:") then
        --     identifiers.ip = id
        -- elseif string.find(id, "discord:") then
        --     identifiers.discord = id
        -- elseif string.find(id, "license:") then
        --     identifiers.license = id
        -- elseif string.find(id, "license2:") then
        --     identifiers.license2 = id
        -- elseif string.find(id, "xbl:") then
        --     identifiers.xbl = id
        -- elseif string.find(id, "live:") then
        --     identifiers.live = id
        -- end
    end

    -- return identifiers
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

