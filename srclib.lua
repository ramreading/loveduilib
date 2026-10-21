local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local setClipboard = setclipboard or toclipboard or writeclipboard or write_clipboard
	or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)

local Theme = {
	Background   = Color3.new(0, 0, 0),
	Secondary    = Color3.new(0, 0, 0),
	Element      = Color3.new(0, 0, 0),
	ElementHover = Color3.fromRGB(30, 0, 0),
	Off          = Color3.new(0, 0, 0),
	Border       = Color3.fromRGB(220, 0, 0),
	BorderHover  = Color3.fromRGB(255, 30, 30),
	Text         = Color3.new(1, 1, 1),
	SubText      = Color3.fromRGB(220, 220, 220),
	Warning      = Color3.fromRGB(255, 190, 70),
	Accent       = Color3.fromRGB(220, 0, 0),
}

local FONT_TITLE = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold)
local FONT_MAIN  = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)

local BORDER = 3
local TI     = TweenInfo.new(0.10, Enum.EasingStyle.Linear)

local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in props do if k ~= "Parent" then inst[k] = v end end
	if children then for _, c in children do c.Parent = inst end end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function box(class, props, children)
	props.BorderSizePixel = BORDER
	props.BorderColor3    = props.BorderColor3 or Theme.Border
	return create(class, props, children)
end

local function tween(obj, props)
	local t = TweenService:Create(obj, TI, props)
	t:Play()
	return t
end

local function makeDraggable(frame, handle)
	local dragging, dragInput, startPos, startFramePos
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = inp.Position
			startFramePos = frame.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			dragInput = inp
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if inp == dragInput and dragging then
			local delta = inp.Position - startPos
			frame.Position = UDim2.new(
				startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
				startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
		end
	end)
end

local function bindDrag(region, onUpdate)
	local dragging = false
	local function upd(inp)
		local ap, sz = region.AbsolutePosition, region.AbsoluteSize
		onUpdate(
			math.clamp((inp.Position.X - ap.X) / sz.X, 0, 1),
			math.clamp((inp.Position.Y - ap.Y) / sz.Y, 0, 1))
	end
	region.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; upd(inp)
		end
	end)
	region.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging then upd(inp) end
	end)
end

local function getGuiParent()
	if gethui then return gethui() end
	local ok, cg = pcall(function()
		return (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
	end)
	return ok and cg or game:GetService("CoreGui")
end

local Library = {}
Library.__index = Library

local ScreenGui = create("ScreenGui", {
	Name = "c00lguiReborn",
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = getGuiParent()

local NotifHolder = create("Frame", {
	Name = "Notifications", BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 260, 1, -32), Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

function Library:Notify(cfg)
	cfg = cfg or {}
	local dur = cfg.Duration or 4
	local card = box("Frame", {
		BackgroundColor3 = Theme.Background,
		Size = UDim2.new(0, 260, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true, Parent = NotifHolder,
	})
	local accent = create("Frame", {
		BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0), Parent = card,
	})
	local content = create("Frame", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9) }),
	})
	create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Title or "Notification",
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1, Parent = content,
	})
	if cfg.Content then
		create("TextLabel", {
			BackgroundTransparency = 1, Text = cfg.Content,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, Parent = content,
		})
	end
	task.delay(dur, function() card:Destroy() end)
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}

	local W, H = cfg.Width or 560, cfg.Height or 420
	local Window = { Tabs = {}, _current = nil, _index = 0 }

	local BG = box("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = Theme.Background,
		BorderColor3 = Theme.Border,
		BorderSizePixel = BORDER,
		Parent = ScreenGui,
	})

	local Title = box("TextLabel", {
		Name = "Title", BackgroundColor3 = Theme.Background,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 40),
		FontFace = FONT_TITLE, TextSize = 20,
		Text = cfg.Title or "c00lgui Reborn",
		TextColor3 = Theme.Text,
		Parent = BG,
	})

	local NavLeft = box("TextButton", {
		Name = "<", BackgroundColor3 = Theme.Background,
		Position = UDim2.new(0, 0, 0, 43),
		Size = UDim2.new(0.5, -2, 0, 40),
		FontFace = FONT_TITLE, TextSize = 32, Text = "<",
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Center,
		AutoButtonColor = false, Parent = BG,
	})
	local NavRight = box("TextButton", {
		Name = ">", BackgroundColor3 = Theme.Background,
		Position = UDim2.new(0.5, 2, 0, 43),
		Size = UDim2.new(0.5, -2, 0, 40),
		FontFace = FONT_TITLE, TextSize = 32, Text = ">",
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Center,
		AutoButtonColor = false, Parent = BG,
	})

	local PageHost = create("Frame", {
		Name = "Pages", BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 86),
		Size = UDim2.new(1, 0, 1, -110),
		Parent = BG,
	})

	local Close = box("TextButton", {
		Name = "Close", BackgroundColor3 = Theme.Background,
		Position = UDim2.new(0, 0, 1, -20),
		Size = UDim2.new(1, 0, 0, 20),
		FontFace = FONT_MAIN, TextSize = 14, Text = "Close",
		TextColor3 = Theme.Text, AutoButtonColor = false, Parent = BG,
	})

	local function navHover(btn)
		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundColor3 = Theme.ElementHover })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundColor3 = Theme.Background })
		end)
	end
	navHover(NavLeft); navHover(NavRight)

	makeDraggable(BG, Title)

	Close.Activated:Connect(function()
		PageHost.Visible = not PageHost.Visible
		Close.Text = PageHost.Visible and "Close" or "Open"
	end)

	local hidden = false
	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == (cfg.ToggleKey or Enum.KeyCode.RightShift) then
			hidden = not hidden
			BG.Visible = not hidden
		end
	end)

	function Window:CreateTab(tcfg)
		tcfg = tcfg or {}
		local Tab = { _order = 0, _left = {}, _right = {} }
		Window._index += 1
		local myIndex = Window._index

		local page = create("ScrollingFrame", {
			Name = tcfg.Name or "Tab",
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Border,
			Visible = false,
			Parent = PageHost,
		}, {
			create("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
			}),
		})

		local rowCount = 0
		local function nextSlot(side)
			rowCount += (side == "left" and 1 or 0)
			return rowCount
		end

		local function place(el, height)
			local side = (#Tab._left <= #Tab._right) and "left" or "right"
			local order = math.max(#Tab._left, #Tab._right) + 1
			local row = box("Frame", {
				BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = UDim2.new(0.5, -3, 0, height or 30),
				LayoutOrder = order,
				Parent = page,
			})
			el.Parent = row
			el.Size = UDim2.new(1, 0, 1, 0)
			el.Position = UDim2.new(0, 0, 0, 0)
			if side == "left" then Tab._left[#Tab._left + 1] = row
			else Tab._right[#Tab._right + 1] = row end
			row.Position = UDim2.new(0, 0, 0, 0)
			return row
		end

		page:ClearAllChildren()
		local grid = create("UIGridLayout", {
			CellSize = UDim2.new(0.5, -2, 0, 32),
			CellPadding = UDim2.new(0, 2, 0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})
		create("UIPadding", {
			PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
			Parent = page,
		})

		local function select()
			if Window._current == Tab then return end
			for _, t in Window.Tabs do t._page.Visible = false end
			Window._current = Tab
			page.Visible = true
		end

		Tab._page = page
		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then select() end

		NavRight.Activated:Connect(function()
			local idx = table.find(Window.Tabs, Window._current)
			Window.Tabs[((idx or 1) % #Window.Tabs) + 1]._page.Visible = true
			Window.Tabs[idx]._page.Visible = false
			Window._current = Window.Tabs[((idx or 1) % #Window.Tabs) + 1]
		end)
		NavLeft.Activated:Connect(function()
			local idx = table.find(Window.Tabs, Window._current)
			local newIdx = idx - 1
			if newIdx < 1 then newIdx = #Window.Tabs end
			Window.Tabs[idx]._page.Visible = false
			Window.Tabs[newIdx]._page.Visible = true
			Window._current = Window.Tabs[newIdx]
		end)

		local function push(el)
			Tab._order += 1
			el.LayoutOrder = Tab._order
			el.Parent = page
			return el
		end

		local function styledButton(text, cb)
			local b = box("TextButton", {
				BackgroundColor3 = Theme.Background,
				FontFace = FONT_MAIN, TextSize = 14, Text = text or "Button",
				TextColor3 = Theme.Text, AutoButtonColor = false,
			})
			b.MouseEnter:Connect(function()
				tween(b, { BorderColor3 = Theme.BorderHover, BackgroundColor3 = Theme.ElementHover })
			end)
			b.MouseLeave:Connect(function()
				tween(b, { BorderColor3 = Theme.Border, BackgroundColor3 = Theme.Background })
			end)
			b.Activated:Connect(function()
				tween(b, { BackgroundColor3 = Theme.Border })
				task.wait(0.08)
				tween(b, { BackgroundColor3 = Theme.Background })
				if cb then task.spawn(cb) end
			end)
			return b
		end

		function Tab:CreateLabel(text)
			return {
				Set = function(_, t) end,
			}
		end

		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			local b = styledButton(bcfg.Name or "Button", bcfg.Callback)
			push(b)
			return { Instance = b }
		end

		function Tab:CreateToggle(tocfg)
			tocfg = tocfg or {}
			local state = tocfg.Default or false
			local b = box("TextButton", {
				BackgroundColor3 = Theme.Background,
				FontFace = FONT_MAIN, TextSize = 14,
				Text = tocfg.Name or "Toggle",
				TextColor3 = Theme.Text, AutoButtonColor = false,
			})
			local ind = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.new(0, 40, 1, 0),
				FontFace = FONT_TITLE, TextSize = 13,
				Text = state and "ON" or "OFF",
				TextColor3 = state and Theme.Border or Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = b,
			})
			local api = {}
			function api:Set(v)
				state = v
				ind.Text = state and "ON" or "OFF"
				ind.TextColor3 = state and Theme.Border or Theme.SubText
				if tocfg.Callback then task.spawn(tocfg.Callback, state) end
			end
			b.Activated:Connect(function() api:Set(not state) end)
			if state and tocfg.Callback then task.spawn(tocfg.Callback, true) end
			push(b)
			api.Instance = b
			return api
		end

		function Tab:CreateStat(scfg)
			scfg = scfg or {}
			local f = box("Frame", { BackgroundColor3 = Theme.Background })
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0.5, -8, 1, 0),
				FontFace = FONT_MAIN, TextSize = 13, Text = scfg.Name or "Stat",
				TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
			})
			local val = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.new(0.5, -8, 1, 0),
				FontFace = FONT_TITLE, TextSize = 13, Text = tostring(scfg.Value or "-"),
				TextColor3 = Theme.Border, TextXAlignment = Enum.TextXAlignment.Right, Parent = f,
			})
			push(f)
			return { Set = function(_, v) val.Text = tostring(v) end, Instance = f }
		end

		function Tab:CreateSlider(slcfg)
			slcfg = slcfg or {}
			local min, max = slcfg.Min or 0, slcfg.Max or 100
			local inc = slcfg.Increment or 1
			local value = math.clamp(slcfg.Default or min, min, max)
			local f = box("Frame", { BackgroundColor3 = Theme.Background })
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 3), Size = UDim2.new(1, -70, 0, 14),
				FontFace = FONT_MAIN, TextSize = 12, Text = slcfg.Name or "Slider",
				TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
			})
			local val = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 3),
				Size = UDim2.new(0, 60, 0, 14),
				FontFace = FONT_TITLE, TextSize = 12, Text = tostring(value),
				TextColor3 = Theme.Border, TextXAlignment = Enum.TextXAlignment.Right, Parent = f,
			})
			local track = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(30, 0, 0), BorderSizePixel = 0,
				Position = UDim2.new(0, 8, 1, -9), Size = UDim2.new(1, -16, 0, 3),
				Parent = f,
			})
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0), Parent = track,
			})
			local knob = box("Frame", {
				BackgroundColor3 = Theme.Border,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.fromOffset(8, 8), ZIndex = 2, Parent = track,
			})
			local api = {}
			local function apply(alpha, fire)
				local raw = min + (max - min) * alpha
				value = math.clamp(math.floor(raw / inc + 0.5) * inc, min, max)
				local a = (max - min) == 0 and 0 or (value - min) / (max - min)
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				val.Text = tostring(value)
				if fire and slcfg.Callback then task.spawn(slcfg.Callback, value) end
			end
			bindDrag(track, function(ax) apply(ax, true) end)
			function api:Set(v) apply((math.clamp(v, min, max) - min) / (max - min), true) end
			function api:Get() return value end
			push(f)
			api.Instance = f
			return api
		end

		function Tab:CreateTextbox(txcfg)
			txcfg = txcfg or {}
			local f = box("Frame", { BackgroundColor3 = Theme.Background })
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0.4, -8, 1, 0),
				FontFace = FONT_MAIN, TextSize = 13, Text = txcfg.Name or "Textbox",
				TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
			})
			local tb = box("TextBox", {
				BackgroundColor3 = Theme.Background,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.new(0.55, 0, 0, 22),
				FontFace = FONT_MAIN, TextSize = 13, Text = txcfg.Default or "",
				PlaceholderText = txcfg.Placeholder or "...",
				PlaceholderColor3 = Theme.SubText,
				TextColor3 = Theme.Text, ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = f,
			})
			tb.Focused:Connect(function() tween(tb, { BorderColor3 = Theme.BorderHover }) end)
			tb.FocusLost:Connect(function()
				tween(tb, { BorderColor3 = Theme.Border })
				if txcfg.Callback then task.spawn(txcfg.Callback, tb.Text) end
			end)
			push(f)
			return {
				Set = function(_, t) tb.Text = t end,
				Get = function() return tb.Text end,
				Instance = f,
			}
		end

		function Tab:CreateDropdown(dcfg)
			dcfg = dcfg or {}
			local options = dcfg.Options or {}
			local multi = dcfg.Multi or false
			local selected = {}
			if dcfg.Default then
				if type(dcfg.Default) == "table" then for _, d in dcfg.Default do selected[d] = true end
				else selected[dcfg.Default] = true end
			end
			local f = box("Frame", { BackgroundColor3 = Theme.Background, ClipsDescendants = true })
			f.Size = UDim2.new(0.5, -2, 0, 32)
			local header = box("TextButton", {
				BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 32),
				FontFace = FONT_MAIN, TextSize = 13, Text = dcfg.Name or "Dropdown",
				TextColor3 = Theme.Text, AutoButtonColor = false, Parent = f,
			})
			local list = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 32),
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false, Parent = f,
			}, {
				create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
			})
			local function rebuild()
				for _, c in list:GetChildren() do
					if c:IsA("TextButton") then c:Destroy() end
				end
				for i, opt in options do
					local ob = box("TextButton", {
						BackgroundColor3 = Theme.Background,
						Size = UDim2.new(1, 0, 0, 26), LayoutOrder = i,
						FontFace = FONT_MAIN, TextSize = 12,
						Text = (selected[opt] and "[x] " or "[ ] ") .. opt,
						TextColor3 = selected[opt] and Theme.Border or Theme.SubText,
						AutoButtonColor = false, Parent = list,
					})
					ob.Activated:Connect(function()
						if multi then selected[opt] = not selected[opt]
						else
							table.clear(selected); selected[opt] = true
						end
						rebuild()
						if dcfg.Callback then
							if multi then
								local out = {}
								for _, o in options do if selected[o] then table.insert(out, o) end end
								task.spawn(dcfg.Callback, out)
							else task.spawn(dcfg.Callback, opt) end
						end
					end)
				end
			end
			local open = false
			header.Activated:Connect(function()
				open = not open
				list.Visible = open
				f.Size = UDim2.new(0.5, -2, 0, open and (32 + #options * 28 + 4) or 32)
			end)
			local api = {}
			function api:Set(val)
				table.clear(selected)
				if type(val) == "table" then for _, x in val do selected[x] = true end
				else selected[val] = true end
				rebuild()
			end
			function api:Get()
				local out = {}
				for _, o in options do if selected[o] then table.insert(out, o) end end
				return multi and out or out[1]
			end
			api.Instance = f
			rebuild()
			push(f)
			return api
		end

		function Tab:CreateColorPicker(ccfg)
			ccfg = ccfg or {}
			local color = ccfg.Default or Color3.fromRGB(255, 0, 0)
			local f = box("Frame", { BackgroundColor3 = Theme.Background })
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -50, 1, 0),
				FontFace = FONT_MAIN, TextSize = 13, Text = ccfg.Name or "Color",
				TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
			})
			local swatch = box("Frame", {
				BackgroundColor3 = color,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(28, 18), Parent = f,
			})
			local api = {}
			function api:Set(c) color = c; swatch.BackgroundColor3 = c; if ccfg.Callback then task.spawn(ccfg.Callback, c) end end
			function api:Get() return color end
			api.Instance = f
			push(f)
			return api
		end

		return Tab
	end

	Window.Instance = BG
	return Window
end

return Library
