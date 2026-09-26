local blockedPlayers = {}
local wp = core.get_worldpath()

-- Data will be saved in JSON format (generally easier to access this data)
local function saveBlockedPlayers()
    local json = core.write_json(blockedPlayers, true)
    local file = io.open(wp .. "/blocked_players.json", "w")
    file:write(json)
    file:close()
end

local function loadBlockedPlayers()
    local file = io.open(wp .. "/blocked_players.json", "r")
    if file then
        local content = file:read("*a")
        blockedPlayers = core.parse_json(content)
    end
end

loadBlockedPlayers()

-- Handling how messages are sent
core.register_on_chat_message(function(name, message)
    local cache = {} -- Players to send message to
    for _, player in ipairs(core.get_connected_players()) do
        local pn = player:get_player_name()
        cache[(#cache or 0) + 1] = pn

        if blockedPlayers[pn] and blockedPlayers[pn][name] then
            cache[#cache] = nil -- Player is blocked. Remove them from the list
        end
    end

    if #cache == #core.get_connected_players() then
        return
    end

    for i=1, #cache do
        local newMsg = core.format_chat_message(name, message)
        core.chat_send_player(cache[i], newMsg)
    end

    return true
end)

-- Commands
core.register_chatcommand("block", {
    description = "'Blocks' a player | You dont see their messages.",
    param = "<target>",
    func = function(name, param)
        blockedPlayers[name] = blockedPlayers[name] or {}
        blockedPlayers[name][param] = true
        return true, "[Server]: " .. param .. " has been blocked."
    end
})

core.register_chatcommand("unblock", {
    description = "'Unblocks' a player | You will be able to see their messages again.",
    param = "<target>",
    func = function(name, param)
        if name == param then
            return false, "You cannot block yourself!"
        end

        blockedPlayers[name] = blockedPlayers[name] or {}
        if blockedPlayers[name][param] then
            blockedPlayers[name][param] = nil
            return true, param .. " has been unblocked."
        else
            return false, "Invalid target: '" .. param .. "'."
        end
    end
})

-- '/msg' command override
local old_msg_func = core.registered_chatcommands["msg"].func
core.override_chatcommand("msg", {
    func = function(name, param)
        local sendto, message = param:match("^(%S+)%s(.+)$")
        if blockedPlayers[sendto] and blockedPlayers[sendto][name] then
            return false, "Failed to send PM to " .. sendto
        end
        return old_msg_func(name, param)
    end,
})

core.register_on_shutdown(function()
    saveBlockedPlayers()
end)