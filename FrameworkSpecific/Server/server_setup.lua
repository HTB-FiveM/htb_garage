
-- Map a Role Play framework to wrapper functions to the platform specific counterparts
frameworkFunctionMappings = {
    esx = {
        runStartupStuff = RunStartupStuffEsx,
        getAllPlayerNames = GetAllPlayerNamesEsx,
        registerDatabase = RegisterDatabaseQueriesEsx,
        identifierFromServerId = IdentifierFromServerIdEsx
    },
    qbcore = {
        runStartupStuff = RunStartupStuffQbCore,
        getAllPlayerNames = GetAllPlayerNamesQbCore,
        registerDatabase = RegisterDatabaseQueriesQbCore,
        identifierFromServerId = IdentifierFromServerIdQbCore
    },
    custom = {
        runStartupStuff = RunStartupStuffCustom,
        getAllPlayerNames = GetAllPlayerNamesCustom,
        registerDatabase = RegisterDatabaseQueriesCustom,
        identifierFromServerId = IdentifierFromServerIdCustom
    }
}

