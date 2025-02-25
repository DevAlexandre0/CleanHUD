ESX = exports["es_extended"]:getSharedObject()
PlayerData = {}

local hudVisible = true
local vehicleHudVisible = false
local lastVehicleData = { fuel = -1, gearMode = "" }
local lastStatusData = { health = -1, armor = -1, stamina = -1, underwater = -1, hunger = -1, thirst = -1, stress = -1 }
local lastMoneyData = { money = -1, bankMoney = -1 }
local seatbeltOn = false  -- Track seatbelt state
local stress = 0

RegisterNetEvent("esx:playerLoaded", function()
    Wait(500)
    TriggerEvent('hud:client:LoadMap')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    TriggerEvent('hud:client:LoadMap')
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    updateHUD()
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
    if account.name == 'money' or account.name == 'bank' then
        updateHUD()
    end
end)

RegisterCommand("togglehud", function()
    hudVisible = not hudVisible
    DisplayRadar(hudVisible)
    SendNUIMessage({
        action = 'toggleHud',
        state = hudVisible
    })
end, false)

RegisterNetEvent('hud:client:LoadMap', function()
    Wait(50)
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local minimapOffset = (1920 / 1080 > resolutionX / resolutionY) and ((1920 / 1080 - resolutionX / resolutionY) / 3.6) - 0.008 or 0

    RequestStreamedTextureDict("squaremap", false)
    while not HasStreamedTextureDictLoaded("squaremap") do
        Wait(150)
    end

    SetMinimapClipType(0)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")

    SetMinimapComponentPosition("minimap", "L", "B", -0.006 + minimapOffset, -0.040, 0.1638, 0.183)
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.0, 0.128, 0.20)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.015 + minimapOffset, 0.030, 0.262, 0.300)
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    --SetRadarBigmapEnabled(true, false)
    Wait(100)
    --SetRadarBigmapEnabled(false, false)
    SetRadarZoom(1000)
end)

Citizen.CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(false, false)
    while true do
        Wait(0)
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end
end)

-- Listen for 'B' key press to toggle seatbelt
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 29) then  -- 'B' key
            toggleSeatbelt()
        end
    end
end)

function toggleSeatbelt()
    seatbeltOn = not seatbeltOn
    SendNUIMessage({
        action = 'toggleSeatBelt',
        seatbelt = seatbeltOn
    })

    if seatbeltOn then
        TriggerEvent('esx:showNotification', 'Seatbelt On')
    else
        TriggerEvent('esx:showNotification', 'Seatbelt Off')
    end
end

-- Prevent ejection when seatbelt is on
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle ~= 0 then
            if seatbeltOn then
                -- Keep the player in the vehicle if seatbelt is on
                if not IsPedInVehicle(playerPed, vehicle, false) then
                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1) -- Re-seat the player in the vehicle
                end
            end
        end
    end
end)

function updateHUD()
    lib.callback('hud:getPlayerData', false, function(data)
        if data and hudVisible then
            if data.money ~= lastMoneyData.money or data.bankMoney ~= lastMoneyData.bankMoney then
                lastMoneyData.money = data.money
                lastMoneyData.bankMoney = data.bankMoney
                SendNUIMessage({
                    action = 'updateHud',
                    playerId = data.playerId,
                    money = data.money,
                    bankMoney = data.bankMoney,
                    job = data.job,
                    jobGrade = data.jobGrade
                })
            end
        end
    end)
end

if Config.useHRSGears then
    function updateMode()
        local isManual = exports.HRSGears:ismanual()
        local gearMode = isManual and "Manual" or "Automatic"
        if gearMode ~= lastVehicleData.gearMode then
            lastVehicleData.gearMode = gearMode
            SendNUIMessage({
                action = 'switchMode',
                gearMode = gearMode
            })
        end
    end
end

function updateVehicleHUD()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle ~= 0 and hudVisible then
        local isManual = false
        if not vehicleHudVisible then
            vehicleHudVisible = true
            SendNUIMessage({ action = 'showVehicleHud' })
        end
        if Config.useHRSGears then
            isManual = exports.HRSGears:ismanual()
        end
        local fuelLevel = Entity(vehicle).state.fuel or 0
        local speed = GetEntitySpeed(vehicle) * 3.6
        local rpm = GetVehicleCurrentRpm(vehicle) * 10000
        local gear = isManual and exports.HRSGears:check() or GetVehicleCurrentGear(vehicle)
        local engineHealth = GetVehicleEngineHealth(vehicle) / 10
        local bodyHealth = GetVehicleBodyHealth(vehicle) / 10

        if fuelLevel ~= lastVehicleData.fuel or
           speed ~= lastVehicleData.speed or rpm ~= lastVehicleData.rpm or
           gear ~= lastVehicleData.gear or engineHealth ~= lastVehicleData.engineHealth or
           bodyHealth ~= lastVehicleData.bodyHealth then

            lastVehicleData.fuel = fuelLevel
            lastVehicleData.speed = speed
            lastVehicleData.rpm = rpm
            lastVehicleData.gear = gear
            lastVehicleData.engineHealth = engineHealth
            lastVehicleData.bodyHealth = bodyHealth

            SendNUIMessage({
                action = 'updateVehicleHud',
                fuel = fuelLevel,
                speed = math.floor(speed),
                rpm = math.floor(rpm),
                gear = gear,
                engineHealth = math.floor(engineHealth),
                bodyHealth = math.floor(bodyHealth)
            })
        end
    elseif vehicle == 0 and vehicleHudVisible then
        vehicleHudVisible = false
        SendNUIMessage({ action = 'hideVehicleHud' })
    end
end

function updateStatusHUD()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()
    local health = GetEntityHealth(playerPed) - 100
    local armor = GetPedArmour(playerPed)
    local stamina = math.floor(100 - GetPlayerSprintStaminaRemaining(playerId))
    local underwater = math.floor(GetPlayerUnderwaterTimeRemaining(playerId) / 0.1)

    lib.callback('hud:getStatusData', false, function(statusData)
        local hunger = statusData.hunger and math.floor(statusData.hunger) or 0
        local thirst = statusData.thirst and math.floor(statusData.thirst) or 0
        if Config.stress.enableStress then
            stress = statusData.stress and math.floor(statusData.stress) or 0
        end
        local showArmor = armor > 0
        local showStamina = stamina < 100
        local showOxygen = underwater < 100
        local showStress = stress > 0

        if health ~= lastStatusData.health or armor ~= lastStatusData.armor or stamina ~= lastStatusData.stamina or 
           underwater ~= lastStatusData.underwater or hunger ~= lastStatusData.hunger or thirst ~= lastStatusData.thirst 
           or stress ~= lastStatusData.stress then

            lastStatusData.health = health
            lastStatusData.armor = armor
            lastStatusData.stamina = stamina
            lastStatusData.underwater = underwater
            lastStatusData.hunger = hunger
            lastStatusData.thirst = thirst
            lastStatusData.stress = stress

            SendNUIMessage({
                action = 'updateStatusHud',
                health = health,
                armor = showArmor and armor or 0,
                stamina = showStamina and stamina or 100,
                oxygen = showOxygen and underwater or 100,
                hunger = hunger,
                thirst = thirst,
                stress = showStress and stress or 0,
            })
        end
    end)
end

----------STRESS----------
if Config.stress.enableStress then
    local hasWeapon = false
    local function getBlurIntensity(stressLevel)
        for _, v in pairs(Config.stress.blurIntensity) do
            if stressLevel >= v.min and stressLevel <= v.max then
                return v.intensity
            end
        end
        return 1500
    end

    local function getEffectInterval(stressLevel)
        for _, v in pairs(Config.stress.effectInterval) do
            if stressLevel >= v.min and stressLevel <= v.max then
                return v.timeout
            end
        end
        return 60000
    end

    local function isWhitelistedWeaponStress(weapon)
        if weapon then
            for _, v in pairs(Config.stress.whitelistedWeapons) do
                if weapon == v then
                    return true
                end
            end
        end
        return false
    end

    local function startWeaponStressThread(weapon)
        if isWhitelistedWeaponStress(weapon) then return end
        hasWeapon = true

        CreateThread(function()
            while hasWeapon do
                if IsPedShooting(lib.cache.ped) then
                    if math.random() <= Config.stress.chance then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 5))
                    end
                end
                Wait(0)
            end
        end)
    end

    AddEventHandler('ox_inventory:currentWeapon', function(currentWeapon)
        hasWeapon = false
        if not currentWeapon then return end
        startWeaponStressThread(currentWeapon.hash)
    end)

    RegisterNetEvent('hud:client:GetStress', function(amount, action)
        TriggerEvent('esx_status:getStatus', 'stress', function(status)
            if status then
                stress = status.val
                local newStress = action == 'gain' and (stress + amount) or (stress - amount)
                TriggerServerEvent('hud:server:UpdateStress', newStress, action)
            end
        end) 
    end)

    -- Stress Management
    CreateThread(function()
        while true do
            if ESX.IsPlayerLoaded() and lib.cache.vehicle then
                local veh = lib.cache.vehicle
                local vehClass = GetVehicleClass(veh)
                local speed = GetEntitySpeed(veh) * 3.6
    
                if not (vehClass == 13 or vehClass == 14 or vehClass == 15 or vehClass == 16 or vehClass == 21) then
                    local stressSpeed = (vehClass == 8 or not seatbeltOn) and Config.stress.minForSpeedingUnbuckled or Config.stress.minForSpeeding
                    if speed >= stressSpeed then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            end
            Wait(10000)
        end
    end)
    
    CreateThread(function()
        while true do
            local effectInterval = getEffectInterval(stress)
            if stress >= 100 then
                local blurIntensity = getBlurIntensity(stress)
                local fallRepeat = math.random(2, 4)
                local ragdollTimeout = fallRepeat * 1750
                TriggerScreenblurFadeIn(1000.0)
                Wait(blurIntensity)
                TriggerScreenblurFadeOut(1000.0)

                if not IsPedRagdoll(lib.cache.ped) and IsPedOnFoot(lib.cache.ped) and not IsPedSwimming(lib.cache.ped) then
                    local forwardVector = GetEntityForwardVector(lib.cache.ped)
                    SetPedToRagdollWithFall(lib.cache.ped, ragdollTimeout, ragdollTimeout, 1, forwardVector.x, forwardVector.y, forwardVector.z, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                end

                Wait(1000)
                for _ = 1, fallRepeat, 1 do
                    Wait(750)
                    DoScreenFadeOut(200)
                    Wait(1000)
                    DoScreenFadeIn(200)
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(blurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                end
            elseif stress >= Config.stress.minForShaking then
                local blurIntensity = getBlurIntensity(stress)
                TriggerScreenblurFadeIn(1000.0)
                Wait(blurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
            Wait(effectInterval)
        end
    end)
end
----------STRESS----------

CreateThread(function()
    Wait(2000)
    while true do
        updateHUD()
        if Config.useHRSGears then
            updateMode()
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        updateVehicleHUD()
        Wait(100)
    end
end)

CreateThread(function()
    while true do
        updateStatusHUD()
        Wait(500)
    end
end)
