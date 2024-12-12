AddEventHandler("OnPluginStart", function(event)
end)

AddEventHandler("OnAllPluginsLoaded", function(event)
    db_init()
    db_auth_loader()
    main()
    return EventResult.Continue
end)
