local FastFlags = require(script.Parent.Parent.FastFlags)

local EditClip = {}
EditClip.__index = EditClip

EditClip.ActionType = {
	lengthChange="lengthChange", 
	editRotate="editRotate",
	editTransform="editTransform",
	editEasingOptions="editEasingOptions",
	cut="cut",
	paste="paste",
	resetKeyframe="resetKeyframe",
	deleteKeyframe="deleteKeyframe",
	deletePose="deletePose",
	createKeyframe="createKeyframe",
	keyframeMove="keyframeMove",
	editKeyframeName="editKeyframeName",
}

if FastFlags:isScaleKeysOn() then
	EditClip.ActionType["clipScale"]="clipScale"
end

if FastFlags:isAnimationEventsOn() then
	EditClip.ActionType["removeAnimationEvents"] = "removeAnimationEvents"
	EditClip.ActionType["removeAnimationEvent"] = "removeAnimationEvent"
	EditClip.ActionType["editAnimationEvents"] = "editAnimationEvents"
	EditClip.ActionType["editAnimationEvent"] = "editAnimationEvent"
	EditClip.ActionType["addAnimationEvent"] = "addAnimationEvent"
end

EditClip.Description = {
	[EditClip.ActionType.lengthChange]="Edit Length",
	[EditClip.ActionType.editRotate]="Edit Rotation",
	[EditClip.ActionType.editTransform]="Edit Position",
	[EditClip.ActionType.resetKeyframe]="Reset Keyframe(s)",
	[EditClip.ActionType.editKeyframeName]="Edit Keyframe",
}

if FastFlags:isAnimationEventsOn() then
	EditClip.Description[EditClip.ActionType.removeAnimationEvents]="Remove Events"
	EditClip.Description[EditClip.ActionType.removeAnimationEvent]="Remove Event"
	EditClip.Description[EditClip.ActionType.editAnimationEvents]="Edit Events"
	EditClip.Description[EditClip.ActionType.editAnimationEvent]="Edit Event"
	EditClip.Description[EditClip.ActionType.addAnimationEvent]="Add Event"
end

function EditClip:execute(Paths, actionType)
	if FastFlags:isCheckForSavedChangesOn() then
		Paths.UtilityScriptUndoRedo:registerUndo(EditClip:new(Paths, {action = actionType}), true)
	else
		Paths.UtilityScriptUndoRedo:registerUndo(EditClip:new(Paths, {action = actionType}))
	end
end

function EditClip:new(Paths, action)
	local self = setmetatable({}, EditClip)
	self.Paths = Paths
	action.undo = Paths.DataModelClip:createAnimationFromCurrentData(false)
	self.action = action
	return self
end

function EditClip:undo()
	local newRedo = self.Paths.DataModelClip:createAnimationFromCurrentData(false)
	self.Paths.DataModelClip:loadImportAnim(self.action.undo)
	self.action.redo = newRedo
end

function EditClip:redo()
	local newUndo = self.Paths.DataModelClip:createAnimationFromCurrentData(false)
	self.Paths.DataModelClip:loadImportAnim(self.action.redo)
	self.action.undo = newUndo
end

function EditClip:getDescription()
	local defaultDescription = "Edit Clip"
	return self.Description[self.action.action] and self.Description[self.action.action] or defaultDescription
end

return EditClip
