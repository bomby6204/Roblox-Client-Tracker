--[[
	// FileName: AvatarContextMenu.lua
	// Written by: TheGamer101
	// Description: A context menu to allow users to click on avatars and then interact with that user.
]]

-- OPTIONS
local DEBUG_MODE = game:GetService("RunService"):IsStudio() -- use this to run as a guest/use in games that don't have AvatarContextMenu. FOR TESTING ONLY!
local isAvatarContextMenuEnabled = false

local FFlagCoreScriptACMThemeCustomization = settings():GetFFlag("CoreScriptACMThemeCustomization")
local FFlagUserFixClickToMoveWithACM = settings():GetFFlag("UserFixClickToMoveWithACM")
local FFlagUseRoactPlayerList = settings():GetFFlag("UseRoactPlayerList")

-- CONSTANTS
local MAX_CONTEXT_MENU_DISTANCE = 100

local OPEN_MENU_TIME = 0.2
local OPEN_MENU_TWEEN = TweenInfo.new(OPEN_MENU_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local CLOSE_MENU_TIME = 0.2
local CLOSE_MENU_TWEEN = TweenInfo.new(CLOSE_MENU_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local LEAVE_MENU_ACTION_NAME = "EscapeAvatarContextMenu"

local MAX_MOVEMENT_THRESHOLD = 20

-- SERVICES
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local PlayersService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGuiService = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local AnalyticsService = game:GetService("AnalyticsService")

local hasTrackedAvatarContextMenu = false
function enableAvatarContextMenu(enabled)
	isAvatarContextMenuEnabled = not not enabled
	if isAvatarContextMenuEnabled and not hasTrackedAvatarContextMenu then
		hasTrackedAvatarContextMenu = true
		AnalyticsService:TrackEvent("Game", "AvatarContextMenuEnabled", "placeId: " .. tostring(game.PlaceId))
	end
end

StarterGui:RegisterSetCore("SetAvatarContextMenuEnabled", enableAvatarContextMenu)
if FFlagUserFixClickToMoveWithACM then
	StarterGui:RegisterSetCore("AvatarContextMenuEnabled", enableAvatarContextMenu)

	StarterGui:RegisterGetCore("AvatarContextMenuEnabled", function()
		return isAvatarContextMenuEnabled
	end)
end

--- MODULES
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local CoreGuiModules = RobloxGui:WaitForChild("Modules")
local AvatarMenuModules = CoreGuiModules:WaitForChild("AvatarContextMenu")

local ContextMenuGui = require(AvatarMenuModules:WaitForChild("ContextMenuGui"))
local ContextMenuItemsModule = require(AvatarMenuModules:WaitForChild("ContextMenuItems"))
local ContextMenuUtil = require(AvatarMenuModules:WaitForChild("ContextMenuUtil"))
local SelectedCharacterIndicator = require(AvatarMenuModules:WaitForChild("SelectedCharacterIndicator"))
local ThemeHandler = require(AvatarMenuModules.ThemeHandler)

local BlockingUtility
if FFlagUseRoactPlayerList then
	BlockingUtility = require(CoreGuiModules.BlockingUtility)
else
	local PlayerDropDownModule = require(CoreGuiModules:WaitForChild("PlayerDropDown"))
	BlockingUtility = PlayerDropDownModule:CreateBlockingUtility()
end

--- VARIABLES

local LocalPlayer = PlayersService.LocalPlayer
while not LocalPlayer do
	PlayersService.PlayerAdded:wait()
	LocalPlayer = PlayersService.LocalPlayer
end

-- no avatar context menu for guests
if LocalPlayer.UserId <= 0 and not DEBUG_MODE then return end

local ContextMenuItems = nil
local ContextMenuFrame = nil

local ContextMenuOpening = false

local ContextMenuOpen = false
local SelectedPlayer = nil

local lastInputObject = nil
local initialScreenPoint = nil

local hasTouchSwipeInput = nil

local contextMenuPlayerChangedConn = nil

if FFlagCoreScriptACMThemeCustomization then
	ContextMenuFrame = ContextMenuGui:CreateMenuFrame(ThemeHandler:GetTheme())
else
	ContextMenuFrame = ContextMenuGui:CreateMenuFrame()
end
ContextMenuItems = ContextMenuItemsModule.new(ContextMenuFrame.Content.ContextActionList)

function SetSelectedPlayer(player, dontTween)
	if SelectedPlayer == player then return end
	SelectedPlayer = player
	if FFlagCoreScriptACMThemeCustomization then
		SelectedCharacterIndicator:ChangeSelectedPlayer(SelectedPlayer, ThemeHandler:GetTheme())
	else
		SelectedCharacterIndicator:ChangeSelectedPlayer(SelectedPlayer)
	end
	ContextMenuItems:BuildContextMenuItems(SelectedPlayer)
	ContextMenuGui:SwitchToPlayerEntry(SelectedPlayer, dontTween)
end

function OpenMenu(theme)
	ContextMenuOpening = true

	ContextMenuFrame.Visible = true
	ContextMenuFrame.Content.ContextActionList.CanvasPosition = Vector2.new(0,0)
	if FFlagCoreScriptACMThemeCustomization then
		ContextMenuFrame.Position = theme.OffScreenPosition
	else
		ContextMenuFrame.Position = UDim2.new(0.5, 0, 1, ContextMenuFrame.AbsoluteSize.Y)
	end

	contextMenuPlayerChangedConn = ContextMenuGui.SelectedPlayerChanged:connect(function()
		SetSelectedPlayer(ContextMenuGui:GetSelectedPlayer())
	end)

	local positionTween
	if FFlagCoreScriptACMThemeCustomization then
		ContextMenuFrame.Position = theme.OffScreenPosition
		positionTween = TweenService:Create(ContextMenuFrame, OPEN_MENU_TWEEN, {Position = theme.OnScreenPosition})
	else
		positionTween = TweenService:Create(ContextMenuFrame, OPEN_MENU_TWEEN, {Position = UDim2.new(0.5, 0, 1 - ContextMenuGui:GetBottomScreenPaddingConstant(), 0)})
	end
	positionTween:Play()
	positionTween.Completed:wait()

	ContextMenuOpening = false
end

function BindMenuActions()
	-- Close Menu actions
	local closeMenuFunc = function(actionName, inputState, input)
		if inputState ~= Enum.UserInputState.Begin then
			return
		end
		CloseContextMenu()
	end
	ContextActionService:BindCoreAction(LEAVE_MENU_ACTION_NAME, closeMenuFunc, false, Enum.KeyCode.Escape,
		Enum.KeyCode.ButtonB)

    local menuOpenedCon = nil
    menuOpenedCon = GuiService.MenuOpened:connect(function()
        menuOpenedCon:disconnect()
        closeMenuFunc(nil, Enum.UserInputState.Begin, nil)
    end)
end

function BuildPlayerCarousel(selectedPlayer, worldPoint)
	local playersByProximity = {}
	local players = PlayersService:GetPlayers()
	for i = 1, #players do
		if players[i].UserId > 0 or DEBUG_MODE then
			if players[i] ~= LocalPlayer then
				local playerPosition = ContextMenuUtil:GetPlayerPosition(players[i])
				if playerPosition then
					local distanceFromClicked = (worldPoint - playerPosition).magnitude
					table.insert(playersByProximity, {players[i], distanceFromClicked})
				end
			end
		end
	end

	local function closestPlayerComp(playerA, playerB)
		return playerA[2] > playerB[2]
	end
	table.sort(playersByProximity, closestPlayerComp)

	if FFlagCoreScriptACMThemeCustomization then
		ContextMenuGui:BuildPlayerCarousel(playersByProximity, ThemeHandler:GetTheme())
	else
		ContextMenuGui:BuildPlayerCarousel(playersByProximity)
	end
end

PlayersService.PlayerRemoving:connect(function(player)
	if ContextMenuOpen and player ~= SelectedPlayer then
		ContextMenuGui:RemovePlayerEntry(player)
	end
end)

function OpenContextMenu(player, worldPoint)
    if ContextMenuOpening or ContextMenuOpen or not isAvatarContextMenuEnabled then
        return
	end

	ContextMenuOpen = true
	BuildPlayerCarousel(player, worldPoint)
	ContextMenuUtil:DisablePlayerMovement()
	BindMenuActions()
	SetSelectedPlayer(player, true)

	if FFlagCoreScriptACMThemeCustomization then
		ContextMenuGui:UpdateGuiTheme(ThemeHandler:GetTheme())
		OpenMenu(ThemeHandler:GetTheme())
	else
		OpenMenu()
	end
end

function CloseContextMenu()
	GuiService.SelectedCoreObject = nil

	ContextActionService:UnbindCoreAction(LEAVE_MENU_ACTION_NAME)

	ContextMenuUtil:EnablePlayerMovement()
	if contextMenuPlayerChangedConn then
		contextMenuPlayerChangedConn:disconnect()
	end

	local positionTween = TweenService:Create(ContextMenuFrame, CLOSE_MENU_TWEEN, {Position = UDim2.new(0.5, 0, 1, ContextMenuFrame.AbsoluteSize.Y)})
	positionTween:Play()
	positionTween.Completed:wait()

	ContextMenuFrame.Visible = false
	SetSelectedPlayer(nil)
	ContextMenuOpen = false
end
ContextMenuGui:SetCloseMenuFunc(CloseContextMenu)
ContextMenuItems:SetCloseMenuFunc(CloseContextMenu)

local function isPointInside(point, topLeft, bottomRight)
	return (point.X >= topLeft.X and
			point.X <= bottomRight.X and
			point.Y >= topLeft.Y and
			point.Y <= bottomRight.Y)
end

function PointInSwipeArea(screenPoint)
	local topLeft = ContextMenuFrame.AbsolutePosition

	local nameTag = ContextMenuFrame.Content:FindFirstChild("NameTag")
	local bottomRight = Vector2.new(topLeft.x + ContextMenuFrame.AbsoluteSize.x, nameTag.AbsolutePosition.y + nameTag.AbsoluteSize.y)

	return isPointInside(screenPoint, topLeft, bottomRight)
end

function LocalPlayerHasToolEquipped()
	if not LocalPlayer.Character then return false end

	for _, child in ipairs(LocalPlayer.Character:GetChildren()) do
		if child:IsA("BackpackItem") then
			return true
		end
	end

	return false
end

function shouldIgnoreLocalCharacter()
	if LocalPlayer.Character then
		local head = LocalPlayer.Character:FindFirstChild("Head")
		if head then
			-- This will be true if the player is in first person.
			return head.LocalTransparencyModifier >= 0.95
		end
	end
end

function clickedOnPoint(screenPoint)
	local camera = workspace.CurrentCamera
	if not camera then return end

	if LocalPlayerHasToolEquipped() then return end

	local ray = camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
	ray = Ray.new(ray.Origin, ray.Direction * MAX_CONTEXT_MENU_DISTANCE)
	local hitPart, hitPoint
	if shouldIgnoreLocalCharacter() then
		hitPart, hitPoint = workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
	else
		hitPart, hitPoint = workspace:FindPartOnRay(ray, nil, false, true)
	end
	local player = ContextMenuUtil:FindPlayerFromPart(hitPart)

	if player and ((DEBUG_MODE and player ~= LocalPlayer) or (player ~= LocalPlayer and player.UserId > 0)) then
		if ContextMenuOpen then
			SetSelectedPlayer(player)
		else
			OpenContextMenu(player, hitPoint)
		end
	elseif not player and ContextMenuOpen then
		CloseContextMenu()
	end
end

function OnUserInput(screenPoint, inputObject)
	if inputObject.UserInputState == Enum.UserInputState.Begin and lastInputObject == nil then
		lastInputObject = inputObject
		initialScreenPoint = screenPoint
	elseif lastInputObject == inputObject and inputObject.UserInputState == Enum.UserInputState.Change then
		if (screenPoint - initialScreenPoint).magnitude > 5 then
			lastInputObject = nil
			initialScreenPoint = nil
		end
	elseif inputObject.UserInputState == Enum.UserInputState.End and lastInputObject == inputObject then
		lastInputObject = nil
		initialScreenPoint = nil
		clickedOnPoint(screenPoint)
	end
end

function OnMouseMoved(screenPoint)
	if not ContextMenuOpen and lastInputObject and (screenPoint - initialScreenPoint).magnitude > MAX_MOVEMENT_THRESHOLD then
		lastInputObject = nil
		initialScreenPoint = nil
	end
end

function trackTouchSwipeInput(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.Touch then
		if not hasTouchSwipeInput and inputObject.UserInputState == Enum.UserInputState.Begin then
			if PointInSwipeArea(inputObject.Position) then
				hasTouchSwipeInput = inputObject
			end
		elseif hasTouchSwipeInput == inputObject and inputObject.UserInputState == Enum.UserInputState.End then
			spawn(function()
				hasTouchSwipeInput = nil
			end)
		end
	end
end

local function functionProcessInput(inputObject, gameProcessedEvent)
	trackTouchSwipeInput(inputObject)

	if gameProcessedEvent then
		if inputObject == lastInputObject then
			lastInputObject = nil
		end
		return
	end

	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or
		inputObject.UserInputType == Enum.UserInputType.Touch then
			OnUserInput(Vector2.new(inputObject.Position.X, inputObject.Position.Y), inputObject)
	elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
			OnMouseMoved(Vector2.new(inputObject.Position.X, inputObject.Position.Y))
	end
end

UserInputService.InputBegan:Connect(functionProcessInput)
UserInputService.InputChanged:Connect(functionProcessInput)
UserInputService.InputEnded:Connect(functionProcessInput)

UserInputService.TouchSwipe:Connect(function(swipeDir, numOfTouches, gameProcessedEvent)
	if not gameProcessedEvent then return end
	if not ContextMenuOpen then return end
	if not hasTouchSwipeInput then return end

	local offset = 0
	if swipeDir == Enum.SwipeDirection.Left then
		offset = 1
	elseif swipeDir == Enum.SwipeDirection.Right then
		offset = -1
	end

	if offset ~= 0 then
		ContextMenuGui:OffsetPlayerEntry(offset)
		SetSelectedPlayer(ContextMenuGui:GetSelectedPlayer())
	end
end)

LocalPlayer.FriendStatusChanged:Connect(function(player, friendStatus)
	if player and player == SelectedPlayer then
		local isBlocked = BlockingUtility:IsPlayerBlockedByUserId(player.UserId)
		ContextMenuItems:UpdateFriendButton(friendStatus, isBlocked)
	end
end)

function GetWorldPoint(player)
	if player.Character then
		local rootPart = player.Character:FindFirstChild("RootPart")
		if rootPart then
			return rootPart.Position
		end
	end
	if player ~= LocalPlayer then
		return GetWorldPoint(LocalPlayer)
	end
	return Vector3.new(0, 0, 0)
end

StarterGui:RegisterGetCore("AvatarContextMenuTarget",
	function()
		return SelectedPlayer
	end
)
StarterGui:RegisterSetCore("AvatarContextMenuTarget",
	function(player)
		local isPlayer = typeof(player) == "Instance" and player:IsA("Player")
		if isPlayer then
			if player.Parent ~= nil then
				if ContextMenuOpen or ContextMenuOpening then
					SetSelectedPlayer(player, true)
				else
					OpenContextMenu(player, GetWorldPoint(player))
				end
			else
				error("AvatarContextMenuTarget Player must be in the game")
			end
		elseif player == nil then
			CloseContextMenu()
		else
			error("AvatarContextMenuTarget argument must be a Player or nil")
		end
	end
)
