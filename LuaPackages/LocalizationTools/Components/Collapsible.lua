local Roact = require(game:GetService("CorePackages").Roact)
local Theming = require(script.Parent.Parent.Theming)

local BAR_HEIGHT = 24
local ICON_SIZE = 16

local Collapsible = Roact.PureComponent:extend("Collapsible")

function Collapsible:init()
    self.state ={
        open = false,
    }
end

function Collapsible:render()
    return Theming.withTheme(function(theme)
        return Roact.createElement("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = self.props.LayoutOrder,
            Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
        }, {
            Layout = Roact.createElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 5),
            }),

            TopBar = Roact.createElement("TextButton", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
                LayoutOrder = 1,
                Text = "",

                [Roact.Event.MouseButton1Click] = function()
                    self:setState(function(prevState, _)
                        return {
                            open = not prevState.open,
                        }
                    end)
                end
            }, {
                Layout = Roact.createElement("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 5),
                }),

                IconFrame = Roact.createElement("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 1,
                    Size = UDim2.new(0, BAR_HEIGHT, 0, BAR_HEIGHT),
                }, {
                    IconImage = Roact.createElement("ImageLabel", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Image = self.state.open and
                            "rbxasset://textures/collapsibleArrowDown.png" or
                            "rbxasset://textures/collapsibleArrowRight.png",
                        ImageColor3 = theme.BrightText,
                    }),
                }),

                Title = Roact.createElement("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 2,
                    Size = UDim2.new(1, -BAR_HEIGHT, 0, BAR_HEIGHT),
                    Text = self.props.Title,
                    TextColor3 = theme.BrightText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
            }),

            Content = self.state.open and self.props.RenderContent() or nil,
        })
    end)
end

return Collapsible
