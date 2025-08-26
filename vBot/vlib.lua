-- Author: Vithrax
-- contains mostly basic function shortcuts and code shorteners

-- initial global variables declaration
vBot = {} -- global namespace for bot variables
vBot.BotServerMembers = {}
vBot.standTime = now
vBot.isUsingPotion = false
vBot.isUsing = false
vBot.customCooldowns = {}

function logInfo(text)
    local timestamp = os.date("%H:%M:%S")
    text = tostring(text)
    local start = timestamp.." [vBot]: "

    return modules.client_terminal.addLine(start..text, "orange") 
end

-- scripts / functions
onPlayerPositionChange(function(x,y)
    vBot.standTime = now
end)

function standTime()
    return now - vBot.standTime
end

function relogOnCharacter(charName)
    local characters = g_ui.getRootWidget().charactersWindow.characters
    for index, child in ipairs(characters:getChildren()) do
        local name = child:getChildren()[1]:getText()
    
        if name:lower():find(charName:lower()) then
            child:focus()
            schedule(100, modules.client_entergame.CharacterList.doLogin)
        end
    end
end

function castSpell(text)
    if canCast(text) then
        say(text)
    end
end

-- Optimized damage tracking system with better performance
local dmgTable = {}
local lastDmgCleanup = now
local lastDmgMessage = now
local MAX_DAMAGE_ENTRIES = 50 -- Prevent memory bloat

onTextMessage(function(mode, text)
    if not text:lower():find("you lose") or not text:lower():find("due to") then
        return
    end

    local dmg = string.match(text, "%d+")
    if not dmg then return end

    dmg = tonumber(dmg)
    if not dmg or dmg <= 0 then return end

    -- Optimized cleanup: only run every 2 seconds instead of every message
    if now - lastDmgCleanup > 2000 then
        local cutoffTime = now - 3000
        local newTable = {}
        for i, v in ipairs(dmgTable) do
            if v.t > cutoffTime then
                table.insert(newTable, v)
            end
        end
        dmgTable = newTable
        lastDmgCleanup = now
    end

    -- Prevent table from growing too large
    if #dmgTable >= MAX_DAMAGE_ENTRIES then
        table.remove(dmgTable, 1) -- Remove oldest entry
    end

    lastDmgMessage = now
    table.insert(dmgTable, {d = dmg, t = now})
end)

-- Enhanced burst damage calculation with better accuracy
-- returns number
function burstDamageValue()
    if #dmgTable == 0 then return 0 end

    -- Clean up old entries before calculation
    local cutoffTime = now - 3000
    local validEntries = {}
    for i, v in ipairs(dmgTable) do
        if v.t > cutoffTime then
            table.insert(validEntries, v)
        end
    end

    if #validEntries <= 1 then
        return #validEntries == 1 and validEntries[1].d or 0
    end

    local totalDamage = 0
    local timeSpan = validEntries[#validEntries].t - validEntries[1].t

    -- Calculate total damage over the time span
    for i, v in ipairs(validEntries) do
        totalDamage = totalDamage + v.d
    end

    -- Avoid division by zero and ensure reasonable time span
    if timeSpan <= 0 then timeSpan = 100 end

    return math.ceil(totalDamage / (timeSpan / 1000))
end

-- Additional damage tracking functions
function getTotalDamageInLast(seconds)
    if type(seconds) ~= "number" or seconds <= 0 then return 0 end

    local cutoffTime = now - (seconds * 1000)
    local total = 0

    for i, v in ipairs(dmgTable) do
        if v.t > cutoffTime then
            total = total + v.d
        end
    end

    return total
end

function getDamagePerSecond()
    return burstDamageValue()
end

-- simplified function from modules
-- displays string as white colour message
function whiteInfoMessage(text)
    return modules.game_textmessage.displayGameMessage(text)
end

function statusMessage(text, logInConsole)
    return not logInConsole and modules.game_textmessage.displayFailureMessage(text) or modules.game_textmessage.displayStatusMessage(text)
end

-- same as above but red message
function broadcastMessage(text)
    return modules.game_textmessage.displayBroadcastMessage(text)
end

-- almost every talk action inside cavebot has to be done by using schedule
-- therefore this is simplified function that doesn't require to build a body for schedule function
function scheduleNpcSay(text, delay)
    if not text or not delay then return false end

    return schedule(delay, function() NPC.say(text) end)
end

-- returns first number in string, already formatted as number
-- returns number or nil
function getFirstNumberInText(text)
    local n = nil
    if string.match(text, "%d+") then n = tonumber(string.match(text, "%d+")) end
    return n
end

-- function to search if item of given ID can be found on certain tile
-- first argument is always ID 
-- the rest of aguments can be:
-- - tile
-- - position
-- - or x,y,z coordinates as p1, p2 and p3
-- returns boolean
function isOnTile(id, p1, p2, p3)
    if not id then return end
    local tile
    if type(p1) == "table" then
        tile = g_map.getTile(p1)
    elseif type(p1) ~= "number" then
        tile = p1
    else
        local p = getPos(p1, p2, p3)
        tile = g_map.getTile(p)
    end
    if not tile then return end

    local item = false
    if #tile:getItems() ~= 0 then
        for i, v in ipairs(tile:getItems()) do
            if v:getId() == id then item = true end
        end
    else
        return false
    end

    return item
end

-- position is a special table, impossible to compare with normal one
-- this is translator from x,y,z to proper position value
-- returns position table
function getPos(x, y, z)
    if not x or not y or not z then return nil end
    local pos = pos()
    pos.x = x
    pos.y = y
    pos.z = z

    return pos
end

-- Enhanced purse and container functions with better validation
function openPurse()
    local player = g_game.getLocalPlayer()
    if not player then return false end

    local purse = player:getInventoryItem(InventorySlotPurse)
    if not purse then return false end

    return g_game.use(purse)
end

-- Enhanced container functions with better validation and additional utilities
function containerIsFull(c)
    if not c or type(c) ~= "table" then return false end
    if not c.getCapacity or not c.getItems then return false end

    local capacity = c:getCapacity()
    local itemCount = #c:getItems()

    return capacity <= itemCount
end

function containerHasSpace(c, itemSize)
    if not c or type(c) ~= "table" then return false end
    if not c.getCapacity or not c.getItems then return false end

    itemSize = itemSize or 1
    if itemSize < 1 then return false end

    local capacity = c:getCapacity()
    local itemCount = #c:getItems()

    return (capacity - itemCount) >= itemSize
end

function getContainerFreeSlots(c)
    if not c or type(c) ~= "table" then return 0 end
    if not c.getCapacity or not c.getItems then return 0 end

    local capacity = c:getCapacity()
    local itemCount = #c:getItems()

    return math.max(0, capacity - itemCount)
end

-- Enhanced item dropping with better validation and options
function dropItem(idOrObject, count)
    if not idOrObject then return false end

    local item
    if type(idOrObject) == "number" then
        item = findItem(idOrObject)
    else
        item = idOrObject
    end

    if not item then return false end

    count = count or item:getCount()
    if count <= 0 then return false end

    -- Ensure we don't drop more than the item has
    count = math.min(count, item:getCount())

    return g_game.move(item, pos(), count)
end

-- Additional utility functions for item and container management
function getItemCount(id)
    if type(id) ~= "number" then return 0 end

    local items = findItems(id)
    local total = 0

    for _, item in ipairs(items) do
        total = total + item:getCount()
    end

    return total
end

function hasItem(id, count)
    if type(id) ~= "number" then return false end
    count = count or 1

    return getItemCount(id) >= count
end

function getContainerByName(name)
    if type(name) ~= "string" then return nil end

    for _, container in pairs(getContainers()) do
        if container:getName():lower():find(name:lower()) then
            return container
        end
    end

    return nil
end

function getBestContainerForItem(itemId)
    if type(itemId) ~= "number" then return nil end

    local bestContainer = nil
    local mostFreeSlots = -1

    for _, container in pairs(getContainers()) do
        local name = container:getName():lower()
        -- Skip depot boxes for regular items
        if not name:find("depot") and not name:find("your inbox") then
            local freeSlots = getContainerFreeSlots(container)
            if freeSlots > mostFreeSlots then
                mostFreeSlots = freeSlots
                bestContainer = container
            end
        end
    end

    return bestContainer
end

-- not perfect function to return whether character has utito tempo buff
-- known to be bugged if received debuff (ie. roshamuul)
-- TODO: simply a better version
-- returns boolean
function isBuffed()
    local var = false
    if not hasPartyBuff() then return var end

    local skillId = 0
    for i = 1, 4 do
        if player:getSkillBaseLevel(i) > player:getSkillBaseLevel(skillId) then
            skillId = i
        end
    end

    local premium = (player:getSkillLevel(skillId) - player:getSkillBaseLevel(skillId))
    local base = player:getSkillBaseLevel(skillId)
    if (premium / 100) * 305 > base then
        var = true
    end
    return var
end

-- if using index as table element, this can be used to properly assign new idex to all values
-- table needs to contain "index" as value
-- if no index in tables, it will create one
function reindexTable(t)
    if not t or type(t) ~= "table" then return end

    local i = 0
    for _, e in pairs(t) do
        i = i + 1
        e.index = i
    end
end

-- supports only new tibia, ver 10+
-- returns how many kills left to get next skull - can be red skull, can be black skull!
-- reutrns number
function killsToRs()
    return math.min(g_game.getUnjustifiedPoints().killsDayRemaining,
                    g_game.getUnjustifiedPoints().killsWeekRemaining,
                    g_game.getUnjustifiedPoints().killsMonthRemaining)
end

-- calculates exhaust for potions based on "Aaaah..." message
-- changes state of vBot variable, can be used in other scripts
-- already used in pushmax, healbot, etc

onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then return end
    if mode ~= 34 then return end

    if text == "Aaaah..." then
        vBot.isUsingPotion = true
        schedule(950, function() vBot.isUsingPotion = false end)
    end
end)

-- [[ Enhanced spell casting system ]] --
-- Optimized spell tracking with better memory management
SpellCastTable = {}
local MAX_SPELL_ENTRIES = 100 -- Prevent memory bloat
local spellCleanupTime = now

-- Enhanced spell cast detection with better validation
onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then return end
    if not text then return end

    text = text:lower()

    -- Only process if it's actually a spell being tracked
    if SpellCastTable[text] then
        SpellCastTable[text].t = now
        SpellCastTable[text].lastCast = now
    end
end)

-- Periodic cleanup of old spell entries to prevent memory bloat
macro(5000, function()
    local cutoffTime = now - 300000 -- 5 minutes ago
    local toRemove = {}

    for spell, data in pairs(SpellCastTable) do
        if now - data.t > data.d * 3 then -- 3x the spell delay
            table.insert(toRemove, spell)
        end
    end

    for _, spell in ipairs(toRemove) do
        SpellCastTable[spell] = nil
    end

    -- Prevent table from growing too large
    local count = 0
    for _ in pairs(SpellCastTable) do count = count + 1 end

    if count > MAX_SPELL_ENTRIES then
        local removeCount = count - MAX_SPELL_ENTRIES + 10
        local removed = 0
        for spell, data in pairs(SpellCastTable) do
            if removed >= removeCount then break end
            SpellCastTable[spell] = nil
            removed = removed + 1
        end
    end
end)

-- Enhanced cast function with better validation and safety
function cast(text, delay)
    if type(text) ~= "string" or text == "" then return false end

    text = text:lower()

    -- Validate delay parameter
    if delay and (type(delay) ~= "number" or delay < 0) then
        delay = nil
    end

    if not delay or delay < 100 then
        return say(text) -- if not added delay or delay is really low then just treat it like casual say
    end

    -- Initialize or update spell tracking
    if not SpellCastTable[text] or SpellCastTable[text].d ~= delay then
        SpellCastTable[text] = {
            t = now - delay,  -- Set to past so it can be cast immediately
            d = delay,
            lastCast = 0
        }
        return say(text)
    end

    local lastCast = SpellCastTable[text].t
    local spellDelay = SpellCastTable[text].d

    if now - lastCast > spellDelay then
        local result = say(text)
        if result then
            SpellCastTable[text].lastCast = now
        end
        return result
    end

    return false -- Spell still on cooldown
end

-- Enhanced canCast with better validation and additional checks
local Spells = modules.gamelib.SpellInfo['Default']
function canCast(spell, ignoreRL, ignoreCd)
    if type(spell) ~= "string" or spell == "" then return false end

    spell = spell:lower()

    -- Check custom spell table first
    if SpellCastTable[spell] then
        if ignoreCd or now - SpellCastTable[spell].t > SpellCastTable[spell].d then
            return true
        else
            return false
        end
    end

    -- Check game spell data
    local spellData = getSpellData(spell)
    if spellData then
        local hasMana = mana() >= (spellData.mana or 0)
        local hasLevel = level() >= (spellData.level or 0)
        local notOnCooldown = ignoreCd or not getSpellCoolDown(spell)

        if (ignoreRL or (hasMana and hasLevel)) and notOnCooldown then
            return true
        else
            return false
        end
    end

    -- If no spell data found, allow casting (for custom spells)
    return true
end

-- Additional utility functions for spell management
function getSpellCooldownRemaining(spell)
    if type(spell) ~= "string" then return 0 end

    spell = spell:lower()

    if SpellCastTable[spell] then
        local timeSinceCast = now - SpellCastTable[spell].t
        local remaining = SpellCastTable[spell].d - timeSinceCast
        return math.max(0, remaining)
    end

    return 0
end

function isSpellReady(spell)
    return canCast(spell, false, false)
end

function forceCast(spell)
    return canCast(spell, true, true) and cast(spell)
end

local lastPhrase = ""
onTalk(function(name, level, mode, text, channelId, pos)
    if name == player:getName() then
        lastPhrase = text:lower()
    end
end)

if onSpellCooldown and onGroupSpellCooldown then
    onSpellCooldown(function(iconId, duration)
        schedule(1, function()
            if not vBot.customCooldowns[lastPhrase] then
                vBot.customCooldowns[lastPhrase] = {id = iconId}
            end
        end)
    end)

    onGroupSpellCooldown(function(iconId, duration)
        schedule(2, function()
            if vBot.customCooldowns[lastPhrase] then
                vBot.customCooldowns[lastPhrase] = {id = vBot.customCooldowns[lastPhrase].id, group = {[iconId] = duration}}
            end
        end)
    end)
else
    warn("Outdated OTClient! update to newest version to take benefits from all scripts!")
end

-- exctracts data about spell from gamelib SpellInfo table
-- returns table
-- ie:['Spell Name'] = {id, words, exhaustion, premium, type, icon, mana, level, soul, group, vocations}
-- cooldown detection module
function getSpellData(spell)
    if not spell then return false end
    spell = spell:lower()
    local t = nil
    local c = nil
    for k, v in pairs(Spells) do
        if v.words == spell then
            t = k
            break
        end
    end
    if not t then
        for k, v in pairs(vBot.customCooldowns) do
            if k == spell then
                c = {id = v.id, mana = 1, level = 1, group = v.group}
                break
            end
        end
    end
    if t then
        return Spells[t]
    elseif c then
        return c
    else
        return false
    end
end

-- based on info extracted by getSpellData checks if spell is on cooldown
-- returns boolean
function getSpellCoolDown(text)
    if not text then return nil end
    text = text:lower()
    local data = getSpellData(text)
    if not data then return false end
    local icon = modules.game_cooldown.isCooldownIconActive(data.id)
    local group = false
    for groupId, duration in pairs(data.group) do
        if modules.game_cooldown.isGroupCooldownIconActive(groupId) then
            group = true
            break
        end
    end
    if icon or group then
        return true
    else
        return false
    end
end

-- global var to indicate that player is trying to do something
-- prevents action blocking by scripts
-- below callbacks are triggers to changing the var state
local isUsingTime = now
macro(100, function()
    vBot.isUsing = now < isUsingTime and true or false
end)
onUse(function(pos, itemId, stackPos, subType)
    if pos.x > 65000 then return end
    if getDistanceBetween(player:getPosition(), pos) > 1 then return end
    local tile = g_map.getTile(pos)
    if not tile then return end

    local topThing = tile:getTopUseThing()
    if topThing:isContainer() then return end

    isUsingTime = now + 1000
end)
onUseWith(function(pos, itemId, target, subType)
    if pos.x < 65000 then isUsingTime = now + 1000 end
end)

-- returns first word in string 
function string.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

-- Enhanced player relationship system with better caching and performance
CachedFriends = {}
CachedEnemies = {}
local CACHE_CLEANUP_INTERVAL = 30000 -- Clean cache every 30 seconds
local lastCacheCleanup = now

-- Periodic cache cleanup to prevent memory bloat
macro(CACHE_CLEANUP_INTERVAL, function()
    -- Simple cleanup: remove entries that haven't been accessed recently
    -- This is a lightweight approach to prevent the cache from growing too large
    local currentTime = now
    local toRemoveFriends = {}
    local toRemoveEnemies = {}

    for creature, timestamp in pairs(CachedFriends) do
        if type(timestamp) == "number" and currentTime - timestamp > CACHE_CLEANUP_INTERVAL * 2 then
            table.insert(toRemoveFriends, creature)
        end
    end

    for creature, timestamp in pairs(CachedEnemies) do
        if type(timestamp) == "number" and currentTime - timestamp > CACHE_CLEANUP_INTERVAL * 2 then
            table.insert(toRemoveEnemies, creature)
        end
    end

    for _, creature in ipairs(toRemoveFriends) do
        CachedFriends[creature] = nil
    end

    for _, creature in ipairs(toRemoveEnemies) do
        CachedEnemies[creature] = nil
    end
end)

-- Enhanced friend detection with better caching and validation
function isFriend(c)
    if not c then return false end

    local name = c
    local creature = c

    if type(c) ~= "string" then
        if c == player then return true end
        if not c.getName then return false end
        name = c:getName()
        if not name then return false end
    end

    -- Check cache first with timestamp validation
    if CachedFriends[creature] then
        if type(CachedFriends[creature]) == "number" then
            CachedFriends[creature] = now -- Update access time
        end
        return CachedFriends[creature] == true or type(CachedFriends[creature]) == "number"
    end

    if CachedEnemies[creature] then
        if type(CachedEnemies[creature]) == "number" then
            CachedEnemies[creature] = now
        end
        return false
    end

    -- Check friend list
    if storage.playerList and storage.playerList.friendList and table.find(storage.playerList.friendList, name) then
        CachedFriends[creature] = now
        return true
    end

    -- Check bot server members
    if vBot.BotServerMembers and vBot.BotServerMembers[name] then
        CachedFriends[creature] = now
        return true
    end

    -- Check party members
    if storage.playerList and storage.playerList.groupMembers then
        local p = creature
        if type(creature) == "string" then
            p = getCreatureByName(creature, true)
        end

        if p and p:isLocalPlayer() then
            CachedFriends[creature] = now
            return true
        end

        if p and p:isPlayer() and p:isPartyMember() then
            CachedFriends[creature] = now
            CachedFriends[p] = now
            return true
        end
    end

    -- Cache negative result to avoid repeated lookups
    CachedEnemies[creature] = now
    return false
end

-- Enhanced enemy detection with better validation
function isEnemy(c)
    if not c then return false end

    local name = c
    local p = nil

    if type(c) ~= "string" then
        if c == player then return false end
        if not c.getName then return false end
        name = c:getName()
        p = c
    end

    if not name then return false end

    if not p then
        p = getCreatureByName(name, true)
    end

    if not p then return false end

    if p:isLocalPlayer() then return false end

    -- Check cache first
    if CachedEnemies[p] then
        if type(CachedEnemies[p]) == "number" then
            CachedEnemies[p] = now
        end
        return true
    end

    -- Check enemy list
    if storage.playerList and storage.playerList.enemyList and table.find(storage.playerList.enemyList, name) then
        CachedEnemies[p] = now
        return true
    end

    -- Check marks setting
    if storage.playerList and storage.playerList.marks and not isFriend(name) then
        CachedEnemies[p] = now
        return true
    end

    -- Check emblem (skull)
    if p:getEmblem() == 2 then
        CachedEnemies[p] = now
        return true
    end

    -- Cache negative result
    CachedFriends[p] = now
    return false
end

function getPlayerDistribution()
    local friends = {}
    local neutrals = {}
    local enemies = {}
    for i, spec in ipairs(getSpectators()) do
        if spec:isPlayer() and not spec:isLocalPlayer() then
            if isFriend(spec) then
                table.insert(friends, spec)
            elseif isEnemy(spec) then
                table.insert(enemies, spec)
            else
                table.insert(neutrals, spec)
            end
        end
    end

    return friends, neutrals, enemies
end

function getFriends()
    local friends, neutrals, enemies = getPlayerDistribution()

    return friends
end

function getNeutrals()
    local friends, neutrals, enemies = getPlayerDistribution()

    return neutrals
end

function getEnemies()
    local friends, neutrals, enemies = getPlayerDistribution()

    return enemies
end

-- based on first word in string detects if text is a offensive spell
-- returns boolean
function isAttSpell(expr)
    if string.starts(expr, "exori") or string.starts(expr, "exevo") then
        return true
    else
        return false
    end
end

-- returns dressed-up item id based on not dressed id
-- returns number
function getActiveItemId(id)
    if not id then return false end

    if id == 3049 then
        return 3086
    elseif id == 3050 then
        return 3087
    elseif id == 3051 then
        return 3088
    elseif id == 3052 then
        return 3089
    elseif id == 3053 then
        return 3090
    elseif id == 3091 then
        return 3094
    elseif id == 3092 then
        return 3095
    elseif id == 3093 then
        return 3096
    elseif id == 3097 then
        return 3099
    elseif id == 3098 then
        return 3100
    elseif id == 16114 then
        return 16264
    elseif id == 23531 then
        return 23532
    elseif id == 23533 then
        return 23534
    elseif id == 23544 then
        return 23528
    elseif id == 23529 then
        return 23530
    elseif id == 30343 then -- Sleep Shawl
        return 30342
    elseif id == 30344 then -- Enchanted Pendulet
        return 30345
    elseif id == 30403 then -- Enchanted Theurgic Amulet
        return 30402
    elseif id == 31621 then -- Blister Ring
        return 31616
    elseif id == 32621 then -- Ring of Souls
        return 32635
    else
        return id
    end
end

-- returns not dressed item id based on dressed-up id
-- returns number
function getInactiveItemId(id)
    if not id then return false end

    if id == 3086 then
        return 3049
    elseif id == 3087 then
        return 3050
    elseif id == 3088 then
        return 3051
    elseif id == 3089 then
        return 3052
    elseif id == 3090 then
        return 3053
    elseif id == 3094 then
        return 3091
    elseif id == 3095 then
        return 3092
    elseif id == 3096 then
        return 3093
    elseif id == 3099 then
        return 3097
    elseif id == 3100 then
        return 3098
    elseif id == 16264 then
        return 16114
    elseif id == 23532 then
        return 23531
    elseif id == 23534 then
        return 23533
    elseif id == 23530 then
        return 23529
    elseif id == 30342 then -- Sleep Shawl
        return 30343
    elseif id == 30345 then -- Enchanted Pendulet
        return 30344
    elseif id == 30402 then -- Enchanted Theurgic Amulet
        return 30403
    elseif id == 31616 then -- Blister Ring
        return 31621
    elseif id == 32635 then -- Ring of Souls
        return 32621
    else
        return id
    end
end

-- returns amount of monsters within the range of position
-- does not include summons (new tibia)
-- returns number
function getMonstersInRange(pos, range)
    if not pos or not range then return false end
    local monsters = 0
    for i, spec in pairs(getSpectators()) do
        if spec:isMonster() and
            (g_game.getClientVersion() < 960 or spec:getType() < 3) and
            getDistanceBetween(pos, spec:getPosition()) < range then
            monsters = monsters + 1
        end
    end
    return monsters
end

-- shortcut in calculating distance from local player position
-- needs only one argument
-- returns number
function distanceFromPlayer(coords)
    if not coords then return false end
    return getDistanceBetween(pos(), coords)
end

-- returns amount of monsters within the range of local player position
-- does not include summons (new tibia)
-- can also check multiple floors
-- returns number
function getMonsters(range, multifloor)
    if not range then range = 10 end
    local mobs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        mobs = (g_game.getClientVersion() < 960 or spec:getType() < 3) and
                   spec:isMonster() and distanceFromPlayer(spec:getPosition()) <=
                   range and mobs + 1 or mobs;
    end
    return mobs;
end

-- returns amount of players within the range of local player position
-- does not include party members
-- can also check multiple floors
-- returns number
function getPlayers(range, multifloor)
    if not range then range = 10 end
    local specs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        if not spec:isLocalPlayer() and spec:isPlayer() and distanceFromPlayer(spec:getPosition()) <= range and not ((spec:getShield() ~= 1 and spec:isPartyMember()) or spec:getEmblem() == 1) then
            specs = specs + 1
        end
    end
    return specs;
end

-- this is multifloor function
-- checks if player added in "Anti RS list" in player list is within the given range
-- returns boolean
function isBlackListedPlayerInRange(range)
    if #storage.playerList.blackList == 0 then return end
    if not range then range = 10 end
    local found = false
    for _, spec in pairs(getSpectators(true)) do
        local specPos = spec:getPosition()
        local pPos = player:getPosition()
        if spec:isPlayer() then
            if math.abs(specPos.z - pPos.z) <= 2 then
                if specPos.z ~= pPos.z then specPos.z = pPos.z end
                if distanceFromPlayer(specPos) < range then
                    if table.find(storage.playerList.blackList, spec:getName()) then
                        found = true
                    end
                end
            end
        end
    end
    return found
end

-- checks if there is non-friend player withing the range
-- padding is only for multifloor
-- returns boolean
function isSafe(range, multifloor, padding)
    local onSame = 0
    local onAnother = 0
    if not multifloor and padding then
        multifloor = false
        padding = false
    end

    for _, spec in pairs(getSpectators(multifloor)) do
        if spec:isPlayer() and not spec:isLocalPlayer() and
            not isFriend(spec:getName()) then
            if spec:getPosition().z == posz() and
                distanceFromPlayer(spec:getPosition()) <= range then
                onSame = onSame + 1
            end
            if multifloor and padding and spec:getPosition().z ~= posz() and
                distanceFromPlayer(spec:getPosition()) <= (range + padding) then
                onAnother = onAnother + 1
            end
        end
    end

    if onSame + onAnother > 0 then
        return false
    else
        return true
    end
end

-- returns amount of players within the range of local player position
-- can also check multiple floors
-- returns number
function getAllPlayers(range, multifloor)
    if not range then range = 10 end
    local specs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        specs = not spec:isLocalPlayer() and spec:isPlayer() and
                    distanceFromPlayer(spec:getPosition()) <= range and specs +
                    1 or specs;
    end
    return specs;
end

-- returns amount of NPC's within the range of local player position
-- can also check multiple floors
-- returns number
function getNpcs(range, multifloor)
    if not range then range = 10 end
    local npcs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        npcs =
            spec:isNpc() and distanceFromPlayer(spec:getPosition()) <= range and
                npcs + 1 or npcs;
    end
    return npcs;
end

-- main function for calculatin item amount in all visible containers
-- also considers equipped items
-- returns number
function itemAmount(id)
    return player:getItemsCount(id)
end

-- self explanatory
-- a is item to use on 
-- b is item to use a on
function useOnInvertoryItem(a, b)
    local item = findItem(b)
    if not item then return end

    return useWith(a, item)
end

-- pos can be tile or position
-- returns table of tiles surrounding given POS/tile
function getNearTiles(pos)
    if type(pos) ~= "table" then pos = pos:getPosition() end

    local tiles = {}
    local dirs = {
        {-1, 1}, {0, 1}, {1, 1}, {-1, 0}, {1, 0}, {-1, -1}, {0, -1}, {1, -1}
    }
    for i = 1, #dirs do
        local tile = g_map.getTile({
            x = pos.x - dirs[i][1],
            y = pos.y - dirs[i][2],
            z = pos.z
        })
        if tile then table.insert(tiles, tile) end
    end

    return tiles
end

-- self explanatory
-- use along with delay, it will only call action
function useGroundItem(id)
    if not id then return false end

    local dest = nil
    for i, tile in ipairs(g_map.getTiles(posz())) do
        for j, item in ipairs(tile:getItems()) do
            if item:getId() == id then
                dest = item
                break
            end
        end
    end

    if dest then
        return use(dest)
    else
        return false
    end
end

-- self explanatory
-- use along with delay, it will only call action
function reachGroundItem(id)
    if not id then return false end

    local dest = nil
    for i, tile in ipairs(g_map.getTiles(posz())) do
        for j, item in ipairs(tile:getItems()) do
            local iPos = item:getPosition()
            local iId = item:getId()
            if iId == id then
                if findPath(pos(), iPos, 20,
                            {ignoreNonPathable = true, precision = 1}) then
                    dest = item
                    break
                end
            end
        end
    end

    if dest then
        return autoWalk(iPos, 20, {ignoreNonPathable = true, precision = 1})
    else
        return false
    end
end

-- self explanatory
-- returns object
function findItemOnGround(id)
    for i, tile in ipairs(g_map.getTiles(posz())) do
        for j, item in ipairs(tile:getItems()) do
            if item:getId() == id then return item end
        end
    end
end

-- self explanatory
-- use along with delay, it will only call action
function useOnGroundItem(a, b)
    if not b then return false end
    local item = findItem(a)
    if not item then return false end

    local dest = nil
    for i, tile in ipairs(g_map.getTiles(posz())) do
        for j, item in ipairs(tile:getItems()) do
            if item:getId() == id then
                dest = item
                break
            end
        end
    end

    if dest then
        return useWith(item, dest)
    else
        return false
    end
end

-- returns target creature
function target()
    if not g_game.isAttacking() then
        return
    else
        return g_game.getAttackingCreature()
    end
end

-- returns target creature
function getTarget() return target() end

-- dist is boolean
-- returns target position/distance from player
function targetPos(dist)
    if not g_game.isAttacking() then return end
    if dist then
        return distanceFromPlayer(target():getPosition())
    else
        return target():getPosition()
    end
end

-- for gunzodus/ezodus only
-- it will reopen loot bag, necessary for depositer
function reopenPurse()
    for i, c in pairs(getContainers()) do
        if c:getName():lower() == "loot bag" or c:getName():lower() ==
            "store inbox" then g_game.close(c) end
    end
    schedule(100, function()
        g_game.use(g_game.getLocalPlayer():getInventoryItem(InventorySlotPurse))
    end)
    schedule(1400, function()
        for i, c in pairs(getContainers()) do
            if c:getName():lower() == "store inbox" then
                for _, i in pairs(c:getItems()) do
                    if i:getId() == 23721 then
                        g_game.open(i, c)
                    end
                end
            end
        end
    end)
    return CaveBot.delay(1500)
end

-- getSpectator patterns
-- param1 - pos/creature
-- param2 - pattern
-- param3 - type of return
-- 1 - everyone, 2 - monsters, 3 - players
-- returns number
function getCreaturesInArea(param1, param2, param3)
    local specs = 0
    local monsters = 0
    local players = 0
    for i, spec in pairs(getSpectators(param1, param2)) do
        if spec ~= player then
            specs = specs + 1
            if spec:isMonster() and
                (g_game.getClientVersion() < 960 or spec:getType() < 3) then
                monsters = monsters + 1
            elseif spec:isPlayer() and not isFriend(spec:getName()) then
                players = players + 1
            end
        end
    end

    if param3 == 1 then
        return specs
    elseif param3 == 2 then
        return monsters
    else
        return players
    end
end

-- can be improved
-- TODO in future
-- uses getCreaturesInArea, specType
-- returns number
function getBestTileByPatern(pattern, specType, maxDist, safe)
    if not pattern or not specType then return end
    if not maxDist then maxDist = 4 end

    local bestTile = nil
    local best = nil
    for _, tile in pairs(g_map.getTiles(posz())) do
        if distanceFromPlayer(tile:getPosition()) <= maxDist then
            local minimapColor = g_map.getMinimapColor(tile:getPosition())
            local stairs = (minimapColor >= 210 and minimapColor <= 213)
            if tile:canShoot() and tile:isWalkable() then
                if getCreaturesInArea(tile:getPosition(), pattern, specType) > 0 then
                    if (not safe or
                        getCreaturesInArea(tile:getPosition(), pattern, 3) == 0) then
                        local candidate =
                            {
                                pos = tile,
                                count = getCreaturesInArea(tile:getPosition(),
                                                           pattern, specType)
                            }
                        if not best or best.count <= candidate.count then
                            best = candidate
                        end
                    end
                end
            end
        end
    end

    bestTile = best

    if bestTile then
        return bestTile
    else
        return false
    end
end

-- returns container object based on name
function getContainerByName(name, notFull)
    if type(name) ~= "string" then return nil end

    local d = nil
    for i, c in pairs(getContainers()) do
        if c:getName():lower() == name:lower() and (not notFull or not containerIsFull(c)) then
            d = c
            break
        end
    end
    return d
end

-- returns container object based on container ID
function getContainerByItem(id, notFull)
    if type(id) ~= "number" then return nil end

    local d = nil
    for i, c in pairs(getContainers()) do
        if c:getContainerItem():getId() == id and (not notFull or not containerIsFull(c)) then
            d = c
            break
        end
    end
    return d
end

-- [[ ready to use getSpectators patterns ]] --
LargeUeArea = [[
    0000001000000
    0000011100000
    0000111110000
    0001111111000
    0011111111100
    0111111111110
    1111111111111
    0111111111110
    0011111111100
    0001111111000
    0000111110000
    0000011100000
    0000001000000
]]

NormalUeAreaMs = [[
    00000100000
    00011111000
    00111111100
    01111111110
    01111111110
    11111111111
    01111111110
    01111111110
    00111111100
    00001110000
    00000100000
]]

NormalUeAreaEd = [[
    00000100000
    00001110000
    00011111000
    00111111100
    01111111110
    11111111111
    01111111110
    00111111100
    00011111000
    00001110000
    00000100000
]]

smallUeArea = [[
    0011100
    0111110
    1111111
    1111111
    1111111
    0111110
    0011100
]]

largeRuneArea = [[
    0011100
    0111110
    1111111
    1111111
    1111111
    0111110
    0011100
]]

adjacentArea = [[
    111
    101
    111
]]

longBeamArea = [[
    0000000N0000000
    0000000N0000000
    0000000N0000000
    0000000N0000000
    0000000N0000000
    0000000N0000000
    0000000N0000000
    WWWWWWW0EEEEEEE
    0000000S0000000
    0000000S0000000
    0000000S0000000
    0000000S0000000
    0000000S0000000
    0000000S0000000
    0000000S0000000
]]

shortBeamArea = [[
    00000100000
    00000100000
    00000100000
    00000100000
    00000100000
    EEEEE0WWWWW
    00000S00000
    00000S00000
    00000S00000
    00000S00000
    00000S00000
]]

newWaveArea = [[
    000NNNNN000
    000NNNNN000
    0000NNN0000
    WW00NNN00EE
    WWWW0N0EEEE
    WWWWW0EEEEE
    WWWW0S0EEEE
    WW00SSS00EE
    0000SSS0000
    000SSSSS000
    000SSSSS000
]]

bigWaveArea = [[
    0000NNN0000
    0000NNN0000
    0000NNN0000
    00000N00000
    WWW00N00EEE
    WWWWW0EEEEE
    WWW00S00EEE
    00000S00000
    0000SSS0000
    0000SSS0000
    0000SSS0000
]]

smallWaveArea = [[
    00NNN00
    00NNN00
    WW0N0EE
    WWW0EEE
    WW0S0EE
    00SSS00
    00SSS00
]]

diamondArrowArea = [[
    01110
    11111
    11111
    11111
    01110
]]

-- Enhanced utility functions for better bot functionality

-- Improved distance calculation with better validation
function getDistanceBetween(pos1, pos2)
    if not pos1 or not pos2 then return 999 end
    if type(pos1) ~= "table" or type(pos2) ~= "table" then return 999 end

    local dx = math.abs(pos1.x - pos2.x)
    local dy = math.abs(pos1.y - pos2.y)

    -- Handle different floors
    if pos1.z ~= pos2.z then return 999 end

    -- Use chebyshev distance for diagonal movement
    return math.max(dx, dy)
end

-- Check if position is within a specified range
function isInRange(pos, center, range)
    if not pos or not center or type(range) ~= "number" then return false end
    return getDistanceBetween(pos, center) <= range
end

-- Get position in front of the player based on direction
function getPositionInFront(range)
    range = range or 1
    if type(range) ~= "number" or range < 1 then range = 1 end

    local player = g_game.getLocalPlayer()
    if not player then return nil end

    local pos = player:getPosition()
    local dir = player:getDirection()

    if dir == 0 then -- North
        return {x = pos.x, y = pos.y - range, z = pos.z}
    elseif dir == 1 then -- East
        return {x = pos.x + range, y = pos.y, z = pos.z}
    elseif dir == 2 then -- South
        return {x = pos.x, y = pos.y + range, z = pos.z}
    elseif dir == 3 then -- West
        return {x = pos.x - range, y = pos.y, z = pos.z}
    end

    return nil
end

-- Enhanced walking validation
function canWalkTo(pos)
    if not pos or type(pos) ~= "table" then return false end

    local tile = g_map.getTile(pos)
    if not tile then return false end

    -- Check if tile is walkable
    if not tile:isWalkable() then return false end

    -- Check for blocking creatures
    local topCreature = tile:getTopCreature()
    if topCreature and not topCreature:isLocalPlayer() then return false end

    return true
end

-- Get creatures within a specified range
function getCreaturesInRange(center, range, includePlayers, includeMonsters, includeNpcs)
    if not center or type(range) ~= "number" then return {} end

    includePlayers = includePlayers ~= false -- Default true
    includeMonsters = includeMonsters ~= false -- Default true
    includeNpcs = includeNpcs ~= false -- Default true

    local creatures = {}
    local spectators = getSpectators()

    for _, creature in ipairs(spectators) do
        if creature and not creature:isLocalPlayer() then
            local cpos = creature:getPosition()
            if getDistanceBetween(center, cpos) <= range then
                if (creature:isPlayer() and includePlayers) or
                   (creature:isMonster() and includeMonsters) or
                   (creature:isNpc() and includeNpcs) then
                    table.insert(creatures, creature)
                end
            end
        end
    end

    return creatures
end

-- Enhanced health and mana percentage calculations with better validation
function getHealthPercent()
    local player = g_game.getLocalPlayer()
    if not player then return 0 end

    local maxHealth = player:getMaxHealth()
    if maxHealth <= 0 then return 0 end

    return math.floor((player:getHealth() / maxHealth) * 100)
end

function getManaPercent()
    local player = g_game.getLocalPlayer()
    if not player then return 0 end

    local maxMana = player:getMaxMana()
    if maxMana <= 0 then return 0 end

    return math.floor((player:getMana() / maxMana) * 100)
end

-- Check if player has a specific buff/debuff by icon
function hasIcon(iconId)
    if type(iconId) ~= "number" then return false end

    local player = g_game.getLocalPlayer()
    if not player then return false end

    return player:hasIcon(iconId)
end

-- Get all active condition icons
function getActiveIcons()
    local player = g_game.getLocalPlayer()
    if not player then return {} end

    local icons = {}
    -- This would need to be implemented based on the specific game client
    -- For now, return empty table as a placeholder
    return icons
end

-- Enhanced logout function with safety checks
function safeLogout()
    if vBot.isUsingPotion then return false end
    if vBot.isUsing then return false end

    -- Check if in combat or other dangerous situations
    local spectators = getSpectators()
    for _, creature in ipairs(spectators) do
        if creature and isEnemy(creature) then
            local distance = getDistanceBetween(player:getPosition(), creature:getPosition())
            if distance <= 8 then -- Enemy too close
                return false
            end
        end
    end

    -- Additional safety checks could be added here

    logout()
    return true
end

-- Utility function to format time in milliseconds to readable format
function formatTime(ms)
    if type(ms) ~= "number" or ms < 0 then return "0s" end

    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)

    if hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes % 60, seconds % 60)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, seconds % 60)
    else
        return string.format("%ds", seconds)
    end
end

-- Enhanced random number generation with better distribution
function randomBetween(min, max)
    if type(min) ~= "number" or type(max) ~= "number" then return 0 end
    if min > max then min, max = max, min end

    return math.floor(math.random() * (max - min + 1)) + min
end

-- Check if a value is within a range (inclusive)
function isInRange(value, min, max)
    if type(value) ~= "number" or type(min) ~= "number" or type(max) ~= "number" then
        return false
    end
    return value >= min and value <= max
end

-- Enhanced table utility functions
function table.count(t)
    if type(t) ~= "table" then return 0 end

    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function table.contains(t, value)
    if type(t) ~= "table" then return false end

    for _, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

function table.find(t, value)
    if type(t) ~= "table" then return nil end

    for i, v in ipairs(t) do
        if v == value then return i end
    end
    return nil
end

-- Debug logging with different levels
function debugLog(level, message)
    if not message then return end

    local timestamp = os.date("%H:%M:%S")
    local prefix = string.format("[%s] [vBot:%s]", timestamp, level:upper())

    if level == "error" then
        warn(string.format("%s %s", prefix, message))
    elseif level == "info" then
        logInfo(message)
    elseif level == "debug" then
        -- Only show debug messages if debug mode is enabled
        if vBot.debugMode then
            modules.client_terminal.addLine(string.format("%s %s", prefix, message), "yellow")
        end
    end
end

-- Initialize debug mode (can be enabled/disabled)
vBot.debugMode = false

function setDebugMode(enabled)
    vBot.debugMode = enabled == true
    debugLog("info", string.format("Debug mode %s", enabled and "enabled" or "disabled"))
end

