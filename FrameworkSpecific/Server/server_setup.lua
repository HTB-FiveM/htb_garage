
-- Map a Role Play framework to wrapper functions to the platform specific counterparts
frameworkFunctionMappings = {
    esx = {
        runStartupStuff = RunStartupStuffEsx,
        getAllPlayerNames = GetAllPlayerNamesEsx
    },
    custom = {
        runStartupStuff = RunStartupStuffCustom,
        getAllPlayerNames = GetAllPlayerNamesCustom
    }
}

