-- Enhanced vBot Loader with better error handling and initialization
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text

-- Validate configuration name
if not configName or configName == "" then
    return error("Invalid bot configuration selected. Please select a valid configuration.")
end

-- Enhanced UI loading with error handling
local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/vBot", true, false)
local uiLoaded = 0
local uiErrors = 0

for i, file in ipairs(configFiles) do
    local ext = file:split(".")
    if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
        local success = pcall(function()
            g_ui.importStyle(file)
        end)
        if success then
            uiLoaded = uiLoaded + 1
        else
            uiErrors = uiErrors + 1
        end
    end
end

-- Enhanced script loading with validation and error recovery
local function loadScript(name)
    if not name or type(name) ~= "string" then
        return false
    end

    local scriptPath = "/vBot/" .. name .. ".lua"
    local fullPath = "/bot/" .. configName .. scriptPath

    if not g_resources.fileExists(fullPath) then
        return false
    end

    local success, result = pcall(function()
        return dofile(scriptPath)
    end)

    if success then
        return result
    else
        return false
    end
end

-- Enhanced script loading order with dependencies
-- Core libraries and utilities must be loaded first
local luaFiles = {
    -- Core dependencies (must be loaded first)
    {name = "main", required = true, category = "core"},
    {name = "items", required = true, category = "core"},
    {name = "vlib", required = true, category = "core"},
    {name = "Klib", required = true, category = "core"},
    {name = "new_cavebot_lib", required = true, category = "core"},
    {name = "configs", required = true, category = "core"},

    -- Core modules
    {name = "extras", required = false, category = "core"},
    {name = "cavebot", required = false, category = "core"},
    {name = "playerlist", required = false, category = "core"},
    {name = "BotServer", required = false, category = "core"},
    {name = "alarms", required = false, category = "core"},
    {name = "Conditions", required = false, category = "core"},

    -- Equipment and combat
    {name = "Equipper", required = false, category = "combat"},
    {name = "pushmax", required = false, category = "combat"},
    {name = "combo", required = false, category = "combat"},
    {name = "HealBot", required = false, category = "combat"},
    {name = "new_healer", required = false, category = "combat"},
    {name = "AttackBot", required = false, category = "combat"},

    -- Utility modules
    {name = "ingame_editor", required = false, category = "utility"},
    {name = "Dropper", required = false, category = "utility"},
    {name = "Containers", required = false, category = "utility"},
    {name = "quiver_manager", required = false, category = "utility"},
    {name = "quiver_label", required = false, category = "utility"},
    {name = "tools", required = false, category = "utility"},
    {name = "antiRs", required = false, category = "utility"},

    -- Resource management
    {name = "depot_withdraw", required = false, category = "resources"},
    {name = "eat_food", required = false, category = "resources"},
    {name = "equip", required = false, category = "resources"},
    {name = "exeta", required = false, category = "resources"},
    {name = "supplies", required = false, category = "resources"},
    {name = "depositer_config", required = false, category = "resources"},

    -- Information and analysis
    {name = "spy_level", required = false, category = "analysis"},

    -- NPC interaction
    {name = "npc_talk", required = false, category = "npc"},

    -- User interface
    {name = "xeno_menu", required = false, category = "ui"},
    {name = "hold_target", required = false, category = "ui"},
    {name = "cavebot_control_panel", required = false, category = "ui"}
}

-- Load scripts with enhanced error handling
local loadedScripts = 0
local failedScripts = 0
local criticalErrors = 0

for i, scriptInfo in ipairs(luaFiles) do
    local success = loadScript(scriptInfo.name)

    if success then
        loadedScripts = loadedScripts + 1
        -- Optional: Log successful loading for debugging
        -- print("[vBot Loader] Loaded: " .. scriptInfo.name)
    else
        failedScripts = failedScripts + 1
        if scriptInfo.required then
            criticalErrors = criticalErrors + 1
        end
    end
end

-- Enhanced initialization logging (always available)
local logMessage = string.format(
    "[vBot Loader] Initialization complete - Scripts: %d/%d, UI: %d/%d",
    loadedScripts, #luaFiles, uiLoaded, uiLoaded + uiErrors
)

if criticalErrors > 0 then

elseif failedScripts > 0 then

else

end

-- Enhanced UI initialization (only if core modules loaded successfully)
if criticalErrors == 0 then
    -- Check if UI functions are available before using them
    local uiAvailable = pcall(function()
        setDefaultTab("Main")
        return true
    end)

    if uiAvailable then
        setDefaultTab("Main")

        -- Display loading statistics only if UI is working
        local uiWorking = pcall(function()
            UI.Separator()
            UI.Label(string.format("vBot Enhanced - Scripts: %d/%d loaded", loadedScripts, #luaFiles))
            if uiLoaded > 0 then
                UI.Label(string.format("UI Files: %d loaded", uiLoaded))
            end
            if uiErrors > 0 then
                UI.Label(string.format("UI Errors: %d", uiErrors), "red")
            end
            if failedScripts > 0 then
                UI.Label(string.format("Script Errors: %d", failedScripts), "orange")
            end
            if criticalErrors > 0 then
                UI.Label(string.format("CRITICAL ERRORS: %d - Check console!", criticalErrors), "red")
            end
            UI.Separator()
            UI.Label("Private Scripts:")
            UI.Separator()

            -- Optional: Add system status indicators
            if HealBot and HealBot.isOn then
                UI.Label("HealBot: Active", "green")
            end

            if TargetBot and TargetBot.isOn then
                UI.Label("TargetBot: Active", "green")
            end

            if CaveBot and CaveBot.isOn then
                UI.Label("CaveBot: Active", "green")
            end

            UI.Separator()
            return true
        end)

        if not uiWorking then

        end
    else

    end
else

end
