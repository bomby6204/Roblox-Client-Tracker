-- singleton
local FastFlags = require(script.Parent.Parent.FastFlags)

local MultiSelectArea = {}

if FastFlags:isAnimationEventsOn() then
	local function findJointsInMultiSelectArea(self, Paths)
		for _, jointScript in pairs(Paths.GUIScriptJointTimeline.JointScripts) do
			if Paths.HelperFunctionsMath:overlap(Paths.GUIScriptMultiSelectArea.TargetWidget, jointScript.jointWidget.InfoAndTrack) then
				if FastFlags:isShiftSelectJointsOn() or not Paths.DataModelSession:areAnyKeyframesSelected() then
					if FastFlags:isShiftSelectJointsOn() then
						self.TempJoints[jointScript] = jointScript.DataItem
					end
					Paths.DataModelSession:addToDataItems(jointScript.DataItem, false)
				end
				if not FastFlags:isOptimizationsEnabledOn() then
					for _, key in ipairs(jointScript.Keyframes) do
						if key.Time and self.SelectAndDragBox:isInSelectedTimeRange(key.Time) then
							Paths.DataModelSession:addPoseToSelectedKeyframes(key.Time, jointScript.DataItem, false)
						else
							if not Paths.DataModelSession:isAClickedPose(key.Time, jointScript.DataItem) then
								Paths.DataModelSession:removePoseFromSelectedKeyframes(key.Time, jointScript.DataItem, false)
							end
						end
					end
				end
			else
				if not FastFlags:isScaleKeysOn() or not Paths.HelperFunctionsMath:overlap(Paths.GUIScriptMultiSelectArea.TargetWidget, Paths.GUIIndicatorArea) then
					if not FastFlags:isShiftSelectJointsOn() or self.TempJoints[jointScript] then
						Paths.DataModelSession:removeFromDataItems(jointScript.DataItem, false)
						if FastFlags:isShiftSelectJointsOn() then
							self.TempJoints[jointScript] = nil
						end
					end
				end
				if not FastFlags:isOptimizationsEnabledOn() then
					for _, key in ipairs(jointScript.Keyframes) do
						if not Paths.DataModelSession:isAClickedPose(key.Time, jointScript.DataItem) then
							Paths.DataModelSession:removePoseFromSelectedKeyframes(key.Time, jointScript.DataItem, false)
						end
					end
				end
			end
		end
		Paths.DataModelSession.SelectedChangeEvent:fire()
	end

	local function findKeysInMultiSelectArea(self, Paths)
		if FastFlags:isShiftSelectJointsOn() then
			for jointScript, dataItem in pairs(self.TempJoints) do
				for _, key in pairs(jointScript.Keyframes) do
					if key.Time and self.SelectAndDragBox:isInSelectedTimeRange(key.Time) and not Paths.DataModelSession:isAClickedPose(key.Time, dataItem) then
						Paths.DataModelSession:addPoseToSelectedKeyframes(key.Time, dataItem, false)
					end
				end
			end
		else
			for _, dataItem in pairs(Paths.DataModelSession:getSelectedDataItems()) do
				local jointScript = Paths.GUIScriptJointTimeline.JointScripts[dataItem.Item]
				for _, key in pairs(jointScript.Keyframes) do
					if key.Time and self.SelectAndDragBox:isInSelectedTimeRange(key.Time) and not Paths.DataModelSession:isAClickedPose(key.Time, dataItem) then
						Paths.DataModelSession:addPoseToSelectedKeyframes(key.Time, dataItem, false)
					end
				end
			end
		end
	end

	local function findIndicatorsInMultiSelectArea(self, Paths)
		local indicators = self.Paths.GUIScriptIndicatorArea.KeyframeIndicators
		for _, indicator in pairs(indicators) do
			if Paths.HelperFunctionsMath:overlap(self.TargetWidget, indicator.TargetWidget) then
				if not self.Paths.DataModelSession:areAnyPosesForTimeSelected(indicator.Time) then
					Paths.DataModelSession:addAllPosesAtTimeToKeyframes(indicator.Time, false)
				end
			elseif not FastFlags:isOptimizationsEnabledOn() and self.Paths.DataModelSession:areAnyPosesForTimeSelected(indicator.Time) then
				Paths.DataModelSession:removeAllPosesAtTimeFromKeyframes(indicator.Time, false)
			end
		end
		if not FastFlags:isOptimizationsEnabledOn() then
			Paths.DataModelSession.SelectedChangeEvent:fire()
		end
	end

	function MultiSelectArea:init(Paths)
		self.Paths = Paths
		self.TargetWidget = Paths.GUIMultiSelectArea
		if FastFlags:isShiftSelectJointsOn() then
			self.TempJoints = {}
		end
		if FastFlags:isOptimizationsEnabledOn() then
			local selectFunc = function()
				findJointsInMultiSelectArea(self, Paths)
			end
			local endFunc = function()
				findIndicatorsInMultiSelectArea(self, Paths)
				findKeysInMultiSelectArea(self, Paths)
				Paths.DataModelSession.SelectedChangeEvent:fire()
				if FastFlags:isShiftSelectJointsOn() then
					self.TempJoints = {}
				end
			end
			if FastFlags:isContinueScrollingWithSelectionAreaOn() then
				local bounds = Paths.GUIScriptJointTimeline:getJointTrackBounds()
				self.SelectAndDragBox = self.Paths.WidgetSelectAndDragBox:new(Paths, Paths.GUIMultiSelectArea, self.Paths.GUIScriptJointTimeline.TargetWidget, selectFunc, endFunc, bounds)
			else
				self.SelectAndDragBox = self.Paths.WidgetSelectAndDragBox:new(Paths, Paths.GUIMultiSelectArea, self.Paths.GUIScriptJointTimeline.TargetWidget, selectFunc, endFunc)
			end
		else
			local selectFunc = function()
				findIndicatorsInMultiSelectArea(self, Paths)
				findJointsInMultiSelectArea(self, Paths)
			end
			self.SelectAndDragBox = self.Paths.WidgetSelectAndDragBox:new(Paths, Paths.GUIMultiSelectArea, self.Paths.GUIScriptJointTimeline.TargetWidget, selectFunc)
		end
	end

	function MultiSelectArea:isSelecting()
		return self.SelectAndDragBox:isSelecting()
	end

	function MultiSelectArea:terminate()
		self.SelectAndDragBox:terminate()
		self.SelectAndDragBox = nil

		self.Paths = nil
	end
else
	MultiSelectArea.TargetWidget = nil
	MultiSelectArea.StartPos = nil
	MultiSelectArea.StartTime = nil
	MultiSelectArea.EndTime = nil
	MultiSelectArea.Clicked = false

	local function positionArea(self)
		local xOffset = self.StartPos.X - self.Paths.GUIScriptJointTimeline.TargetWidget.AbsolutePosition.X
		local yOffset = self.StartPos.Y - self.Paths.GUIScriptJointTimeline.TargetWidget.AbsolutePosition.Y

		self.TargetWidget.Position = UDim2.new(0, xOffset, 0, yOffset)
	end

	local function resizeArea(self)
		if self.StartPos.X ~= nil and self.StartPos.Y ~= nil then
			local size = Vector2.new(self.StartPos.X - self.Paths.InputMouse:getX(), self.StartPos.Y - self.Paths.InputMouse:getY())
			
			local anchorPosX = 0
			local anchorPosY = 0

			if size.X > 0 then anchorPosX = 1 end
			if size.Y > 0 then anchorPosY = 1 end

			size = 	Vector2.new(math.abs(size.X), math.abs(size.Y))

			self.TargetWidget.AnchorPoint = Vector2.new(anchorPosX, anchorPosY)
			self.TargetWidget.Size = UDim2.new(0, size.X, 0, size.Y)
		end
	end

	local function findJointsInMultiSelectArea(Paths)
		for _, jointScript in pairs(Paths.GUIScriptJointTimeline.JointScripts) do
			if Paths.HelperFunctionsMath:overlap(Paths.GUIScriptMultiSelectArea.TargetWidget, jointScript.jointWidget.InfoAndTrack) then
				if not Paths.DataModelSession:areAnyKeyframesSelected() then
					Paths.DataModelSession:addToDataItems(jointScript.DataItem, false)
				end
				for _, key in ipairs(jointScript.Keyframes) do
					if key.Time and Paths.GUIScriptMultiSelectArea:isInSelectedTimeRange(key.Time) then
						Paths.DataModelSession:addPoseToSelectedKeyframes(key.Time, jointScript.DataItem, false)
					else
						if not Paths.DataModelSession:isAClickedPose(key.Time, jointScript.DataItem) then
							Paths.DataModelSession:removePoseFromSelectedKeyframes(key.Time, jointScript.DataItem, false)
						end
					end
				end
			else
				if not FastFlags:isScaleKeysOn() or not Paths.HelperFunctionsMath:overlap(Paths.GUIScriptMultiSelectArea.TargetWidget, Paths.GUIIndicatorArea) then
					Paths.DataModelSession:removeFromDataItems(jointScript.DataItem, false)
				end
				for _, key in ipairs(jointScript.Keyframes) do
					if not Paths.DataModelSession:isAClickedPose(key.Time, jointScript.DataItem) then
						Paths.DataModelSession:removePoseFromSelectedKeyframes(key.Time, jointScript.DataItem, false)
					end
				end
			end
		end
		Paths.DataModelSession.SelectedChangeEvent:fire()
	end

	local function findIndicatorsInMultiSelectArea(self, Paths)
		local indicators = self.Paths.GUIScriptIndicatorArea.KeyframeIndicators
		for _, indicator in ipairs(indicators) do
			if Paths.HelperFunctionsMath:overlap(self.TargetWidget, indicator.TargetWidget) then
				if not self.Paths.DataModelSession:areAnyPosesForTimeSelected(indicator.Time) then
					Paths.DataModelSession:addAllPosesAtTimeToKeyframes(indicator.Time, false)
				end
			elseif self.Paths.DataModelSession:areAnyPosesForTimeSelected(indicator.Time) then
				Paths.DataModelSession:removeAllPosesAtTimeFromKeyframes(indicator.Time, false)
			end
		end
		Paths.DataModelSession.SelectedChangeEvent:fire()
	end

	local function show(self)
		self.StartPos = Vector2.new(self.Paths.InputMouse:getX(), self.Paths.InputMouse:getY())
		positionArea(self)
		resizeArea(self)
		self.TargetWidget.Visible = true
	end

	local function update(self)
		resizeArea(self)
	end

	local function hide(self)
		self.TargetWidget.Visible = false
	end

	local function setStartTime(self, time)
		self.StartTime = time
	end

	local function setEndTime(self, time)
		self.EndTime = time
	end

	function MultiSelectArea:init(Paths)
		self.Paths = Paths
		self.TargetWidget = Paths.GUIMultiSelectArea
		self.TargetWidget.Visible = false

		self.Connections = Paths.UtilityScriptConnections:new(Paths)

		self.Connections:add(self.TargetWidget.Parent.InputBegan:connect(function(input)
			local clickTime = self.Paths.UtilityScriptDisplayArea:getFormattedMouseTime()
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Paths.GUIScriptScrubberDisplayArea.dragableScrubber:isDragging() then
				if not Paths.UtilityScriptMoveItems:isMovingKeys() then
					self.Clicked = true
					show(self)
					setStartTime(self, clickTime)
					setEndTime(self, clickTime)
				end
			end
		end))

		self.Connections:add(self.TargetWidget.Parent.InputChanged:connect(function(input)
			local clickTime = self.Paths.UtilityScriptDisplayArea:getFormattedMouseTime()
			if input.UserInputType == Enum.UserInputType.MouseMovement and self.Clicked and not self.Paths.GUIScriptScrubberDisplayArea.dragableScrubber:isDragging() then
				if not Paths.UtilityScriptMoveItems:isMovingKeys() then
					update(self)
					findIndicatorsInMultiSelectArea(self, Paths)
					findJointsInMultiSelectArea(Paths)
					setEndTime(self, clickTime)
				end
			end
		end))

		self.Connections:add(self.TargetWidget.Parent.InputEnded:connect(function(input)
			local clickTime = self.Paths.UtilityScriptDisplayArea:getFormattedMouseTime()
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self.Clicked = false
				hide(self)
				setEndTime(self, clickTime)
			end
		end))
	end

	function MultiSelectArea:isInSelectedTimeRange(time)
		if time and self.StartTime ~= nil and self.EndTime ~= nil then
			if not self.Paths.HelperFunctionsMath:isCloseToZero(self.StartTime) or not self.Paths.HelperFunctionsMath:isCloseToZero(self.EndTime) then
				local min, max = math.min(self.StartTime, self.EndTime), math.max(self.StartTime, self.EndTime)
				if time >= min and time <= max then
					return true
				end
			end
		end

		return false
	end

	if FastFlags:isScaleKeysOn() then
		function MultiSelectArea:isSelecting()
			return self.Clicked
		end
	end

	function MultiSelectArea:terminate()
		self.TargetWidget = nil
		self.Paths = nil

		self.Connections:disconnectAll()
	end
end

return MultiSelectArea