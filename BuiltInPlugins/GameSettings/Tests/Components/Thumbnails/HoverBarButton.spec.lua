return function()
	local Plugin = script.Parent.Parent.Parent.Parent
	local Roact = require(Plugin.Roact)

	local HoverBarButton = require(Plugin.Src.Components.Thumbnails.HoverBarButton)

	local function createTestHoverBarButton(enabled)
		return Roact.createElement(HoverBarButton, {
			Image = "",
		})
	end

	it("should create and destroy without errors", function()
		local element = createTestHoverBarButton()
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render correctly", function()
		local container = workspace
		local instance = Roact.mount(createTestHoverBarButton(), container)
		local button = container.ImageButton

		expect(button.Icon).to.be.ok()

		Roact.unmount(instance)
	end)
end