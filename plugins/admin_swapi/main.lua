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
    elseif name == "setBots" then
        setBots(callback, corrid, payload_content)
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

function setBots(callback, corrid, payload)
    server:Execute("mp_autoteambalance 0")
    server:Execute("mp_limitteams 0")
    server:Execute("bot_kick all")

    for i = 1, payload["t"] do
        server:Execute("bot_add_t")
    end

    for i = 1, payload["ct"] do
        server:Execute("bot_add_ct")
    end

    execute_curl(callback, corrid, 200, "OK", nil)
end

function getPlayers(callback, corrid)
    weaponNames = {
        -- Pistols
        [1] = "Desert Eagle",
        [2] = "Dual Berettas",
        [3] = "Five-SeveN",
        [4] = "Glock-18",
        [30] = "Tec-9",
        [31] = "Zeus x27 (Taser)",
        [32] = "P2000",
        [36] = "P250",
        [61] = "USP-S",
        [63] = "CZ75-Auto",
        [64] = "R8 Revolver",

        -- Grenades
        [44] = "High-Explosive Grenade",
        [45] = "Smoke Grenade",
        [46] = "Molotov Cocktail",
        [47] = "Decoy Grenade",
        [48] = "Incendiary Grenade",
        [49] = "Flashbang",

        -- Rifles
        [7] = "AK-47",
        [8] = "AUG",
        [10] = "FAMAS",
        [13] = "Galil AR",
        [16] = "M4A4",
        [39] = "SG 553",
        [60] = "M4A1-S",

        -- Sniper Rifles
        [9] = "AWP",
        [11] = "G3SG1 (Auto Sniper)",
        [38] = "SCAR-20 (Auto Sniper)",
        [40] = "SSG 08 (Scout)",

        -- Submachine Guns (SMGs)
        [17] = "MAC-10",
        [19] = "P90",
        [23] = "MP5-SD",
        [24] = "UMP-45",
        [26] = "PP-Bizon",
        [33] = "MP7",
        [34] = "MP9",

        -- Heavy Weapons
        [14] = "M249",
        [28] = "Negev",
        [25] = "XM1014 (Auto Shotgun)",
        [27] = "MAG-7",
        [29] = "Sawed-Off Shotgun",
        [35] = "Nova",

        -- Knives
        [41] = "Terrorist Knife",
        [42] = "Counter-Terrorist Knife",
        [59] = "Classic Knife",
        [500] = "Bayonet",
        [503] = "Classic Knife",
        [505] = "Flip Knife",
        [506] = "Gut Knife",
        [507] = "Karambit",
        [508] = "M9 Bayonet",
        [509] = "Huntsman Knife",
        [512] = "Falchion Knife",
        [514] = "Bowie Knife",
        [515] = "Butterfly Knife",
        [516] = "Shadow Daggers",
        [517] = "Paracord Knife",
        [518] = "Survival Knife",
        [519] = "Ursus Knife",
        [520] = "Navaja Knife",
        [521] = "Nomad Knife",
        [522] = "Stiletto Knife",
        [523] = "Talon Knife",
        [525] = "Skeleton Knife",
        [526] = "Kukri Knife",

        -- Gloves
        [5027] = "Bloodhound Gloves",
        [5028] = "Terrorist Gloves",
        [5029] = "Counter-Terrorist Gloves",
        [5030] = "Sport Gloves",
        [5031] = "Driver Gloves",
        [5032] = "Hand Wraps",
        [5033] = "Moto Gloves",
        [5034] = "Specialist Gloves",
        [5035] = "Hydra Gloves"
    }

    local weaponTypes = {
        [0] = "Knife",
        [1] = "Pistol",
        [2] = "Submachine Gun",
        [3] = "Rifle",
        [4] = "Shotgun",
        [5] = "Sniper Rifle",
        [6] = "Machine Gun",
        [7] = "C4",
        [8] = "Taser",
        [9] = "Grenade",
        [10] = "Equipment",
        [11] = "Stackable Item",
        [12] = "Fists",
        [13] = "Breach Charge",
        [14] = "Bump Mine",
        [15] = "Tablet",
        [16] = "Melee",
        [17] = "Shield",
        [18] = "Zone Repulsor",
      }

    local teamNames = {
        [0] = "None",
        [1] = "Spectator",
        [2] = "T",
        [3] = "CT"
    }

    local weaponCategories = {
        [0] = "Other",
        [1] = "Melee",
        [2] = "Secondary",
        [3] = "SMG",
        [4] = "Rifle",
        [5] = "Heavy"
    }
    local players = {}

    for i = 0, playermanager:GetPlayerCap() - 1, 1 do
        local pl = GetPlayer(i)
        if pl then

    local weaponList = {}
    local weaponManager = pl:GetWeaponManager()

        if weaponManager then
            local weapons = weaponManager:GetWeapons()
            if weapons then
                for _, weapon in ipairs(weapons) do
                    local weaponData = weapon:CCSWeaponBaseVData()

                    if weaponData then
                        local weaponInfo = {
                            id = weapon:CBasePlayerWeapon().Parent.AttributeManager.Item.ItemDefinitionIndex,
                            name = weaponNames[weapon:CBasePlayerWeapon().Parent.AttributeManager.Item.ItemDefinitionIndex] or "Unknown",
                            slot = weaponData.GearSlot,
                            weaponType = weaponTypes[weaponData.WeaponType] or "Unknown",
                            weaponCategory = weaponCategories[weaponData.WeaponCategory] or "Unknown"
                        }
                        table.insert(weaponList, weaponInfo)
                    end
                end
            end
        end

        local playerDetails = {
                steamid2 = tostring(pl:GetSteamID2()),
                team = teamNames[pl:CBaseEntity().TeamNum],
                name = pl:CBasePlayerController().PlayerName,
                slot = pl:GetSlot(),
                health = pl:CBaseEntity().Health,
                connectedtime = pl:GetConnectedTime(),
                ip = pl:GetIPAddress(),
                weapons = weaponList
            }

            table.insert(players, playerDetails)
        end
    end

    local playerJson = json.encode(players)
    execute_curl(callback, corrid, 200, "OK", base64_encode(playerJson))
end
