
function RunStartupStuffQbCore()
    QBCore = exports['qb-core']:GetCoreObject()

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        TriggerServerEvent('htb_garage:playerLoaded')
    end)

end

function ShowNotificationQbCore(msg)
    QBCore.Functions.Notify(msg, "info", 5000)

end


function GetPlayerDataQbCore()
    local playerData = QBCore.Functions.GetPlayerData()

    return {
        identifier = playerData.citizenid,
        accounts = {
            { name = "bank", money = playerData.money.bank },
            { name = "money", money = playerData.money.cash }
        }
    }
end
