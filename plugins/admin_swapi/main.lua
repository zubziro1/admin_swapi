function main()
    commands:Register("api", function(playerid, args, argc, silent, prefix)
        if argc == 4 then
            local corrid = args[1]
            local auth = args[2]
            local callback = base64_decode(args[3])
            local payload = base64_decode(args[4])
            print("swapi req corrid: " .. corrid .. " auth " .. auth .. " callback " .. callback .. " payload " .. payload)

            if verify_access_token(auth) then
                local status, payload_table = pcall(function()
                    return json.decode(payload)
                end)
                local status, payload_content = pcall(function()
                    return json.decode(payload_table["payload"])
                end)

                if status and payload_table and payload_table["function"] then
                    if payload_table["function"] == "setMap" then
                        setMap(payload_content)
                    end
                else
                    print("Invalid or missing function in payload")
                end

                execute_curl(callback, corrid, 200, "OK", nil)
            else
                print("Denied api access. Returning HTTP 401 Unauthorized.")
                execute_curl(callback, corrid, 401, "Unauthorized: Invalid or missing access token.", nil)
            end
        else
            print("Missing req parameters, count != 4 -> " .. argc)
        end
    end)
end

function setMap(payload)
    server:Execute("changelevel " .. payload["name"])
end
