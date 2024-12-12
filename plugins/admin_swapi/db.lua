function db_init()
	db = Database(tostring(config:Fetch("admins.connection_name")))
	if not db:IsConnected() then return end

	db:QueryParams("CREATE TABLE `@tablename` (`token` varchar(128) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;",
    		{ tablename = "sw_swapi_auth" },
    		function(err, result)
    			if #result > 0 then
    				print("Table sw_swapi_auth created ok.")
    		    else
                    print("Table sw_swapi_auth exists.")
                end

    		end)
end

function db_auth_loader()
	if not db:IsConnected() then return end

	auth_tokens = {}

	db:QueryParams(
		"select token from `sw_swapi_auth`",
		{},
		function(err, result)
			if #err > 0 then return print("ERROR: " .. err) end
			auth_tokens = result
		end)
end
