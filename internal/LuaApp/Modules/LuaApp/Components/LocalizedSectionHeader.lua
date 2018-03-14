local Modules = game:GetService("CoreGui").RobloxGui.Modules

local RoactLocalization = require(Modules.LuaApp.RoactLocalization)
local SectionHeader = require(Modules.LuaApp.Components.SectionHeader)

return RoactLocalization.connect({ "text" })(SectionHeader)