-- Alternative Implementation Approaches for vBot Features
-- This file demonstrates different ways to implement the same functionality

-- ======================== --
-- [[ TARGET SELECTION VARIATIONS ]] --
-- ======================== --

-- Variation 1: Distance-based with HP tiebreaker (current implementation)
function TargetBot.SelectTarget_DistanceFirst(targets)
    table.sort(targets, function(a, b)
        if a.distance ~= b.distance then
            return a.distance < b.distance -- Closer first
        else
            return a.hpPercent < b.hpPercent -- Lower HP first (tiebreaker)
        end
    end)
    return targets[1]
end

-- Variation 2: HP-based with distance tiebreaker
function TargetBot.SelectTarget_HPFirst(targets)
    table.sort(targets, function(a, b)
        if a.hpPercent ~= b.hpPercent then
            return a.hpPercent < b.hpPercent -- Lower HP first
        else
            return a.distance < b.distance -- Closer first (tiebreaker)
        end
    end)
    return targets[1]
end

-- Variation 3: Priority-based selection with custom weights
function TargetBot.SelectTarget_Weighted(targets, weights)
    weights = weights or {
        hpWeight = 0.6,        -- 60% weight for HP
        distanceWeight = 0.4   -- 40% weight for distance
    }

    for _, target in ipairs(targets) do
        -- Normalize values (0-1 scale)
        local hpScore = 1 - (target.hpPercent / 100) -- Lower HP = higher score
        local distanceScore = 1 - math.min(target.distance / 10, 1) -- Closer = higher score

        -- Calculate weighted score
        target.score = (hpScore * weights.hpWeight) + (distanceScore * weights.distanceWeight)
    end

    table.sort(targets, function(a, b) return a.score > b.score end) -- Higher score first
    return targets[1]
end

-- Variation 4: Threat-based selection (prioritizes dangerous targets)
function TargetBot.SelectTarget_ThreatBased(targets)
    for _, target in ipairs(targets) do
        -- Calculate threat level based on various factors
        local threat = 0
        threat = threat + (100 - target.hpPercent) * 0.5 -- Weaker = more threatening
        threat = threat + (10 - target.distance) * 2     -- Closer = more threatening
        threat = threat + (target.danger or 0)           -- Base danger level

        target.threat = threat
    end

    table.sort(targets, function(a, b) return a.threat > b.threat end) -- Higher threat first
    return targets[1]
end

-- ======================== --
-- [[ PATHFINDING VARIATIONS ]] --
-- ======================== --

-- Variation 1: Standard A* pathfinding (current implementation)
function CaveBot.FindPath_Standard(start, goal, options)
    return findPath(start, goal, options.maxDist or 40, {
        ignoreNonPathable = options.ignoreNonPathable ~= false,
        precision = options.precision or 1,
        ignoreCreatures = options.ignoreCreatures or false,
        allowUnseen = options.allowUnseen or false,
        allowOnlyVisibleTiles = options.allowOnlyVisibleTiles or false
    })
end

-- Variation 2: Hybrid pathfinding (tries multiple approaches)
function CaveBot.FindPath_Hybrid(start, goal, options)
    -- Try 1: Standard pathfinding
    local path = CaveBot.FindPath_Standard(start, goal, options)
    if path then return path end

    -- Try 2: Ignore creatures
    path = findPath(start, goal, options.maxDist or 40, {
        ignoreNonPathable = true,
        precision = 2,
        ignoreCreatures = true,
        allowUnseen = true,
        allowOnlyVisibleTiles = false
    })
    if path then return path end

    -- Try 3: Lower precision
    path = findPath(start, goal, options.maxDist or 40, {
        ignoreNonPathable = true,
        precision = 0,
        ignoreCreatures = true,
        allowUnseen = true,
        allowOnlyVisibleTiles = false
    })

    return path
end

-- Variation 3: Cost-based pathfinding (avoids expensive tiles)
function CaveBot.FindPath_CostBased(start, goal, options)
    -- This would require implementing a custom pathfinding algorithm
    -- that considers tile costs (e.g., avoid fire fields, prefer roads)
    -- For now, return standard path
    return CaveBot.FindPath_Standard(start, goal, options)
end

-- ======================== --
-- [[ HEALTH MONITORING VARIATIONS ]] --
-- ======================== --

-- Variation 1: Simple threshold-based (current implementation)
function HealthMonitor_Simple(callbacks)
    EnhancedCallbacks.onHealthChange(function(healthPercent, healthChange, healthHistory)
        for _, callback in ipairs(callbacks) do
            if healthPercent <= callback.threshold then
                callback.action(healthPercent, healthChange)
            end
        end
    end)
end

-- Variation 2: Trend-based monitoring
function HealthMonitor_Trend(callbacks)
    local healthTrend = {}
    local trendWindow = 5 -- Check last 5 health changes

    EnhancedCallbacks.onHealthChange(function(healthPercent, healthChange, healthHistory)
        if #healthHistory >= trendWindow then
            local recentChanges = {}
            for i = #healthHistory - trendWindow + 1, #healthHistory do
                table.insert(recentChanges, healthHistory[i])
            end

            local totalChange = 0
            for _, change in ipairs(recentChanges) do
                totalChange = totalChange + change.health
            end

            local averageChange = totalChange / trendWindow
            local isDeclining = averageChange < -2 -- Losing more than 2 HP per change

            for _, callback in ipairs(callbacks) do
                if callback.type == "declining" and isDeclining then
                    callback.action(healthPercent, averageChange)
                end
            end
        end
    end)
end

-- Variation 3: Predictive monitoring
function HealthMonitor_Predictive(callbacks)
    local predictionWindow = 10
    local healthHistory = {}

    EnhancedCallbacks.onHealthChange(function(healthPercent, healthChange, healthHistory)
        table.insert(healthHistory, {
            timestamp = now,
            health = healthChange.currentHealth
        })

        if #healthHistory >= predictionWindow then
            -- Simple linear regression to predict future health
            local predictedHealth = predictHealth(healthHistory, 3000) -- Predict 3 seconds ahead

            for _, callback in ipairs(callbacks) do
                if callback.type == "predictive" and predictedHealth <= callback.threshold then
                    callback.action(predictedHealth, healthPercent)
                end
            end
        end
    end)
end

-- ======================== --
-- [[ COMBAT STRATEGY VARIATIONS ]] --
-- ======================== --

-- Variation 1: Aggressive strategy
local CombatStrategy_Aggressive = {
    name = "Aggressive",
    targetSelection = TargetBot.SelectTarget_ThreatBased,
    keepDistance = function(target) return 1 end,
    useAreaSpells = true,
    chaseMode = true,
    description = "Focus on strongest threats, stay close, use area spells"
}

-- Variation 2: Defensive strategy
local CombatStrategy_Defensive = {
    name = "Defensive",
    targetSelection = TargetBot.SelectTarget_HPFirst,
    keepDistance = function(target) return 3 end,
    useAreaSpells = false,
    chaseMode = false,
    description = "Focus on weak targets, keep distance, avoid area spells"
}

-- Variation 3: Balanced strategy
local CombatStrategy_Balanced = {
    name = "Balanced",
    targetSelection = TargetBot.SelectTarget_Weighted,
    keepDistance = function(target) return target.distance > 2 and 2 or 1 end,
    useAreaSpells = function() return TargetBot.getValidTargets(3) >= 3 end,
    chaseMode = true,
    description = "Adaptive approach based on situation"
}

-- Variation 4: Kiting strategy
local CombatStrategy_Kiting = {
    name = "Kiting",
    targetSelection = TargetBot.SelectTarget_DistanceFirst,
    keepDistance = function(target) return 4 end,
    useAreaSpells = false,
    chaseMode = false,
    moveAwayFromTarget = true,
    description = "Stay at range, kite targets, avoid melee"
}

-- ======================== --
-- [[ LOOTING VARIATIONS ]] --
-- ======================== --

-- Variation 1: Standard looting (current implementation)
function Looting_Standard(targets, dangerLevel)
    -- Standard looting logic
    for _, target in ipairs(targets) do
        if target.loot and target.loot.items then
            for _, item in ipairs(target.loot.items) do
                -- Loot item
            end
        end
    end
end

-- Variation 2: Priority-based looting
function Looting_Priority(targets, dangerLevel)
    local lootQueue = {}

    -- Build loot queue with priorities
    for _, target in ipairs(targets) do
        if target.loot and target.loot.items then
            for _, item in ipairs(target.loot.items) do
                local priority = getItemPriority(item.id)
                table.insert(lootQueue, {
                    item = item,
                    priority = priority,
                    distance = getDistanceBetween(pos(), target.position)
                })
            end
        end
    end

    -- Sort by priority, then distance
    table.sort(lootQueue, function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority
        else
            return a.distance < b.distance
        end
    end)

    -- Process loot queue
    for _, lootItem in ipairs(lootQueue) do
        -- Loot high priority items first
    end
end

-- Variation 3: Selective looting based on capacity
function Looting_Selective(targets, dangerLevel)
    local freeSlots = getFreeSlots()
    local lootOnlyValuables = freeSlots < 5 -- Only loot valuable items if low on space

    for _, target in ipairs(targets) do
        if target.loot and target.loot.items then
            for _, item in ipairs(target.loot.items) do
                if not lootOnlyValuables or isValuableItem(item.id) then
                    -- Loot item
                end
            end
        end
    end
end

-- ======================== --
-- [[ MEMORY MANAGEMENT VARIATIONS ]] --
-- ======================== --

-- Variation 1: Simple cache with size limit
local SimpleCache = {
    data = {},
    maxSize = 100,
    hits = 0,
    misses = 0,

    get = function(self, key)
        if self.data[key] then
            self.hits = self.hits + 1
            return self.data[key]
        else
            self.misses = self.misses + 1
            return nil
        end
    end,

    set = function(self, key, value)
        if table.count(self.data) >= self.maxSize then
            -- Remove random entry (simple approach)
            local firstKey = next(self.data)
            self.data[firstKey] = nil
        end
        self.data[key] = value
    end
}

-- Variation 2: LRU (Least Recently Used) cache
local LRUCache = {
    data = {},
    accessOrder = {},
    maxSize = 100,

    get = function(self, key)
        if self.data[key] then
            -- Move to end (most recently used)
            for i, k in ipairs(self.accessOrder) do
                if k == key then
                    table.remove(self.accessOrder, i)
                    break
                end
            end
            table.insert(self.accessOrder, key)
            return self.data[key]
        end
        return nil
    end,

    set = function(self, key, value)
        if not self.data[key] and table.count(self.data) >= self.maxSize then
            -- Remove least recently used
            local lruKey = table.remove(self.accessOrder, 1)
            self.data[lruKey] = nil
        end

        self.data[key] = value
        if not table.find(self.accessOrder, key) then
            table.insert(self.accessOrder, key)
        end
    end
}

-- Variation 3: TTL (Time To Live) cache
local TTLCache = {
    data = {},
    timestamps = {},
    maxSize = 100,
    ttl = 30000, -- 30 seconds

    get = function(self, key)
        if self.data[key] then
            if now - self.timestamps[key] > self.ttl then
                -- Entry expired
                self.data[key] = nil
                self.timestamps[key] = nil
                return nil
            else
                return self.data[key]
            end
        end
        return nil
    end,

    set = function(self, key, value)
        if table.count(self.data) >= self.maxSize then
            -- Remove expired entries first
            for k, timestamp in pairs(self.timestamps) do
                if now - timestamp > self.ttl then
                    self.data[k] = nil
                    self.timestamps[k] = nil
                end
            end

            -- If still full, remove oldest
            if table.count(self.data) >= self.maxSize then
                local oldestKey, oldestTime = nil, now
                for k, timestamp in pairs(self.timestamps) do
                    if timestamp < oldestTime then
                        oldestKey, oldestTime = k, timestamp
                    end
                end
                if oldestKey then
                    self.data[oldestKey] = nil
                    self.timestamps[oldestKey] = nil
                end
            end
        end

        self.data[key] = value
        self.timestamps[key] = now
    end
}

-- ======================== --
-- [[ CONFIGURATION VARIATIONS ]] --
-- ======================== --

-- Variation 1: Simple key-value storage
local Config_Simple = {
    data = {},

    get = function(self, key, default)
        return self.data[key] or default
    end,

    set = function(self, key, value)
        self.data[key] = value
        -- Auto-save could be implemented here
    end
}

-- Variation 2: Hierarchical configuration
local Config_Hierarchical = {
    data = {},

    get = function(self, path, default)
        local keys = string.split(path, ".")
        local current = self.data

        for _, key in ipairs(keys) do
            if type(current) == "table" and current[key] then
                current = current[key]
            else
                return default
            end
        end

        return current
    end,

    set = function(self, path, value)
        local keys = string.split(path, ".")
        local current = self.data

        for i = 1, #keys - 1 do
            local key = keys[i]
            if not current[key] then
                current[key] = {}
            end
            current = current[key]
        end

        current[keys[#keys]] = value
    end
}

-- Variation 3: Profile-based configuration
local Config_ProfileBased = {
    profiles = {},
    currentProfile = "default",

    switchProfile = function(self, profileName)
        if not self.profiles[profileName] then
            self.profiles[profileName] = {}
        end
        self.currentProfile = profileName
    end,

    get = function(self, key, default)
        local profile = self.profiles[self.currentProfile] or {}
        return profile[key] or default
    end,

    set = function(self, key, value)
        if not self.profiles[self.currentProfile] then
            self.profiles[self.currentProfile] = {}
        end
        self.profiles[self.currentProfile][key] = value
    end
}

-- ======================== --
-- [[ IMPLEMENTATION EXAMPLES ]] --
-- ======================== --

-- Example: Dynamic strategy switching based on conditions
function CombatStrategy_Dynamic()
    local strategies = {
        CombatStrategy_Aggressive,
        CombatStrategy_Defensive,
        CombatStrategy_Balanced,
        CombatStrategy_Kiting
    }

    local function evaluateConditions()
        local hpPercent = getHealthPercent()
        local manaPercent = getManaPercent()
        local targets = TargetBot.getValidTargets(5)
        local areaDanger = TargetBot.calculateAreaDanger()

        -- Choose strategy based on conditions
        if hpPercent <= 30 or manaPercent <= 20 then
            return CombatStrategy_Defensive
        elseif areaDanger.danger > 50 and #targets >= 5 then
            return CombatStrategy_Kiting
        elseif #targets >= 3 then
            return CombatStrategy_Balanced
        else
            return CombatStrategy_Aggressive
        end
    end

    -- Apply strategy every few seconds
    macro(3000, function()
        local strategy = evaluateConditions()
        TargetBot.setStrategy(strategy)
        debugLog("info", "Switched to combat strategy: " .. strategy.name)
    end)
end

-- Example: Adaptive pathfinding based on environment
function AdaptivePathfinding(start, goal, options)
    local environment = analyzeEnvironment(start, goal)

    if environment.hasManyCreatures then
        -- Use creature-aware pathfinding
        return findPath(start, goal, options.maxDist, {
            ignoreNonPathable = true,
            ignoreCreatures = false,
            precision = 2
        })
    elseif environment.hasObstacles then
        -- Use obstacle-aware pathfinding
        return findPath(start, goal, options.maxDist, {
            ignoreNonPathable = false,
            ignoreCreatures = true,
            precision = 1
        })
    else
        -- Use standard pathfinding
        return findPath(start, goal, options.maxDist, {
            ignoreNonPathable = true,
            ignoreCreatures = true,
            precision = 1
        })
    end
end

-- Example: Multi-layered health monitoring
function HealthMonitor_MultiLayer()
    local layers = {
        {
            name = "Critical",
            threshold = 20,
            actions = {"use_strong_heal", "retreat", "call_help"}
        },
        {
            name = "Low",
            threshold = 40,
            actions = {"use_heal", "be_careful"}
        },
        {
            name = "Medium",
            threshold = 60,
            actions = {"monitor_trend"}
        },
        {
            name = "Comfortable",
            threshold = 80,
            actions = {"normal_behavior"}
        }
    }

    EnhancedCallbacks.onHealthChange(function(healthPercent, healthChange, healthHistory)
        for _, layer in ipairs(layers) do
            if healthPercent <= layer.threshold then
                for _, action in ipairs(layer.actions) do
                    performHealthAction(action, healthPercent, healthChange)
                end
                break -- Execute only the most critical layer
            end
        end
    end)
end

print("Alternative Implementations Library loaded")
print("This file contains various approaches to implement the same functionality")
print("Use these examples to customize behavior for your specific needs")
