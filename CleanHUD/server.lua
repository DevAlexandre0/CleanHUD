ESX = exports["es_extended"]:getSharedObject()

lib.callback.register('hud:getPlayerData', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return nil end

    return {
        playerId = xPlayer.source,
        money = xPlayer.getMoney(),
        bankMoney = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0,
        job = xPlayer.job.label,
        jobGrade = xPlayer.job.grade_label
    }
end)

lib.callback.register('hud:getStatusData', function(source)
    local status = {}

    TriggerEvent('esx_status:getStatus', source, 'hunger', function(hunger)
        status.hunger = hunger and hunger.percent or 0
    end)

    TriggerEvent('esx_status:getStatus', source, 'thirst', function(thirst)
        status.thirst = thirst and thirst.percent or 0
    end)

    if Config.stress.enableStress then
        TriggerEvent('esx_status:getStatus', source, 'stress', function(stress)
            status.stress = stress and stress.percent or 0
        end)
    end

    return status
end)

if Config.stress.enableStress then
    RegisterNetEvent('hud:server:GainStress', function(amount)
        if not Config.stress.enableStress then return end
        local src = source
        local player = ESX.GetPlayerFromId(src)
        if not player then return end
        TriggerClientEvent('hud:client:GetStress', src, amount, 'gain')
    end)

    RegisterNetEvent('hud:server:RelieveStress', function(amount)
        if not Config.stress.enableStress then return end
        local src = source
        local player = ESX.GetPlayerFromId(src)
        if not player then return end
        TriggerClientEvent('hud:client:GetStress', src, amount, 'relieve')
    end)

    RegisterNetEvent('hud:server:UpdateStress', function(amount, action)
        local src = source
        local player = ESX.GetPlayerFromId(src)
        if not player then return end
        local newStress = action == 'gain' and math.min(amount, 100) or math.max(amount, 0)
        TriggerClientEvent('hud:client:UpdateStress', src, newStress)
        if action == 'gain' then
            TriggerClientEvent("esx_status:add", src, "stress", newStress)
            TriggerClientEvent('ox_lib:notify', src, {
                description = 'Feeling More Stressed!',
                type = 'error',
            })
        else
            TriggerClientEvent("esx_status:remove", src, "stress", newStress)
            TriggerClientEvent('ox_lib:notify', src, {
                description = 'Feeling Less Stressed!',
                type = 'success',
            })
        end
    end)
end

