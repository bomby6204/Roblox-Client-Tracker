--[[
	Represents the Thumbnails widget in Basic Info.
	Consists of a list of tips as well as the ThumbnailSet.
	Handles the logic for dragging and reordering thumbnails.

	This component should only be created as part of a ThumbnailController.
	If just making a list of thumbnails to preview, use a ThumbnailSet.

	Props:
		bool Enabled = Whether this component is enabled.

		table Thumbnails = A list of thumbnails to display.
			{id1 = {thumbnail1}, id2 = {thumbnail2}, ..., idn = {thumbnailn}}

		list Order = The order that the given Thumbnails will be displayed.
			{id1, id2, id3, ..., idn}

		int LayoutOrder = The order in which this widget should display in its parent.
		function ThumbnailAction = A callback for when the user interacts with a Thumbnail.
			Called when a thumbnail's button is pressed, when the user wants to add a new
			thumbnail, or when the user has finished dragging a thumbnail.
			These actions are handled by the ThumbnailController above this component.
]]

local FFlagGameSettingsImageUploadingEnabled = settings():GetFFlag("GameSettingsImageUploadingEnabled")
local FFlagGameSettingsEnforceMaxThumbnails = settings():GetFFlag("GameSettingsEnforceMaxThumbnails")

local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Roact)
local Cryo = require(Plugin.Cryo)
local Constants = require(Plugin.Src.Util.Constants)
local withTheme = require(Plugin.Src.Consumers.withTheme)
local withLocalization = require(Plugin.Src.Consumers.withLocalization)
local getMouse = require(Plugin.Src.Consumers.getMouse)

local ThumbnailSet = require(Plugin.Src.Components.Thumbnails.ThumbnailSet)
local DragGhostThumbnail = require(Plugin.Src.Components.Thumbnails.DragGhostThumbnail)
local BulletPoint = require(Plugin.Src.Components.BulletPoint)
local createFitToContent = require(Plugin.Src.Components.createFitToContent)

local ThumbnailWidget = Roact.PureComponent:extend("ThumbnailWidget")

local FitToContent = createFitToContent("Frame", "UIListLayout", {
	Padding = UDim.new(0, 15),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

function ThumbnailWidget:init()
	self.frameRef = Roact.createRef()
	self.state = {
		dragId = nil,
		dragIndex = nil,
		oldIndex = nil,
	}

	self.heightChanged = function(newheight)
		local frame = self.frameRef.current
		frame.Size = UDim2.new(1, 0, 0, newheight + Constants.FRAME_PADDING
			+ Constants.ELEMENT_PADDING + Constants.HEADER_HEIGHT + Constants.ELEMENT_PADDING)
	end

	self.startDragging = function(dragInfo)
		self:setState({
			dragId = dragInfo.thumbnailId,
			dragIndex = dragInfo.index,
			oldIndex = dragInfo.index or nil,
		})
	end

	self.dragMove = function(dragInfo)
		self:setState({
			dragIndex = dragInfo.index,
		})
	end

	self.stopDragging = function()
		if self.state.dragId ~= nil and self.state.dragIndex ~= nil then
			getMouse(self).resetMouse()
			if self.state.dragIndex == self.state.oldIndex then
				self:setState({
					dragId = Roact.None,
					dragIndex = Roact.None,
					oldIndex = Roact.None,
				})
			else
				self.props.ThumbnailAction("MoveTo", {
					thumbnailId = self.state.dragId,
					index = self.state.dragIndex,
				})
			end
		end
	end
end

function ThumbnailWidget.getDerivedStateFromProps(_, lastState)
	-- When the user stops dragging, the Order prop will change, and
	-- the lastState will still hold a dragId and dragIndex. Set those values
	-- back to nil here so that the thumbnails render in the right order.
	if lastState.dragId ~= nil then
		return {
			dragId = Roact.None,
			dragIndex = Roact.None,
			oldIndex = Roact.None,
		}
	end
end

function ThumbnailWidget:render()
	return withLocalization(function(localized)
		return withTheme(function(theme)
			local active = self.props.Enabled

			local thumbnails = self.props.Thumbnails or {}
			local order = self.props.Order or {}
			local numThumbnails = #order or 0
			local errorMessage = self.props.ErrorMessage

			local dragId = self.state.dragId
			local dragIndex = self.state.dragIndex
			local dragging = dragId ~= nil

			local dragThumbnails
			local dragOrder
			if dragging then
				dragThumbnails = Cryo.Dictionary.join(thumbnails, {
					[dragId] = {
						id = "DragDestination",
					},
				})
				dragOrder = Cryo.List.removeValue(order, dragId)
				table.insert(dragOrder, dragIndex, dragId)
			end

			local dragImageId = nil
			if thumbnails[dragId] then
				if thumbnails[dragId].imageId then
					dragImageId = "rbxassetid://" .. thumbnails[dragId].imageId
				elseif FFlagGameSettingsImageUploadingEnabled and thumbnails[dragId].tempId then
					dragImageId = thumbnails[dragId].tempId
				end
			end

			local countTextColor
			if FFlagGameSettingsEnforceMaxThumbnails then
				if errorMessage or numThumbnails > Constants.MAX_THUMBNAILS then
					countTextColor = Constants.ERROR_COLOR
				else
					countTextColor = theme.thumbnail.count
				end
			else
				countTextColor = errorMessage and Constants.ERROR_COLOR or theme.thumbnail.count
			end

			return Roact.createElement(FitToContent, {
				LayoutOrder = self.props.LayoutOrder or 1,
				BackgroundTransparency = 1,
			}, {
				-- Placed in a folder to prevent this component from being part
				-- of the LayoutOrder. This component is a drag area that is the size
				-- of the entire component.
				DragFolder = Roact.createElement("Folder", {}, {
					DragGhost = Roact.createElement(DragGhostThumbnail, {
						Enabled = active and dragging,
						Image = dragImageId,
						StopDragging = self.stopDragging,
					}),
				}),

				Title = Roact.createElement("TextLabel", {
					LayoutOrder = 0,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 16),

					TextColor3 = theme.titledFrame.text,
					Font = Enum.Font.SourceSans,
					TextSize = 22,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Text = localized.Title.Thumbnails,
				}),

				Notes = Roact.createElement("Frame", {
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 72),
					Position = UDim2.new(0, 0, 0, 0),
				}, {
					Layout = Roact.createElement("UIListLayout", {
						Padding = UDim.new(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					LimitHint = Roact.createElement(BulletPoint, {
						LayoutOrder = 1,
						Text = localized.Thumbnails.Limit({
							maxThumbnails = Constants.MAX_THUMBNAILS,
						}),
					}),
					FileHint = Roact.createElement(BulletPoint, {
						LayoutOrder = 2,
						Text = localized.Thumbnails.Hint({
							fileTypes = table.concat(Constants.IMAGE_TYPES, ", "),
						}),
					}),
					ModerationHint = Roact.createElement(BulletPoint, {
						LayoutOrder = 3,
						Text = localized.Thumbnails.Moderation,
					}),
				}),

				Thumbnails = Roact.createElement(ThumbnailSet, {
					LayoutOrder = 2,
					Thumbnails = dragging and dragThumbnails or thumbnails,
					Order = dragging and dragOrder or order,
					HoverBarsEnabled = not dragging,
					Enabled = active,
					Position = UDim2.new(0, 0, 0, 96),

					SetHeight = self.heightChanged,

					StartDragging = self.startDragging,
					DragMove = self.dragMove,

					ButtonPressed = self.props.ThumbnailAction,
					AddNew = function()
						self.props.ThumbnailAction("AddNew")
					end,
				}),

				-- Placed in a folder to prevent this component from being part
				-- of the LayoutOrder and receiving padding above and below
				CountFolder = Roact.createElement("Folder", {}, {
					Count = Roact.createElement("TextLabel", {
						Visible = active,
						Size = UDim2.new(1, 0, 0, 20),
						Position = UDim2.new(0, 0, 1, Constants.ELEMENT_PADDING),
						AnchorPoint = Vector2.new(0, 1),
						BackgroundTransparency = 1,
						TextColor3 = countTextColor,
						Text = errorMessage
							or numThumbnails > 0 and (numThumbnails .. "/" .. Constants.MAX_THUMBNAILS)
							or localized.Thumbnails.Count({maxThumbnails = Constants.MAX_THUMBNAILS}),
						Font = Enum.Font.SourceSans,
						TextSize = 16,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					}),
				}),
			})
		end)
	end)
end

return ThumbnailWidget