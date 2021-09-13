function RunStartupStuffEsx(msg)
    -- NOTE: If not using legacy then comment out the '@es_extended/imports.lua' line in fxmanifest.lua
    --       Legacy provides a definition for ESX object so this should overwrite the global, but
    --       better to not let it load if not required
    if Config.UsingEsxLegacy == false then
        ESX = nil 
    
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
    end
end


function GetAllPlayerNamesEsx()
    -- If you don't have this function in your es_extended, add it. I won't accomodate for
    -- not having this as without it there's MAJOR potential for server killing. Find it in ESX Legacy
    local xPlayers = ESX.GetExtendedPlayers()
    local playerNames = {}
    for _, playerIdStr in pairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if xPlayers[playerId] ~= nil then
            playerNames[playerId] = xPlayers[playerId].name
        end
    end

    return playerNames
end
