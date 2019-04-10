--[[
	NetworkInterface

	Provides an interface between real Networking implementation and Mock one for production and test
]]--

local Plugin = script.Parent.Parent.Parent

local Networking = require(Plugin.Libs.Http.Networking)
local Promise = require(Plugin.Libs.Http.Promise)

local DebugFlags = require(Plugin.Core.Util.DebugFlags)
local PageInfoHelper = require(Plugin.Core.Util.PageInfoHelper)
local Urls = require(Plugin.Core.Util.Urls)
local Constants = require(Plugin.Core.Util.Constants)

local Category = require(Plugin.Core.Types.Category)

local NetworkInterface = {}
NetworkInterface.__index = NetworkInterface

function NetworkInterface:new()
	local networkImp = {
		_networkImp = Networking.new()

	}
	setmetatable(networkImp, NetworkInterface)

	return networkImp
end

local function printUrl(method, httpMethod, url, payload)
	if DebugFlags.shouldDebugUrls() then
		print(("NetworkInterface:%s()"):format(method))
		print(("\t%s %s"):format(httpMethod:upper() or "method=nil", url or "url=nil"))
		if payload then
			print(("\t%s"):format(tostring(payload)))
		end
	end
end

local function sendRequestAndRetry(requestFunc, retryData)
	retryData = retryData or {
		attempts = 0,
		time = 0,
		maxRetries = 5
	}
	retryData.attempts = retryData.attempts + 1

	return requestFunc():catch(function(result)
		if retryData.attempts >= retryData.maxRetries then
			-- Eventually give up
			return Promise.reject(result)
		end

		local timeToWait = 2^(retryData.attempts - 1)
		wait(timeToWait)

		return sendRequestAndRetry(requestFunc, retryData)
	end)
end

function NetworkInterface:getAssets(pageInfo)
	local category = PageInfoHelper.getCategoryForPageInfo(pageInfo) or ""
	local searchTerm = pageInfo.searchTerm or ""
	local pageSize = pageInfo.pageSize or Constants.GET_ITEMS_PAGE_SIZE
	local page = pageInfo.page or 1
	local sortType = PageInfoHelper.getSortTypeForPageInfo(pageInfo) or ""
	local groupId = Category.categoryIsGroupAsset(pageInfo.categoryIndex)
		and PageInfoHelper.getGroupIdForPageInfo(pageInfo)
		or 0
	local creatorId = pageInfo.creator and pageInfo.creator.Id or ""

	local targetUrl = Urls.constructGetAssetsUrl(category, searchTerm, pageSize, page, sortType, groupId, creatorId)

	return sendRequestAndRetry(function()
		printUrl("getAssets", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:postVote(assetId, bool)
	local targetUrl = Urls.constructPostVoteUrl()

	local payload = self._networkImp:jsonEncode({
		assetId = assetId,
		vote = bool,
	})

	return sendRequestAndRetry(function()
		printUrl("postVote", "POST", targetUrl, payload)
		return self._networkImp:httpPostJson(targetUrl, payload)
	end)
end

function NetworkInterface:postUnvote(assetId)
	local targetUrl = Urls.constructPostVoteUrl()

	local payload = self._networkImp:jsonEncode({
		assetId = assetId,
	})

	return sendRequestAndRetry(function()
		printUrl("postUnvote", "POST", targetUrl, payload)
		return self._networkImp:httpPostJson(targetUrl, payload)
	end)
end

function NetworkInterface:postInsertAsset(assetId)
	local targetUrl = Urls.constructInsertAssetUrl(assetId)

	local payload = self._networkImp:jsonEncode({
		assetId = assetId,
	})

	return sendRequestAndRetry(function()
		printUrl("postInsertAsset", "POST", targetUrl, payload)
		return self._networkImp:httpPost(targetUrl, payload)
	end)
end

function NetworkInterface:getManageableGroups()
	local targetUrl = Urls.constructGetManageableGroupsUrl()

	return sendRequestAndRetry(function()
		printUrl("getManageableGroups", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getUsers(searchTerm, numResults)
	local targetUrl = Urls.constructUserSearchUrl(searchTerm, numResults)
	printUrl("getUsers", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:getFavoriteCounts(assetId)
	local targetUrl = Urls.constructFavoriteCountsUrl(assetId)

	printUrl("getFavorites", "GET", targetUrl)
	return self._networkImp:httpGet(targetUrl)
end

function NetworkInterface:getFavorited(userId, assetId)
	local targetUrl = Urls.constructGetFavoritedUrl(userId, assetId)

	printUrl("getFavorited", "GET", targetUrl)
	return self._networkImp:httpGet(targetUrl)
end

function NetworkInterface:postFavorite(userId, assetId)
	local targetUrl = Urls.constructPostFavoriteUrl(userId, assetId)

	local payload = self._networkImp:jsonEncode({
		userId = userId,
		assetId = assetId,
	})

	printUrl("postFavorite", "POST", targetUrl, payload)
	return self._networkImp:httpPostJson(targetUrl, payload)
end

function NetworkInterface:deleteFavorite(userId, assetId)
	local targetUrl = Urls.constructDeleteFavoriteUrl(userId, assetId)

	printUrl("deleteFavorite", "DELETE", targetUrl)
	return self._networkImp:httpDelete(targetUrl)
end

return NetworkInterface
