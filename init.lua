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
    local newMsg = core.format_chat_message(name, message)
    for _, player in ipairs(core.get_connected_players()) do
        local pn = player:get_player_name()
        if not blockedPlayers[pn] or not blockedPlayers[pn][name] then
            core.chat_send_player(pn, newMsg)
        end
    end
    return true
end)

-- Commands
core.register_chatcommand("block", {
    description = "'Blocks' a player | You dont see their messages.",
    param = "<target>",
    func = function(name, param)
        if name == param then
            return false, "You cannot block yourself!"
        end

        blockedPlayers[name] = blockedPlayers[name] or {}
        blockedPlayers[name][param] = true
        return true, param .. " has been blocked."
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