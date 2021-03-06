--[[
	Handles analytics for Game Settings, including Diag and EventStream.
	Diag charts can be found under the Developer Tools page on Rcity.

	Tracked diagnostics:
		-Load/Save time
		-Load/Save errors
		-Load/Save success rate

	Tracked events:
		-Widget open
		-Tab switches
		-Widget close

	Allows for local logging to the console by modifying the constant value below.
]]

local FFlagGameSettingsStandardizedOpenEvent = settings():GetFFlag("GameSettingsStandardizedOpenEvent")

local LOG_ANALYTICS_EVENTS = false

local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")

local Plugin = script.Parent.Parent.Parent
local Cryo = require(Plugin.Cryo)

--These functions will be implemented in CLIDEVSRVS-1689
local function getStudioSession()
	local sessionId = nil
	pcall(function()
		sessionId = AnalyticsService:GetSessionId()
	end)
	return sessionId
end

local function getStudioId()
	local clientId = nil
	pcall(function()
		clientId = AnalyticsService:GetClientId()
	end)
	return clientId
end

local Analytics = {}

-- Logging
function Analytics.print(reportType, counterName, num)
	if LOG_ANALYTICS_EVENTS then
		print(string.format("Game Settings Analytics: %s: \"%s\", %f", reportType, counterName, num))
	end
end

function Analytics.printTable(reportType, counterName, tab)
	if LOG_ANALYTICS_EVENTS then
		print(string.format("Game Settings Analytics: %s: \"%s\", %s", reportType, counterName, tab))
	end
end

-- Analytics impl
function Analytics.reportCounter(counterName, num)
	Analytics.print("reportCounter", counterName, num or 1)
	AnalyticsService:ReportCounter(counterName, num or 1)
end

function Analytics.reportStats(counterName, num)
	Analytics.print("reportStats", counterName, num)
	AnalyticsService:ReportStats(counterName, num)
end

function Analytics.sendEventDeferred(eventName, additionalArgs)
	Analytics.printTable("sendEventDeferred", eventName, HttpService:JSONEncode(additionalArgs))
	local args = Cryo.Dictionary.join(additionalArgs, {
		uid = getStudioId(),
		sid = getStudioSession(),
		pid = game.PlaceId,
	})
	AnalyticsService:SendEventDeferred("studio", "gameSettings", eventName, args)
end

-- Analytics events
function Analytics.onLoadAttempt()
	Analytics.reportCounter("GameSettings_LoadAttempt")
end

function Analytics.onLoadSuccess(loadTimeSeconds)
	Analytics.reportCounter("GameSettings_LoadSuccess")
	Analytics.reportStats("GameSettings_LoadTime_Success", loadTimeSeconds)
end

function Analytics.onSaveAttempt()
	Analytics.reportCounter("GameSettings_SaveAttempt")
end

function Analytics.onSaveSuccess(loadTimeSeconds)
	Analytics.reportCounter("GameSettings_SaveSuccess")
	Analytics.reportStats("GameSettings_SaveTime_Success", loadTimeSeconds)
end

function Analytics.onSaveError(errorName)
	Analytics.reportCounter(string.format("GameSettings_%sSaveError", errorName))
end

function Analytics.onLoadError(errorName)
	Analytics.reportCounter(string.format("GameSettings_%sLoadError", errorName))
end

function Analytics.onOpenEvent(userId)
	Analytics.sendEventDeferred("gameSettingsOpen", {})

	if FFlagGameSettingsStandardizedOpenEvent then
		Analytics.sendEventDeferred("toolOpened", {
			method = 1, --studio tab
			uid = userId,
			gameId = game.GameId,
		})
	end
end

function Analytics.onCloseEvent(buttonSelected, timeOpen)
	Analytics.sendEventDeferred("gameSettingsClose", {
		["buttonSelected"] = buttonSelected,
		["timeOpen"] = string.format("%f", timeOpen),
	})
end

function Analytics.onTabChangeEvent(oldTab, newTab)
	if oldTab and newTab then
		Analytics.sendEventDeferred("gameSettingsTabChange", {
			["oldTab"] = oldTab,
			["newTab"] = newTab,
		})
	end
end

return Analytics