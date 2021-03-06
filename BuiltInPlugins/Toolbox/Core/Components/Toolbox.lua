--[[
	The toolbox itself

	Props (many of these come from the store):
		number initialWidth = 0
		number initialSelectedBackgroundIndex = 1
		number initialSelectedCategoryIndex = 1
		string initialSearchTerm = ""
		number initialSelectedSortIndex = 1

		Backgrounds backgrounds
		Categories categories
		Suggestions suggestions
		Sorts sorts

		callback loadManageableGroups()
		callback updatePageInfo()
]]

local FFlagStudioMarketplaceTabsEnabled = settings():GetFFlag("StudioMarketplaceTabsEnabled")

local Plugin = script.Parent.Parent.Parent

local Libs = Plugin.Libs
local Roact = require(Libs.Roact)
local RoactRodux = require(Libs.RoactRodux)

local Constants = require(Plugin.Core.Util.Constants)
local Images = require(Plugin.Core.Util.Images)
local ContextGetter = require(Plugin.Core.Util.ContextGetter)
local ContextHelper = require(Plugin.Core.Util.ContextHelper)

local Sort = require(Plugin.Core.Types.Sort)
local Category = require(Plugin.Core.Types.Category)

local getNetwork = ContextGetter.getNetwork
local getSettings = ContextGetter.getSettings
local withTheme = ContextHelper.withTheme
local withLocalization = ContextHelper.withLocalization

local TabSet = require(Plugin.Core.Components.TabSet)
local Footer = require(Plugin.Core.Components.Footer.Footer)
local Header = require(Plugin.Core.Components.Header)
local MainView = require(Plugin.Core.Components.MainView.MainView)
local SoundPreviewComponent = require(Plugin.Core.Components.SoundPreviewComponent)

local GetManageableGroupsRequest = require(Plugin.Core.Networking.Requests.GetManageableGroupsRequest)
local UpdatePageInfoAndSendRequest = require(Plugin.Core.Networking.Requests.UpdatePageInfoAndSendRequest)
local ChangeMarketplaceTab = require(Plugin.Core.Networking.Requests.ChangeMarketplaceTab)

local Analytics = require(Plugin.Core.Util.Analytics.Analytics)

local Toolbox = Roact.PureComponent:extend("Toolbox")

function Toolbox:handleInitialSettings()
	local networkInterface = getNetwork(self)
	local settings = getSettings(self)
	local initialSettings = settings:loadInitialSettings()

	-- Load the initial values and make sure they're safe
	local initialSelectedCategoryIndex = initialSettings.categoryIndex or 1
	if initialSelectedCategoryIndex < 1 or initialSelectedCategoryIndex > #self.props.categories then
		initialSelectedCategoryIndex = 1
	end

	-- We don't want initial search based on last search text for toolbox.
	-- But let's keep the option to re-add this in the future
	local initialSearchTerm = ""

	local initialSelectedSortIndex = initialSettings.sortIndex or 1
	if initialSelectedSortIndex < 1 or initialSelectedSortIndex > #self.props.sorts then
		initialSelectedSortIndex = Sort.getDefaultSortForCategory(initialSelectedCategoryIndex)
	end

	local initialSelectedBackgroundIndex = initialSettings.backgroundIndex or 1

	-- Set the initial page info for the toolbox
	-- This will trigger a web request to load the first round of assets
	self.props.updatePageInfo(networkInterface, settings, {
		categoryIndex = initialSelectedCategoryIndex,
		searchTerm = initialSearchTerm,
		sortIndex = initialSelectedSortIndex,
		groupIndex = 0,
		page = 1,
		pageSize = Constants.GET_ITEMS_PAGE_SIZE,
		selectedBackgroundIndex = initialSelectedBackgroundIndex,
	})
end

function Toolbox:init(props)
	self.state = {
		toolboxWidth = math.max(props.initialWidth or 0, Constants.TOOLBOX_MIN_WIDTH),
		showSearchOptions = false,
	}

	self.toolboxRef = Roact.createRef()

	-- If flag is on, use function that gets ref, else use old with rbx param
	self.onAbsoluteSizeChange = function()
		local toolboxWidth = math.max(self.toolboxRef.current.AbsoluteSize.x,
			Constants.TOOLBOX_MIN_WIDTH)
		if self.state.toolboxWidth ~= toolboxWidth then
			self:setState({
				toolboxWidth = toolboxWidth,
			})
		end
	end

	self:handleInitialSettings()

	self.toggleSearchOptions = function()
		local showSearchOptions = self.state.showSearchOptions

		if not showSearchOptions then
			Analytics.onSearchOptionsOpened()
		end

		self:setState({
			showSearchOptions = not showSearchOptions
		})
	end

	local networkInterface = getNetwork(self)
	local settings = getSettings(self)
	self.changeMarketplaceTab = function(tabName)
		self.props.changeMarketplaceTab(networkInterface, tabName, settings)
		self.props.updatePageInfo(networkInterface, settings, {
			categoryIndex = 1,
			searchTerm = "",
			sortIndex = 1,
			groupIndex = 0,
			page = 1,
			pageSize = Constants.GET_ITEMS_PAGE_SIZE,
			selectedBackgroundIndex = 0,
		})
	end
end

function Toolbox:didMount()
	if self.toolboxRef.current then
		self.toolboxRef.current:GetPropertyChangedSignal("AbsoluteSize"):connect(self.onAbsoluteSizeChange)
	end

	self:handleInitialSettings()

	if not FFlagStudioMarketplaceTabsEnabled then
		self.props.loadManageableGroups(getNetwork(self))
	end
end

function Toolbox:render()
	return withTheme(function(theme)
		return withLocalization(function(_, localizedContent)
			local props = self.props
			local state = self.state

			local toolboxWidth = state.toolboxWidth
			local showSearchOptions = state.showSearchOptions

			local backgrounds = props.backgrounds
			local suggestions = props.suggestions or {}
			local currentTab = props.currentTab

			local toolboxTheme = theme.toolbox

			local onAbsoluteSizeChange = self.onAbsoluteSizeChange

			local tabHeight = FFlagStudioMarketplaceTabsEnabled and Constants.TAB_WIDGET_HEIGHT or 0
			local headerOffset = FFlagStudioMarketplaceTabsEnabled and tabHeight or 0

			return Roact.createElement("Frame", {
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),

				BorderSizePixel = 0,
				BackgroundColor3 = toolboxTheme.backgroundColor,

				[Roact.Ref] = self.toolboxRef,
				[Roact.Change.AbsoluteSize] = onAbsoluteSizeChange,
			}, {
				Tabs = FFlagStudioMarketplaceTabsEnabled and Roact.createElement(TabSet, {
					Size = UDim2.new(1, 0, 0, Constants.TAB_WIDGET_HEIGHT),
					Tabs = {
						{Key = Category.MARKETPLACE_KEY, Text = localizedContent.Tabs.Marketplace, Image = Images.MARKETPLACE_TAB},
						{Key = Category.INVENTORY_KEY, Text = localizedContent.Tabs.Inventory, Image = Images.INVENTORY_TAB},
						{Key = Category.RECENT_KEY, Text = localizedContent.Tabs.Recent, Image = Images.RECENT_TAB},
					},
					CurrentTab = currentTab,
					onTabSelected = self.changeMarketplaceTab,
				}),

				Header = Roact.createElement(Header, {
					Position = UDim2.new(0, 0, 0, headerOffset),
					maxWidth = toolboxWidth,
					onSearchOptionsToggled = self.toggleSearchOptions,
				}),

				MainView = Roact.createElement(MainView, {
					Position = UDim2.new(0, 0, 0, headerOffset + Constants.HEADER_HEIGHT + 1),
					Size = UDim2.new(1, 0, 1, -(Constants.HEADER_HEIGHT + Constants.FOOTER_HEIGHT + headerOffset + 2)),

					maxWidth = toolboxWidth,
					suggestions = suggestions,
					showSearchOptions = showSearchOptions,
					onSearchOptionsToggled = self.toggleSearchOptions,
				}),

				Footer = Roact.createElement(Footer, {
					backgrounds = backgrounds,
				}),

				AudioPreview = Roact.createElement(SoundPreviewComponent)
			})
		end)
	end)
end

local function mapStateToProps(state, props)
	state = state or {}
	local pageInfo = state.pageInfo or {}

	return {
		categories = pageInfo.categories or {},
		currentTab = pageInfo.currentTab or Category.MARKETPLACE_KEY,
		sorts = pageInfo.sorts or {}
	}
end

local function mapDispatchToProps(dispatch)
	return {
		-- FIXME (psewell) Remove when removing FFlagStudioMarketplaceTabsEnabled
		loadManageableGroups = function(networkInterface)
			dispatch(GetManageableGroupsRequest(networkInterface))
		end,

		updatePageInfo = function(networkInterface, settings, newPageInfo)
			dispatch(UpdatePageInfoAndSendRequest(networkInterface, settings, newPageInfo))
		end,

		changeMarketplaceTab = function(networkInterface, tabName, settings)
			dispatch(ChangeMarketplaceTab(networkInterface, tabName, settings))
		end,
	}
end

return RoactRodux.UNSTABLE_connect2(mapStateToProps, mapDispatchToProps)(Toolbox)
