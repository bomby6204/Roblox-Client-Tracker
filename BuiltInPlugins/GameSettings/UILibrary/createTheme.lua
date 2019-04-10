--[[
	Transforms values from an app theme into a theme usable by the UILibrary.

	Parameters:
		table style:
			Specifies default style values which will be used to construct the theme.
			These include the basic palette colors (backgroundColor, textColor, etc),
			as well as other top-level fonts and sizes. Refer to defaultStyle for
			a list of style values that can be overridden.

		table overrides (optional):
			After the theme is created, overrides can be set for specific elements.

			For example, an overrides table of:
			{
				checkBox.backgroundColor = Color3.new(1, 1, 1),
			}

			Would change the background color of only the Checkbox component.
]]

local Style = require(script.Parent.Style)
local replaceDefaults = require(script.Parent.deepJoin)

return function(style, overrides)
	style = style or {}
	overrides = overrides or {}

	style = replaceDefaults(Style.Defaults, style)
	assert(Style.isValid(style), "Provided style table could not be validated.")

	-- Theme entries for UILibrary components are defined below
	local checkBox = {
		font = style.font,

		backgroundImage = "rbxasset://textures/GameSettings/UncheckedBox.png",
		selectedImage = "rbxasset://textures/GameSettings/CheckedBoxLight.png",

		backgroundColor = style.backgroundColor,
		titleColor = style.textColor,
	}

	local roundFrame = {
		backgroundImage = "rbxasset://textures/StudioToolbox/RoundedBackground.png",
		borderImage = "rbxasset://textures/StudioToolbox/RoundedBorder.png",
	}

	local dropShadow = {
		image = "rbxasset://textures/StudioUIEditor/resizeHandleDropShadow.png",
	}

	local tooltip = {
		font = style.font,

		backgroundColor = style.itemColor,
		borderColor = style.borderColor,
		textColor = style.textColor,
		shadowColor = style.shadowColor,
		shadowTransparency = style.shadowTransparency,
	}

	local keyframe = {
		backgroundColor = style.itemColor,
		borderColor = style.borderColor,

		selected = {
			backgroundColor = style.selectionColor,
			borderColor = style.selectionBorderColor,
		},
	}

    local timelineTick = {
        font = style.font,

        lineColor = style.separationLineColor,
        textColor = style.dimmerTextColor,
    }

    local timeline = {
    	barColor = style.borderColor,
	}

	return replaceDefaults({
		 checkBox = checkBox,
		 roundFrame = roundFrame,
		 dropShadow = dropShadow,
		 tooltip = tooltip,
		 keyframe = keyframe,
         timelineTick = timelineTick,
         timeline = timeline,
	}, overrides)
end