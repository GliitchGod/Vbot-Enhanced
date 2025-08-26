-- Enhanced Callbacks Library for vBot 4.8
-- Provides comprehensive callback functions for script development
-- Author: vBot Enhancement System

local EnhancedCallbacks = {}

-- ======================== --
-- [[ UTILITY FUNCTIONS ]] --
-- ======================== --

-- Enhanced callback registration with error handling
function EnhancedCallbacks.registerCallback(eventType, callback, priority)
    if type(callback) ~= "function" then
        error("EnhancedCallbacks: Callback must be a function")
        return false
    end

    if type(eventType) ~= "string" then
        error("EnhancedCallbacks: Event type must be a string")
        return false
    end

    priority = priority or 0

    local success, result = pcall(function()
        if eventType == "talk" then
            onTalk(callback)
        elseif eventType == "text" then
            onTextMessage(callback)
        elseif eventType == "use" then
            onUse(callback)
        elseif eventType == "useWith" then
            onUseWith(callback)
        elseif eventType == "move" then
            onPlayerPositionChange(callback)
        elseif eventType == "health" then
            onPlayerHealthChange(callback)
        elseif eventType == "mana" then
            onManaChange(callback)
        elseif eventType == "level" then
            onLevelChange(callback)
        elseif eventType == "login" then
            onLogin(callback)
        elseif eventType == "logout" then
            onLogout(callback)
        elseif eventType == "creature" then
            onCreatureAppear(callback)
        elseif eventType == "creatureDisappear" then
            onCreatureDisappear(callback)
        elseif eventType == "spell" then
            onSpellCooldown(callback)
        elseif eventType == "groupSpell" then
            onGroupSpellCooldown(callback)
        elseif eventType == "attack" then
            onAttackingCreatureChange(callback)
        elseif eventType == "missile" then
            onMissile(callback)
        elseif eventType == "projectile" then
            onProjectile(callback)
        elseif eventType == "animatedText" then
            onAnimatedText(callback)
        elseif eventType == "staticText" then
            onStaticText(callback)
        elseif eventType == "tileUpdate" then
            onTileUpdate(callback)
        elseif eventType == "container" then
            onContainerUpdate(callback)
        elseif eventType == "channel" then
            onChannelUpdate(callback)
        elseif eventType == "vip" then
            onVipUpdate(callback)
        else
            error("EnhancedCallbacks: Unknown event type '" .. eventType .. "'")
        end
    end)

    if success then
        debugLog("info", "EnhancedCallbacks: Successfully registered " .. eventType .. " callback")
        return true
    else
        debugLog("error", "EnhancedCallbacks: Failed to register " .. eventType .. " callback: " .. tostring(result))
        return false
    end
end

-- Remove all callbacks of a specific type
function EnhancedCallbacks.clearCallbacks(eventType)
    -- This would require storing callback references, for now just log
    debugLog("info", "EnhancedCallbacks: clearCallbacks not fully implemented for " .. tostring(eventType))
end

-- ======================== --
-- [[ ENHANCED CALLBACKS ]] --
-- ======================== --

-- Enhanced talk callback with filtering and logging
EnhancedCallbacks.onTalk = function(filter, callback)
    local enhancedCallback = function(name, level, mode, text, channelId, pos)
        if filter then
            local shouldProcess = false

            if filter.name and name:lower():find(filter.name:lower()) then
                shouldProcess = true
            elseif filter.text and text:lower():find(filter.text:lower()) then
                shouldProcess = true
            elseif filter.mode and mode == filter.mode then
                shouldProcess = true
            elseif not filter.name and not filter.text and not filter.mode then
                shouldProcess = true -- No filter specified
            end

            if not shouldProcess then return end
        end

        local success, result = pcall(function()
            return callback(name, level, mode, text, channelId, pos)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onTalk error: " .. tostring(result))
        end
    end

    onTalk(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced talk callback registered")
end

-- Enhanced text message callback with content analysis
EnhancedCallbacks.onTextMessage = function(filter, callback)
    local enhancedCallback = function(mode, text)
        if filter then
            if filter.mode and mode ~= filter.mode then return end
            if filter.contains and not text:lower():find(filter.contains:lower()) then return end
            if filter.startsWith and not text:lower():starts(filter.startsWith:lower()) then return end
            if filter.damage and not text:lower():find("you lose") and not text:lower():find("due to") then return end
            if filter.heal and not text:lower():find("you heal") and not text:lower():find("you gain") then return end
        end

        local success, result = pcall(function()
            return callback(mode, text)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onTextMessage error: " .. tostring(result))
        end
    end

    onTextMessage(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced text message callback registered")
end

-- Enhanced position change callback with movement tracking
EnhancedCallbacks.onPositionChange = function(callback)
    local lastPosition = nil
    local moveCount = 0

    local enhancedCallback = function(newPos, oldPos)
        if not newPos then return end

        local success, result = pcall(function()
            local movement = nil

            if oldPos and lastPosition then
                movement = {
                    from = oldPos,
                    to = newPos,
                    distance = getDistanceBetween(oldPos, newPos),
                    direction = EnhancedCallbacks.getDirection(oldPos, newPos)
                }
                moveCount = moveCount + 1
            end

            return callback(newPos, oldPos, movement, moveCount)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onPositionChange error: " .. tostring(result))
        end

        lastPosition = newPos
    end

    onPlayerPositionChange(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced position change callback registered")
end

-- Enhanced health change callback with health tracking
EnhancedCallbacks.onHealthChange = function(callback)
    local lastHealth = nil
    local lastMaxHealth = nil
    local healthHistory = {}

    local enhancedCallback = function(healthPercent)
        local success, result = pcall(function()
            local currentHealth = hp()
            local currentMaxHealth = hpmax()
            local healthChange = nil

            if lastHealth and lastMaxHealth then
                healthChange = {
                    previousHealth = lastHealth,
                    previousMaxHealth = lastMaxHealth,
                    currentHealth = currentHealth,
                    currentMaxHealth = currentMaxHealth,
                    healthDifference = currentHealth - lastHealth,
                    maxHealthDifference = currentMaxHealth - lastMaxHealth,
                    percentChange = healthPercent,
                    wasDamage = currentHealth < lastHealth,
                    wasHeal = currentHealth > lastHealth
                }

                -- Keep health history (last 10 entries)
                table.insert(healthHistory, {
                    timestamp = now,
                    health = currentHealth,
                    maxHealth = currentMaxHealth,
                    percent = healthPercent
                })

                if #healthHistory > 10 then
                    table.remove(healthHistory, 1)
                end
            end

            return callback(healthPercent, healthChange, healthHistory)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onHealthChange error: " .. tostring(result))
        end

        lastHealth = hp()
        lastMaxHealth = hpmax()
    end

    onPlayerHealthChange(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced health change callback registered")
end

-- Enhanced mana change callback with mana tracking
EnhancedCallbacks.onManaChange = function(callback)
    local lastMana = nil
    local lastMaxMana = nil
    local manaHistory = {}

    local enhancedCallback = function(player, mana, maxMana, oldMana, oldMaxMana)
        local success, result = pcall(function()
            local manaChange = nil

            if lastMana and lastMaxMana then
                manaChange = {
                    previousMana = lastMana,
                    previousMaxMana = lastMaxMana,
                    currentMana = mana,
                    currentMaxMana = maxMana,
                    manaDifference = mana - lastMana,
                    maxManaDifference = maxMana - lastMaxMana,
                    percentChange = maxMana > 0 and (mana / maxMana) * 100 or 0,
                    wasSpent = mana < lastMana,
                    wasGained = mana > lastMana
                }

                -- Keep mana history (last 10 entries)
                table.insert(manaHistory, {
                    timestamp = now,
                    mana = mana,
                    maxMana = maxMana,
                    percent = maxMana > 0 and (mana / maxMana) * 100 or 0
                })

                if #manaHistory > 10 then
                    table.remove(manaHistory, 1)
                end
            end

            return callback(player, mana, maxMana, oldMana, oldMaxMana, manaChange, manaHistory)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onManaChange error: " .. tostring(result))
        end

        lastMana = mana
        lastMaxMana = maxMana
    end

    onManaChange(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced mana change callback registered")
end

-- Enhanced use callback with item tracking
EnhancedCallbacks.onUse = function(callback)
    local enhancedCallback = function(pos, itemId, stackPos, subType)
        local success, result = pcall(function()
            local itemInfo = nil
            local tile = g_map.getTile(pos)

            if tile then
                local topThing = tile:getTopThing()
                if topThing then
                    itemInfo = {
                        id = topThing:getId(),
                        name = topThing:getName(),
                        position = pos,
                        stackPos = stackPos,
                        subType = subType,
                        isContainer = topThing:isContainer(),
                        isUseable = topThing:isUseable(),
                        isWalkable = tile:isWalkable(),
                        hasCreature = tile:hasCreature()
                    }
                end
            end

            return callback(pos, itemId, stackPos, subType, itemInfo)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onUse error: " .. tostring(result))
        end
    end

    onUse(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced use callback registered")
end

-- Enhanced useWith callback with item combination tracking
EnhancedCallbacks.onUseWith = function(callback)
    local enhancedCallback = function(pos, itemId, target, subType)
        local success, result = pcall(function()
            local useInfo = {
                position = pos,
                itemId = itemId,
                subType = subType,
                targetItem = target and target:getId(),
                targetName = target and target:getName(),
                targetPosition = target and target:getPosition(),
                targetType = target and (target:isMonster() and "monster" or target:isPlayer() and "player" or target:isNpc() and "npc" or "item")
            }

            return callback(pos, itemId, target, subType, useInfo)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onUseWith error: " .. tostring(result))
        end
    end

    onUseWith(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced useWith callback registered")
end

-- Enhanced creature appearance callback
EnhancedCallbacks.onCreatureAppear = function(callback)
    local enhancedCallback = function(creature)
        local success, result = pcall(function()
            local creatureInfo = nil
            if creature then
                creatureInfo = {
                    id = creature:getId(),
                    name = creature:getName(),
                    position = creature:getPosition(),
                    type = creature:isMonster() and "monster" or creature:isPlayer() and "player" or creature:isNpc() and "npc" or "unknown",
                    healthPercent = creature:getHealthPercent(),
                    direction = creature:getDirection(),
                    outfit = creature:getOutfit(),
                    skull = creature:getSkull(),
                    emblem = creature:getEmblem(),
                    isLocalPlayer = creature:isLocalPlayer(),
                    isPartyMember = creature:isPlayer() and creature:isPartyMember(),
                    distance = creature:getPosition() and getDistanceBetween(pos(), creature:getPosition()) or 999
                }
            end

            return callback(creature, creatureInfo)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onCreatureAppear error: " .. tostring(result))
        end
    end

    onCreatureAppear(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced creature appear callback registered")
end

-- Enhanced creature disappear callback
EnhancedCallbacks.onCreatureDisappear = function(callback)
    local enhancedCallback = function(creature)
        local success, result = pcall(function()
            local creatureInfo = nil
            if creature then
                creatureInfo = {
                    id = creature:getId(),
                    name = creature:getName(),
                    position = creature:getPosition(),
                    type = creature:isMonster() and "monster" or creature:isPlayer() and "player" or creature:isNpc() and "npc" or "unknown",
                    lastSeen = now
                }
            end

            return callback(creature, creatureInfo)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onCreatureDisappear error: " .. tostring(result))
        end
    end

    onCreatureDisappear(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced creature disappear callback registered")
end

-- Enhanced attacking creature change callback
EnhancedCallbacks.onAttackingCreatureChange = function(callback)
    local lastTarget = nil

    local enhancedCallback = function(creature)
        local success, result = pcall(function()
            local targetInfo = nil
            if creature then
                targetInfo = {
                    id = creature:getId(),
                    name = creature:getName(),
                    position = creature:getPosition(),
                    type = creature:isMonster() and "monster" or creature:isPlayer() and "player" or creature:isNpc() and "npc" or "unknown",
                    healthPercent = creature:getHealthPercent(),
                    distance = creature:getPosition() and getDistanceBetween(pos(), creature:getPosition()) or 999
                }
            end

            local changeInfo = {
                previousTarget = lastTarget,
                currentTarget = targetInfo,
                targetChanged = lastTarget ~= (targetInfo and targetInfo.id),
                hasTarget = creature ~= nil,
                timestamp = now
            }

            local result = callback(creature, changeInfo)
            lastTarget = targetInfo and targetInfo.id
            return result
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onAttackingCreatureChange error: " .. tostring(result))
        end
    end

    onAttackingCreatureChange(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced attacking creature change callback registered")
end

-- Enhanced missile callback for projectile tracking
EnhancedCallbacks.onMissile = function(callback)
    local enhancedCallback = function(missile)
        local success, result = pcall(function()
            local missileInfo = nil
            if missile then
                missileInfo = {
                    id = missile:getId(),
                    fromPosition = missile:getFromPosition(),
                    toPosition = missile:getToPosition(),
                    distance = missile:getFromPosition() and missile:getToPosition() and
                              getDistanceBetween(missile:getFromPosition(), missile:getToPosition()) or 0,
                    direction = missile:getFromPosition() and missile:getToPosition() and
                               EnhancedCallbacks.getDirection(missile:getFromPosition(), missile:getToPosition()),
                    timestamp = now
                }
            end

            return callback(missile, missileInfo)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onMissile error: " .. tostring(result))
        end
    end

    onMissile(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced missile callback registered")
end

-- Enhanced container update callback
EnhancedCallbacks.onContainerUpdate = function(callback)
    local enhancedCallback = function(container, operation)
        local success, result = pcall(function()
            local containerInfo = nil
            if container then
                containerInfo = {
                    id = container:getId(),
                    name = container:getName(),
                    capacity = container:getCapacity(),
                    itemCount = container:getItemsCount(),
                    isOpen = container:isOpen(),
                    operation = operation, -- add, remove, update
                    timestamp = now
                }
            end

            return callback(container, operation, containerInfo)
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.onContainerUpdate error: " .. tostring(result))
        end
    end

    onContainerUpdate(enhancedCallback)
    debugLog("info", "EnhancedCallbacks: Enhanced container update callback registered")
end

-- ======================== --
-- [[ UTILITY FUNCTIONS ]] --
-- ======================== --

-- Get direction between two positions
EnhancedCallbacks.getDirection = function(fromPos, toPos)
    if not fromPos or not toPos then return nil end

    local dx = toPos.x - fromPos.x
    local dy = toPos.y - fromPos.y

    if dx == 0 and dy == -1 then return 0 end -- North
    if dx == 1 and dy == -1 then return 1 end -- NorthEast
    if dx == 1 and dy == 0 then return 2 end -- East
    if dx == 1 and dy == 1 then return 3 end -- SouthEast
    if dx == 0 and dy == 1 then return 4 end -- South
    if dx == -1 and dy == 1 then return 5 end -- SouthWest
    if dx == -1 and dy == 0 then return 6 end -- West
    if dx == -1 and dy == -1 then return 7 end -- NorthWest

    return nil -- No direction (same position or diagonal)
end

-- Check if position is within range
EnhancedCallbacks.isInRange = function(center, target, range)
    if not center or not target or not range then return false end
    return getDistanceBetween(center, target) <= range
end

-- Get creatures in range with filtering
EnhancedCallbacks.getCreaturesInRange = function(center, range, filter)
    center = center or pos()
    range = range or 10
    filter = filter or {}

    local creatures = {}
    local spectators = getSpectators(center, false, range, range)

    for _, creature in ipairs(spectators) do
        if creature and not creature:isLocalPlayer() then
            local include = true

            if filter.type == "monster" and not creature:isMonster() then include = false end
            if filter.type == "player" and not creature:isPlayer() then include = false end
            if filter.type == "npc" and not creature:isNpc() then include = false end

            if filter.name and not creature:getName():lower():find(filter.name:lower()) then include = false end
            if filter.minHealth and creature:getHealthPercent() < filter.minHealth then include = false end
            if filter.maxHealth and creature:getHealthPercent() > filter.maxHealth then include = false end

            if include then
                table.insert(creatures, creature)
            end
        end
    end

    return creatures
end

-- Get items in range
EnhancedCallbacks.getItemsInRange = function(center, range, itemId)
    center = center or pos()
    range = range or 5

    local items = {}
    local spectators = getSpectators(center, false, range, range)

    for _, creature in ipairs(spectators) do
        if creature and creature:isItem() then
            local item = creature
            if not itemId or item:getId() == itemId then
                local distance = getDistanceBetween(center, item:getPosition())
                table.insert(items, {
                    item = item,
                    distance = distance,
                    id = item:getId(),
                    count = item:getCount(),
                    position = item:getPosition()
                })
            end
        end
    end

    -- Sort by distance
    table.sort(items, function(a, b) return a.distance < b.distance end)

    return items
end

-- Enhanced delay function with callback support
EnhancedCallbacks.delayedCallback = function(delay, callback, ...)
    local args = {...}
    schedule(delay, function()
        local success, result = pcall(function()
            return callback(unpack(args))
        end)

        if not success then
            debugLog("error", "EnhancedCallbacks.delayedCallback error: " .. tostring(result))
        end
    end)
end

-- Conditional callback execution
EnhancedCallbacks.conditionalCallback = function(condition, callback, ...)
    local args = {...}

    if type(condition) == "function" then
        if not condition() then return end
    elseif type(condition) == "boolean" then
        if not condition then return end
    end

    local success, result = pcall(function()
        return callback(unpack(args))
    end)

    if not success then
        debugLog("error", "EnhancedCallbacks.conditionalCallback error: " .. tostring(result))
    end

    return result
end

-- ======================== --
-- [[ INITIALIZATION ]] --
-- ======================== --

-- Initialize the enhanced callbacks system
debugLog("info", "Enhanced Callbacks Library loaded successfully")
debugLog("info", "Available enhanced callbacks: onTalk, onTextMessage, onPositionChange, onHealthChange, onManaChange, onUse, onUseWith, onCreatureAppear, onCreatureDisappear, onAttackingCreatureChange, onMissile, onContainerUpdate")

-- Return the library for external use
return EnhancedCallbacks
