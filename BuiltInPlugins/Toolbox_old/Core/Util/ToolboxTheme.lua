local Plugin = script.Parent.Parent.Parent

local Libs = Plugin.Libs
local Cryo = require(Libs.Cryo)

local createSignal = require(Plugin.Core.Util.createSignal)
local Immutable = require(Plugin.Core.Util.Immutable)
local wrapStrictTable = require(Plugin.Core.Util.wrapStrictTable)

local ToolboxTheme = {}
ToolboxTheme.__index = ToolboxTheme

function ToolboxTheme.createDummyThemeManager()
	-- Fake the studio theme impl
	return ToolboxTheme.new({
		getTheme = {
			GetColor = function()
				return Color3.fromRGB(0, 0, 0)
			end,
		},
	})
end

--[[
	options:
		getTheme : function void -> Theme
		isDarkerTheme : function Theme -> bool
		themeChanged : RbxScriptSignal
]]
function ToolboxTheme.new(options)
	local self = {
		_externalThemeGetter = options.getTheme or nil,
		_isDarkThemeGetter = options.isDarkerTheme or false,
		_externalThemeChangedSignal = options.themeChanged or nil,

		_externalThemeChangedConnection = nil,

		_values = {},

		_signal = createSignal(),
	}

	self.values = wrapStrictTable(self._values, "theme")

	setmetatable(self, ToolboxTheme)

	if self._externalThemeChangedSignal then
		self._externalThemeChangedConnection = self._externalThemeChangedSignal:Connect(function()
			self:_recalculateTheme()
		end)
	end
	self:_recalculateTheme()

	return self
end

function ToolboxTheme:subscribe(...)
	return self._signal:subscribe(...)
end

function ToolboxTheme:destroy()
	if self._externalThemeChangedConnection then
		self._externalThemeChangedConnection:Disconnect()
	end
end

function ToolboxTheme:_update(changedValues)
	self._values = (Cryo.Dictionary.join)(self._values,
		changedValues)
	self.values = wrapStrictTable(self._values, "theme")
	self._signal:fire(self.values)
end

function ToolboxTheme:_getExternalTheme()
	local getter = self._externalThemeGetter

	if type(getter) == "function" then
		return getter()
	end

	return getter
end

function ToolboxTheme:_isDarkerTheme()
	local getter = self._isDarkThemeGetter

	if type(getter) == "function" then
		return getter(self:_getExternalTheme())
	end

	return getter and true or false
end

function ToolboxTheme:_recalculateTheme()
	local externalTheme = self:_getExternalTheme()
	local isDark = self:_isDarkerTheme()

	-- Shorthands for getting a color
	local c = Enum.StudioStyleGuideColor
	local m = Enum.StudioStyleGuideModifier

	local function color(...)
		return externalTheme:GetColor(...)
	end

	self:_update({
		isDarkerTheme = isDark,

		toolbox = {
			backgroundColor = color(c.MainBackground),
		},

		header = {
			backgroundColor = color(c.Titlebar),
			borderColor = color(c.Border),
		},

		dropdownMenu = {
			currentSelection = {
				backgroundColor = color(c.Dropdown),
				backgroundSelectedColor = color(c.CurrentMarker),
				borderColor = color(c.Border),
				borderSelectedColor = color(c.CurrentMarker),
				textColor = color(c.MainText),
				textSelectedColor = color(c.MainText, m.Selected),

				-- TODO CLIDEVSRVS-1690: Icon colour
				iconColor = isDark and Color3.fromRGB(242, 242, 242) or Color3.fromRGB(25, 25, 25),
				iconSelectedColor = Color3.fromRGB(255, 255, 255),
			},

			item = {
				backgroundColor = color(c.Item),

				-- TODO CLIDEVSRVS-1690: Item background colour
				-- backgroundSelectedColor = isDark and Color3.fromRGB(11, 90, 175) or Color3.fromRGB(242, 242, 242),
				backgroundSelectedColor = isDark and color(c.Item, m.Selected) or color(c.Tab),

				selectedBarColor = color(c.CurrentMarker),
				textColor = color(c.MainText),
			},

			dropdownFrame = {
				borderColor = color(c.Border),
			},
		},

		searchBar = {
			backgroundColor = color(c.Dropdown),
			borderColor = color(c.Border),
			borderSelectedColor = color(c.CurrentMarker),
			textColor = color(c.MainText),
			placeholderTextColor = color(c.DimmedText),
			divideLineColor = color(c.Border),

			-- TODO CLIDEVSRVS-1690: Search bar button colours
			searchButton = {
				imageColor = Color3.fromRGB(184, 184, 184),
				imageSelectedColor = Color3.fromRGB(0, 162, 255),
			},

			clearButton = {
				imageColor = Color3.fromRGB(184, 184, 184),
				imageSelectedColor = Color3.fromRGB(0, 162, 255),
			},
		},

		asset = {
			outline = {
				backgroundColor = color(c.MainBackground),
				borderColor = color(c.Border),
			},

			icon = {
				-- TODO CLIDEVSRVS-1690: Don't show border in lighter theme. Put that into theme object, rather than asset icon?
				borderColor = color(c.Item, m.Hover),
			},

			assetName = {
				textColor = color(c.LinkText),
			},

			creatorName = {
				textColor = color(c.SubText),
			},

			voting = {
				textColor = color(c.SubText),

				upVotes = Color3.fromRGB(82, 168, 70),
				downVotes = Color3.fromRGB(206, 100, 91),

				votedUpThumb = Color3.fromRGB(0, 178, 89),
				votedDownThumb = Color3.fromRGB(216, 104, 104),
				voteThumb = Color3.fromRGB(117, 117, 117),
			},
		},

		infoBanner = {
			backgroundColor = color(c.Titlebar),
			textColor = color(c.SubText),
		},

		loadingIndicator = {
			baseColor = isDark and Color3.fromRGB(56, 56, 56) or Color3.fromRGB(184, 184, 184),
			endColor = isDark and Color3.fromRGB(11, 90, 175) or Color3.fromRGB(0, 162, 255),
		},

		footer = {
			backgroundColor = color(c.Titlebar),
			borderColor = color(c.Border),
			labelTextColor = color(c.MainText),

			button = {
				textColor = color(c.MainText),
				textSelectedColor = color(c.MainText, m.Selected),
				backgroundColor = color(c.Dropdown),
				backgroundSelectedColor = color(c.CurrentMarker),
				borderColor = color(c.Border),
				borderSelectedColor = color(c.CurrentMarker),
			},
		},

		tooltip = {
			backgroundColor = color(c.MainBackground),
			borderColor = color(c.Border),
			textColor = color(c.MainText),
		},

		scrollingFrame = {
			-- TODO CLIDEVSRVS-1690: Scrollbar colour.
			-- Using semantic names means background too dark in light theme and bar invisible to see in dark theme.
			scrollbarBackgroundColor = isDark and Color3.fromRGB(41, 41, 41) or Color3.fromRGB(245, 245, 245),
			scrollbarImageColor = isDark and Color3.fromRGB(85, 85, 85) or Color3.fromRGB(245, 245, 245),
		},

		sortComponent = {
			labelTextColor = color(c.MainText),
		},

		suggestionsComponent = {
			labelTextColor = color(c.MainText),
			textColor = color(c.SubText),
			textHoveredColor = color(c.LinkText),
			underlineColor = color(c.LinkText),
		},

		-- TODO: Look at adding this to flag off case
		-- In case improvements flag is on but themes get turned off
		messageBox = {
			backgroundColor = color(c.MainBackground),
			textColor = color(c.MainText),
			informativeTextColor = color(c.SubText),

			button = {
				textColor = color(c.MainText),
				textSelectedColor = color(c.MainText, m.Selected),
				backgroundColor = color(c.MainBackground),
				backgroundSelectedColor = color(c.CurrentMarker),
				borderColor = color(c.Border),
				borderSelectedColor = color(c.CurrentMarker),
			}
		}
	})
end

return ToolboxTheme
