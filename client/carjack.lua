--Ped carjacking based on polyzone
--Author: kush#6076
local inzone = false
local Zones = {}
QBCore = nil
local globalpeds = {}
CreateThread(function()
    while QBCore == nil do
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
        Wait(200)
    end
end)

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

--This thread makes npc's shoot at players driving luxury cars in the hood
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(90000)
        local playerped = PlayerPedId()
        if QBCore ~= nil and inzone then --AND PLAYER IS IN POLYZONE HOOD
            --see if player is in a vehile and is also the driver
            if IsPedInAnyVehicle(playerped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(playerped, true), -1) == playerped then
                local veh = GetVehiclePedIsIn(playerped, false)
                local modelName = GetEntityModel(veh)
                --check if its a luxury car
                if QBCore.Shared.VehicleModels[modelName] ~= nil then
                    if QBCore.Shared.VehicleModels[modelName]["shop"] == "custom" then
                        --bingo we got a hit, players driving a luxury car
                        --grab nearest ped(s)
                        local coords = GetEntityCoords(playerped)
                        local IgnorePeds = {}
                        if next(IgnorePeds) == nil then
                            --add players to ignore
                            for _, player in ipairs(GetActivePlayers()) do
                                local p = GetPlayerPed(player)
                                table.insert(IgnorePeds, p)
                            end
                        end
                        local peds = QBCore.Functions.GetPeds(IgnorePeds)
                        local nearbypeds = {}
                        if next(nearbypeds) == nil then
                            --add nearby peds within 50 meters to shooters list
                            for _, ped in pairs(peds) do
                                local pedcoords = GetEntityCoords(ped)
                                local dist = GetDistanceBetweenCoords(pedcoords, coords.x, coords.y, coords.z, true)
                                if dist < 50 then
                                    table.insert(nearbypeds, ped)
                                end
                            end
                        end

                        --make peds nearby shoot at player
                        SetPedRelationshipGroupHash(playerped, GetHashKey("PLAYER"))
                        AddRelationshipGroup("HeistGuards")
                        for _, ped in pairs(nearbypeds) do
                            --Setup peds to shoot
                            if not has_value(globalpeds, ped) then
                                SetPedCanSwitchWeapon(ped, true)
                                SetPedArmour(ped, 100)
                                SetPedAccuracy(ped, 99)
                                GiveWeaponToPed(ped, GetHashKey("WEAPON_MACHINEPISTOL"), 255, false, false)
                                SetPedDropsWeaponsWhenDead(ped, false)
					            SetPedFleeAttributes(ped, 0, false)	
					            SetPedRelationshipGroupHash(ped, GetHashKey("HeistGuards"))
                                ClearPedTasksImmediately(ped)
                                table.insert(globalpeds, ped)
                            end
                        end

                        SetPedRelationshipGroupHash(ped, GetHashKey("PLAYER"))
				        AddRelationshipGroup('HeistGuards')

                       
                        SetRelationshipBetweenGroups(0, GetHashKey("HeistGuards"), GetHashKey("HeistGuards"))
				        SetRelationshipBetweenGroups(5, GetHashKey("HeistGuards"), GetHashKey("PLAYER"))
				        SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("HeistGuards"))
                    end
                end
            end 
        elseif inzone == false and QBCore ~= nil then
            globalpeds = {}
        end
    end
end)






--this thread checks for parked vehicles near players and makes an npc steal them

Citizen.CreateThread(function()
    local stealingInProgress = false
    while true do
        Citizen.Wait(60000)
        local playerped = PlayerPedId()
        if inzone == true and QBCore ~= nil then --check if player is in the hood and QBCore isn't tweaking
            --print("in zone")
            local veh = GetVehiclePedIsIn(playerped, true) --grab last vehicle player was in
            if veh ~= 0 and veh ~= nil then
                local modelName = GetEntityModel(veh)
                if QBCore.Shared.VehicleModels[modelName]["shop"] == "custom" then --check if last vehicle was a lux vehicle
                    --bingo got a hit
                    --lets grab vehicle coords and check if the vehicle is still in the hood
                    local vehcoords = GetEntityCoords(veh)
                    for _, zone in pairs(Zones) do
                        if Zones[_]:isPointInside(vehcoords) then
                            --car is in the hood, lets grab the nearest ped and make them steal the car
                            --make sure we add in Players to the ignore list
                            local IgnorePeds = {}
                            if next(IgnorePeds) == nil then
                                --add players to ignore
                                for _, player in ipairs(GetActivePlayers()) do
                                    local p = GetPlayerPed(player)
                                    table.insert(IgnorePeds, p)
                                end
                            end
                            local stealingPed, dist = QBCore.Functions.GetClosestPed(vehcoords, IgnorePeds) --grab closest ped
                            ClearPedTasksImmediately(stealingPed) --clear tasks
                            SetVehicleDoorsLocked(veh, 1)
                            TaskEnterVehicle(stealingPed, veh, 30000, -1, 2.0, 1, 0) --make the ped get in the car
                            while not IsPedInAnyVehicle(stealingPed, false) do --wait till the ped is in the car
                                Citizen.Wait(1000)
                            end
                            TaskVehicleDriveToCoordLongrange(stealingPed, veh, 1260.11, -3320.38, 5.8, 100, 1074528293, 20.0)
                        end
                    end
                end
            end
        end
    end
end)


Citizen.CreateThread(function()
    while true do
        local plyPed = PlayerPedId()
        local coord = GetEntityCoords(plyPed)

        Citizen.Wait(10000)

        for _, zone in pairs(Zones) do
            if Zones[_]:isPointInside(coord) then
                inzone = true
                while inzone do
                    local plyPed = PlayerPedId()
                    local InZoneCoordS = GetEntityCoords(plyPed)

                    if not Zones[_]:isPointInside(InZoneCoordS) then 
                        inzone = false
                    end

                    Citizen.Wait(250)
                end
            end
        end
    end
end)


function AddPolyZone(name, points, options)
    Zones[name] = PolyZone:Create(points, options)
end



Citizen.CreateThread(function()
    AddPolyZone(
        "hoodzone",
            {vector2(-94.943382263184, -1261.5183105468),
            vector2(-4.8702230453492, -1267.470703125),
            vector2(73.36947631836, -1279.714477539),
            vector2(120.38999938964, -1273.6029052734),
            vector2(141.00337219238, -1266.7062988282),
            vector2(178.94549560546, -1246.05859375),
            vector2(298.5802307129, -1242.7377929688),
            vector2(385.43923950196, -1240.228881836),
            vector2(526.51690673828, -1239.7221679688),
            vector2(549.80682373046, -1398.1258544922),
            vector2(546.27770996094, -1509.4699707032),
            vector2(609.92065429688, -1578.2823486328),
            vector2(602.22631835938, -1813.8289794922),
            vector2(587.34259033204, -1995.2864990234),
            vector2(594.26770019532, -2119.4362792968),
            vector2(572.39660644532, -2403.9064941406),
            vector2(498.0620727539, -2310.7741699218),
            vector2(377.72424316406, -2228.8017578125),
            vector2(279.6284790039, -2231.8012695312),
            vector2(105.61742401124, -2242.0305175782),
            vector2(-24.44021987915, -2253.5070800782),
            vector2(-247.24140930176, -2252.09765625),
            vector2(-325.6336364746, -2216.7314453125),
            vector2(-474.67443847656, -2206.4299316406),
            vector2(-657.95666503906, -1779.7438964844),
            vector2(-594.06616210938, -1747.5356445312),
            vector2(-478.99710083008, -1687.5268554688),
            vector2(-383.04815673828, -1535.5671386718),
            vector2(-363.91430664062, -1433.8743896484),
            vector2(-358.0495300293, -1323.4661865234),
            vector2(-330.82803344726, -1271.033203125),
            vector2(-277.07763671875, -1258.5600585938),
            vector2(-243.65899658204, -1255.1452636718),
            vector2(-171.3165435791, -1252.0112304688)},
            {
                name="hood",
                --minZ = 16.465925216674,
                --maxZ = 64.493560791016
              }
    )
end)