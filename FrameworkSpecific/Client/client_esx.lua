EsxStrategy = {
    RunStartupStuff = Strategy:new(function()
        -- NOTE: If not using legacy then comment out the '@es_extended/imports.lua' line in fxmanifest.lua
        --       Legacy provides a definition for ESX object so this should overwrite the global, but
        --       better to not let it load if not required
        if Config.UsingEsxLegacy == false then
            ESX = nil 

            Citizen.CreateThread(function() 
                while ESX == nil do 
                    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) 
                    Citizen.Wait(1) 
                end 
            end) 
        end

        RegisterNetEvent('esx:playerLoaded')
        AddEventHandler('esx:playerLoaded', function()
            TriggerServerEvent('htb_garage:playerLoaded')
        end)

    end),

    ShowNotification = Strategy:new(function(msg)
        ESX.ShowNotification(msg)
    end),

    GetPlayerData = Strategy:new(function()
        return ESX.GetPlayerData()
    end)
}

