local CoreGui = game:GetService("CoreGui")

local Modules = CoreGui.RobloxGui.Modules
local Common = Modules.Common
local LuaChat = Modules.LuaChat

local ActionType = require(LuaChat.ActionType)
local Action = require(Common.Action)

return Action(ActionType.ReceivedConversation, function(convo)
	return {
		conversation = convo,
	}
end)