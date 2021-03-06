-- singleton

local FastFlags = require(script.Parent.Parent.FastFlags)

local TimelineMenu = {}

TimelineMenu.TargetWidget = nil
TimelineMenu.Menu  = nil

function TimelineMenu:init(Paths)
	self.Paths = Paths
	self.TargetWidget = Paths.GUITimelineMenu
	self.fullSize = self.TargetWidget.Size
	self.Menu = Paths.WidgetMainMenu:new2(Paths, self.TargetWidget)

	self.AddKeyHandle = self.Menu:getOption("MenuOptionAddKey")
	self.Menu:setClickCallback(self.AddKeyHandle, function()
		if FastFlags:isRightClickAddKeyFixOn() then
			Paths.DataModelKeyframes:createAndSelectKeyframe(self.DataItem, self.Time)
		else
			Paths.DataModelKeyframes:getOrCreateKeyframes(Paths.DataModelSession:getSelectedDataItems(), self.Time)
		end
	end)

	if FastFlags:isRightClickAddKeyFixOn() then
		self.AddKeyAtScrubberHandle = self.Menu:getOption("MenuOptionAddKeyAtScrubber")
		self.Menu:setClickCallback(self.AddKeyAtScrubberHandle, function()
			Paths.DataModelKeyframes:createAndSelectMultipleKeys(Paths.DataModelSession:getSelectedDataItems(), Paths.DataModelSession:getScrubberTime())
		end)
	end
	
	self.DeleteKeyHandle = self.Menu:getOption("MenuOptionDeleteKey")
	self.Menu:setClickCallback(self.DeleteKeyHandle, function() Paths.DataModelKeyframes:deleteSelectedPosesAndEmptyKeyframes() end)
	
	self.CopyKeyHandle = self.Menu:getOption("MenuOptionCopyKey")
	if FastFlags:isAnimationEventsOn() then
		self.Menu:setClickCallback(self.CopyKeyHandle, function() Paths.UtilityScriptCopyPaste:copy() end)	
	else
		self.Menu:setClickCallback(self.CopyKeyHandle, function() Paths.UtilityScriptCopyPaste:copy(self.Paths.DataModelSession:getSelectedKeyframes(), self.Time) end)
	end
	
	self.CutKeyHandle = self.Menu:getOption("MenuOptionCutKey")
	if FastFlags:isAnimationEventsOn() then
		self.Menu:setClickCallback(self.CutKeyHandle, function() Paths.UtilityScriptCopyPaste:cut() end)
	else
		self.Menu:setClickCallback(self.CutKeyHandle, function() Paths.UtilityScriptCopyPaste:cut(self.Paths.DataModelSession:getSelectedKeyframes(), self.Time) end)
	end
	
	self.PasteKeyHandle = self.Menu:getOption("MenuOptionPasteKey")
	self.Menu:setClickCallback(self.PasteKeyHandle, function() Paths.UtilityScriptCopyPaste:paste(self.Time) end)
	
	self.easingOptionsHandle = self.Menu:getOption("MenuOptionEasingOptions")
	self.Menu:setClickCallback(self.easingOptionsHandle, function() Paths.GUIScriptEasingOptions:show(self.Paths.DataModelSession:getAllSelectedPoses()) end)

	if FastFlags:isScaleKeysOn() then
		self.changeDurationHandle = self.Menu:getOption("MenuOptionChangeDuration")
		self.Menu:setClickCallback(self.changeDurationHandle, function() Paths.GUIScriptScaleControls:promptDurationChange() end)
	end
	
	self.resetChangedHandle = self.Menu:getOption("MenuOptionResetChanged")
	self.Menu:setClickCallback(self.resetChangedHandle, function() Paths.DataModelKeyframes:resetKeyframeToDefaultPose(self.Time) end)
	
	self.resetJointHandle = self.Menu:getOption("MenuOptionResetJoint")
	self.Menu:setClickCallback(self.resetJointHandle, function()
		if not FastFlags:isFixResetJointOn() or not self.Paths.HelperFunctionsTable:isNilOrEmpty(Paths.DataModelSession:getSelectedDataItems()) then
			Paths.DataModelKeyframes:resetPartsToDefaultPose(Paths.DataModelSession:getSelectedDataItems(), self.Time)
		end
	end)
	if not FastFlags:isFixResetJointOn() then
		self.Menu:setEnabled(self.resetJointHandle, true)
	end

	self.RenameKeyFrameHandle = self.Menu:getOption("MenuOptionRenameKeyFrame")
	self.Menu:setClickCallback(self.RenameKeyFrameHandle, function() self.Paths.ActionEditKeyframeName:execute(self.Paths, self.Paths.DataModelClip:getKeyframe(self.Time)) end)	
	
	self.Connections = Paths.UtilityScriptConnections:new(Paths)	
	local closeForChanges = function()
		if self.Menu:isOpen() then -- close if anything done while the menu is open, as things could be in a weird state (alternately could disable undo/redo while this menu is open)
			self.Menu:turnOn(false)
		end
	end
	self.Connections:add(self.Paths.UtilityScriptUndoRedo.ChangeEvent:connect(closeForChanges))
	self.Connections:add(self.Paths.DataModelSession.SelectedChangeEvent:connect(closeForChanges))		
end

function TimelineMenu:showAvailableOptions(pose)
	local multipleDataItemsSelected = self.Paths.DataModelSession:areMultipleDataItemsSelected()
	local multiplePosesSelected = self.Paths.DataModelSession:areMultiplePosesSelected()
	local showKeyframeSelectedMenu = self.Paths.DataModelSession:areAnyKeyframesSelected()
	local poseSelected = pose ~= nil
	local showPoseOptions = poseSelected and showKeyframeSelectedMenu and not multiplePosesSelected
	local showKeyframeActionLabel = self.Paths.DataModelSession:isOnlyOneKeyframeSelected() and not poseSelected
	local showAddKeyAtScrubber = not poseSelected and self.Paths.DataModelSession:areAnyDataItemsSelected()

	if FastFlags:isRightClickAddKeyFixOn() then
		self.Menu:setEnabled(self.AddKeyHandle, not poseSelected)
		self.Menu:setEnabled(self.AddKeyAtScrubberHandle, showAddKeyAtScrubber)
		local addText = multipleDataItemsSelected and "Add Keys at Scrubber" or "Add Key at Scrubber"
		self.Menu:setMainText(self.AddKeyAtScrubberHandle, addText)
	else
		self.Menu:setEnabled(self.AddKeyHandle, not showKeyframeSelectedMenu)
		local addText = multipleDataItemsSelected and "Add Keys" or "Add Key"
		self.Menu:setMainText(self.AddKeyHandle, addText)
	end

	self.Menu:setEnabled(self.DeleteKeyHandle, showKeyframeSelectedMenu)

	local deleteText = multiplePosesSelected and "Selection" or self.DataItem.Name
	if showKeyframeActionLabel then
		deleteText = "Keyframe"
	end
	self.Menu:setMainText(self.DeleteKeyHandle, "Delete " .. deleteText)
	
	self.Menu:setEnabled(self.CutKeyHandle, showKeyframeSelectedMenu)
	self.Menu:setEnabled(self.CopyKeyHandle, showKeyframeSelectedMenu)

	local cutCopyDescription = self.DataItem.Name
	if multiplePosesSelected then
		cutCopyDescription = "Selection"
	end

	if showKeyframeActionLabel then
		cutCopyDescription = "Keyframe"
	end

	self.Menu:setMainText(self.CutKeyHandle, "Cut " .. cutCopyDescription)
	self.Menu:setMainText(self.CopyKeyHandle, "Copy " .. cutCopyDescription)

	local canPaste = self.Paths.UtilityScriptCopyPaste:canPasteKeyframePoses() or self.Paths.UtilityScriptCopyPaste:canPaste(self.DataItem.Name)
	self.Menu:setEnabled(self.PasteKeyHandle, canPaste)
	
	self.Menu:setMainText(self.PasteKeyHandle, "Paste " .. self.Paths.UtilityScriptCopyPaste:getPasteDescription())

	self.Menu:setEnabled(self.easingOptionsHandle, showKeyframeSelectedMenu)

	if FastFlags:isScaleKeysOn() then
		self.Menu:setEnabled(self.changeDurationHandle, self.Paths.GUIScriptScaleControls:isActive())
	end

	self.Menu:setEnabled(self.resetChangedHandle, self.Paths.DataModelKeyframes:doAnyPosesExist())

	if FastFlags:isFixResetJointOn() then
		self.Menu:setMainText(self.resetJointHandle, "Reset Selected")
		self.Menu:setEnabled(self.resetJointHandle, self.Paths.DataModelSession:areAnyDataItemsSelected())
	else
		local resetText = (multipleDataItemsSelected or multiplePosesSelected) and "Reset Selected" or ("Reset " .. self.DataItem.Name)
		self.Menu:setMainText(self.resetJointHandle, resetText)
	end
			
	if FastFlags:isFixRenameKeyOptionOn() then
		self.Menu:setEnabled(self.RenameKeyFrameHandle, showKeyframeActionLabel or showPoseOptions)
	else
		self.Menu:setEnabled(self.RenameKeyFrameHandle, showPoseOptions)
	end
	local theRenameKeyText = "Rename Key "
	if showKeyframeSelectedMenu then						
		local key = self.Paths.DataModelClip:getKeyframe(self.Time)			
		theRenameKeyText = nil ~= key and theRenameKeyText .. key.Name or theRenameKeyText				
	end
	self.Menu:setMainText(self.RenameKeyFrameHandle, theRenameKeyText)
end

local function positionMenu(self)
	local potentialXOffset = self.Paths.InputMouse:getX()-self.TargetWidget.Parent.AbsolutePosition.X
	local potentialYOffset = self.Paths.InputMouse:getY()-self.TargetWidget.Parent.AbsolutePosition.Y

	-- checking horizontal		
	local rightSideEdge = self.TargetWidget.Parent.AbsolutePosition.X+self.TargetWidget.Parent.AbsoluteSize.X	
	local willMenuGetCutOffToTheRight = potentialXOffset+self.TargetWidget.AbsoluteSize.X > rightSideEdge
	if willMenuGetCutOffToTheRight then
		potentialXOffset = rightSideEdge-self.TargetWidget.AbsoluteSize.X --move menu to the left
	end
	
	-- checking vertical
	local bottomSideEdge = self.Paths.GUIScrollingJointTimeline.AbsolutePosition.Y + self.Paths.GUIScrollingJointTimeline.AbsoluteSize.Y
	local willMenuGetCutOffToTheBottom = potentialYOffset+self.TargetWidget.AbsoluteSize.Y > bottomSideEdge
	if willMenuGetCutOffToTheBottom then
		potentialYOffset = potentialYOffset-self.TargetWidget.AbsoluteSize.Y --move menu above cursor
	end

	if self.TargetWidget.AbsoluteSize.Y > self.Paths.GUIScrollingJointTimeline.AbsoluteSize.Y then
		potentialYOffset = self.Paths.GUIScrollingJointTimeline.AbsolutePosition.Y
	end
	self.TargetWidget.Position = UDim2.new(0, potentialXOffset, 0, math.max(self.Paths.GUIScrollingJointTimeline.AbsolutePosition.Y, potentialYOffset))
end

local function scaleMenuForScrolling(self)
	if self.TargetWidget.AbsoluteSize.Y > self.Paths.GUIScrollingJointTimeline.AbsoluteSize.Y then
		self.TargetWidget.Size = UDim2.new(0, self.fullSize.X.Offset, 0, self.Paths.GUIScrollingJointTimeline.AbsoluteSize.Y)
		self.TargetWidget.MenuOptions.ScrollingEnabled = true
	else
		self.TargetWidget.MenuOptions.ScrollingEnabled = false
	end
end

function TimelineMenu:show(time, dataItem, pose)
	self.Time = time
	self.DataItem = dataItem
	self.Pose = pose

	self.Keyframe = self.Paths.DataModelClip:getKeyframe(time)

	self:showAvailableOptions(pose)

	-- use full size to determine where to position the menu
	self.TargetWidget.Size = self.fullSize
	positionMenu(self)
	scaleMenuForScrolling(self)
	
	self.Menu:turnOn(true)
end

function TimelineMenu:terminate()
	self.Connections:terminate()
	self.Connections = nil
	
	self.Menu:terminate()
	self.Menu = nil
	self.TargetWidget = nil
	self.Paths = nil
end

return TimelineMenu