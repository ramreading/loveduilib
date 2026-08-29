--!strict
-- CodexUI - a Studio-safe Roblox UI library with a Codex-inspired terminal theme.
-- Put this ModuleScript in ReplicatedStorage and require it from a LocalScript.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local CodexUI = {}
CodexUI.__index = CodexUI

CodexUI.Theme = {
	Background = Color3.fromRGB(12, 15, 20),
	Surface = Color3.fromRGB(20, 25, 33),
	SurfaceHover = Color3.fromRGB(29, 37, 48),
	Panel = Color3.fromRGB(16, 21, 28),
	Border = Color3.fromRGB(57, 72, 88),
	Text = Color3.fromRGB(232, 238, 245),
	Muted = Color3.fromRGB(145, 160, 177),
	Accent = Color3.fromRGB(16, 185, 129), -- Codex green
	AccentDim = Color3.fromRGB(10, 85, 64),
	Danger = Color3.fromRGB(248, 113, 113),
}

local SMALL = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium)
local BOLD = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)
local TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function make(className: string, properties: {[string]: any}, parent: Instance?): Instance
	local object = Instance.new(className)
	for property, value in pairs(properties) do object[property] = value end
	object.Parent = parent
	return object
end

local function round(object: Instance, radius: number)
	make("UICorner", {CornerRadius = UDim.new(0, radius)}, object)
end

local function outline(object: Instance, color: Color3?, transparency: number?)
	return make("UIStroke", {Color = color or CodexUI.Theme.Border, Transparency = transparency or 0, Thickness = 1}, object)
end

local function animate(object: Instance, properties: {[string]: any})
	local tween = TweenService:Create(object, TWEEN, properties)
	tween:Play()
	return tween
end

local function drag(window: GuiObject, handle: GuiObject)
	local moving, input, origin, position = false, nil, nil, nil
	handle.InputBegan:Connect(function(event)
		if event.UserInputType == Enum.UserInputType.MouseButton1 or event.UserInputType == Enum.UserInputType.Touch then
			moving, origin, position = true, event.Position, window.Position
			event.Changed:Connect(function()
				if event.UserInputState == Enum.UserInputState.End then moving = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(event)
		if event.UserInputType == Enum.UserInputType.MouseMovement or event.UserInputType == Enum.UserInputType.Touch then input = event end
	end)
	UserInputService.InputChanged:Connect(function(event)
		if moving and event == input then
			local delta = event.Position - origin
			window.Position = UDim2.new(position.X.Scale, position.X.Offset + delta.X, position.Y.Scale, position.Y.Offset + delta.Y)
		end
	end)
end

local function setButtonStyle(button: TextButton)
	button.MouseEnter:Connect(function() animate(button, {BackgroundColor3 = CodexUI.Theme.SurfaceHover}) end)
	button.MouseLeave:Connect(function() animate(button, {BackgroundColor3 = CodexUI.Theme.Surface}) end)
end

function CodexUI:CreateWindow(config: {Title: string?, Subtitle: string?, Parent: Instance?, ToggleKey: Enum.KeyCode?})
	config = config or {}
	local parent = config.Parent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local gui = make("ScreenGui", {Name = "CodexUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, parent) :: ScreenGui
	local notifications = make("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(320, 400)}, gui)
	make("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8)}, notifications)

	local shell = make("Frame", {Name = "CodexWindow", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(680, 455), BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0}, gui) :: Frame
	round(shell, 10); outline(shell, self.Theme.Border, .15)
	local header = make("Frame", {BackgroundColor3 = self.Theme.Panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 64)}, shell) :: Frame
	round(header, 10)
	make("Frame", {BackgroundColor3 = self.Theme.Panel, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10)}, header)
	make("TextLabel", {BackgroundTransparency = 1, Text = ">_ " .. (config.Title or "CODEX INTERFACE"), FontFace = BOLD, TextSize = 17, TextColor3 = self.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -100, 0, 22)}, header)
	make("TextLabel", {BackgroundTransparency = 1, Text = config.Subtitle or "Ready for instruction", FontFace = SMALL, TextSize = 12, TextColor3 = self.Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 34), Size = UDim2.new(1, -100, 0, 18)}, header)
	local live = make("TextLabel", {BackgroundTransparency = 1, Text = "● LIVE", FontFace = BOLD, TextSize = 11, TextColor3 = self.Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -18, 0, 14), Size = UDim2.fromOffset(65, 18)}, header)
	local close = make("TextButton", {Text = "×", FontFace = BOLD, TextSize = 22, TextColor3 = self.Theme.Muted, BackgroundTransparency = 1, Position = UDim2.new(1, -44, 0, 32), Size = UDim2.fromOffset(30, 24)}, header) :: TextButton
	close.Activated:Connect(function() gui:Destroy() end)
	close.MouseEnter:Connect(function() animate(close, {TextColor3 = self.Theme.Danger}) end)
	close.MouseLeave:Connect(function() animate(close, {TextColor3 = self.Theme.Muted}) end)

	local sidebar = make("Frame", {BackgroundColor3 = self.Theme.Panel, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(0, 168, 1, -64)}, shell)
	local tabs = make("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 14), Size = UDim2.new(1, -20, 1, -28), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 2, ScrollBarImageColor3 = self.Theme.Border}, sidebar)
	make("UIListLayout", {Padding = UDim.new(0, 5)}, tabs)
	local content = make("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(168, 64), Size = UDim2.new(1, -168, 1, -64)}, shell)
	make("Frame", {BackgroundColor3 = self.Theme.Border, BorderSizePixel = 0, Position = UDim2.fromOffset(168, 64), Size = UDim2.new(0, 1, 1, -64)}, shell)
	drag(shell, header)

	local window = {Gui = gui, Instance = shell, Tabs = {}, CurrentTab = nil}
	function window:Notify(data: {Title: string?, Content: string?, Duration: number?})
		data = data or {}
		local card = make("Frame", {BackgroundColor3 = CodexUI.Theme.Surface, BorderSizePixel = 0, Size = UDim2.fromOffset(310, 0), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true}, notifications)
		round(card, 7); outline(card, CodexUI.Theme.Border, .2)
		make("Frame", {BackgroundColor3 = CodexUI.Theme.Accent, BorderSizePixel = 0, Size = UDim2.fromOffset(3, 50)}, card)
		local text = make("TextLabel", {BackgroundTransparency = 1, Text = "[" .. (data.Title or "SYSTEM") .. "]\n" .. (data.Content or ""), FontFace = SMALL, TextColor3 = CodexUI.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, card)
		make("UIPadding", {PaddingBottom = UDim.new(0, 10)}, card)
		task.delay(data.Duration or 4, function() if card.Parent then animate(card, {BackgroundTransparency = 1}); task.wait(.18); card:Destroy() end end)
	end
	function window:Toggle(state: boolean?) gui.Enabled = state == nil and not gui.Enabled or state == true end
	UserInputService.InputBegan:Connect(function(input, processed) if not processed and input.KeyCode == (config.ToggleKey or Enum.KeyCode.RightShift) then window:Toggle() end end)

	function window:CreateTab(data: {Name: string?, Icon: string?})
		data = data or {}
		local tab = {Order = 0}
		local tabButton = make("TextButton", {Text = (data.Icon and data.Icon .. "  " or "") .. (data.Name or "New Tab"), FontFace = SMALL, TextSize = 13, TextColor3 = CodexUI.Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = CodexUI.Theme.Surface, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 34)}, tabs) :: TextButton
		round(tabButton, 6)
		local page = make("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Position = UDim2.fromOffset(16, 16), Size = UDim2.new(1, -32, 1, -32), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 3, ScrollBarImageColor3 = CodexUI.Theme.Border}, content)
		make("UIListLayout", {Padding = UDim.new(0, 8)}, page)
		local function choose()
			for _, other in ipairs(window.Tabs) do other.Page.Visible = false; animate(other.Button, {BackgroundTransparency = 1, TextColor3 = CodexUI.Theme.Muted}) end
			window.CurrentTab = tab; page.Visible = true; animate(tabButton, {BackgroundTransparency = 0, TextColor3 = CodexUI.Theme.Accent})
		end
		tabButton.Activated:Connect(choose)
		tab.Button, tab.Page = tabButton, page
		table.insert(window.Tabs, tab); if #window.Tabs == 1 then choose() end
