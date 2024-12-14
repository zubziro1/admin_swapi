function main()
    commands:Register("api", function(playerid, args, argc, silent, prefix)
        if argc ~= 4 then
            print("Missing req parameters, count != 4 -> " .. argc)
            return
        end
    
        local corrid = args[1]
        local auth = args[2]
        local callback = base64_decode(args[3])
        local payload = base64_decode(args[4])
        print("swapi req corrid: " .. corrid .. " callback " .. callback)

        if not verify_access_token(auth) then
            print("Denied api access. Returning HTTP 401 Unauthorized.")
            execute_curl(callback, corrid, 401, "Unauthorized: Invalid or missing access token.", nil)
            return
        end

        local status_main, payload_main = pcall(function()
            return json.decode(payload)
        end)
        local status_content, payload_content = pcall(function()
            return json.decode(payload_main["payload"])
        end)

        if status_main and payload_main and payload_main["function"] then
            execute(payload_main["function"], callback, corrid, payload_content)
        else
            print("Invalid or missing function in payload")
            execute_curl(callback, corrid, 404, "Not Found", nil)
        end
    end)
end

function execute(name, callback, corrid, payload_content)
    print("exec: " .. name)

    if name == "setMap" then
        setMap(callback, corrid, payload_content)
        return
    elseif name == "getPlayers" then
        getPlayers(callback, corrid)
        return
    else
        print("Invalid or missing function in payload")
        execute_curl(callback, corrid, 404, "Not Found", nil)
        return
    end
end

function setMap(callback, corrid, payload)
    server:Execute("changelevel " .. payload["name"])
    execute_curl(callback, corrid, 200, "OK", nil)
end

function getPlayers(callback, corrid)
    local players = {}
    for i = 0, playermanager:GetPlayerCap() - 1, 1 do
        local pl = GetPlayer(i)
        if pl then
            -- Extract player details as a table
            local playerDetails = {
                steamid =  tostring(pl:GetSteamID()),
                steamid2 =  tostring(pl:GetSteamID2()),
                name = pl:CBasePlayerController().PlayerName,
                slot = pl:GetSlot(),
                health = pl:CBaseEntity().Health,
                connectedtime = pl:GetConnectedTime(),
                ip = pl:GetIPAddress()
            }
            table.insert(players, playerDetails)
        end
    end

    local playerJson = json.encode(players)

    print(playerJson)

    execute_curl(callback, corrid, 200, "OK", base64_encode(playerJson))
end
