local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

AddEventHandler("OnPluginStart", function(event)
end)

AddEventHandler("OnAllPluginsLoaded", function(event)
    main()
    return EventResult.Continue
end)

function main()
    commands:Register("api", function(playerid, args, argc, silent, prefix)
        if argc == 4 then
            local corrid = args[1]
            local auth = args[2]
            local callback = base64_decode(args[3])
            local payload = base64_decode(args[4])
            print("swapi req corrid: " .. corrid .. " callback " .. callback .. " payload " .. payload)

            local headers = "-H 'Content-Type: text/plain'"
            local data = "-d '" .. payload .. "'"
            local command = string.format('curl -s -w "%%{http_code}" %s %s %s 2>&1', headers, data, callback .. corrid)
            local handle = io.popen(command)
            local result = handle:read("*a")
            handle:close()

            print("Done: " .. result .. " " .. callback .. corrid)
        else
            print("Missing req parameters, count !=4 -> " .. argc)
        end

    end)
end

function base64_decode(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end

function base64_encode(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

--[[
Some strange problems with callback and/or events first 3 calls is OK but then it starts to bail out with very long time for callback execution.
--In reg() tested:

            PerformHTTPRequest('http://192.168.xx.xx:8080/callback/' .. args[1], onResponse, 'POST', 'test', {}, {})

--And:

            local sendData = {
                url = callurl,
                method ='POST',
                data = 'test',
                headers = {},
                files = {}
            }

            local httpRequestID = http:PerformHTTP(json_encode(sendData))
            http:ProcessPendingHTTPRequests()

--With:

function onResponse(status, body, headers, err)
    if status == 200 then
        print("HTTP 200")
    else
        print("HTTP Failed:", status)
        print("err:", err)
        print("body:", body)
        print("headers:", headers)
    end
end

--And:

AddEventHandler("OnHTTPActionPerformed", function(event, status, body, headers, err, httpRequestID)

    if status == 200 then
        print("HTTP 200")
    else
        print("HTTP Failed:", status)
        print("err:", err)
        print("body:", body)
        print("headers:", headers)
    end

    return EventResult.Stop
end)

]]--
