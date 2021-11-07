-- Map a Role Play framework to wrapper functions to the platform specific counterparts

frameworkFunctionMappings = {
    esx = {
        runStartupStuff = RunStartupStuffEsx,
        showNotification = ShowNotificationEsx,
        requestModel = RequestModelEsx,
        setBaseVehicleProperties = SetBaseVehiclePropertiesEsx,
        getBaseVehicleProperties = GetBaseVehiclePropertiesEsx

    },
    qbcore = {
        runStartupStuff = RunStartupStuffQbCore,
        showNotification = ShowNotificationQbCore,
        requestModel = RequestModelQbCore,
        setBaseVehicleProperties = SetBaseVehiclePropertiesQbCore,
        getBaseVehicleProperties = GetBaseVehiclePropertiesQbCore

    },
    custom = {
        runStartupStuff = RunStartupStuffCustom,
        showNotification = ShowNotificationCustom,
        requestModel = RequestModelCustom,
        setBaseVehicleProperties = SetBaseVehiclePropertiesCustom,
        getBaseVehicleProperties = GetBaseVehiclePropertiesCustom
    },
    none = {
        runStartupStuff = RunStartupStuffNone,
        showNotification = ShowNotificationNone,
        requestModel = RequestModelNone,
        setBaseVehicleProperties = SetBaseVehiclePropertiesNone,
        getBaseVehicleProperties = GetBaseVehiclePropertiesNone
    }
}


