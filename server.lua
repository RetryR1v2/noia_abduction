local ufosInZones = {}
local zoneCooldowns = {}
local ufoSpawned = {}
local ufoSpawnCooldown = {}

RegisterNetEvent('playerEnteredUfoZone')
AddEventHandler('playerEnteredUfoZone', function(zoneId)
    local src = source -- O jogador que entrou na zona
    local currentTime = GetGameTimer()

    if (ufoSpawnCooldown[zoneId] or 0) < currentTime then
        local playersInZone = GetPlayersInZone(zoneId)
        if #playersInZone > 0 then
            if not ufosInZones[zoneId] or (ufosInZones[zoneId].owner ~= src) then
                local chosenPlayer = playersInZone[math.random(#playersInZone)]

                TriggerClientEvent('spawnufos_cl', chosenPlayer, Config.UfoSpawnZones[zoneId].x, Config.UfoSpawnZones[zoneId].y, Config.UfoSpawnZones[zoneId].z, zoneId)

                ufoSpawnCooldown[zoneId] = currentTime + Config.UfoSpawnInterval
                ufosInZones[zoneId] = { count = 1, owner = chosenPlayer } -- Marca que um OVNI foi spawnado e quem é o dono
                if Config.DebugPrints then print("OVNI spawnado na zona " .. zoneId .. " para o jogador " .. chosenPlayer)end
            else
                if Config.DebugPrints then print("OVNI já existe na zona " .. zoneId .. " e pertence ao jogador " .. ufosInZones[zoneId].owner)end
            end
        end
    else
        if Config.DebugPrints then print("Cooldown ativo para a zona " .. zoneId)end
    end
end)

RegisterNetEvent('playerExitedUfoZone')
AddEventHandler('playerExitedUfoZone', function(zoneId)
    local src = source -- O jogador que saiu da zona

    if ufosInZones[zoneId] and ufosInZones[zoneId].owner == src then
        ufosInZones[zoneId] = nil
        if Config.DebugPrints then print("OVNI removido da zona " .. zoneId .. " porque o jogador " .. src .. " saiu.")end
    end
end)

local function CalculateDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function GetPlayersInZone(zoneId)
    local playersInZone = {}
    local zone = Config.UfoSpawnZones[zoneId]

    for _, playerId in ipairs(GetPlayers()) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)

        if CalculateDistance(playerCoords.x, playerCoords.y, playerCoords.z, zone.x, zone.y, zone.z) <= zone.radius then
            table.insert(playersInZone, playerId)
        end
    end

    return playersInZone
end

RegisterNetEvent('requestUfoSpawn')
AddEventHandler('requestUfoSpawn', function(zoneId)
    if not ufosInZones[zoneId] then
        -- Spawnar o OVNI
        local zone = Config.UfoSpawnZones[zoneId]
        local spawnX, spawnY, spawnZ = zone.x + math.random(-zone.radius, zone.radius), zone.y + math.random(-zone.radius, zone.radius), zone.z + 10.0

        local players = GetPlayers()
        local playersNearby = {}
        local maxDistance = 500.0 -- Distância máxima para considerar jogadores próximos

        for _, playerId in ipairs(players) do
            local playerPed = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(playerPed)

            local distance = #(playerCoords - vector3(spawnX, spawnY, spawnZ))

            if distance <= maxDistance then
                table.insert(playersNearby, playerId)
            end
        end

        if #playersNearby > 0 then
            local randomPlayer = playersNearby[math.random(1, #playersNearby)]

            TriggerClientEvent('spawnufos_cl', randomPlayer, spawnX, spawnY, spawnZ, zoneId)

            ufosInZones[zoneId] = { count = 1, owner = randomPlayer }

            if Config.DebugPrints then print("OVNI spawnado na zona " .. zoneId .. " para o jogador " .. randomPlayer .. ". Total de OVNIs: " .. ufosInZones[zoneId].count)end
        else
            if Config.DebugPrints then print("Nenhum jogador próximo o suficiente para spawnar o OVNI.")end
        end
    else
        if Config.DebugPrints then print("OVNI já spawnado na zona " .. zoneId .. ".")end
    end
end)

function table.contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

RegisterNetEvent('removeUfo')
AddEventHandler('removeUfo', function(zoneId)
    if ufosInZones[zoneId] and ufosInZones[zoneId] > 0 then
        -- Remova o OVNI apenas se ele realmente existir
        local ufoId = ufoIds[zoneId] -- Obtém o ID do OVNI
        if DoesEntityExist(ufoId) then
            -- Aqui você poderia fazer a lógica para remover o OVNI
            DeleteEntity(ufoId) -- ou a função específica que remove o OVNI
            ufosInZones[zoneId] = 0 -- Limpa a contagem de OVNIs na zona
            if Config.DebugPrints then print("OVNI removido da zona " .. zoneId .. ". OVNIs restantes: " .. ufosInZones[zoneId])end
            ufoSpawned[zoneId] = nil -- Limpar a marcação do OVNI spawnado
            ufoSpawnCooldown[zoneId] = nil -- Limpar o cooldown
        else
            if Config.DebugPrints then print("OVNI não existe mais para remover na zona " .. zoneId .. ".")end
        end
    else
        if Config.DebugPrints then print("Nenhum OVNI para remover na zona " .. zoneId .. ".")end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Redefine a tabela de contagem de OVNIs e o estado de spawn
        ufosInZones = {}
        ufoSpawnInProgress = {}
        if Config.DebugPrints then print("Contagem de OVNIs redefinida ao parar o recurso.")end
    end
end)
