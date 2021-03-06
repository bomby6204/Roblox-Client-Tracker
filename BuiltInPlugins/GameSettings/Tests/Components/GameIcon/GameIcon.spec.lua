return function()
	local Plugin = script.Parent.Parent.Parent.Parent
	local Roact = require(Plugin.Roact)

	local Theme = require(Plugin.Src.Util.Theme)
	local ThemeProvider = require(Plugin.Src.Providers.ThemeProvider)
	local Localization = require(Plugin.Src.Localization.Localization)
	local LocalizationProvider = require(Plugin.Src.Providers.LocalizationProvider)

	local GameIcon = require(Plugin.Src.Components.GameIcon.GameIcon)

	local theme = Theme.newDummyTheme()
	local localization = Localization.newDummyLocalization()
	local localized = localization.values

	local function createTestGameIcon(props)
		return Roact.createElement(ThemeProvider, {
			theme = theme,
		}, {
			Roact.createElement(LocalizationProvider, {
				localization = localization,
			}, {
				icon = Roact.createElement(GameIcon, props),
			}),
		})
	end

	it("should create and destroy without errors", function()
		local element = createTestGameIcon()
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render correctly", function()
		local container = workspace
		local instance = Roact.mount(createTestGameIcon(), container)
		local icon = container.ImageLabel

		expect(icon.Fallback).to.be.ok()
		expect(icon.InfoText).to.be.ok()
		expect(icon.Change).to.be.ok()
		expect(icon.Change.Text).to.be.ok()

		Roact.unmount(instance)
	end)

	it("should show when it is under review", function()
		local container = workspace
		local instance = Roact.mount(createTestGameIcon({
			Review = true,
		}), container)
		local icon = container.ImageLabel

		expect(icon.InfoText.Visible).to.equal(true)
		expect(icon.InfoText.Text).to.equal(localized.GameIcon.Review)

		Roact.unmount(instance)
	end)
end