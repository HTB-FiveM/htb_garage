
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
        identifier = citizenid,
        accounts = {
            bank = playerData.accounts.bank,
            money = playerData.accounts.cash
        }
    }
end
