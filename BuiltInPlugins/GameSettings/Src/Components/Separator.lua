--[[
	A simple gray rectangle used to separate elements in the page.
	Can also be customized using its Size and Position.

	Props:
		UDim2 Size = UDim2.new(1, 0, 0, 3)
		UDim2 Position = UDim2.new()
		int LayoutOrder = The order this Separator will sort to when placed in a UIListLayout.
]]

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Roact)
local withTheme = require(Plugin.Src.Consumers.withTheme)

local function Separator(props)
	return withTheme(function(theme)
		return Roact.createElement("Frame", {
			Size = props.Size or UDim2.new(1, 0, 0, 2),
			Position = props.Position,
			BackgroundColor3 = theme.separator,
			BorderSizePixel = 0,
			LayoutOrder = props.LayoutOrder or 1,
		})
	end)
end

return Separator