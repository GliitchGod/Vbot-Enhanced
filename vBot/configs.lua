--[[
    Enhanced Configs for modules
    Based on Kondrah storage method with improvements
--]]

-- Enhanced configuration system with better error handling and validation
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text

-- Validate config name
if not configName or configName == "" then
    return onError("Invalid configuration name. Please select a valid bot configuration.")
end

-- Create vBot config directory with error handling
local configDir = "/bot/".. configName .."/vBot_configs/"
if not g_resources.directoryExists(configDir) then
    local success = g_resources.makeDir(configDir)
    if not success then
        return onError("Failed to create vBot configuration directory: " .. configDir)
    end
end

-- Create profile directories with validation
local MAX_PROFILES = 10
for i=1, MAX_PROFILES do
    local path = "/bot/".. configName .."/vBot_configs/profile_"..i
    if not g_resources.directoryExists(path) then
        local success = g_resources.makeDir(path)
        if not success then
            debugLog("error", string.format("Failed to create profile directory: %s", path))
        end
    end
end

-- Enhanced profile management
local profile = g_settings.getNumber('profile')
if not profile or profile < 1 or profile > MAX_PROFILES then
    profile = 1 -- Default to profile 1
    g_settings.setNumber('profile', profile)
    debugLog("info", string.format("Invalid profile number, defaulting to profile %d", profile))
end

-- Configuration file paths with validation
HealBotConfig = {}
local healBotFile = "/bot/" .. configName .. "/vBot_configs/profile_".. profile .. "/HealBot.json"
AttackBotConfig = {}
local attackBotFile = "/bot/" .. configName .. "/vBot_configs/profile_".. profile .. "/AttackBot.json"
SuppliesConfig = {}
local suppliesFile = "/bot/" .. configName .. "/vBot_configs/profile_".. profile .. "/Supplies.json"

-- Enhanced configuration validation
local function validateConfigPath(filePath, configType)
    if not filePath or filePath == "" then
        debugLog("error", string.format("Invalid %s config file path", configType))
        return false
    end

    -- Check if directory exists
    local dirPath = filePath:match("(.+)/[^/]+$")
    if not g_resources.directoryExists(dirPath) then
        local success = g_resources.makeDir(dirPath)
        if not success then
            debugLog("error", string.format("Failed to create directory for %s config: %s", configType, dirPath))
            return false
        end
    end

    return true
end

-- Validate all config paths
if not validateConfigPath(healBotFile, "HealBot") or
   not validateConfigPath(attackBotFile, "AttackBot") or
   not validateConfigPath(suppliesFile, "Supplies") then
    debugLog("error", "Configuration path validation failed")
end


-- Enhanced configuration loading with backup and recovery
local function loadConfig(filePath, configType, configTable)
    if not g_resources.fileExists(filePath) then
        debugLog("info", string.format("%s config file does not exist, using defaults: %s", configType, filePath))
        return true
    end

    local fileContents = g_resources.readFileContents(filePath)
    if not fileContents or fileContents == "" then
        debugLog("error", string.format("Empty or unreadable %s config file: %s", configType, filePath))
        return false
    end

    local status, result = pcall(function()
        return json.decode(fileContents)
    end)

    if not status then
        debugLog("error", string.format("Error reading %s config file (%s): %s",
            configType, filePath, result))

        -- Try to restore from backup
        local backupFile = filePath .. ".backup"
        if g_resources.fileExists(backupFile) then
            debugLog("info", string.format("Attempting to restore %s config from backup", configType))
            local backupContents = g_resources.readFileContents(backupFile)
            if backupContents then
                local backupStatus, backupResult = pcall(function()
                    return json.decode(backupContents)
                end)
                if backupStatus then
                    configTable = backupResult
                    debugLog("info", string.format("Successfully restored %s config from backup", configType))
                    return true
                end
            end
        end

        debugLog("error", string.format("Failed to restore %s config from backup, using defaults", configType))
        return false
    end

    -- Validate configuration structure
    if type(result) ~= "table" then
        debugLog("error", string.format("Invalid %s config structure, expected table", configType))
        return false
    end

    configTable = result
    debugLog("info", string.format("Successfully loaded %s config with %d entries",
        configType, table.count(result)))

    return true
end

-- Load all configurations
loadConfig(healBotFile, "HealBot", HealBotConfig)
loadConfig(attackBotFile, "AttackBot", AttackBotConfig)
loadConfig(suppliesFile, "Supplies", SuppliesConfig)

-- Enhanced configuration saving with backup and validation
function vBotConfigSave(file)
    if not file then
        debugLog("error", "vBotConfigSave: No file specified")
        return false
    end

    file = file:lower()

    -- Determine config file and table
    local configFile, configTable, configType
    if file == "heal" then
        configFile = healBotFile
        configTable = HealBotConfig
        configType = "HealBot"
    elseif file == "atk" or file == "attack" then
        configFile = attackBotFile
        configTable = AttackBotConfig
        configType = "AttackBot"
    elseif file == "supply" or file == "supplies" then
        configFile = suppliesFile
        configTable = SuppliesConfig
        configType = "Supplies"
    else
        debugLog("error", string.format("vBotConfigSave: Unknown config type '%s'", file))
        return false
    end

    -- Validate config table
    if type(configTable) ~= "table" then
        debugLog("error", string.format("vBotConfigSave: Invalid %s config table", configType))
        return false
    end

    -- Create backup before saving
    if g_resources.fileExists(configFile) then
        local backupFile = configFile .. ".backup"
        local originalContent = g_resources.readFileContents(configFile)
        if originalContent then
            g_resources.writeFileContents(backupFile, originalContent)
            debugLog("debug", string.format("Created backup for %s config", configType))
        end
    end

    -- Encode configuration with error handling
    local status, result = pcall(function()
        return json.encode(configTable, 2)
    end)

    if not status then
        debugLog("error", string.format("Error encoding %s config: %s", configType, result))
        return false
    end

    -- Validate file size
    local MAX_FILE_SIZE = 100 * 1024 * 1024 -- 100MB
    if result:len() > MAX_FILE_SIZE then
        debugLog("error", string.format("%s config file too large (%d bytes), maximum is %d bytes",
            configType, result:len(), MAX_FILE_SIZE))
        return false
    end

    -- Write file with validation
    local writeSuccess = g_resources.writeFileContents(configFile, result)
    if not writeSuccess then
        debugLog("error", string.format("Failed to write %s config file: %s", configType, configFile))
        return false
    end

    debugLog("debug", string.format("Successfully saved %s config (%d bytes) to %s",
        configType, result:len(), configFile))

    return true
end

-- Additional configuration management functions
function vBotConfigReset(configType)
    if not configType then return false end

    configType = configType:lower()

    if configType == "heal" then
        HealBotConfig = {}
        return vBotConfigSave("heal")
    elseif configType == "atk" or configType == "attack" then
        AttackBotConfig = {}
        return vBotConfigSave("atk")
    elseif configType == "supply" or configType == "supplies" then
        SuppliesConfig = {}
        return vBotConfigSave("supply")
    elseif configType == "all" then
        HealBotConfig = {}
        AttackBotConfig = {}
        SuppliesConfig = {}
        local healSuccess = vBotConfigSave("heal")
        local attackSuccess = vBotConfigSave("atk")
        local suppliesSuccess = vBotConfigSave("supply")
        return healSuccess and attackSuccess and suppliesSuccess
    end

    return false
end

function vBotConfigBackup()
    local successCount = 0
    local totalCount = 0

    for _, configInfo in ipairs({
        {file = healBotFile, table = HealBotConfig, type = "HealBot"},
        {file = attackBotFile, table = AttackBotConfig, type = "AttackBot"},
        {file = suppliesFile, table = SuppliesConfig, type = "Supplies"}
    }) do
        totalCount = totalCount + 1
        if g_resources.fileExists(configInfo.file) then
            local content = g_resources.readFileContents(configInfo.file)
            if content then
                local backupFile = configInfo.file .. ".manual_backup"
                if g_resources.writeFileContents(backupFile, content) then
                    successCount = successCount + 1
                    debugLog("info", string.format("Created manual backup for %s config", configInfo.type))
                end
            end
        end
    end

    debugLog("info", string.format("Backup completed: %d/%d configs backed up successfully", successCount, totalCount))
    return successCount == totalCount
end

function vBotConfigGetStatus()
    local status = {
        profile = profile,
        configName = configName,
        configs = {}
    }

    for _, configInfo in ipairs({
        {file = healBotFile, table = HealBotConfig, type = "HealBot"},
        {file = attackBotFile, table = AttackBotConfig, type = "AttackBot"},
        {file = suppliesFile, table = SuppliesConfig, type = "Supplies"}
    }) do
        local exists = g_resources.fileExists(configInfo.file)
        local backupExists = g_resources.fileExists(configInfo.file .. ".backup")
        local entryCount = table.count(configInfo.table)

        table.insert(status.configs, {
            type = configInfo.type,
            file = configInfo.file,
            exists = exists,
            backupExists = backupExists,
            entryCount = entryCount,
            size = exists and #g_resources.readFileContents(configInfo.file) or 0
        })
    end

    return status
end

-- Initialize configuration system
debugLog("info", string.format("Configuration system initialized for profile %d (%s)", profile, configName))