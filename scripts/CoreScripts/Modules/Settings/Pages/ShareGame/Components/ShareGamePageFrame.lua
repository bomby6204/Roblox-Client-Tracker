local CoreGui = game:GetService("CoreGui")
local CorePackages = game:GetService("CorePackages")
local HttpRbxApiService = game:GetService("HttpRbxApiService")
local Players = game:GetService("Players")

local AppTempCommon = CorePackages.AppTempCommon
local Modules = CoreGui.RobloxGui.Modules

local FFlagLuaChatRemoveOldRoactRoduxConnect = settings():GetFFlag("LuaChatRemoveOldRoactRoduxConnect")
local FFlagLuaInviteModalEnabled = settings():GetFFlag("LuaInviteModalEnabledV373")

local Roact = require(CorePackages.Roact)
local RoactRodux = require(CorePackages.RoactRodux)
local httpRequest
local ApiFetchUsersFriends
local RetrievalStatus
if not FFlagLuaInviteModalEnabled then
	httpRequest = require(AppTempCommon.Temp.httpRequest)
	ApiFetchUsersFriends = require(AppTempCommon.LuaApp.Thunks.ApiFetchUsersFriends)
	RetrievalStatus = require(CorePackages.AppTempCommon.LuaApp.Enum.RetrievalStatus)
end

local ShareGame = Modules.Settings.Pages.ShareGame

local Header = require(ShareGame.Components.Header)
local ConversationList = require(ShareGame.Components.ConversationList)
local Constants = require(ShareGame.Constants)

local FetchUserFriends
local ClosePage
local BackButton
if FFlagLuaInviteModalEnabled then
	BackButton = require(ShareGame.Components.BackButton)
else
	FetchUserFriends = require(ShareGame.Thunks.FetchUserFriends)
	ClosePage = require(ShareGame.Actions.ClosePage)
end

local USER_LIST_PADDING = 10

local ShareGamePageFrame = Roact.PureComponent:extend("ShareGamePageFrame")

local ToasterComponent = require(ShareGame.Components.ErrorToaster)

if not FFlagLuaInviteModalEnabled then
	function ShareGamePageFrame:init()
		self.props.reFetch()
	end
end

function ShareGamePageFrame:render()
	local analytics = self.props.analytics
	local deviceLayout = self.props.deviceLayout
	local zIndex = self.props.zIndex
	local closePage = self.props.closePage
	local searchAreaActive = self.props.searchAreaActive
	local searchText = self.props.searchText

	local layoutSpecific = Constants.LayoutSpecific[deviceLayout]
	local headerHeight = layoutSpecific.HEADER_HEIGHT
	local isDesktop
	local iconType
	local toggleSearchIcon
	if FFlagLuaInviteModalEnabled then
		isDesktop = deviceLayout == Constants.DeviceLayout.DESKTOP
		iconType = not isDesktop and BackButton.IconType.Arrow or BackButton.IconType.None

		toggleSearchIcon = not isDesktop
	end

	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = zIndex,
	}, {
		toasterPortal = Roact.createElement(Roact.Portal, {
			target = CoreGui,
		}, {
			Toaster = Roact.createElement(ToasterComponent),
		}),

		Header = Roact.createElement(Header, {
			deviceLayout = deviceLayout,
			size = UDim2.new(1, 0, 0, headerHeight),
			position = UDim2.new(0, 0, 0, -headerHeight),
			layoutOrder = 0,
			zIndex = zIndex,
			closePage = closePage,
			searchAreaActive = searchAreaActive,
			toggleSearchIcon = toggleSearchIcon,
			iconType = iconType,
		}),
		ConversationList = Roact.createElement(ConversationList, {
			analytics = analytics,
			size = UDim2.new(1, 0, 1, layoutSpecific.EXTEND_BOTTOM_SIZE - USER_LIST_PADDING),
			topPadding = USER_LIST_PADDING,
			layoutOrder = 1,
			zIndex = zIndex,
			searchText = searchText,
		}),
	})
end

if not FFlagLuaInviteModalEnabled then
	-- This logic is being moved to ShareGameContainer.lua
	-- so it can be shared with this file and ModalShareGamePageFrame.lua
	if FFlagLuaChatRemoveOldRoactRoduxConnect then
		ShareGamePageFrame = RoactRodux.UNSTABLE_connect2(
			function(state, props)
				return {
					deviceLayout = state.DeviceInfo.DeviceLayout,
					searchAreaActive = state.ConversationsSearch.SearchAreaActive,
					searchText = state.ConversationsSearch.SearchText,
				}
			end,
			function(dispatch)
				return {
					closePage = function()
						dispatch(ClosePage(Constants.PageRoute.SHARE_GAME))
					end,

					reFetch = function()
						local userId = tostring(Players.LocalPlayer.UserId)
						local requestImpl = httpRequest(HttpRbxApiService)

						dispatch(FetchUserFriends(requestImpl, userId))
					end
				}
			end
		)(ShareGamePageFrame)
	else
		ShareGamePageFrame = RoactRodux.connect(function(store)
			local state = store:getState()
			return {
				deviceLayout = state.DeviceInfo.DeviceLayout,

				searchAreaActive = state.ConversationsSearch.SearchAreaActive,
				searchText = state.ConversationsSearch.SearchText,

				closePage = function()
					store:dispatch(ClosePage(Constants.PageRoute.SHARE_GAME))
				end,
				reFetch = function()
					local userId = tostring(Players.LocalPlayer.UserId)
					local friendsRetrievalStatus = state.Friends.retrievalStatus[userId]
					if friendsRetrievalStatus ~= RetrievalStatus.Fetching then
						local networkImpl = httpRequest(HttpRbxApiService)
						store:dispatch(ApiFetchUsersFriends(networkImpl, userId, Constants.ThumbnailRequest.InviteToGame))
					end
				end
			}
		end)(ShareGamePageFrame)
	end
end

return ShareGamePageFrame