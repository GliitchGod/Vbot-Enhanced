CaveBot = {} -- global namespace

-------------------------------------------------------------------
-- CaveBot lib 1.0
-- Contains a universal set of functions to be used in CaveBot

----------------------[[ basic assumption ]]-----------------------
-- in general, functions cannot be slowed from within, only externally, by event calls, delays etc.
-- considering that and the fact that there is no while loop, every function return action
-- thus, functions will need to be verified outside themselfs or by another function
-- overall tips to creating extension:
--   - functions return action(nil) or true(done)
--   - extensions are controlled by retries var
-------------------------------------------------------------------

-- local variables, constants and functions, used by global functions
local LOCKERS_LIST = {3497, 3498, 3499, 3500}
local LOCKER_ACCESSTILE_MODIFIERS = {
    [3497] = {0,-1},
    [3498] = {1,0},
    [3499] = {0,1},
    [3500] = {-1,0}
}

local function CaveBotConfigParse()
	local name = storage["_configs"]["targetbot_configs"]["selected"]
    if not name then 
        return warn("[vBot] Please create a new TargetBot config and reset bot")
    end
	local file = configDir .. "/targetbot_configs/" .. name .. ".json"
	local data = g_resources.readFileContents(file)
	return Config.parse(data)['looting']
end

local function getNearTiles(pos)
    if type(pos) ~= "table" then
        pos = pos:getPosition()
    end

    local tiles = {}
    local dirs = {
        {-1, 1},
        {0, 1},
        {1, 1},
        {-1, 0},
        {1, 0},
        {-1, -1},
        {0, -1},
        {1, -1}
    }
    for i = 1, #dirs do
        local tile =
            g_map.getTile(
            {
                x = pos.x - dirs[i][1],
                y = pos.y - dirs[i][2],
                z = pos.z
            }
        )
        if tile then
            table.insert(tiles, tile)
        end
    end

    return tiles
end

-- ##################### --
-- [[ Information class ]] --
-- ##################### --

--- global variable to reflect current CaveBot status
CaveBot.Status = "waiting"

--- Parses config and extracts loot list.
-- @return table
function CaveBot.GetLootItems()
    local t = CaveBotConfigParse() and CaveBotConfigParse()["items"] or nil

    local returnTable = {}
    if type(t) == "table" then
        for i, item in pairs(t) do
            table.insert(returnTable, item["id"])
        end
    end

    return returnTable
end


--- Checks whether player has any visible items to be stashed
-- @return boolean
function CaveBot.HasLootItems()
    for _, container in pairs(getContainers()) do
        local name = container:getName():lower()
        if not name:find("depot") and not name:find("your inbox") then
            for _, item in pairs(container:getItems()) do
                local id = item:getId()
                if table.find(CaveBot.GetLootItems(), id) then
                    return true
                end
            end
        end
    end
end

--- Parses config and extracts loot containers.
-- @return table
function CaveBot.GetLootContainers()
    local t = CaveBotConfigParse() and CaveBotConfigParse()["containers"] or nil

    local returnTable = {}
    if type(t) == "table" then
        for i, container in pairs(t) do
            table.insert(returnTable, container["id"])
        end
    end

    return returnTable
end

--- Information about open containers.
-- @param amount is boolean
-- @return table or integer
function CaveBot.GetOpenedLootContainers(containerTable)
    local containers = CaveBot.GetLootContainers()

    local t = {}
    for i, container in pairs(getContainers()) do
        local containerId = container:getContainerItem():getId()
        if table.find(containers, containerId) then
            table.insert(t, container)
        end
    end

    return containerTable and t or #t
end

--- Some actions needs to be additionally slowed down in case of high ping.
-- Maximum at 2000ms in case of lag spike.
-- @param multiplayer is integer
-- @return void
function CaveBot.PingDelay(multiplayer)
    multiplayer = multiplayer or 1
    if ping() and ping() > 150 then -- in most cases ping above 150 affects CaveBot
        local value = math.min(ping() * multiplayer, 2000)
        return delay(value)
    end
end

-- ##################### --
-- [[ Container class ]] --
-- ##################### --

--- Closes any loot container that is open.
-- @return void or boolean
function CaveBot.CloseLootContainer()
    local containers = CaveBot.GetLootContainers()

    for i, container in pairs(getContainers()) do
        local containerId = container:getContainerItem():getId()
        if table.find(containers, containerId) then
            return g_game.close(container)
        end
    end

    return true
end

function CaveBot.CloseAllLootContainers()
    local containers = CaveBot.GetLootContainers()

    for i, container in pairs(getContainers()) do
        local containerId = container:getContainerItem():getId()
        if table.find(containers, containerId) then
            g_game.close(container)
        end
    end

    return true
end

--- Opens any loot container that isn't already opened.
-- @return void or boolean
function CaveBot.OpenLootContainer()
    local containers = CaveBot.GetLootContainers()

    local t = {}
    for i, container in pairs(getContainers()) do
        local containerId = container:getContainerItem():getId()
        table.insert(t, containerId)
    end

    for _, container in pairs(getContainers()) do
        for _, item in pairs(container:getItems()) do
            local id = item:getId()
            if table.find(containers, id) and not table.find(t, id) then
                return g_game.open(item)
            end
        end
    end

    return true
end

-- ##################### --
-- [[[ Position class ]] --
-- ##################### --

--- Compares distance between player position and given pos.
-- @param position is table
-- @param distance is integer
-- @return boolean
function CaveBot.MatchPosition(position, distance)
    local pPos = player:getPosition()
    distance = distance or 1
    return getDistanceBetween(pPos, position) <= distance
end

--- Stripped down to take less space.
-- Use only to safe position, like pz movement or reaching npc.
-- Needs to be called between 200-500ms to achieve fluid movement.
-- @param position is table
-- @param distance is integer
-- @return void
function CaveBot.GoTo(position, precision)
    if not precision then
        precision = 3
    end
    return CaveBot.walkTo(position, 20, {ignoreCreatures = true, precision = precision})
end

--- Finds position of npc by name and reaches its position.
-- @return void(acion) or boolean
function CaveBot.ReachNPC(name)
    name = name:lower()
    
    local npc = nil
    for i, spec in pairs(getSpectators()) do
        if spec:isNpc() and spec:getName():lower() == name then
            npc = spec
        end
    end

    if not CaveBot.MatchPosition(npc:getPosition(), 3) then
        CaveBot.GoTo(npc:getPosition())
    else
        return true
    end
end

-- ##################### --
-- [[[[ Depot class ]]]] --
-- ##################### --

--- Reaches closest locker.
-- @return void(acion) or boolean

local depositerLockerTarget = nil
local depositerLockerReachRetries = 0
function CaveBot.ReachDepot()
    local pPos = player:getPosition()
    local tiles = getNearTiles(player:getPosition())

    for i, tile in pairs(tiles) do
        for i, item in pairs(tile:getItems()) do
            if table.find(LOCKERS_LIST, item:getId()) then
                depositerLockerTarget = nil
                depositerLockerReachRetries = 0
                return true -- if near locker already then return function
            end
        end
    end

    if depositerLockerReachRetries > 20 then
        depositerLockerTarget = nil
        depositerLockerReachRetries = 0
    end

    local candidates = {}

    if not depositerLockerTarget or distanceFromPlayer(depositerLockerTarget, pPos) > 12 then
        for i, tile in pairs(g_map.getTiles(posz())) do
            local tPos = tile:getPosition()
            for i, item in pairs(tile:getItems()) do
                if table.find(LOCKERS_LIST, item:getId()) then
                    local lockerTilePos = tile:getPosition()
                          lockerTilePos.x = lockerTilePos.x + LOCKER_ACCESSTILE_MODIFIERS[item:getId()][1]
                          lockerTilePos.y = lockerTilePos.y + LOCKER_ACCESSTILE_MODIFIERS[item:getId()][2]
                    local lockerTile = g_map.getTile(lockerTilePos)
                    if not lockerTile:hasCreature() then
                        if findPath(pos(), tPos, 20, {ignoreNonPathable = false, precision = 1, ignoreCreatures = true}) then
                            local distance = getDistanceBetween(tPos, pPos)
                            table.insert(candidates, {pos=tPos, dist=distance})
                        end
                    end
                end
            end
        end

        if #candidates > 1 then
            table.sort(candidates, function(a,b) return a.dist < b.dist end)
        end
    end

    depositerLockerTarget = depositerLockerTarget or candidates[1].pos

    if depositerLockerTarget then
        if not CaveBot.MatchPosition(depositerLockerTarget) then
            depositerLockerReachRetries = depositerLockerReachRetries + 1
            return CaveBot.GoTo(depositerLockerTarget, 1)
        else
            depositerLockerReachRetries = 0
            depositerLockerTarget = nil
            return true
        end
    end
end

--- Opens locker item.
-- @return void(acion) or boolean
function CaveBot.OpenLocker()
    local pPos = player:getPosition()
    local tiles = getNearTiles(player:getPosition())

    local locker = getContainerByName("Locker")
    if not locker then
        for i, tile in pairs(tiles) do
            for i, item in pairs(tile:getItems()) do
                if table.find(LOCKERS_LIST, item:getId()) then
                    local topThing = tile:getTopUseThing()
                    if not topThing:isNotMoveable() then
                        g_game.move(topThing, pPos, topThing:getCount())
                    else
                        return g_game.open(item)
                    end
                end
            end
        end
    else
        return true
    end
end

--- Opens depot chest.
-- @return void(acion) or boolean
function CaveBot.OpenDepotChest()
    local depot = getContainerByName("Depot chest")
    if not depot then
        local locker = getContainerByName("Locker")
        if not locker then
            return CaveBot.OpenLocker()
        end
        for i, item in pairs(locker:getItems()) do
            if item:getId() == 3502 then
                return g_game.open(item, locker)
            end
        end
    else
        return true
    end
end

--- Opens inbox inside locker.
-- @return void(acion) or boolean
function CaveBot.OpenInbox()
    local inbox = getContainerByName("Your inbox")
    if not inbox then
        local locker = getContainerByName("Locker")
        if not locker then
            return CaveBot.OpenLocker()
        end
        for i, item in pairs(locker:getItems()) do
            if item:getId() == 12902 then
                return g_game.open(item)
            end
        end
    else
        return true
    end
end

--- Opens depot box of given number.
-- @param index is integer
-- @return void or boolean
function CaveBot.OpenDepotBox(index)
    local depot = getContainerByName("Depot chest")
    if not depot then
        return CaveBot.ReachAndOpenDepot()
    end

    local foundParent = false
    for i, container in pairs(getContainers()) do
        if container:getName():lower():find("depot box") then
            foundParent = container
            break
        end
    end
    if foundParent then return true end

    for i, container in pairs(depot:getItems()) do
        if i == index then
            return g_game.open(container)
        end
    end
end

--- Reaches and opens depot.
-- Combined for shorthand usage.
-- @return boolean whether succeed to reach and open depot
function CaveBot.ReachAndOpenDepot()
    if CaveBot.ReachDepot() and CaveBot.OpenDepotChest() then 
        return true 
    end
    return false
end

--- Reaches and opens imbox.
-- Combined for shorthand usage.
-- @return boolean whether succeed to reach and open depot
function CaveBot.ReachAndOpenInbox()
    if CaveBot.ReachDepot() and CaveBot.OpenInbox() then 
        return true 
    end
    return false
end

--- Stripped down function to stash item.
-- @param item is object
-- @param index is integer
-- @param destination is object
-- @return void
function CaveBot.StashItem(item, index, destination)
    destination = destination or getContainerByName("Depot chest")
    if not destination then return false end

    return g_game.move(item, destination:getSlotPosition(index), item:getCount())
end

--- Withdraws item from depot chest or mail inbox.
-- main function for depositer/withdrawer
-- @param id is integer
-- @param amount is integer
-- @param fromDepot is boolean or integer
-- @param destination is object
-- @return void
function CaveBot.WithdrawItem(id, amount, fromDepot, destination)
    if destination and type(destination) == "string" then
        destination = getContainerByName(destination)
    end
    local itemCount = itemAmount(id)
    local depot
    for i, container in pairs(getContainers()) do
        if container:getName():lower():find("depot box") or container:getName():lower():find("your inbox") then
            depot = container
            break
        end
    end
    if not depot then
        if fromDepot then
            if not CaveBot.OpenDepotBox(fromDepot) then return end
        else
            return CaveBot.ReachAndOpenInbox()
        end
        return
    end
    if not destination then
        for i, container in pairs(getContainers()) do
            if container:getCapacity() > #container:getItems() and not string.find(container:getName():lower(), "quiver") and not string.find(container:getName():lower(), "depot") and not string.find(container:getName():lower(), "loot") and not string.find(container:getName():lower(), "inbox") then
                destination = container
            end
        end
    end

    if itemCount >= amount then 
        return true 
    end

    local toMove = amount - itemCount
    for i, item in pairs(depot:getItems()) do
        if item:getId() == id then
            return g_game.move(item, destination:getSlotPosition(destination:getItemsCount()), math.min(toMove, item:getCount()))
        end
    end
end

-- ##################### --
-- [[[[[ Talk class ]]]] --
-- ##################### --

--- Controlled by event caller.
-- Simple way to build npc conversations instead of multiline overcopied code.
-- @return void
function CaveBot.Conversation(...)
    local expressions = {...}
    local delay = storage.extras.talkDelay or 1000

    local talkDelay = 0
    for i, expr in ipairs(expressions) do
        schedule(talkDelay, function() NPC.say(expr) end)
        talkDelay = talkDelay + delay
    end
end

--- Says hi trade to NPC.
-- Used as shorthand to open NPC trade window.
-- @return void
function CaveBot.OpenNpcTrade()
    return CaveBot.Conversation("hi", "trade")
end

--- Says hi destination yes to NPC.
-- Used as shorthand to travel.
-- @param destination is string
-- @return void
function CaveBot.Travel(destination)
    return CaveBot.Conversation("hi", destination, "yes")
end

-- ##################### --
-- [[ Enhanced Functions ]] --
-- ##################### --

--- Enhanced walking function with better validation and safety checks
-- @param position table with x, y, z coordinates
-- @param timeout maximum time to try walking (default 5000ms)
-- @param options table with additional options
-- @return boolean or action
function CaveBot.walkTo(position, timeout, options)
    if not position or type(position) ~= "table" then
        debugLog("error", "CaveBot.walkTo: Invalid position provided")
        return false
    end

    timeout = timeout or 5000
    options = options or {}

    local precision = options.precision or 1
    local ignoreCreatures = options.ignoreCreatures or false
    local ignoreNonPathable = options.ignoreNonPathable or false

    -- Enhanced position validation
    if not position.x or not position.y or not position.z then
        debugLog("error", "CaveBot.walkTo: Position missing coordinates")
        return false
    end

    -- Check if already at destination
    if CaveBot.MatchPosition(position, precision) then
        return true
    end

    -- Check if position is walkable
    local tile = g_map.getTile(position)
    if not tile or not tile:isWalkable() then
        debugLog("info", string.format("CaveBot.walkTo: Position not walkable (%d, %d, %d)",
            position.x, position.y, position.z))
        return false
    end

    -- Enhanced pathfinding with better options
    local path = findPath(pos(), position, 20, {
        ignoreNonPathable = ignoreNonPathable,
        precision = precision,
        ignoreCreatures = ignoreCreatures
    })

    if not path then
        debugLog("info", string.format("CaveBot.walkTo: No path found to (%d, %d, %d)",
            position.x, position.y, position.z))
        return false
    end

    -- Execute walking action
    return walkTo(path)
end

--- Enhanced item stashing with better validation and error handling
-- @param item item object to stash
-- @param destination optional destination container
-- @return boolean success status
function CaveBot.StashItemEnhanced(item, destination)
    if not item or type(item) ~= "table" then
        debugLog("error", "CaveBot.StashItemEnhanced: Invalid item provided")
        return false
    end

    destination = destination or getContainerByName("Depot chest")
    if not destination then
        debugLog("error", "CaveBot.StashItemEnhanced: No depot chest found")
        return false
    end

    -- Check if destination has space
    if not containerHasSpace(destination) then
        debugLog("info", "CaveBot.StashItemEnhanced: Depot chest is full")
        return false
    end

    local result = g_game.move(item, destination:getSlotPosition(destination:getItemsCount()), item:getCount())

    if result then
        debugLog("debug", string.format("CaveBot.StashItemEnhanced: Stashed item ID %d (count: %d)",
            item:getId(), item:getCount()))
    else
        debugLog("info", string.format("CaveBot.StashItemEnhanced: Failed to stash item ID %d",
            item:getId()))
    end

    return result
end

--- Enhanced item withdrawal with better validation
-- @param id item ID to withdraw
-- @param amount amount to withdraw
-- @param fromDepot depot box index or false for inbox
-- @param destination destination container
-- @return boolean success status
function CaveBot.WithdrawItemEnhanced(id, amount, fromDepot, destination)
    if not id or type(id) ~= "number" then
        debugLog("error", "CaveBot.WithdrawItemEnhanced: Invalid item ID")
        return false
    end

    if not amount or type(amount) ~= "number" or amount <= 0 then
        debugLog("error", "CaveBot.WithdrawItemEnhanced: Invalid amount")
        return false
    end

    -- Handle string destination names
    if destination and type(destination) == "string" then
        destination = getContainerByName(destination)
    end

    -- Check current item count
    local currentCount = itemAmount(id)
    if currentCount >= amount then
        debugLog("debug", string.format("CaveBot.WithdrawItemEnhanced: Already have enough of item ID %d", id))
        return true
    end

    -- Find depot container
    local depot = nil
    for _, container in pairs(getContainers()) do
        local name = container:getName():lower()
        if name:find("depot box") or name:find("your inbox") then
            depot = container
            break
        end
    end

    if not depot then
        if fromDepot then
            if not CaveBot.OpenDepotBox(fromDepot) then
                debugLog("error", "CaveBot.WithdrawItemEnhanced: Failed to open depot box")
                return false
            end
        else
            if not CaveBot.ReachAndOpenInbox() then
                debugLog("error", "CaveBot.WithdrawItemEnhanced: Failed to open inbox")
                return false
            end
        end
        return false
    end

    -- Find suitable destination container
    if not destination then
        for _, container in pairs(getContainers()) do
            local name = container:getName():lower()
            if containerHasSpace(container) and
               not name:find("quiver") and
               not name:find("depot") and
               not name:find("loot") and
               not name:find("inbox") then
                destination = container
                break
            end
        end
    end

    if not destination then
        debugLog("error", "CaveBot.WithdrawItemEnhanced: No suitable destination container found")
        return false
    end

    -- Calculate how much more we need
    local needed = amount - currentCount

    -- Find and withdraw items
    for _, item in pairs(depot:getItems()) do
        if item:getId() == id then
            local withdrawAmount = math.min(needed, item:getCount())
            local result = g_game.move(item, destination:getSlotPosition(destination:getItemsCount()), withdrawAmount)

            if result then
                debugLog("debug", string.format("CaveBot.WithdrawItemEnhanced: Withdrew %d of item ID %d",
                    withdrawAmount, id))
                needed = needed - withdrawAmount
                if needed <= 0 then
                    return true
                end
            else
                debugLog("info", string.format("CaveBot.WithdrawItemEnhanced: Failed to withdraw item ID %d", id))
                return false
            end
        end
    end

    debugLog("info", string.format("CaveBot.WithdrawItemEnhanced: Could not find enough of item ID %d", id))
    return false
end

--- Enhanced NPC conversation with better error handling
-- @param ... variable number of expressions to say
-- @return void
function CaveBot.ConversationEnhanced(...)
    local expressions = {...}
    if #expressions == 0 then return end

    local delay = storage.extras.talkDelay or 1000

    -- Validate all expressions
    for i, expr in ipairs(expressions) do
        if not expr or type(expr) ~= "string" then
            debugLog("error", string.format("CaveBot.ConversationEnhanced: Invalid expression at index %d", i))
            return
        end
    end

    local talkDelay = 0
    for i, expr in ipairs(expressions) do
        schedule(talkDelay, function()
            NPC.say(expr)
            debugLog("debug", string.format("CaveBot.ConversationEnhanced: Said '%s' (delay: %dms)", expr, talkDelay))
        end)
        talkDelay = talkDelay + delay
    end
end

--- Enhanced NPC reaching with better validation
-- @param name NPC name to reach
-- @param maxRetries maximum number of retries (default 10)
-- @return boolean success status
function CaveBot.ReachNPCEnhanced(name, maxRetries)
    if not name or type(name) ~= "string" then
        debugLog("error", "CaveBot.ReachNPCEnhanced: Invalid NPC name")
        return false
    end

    maxRetries = maxRetries or 10
    local retries = 0

    name = name:lower()

    local npc = nil
    for _, spec in pairs(getSpectators()) do
        if spec:isNpc() and spec:getName():lower() == name then
            npc = spec
            break
        end
    end

    if not npc then
        debugLog("info", string.format("CaveBot.ReachNPCEnhanced: NPC '%s' not found", name))
        return false
    end

    local npcPos = npc:getPosition()

    if CaveBot.MatchPosition(npcPos, 3) then
        debugLog("debug", string.format("CaveBot.ReachNPCEnhanced: Already near NPC '%s'", name))
        return true
    end

    if retries >= maxRetries then
        debugLog("info", string.format("CaveBot.ReachNPCEnhanced: Max retries reached for NPC '%s'", name))
        return false
    end

    retries = retries + 1
    return CaveBot.GoTo(npcPos)
end

--- Enhanced depot reaching with better error handling
-- @param maxRetries maximum retries for reaching depot
-- @return boolean success status
function CaveBot.ReachDepotEnhanced(maxRetries)
    maxRetries = maxRetries or 20

    local pPos = player:getPosition()
    local tiles = getNearTiles(pPos)

    -- Check if already near a locker
    for _, tile in pairs(tiles) do
        for _, item in pairs(tile:getItems()) do
            if table.find(LOCKERS_LIST, item:getId()) then
                depositerLockerTarget = nil
                depositerLockerReachRetries = 0
                return true
            end
        end
    end

    -- Reset if too many retries
    if depositerLockerReachRetries > maxRetries then
        depositerLockerTarget = nil
        depositerLockerReachRetries = 0
        debugLog("info", "CaveBot.ReachDepotEnhanced: Max retries reached, resetting")
        return false
    end

    local candidates = {}

    -- Find locker candidates if needed
    if not depositerLockerTarget or getDistanceBetween(depositerLockerTarget, pPos) > 12 then
        for _, tile in pairs(g_map.getTiles(posz())) do
            local tPos = tile:getPosition()
            for _, item in pairs(tile:getItems()) do
                if table.find(LOCKERS_LIST, item:getId()) then
                    local lockerTilePos = {
                        x = tPos.x + LOCKER_ACCESSTILE_MODIFIERS[item:getId()][1],
                        y = tPos.y + LOCKER_ACCESSTILE_MODIFIERS[item:getId()][2],
                        z = tPos.z
                    }
                    local lockerTile = g_map.getTile(lockerTilePos)

                    if lockerTile and not lockerTile:hasCreature() then
                        if findPath(pos(), tPos, 20, {
                            ignoreNonPathable = false,
                            precision = 1,
                            ignoreCreatures = true
                        }) then
                            local distance = getDistanceBetween(tPos, pPos)
                            table.insert(candidates, {pos = tPos, dist = distance})
                        end
                    end
                end
            end
        end

        if #candidates == 0 then
            debugLog("info", "CaveBot.ReachDepotEnhanced: No accessible lockers found")
            return false
        end

        -- Sort by distance
        if #candidates > 1 then
            table.sort(candidates, function(a, b) return a.dist < b.dist end)
        end
    end

    depositerLockerTarget = depositerLockerTarget or candidates[1].pos

    if depositerLockerTarget then
        if not CaveBot.MatchPosition(depositerLockerTarget) then
            depositerLockerReachRetries = depositerLockerReachRetries + 1
            return CaveBot.GoTo(depositerLockerTarget, 1)
        else
            depositerLockerReachRetries = 0
            depositerLockerTarget = nil
            return true
        end
    end

    return false
end

--- Check if player is stuck (not moving for a while)
-- @param threshold time in milliseconds to consider stuck (default 3000)
-- @return boolean
function CaveBot.IsStuck(threshold)
    threshold = threshold or 3000
    return standTime() > threshold
end

--- Enhanced delay function that respects cavebot state
-- @param ms milliseconds to delay
-- @return void
function CaveBot.Delay(ms)
    if not ms or type(ms) ~= "number" or ms <= 0 then return end

    -- Check if targetbot is working and adjust delay
    if TargetBot and TargetBot.isOn and TargetBot.isOn() then
        ms = ms + 300 -- Add extra delay when targetbot is active
    end

    delay(ms)
end

--- Get cavebot status information
-- @return table with status information
function CaveBot.GetStatus()
    local status = {
        isActive = CaveBot.isOn(),
        isWalking = CaveBot.doWalking(),
        isStuck = CaveBot.IsStuck(),
        standTime = standTime(),
        currentPosition = player:getPosition(),
        healthPercent = getHealthPercent(),
        manaPercent = getManaPercent()
    }

    -- Add container information
    local containers = getContainers()
    status.containerCount = #containers
    status.hasDepot = false
    status.hasInbox = false

    for _, container in pairs(containers) do
        local name = container:getName():lower()
        if name:find("depot") then
            status.hasDepot = true
        elseif name:find("inbox") then
            status.hasInbox = true
        end
    end

    return status
end

--- Enhanced action execution with better error handling
-- @param actionName name of the action to execute
-- @param value value to pass to the action
-- @return result of action execution
function CaveBot.ExecuteAction(actionName, value)
    if not actionName or type(actionName) ~= "string" then
        debugLog("error", "CaveBot.ExecuteAction: Invalid action name")
        return false
    end

    local action = CaveBot.Actions[actionName]
    if not action then
        debugLog("error", string.format("CaveBot.ExecuteAction: Action '%s' not found", actionName))
        return false
    end

    if not action.callback then
        debugLog("error", string.format("CaveBot.ExecuteAction: Action '%s' has no callback", actionName))
        return false
    end

    local success, result = pcall(function()
        return action.callback(value, 0, true)
    end)

    if not success then
        debugLog("error", string.format("CaveBot.ExecuteAction: Error executing action '%s': %s", actionName, result))
        return false
    end

    return result
end

-- Enhanced waypoint skipping functions
function CaveBot.setSkipBlockedMode(enabled)
    if type(enabled) ~= "boolean" then enabled = true end

    -- Store the current skipBlocked setting
    if not CaveBot._originalSkipBlocked then
        CaveBot._originalSkipBlocked = CaveBot.Config.get("skipBlocked")
    end

    CaveBot.Config.set("skipBlocked", enabled)

    if enabled then
        debugLog("info", "CaveBot: Skip blocked waypoints enabled - will skip non-pathable waypoints")
    else
        debugLog("info", "CaveBot: Skip blocked waypoints disabled - will retry unreachable waypoints")
    end

    return true
end

function CaveBot.isSkipBlockedMode()
    return CaveBot.Config.get("skipBlocked") == true
end

function CaveBot.resetSkipBlockedMode()
    if CaveBot._originalSkipBlocked ~= nil then
        CaveBot.Config.set("skipBlocked", CaveBot._originalSkipBlocked)
        debugLog("info", "CaveBot: Skip blocked mode reset to original setting")
        return true
    end
    return false
end

-- Enhanced status information
function CaveBot.getEnhancedStatus()
    local status = CaveBot.GetStatus()
    status.skipBlocked = CaveBot.isSkipBlockedMode()
    status.isOn = CaveBot.isOn()
    status.isWalking = CaveBot.doWalking()
    status.maxGotoDistance = storage.extras.gotoMaxDistance or 100

    -- Add waypoint information if available
    if CaveBot.actionList then
        local actions = CaveBot.actionList:getChildCount()
        local currentAction = CaveBot.actionList:getFocusedChild()

        status.totalWaypoints = actions
        status.currentWaypointIndex = currentAction and CaveBot.actionList:getChildIndex(currentAction) or 0
        status.currentWaypoint = currentAction and {
            action = currentAction.action,
            value = currentAction.value
        } or nil
    end

    -- Add targetbot integration info
    status.targetBotActive = TargetBot and TargetBot.isActive and TargetBot.isActive() or false
    status.creatureAvoidance = status.targetBotActive and "disabled" or "enabled"

    return status
end

-- Enhanced goto distance management
function CaveBot.setMaxGotoDistance(distance)
    if type(distance) ~= "number" or distance < 10 or distance > 500 then
        debugLog("error", string.format("CaveBot.setMaxGotoDistance: Invalid distance %s, must be 10-500", tostring(distance)))
        return false
    end

    storage.extras.gotoMaxDistance = distance
    debugLog("info", string.format("CaveBot: Max goto distance set to %d tiles", distance))
    return true
end

function CaveBot.getMaxGotoDistance()
    return storage.extras.gotoMaxDistance or 100
end

function CaveBot.resetMaxGotoDistance()
    storage.extras.gotoMaxDistance = nil
    debugLog("info", "CaveBot: Max goto distance reset to default (100)")
    return true
end

-- Initialize cavebot debug logging
debugLog("info", "CaveBot library enhanced and loaded")