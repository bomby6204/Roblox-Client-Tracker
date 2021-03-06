--[[
	Get request for universe active status, as well as creator info.
]]

local RELEVANT_ENTRIES = {
	isActive = true,
	creatorType = true,
	creatorName = true,
}

local HttpService = game:GetService("HttpService")

local Plugin = script.Parent.Parent.Parent.Parent
local Promise = require(Plugin.Promise)
local Http = require(Plugin.Src.Networking.Http)
local Analytics = require(Plugin.Src.Util.Analytics)
local extractRelevantEntries = require(Plugin.Src.Util.extractRelevantEntries)

local UNIVERSES_REQUEST_URL = "v1/universes/%d"
local UNIVERSES_REQUEST_TYPE = "develop"

local ACTIVATE_REQUEST_URL = "v1/universes/%d/activate"
local ACTIVATE_REQUEST_TYPE = "develop"

local DEACTIVATE_REQUEST_URL = "v1/universes/%d/deactivate"
local DEACTIVATE_REQUEST_TYPE = "develop"

local Universes = {}

function Universes.AcceptsValue(key)
	return key == "isActive"
end

function Universes.Get(universeId)
	local requestInfo = {
		Url = Http.BuildRobloxUrl(UNIVERSES_REQUEST_TYPE, UNIVERSES_REQUEST_URL, universeId),
		Method = "GET",
	}

	return Http.Request(requestInfo):andThen(function(jsonResult)
		local result = HttpService:JSONDecode(jsonResult)
		return extractRelevantEntries(result, RELEVANT_ENTRIES)
	end)
	:catch(function()
		warn("Game Settings: Could not load settings from universes.")
		Analytics.onLoadError("Universes")
		return Promise.reject()
	end)
end

function Universes.Set(universeId, isActive)
	if isActive == nil then
		return Promise.resolve()
	end

	local requestInfo = {
		Method = "POST",
	}

	if isActive then
		requestInfo.Url = Http.BuildRobloxUrl(ACTIVATE_REQUEST_TYPE, ACTIVATE_REQUEST_URL, universeId)
	else
		requestInfo.Url = Http.BuildRobloxUrl(DEACTIVATE_REQUEST_TYPE, DEACTIVATE_REQUEST_URL, universeId)
	end

	return Http.Request(requestInfo)
	:catch(function()
		warn("Game Settings: Could not change universe Active status.")
		Analytics.onSaveError("UniverseActive")
		return Promise.reject()
	end)
end

return Universes