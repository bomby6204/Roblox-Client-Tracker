return function()
	local Modules = game:GetService("CoreGui").RobloxGui.Modules

	local Roact = require(Modules.Common.Roact)
	local Rodux = require(Modules.Common.Rodux)
	local RoactRodux = require(Modules.Common.RoactRodux)

	local AppReducer = require(Modules.LuaApp.AppReducer)

	local DropDownList = require(Modules.LuaApp.Components.DropDownList)

	it("should create and destroy without errors", function()

		local store = Rodux.Store.new(AppReducer)

		local listItems = {
			{
				text = "Featured",
				icon = "rbxasset://textures/ui/LuaApp/category/ic-featured.png",
			}, {
				text = "Popular",
				icon = "rbxasset://textures/ui/LuaApp/category/ic-popular.png",
			}, {
				text = "Top Rated",
				icon = "rbxasset://textures/ui/LuaApp/category/ic-top rated.png",
			}
		}

		local element = Roact.createElement(RoactRodux.StoreProvider, {
			store = store,
		}, {
			List = Roact.createElement(DropDownList, {
				itemDefault = 1,
				items = listItems,
				size = UDim2.new(0, 300, 0, 40),
				text = "Default Text",
			}),
		})

		local instance = Roact.reify(element)
		Roact.teardown(instance)
	end)
end