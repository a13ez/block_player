-- Data will be saved based on "How many players blocked this person"
-- i.e. ["Aimless"] = {["player1"] = true, ["player2"] = true}
local blockedPlayers = {}
local wp = core.get_worldpath()

-- Data will be saved in JSON format (generally easier to access this data)
local function saveBlockedPlayers()
    local json = core.write_json(blockedPlayers, true)
    local file = io.open(wp .. "/block_player.json", "w")
    file:write(json)
    file:close()
end

local function loadBlockedPlayers()
    local file = io.open(wp .. "/block_player.json", "r")
    if file then
        local content = core.parse_json(file:read("*a"))
        blockedPlayers = (content and content ~= nil and type(content) == "table") or {}
    end
end

loadBlockedPlayers()

-- Handling how messages are sent
core.register_on_chat_message(function(name, message)
    if not blockedPlayers[name] or #blockedPlayers[name] <= 0 then
        return
    end

    local newMsg = core.format_chat_message(name, message)
    for _, player in ipairs(core.get_connected_players()) do
        local pn = player:get_player_name()
        if not blockedPlayers[name][pn] then
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

        blockedPlayers[param] = blockedPlayers[param] or {}
        blockedPlayers[param][name] = true
        saveBlockedPlayers()
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

        blockedPlayers[param] = blockedPlayers[param] or {}
        if blockedPlayers[param][name] then
            blockedPlayers[param][name] = nil
            saveBlockedPlayers()
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
        if blockedPlayers[name] and blockedPlayers[name][sendto] then
            return false, "Failed to send PM to " .. sendto
        end
        return old_msg_func(name, param)
    end,
})