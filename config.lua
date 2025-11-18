protex = {}

-- NxPDev API Configuration
protex.apiKey = ""

-- Enable/Disable automatic reporting
protex.enableAutoReport = true

-- Debug mode (prints detailed information)
protex.debugMode = false

-- Anti-Cheat Provider Configuration
protex.antiCheats = {
    fiveguard = {
        enabled = true,                    -- Enable FiveGuard integration
        resourceName = "fiveguard",        -- Resource name to check if loaded
        eventName = "fg:BanHandler",       -- Event name to listen for
        requireResource = true,            -- Only enable if resource is running
        displayName = "FiveGuard"          -- Display name for logs
    },

    -- Example: Add txAdmin bans (disabled by default)
    -- txadmin = {
    --     enabled = false,
    --     resourceName = "monitor",
    --     eventName = "txAdmin:events:playerBanned",
    --     requireResource = false,
    --     displayName = "txAdmin"
    -- },

    -- Example: Add other anti-cheats here in the future
    -- anticheat_name = { ... }
}