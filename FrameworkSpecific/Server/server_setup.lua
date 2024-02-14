
-- Map a Role Play framework to wrapper functions to the platform specific counterparts
frameworkFunctionMappings = {
    esx = {
        runStartupStuff = RunStartupStuffEsx,
        getAllPlayerNames = GetAllPlayerNamesEsx,
        getPlayerIdentifierFromId = GetPlayerIdentifierFromIdEsx,
        makePayment = MakePaymentEsx
    },
    qbcore = {
        runStartupStuff = RunStartupStuffQbCore,
        getAllPlayerNames = GetAllPlayerNamesQbCore,
        getPlayerIdentifierFromId = GetPlayerIdentifierFromIdQbCore,
        makePayment = MakePaymentQbCore
    },
    custom = {
        runStartupStuff = RunStartupStuffCustom,
        getAllPlayerNames = GetAllPlayerNamesCustom,
        getPlayerIdentifierFromId = getPlayerIdentifierFromIdCustom,
        makePayment = MakePaymentCustom
    }
}

SQL = {}

