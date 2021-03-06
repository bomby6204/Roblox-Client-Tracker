return function()
	local NavigationEvents = require(script.Parent.NavigationEvents)

	describe("NavigationEvents token tests", function()
		it("should return same object for each token for multiple calls", function()
			expect(NavigationEvents.WillFocus).to.equal(NavigationEvents.WillFocus)
			expect(NavigationEvents.DidFocus).to.equal(NavigationEvents.DidFocus)
			expect(NavigationEvents.WillBlur).to.equal(NavigationEvents.WillBlur)
			expect(NavigationEvents.DidBlur).to.equal(NavigationEvents.DidBlur)
		end)

		it("should return matching string names for symbols", function()
			expect(tostring(NavigationEvents.WillFocus)).to.equal("WILL_FOCUS")
			expect(tostring(NavigationEvents.DidFocus)).to.equal("DID_FOCUS")
			expect(tostring(NavigationEvents.WillBlur)).to.equal("WILL_BLUR")
			expect(tostring(NavigationEvents.DidBlur)).to.equal("DID_BLUR")
		end)
	end)
end
