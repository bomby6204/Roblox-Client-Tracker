local AnalyticsService = game:GetService("AnalyticsService")
local SocialService = game:GetService("SocialService")
local CoreGui = game:GetService("CoreGui")
local CorePackages = game:GetService("CorePackages")
local Players = game:GetService("Players")

local RobloxGui = CoreGui:WaitForChild("RobloxGui")

local Modules = RobloxGui.Modules
local SettingsHubDirectory = Modules.Settings
local ShareGameDirectory = SettingsHubDirectory.Pages.ShareGame

local Diag = require(CorePackages.AppTempCommon.AnalyticsReporters.Diag)
local EventStream = require(CorePackages.AppTempCommon.Temp.EventStream)
local InviteToGameAnalytics = require(ShareGameDirectory.Analytics.InviteToGameAnalytics)

local FFlagLuaInviteNewAnalytics = settings():GetFFlag("LuaInviteNewAnalytics")

local inviteToGameAnalytics
if FFlagLuaInviteNewAnalytics then
	inviteToGameAnalytics = InviteToGameAnalytics.new()
		:withEventStream(EventStream.new())
		:withDiag(Diag.new(AnalyticsService))
		:withButtonName(InviteToGameAnalytics.ButtonName.ModalPrompt)
end

local InviteToGamePrompt = require(ShareGameDirectory.InviteToGamePrompt)
local modalPrompt = InviteToGamePrompt.new(CoreGui)
	:withSocialServiceAndLocalPlayer(SocialService, Players.LocalPlayer)
	:withAnalytics(inviteToGameAnalytics)

SocialService.PromptInviteRequested:Connect(function(player)
	if player ~= Players.LocalPlayer
		or not SocialService:CanSendGameInviteAsync(player) then
		return
	end

	modalPrompt:show()
end)