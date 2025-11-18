-- ============================================================================
-- PROTEX REPORT SYSTEM - Modular Anti-Cheat Integration
-- ============================================================================

local activeProviders = {}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function GetDiscordId(source)
    if protex.debugMode then
        print("^3[Protex Report DEBUG] GetDiscordId called with source: " .. tostring(source) .. "^0")
    end

    if not source or source == 0 then
        if protex.debugMode then
            print("^1[Protex Report DEBUG] Source is nil or 0^0")
        end
        return nil
    end

    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then
        if protex.debugMode then
            print("^1[Protex Report DEBUG] No identifiers found for source^0")
        end
        return nil
    end

    if protex.debugMode then
        print("^3[Protex Report DEBUG] Found " .. #identifiers .. " identifiers:^0")
        for i, id in pairs(identifiers) do
            print("^3[Protex Report DEBUG]   [" .. i .. "] " .. tostring(id) .. "^0")
        end
    end

    for _, id in pairs(identifiers) do
        if string.match(id, "discord:") then
            local discordId = string.gsub(id, "discord:", "")
            if protex.debugMode then
                print("^2[Protex Report DEBUG] Discord ID found: " .. discordId .. "^0")
            end
            return discordId
        end
    end

    if protex.debugMode then
        print("^1[Protex Report DEBUG] No Discord identifier found in player identifiers^0")
    end

    return nil
end

local function GetPlayerNameSafe(source)
    if not source or source == 0 then
        return "Unknown Player"
    end

    local name = GetPlayerName(source)
    return name or "Unknown Player"
end

local function SendReportToAPI(discordId, playerName, reason, evidence)
    if not protex.enableAutoReport then
        if protex.debugMode then
            print("^3[Protex Report] Auto-reporting is disabled^0")
        end
        return
    end

    if not discordId or discordId == "" then
        print("^1[Protex Report] ERROR: No Discord ID found for banned player^0")
        return
    end

    discordId = tostring(discordId)

    local payload = {
        reportedUserId = discordId,
        reason = reason or "Banned by FiveGuard Anti-Cheat",
        evidence = evidence or "No additional evidence provided"
    }

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. protex.apiKey
    }

    if protex.debugMode then
        print("^2[Protex Report] Sending report for: " .. playerName .. " (Discord: " .. discordId .. ")^0")
        print("^2[Protex Report] Reason: " .. payload.reason .. "^0")
        print("^2[Protex Report DEBUG] Full JSON Payload:^0")
        local jsonPayload = json.encode(payload)
        print("^2[Protex Report DEBUG] " .. jsonPayload .. "^0")
        print("^2[Protex Report DEBUG] Payload size: " .. string.len(jsonPayload) .. " bytes^0")
        print("^2[Protex Report DEBUG] Authorization: Bearer " .. string.sub(protex.apiKey, 1, 20) .. "..." .. "^0")
    end

    PerformHttpRequest("https://nxpdev.dk/api/profile/report", function(statusCode, response, headers)
        if protex.debugMode then
            print("^3[Protex Report DEBUG] HTTP Response received:^0")
            print("^3[Protex Report DEBUG]   Status Code: " .. tostring(statusCode) .. "^0")
            print("^3[Protex Report DEBUG]   Response: " .. tostring(response or "nil") .. "^0")
            print("^3[Protex Report DEBUG]   Response type: " .. type(response) .. "^0")
        end
        if statusCode == 200 then
            print("^2[Protex Report] Successfully reported " .. playerName .. " to NxPDev.dk^0")

            if protex.debugMode and response then
                print("^2[Protex Report] Response: " .. response .. "^0")
            end
        elseif statusCode == 400 then
            print("^1[Protex Report] ERROR: Bad request - Invalid data sent^0")
            if response and response ~= "" then
                print("^1[Protex Report] API Response: " .. response .. "^0")
            else
                print("^1[Protex Report] API returned no error message (empty response)^0")
            end
        elseif statusCode == 401 then
            print("^1[Protex Report] ERROR: Unauthorized - Check your API key^0")
        elseif statusCode == 404 then
            print("^3[Protex Report] WARNING: User not found on NxPDev.dk^0")
        elseif statusCode == 429 then
            print("^3[Protex Report] WARNING: Too many pending reports^0")
            if protex.debugMode and response then
                print("^3[Protex Report] Response: " .. response .. "^0")
            end
        elseif statusCode == 500 then
            print("^1[Protex Report] ERROR: Server error on NxPDev.dk^0")
            if protex.debugMode and response then
                print("^1[Protex Report] Response: " .. response .. "^0")
            end
        else
            print("^1[Protex Report] ERROR: Unknown status code " .. tostring(statusCode) .. "^0")
            if protex.debugMode and response then
                print("^1[Protex Report] Response: " .. response .. "^0")
            end
        end
    end, "POST", json.encode(payload), headers)
end

-- ============================================================================
-- ANTI-CHEAT PROVIDER HANDLERS
-- ============================================================================

local function ProcessBan(providerName, banData)
    local discordId = banData.discordId
    local playerName = banData.playerName or "Unknown Player"
    local reason = banData.reason or "Banned by Anti-Cheat"
    local evidence = banData.evidence or "No evidence provided"

    if not discordId then
        print("^1[Protex Report] ERROR: No Discord ID provided for banned player: " .. playerName .. "^0")
        return
    end

    print("^3[Protex Report] Player Banned (" .. providerName .. "): " .. playerName .. " - " .. reason .. "^0")
    SendReportToAPI(discordId, playerName, reason, evidence)
end

local function HandleFiveGuardBan(BanId, data, additional_info, screenshot_url)
    if protex.debugMode then
        print("^3[Protex Report DEBUG] ===== FiveGuard Ban Event Received =====^0")
        print("^3[Protex Report DEBUG] BanId: " .. tostring(BanId) .. "^0")
        if data then
            for k, v in pairs(data) do
                print("^3[Protex Report DEBUG]   " .. tostring(k) .. " = " .. tostring(v) .. "^0")
            end
        else
            print("^1[Protex Report DEBUG] Data is nil!^0")
        end
        print("^3[Protex Report DEBUG] ==========================================^0")
    end

    local playerName = data.name or "Unknown Player"
    local reason = data.reason or "Banned by FiveGuard"
    local source = data.source or 0

    print("^3[Protex Report] Player Banned: " .. playerName .. ", BanId: " .. tostring(BanId) .. ", Reason: " .. reason .. "^0")

    if source == 0 then
        if protex.debugMode then
            print("^3[Protex Report DEBUG] Trying to find source in alternative fields^0")
        end

        source = data.playerId or data.player_id or data.id or data.src or 0

        if protex.debugMode then
            print("^3[Protex Report DEBUG] Alternative source found: " .. tostring(source) .. "^0")
        end
    end

    local discordId = GetDiscordId(source)

    if not discordId and data then
        if protex.debugMode then
            print("^3[Protex Report DEBUG] Searching for Discord ID in data table^0")
        end

        discordId = data.discord or data.discordId or data.discord_id or data.discordIdentifier

        if discordId then
            discordId = tostring(discordId)

            if string.match(discordId, "discord:") then
                discordId = string.gsub(discordId, "discord:", "")
            end

            if protex.debugMode then
                print("^2[Protex Report DEBUG] Discord ID found in data table: " .. discordId .. "^0")
            end
        end
    end

    if not discordId then
        print("^1[Protex Report] Could not retrieve Discord ID for banned player: " .. playerName .. "^0")

        if protex.debugMode then
            print("^3[Protex Report DEBUG] Trying to find player in server^0")
            local players = GetPlayers()

            for _, playerId in ipairs(players) do
                local name = GetPlayerName(playerId)
                if name == playerName then
                    print("^2[Protex Report DEBUG] Found matching player by name! Source: " .. playerId .. "^0")
                    discordId = GetDiscordId(tonumber(playerId))
                    if discordId then
                        print("^2[Protex Report DEBUG] Successfully retrieved Discord ID from name match!^0")
                        break
                    end
                end
            end
        end

        if not discordId then
            print("^1[Protex Report] FAILED: No Discord ID found. Cannot send report to NxPDev.dk^0")
            return
        end
    end

    local evidence = "FiveGuard Ban Information\n\n"
    evidence = evidence .. "Ban ID: " .. tostring(BanId) .. "\n"
    evidence = evidence .. "Player Name: " .. playerName .. "\n"
    evidence = evidence .. "Reason: " .. reason .. "\n"

    if additional_info and additional_info ~= "" then
        evidence = evidence .. "Additional Info: " .. tostring(additional_info) .. "\n"
    end

    if screenshot_url and screenshot_url ~= "" then
        evidence = evidence .. "Screenshot URL: " .. screenshot_url .. "\n"
    end

    evidence = evidence .. "\nBanned by: FiveGuard Anti-Cheat System"

    ProcessBan("FiveGuard", {
        discordId = discordId,
        playerName = playerName,
        reason = reason,
        evidence = evidence
    })
end

-- ============================================================================
-- PROVIDER REGISTRATION SYSTEM
-- ============================================================================

local function IsResourceLoaded(resourceName)
    return GetResourceState(resourceName) == "started"
end

local function RegisterProviders()
    print("^2[Protex Report] Checking Anti-Cheat Providers...^0")

    for providerKey, provider in pairs(protex.antiCheats) do
        if provider.enabled then
            if provider.requireResource and not IsResourceLoaded(provider.resourceName) then
                print("^3[Protex Report] " .. provider.displayName .. " integration disabled: Resource '" .. provider.resourceName .. "' not found^0")
            else
                if providerKey == "fiveguard" then
                    AddEventHandler(provider.eventName, HandleFiveGuardBan)
                    activeProviders[providerKey] = provider
                    print("^2[Protex Report] " .. provider.displayName .. " integration registered^0")
                -- Add more providers here in the future:
                -- elseif providerKey == "txadmin" then
                --     AddEventHandler(provider.eventName, HandleTxAdminBan)
                --     activeProviders[providerKey] = provider
                --     print("^2[Protex Report] " .. provider.displayName .. " integration registered^0")
                else
                    print("^3[Protex Report] Warning: Unknown provider '" .. providerKey .. "' - no handler available^0")
                end
            end
        else
            if protex.debugMode then
                print("^3[Protex Report DEBUG] " .. provider.displayName .. " integration is disabled in config^0")
            end
        end
    end

    local count = 0
    for _ in pairs(activeProviders) do count = count + 1 end

    if count == 0 then
        print("^3[Protex Report] WARNING: No anti-cheat providers active!^0")
    else
        print("^2[Protex Report] " .. count .. " provider(s) active^0")
    end
end

-- ============================================================================
-- RESOURCE LIFECYCLE
-- ============================================================================

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^2========================================^0")
        print("^2[Protex Report] System Started^0")

        if protex.enableAutoReport then
            print("^2[Protex Report] Auto-reporting: ENABLED^0")
        else
            print("^3[Protex Report] Auto-reporting: DISABLED^0")
        end

        if protex.debugMode then
            print("^3[Protex Report] Debug mode: ENABLED^0")
        end

        RegisterProviders()

        print("^2========================================^0")
    end
end)

AddEventHandler("onServerResourceStart", function(resourceName)
    for providerKey, provider in pairs(protex.antiCheats) do
        if provider.enabled and provider.requireResource and provider.resourceName == resourceName then
            if not activeProviders[providerKey] then
                print("^2[Protex Report] " .. provider.displayName .. " resource detected, registering integration...^0")
                RegisterProviders()
                break
            end
        end
    end
end)