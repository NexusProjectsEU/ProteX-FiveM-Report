# Protex Fivem Report

### Config
```
protex.apiKey = ""

protex.enableAutoReport = true

protex.debugMode = false

protex.antiCheats = {
    fiveguard = {
        enabled = true,                    -- Enable FiveGuard integration
        resourceName = "fiveguard",        -- Resource name to check if loaded
        eventName = "fg:BanHandler",       -- Event name to listen for
        requireResource = true,            -- Only enable if resource is running
        displayName = "FiveGuard"          -- Display name for logs
    }
}
```