return function()
	local Plugin = script.Parent.Parent.Parent

	local Libs = Plugin.Libs
	local Roact = require(Libs.Roact)

	local MockWrapper = require(Plugin.Core.Util.MockWrapper)

	local TabSet = require(Plugin.Core.Components.TabSet)
	local Workspace = game:GetService("Workspace")

	it("should create and destroy without errors", function()
		local element = Roact.createElement(MockWrapper, {}, {
			TabSet = Roact.createElement(TabSet, {
				Tabs = {
					{Key = "Key", Text = "Text", Image = "rbxassetid://0"},
				},
				CurrentTab = "Key",
			}),
		})
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render correctly", function()
		local element = Roact.createElement(MockWrapper, {}, {
			TabSet = Roact.createElement(TabSet, {
				Tabs = {
					{Key = "Key", Text = "Text", Image = "rbxassetid://0"},
				},
				CurrentTab = "Key",
			}),
		})
		local container = Workspace.ToolboxTestsTarget
		local instance = Roact.mount(element, container, "TabSet")

		local tabSet = container.TabSet
		expect(tabSet).to.be.ok()
		expect(tabSet.Layout).to.be.ok()
		expect(tabSet.LeftPadding).to.be.ok()
		expect(tabSet.Key).to.be.ok()
		expect(tabSet.RightPadding).to.be.ok()
		expect(tabSet.RightPadding.LowerBorder).to.be.ok()

		Roact.unmount(instance)
	end)
end
