local standBySpells = false
local standByItems = false

local red = "#ff0800" -- "#ff0800" / #ea3c53 best
local blue = "#7ef9ff"

setDefaultTab("HP")
local healPanelName = "healbot"
local ui = setupUI([[
Panel
  height: 38

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('HealBot')

  Button
    id: settings
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup

  Button
    id: 1
    anchors.top: prev.bottom
    anchors.left: parent.left
    text: 1
    margin-right: 2
    margin-top: 4
    size: 17 17

  Button
    id: 2
    anchors.verticalCenter: prev.verticalCenter
    anchors.left: prev.right
    text: 2
    margin-left: 4
    size: 17 17
    
  Button
    id: 3
    anchors.verticalCenter: prev.verticalCenter
    anchors.left: prev.right
    text: 3
    margin-left: 4
    size: 17 17

  Button
    id: 4
    anchors.verticalCenter: prev.verticalCenter
    anchors.left: prev.right
    text: 4
    margin-left: 4
    size: 17 17 
    
  Button
    id: 5
    anchors.verticalCenter: prev.verticalCenter
    anchors.left: prev.right
    text: 5
    margin-left: 4
    size: 17 17
    
  Label
    id: name
    anchors.verticalCenter: prev.verticalCenter
    anchors.left: prev.right
    anchors.right: parent.right
    text-align: center
    margin-left: 4
    height: 17
    text: Profile #1
    background: #292A2A
]])
ui:setId(healPanelName)

if not HealBotConfig[healPanelName] or not HealBotConfig[healPanelName][1] or #HealBotConfig[healPanelName] ~= 5 then
  HealBotConfig[healPanelName] = {
    [1] = {
      enabled = false,
      spellTable = {},
      itemTable = {},
      name = "Profile #1",
      Visible = true,
      Cooldown = true,
      Interval = true,
      Conditions = true,
      Delay = true,
      MessageDelay = false
    },
    [2] = {
      enabled = false,
      spellTable = {},
      itemTable = {},
      name = "Profile #2",
      Visible = true,
      Cooldown = true,
      Interval = true,
      Conditions = true,
      Delay = true,
      MessageDelay = false
    },
    [3] = {
      enabled = false,
      spellTable = {},
      itemTable = {},
      name = "Profile #3",
      Visible = true,
      Cooldown = true,
      Interval = true,
      Conditions = true,
      Delay = true,
      MessageDelay = false
    },
    [4] = {
      enabled = false,
      spellTable = {},
      itemTable = {},
      name = "Profile #4",
      Visible = true,
      Cooldown = true,
      Interval = true,
      Conditions = true,
      Delay = true,
      MessageDelay = false
    },
    [5] = {
      enabled = false,
      spellTable = {},
      itemTable = {},
      name = "Profile #5",
      Visible = true,
      Cooldown = true,
      Interval = true,
      Conditions = true,
      Delay = true,
      MessageDelay = false
    },
  }
end

if not HealBotConfig.currentHealBotProfile or HealBotConfig.currentHealBotProfile == 0 or HealBotConfig.currentHealBotProfile > 5 then 
  HealBotConfig.currentHealBotProfile = 1
end

-- finding correct table, manual unfortunately
local currentSettings
local setActiveProfile = function()
  local n = HealBotConfig.currentHealBotProfile
  currentSettings = HealBotConfig[healPanelName][n]
end
setActiveProfile()

local activeProfileColor = function()
  for i=1,5 do
    if i == HealBotConfig.currentHealBotProfile then
      ui[i]:setColor("green")
    else
      ui[i]:setColor("white")
    end
  end
end
activeProfileColor()

ui.title:setOn(currentSettings.enabled)
ui.title.onClick = function(widget)
  currentSettings.enabled = not currentSettings.enabled
  widget:setOn(currentSettings.enabled)
  vBotConfigSave("heal")
end

ui.settings.onClick = function(widget)
  healWindow:show()
  healWindow:raise()
  healWindow:focus()
end

rootWidget = g_ui.getRootWidget()
if rootWidget then
  healWindow = UI.createWindow('HealWindow', rootWidget)
  healWindow:hide()

  healWindow.onVisibilityChange = function(widget, visible)
    if not visible then
      vBotConfigSave("heal")
      healWindow.healer:show()
      healWindow.settings:hide()
      healWindow.settingsButton:setText("Settings")
    end
  end

  healWindow.settingsButton.onClick = function(widget)
    if healWindow.healer:isVisible() then
      healWindow.healer:hide()
      healWindow.settings:show()
      widget:setText("Back")
    else
      healWindow.healer:show()
      healWindow.settings:hide()
      widget:setText("Settings")
    end
  end

  local setProfileName = function()
    ui.name:setText(currentSettings.name)
  end
  healWindow.settings.profiles.Name.onTextChange = function(widget, text)
    currentSettings.name = text
    setProfileName()
  end
  healWindow.settings.list.Visible.onClick = function(widget)
    currentSettings.Visible = not currentSettings.Visible
    healWindow.settings.list.Visible:setChecked(currentSettings.Visible)
  end
  healWindow.settings.list.Cooldown.onClick = function(widget)
    currentSettings.Cooldown = not currentSettings.Cooldown
    healWindow.settings.list.Cooldown:setChecked(currentSettings.Cooldown)
  end
  healWindow.settings.list.Interval.onClick = function(widget)
    currentSettings.Interval = not currentSettings.Interval
    healWindow.settings.list.Interval:setChecked(currentSettings.Interval)
  end
  healWindow.settings.list.Conditions.onClick = function(widget)
    currentSettings.Conditions = not currentSettings.Conditions
    healWindow.settings.list.Conditions:setChecked(currentSettings.Conditions)
  end
  healWindow.settings.list.Delay.onClick = function(widget)
    currentSettings.Delay = not currentSettings.Delay
    healWindow.settings.list.Delay:setChecked(currentSettings.Delay)
  end
  healWindow.settings.list.MessageDelay.onClick = function(widget)
    currentSettings.MessageDelay = not currentSettings.MessageDelay
    healWindow.settings.list.MessageDelay:setChecked(currentSettings.MessageDelay)
  end

  local refreshSpells = function()
    if currentSettings.spellTable then
      healWindow.healer.spells.spellList:destroyChildren()
      for _, entry in pairs(currentSettings.spellTable) do
        local label = UI.createWidget("SpellEntry", healWindow.healer.spells.spellList)
        label.enabled:setChecked(entry.enabled)
        label.enabled.onClick = function(widget)
          standBySpells = false
          standByItems = false
          entry.enabled = not entry.enabled
          label.enabled:setChecked(entry.enabled)
        end
        label.remove.onClick = function(widget)
          standBySpells = false
          standByItems = false
          table.removevalue(currentSettings.spellTable, entry)
          reindexTable(currentSettings.spellTable)
          label:destroy()
        end
        label:setText("(MP>" .. entry.cost .. ") " .. entry.origin .. entry.sign .. entry.value .. ": " .. entry.spell)
      end
    end
  end
  refreshSpells()

  local refreshItems = function()
    if currentSettings.itemTable then
      healWindow.healer.items.itemList:destroyChildren()
      for _, entry in pairs(currentSettings.itemTable) do
        local label = UI.createWidget("ItemEntry", healWindow.healer.items.itemList)
        label.enabled:setChecked(entry.enabled)
        label.enabled.onClick = function(widget)
          standBySpells = false
          standByItems = false
          entry.enabled = not entry.enabled
          label.enabled:setChecked(entry.enabled)
        end
        label.remove.onClick = function(widget)
          standBySpells = false
          standByItems = false
          table.removevalue(currentSettings.itemTable, entry)
          reindexTable(currentSettings.itemTable)
          label:destroy()
        end
        label.id:setItemId(entry.item)
        label:setText(entry.origin .. entry.sign .. entry.value .. ": " .. entry.item)
      end
    end
  end
  refreshItems()

  healWindow.healer.spells.MoveUp.onClick = function(widget)
    local input = healWindow.healer.spells.spellList:getFocusedChild()
    if not input then return end
    local index = healWindow.healer.spells.spellList:getChildIndex(input)
    if index < 2 then return end

    local t = currentSettings.spellTable

    t[index],t[index-1] = t[index-1], t[index]
    healWindow.healer.spells.spellList:moveChildToIndex(input, index - 1)
    healWindow.healer.spells.spellList:ensureChildVisible(input)
  end

  healWindow.healer.spells.MoveDown.onClick = function(widget)
    local input = healWindow.healer.spells.spellList:getFocusedChild()
    if not input then return end
    local index = healWindow.healer.spells.spellList:getChildIndex(input)
    if index >= healWindow.healer.spells.spellList:getChildCount() then return end

    local t = currentSettings.spellTable

    t[index],t[index+1] = t[index+1],t[index]
    healWindow.healer.spells.spellList:moveChildToIndex(input, index + 1)
    healWindow.healer.spells.spellList:ensureChildVisible(input)
  end

  healWindow.healer.items.MoveUp.onClick = function(widget)
    local input = healWindow.healer.items.itemList:getFocusedChild()
    if not input then return end
    local index = healWindow.healer.items.itemList:getChildIndex(input)
    if index < 2 then return end

    local t = currentSettings.itemTable

    t[index],t[index-1] = t[index-1], t[index]
    healWindow.healer.items.itemList:moveChildToIndex(input, index - 1)
    healWindow.healer.items.itemList:ensureChildVisible(input)
  end

  healWindow.healer.items.MoveDown.onClick = function(widget)
    local input = healWindow.healer.items.itemList:getFocusedChild()
    if not input then return end
    local index = healWindow.healer.items.itemList:getChildIndex(input)
    if index >= healWindow.healer.items.itemList:getChildCount() then return end

    local t = currentSettings.itemTable

    t[index],t[index+1] = t[index+1],t[index]
    healWindow.healer.items.itemList:moveChildToIndex(input, index + 1)
    healWindow.healer.items.itemList:ensureChildVisible(input)
  end

  healWindow.healer.spells.addSpell.onClick = function(widget)
 
    local spellFormula = healWindow.healer.spells.spellFormula:getText():trim()
    local manaCost = tonumber(healWindow.healer.spells.manaCost:getText())
    local spellTrigger = tonumber(healWindow.healer.spells.spellValue:getText())
    local spellSource = healWindow.healer.spells.spellSource:getCurrentOption().text
    local spellEquasion = healWindow.healer.spells.spellCondition:getCurrentOption().text
    local source
    local equasion

    if not manaCost then  
      warn("HealBot: incorrect mana cost value!")       
      healWindow.healer.spells.spellFormula:setText('')
      healWindow.healer.spells.spellValue:setText('')
      healWindow.healer.spells.manaCost:setText('') 
      return 
    end
    if not spellTrigger then  
      warn("HealBot: incorrect condition value!") 
      healWindow.healer.spells.spellFormula:setText('')
      healWindow.healer.spells.spellValue:setText('')
      healWindow.healer.spells.manaCost:setText('')
      return 
    end

    if spellSource == "Current Mana" then
      source = "MP"
    elseif spellSource == "Current Health" then
      source = "HP"
    elseif spellSource == "Mana Percent" then
      source = "MP%"
    elseif spellSource == "Health Percent" then
      source = "HP%"
    else
      source = "burst"
    end
    
    if spellEquasion == "Above" then
      equasion = ">"
    elseif spellEquasion == "Below" then
      equasion = "<"
    else
      equasion = "="
    end

    if spellFormula:len() > 0 then
      table.insert(currentSettings.spellTable,  {index = #currentSettings.spellTable+1, spell = spellFormula, sign = equasion, origin = source, cost = manaCost, value = spellTrigger, enabled = true})
      healWindow.healer.spells.spellFormula:setText('')
      healWindow.healer.spells.spellValue:setText('')
      healWindow.healer.spells.manaCost:setText('')
    end
    standBySpells = false
    standByItems = false
    refreshSpells()
  end

  healWindow.healer.items.addItem.onClick = function(widget)
 
    local id = healWindow.healer.items.itemId:getItemId()
    local trigger = tonumber(healWindow.healer.items.itemValue:getText())
    local src = healWindow.healer.items.itemSource:getCurrentOption().text
    local eq = healWindow.healer.items.itemCondition:getCurrentOption().text
    local source
    local equasion

    if not trigger then
      warn("HealBot: incorrect trigger value!")
      healWindow.healer.items.itemId:setItemId(0)
      healWindow.healer.items.itemValue:setText('')
      return
    end

    if src == "Current Mana" then
      source = "MP"
    elseif src == "Current Health" then
      source = "HP"
    elseif src == "Mana Percent" then
      source = "MP%"
    elseif src == "Health Percent" then
      source = "HP%"
    else
      source = "burst"
    end
    
    if eq == "Above" then
      equasion = ">"
    elseif eq == "Below" then
      equasion = "<"
    else
      equasion = "="
    end

    if id > 100 then
      table.insert(currentSettings.itemTable, {index = #currentSettings.itemTable+1,item = id, sign = equasion, origin = source, value = trigger, enabled = true})
      standBySpells = false
      standByItems = false
      refreshItems()
      healWindow.healer.items.itemId:setItemId(0)
      healWindow.healer.items.itemValue:setText('')
    end
  end

  healWindow.closeButton.onClick = function(widget)
    healWindow:hide()
  end

  local loadSettings = function()
    ui.title:setOn(currentSettings.enabled)
    setProfileName()
    healWindow.settings.profiles.Name:setText(currentSettings.name)
    refreshSpells()
    refreshItems()
    healWindow.settings.list.Visible:setChecked(currentSettings.Visible)
    healWindow.settings.list.Cooldown:setChecked(currentSettings.Cooldown)
    healWindow.settings.list.Delay:setChecked(currentSettings.Delay)
    healWindow.settings.list.MessageDelay:setChecked(currentSettings.MessageDelay)
    healWindow.settings.list.Interval:setChecked(currentSettings.Interval)
    healWindow.settings.list.Conditions:setChecked(currentSettings.Conditions)
  end
  loadSettings()

  local profileChange = function()
    setActiveProfile()
    activeProfileColor()
    loadSettings()
    vBotConfigSave("heal")
  end

  local resetSettings = function()
    currentSettings.enabled = false
    currentSettings.spellTable = {}
    currentSettings.itemTable = {}
    currentSettings.Visible = true
    currentSettings.Cooldown = true
    currentSettings.Delay = true
    currentSettings.MessageDelay = false
    currentSettings.Interval = true
    currentSettings.Conditions = true
    currentSettings.name = "Profile #" .. HealBotConfig.currentBotProfile
  end

  -- profile buttons
  for i=1,5 do
    local button = ui[i]
      button.onClick = function()
      HealBotConfig.currentHealBotProfile = i
      profileChange()
    end
  end

  healWindow.settings.profiles.ResetSettings.onClick = function()
    resetSettings()
    loadSettings()
  end


  -- public functions
  HealBot = {} -- global table

  HealBot.isOn = function()
    return currentSettings.enabled
  end

  HealBot.isOff = function()
    return not currentSettings.enabled
  end

  HealBot.setOff = function()
    currentSettings.enabled = false
    ui.title:setOn(currentSettings.enabled)
    vBotConfigSave("atk")
  end

  HealBot.setOn = function()
    currentSettings.enabled = true
    ui.title:setOn(currentSettings.enabled)
    vBotConfigSave("atk")
  end

  HealBot.getActiveProfile = function()
    return HealBotConfig.currentHealBotProfile -- returns number 1-5
  end

  HealBot.setActiveProfile = function(n)
    if not n or not tonumber(n) or n < 1 or n > 5 then
      return error("[HealBot] wrong profile parameter! should be 1 to 5 is " .. n)
    else
      HealBotConfig.currentHealBotProfile = n
      profileChange()
    end
  end

  HealBot.show = function()
    healWindow:show()
    healWindow:raise()
    healWindow:focus()
  end
end

-- Enhanced spell healing with better performance and validation
macro(100, function()
  if standBySpells then return end
  if not currentSettings.enabled then return end
  if not currentSettings.spellTable or #currentSettings.spellTable == 0 then return end

  local somethingIsOnCooldown = false
  local currentHP = hp()
  local currentHPPercent = hppercent()
  local currentMP = mana()
  local currentMPPercent = manapercent()
  local burstDmg = burstDamageValue()

  -- Pre-calculate values to avoid repeated function calls
  for _, entry in pairs(currentSettings.spellTable) do
    if not entry.enabled then goto continue end
    if not entry.cost or entry.cost >= currentMP then goto continue end

    if not canCast(entry.spell, not currentSettings.Conditions, not currentSettings.Cooldown) then
      somethingIsOnCooldown = true
      goto continue
    end

    local shouldCast = false

    -- Enhanced condition checking with better performance
    if entry.origin == "HP%" then
      local conditionMet = false
      if entry.sign == "=" then
        conditionMet = currentHPPercent == entry.value
      elseif entry.sign == ">" then
        conditionMet = currentHPPercent >= entry.value
      elseif entry.sign == "<" then
        conditionMet = currentHPPercent <= entry.value
      end
      if conditionMet then shouldCast = true end
    elseif entry.origin == "HP" then
      local conditionMet = false
      if entry.sign == "=" then
        conditionMet = currentHP == entry.value
      elseif entry.sign == ">" then
        conditionMet = currentHP >= entry.value
      elseif entry.sign == "<" then
        conditionMet = currentHP <= entry.value
      end
      if conditionMet then shouldCast = true end
    elseif entry.origin == "MP%" then
      local conditionMet = false
      if entry.sign == "=" then
        conditionMet = currentMPPercent == entry.value
      elseif entry.sign == ">" then
        conditionMet = currentMPPercent >= entry.value
      elseif entry.sign == "<" then
        conditionMet = currentMPPercent <= entry.value
      end
      if conditionMet then shouldCast = true end
    elseif entry.origin == "MP" then
      local conditionMet = false
      if entry.sign == "=" then
        conditionMet = currentMP == entry.value
      elseif entry.sign == ">" then
        conditionMet = currentMP >= entry.value
      elseif entry.sign == "<" then
        conditionMet = currentMP <= entry.value
      end
      if conditionMet then shouldCast = true end
    elseif entry.origin == "burst" then
      local conditionMet = false
      if entry.sign == "=" then
        conditionMet = burstDmg == entry.value
      elseif entry.sign == ">" then
        conditionMet = burstDmg >= entry.value
      elseif entry.sign == "<" then
        conditionMet = burstDmg <= entry.value
      end
      if conditionMet then shouldCast = true end
    end

    if shouldCast then
      local castResult = cast(entry.spell)
      if castResult then
        debugLog("debug", string.format("HealBot: Cast spell '%s' (condition: %s%s%d)",
          entry.spell, entry.origin, entry.sign, entry.value))
        return
      else
        debugLog("info", string.format("HealBot: Failed to cast spell '%s'", entry.spell))
      end
    end

    ::continue::
  end

  if not somethingIsOnCooldown then
    standBySpells = true
  end
end)

-- items
macro(100, function()
  if standByItems then return end
  if not currentSettings.enabled or not currentSettings.itemTable or #currentSettings.itemTable == 0 then return end

  if currentSettings.Delay and vBot.isUsing then return end
  if currentSettings.MessageDelay and vBot.isUsingPotion then return end

  -- Dynamic delay based on situation
  local baseDelay = currentSettings.MessageDelay and 0 or 400
  local targetBotDelay = 0

  if TargetBot and TargetBot.isOn and TargetBot.isOn() and TargetBot.Looting and TargetBot.Looting.getStatus then
    local lootStatus = TargetBot.Looting.getStatus()
    if lootStatus and lootStatus:len() > 0 and currentSettings.Interval then
      targetBotDelay = currentSettings.MessageDelay and 200 or 700
    end
  end

  local totalDelay = baseDelay + targetBotDelay
  if totalDelay > 0 then
    delay(totalDelay)
  end

  local currentHP = hp()
  local currentHPPercent = hppercent()
  local currentMP = mana()
  local currentMPPercent = manapercent()
  local burstDmg = burstDamageValue()

  -- Process item healing entries
  for _, entry in pairs(currentSettings.itemTable) do
    if not entry.enabled then goto continue end

    local item = findItem(entry.item)
    if not item and currentSettings.Visible then goto continue end

    local shouldUse = false

    -- Enhanced condition checking with pre-calculated values
    if entry.origin == "HP%" then
      if entry.sign == "=" and currentHPPercent == entry.value then
        shouldUse = true
      elseif entry.sign == ">" and currentHPPercent >= entry.value then
        shouldUse = true
      elseif entry.sign == "<" and currentHPPercent <= entry.value then
        shouldUse = true
      end
    elseif entry.origin == "HP" then
      if entry.sign == "=" and currentHP == entry.value then
        shouldUse = true
      elseif entry.sign == ">" and currentHP >= entry.value then
        shouldUse = true
      elseif entry.sign == "<" and currentHP <= entry.value then
        shouldUse = true
      end
    elseif entry.origin == "MP%" then
      if entry.sign == "=" and currentMPPercent == entry.value then
        shouldUse = true
      elseif entry.sign == ">" and currentMPPercent >= entry.value then
        shouldUse = true
      elseif entry.sign == "<" and currentMPPercent <= entry.value then
        shouldUse = true
      end
    elseif entry.origin == "MP" then
      if entry.sign == "=" and currentMP == entry.value then
        shouldUse = true
      elseif entry.sign == ">" and currentMP >= entry.value then
        shouldUse = true
      elseif entry.sign == "<" and currentMP <= entry.value then
        shouldUse = true
      end
    elseif entry.origin == "burst" then
      if entry.sign == "=" and burstDmg == entry.value then
        shouldUse = true
      elseif entry.sign == ">" and burstDmg >= entry.value then
        shouldUse = true
      elseif entry.sign == "<" and burstDmg <= entry.value then
        shouldUse = true
      end
    end

    if shouldUse then
      local useResult = g_game.useInventoryItemWith(entry.item, player)
      if useResult then
        debugLog("debug", string.format("HealBot: Used item ID %d (condition: %s%s%d)",
          entry.item, entry.origin, entry.sign, entry.value))
        return
      else
        debugLog("info", string.format("HealBot: Failed to use item ID %d", entry.item))
      end
    end

    ::continue::
  end

  standByItems = true
end)
UI.Separator()

-- Enhanced health and mana change handlers with additional validation
onPlayerHealthChange(function(healthPercent)
  if type(healthPercent) ~= "number" or healthPercent < 0 or healthPercent > 100 then return end

  standByItems = false
  standBySpells = false

  debugLog("debug", string.format("HealBot: Health changed to %d%%", healthPercent))
end)

onManaChange(function(player, mana, maxMana, oldMana, oldMaxMana)
  if not mana or not maxMana then return end
  if mana < 0 or maxMana <= 0 then return end

  standByItems = false
  standBySpells = false

  local manaPercent = math.floor((mana / maxMana) * 100)
  debugLog("debug", string.format("HealBot: Mana changed to %d/%d (%d%%)", mana, maxMana, manaPercent))
end)

-- Additional HealBot utility functions
function HealBot.addSpellEntry(spell, condition, value, cost)
  if not spell or type(spell) ~= "string" then return false end
  if not condition or type(condition) ~= "string" then return false end
  if not value or type(value) ~= "number" then return false end
  if not cost or type(cost) ~= "number" then cost = 0 end

  local newEntry = {
    index = #currentSettings.spellTable + 1,
    spell = spell,
    sign = condition,
    origin = "HP%", -- Default to HP%
    value = value,
    cost = cost,
    enabled = true
  }

  table.insert(currentSettings.spellTable, newEntry)
  refreshSpells()

  debugLog("info", string.format("HealBot: Added spell entry '%s' (%s %d)",
    spell, condition, value))

  return true
end

function HealBot.addItemEntry(itemId, condition, value)
  if not itemId or type(itemId) ~= "number" then return false end
  if not condition or type(condition) ~= "string" then return false end
  if not value or type(value) ~= "number" then return false end

  local newEntry = {
    index = #currentSettings.itemTable + 1,
    item = itemId,
    sign = condition,
    origin = "HP%", -- Default to HP%
    value = value,
    enabled = true
  }

  table.insert(currentSettings.itemTable, newEntry)
  refreshItems()

  debugLog("info", string.format("HealBot: Added item entry ID %d (%s %d)",
    itemId, condition, value))

  return true
end

function HealBot.clearAllEntries()
  currentSettings.spellTable = {}
  currentSettings.itemTable = {}
  refreshSpells()
  refreshItems()

  debugLog("info", "HealBot: Cleared all healing entries")

  return true
end

function HealBot.getSpellEntries()
  return currentSettings.spellTable or {}
end

function HealBot.getItemEntries()
  return currentSettings.itemTable or {}
end

function HealBot.getStatus()
  local status = {
    enabled = currentSettings.enabled,
    profile = HealBotConfig.currentHealBotProfile,
    spellCount = #currentSettings.spellTable,
    itemCount = #currentSettings.itemTable,
    standBySpells = standBySpells,
    standByItems = standByItems
  }
  return status
end

-- Emergency healing function for critical situations
function HealBot.emergencyHeal()
  if not currentSettings.enabled then return false end

  local hpPercent = hppercent()
  local mpPercent = manapercent()

  -- Critical HP - use most powerful healing item available
  if hpPercent <= 20 then
    for _, entry in pairs(currentSettings.itemTable) do
      if entry.enabled and entry.origin == "HP%" and entry.sign == "<" then
        local item = findItem(entry.item)
        if item then
          local useResult = g_game.useInventoryItemWith(entry.item, player)
          if useResult then
            debugLog("info", "HealBot: Emergency heal used item ID " .. entry.item)
            return true
          end
        end
      end
    end
  end

  -- Critical MP - use most powerful mana item available
  if mpPercent <= 15 then
    for _, entry in pairs(currentSettings.itemTable) do
      if entry.enabled and entry.origin == "MP%" and entry.sign == "<" then
        local item = findItem(entry.item)
        if item then
          local useResult = g_game.useInventoryItemWith(entry.item, player)
          if useResult then
            debugLog("info", "HealBot: Emergency mana restore used item ID " .. entry.item)
            return true
          end
        end
      end
    end
  end

  return false
end

-- Auto-enable emergency healing when HP is critical
macro(500, function()
  local hpPercent = hppercent()
  if hpPercent <= 25 and currentSettings.enabled then
    HealBot.emergencyHeal()
  end
end)