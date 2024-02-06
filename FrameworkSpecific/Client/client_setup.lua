-- Map a Role Play framework to wrapper functions to the platform specific counterparts

frameworkFunctionMappings = {
    esx = {
        runStartupStuff = RunStartupStuffEsx,
        showNotification = ShowNotificationEsx,
        getPlayerData = GetPlayerDataEsx
    },
    qbcore = {
        runStartupStuff = RunStartupStuffQbCore,
        showNotification = ShowNotificationQbCore,
        getPlayerData = GetPlayerDataQbCore
    },
    custom = {
        runStartupStuff = RunStartupStuffCustom,
        showNotification = ShowNotificationCustom,
        getPlayerData = GetPlayerDataCustom
    },
    none = {
        runStartupStuff = RunStartupStuffNone
    }
}


