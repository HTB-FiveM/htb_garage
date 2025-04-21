NoneStrategy = {
    RunStartupStuff = Strategy:new(function()
        -- Need to build a way to handle player loaded (not connecting) without a framework
        --
        -- AddEventHandler('esx:playerLoaded', function()
        --     TriggerServerEvent('htb_garage:playerLoaded')
        -- end)

    end),

    ShowNotification = Strategy:new(function(msg)
        SetNotificationTextEntry("STRING")
		AddTextComponentString(msg)
		DrawNotification(false, true)
    end),

    GetPlayerData = Strategy:new(function()
        return nil
    end)
}