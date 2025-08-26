-- Klib.lua - Comprehensive AI-Generated Script Support Library
-- Created for vBot 4.8 to support AI-generated scripts and common patterns
-- This library provides commonly referenced functions that AI tools might generate

-- Global namespace
Klib = {}
Klib.version = "1.0.0"
Klib.author = "vBot Enhancement System"

-- ======================== --
-- [[ BASIC UTILITIES ]] --
-- ======================== --

-- Safe print function
function Klib.print(...)
    local args = {...}
    local message = ""
    for i, arg in ipairs(args) do
        message = message .. tostring(arg)
        if i < #args then message = message .. " " end
    end
    print("[Klib] " .. message)
end

-- Safe logging
function Klib.log(level, message)
    level = level or "info"
    local timestamp = os.date("%H:%M:%S")
    local prefix = string.format("[%s] [Klib:%s]", timestamp, level:upper())

    if level == "error" then
        warn(prefix .. " " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- ======================== --
-- [[ TABLE UTILITIES ]] --
-- ======================== --

-- Deep copy a table
function Klib.tableCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Klib.tableCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Merge two tables
function Klib.tableMerge(t1, t2)
    local result = Klib.tableCopy(t1)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Klib.tableMerge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

-- Check if table contains value
function Klib.tableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

-- Get table size (handles both array and hash tables)
function Klib.tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Filter table by condition
function Klib.tableFilter(tbl, condition)
    local result = {}
    for k, v in pairs(tbl) do
        if condition(v, k) then
            result[k] = v
        end
    end
    return result
end

-- Map table values
function Klib.tableMap(tbl, transform)
    local result = {}
    for k, v in pairs(tbl) do
        result[k] = transform(v, k)
    end
    return result
end

-- Reverse table (for arrays)
function Klib.tableReverse(tbl)
    local result = {}
    local len = #tbl
    for i = len, 1, -1 do
        table.insert(result, tbl[i])
    end
    return result
end

-- ======================== --
-- [[ STRING UTILITIES ]] --
-- ======================== --

-- Split string by delimiter
function Klib.stringSplit(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    return result
end

-- Join array into string
function Klib.stringJoin(arr, separator)
    separator = separator or " "
    local result = ""
    for i, v in ipairs(arr) do
        result = result .. tostring(v)
        if i < #arr then result = result .. separator end
    end
    return result
end

-- Trim whitespace
function Klib.stringTrim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

-- Check if string starts with substring
function Klib.stringStartsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

-- Check if string ends with substring
function Klib.stringEndsWith(str, suffix)
    return string.sub(str, -#suffix) == suffix
end

-- Replace all occurrences
function Klib.stringReplace(str, find, replace)
    return string.gsub(str, find, replace)
end

-- Format string with named placeholders
function Klib.stringFormat(template, values)
    local result = template
    for key, value in pairs(values) do
        result = string.gsub(result, "{" .. key .. "}", tostring(value))
    end
    return result
end

-- ======================== --
-- [[ MATH UTILITIES ]] --
-- ======================== --

-- Clamp value between min and max
function Klib.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Linear interpolation
function Klib.lerp(a, b, t)
    return a + (b - a) * t
end

-- Map value from one range to another
function Klib.map(value, fromMin, fromMax, toMin, toMax)
    local normalized = (value - fromMin) / (fromMax - fromMin)
    return toMin + normalized * (toMax - toMin)
end

-- Round number to decimal places
function Klib.round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

-- Check if number is in range
function Klib.isInRange(value, min, max)
    return value >= min and value <= max
end

-- Calculate distance between two points (2D)
function Klib.distance2D(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Calculate distance between two points (3D)
function Klib.distance3D(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- ======================== --
-- [[ TIME UTILITIES ]] --
-- ======================== --

-- Convert milliseconds to readable format
function Klib.formatTime(ms)
    if type(ms) ~= "number" or ms < 0 then return "0s" end

    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local days = math.floor(hours / 24)

    if days > 0 then
        return string.format("%dd %dh %dm %ds", days, hours % 24, minutes % 60, seconds % 60)
    elseif hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes % 60, seconds % 60)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, seconds % 60)
    else
        return string.format("%ds", seconds)
    end
end

-- Get current timestamp
function Klib.getTimestamp()
    return os.time()
end

-- Format current time
function Klib.getCurrentTime(format)
    format = format or "%H:%M:%S"
    return os.date(format)
end

-- Check if enough time has passed
function Klib.hasTimePassed(startTime, duration)
    return (os.time() - startTime) >= duration
end

-- ======================== --
-- [[ RANDOM UTILITIES ]] --
-- ======================== --

-- Generate random integer between min and max
function Klib.randomInt(min, max)
    if min > max then min, max = max, min end
    return math.floor(math.random() * (max - min + 1)) + min
end

-- Generate random float between min and max
function Klib.randomFloat(min, max)
    if min > max then min, max = max, min end
    return min + math.random() * (max - min)
end

-- Choose random item from array
function Klib.randomChoice(array)
    if #array == 0 then return nil end
    return array[Klib.randomInt(1, #array)]
end

-- Shuffle array
function Klib.shuffleArray(array)
    local result = Klib.tableCopy(array)
    for i = #result, 2, -1 do
        local j = Klib.randomInt(1, i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

-- ======================== --
-- [[ EVENT SYSTEM ]] --
-- ======================== --

Klib.events = {}
Klib.eventListeners = {}

-- Register event listener
function Klib.on(eventName, callback)
    if not Klib.eventListeners[eventName] then
        Klib.eventListeners[eventName] = {}
    end
    table.insert(Klib.eventListeners[eventName], callback)
    return #Klib.eventListeners[eventName] -- Return listener ID
end

-- Remove event listener
function Klib.off(eventName, listenerId)
    if Klib.eventListeners[eventName] and Klib.eventListeners[eventName][listenerId] then
        Klib.eventListeners[eventName][listenerId] = nil
    end
end

-- Emit event
function Klib.emit(eventName, ...)
    if Klib.eventListeners[eventName] then
        for _, callback in pairs(Klib.eventListeners[eventName]) do
            if callback then
                local success, result = pcall(callback, ...)
                if not success then
                    Klib.log("error", "Event callback error for '" .. eventName .. "': " .. result)
                end
            end
        end
    end
end

-- ======================== --
-- [[ STATE MACHINE ]] --
-- ======================== --

function Klib.createStateMachine(initialState)
    local stateMachine = {
        currentState = initialState,
        states = {},
        transitions = {},

        addState = function(self, name, onEnter, onUpdate, onExit)
            self.states[name] = {
                onEnter = onEnter,
                onUpdate = onUpdate,
                onExit = onExit
            }
        end,

        addTransition = function(self, fromState, toState, condition)
            if not self.transitions[fromState] then
                self.transitions[fromState] = {}
            end
            self.transitions[fromState][toState] = condition
        end,

        update = function(self)
            -- Check for transitions
            local currentTransitions = self.transitions[self.currentState]
            if currentTransitions then
                for toState, condition in pairs(currentTransitions) do
                    if condition() then
                        self:changeState(toState)
                        break
                    end
                end
            end

            -- Update current state
            local state = self.states[self.currentState]
            if state and state.onUpdate then
                state.onUpdate()
            end
        end,

        changeState = function(self, newState)
            if self.currentState == newState then return end

            local oldState = self.states[self.currentState]
            if oldState and oldState.onExit then
                oldState.onExit()
            end

            Klib.log("info", "State changed from '" .. self.currentState .. "' to '" .. newState .. "'")
            self.currentState = newState

            local newStateObj = self.states[newState]
            if newStateObj and newStateObj.onEnter then
                newStateObj.onEnter()
            end
        end,

        getCurrentState = function(self)
            return self.currentState
        end
    }

    return stateMachine
end

-- ======================== --
-- [[ TIMER SYSTEM ]] --
-- ======================== --

Klib.timers = {}

-- Set timeout using vBot's schedule function
function Klib.setTimeout(callback, delay, ...)
    if not callback or type(callback) ~= "function" then
        Klib.log("error", "setTimeout: Invalid callback function")
        return nil
    end

    if not delay or type(delay) ~= "number" or delay < 0 then
        Klib.log("error", "setTimeout: Invalid delay")
        return nil
    end

    local args = {...}
    local timerId = #Klib.timers + 1

    -- Use vBot's schedule if available
    if schedule then
        schedule(delay, function()
            local success, result = pcall(callback, unpack(args))
            if not success then
                Klib.log("error", "Timer callback error: " .. result)
            end
            Klib.timers[timerId] = nil
        end)
    else
        Klib.log("error", "setTimeout: schedule function not available")
        return nil
    end

    Klib.timers[timerId] = true
    return timerId
end

-- Set interval using vBot's macro function
function Klib.setInterval(callback, interval, ...)
    if not callback or type(callback) ~= "function" then
        Klib.log("error", "setInterval: Invalid callback function")
        return nil
    end

    if not interval or type(interval) ~= "number" or interval < 0 then
        Klib.log("error", "setInterval: Invalid interval")
        return nil
    end

    local args = {...}
    local timerId = #Klib.timers + 1

    -- Use vBot's macro if available
    if macro then
        macro(interval, function()
            local success, result = pcall(callback, unpack(args))
            if not success then
                Klib.log("error", "Interval callback error: " .. result)
            end
        end)
    else
        Klib.log("error", "setInterval: macro function not available")
        return nil
    end

    Klib.timers[timerId] = true
    return timerId
end

function Klib.clearTimer(timerId)
    if Klib.timers[timerId] then
        Klib.timers[timerId] = nil
        return true
    end
    return false
end

-- ======================== --
-- [[ DATA STRUCTURES ]] --
-- ======================== --

-- Queue implementation
function Klib.createQueue()
    local queue = {
        items = {},
        size = 0,

        enqueue = function(self, item)
            table.insert(self.items, item)
            self.size = self.size + 1
        end,

        dequeue = function(self)
            if self.size == 0 then return nil end
            local item = table.remove(self.items, 1)
            self.size = self.size - 1
            return item
        end,

        peek = function(self)
            return self.items[1]
        end,

        isEmpty = function(self)
            return self.size == 0
        end,

        getSize = function(self)
            return self.size
        end,

        clear = function(self)
            self.items = {}
            self.size = 0
        end
    }

    return queue
end

-- Stack implementation
function Klib.createStack()
    local stack = {
        items = {},

        push = function(self, item)
            table.insert(self.items, item)
        end,

        pop = function(self)
            if #self.items == 0 then return nil end
            return table.remove(self.items)
        end,

        peek = function(self)
            return self.items[#self.items]
        end,

        isEmpty = function(self)
            return #self.items == 0
        end,

        getSize = function(self)
            return #self.items
        end,

        clear = function(self)
            self.items = {}
        end
    }

    return stack
end

-- Priority Queue implementation
function Klib.createPriorityQueue()
    local pq = {
        items = {},

        enqueue = function(self, item, priority)
            table.insert(self.items, {item = item, priority = priority})
            self:sort()
        end,

        dequeue = function(self)
            if #self.items == 0 then return nil end
            return table.remove(self.items, 1).item
        end,

        peek = function(self)
            if #self.items == 0 then return nil end
            return self.items[1].item
        end,

        sort = function(self)
            table.sort(self.items, function(a, b) return a.priority < b.priority end)
        end,

        isEmpty = function(self)
            return #self.items == 0
        end,

        getSize = function(self)
            return #self.items
        end,

        clear = function(self)
            self.items = {}
        end
    }

    return pq
end

-- ======================== --
-- [[ CONFIGURATION ]] --
-- ======================== --

Klib.config = {}

-- Simple table serialization (no JSON dependency)
function Klib.serializeTable(tbl, indent)
    indent = indent or ""
    local result = "{\n"

    for k, v in pairs(tbl) do
        result = result .. indent .. "  "
        if type(k) == "string" then
            result = result .. '["' .. k .. '"] = '
        else
            result = result .. '[' .. k .. '] = '
        end

        if type(v) == "table" then
            result = result .. Klib.serializeTable(v, indent .. "  ")
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '"'
        elseif type(v) == "boolean" then
            result = result .. (v and "true" or "false")
        else
            result = result .. tostring(v)
        end

        result = result .. ",\n"
    end

    result = result .. indent .. "}"
    return result
end

-- Simple table deserialization (basic implementation)
function Klib.deserializeTable(str)
    -- Basic deserialization - in a real implementation you'd want a proper parser
    local result = {}

    -- This is a very basic implementation for simple key-value pairs
    -- For complex nested tables, consider using a proper serialization library
    Klib.log("info", "deserializeTable is a basic implementation - use simple key-value pairs")
    return result
end

-- Load configuration
function Klib.loadConfig(filename)
    if not Klib.fileExists(filename) then
        Klib.log("error", "Config file not found: " .. filename)
        return {}
    end

    local content = Klib.readFile(filename)
    if not content then
        return {}
    end

    -- Try to use json if available, otherwise use basic deserialization
    if json and json.decode then
        local success, result = pcall(function()
            return json.decode(content)
        end)

        if success then
            Klib.config = result
            Klib.log("info", "Configuration loaded from " .. filename .. " (JSON)")
            return result
        else
            Klib.log("error", "Failed to parse JSON config file: " .. result)
            return {}
        end
    else
        Klib.log("info", "JSON not available, using basic config loading")
        return Klib.deserializeTable(content)
    end
end

-- Save configuration
function Klib.saveConfig(filename, config)
    config = config or Klib.config

    local content
    if json and json.encode then
        local success, result = pcall(function()
            return json.encode(config, 2)
        end)

        if success then
            content = result
            Klib.log("info", "Configuration encoded using JSON")
        else
            Klib.log("error", "Failed to encode JSON config: " .. result)
            content = Klib.serializeTable(config)
        end
    else
        content = Klib.serializeTable(config)
        Klib.log("info", "Configuration serialized using basic method")
    end

    local success = Klib.writeFile(filename, content)
    if success then
        Klib.log("info", "Configuration saved to " .. filename)
        return true
    else
        Klib.log("error", "Failed to save configuration")
        return false
    end
end

-- Get configuration value
function Klib.getConfig(key, default)
    local keys = Klib.stringSplit(key, ".")
    local current = Klib.config

    for _, k in ipairs(keys) do
        if type(current) == "table" and current[k] then
            current = current[k]
        else
            return default
        end
    end

    return current
end

-- Set configuration value
function Klib.setConfig(key, value)
    local keys = Klib.stringSplit(key, ".")
    local current = Klib.config

    for i = 1, #keys - 1 do
        local k = keys[i]
        if not current[k] then
            current[k] = {}
        end
        current = current[k]
    end

    current[keys[#keys]] = value
end

-- ======================== --
-- [[ FILE OPERATIONS ]] --
-- ======================== --

-- Note: File operations in OTCv8 are limited
-- These functions provide basic file operations where available

-- Read file content (if available)
function Klib.readFile(filename)
    -- Check if file operations are available
    if not g_resources or not g_resources.fileExists then
        Klib.log("error", "File operations not available in this environment")
        return nil, "File operations not supported"
    end

    if not g_resources.fileExists(filename) then
        return nil, "File not found: " .. filename
    end

    local content = g_resources.readFileContents(filename)
    return content
end

-- Write file content (if available)
function Klib.writeFile(filename, content)
    if not g_resources or not g_resources.writeFileContents then
        Klib.log("error", "File operations not available in this environment")
        return false
    end

    local success = g_resources.writeFileContents(filename, content)
    if success then
        Klib.log("info", "File written successfully: " .. filename)
        return true
    else
        Klib.log("error", "Failed to write file: " .. filename)
        return false
    end
end

-- Check if file exists (if available)
function Klib.fileExists(filename)
    if not g_resources or not g_resources.fileExists then
        return false
    end
    return g_resources.fileExists(filename)
end

-- List files in directory (if available)
function Klib.listFiles(directory)
    if not g_resources or not g_resources.listDirectoryFiles then
        Klib.log("error", "Directory listing not available in this environment")
        return {}
    end
    return g_resources.listDirectoryFiles(directory, true, false)
end

-- ======================== --
-- [[ COMBAT UTILITIES ]] --
-- ======================== --

-- Calculate damage per second
function Klib.calculateDPS(damage, timeInSeconds)
    if timeInSeconds <= 0 then return 0 end
    return damage / timeInSeconds
end

-- Check if target is in optimal range
function Klib.isInOptimalRange(targetPos, playerPos, minRange, maxRange)
    if not targetPos or not playerPos or not minRange or not maxRange then
        return false
    end

    -- Ensure positions have required fields
    if not (targetPos.x and targetPos.y and playerPos.x and playerPos.y) then
        return false
    end

    local distance = Klib.distance2D(playerPos.x, playerPos.y, targetPos.x, targetPos.y)
    return distance >= minRange and distance <= maxRange
end

-- Find best position to attack from
function Klib.findBestAttackPosition(targetPos, playerPos, preferredDistance)
    if not targetPos or not playerPos or not preferredDistance then
        return nil
    end

    -- Ensure positions have required fields
    if not (targetPos.x and targetPos.y and targetPos.z and playerPos.x and playerPos.y) then
        return nil
    end

    local bestPos = nil
    local bestScore = -999

    for x = -3, 3 do
        for y = -3, 3 do
            if x ~= 0 or y ~= 0 then
                local testPos = {x = targetPos.x + x, y = targetPos.y + y, z = targetPos.z}
                local distance = Klib.distance2D(testPos.x, testPos.y, playerPos.x, playerPos.y)

                -- Score based on distance from preferred range
                local distanceScore = math.abs(distance - preferredDistance)
                local score = 100 - distanceScore

                if score > bestScore then
                    bestScore = score
                    bestPos = testPos
                end
            end
        end
    end

    return bestPos
end

-- ======================== --
-- [[ NPC INTERACTION ]] --
-- ======================== --

-- Find NPC by name (compatible with vBot)
function Klib.findNPC(name)
    if not name or type(name) ~= "string" then
        return nil
    end

    -- Use vBot's getSpectators if available, otherwise try OTCv8 functions
    local spectators = getSpectators and getSpectators() or {}
    local playerPos = pos and pos() or {x=0, y=0, z=0}

    for _, creature in ipairs(spectators) do
        if creature and creature:isNpc and creature:isNpc() then
            local creatureName = creature:getName and creature:getName()
            if creatureName and creatureName:lower():find(name:lower()) then
                return creature
            end
        end
    end

    return nil
end

-- Calculate distance to NPC
function Klib.getNPCDistance(name)
    local npc = Klib.findNPC(name)
    if not npc then return 999 end

    local npcPos = npc:getPosition and npc:getPosition()
    local playerPos = pos and pos() or {x=0, y=0, z=0}

    if not npcPos or not playerPos then return 999 end

    return Klib.distance2D(playerPos.x or 0, playerPos.y or 0, npcPos.x or 0, npcPos.y or 0)
end

-- Check if player is near NPC
function Klib.isNearNPC(name, maxDistance)
    maxDistance = maxDistance or 3
    return Klib.getNPCDistance(name) <= maxDistance
end

-- ======================== --
-- [[ INVENTORY MANAGEMENT ]] --
-- ======================== --

-- Get item count by ID (vBot compatible)
function Klib.getItemCount(itemId)
    if not itemId or type(itemId) ~= "number" then
        return 0
    end

    -- Use vBot's findItems if available
    if findItems then
        local items = findItems(itemId)
        local total = 0
        if items then
            for _, item in ipairs(items) do
                if item and item:getCount then
                    total = total + item:getCount()
                end
            end
        end
        return total
    end

    -- Fallback if findItems is not available
    Klib.log("info", "findItems function not available, returning 0")
    return 0
end

-- Check if player has enough items
function Klib.hasItem(itemId, requiredCount)
    if not requiredCount then requiredCount = 1 end
    return Klib.getItemCount(itemId) >= requiredCount
end

-- Find best container for item (vBot compatible)
function Klib.findBestContainer(itemSize)
    itemSize = itemSize or 1

    -- Use vBot's getContainers if available
    if not getContainers then
        Klib.log("info", "getContainers function not available")
        return nil
    end

    local bestContainer = nil
    local mostFreeSlots = -1

    local containers = getContainers()
    if not containers then return nil end

    for _, container in pairs(containers) do
        if container and container:getName and container:getCapacity and container:getItemsCount then
            local name = container:getName():lower()
            if not name:find("depot") and not name:find("inbox") then
                local capacity = container:getCapacity()
                local itemCount = container:getItemsCount()
                local freeSlots = capacity - itemCount

                if freeSlots >= itemSize and freeSlots > mostFreeSlots then
                    mostFreeSlots = freeSlots
                    bestContainer = container
                end
            end
        end
    end

    return bestContainer
end

-- ======================== --
-- [[ POSITIONING HELPERS ]] --
-- ======================== --

-- Check if position is walkable (vBot/OTCv8 compatible)
function Klib.isWalkable(pos)
    if not pos or not pos.x or not pos.y or not pos.z then
        return false
    end

    -- Use vBot's g_map if available
    if g_map and g_map.getTile then
        local tile = g_map.getTile(pos)
        if not tile then return false end

        if tile.isWalkable then
            return tile:isWalkable()
        end
    end

    -- Fallback: assume position is walkable if we can't check
    Klib.log("info", "Walkability check not available, assuming position is walkable")
    return true
end

-- Find nearest walkable position
function Klib.findNearestWalkable(center, radius)
    if not center or not center.x or not center.y or not center.z then
        return nil
    end

    radius = radius or 3

    for x = -radius, radius do
        for y = -radius, radius do
            local testPos = {x = center.x + x, y = center.y + y, z = center.z}
            if Klib.isWalkable(testPos) then
                return testPos
            end
        end
    end

    return nil
end

-- Check if position is safe (no dangerous creatures nearby)
function Klib.isPositionSafe(pos, radius)
    if not pos or not pos.x or not pos.y or not pos.z then
        return false
    end

    radius = radius or 5

    -- Use vBot's getSpectators if available
    if not getSpectators then
        Klib.log("info", "getSpectators not available, assuming position is safe")
        return true
    end

    local creatures = getSpectators(pos, false, radius, radius)
    if not creatures then return true end

    for _, creature in ipairs(creatures) do
        if creature and creature:isMonster and creature:isMonster() and isEnemy and isEnemy(creature) then
            local creaturePos = creature:getPosition and creature:getPosition()
            if creaturePos then
                local distance = Klib.distance2D(pos.x, pos.y, creaturePos.x, creaturePos.y)
                if distance <= 2 then -- Creature too close
                    return false
                end
            end
        end
    end

    return true
end

-- ======================== --
-- [[ PERFORMANCE MONITORING ]] --
-- ======================== --

-- Performance monitoring (vBot compatible)
if os and os.clock then
    Klib.performance = {
        startTimes = {},
        callCounts = {},
        totalTimes = {}
    }

    function Klib.performance.startTimer(name)
        Klib.performance.startTimes[name] = os.clock()
    end

    function Klib.performance.endTimer(name)
        local startTime = Klib.performance.startTimes[name]
        if not startTime then return end

        local elapsed = os.clock() - startTime
        Klib.performance.callCounts[name] = (Klib.performance.callCounts[name] or 0) + 1
        Klib.performance.totalTimes[name] = (Klib.performance.totalTimes[name] or 0) + elapsed

        Klib.performance.startTimes[name] = nil
    end

    function Klib.performance.getStats()
        local stats = {}
        for name, totalTime in pairs(Klib.performance.totalTimes) do
            local callCount = Klib.performance.callCounts[name]
            stats[name] = {
                totalTime = totalTime,
                callCount = callCount,
                averageTime = totalTime / callCount
            }
        end
        return stats
    end

    function Klib.performance.reset()
        Klib.performance.startTimes = {}
        Klib.performance.callCounts = {}
        Klib.performance.totalTimes = {}
    end
else
    -- Fallback if os.clock is not available
    Klib.performance = {
        startTimer = function(name) end,
        endTimer = function(name) end,
        getStats = function() return {} end,
        reset = function() end
    }
    Klib.log("info", "Performance monitoring not available (os.clock not found)")
end

-- ======================== --
-- [[ ERROR HANDLING ]] --
-- ======================== --

-- Safe function wrapper
function Klib.safeCall(func, ...)
    local args = {...}
    local success, result = pcall(function()
        return func(unpack(args))
    end)

    if not success then
        Klib.log("error", "Safe call failed: " .. result)
        return nil, result
    end

    return result
end

-- Retry function with exponential backoff
function Klib.retry(func, maxAttempts, initialDelay, backoffFactor)
    maxAttempts = maxAttempts or 3
    initialDelay = initialDelay or 100
    backoffFactor = backoffFactor or 2

    local delay = initialDelay
    local lastError = nil

    for attempt = 1, maxAttempts do
        local success, result = Klib.safeCall(func)

        if success then
            return result
        else
            lastError = result
            if attempt < maxAttempts then
                Klib.log("info", string.format("Attempt %d failed, retrying in %dms: %s", attempt, delay, result))
                schedule(delay, function() end) -- Wait
                delay = delay * backoffFactor
            end
        end
    end

    Klib.log("error", string.format("All %d attempts failed. Last error: %s", maxAttempts, lastError))
    return nil, lastError
end

-- ======================== --
-- [[ DEBUGGING UTILITIES ]] --
-- ======================== --

-- Dump table to string
function Klib.dumpTable(tbl, indent)
    indent = indent or 0
    local result = ""
    local prefix = string.rep("  ", indent)

    if type(tbl) ~= "table" then
        return prefix .. tostring(tbl)
    end

    result = result .. "{\n"

    for k, v in pairs(tbl) do
        result = result .. prefix .. "  [" .. tostring(k) .. "] = "

        if type(v) == "table" then
            result = result .. Klib.dumpTable(v, indent + 1)
        else
            result = result .. tostring(v)
        end

        result = result .. "\n"
    end

    result = result .. prefix .. "}"
    return result
end

-- Debug print with type information
function Klib.debugPrint(value, label)
    label = label or "Debug"
    local valueType = type(value)

    if valueType == "table" then
        print(string.format("[%s] Table with %d elements:", label, Klib.tableSize(value)))
        print(Klib.dumpTable(value))
    else
        print(string.format("[%s] %s: %s", label, valueType, tostring(value)))
    end
end

-- ======================== --
-- [[ INITIALIZATION ]] --
-- ======================== --

-- Compatibility check for unpack function
if not unpack and table.unpack then
    unpack = table.unpack
elseif not unpack then
    -- Create a basic unpack function if not available
    unpack = function(t, i, j)
        i = i or 1
        j = j or #t
        local result = {}
        for k = i, j do
            table.insert(result, t[k])
        end
        return unpack(result) -- Recursive call to built-in unpack if available
    end
end

-- Initialize the library
local initSuccess = pcall(function()
    Klib.log("info", "Klib.lua loaded successfully")
    Klib.log("info", "Version: " .. Klib.version .. " by " .. Klib.author)
    Klib.log("info", "Available modules: events, stateMachine, timers, dataStructures, performance")
    Klib.log("info", "Ready to support AI-generated scripts!")
end)

if not initSuccess then
    -- Fallback if logging is not available
    print("Klib.lua loaded successfully (basic mode)")
end

-- Export common functions to global scope (for AI-generated scripts that might expect them)
-- Only export if _G is available and functions don't already exist
if _G then
    if not _G.safePrint then _G.safePrint = Klib.print end
    if not _G.logMessage then _G.logMessage = Klib.log end
    if not _G.tableCopy then _G.tableCopy = Klib.tableCopy end
    if not _G.tableMerge then _G.tableMerge = Klib.tableMerge end
    if not _G.stringSplit then _G.stringSplit = Klib.stringSplit end
    if not _G.randomInt then _G.randomInt = Klib.randomInt end
    if not _G.clamp then _G.clamp = Klib.clamp end
    if not _G.distance then _G.distance = Klib.distance2D end
    if not _G.formatTime then _G.formatTime = Klib.formatTime end
end

-- Return the library for explicit usage
return Klib
