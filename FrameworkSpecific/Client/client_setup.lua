-- Map a Role Play framework to wrapper functions to the platform specific counterparts

frameworkFunctionMappings = {
    esx = {
        runStartupStuff = RunStartupStuffEsx,
        showNotification = ShowNotificationEsx
    },
    custom = {
        runStartupStuff = RunStartupStuffCustom,
        showNotification = ShowNotificationCustom
    },
    none = {
        runStartupStuff = RunStartupStuffNone
    }
}


