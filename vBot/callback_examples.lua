-- Enhanced Callbacks Library - Usage Examples
-- This file demonstrates how to use the enhanced callbacks in your scripts

-- First, load the enhanced callbacks library
-- Note: The library is automatically loaded by the _Loader.lua

-- ======================== --
-- [[ BASIC USAGE ]] --
-- ======================== --

-- Example 1: Basic enhanced talk callback
EnhancedCallbacks.onTalk(nil, function(name, level, mode, text, channelId, pos)
    print(string.format("Player %s said: %s", name, text))
end)

-- Example 2: Filtered talk callback
EnhancedCallbacks.onTalk({
    name = "GM",  -- Only messages from names containing "GM"
    mode = 1      -- Only private messages
}, function(name, level, mode, text, channelId, pos)
    print(string.format("GM Message from %s: %s", name, text))
    -- You could add special handling for GM messages here
end)

-- ======================== --
-- [[ TEXT MESSAGE EXAMPLES ]] --
-- ======================== --

-- Example 3: Monitor damage messages
EnhancedCallbacks.onTextMessage({
    damage = true  -- Only damage messages
}, function(mode, text)
    local damage = text:match("(%d+)")
    if damage then
        print(string.format("Damage taken: %d HP", tonumber(damage)))
        -- You could trigger healing or other responses here
    end
end)

-- Example 4: Monitor healing messages
EnhancedCallbacks.onTextMessage({
    contains = "heal"  -- Messages containing "heal"
}, function(mode, text)
    print(string.format("Heal message: %s", text))
end)

-- Example 5: Monitor specific system messages
EnhancedCallbacks.onTextMessage({
    startsWith = "You see"  -- Messages starting with "You see"
}, function(mode, text)
    print(string.format("Observation: %s", text))
end)

-- ======================== --
-- [[ POSITION TRACKING ]] --
-- ======================== --

-- Example 6: Track movement
EnhancedCallbacks.onPositionChange(function(newPos, oldPos, movement, moveCount)
    if movement then
        print(string.format("Moved %d tiles %s (total moves: %d)",
            movement.distance,
            movement.direction or "unknown",
            moveCount))
    end
end)

-- Example 7: Area monitoring
local lastArea = nil
EnhancedCallbacks.onPositionChange(function(newPos, oldPos, movement, moveCount)
    local currentArea = string.format("%d,%d", math.floor(newPos.x / 100), math.floor(newPos.y / 100))

    if currentArea ~= lastArea then
        print(string.format("Entered new area: %s", currentArea))
        lastArea = currentArea
        -- You could trigger area-specific actions here
    end
end)

-- ======================== --
-- [[ HEALTH MONITORING ]] --
-- ======================== --

-- Example 8: Health change monitoring
EnhancedCallbacks.onHealthChange(function(healthPercent, healthChange, healthHistory)
    if healthChange then
        if healthChange.wasDamage then
            print(string.format("Damage taken: %d HP (now at %d%%)",
                math.abs(healthChange.healthDifference), healthPercent))
        elseif healthChange.wasHeal then
            print(string.format("Healed: +%d HP (now at %d%%)",
                healthChange.healthDifference, healthPercent))
        end
    end
end)

-- Example 9: Critical health warning
EnhancedCallbacks.onHealthChange(function(healthPercent, healthChange, healthHistory)
    if healthPercent <= 25 then
        print(string.format("CRITICAL HEALTH: %d%% - Take action!", healthPercent))
        -- You could trigger emergency healing or other actions here
    end
end)

-- ======================== --
-- [[ MANA MONITORING ]] --
-- ======================== --

-- Example 10: Mana change monitoring
EnhancedCallbacks.onManaChange(function(player, mana, maxMana, oldMana, oldMaxMana, manaChange, manaHistory)
    if manaChange then
        if manaChange.wasSpent then
            print(string.format("Mana spent: %d MP (now at %d%%)",
                math.abs(manaChange.manaDifference), manaChange.percentChange))
        elseif manaChange.wasGained then
            print(string.format("Mana gained: +%d MP (now at %d%%)",
                manaChange.manaDifference, manaChange.percentChange))
        end
    end
end)

-- Example 11: Low mana warning
EnhancedCallbacks.onManaChange(function(player, mana, maxMana, oldMana, oldMaxMana, manaChange, manaHistory)
    if manaChange and manaChange.percentChange <= 15 then
        print(string.format("LOW MANA: %d%% - Consider mana restoration", manaChange.percentChange))
        -- You could trigger mana potion usage or other actions here
    end
end)

-- ======================== --
-- [[ COMBAT TRACKING ]] --
-- ======================== --

-- Example 12: Target change monitoring
EnhancedCallbacks.onAttackingCreatureChange(function(creature, changeInfo)
    if changeInfo.targetChanged then
        if changeInfo.currentTarget then
            print(string.format("New target: %s (%s) - %d%% HP",
                changeInfo.currentTarget.name,
                changeInfo.currentTarget.type,
                changeInfo.currentTarget.healthPercent))
        else
            print("Target lost or cleared")
        end
    end
end)

-- Example 13: Combat state monitoring
local inCombat = false
EnhancedCallbacks.onAttackingCreatureChange(function(creature, changeInfo)
    local wasInCombat = inCombat
    inCombat = changeInfo.hasTarget

    if inCombat ~= wasInCombat then
        if inCombat then
            print("Entered combat")
        else
            print("Exited combat")
        end
    end
end)

-- ======================== --
-- [[ CREATURE TRACKING ]] --
-- ======================== --

-- Example 14: Monster appearance tracking
EnhancedCallbacks.onCreatureAppear(function(creature, creatureInfo)
    if creatureInfo and creatureInfo.type == "monster" then
        print(string.format("Monster appeared: %s at distance %d (HP: %d%%)",
            creatureInfo.name,
            creatureInfo.distance,
            creatureInfo.healthPercent))
    end
end)

-- Example 15: Player detection
EnhancedCallbacks.onCreatureAppear(function(creature, creatureInfo)
    if creatureInfo and creatureInfo.type == "player" and not creatureInfo.isPartyMember then
        print(string.format("Player detected: %s at distance %d",
            creatureInfo.name,
            creatureInfo.distance))
        -- You could add PvP awareness actions here
    end
end)

-- Example 16: Creature disappearance
EnhancedCallbacks.onCreatureDisappear(function(creature, creatureInfo)
    if creatureInfo and creatureInfo.type == "monster" then
        print(string.format("Monster disappeared: %s", creatureInfo.name))
    end
end)

-- ======================== --
-- [[ ITEM INTERACTION ]] --
-- ======================== --

-- Example 17: Item usage tracking
EnhancedCallbacks.onUse(function(pos, itemId, stackPos, subType, itemInfo)
    if itemInfo then
        print(string.format("Used item: %s (ID: %d) at position (%d,%d,%d)",
            itemInfo.name or "Unknown",
            itemId,
            pos.x, pos.y, pos.z))
    end
end)

-- Example 18: Item combination tracking
EnhancedCallbacks.onUseWith(function(pos, itemId, target, subType, useInfo)
    if useInfo then
        print(string.format("Used item %d with %s at (%d,%d,%d)",
            itemId,
            useInfo.targetName or "unknown",
            pos.x, pos.y, pos.z))
    end
end)

-- ======================== --
-- [[ CONTAINER TRACKING ]] --
-- ======================== --

-- Example 19: Container monitoring
EnhancedCallbacks.onContainerUpdate(function(container, operation, containerInfo)
    if containerInfo then
        print(string.format("Container %s: %s (%d/%d items)",
            containerInfo.name,
            operation,
            containerInfo.itemCount,
            containerInfo.capacity))
    end
end)

-- ======================== --
-- [[ UTILITY FUNCTIONS ]] --
-- ======================== --

-- Example 20: Find nearby monsters
local function scanForMonsters()
    local monsters = EnhancedCallbacks.getCreaturesInRange(pos(), 10, {type = "monster"})
    print(string.format("Found %d monsters within 10 tiles", #monsters))

    for _, monster in ipairs(monsters) do
        local info = {
            id = monster:getId(),
            name = monster:getName(),
            position = monster:getPosition(),
            healthPercent = monster:getHealthPercent(),
            distance = getDistanceBetween(pos(), monster:getPosition())
        }

        print(string.format("  %s - HP: %d%% - Distance: %d",
            info.name, info.healthPercent, info.distance))
    end
end

-- Example 21: Find nearby items
local function scanForItems(itemId)
    local items = EnhancedCallbacks.getItemsInRange(pos(), 5, itemId)
    if itemId then
        print(string.format("Found %d items with ID %d within 5 tiles", #items, itemId))
    else
        print(string.format("Found %d items within 5 tiles", #items))
    end

    for _, item in ipairs(items) do
        print(string.format("  Item ID %d (count: %d) at distance %d",
            item.id, item.count, item.distance))
    end
end

-- Example 22: Delayed action
local function delayedAction()
    EnhancedCallbacks.delayedCallback(5000, function()
        print("This message appears after 5 seconds")
    end)
end

-- Example 23: Conditional action
local function conditionalAction()
    EnhancedCallbacks.conditionalCallback(
        function() return hp() > 50 end,  -- Only if HP > 50%
        function() print("HP is good, proceeding with action") end
    )
end

-- ======================== --
-- [[ ADVANCED EXAMPLES ]] --
-- ======================== --

-- Example 24: Combat state machine
local combatState = "idle"
EnhancedCallbacks.onAttackingCreatureChange(function(creature, changeInfo)
    if changeInfo.hasTarget then
        if combatState ~= "fighting" then
            print("Combat started")
            combatState = "fighting"
        end
    else
        if combatState ~= "idle" then
            print("Combat ended")
            combatState = "idle"
        end
    end
end)

-- Example 25: Health-based auto actions
EnhancedCallbacks.onHealthChange(function(healthPercent, healthChange, healthHistory)
    if healthPercent <= 30 then
        -- Use health potion if available
        local potion = findItem(7590) or findItem(7588)  -- Mana/health potions
        if potion then
            g_game.useInventoryItemWith(potion:getId(), player)
            print("Auto-used health potion")
        end
    end
end)

-- Example 26: Mana-based auto actions
EnhancedCallbacks.onManaChange(function(player, mana, maxMana, oldMana, oldMaxMana, manaChange, manaHistory)
    if manaChange and manaChange.percentChange <= 20 then
        -- Use mana potion if available
        local potion = findItem(7589) or findItem(7588)  -- Mana potions
        if potion then
            g_game.useInventoryItemWith(potion:getId(), player)
            print("Auto-used mana potion")
        end
    end
end)

-- ======================== --
-- [[ DEBUGGING EXAMPLES ]] --
-- ======================== --

-- Example 27: Debug all callbacks (enable debug logging first)
-- setDebugMode(true) -- Uncomment to enable debug logging

-- Example 28: Monitor all text messages for debugging
EnhancedCallbacks.onTextMessage(nil, function(mode, text)
    -- Uncomment to see all text messages
    -- print(string.format("Text [%d]: %s", mode, text))
end)

-- Example 29: Monitor all position changes for debugging
EnhancedCallbacks.onPositionChange(function(newPos, oldPos, movement, moveCount)
    -- Uncomment to track all movement
    -- print(string.format("Position: (%d,%d,%d) Move #%d", newPos.x, newPos.y, newPos.z, moveCount))
end)

-- ======================== --
-- [[ QUICK START ]] --
-- ======================== --

-- To use these examples in your own scripts:

-- 1. Copy the callback registration you need
-- 2. Modify the callback function to suit your needs
-- 3. Add any additional logic or conditions
-- 4. Test the callback with your specific use case

-- Example quick start template:
--[[
-- Load enhanced callbacks (automatically loaded by _Loader.lua)
-- Register a simple callback
EnhancedCallbacks.onTalk(nil, function(name, level, mode, text, channelId, pos)
    -- Your code here
    print("Message from " .. name .. ": " .. text)
end)

-- Register a filtered callback
EnhancedCallbacks.onHealthChange(function(healthPercent, healthChange, healthHistory)
    -- Your code here
    if healthPercent <= 50 then
        print("Low health warning!")
    end
end)
]]

print("Enhanced Callbacks Examples loaded - check console for callback outputs")
print("Available functions: EnhancedCallbacks.onTalk, onTextMessage, onPositionChange, onHealthChange, onManaChange, onUse, onUseWith, onCreatureAppear, onCreatureDisappear, onAttackingCreatureChange, onMissile, onContainerUpdate")
print("Utility functions: getCreaturesInRange, getItemsInRange, delayedCallback, conditionalCallback")
