
QBCoreStrategy = {
    RunStartupStuff = Strategy:new(function()
        QBCore = exports['qb-core']:GetCoreObject()

        RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
        AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
            TriggerServerEvent('htb_garage:playerLoaded')
        end)

    end),

    ShowNotification = Strategy:new(function(msg)
        QBCore.Functions.Notify(msg, "info", 5000)

    end),

    GetPlayerData = Strategy:new(function()
        local playerData = QBCore.Functions.GetPlayerData()

        return {
            identifier = playerData.citizenid,
            accounts = {
                { name = "bank", money = playerData.money.bank },
                { name = "money", money = playerData.money.cash }
            }
        }
    end)
}
