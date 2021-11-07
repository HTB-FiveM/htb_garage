
function RunStartupStuffQbCore()
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        TriggerServerEvent('htb_garage:playerLoaded')
    end)

end

function ShowNotificationQbCore(msg, level)
    local lvl = 'success'
    if level then
        lvl = level
    end
    QBCore.Functions.Notify(msg, lvl)
end

function RequestModelQbCore(modelHash, cb)
    HtbGarageUtil.RequestModel(modelHash, cb)

end

function SetBaseVehiclePropertiesQbCore(vehicle, props)
    QBCore.Functions.SetVehicleProperties(vehicle, props)
end

function GetBaseVehiclePropertiesQbCore(vehicle)
    return QBCore.Functions.GetVehicleProperties(vehicle)
end
