local targetbotMacro = nil
local config = nil
local lastAction = 0
local cavebotAllowance = 0
local lureEnabled = true
local dangerValue = 0
local looterStatus = ""

-- ui
local configWidget = UI.Config()
local ui = UI.createWidget("TargetBotPanel")

ui.list = ui.listPanel.list -- shortcut
TargetBot.targetList = ui.list
TargetBot.Looting.setup()

ui.status.left:setText("Status:")
ui.status.right:setText("Off")
ui.target.left:setText("Target:")
ui.target.right:setText("-")
ui.config.left:setText("Config:")
ui.config.right:setText("-")
ui.danger.left:setText("Danger:")
ui.danger.right:setText("0")

ui.editor.debug.onClick = function()
  local on = ui.editor.debug:isOn()
  ui.editor.debug:setOn(not on)
  if on then
    for _, spec in ipairs(getSpectators()) do
      spec:clearText()
    end
  end
end

local oldTibia = g_game.getClientVersion() < 960

-- Enhanced main targetbot loop with better performance and validation
local lastPerformanceCheck = now
local performanceStats = {
  creaturesScanned = 0,
  targetsFound = 0,
  pathsCalculated = 0,
  averageScanTime = 0
}

targetbotMacro = macro(100, function()
  local startTime = now
  local pos = player:getPosition()

  if not pos then
    debugLog("error", "TargetBot: Unable to get player position")
    return
  end

  -- Enhanced spectator scanning with better performance
  local specs = g_map.getSpectatorsInRange(pos, false, 6, 6) -- 12x12 area
  local creatures = 0
  local monsters = {}

  -- Pre-filter monsters for better performance
  for i, spec in ipairs(specs) do
    if spec and spec:isMonster() then
      creatures = creatures + 1
      table.insert(monsters, spec)
    end
  end

  -- Adaptive area scanning based on monster density
  if creatures > 10 then
    specs = g_map.getSpectatorsInRange(pos, false, 3, 3) -- 6x6 area
    monsters = {}
    for i, spec in ipairs(specs) do
      if spec and spec:isMonster() then
        table.insert(monsters, spec)
      end
    end
  end

  local dangerLevel = 0
  local targets = 0
  local validTargets = {}
  local pathsCalculated = 0

  -- Enhanced creature processing with HP and distance prioritization
  for i, creature in ipairs(monsters) do
    if not creature then goto continue end

    local hppc = creature:getHealthPercent()
    if not hppc or hppc <= 0 then goto continue end

    -- Enhanced path finding with better options
    local path = findPath(player:getPosition(), creature:getPosition(), 7, {
      ignoreLastCreature = true,
      ignoreNonPathable = true,
      ignoreCost = true,
      ignoreCreatures = true
    })

    pathsCalculated = pathsCalculated + 1

    if creature:isMonster() and (oldTibia or creature:getType() < 3) and path then
      local params = TargetBot.Creature.calculateParams(creature, path)
      if params and params.priority and params.priority > 0 then
        targets = targets + 1
        dangerLevel = dangerLevel + (params.danger or 0)

        -- Store target information for HP/distance prioritization
        table.insert(validTargets, {
          params = params,
          hpPercent = hppc,
          distance = #path,
          creature = creature
        })
      end
    end

    ::continue::
  end

  -- Sort targets by distance (closest first), then by HP (lowest first)
  table.sort(validTargets, function(a, b)
    if a.distance ~= b.distance then
      return a.distance < b.distance -- Closer distance first
    else
      return a.hpPercent < b.hpPercent -- Lower HP first (tiebreaker)
    end
  end)

  -- Select the best target (first in sorted list)
  local highestPriorityParams = nil
  if #validTargets > 0 then
    highestPriorityParams = validTargets[1].params

    -- Enhanced debug display with HP and distance info
    if ui.editor.debug:isOn() then
      for _, target in ipairs(validTargets) do
        local debugText = string.format("%s\nHP:%d%% D:%d",
          target.params.config.name, target.hpPercent, target.distance)
        target.creature:setText(debugText)
      end
    end
  end

  -- Update performance statistics
  local scanTime = now - startTime
  performanceStats.creaturesScanned = #monsters
  performanceStats.targetsFound = targets
  performanceStats.pathsCalculated = pathsCalculated
  performanceStats.averageScanTime = ((performanceStats.averageScanTime * 9) + scanTime) / 10

  -- reset walking
  TargetBot.walkTo(nil)

  -- looting
  local looting = TargetBot.Looting.process(targets, dangerLevel)
  local lootingStatus = TargetBot.Looting.getStatus()
  looterStatus = TargetBot.Looting.getStatus()
  dangerValue = dangerLevel

  ui.danger.right:setText(dangerLevel)
  if highestPriorityParams and not isInPz() then
    ui.target.right:setText(highestPriorityParams.creature:getName())
    ui.config.right:setText(highestPriorityParams.config.name)
    TargetBot.Creature.attack(highestPriorityParams, targets, looting)    
    if lootingStatus:len() > 0 then
      TargetBot.setStatus("Attack & " .. lootingStatus)
    elseif cavebotAllowance > now then
      TargetBot.setStatus("Luring using CaveBot")
    else
      TargetBot.setStatus("Attacking")
      if not lureEnabled then
        TargetBot.setStatus("Attacking (luring off)")      
      end
    end
    TargetBot.walk()
    lastAction = now
    return
  end

  ui.target.right:setText("-")
  ui.config.right:setText("-")
  if looting then
    TargetBot.walk()
    lastAction = now
  end
  if lootingStatus:len() > 0 then
    TargetBot.setStatus(lootingStatus)
  else
    TargetBot.setStatus("Waiting")
  end
end)

-- config, its callback is called immediately, data can be nil
config = Config.setup("targetbot_configs", configWidget, "json", function(name, enabled, data)
  if not data then
    ui.status.right:setText("Off")
    return targetbotMacro.setOff() 
  end
  TargetBot.Creature.resetConfigs()
  for _, value in ipairs(data["targeting"] or {}) do
    TargetBot.Creature.addConfig(value)
  end
  TargetBot.Looting.update(data["looting"] or {})

  -- add configs
  if enabled then
    ui.status.right:setText("On")
  else
    ui.status.right:setText("Off")
  end

  targetbotMacro.setOn(enabled)
  targetbotMacro.delay = nil
  lureEnabled = true
end)

-- setup ui
ui.editor.buttons.add.onClick = function()
  TargetBot.Creature.edit(nil, function(newConfig)
    TargetBot.Creature.addConfig(newConfig, true)
    TargetBot.save()
  end)
end

ui.editor.buttons.edit.onClick = function()
  local entry = ui.list:getFocusedChild()
  if not entry then return end
  TargetBot.Creature.edit(entry.value, function(newConfig)
    entry:setText(newConfig.name)
    entry.value = newConfig
    TargetBot.Creature.resetConfigsCache()
    TargetBot.save()
  end)
end

ui.editor.buttons.remove.onClick = function()
  local entry = ui.list:getFocusedChild()
  if not entry then return end
  entry:destroy()
  TargetBot.Creature.resetConfigsCache()
  TargetBot.save()
end

-- public function, you can use them in your scripts
TargetBot.isActive = function() -- return true if attacking or looting takes place
  return lastAction + 300 > now
end

TargetBot.isCaveBotActionAllowed = function()
  return cavebotAllowance > now
end

TargetBot.setStatus = function(text)
  return ui.status.right:setText(text)
end

TargetBot.getStatus = function()
  return ui.status.right:getText()
end

TargetBot.isOn = function()
  return config.isOn()
end

TargetBot.isOff = function()
  return config.isOff()
end

TargetBot.setOn = function(val)
  if val == false then  
    return TargetBot.setOff(true)
  end
  config.setOn()
end

TargetBot.setOff = function(val)
  if val == false then  
    return TargetBot.setOn(true)
  end
  config.setOff()
end

TargetBot.getCurrentProfile = function()
  return storage._configs.targetbot_configs.selected
end

local botConfigName = modules.game_bot.contentsPanel.config:getCurrentOption().text
TargetBot.setCurrentProfile = function(name)
  if not g_resources.fileExists("/bot/"..botConfigName.."/targetbot_configs/"..name..".json") then
    return warn("there is no targetbot profile with that name!")
  end
  TargetBot.setOff()
  storage._configs.targetbot_configs.selected = name
  TargetBot.setOn()
end

TargetBot.delay = function(value)
  targetbotMacro.delay = now + value
end

TargetBot.save = function()
  local data = {targeting={}, looting={}}
  for _, entry in ipairs(ui.list:getChildren()) do
    table.insert(data.targeting, entry.value)
  end
  TargetBot.Looting.save(data.looting)
  config.save(data)
end

TargetBot.allowCaveBot = function(time)
  cavebotAllowance = now + time
end

TargetBot.disableLuring = function()
  lureEnabled = false
end

TargetBot.enableLuring = function()
  lureEnabled = true
end

TargetBot.Danger = function()
  return dangerValue
end

TargetBot.lootStatus = function()
  return looterStatus
end


-- attacks
local lastSpell = 0
local lastAttackSpell = 0

TargetBot.saySpell = function(text, delay)
  if type(text) ~= 'string' or text:len() < 1 then return end
  if not delay then delay = 500 end
  if g_game.getProtocolVersion() < 1090 then
    lastAttackSpell = now -- pause attack spells, healing spells are more important
  end
  if lastSpell + delay < now then
    say(text)
    lastSpell = now
    return true
  end
  return false
end

TargetBot.sayAttackSpell = function(text, delay)
  if type(text) ~= 'string' or text:len() < 1 then return end
  if not delay then delay = 2000 end
  if lastAttackSpell + delay < now then
    say(text)
    lastAttackSpell = now
    return true
  end
  return false
end

local lastItemUse = 0
local lastRuneAttack = 0

TargetBot.useItem = function(item, subType, target, delay)
  if not delay then delay = 200 end
  if lastItemUse + delay < now then
    local thing = g_things.getThingType(item)
    if not thing or not thing:isFluidContainer() then
      subType = g_game.getClientVersion() >= 860 and 0 or 1
    end
    if g_game.getClientVersion() < 780 then
      local tmpItem = g_game.findPlayerItem(item, subType)
      if not tmpItem then return end
      g_game.useWith(tmpItem, target, subType) -- using item from bp
    else
      g_game.useInventoryItemWith(item, target, subType) -- hotkey
    end
    lastItemUse = now
  end
end

TargetBot.useAttackItem = function(item, subType, target, delay)
  if not delay then delay = 2000 end
  if lastRuneAttack + delay < now then
    local thing = g_things.getThingType(item)
    if not thing or not thing:isFluidContainer() then
      subType = g_game.getClientVersion() >= 860 and 0 or 1
    end
    if g_game.getClientVersion() < 780 then
      local tmpItem = g_game.findPlayerItem(item, subType)
      if not tmpItem then return end
      g_game.useWith(tmpItem, target, subType) -- using item from bp  
    else
      g_game.useInventoryItemWith(item, target, subType) -- hotkey
    end
    lastRuneAttack = now
  end
end

TargetBot.canLure = function()
  return lureEnabled
end

-- Enhanced TargetBot utility functions

-- Get performance statistics
TargetBot.getPerformanceStats = function()
  return {
    creaturesScanned = performanceStats.creaturesScanned,
    targetsFound = performanceStats.targetsFound,
    pathsCalculated = performanceStats.pathsCalculated,
    averageScanTime = performanceStats.averageScanTime,
    scanEfficiency = performanceStats.creaturesScanned > 0 and
      (performanceStats.targetsFound / performanceStats.creaturesScanned) * 100 or 0
  }
end

-- Enhanced status checking with more details
TargetBot.getDetailedStatus = function()
  local status = {
    isActive = TargetBot.isActive(),
    isOn = TargetBot.isOn(),
    status = TargetBot.getStatus(),
    target = ui.target.right:getText(),
    config = ui.config.right:getText(),
    danger = dangerValue,
    looterStatus = looterStatus,
    lastAction = now - lastAction,
    cavebotAllowance = cavebotAllowance > now,
    lureEnabled = lureEnabled,
    performance = TargetBot.getPerformanceStats()
  }
  return status
end

-- Enhanced target validation
TargetBot.isValidTarget = function(creature)
  if not creature then return false end
  if not creature:isMonster() then return false end

  local hppc = creature:getHealthPercent()
  if not hppc or hppc <= 0 then return false end

  -- Check if creature is reachable
  local path = findPath(player:getPosition(), creature:getPosition(), 7, {
    ignoreLastCreature = true,
    ignoreNonPathable = true,
    ignoreCost = true,
    ignoreCreatures = true
  })

  return path ~= nil
end

-- Get all valid targets in range
TargetBot.getValidTargets = function(range)
  range = range or 6
  local pos = player:getPosition()
  local specs = g_map.getSpectatorsInRange(pos, false, range, range)
  local validTargets = {}

  for _, creature in ipairs(specs) do
    if TargetBot.isValidTarget(creature) then
      table.insert(validTargets, creature)
    end
  end

  return validTargets
end

-- Calculate optimal attack position for a creature
TargetBot.getOptimalAttackPosition = function(creature, config)
  if not creature then return nil end

  local cpos = creature:getPosition()
  local ppos = player:getPosition()
  local distance = getDistanceBetween(ppos, cpos)

  -- If already in optimal range, stay put
  if config.minRange and config.maxRange then
    if distance >= config.minRange and distance <= config.maxRange then
      return ppos
    end
  end

  -- Find best position around the creature
  local bestPos = nil
  local bestScore = -999

  for x = -1, 1 do
    for y = -1, 1 do
      if x ~= 0 or y ~= 0 then -- Don't check current position
        local testPos = {x = cpos.x + x, y = cpos.y + y, z = cpos.z}
        local tile = g_map.getTile(testPos)

        if tile and tile:isWalkable() then
          local testDistance = getDistanceBetween(testPos, cpos)
          local path = findPath(ppos, testPos, 7, {
            ignoreLastCreature = true,
            ignoreNonPathable = true,
            ignoreCreatures = true
          })

          if path then
            local score = 0
            -- Prefer positions at optimal range
            if config.minRange and config.maxRange then
              if testDistance >= config.minRange and testDistance <= config.maxRange then
                score = score + 10
              elseif testDistance < config.minRange then
                score = score - (config.minRange - testDistance) * 2
              else
                score = score - (testDistance - config.maxRange) * 2
              end
            end

            if score > bestScore then
              bestScore = score
              bestPos = testPos
            end
          end
        end
      end
    end
  end

  return bestPos
end

-- Enhanced danger assessment
TargetBot.calculateAreaDanger = function(position, radius)
  if not position then position = player:getPosition() end
  radius = radius or 6

  local specs = g_map.getSpectatorsInRange(position, false, radius, radius)
  local danger = 0
  local monsters = 0

  for _, creature in ipairs(specs) do
    if creature and creature:isMonster() then
      monsters = monsters + 1
      local configs = TargetBot.Creature.getConfigs(creature)
      for _, config in ipairs(configs) do
        danger = danger + (config.danger or 1)
      end
    end
  end

  return {
    danger = danger,
    monsters = monsters,
    dangerPerMonster = monsters > 0 and (danger / monsters) or 0
  }
end

-- Check if it's safe to lure more monsters
TargetBot.canLureMore = function(maxDanger, maxMonsters)
  maxDanger = maxDanger or 50
  maxMonsters = maxMonsters or 10

  local areaStats = TargetBot.calculateAreaDanger()
  return areaStats.danger < maxDanger and areaStats.monsters < maxMonsters
end

-- Danger detection function (no longer moves character)
TargetBot.handleDanger = function()
  local areaStats = TargetBot.calculateAreaDanger()

  if areaStats.danger > 100 or areaStats.monsters > 15 then
    debugLog("info", string.format("TargetBot: High danger detected (danger: %d, monsters: %d) - Standing ground",
      areaStats.danger, areaStats.monsters))

    -- Only log the danger, don't move the character
    return false
  end

  return false
end

-- Enhanced attack coordination with other modules
TargetBot.isSafeToAttack = function()
  -- Check if healbot needs priority
  if HealBot and HealBot.isOn then
    local hpPercent = getHealthPercent()
    local mpPercent = getManaPercent()

    if hpPercent <= 25 or mpPercent <= 15 then
      return false -- Let healbot handle critical situations first
    end
  end

  -- Check if cavebot is in critical action
  if CaveBot and CaveBot.isOn and CaveBot.isWalking then
    return false -- Don't interrupt cavebot movement
  end

  return true
end

-- Initialize enhanced features
debugLog("info", "TargetBot enhanced with performance monitoring and safety features")

-- Periodic danger check
macro(2000, function()
  if TargetBot.isOn() and TargetBot.isActive() then
    TargetBot.handleDanger()
  end
end)