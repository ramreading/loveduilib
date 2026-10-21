-- based on vaehz lib — recolored to coolgui / c00lkidd red theme
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local setClipboard = setclipboard or toclipboard or writeclipboard or write_clipboard
	or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

-- ── c00lkidd / coolgui red theme ─────────────────────────────────────────
local Theme = {
	Background   = Color3.fromRGB(10, 6, 8),      -- near-black with red tint
	Secondary    = Color3.fromRGB(18, 10, 12),    -- dark maroon
	Element      = Color3.fromRGB(24, 12, 16),    -- element bg
	ElementHover = Color3.fromRGB(38, 16, 22),    -- hover
	Off          = Color3.fromRGB(48, 20, 26),    -- toggle off track
	Stroke       = Color3.fromRGB(220, 40, 60),   -- bright red stroke
	Text         = Color3.fromRGB(255, 235, 235), -- warm white
	SubText      = Color3.fromRGB(200, 130, 140), -- muted red-grey
	Warning      = Color3.fromRGB(255, 90, 70),
	Accent       = Color3.fromRGB(220, 25, 45),   -- c00lkidd red
	AccentGlow   = Color3.fromRGB(255, 60, 80),
	Glow         = Color3.fromRGB(120, 0, 20),    -- shadow glow color
}

local BUILDER_ICONS = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"
local FONT_TITLE = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Bold)
local FONT_MAIN  = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Medium)

local TI    = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_S  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_GLOW = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local STROKE_T = 0.55  -- strokes a bit more visible for that neon look

local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then inst[k] = v end
	end
	if children then
		for _, c in children do c.Parent = inst end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

-- Sharper corners (coolgui style) — default 3 instead of 6
local function corner(parent, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r or 3), Parent = parent })
end

local function stroke(parent, color, trans, thick)
	return create("UIStroke", {
		Color = color or Theme.Stroke,
		Transparency = trans or 0.4,
		Thickness = thick or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- Red glow shadow (UIShadow doesn't take Color in vanilla, so we fake with a
-- red ImageLabel-free approach: a blurred UIGradient frame is overkill, so we
-- just use a normal shadow tinted via UIShadow if supported, else skip).
local function addShadow(parent, blur, trans)
	local ok, shadow = pcall(function()
		return create("UIShadow", {
			BlurRadius = UDim.new(0, blur or 16),
			Transparency = trans or 0.5,
			Parent = parent,
		})
	end)
	if ok and shadow then
		-- Newer UIShadow supports Color; guard it
		pcall(function() shadow.Color = Theme.Glow end)
	end
	return ok and shadow or nil
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info or TI, props)
	t:Play()
	return t
end

local function icon(name, size, filled, color)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = name or "",
		FontFace = Font.new(BUILDER_ICONS, filled and Enum.FontWeight.Bold or Enum.FontWeight.Regular),
		TextColor3 = color or Theme.Text,
		TextScaled = true,
		Size = UDim2.fromOffset(size or 18, size or 18),
	})
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
		local ax = math.clamp((inp.Position.X - ap.X) / sz.X, 0, 1)
		local ay = math.clamp((inp.Position.Y - ap.Y) / sz.Y, 0, 1)
		onUpdate(ax, ay)
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
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			upd(inp)
		end
	end)
end

local function getGuiParent()
	if gethui then return gethui() end
	local ok, cg = pcall(function()
		return (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
	end)
	return ok and cg or game:GetService("CoreGui")
end

local function copyToClipboard(str)
	if not setClipboard then return false end
	return pcall(setClipboard, str)
end

local Library = {}
Library.__index = Library

local ScreenGui = create("ScreenGui", {
	Name = "robloxscriptsUI",
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = getGuiParent()

local NotifHolder = create("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 260, 1, -32),
	Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

function Library:Notify(cfg)
	cfg = cfg or {}
	local dur = cfg.Duration or 4

	local card = create("Frame", {
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 260, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = NotifHolder,
	})
	corner(card, 3)
	local st = stroke(card, Theme.Accent, 1)
	addShadow(card, 14, 0.55)

	local accent = create("Frame", {
		BackgroundColor3 = Theme.AccentGlow, BackgroundTransparency = 1,
		Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, Parent = card,
	})

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11) }),
	})

	local titleLbl = create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Title or "Notification", TextTransparency = 1,
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1, Parent = content,
	})
	local bodyLbl
	if cfg.Content then
		bodyLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = cfg.Content, TextTransparency = 1,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, Parent = content,
		})
	end

	card.Position = UDim2.new(0, 26, 0, 0)
	tween(card, TI_S, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
	tween(st, TI_S, { Transparency = STROKE_T })
	tween(accent, TI_S, { BackgroundTransparency = 0 })
	tween(titleLbl, TI_S, { TextTransparency = 0 })
	if bodyLbl then tween(bodyLbl, TI_S, { TextTransparency = 0 }) end

	task.delay(dur, function()
		tween(card, TI, { BackgroundTransparency = 1, Position = UDim2.new(0, 26, 0, 0) })
		tween(st, TI, { Transparency = 1 })
		tween(accent, TI, { BackgroundTransparency = 1 })
		tween(titleLbl, TI, { TextTransparency = 1 })
		if bodyLbl then tween(bodyLbl, TI, { TextTransparency = 1 }) end
		task.wait(0.2)
		card:Destroy()
	end)
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	if cfg.Accent then Theme.Accent = cfg.Accent end

	local Window = { Tabs = {}, _current = nil }

	local BG = create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(532, 410),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		Parent = ScreenGui,
	})
	corner(BG, 4)
	local bgStroke = stroke(BG, Theme.Accent, 0.35, 1.5)
	addShadow(BG, 28, 0.4)

	-- subtle pulsing red glow on the window border (coolgui vibe)
	task.spawn(function()
		while BG.Parent do
			tween(bgStroke, TI_GLOW, { Transparency = 0.7 })
			task.wait(1.2)
			tween(bgStroke, TI_GLOW, { Transparency = 0.35 })
			task.wait(1.2)
		end
	end)

	local TopBar = create("Frame", {
		Name = "TopBar",
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 45),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = BG,
	})
	stroke(TopBar, Theme.Accent, STROKE_T)
	addShadow(TopBar, 12, 0.7)

	-- accent underline on topbar for the coolgui look
	create("Frame", {
		Name = "AccentLine",
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 6,
		Parent = TopBar,
	})

	create("TextLabel", {
		Name = "Title", Text = cfg.Title or "c00lkidd hub",
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.new(0, 300, 0, 22),
		Parent = TopBar,
	})

	local function ctrlBtn(iconName, offsetX, hoverColor)
		local b = create("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offsetX, 0.5, 0), Size = UDim2.fromOffset(26, 26),
			Parent = TopBar,
		})
		corner(b, 3)
		local ic = icon(iconName, 16, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = b
		b.MouseEnter:Connect(function()
			tween(b, TI, { BackgroundTransparency = 0 })
			tween(ic, TI, { TextColor3 = hoverColor or Theme.Accent })
		end)
		b.MouseLeave:Connect(function()
			tween(b, TI, { BackgroundTransparency = 1 })
			tween(ic, TI, { TextColor3 = Theme.SubText })
		end)
		return b
	end

	local CloseBtn = ctrlBtn("x", -10, Color3.fromRGB(255, 70, 70))
	local MinBtn   = ctrlBtn("minus", -42, Theme.Accent)

	local MoonBtn = create("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -74, 0.5, 0), Size = UDim2.fromOffset(26, 26),
		Parent = TopBar,
	})
	corner(MoonBtn, 3)
	local moonIcon = icon("moon", 16, false, Theme.SubText)
	moonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	moonIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	moonIcon.Parent = MoonBtn

	MoonBtn.MouseEnter:Connect(function()
		tween(MoonBtn, TI, { BackgroundTransparency = 0 })
		tween(moonIcon, TI, { TextColor3 = Theme.AccentGlow })
	end)
	MoonBtn.MouseLeave:Connect(function()
		tween(MoonBtn, TI, { BackgroundTransparency = 1 })
		tween(moonIcon, TI, { TextColor3 = Theme.SubText })
	end)

	local PROFILE_LINK = "https://robloxscripts.com/user/ramread"
	MoonBtn.Activated:Connect(function()
		local copied = copyToClipboard(PROFILE_LINK)
		Library:Notify({
			Title = "robloxscripts Link",
			Content = copied and "Profile link copied to clipboard!" or "Clipboard unavailable: " .. PROFILE_LINK,
			Duration = 3,
		})
	end)

	local Body = create("Frame", {
		Name = "Body", BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(1, 0, 1, -45),
		Parent = BG,
	})

	local TabList = create("ScrollingFrame", {
		Name = "TabList", BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, Size = UDim2.new(0, 140, 1, 0),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.4,
		Parent = Body,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})

	local Content = create("Frame", {
		Name = "Content", BackgroundTransparency = 1,
		Position = UDim2.new(0, 141, 0, 0), Size = UDim2.new(1, -141, 1, 0),
		Parent = Body,
	})

	create("Frame", {
		Name = "SideDivider", BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.6,
		BorderSizePixel = 0, Position = UDim2.new(0, 140, 0, 0), Size = UDim2.new(0, 1, 1, 0),
		ZIndex = 2, Parent = Body,
	})

	makeDraggable(BG, TopBar)

	CloseBtn.Activated:Connect(function()
		tween(BG, TI, { GroupTransparency = 1, Size = UDim2.fromOffset(BG.AbsoluteSize.X, 0) })
		task.wait(0.18); ScreenGui:Destroy()
	end)

	local minimized = false
	MinBtn.Activated:Connect(function()
		minimized = not minimized
		if minimized then
			Body.Visible = false
			tween(BG, TI_S, { Size = UDim2.fromOffset(532, 45) })
		else
			tween(BG, TI_S, { Size = UDim2.fromOffset(532, 410) })
			task.wait(0.12); Body.Visible = true
		end
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
		local Tab = { _order = 0 }

		local btn = create("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34),
			Parent = TabList,
		})
		corner(btn, 3)

		local ic = icon(tcfg.Icon or "circle", 18, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0, 0.5)
		ic.Position = UDim2.new(0, 8, 0.5, 0)
		ic.Parent = btn

		local nameLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = tcfg.Name or "Tab",
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 34, 0.5, 0),
			Size = UDim2.new(1, -40, 1, 0), Parent = btn,
		})

		local pageWrap = create("CanvasGroup", {
			Name = "Page", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), Visible = false, GroupTransparency = 0,
			Parent = Content,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.4,
			Parent = pageWrap,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
			}),
		})

		local function select()
			if Window._current == Tab then return end
			for _, t in Window.Tabs do
				if t ~= Tab then t._wrap.Visible = false end
				tween(t._btn, TI, { BackgroundTransparency = 1 })
				tween(t._icon, TI, { TextColor3 = Theme.SubText })
				tween(t._name, TI, { TextColor3 = Theme.SubText })
			end
			Window._current = Tab
			pageWrap.Visible = true
			pageWrap.GroupTransparency = 1
			pageWrap.Position = UDim2.new(0.04, 0, 0, 0)
			tween(pageWrap, TI_S, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
			tween(btn, TI, { BackgroundTransparency = 0 })
			tween(ic, TI, { TextColor3 = Theme.AccentGlow })
			tween(nameLbl, TI, { TextColor3 = Theme.Text })
		end

		btn.MouseEnter:Connect(function()
			if not pageWrap.Visible then tween(btn, TI, { BackgroundTransparency = 0.6 }) end
		end)
		btn.MouseLeave:Connect(function()
			if not pageWrap.Visible then tween(btn, TI, { BackgroundTransparency = 1 }) end
		end)
		btn.Activated:Connect(select)

		Tab._btn, Tab._icon, Tab._name, Tab._page, Tab._wrap, Tab._select = btn, ic, nameLbl, page, pageWrap, select
		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then select() end

		local function newRow(height)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, height or 34),
				LayoutOrder = Tab._order, BorderSizePixel = 0, Parent = page,
			})
			corner(row, 3)
			stroke(row, Theme.Accent, STROKE_T)
			return row
		end

		function Tab:CreateLabel(text)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Label",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -8, 0, 0),
				Position = UDim2.new(0, 4, 0, 0), Parent = row,
			})
			create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = row })
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		function Tab:CreateWarning(text)
			local row = newRow(0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundColor3 = Color3.fromRGB(40, 14, 16)
			for _, s in row:GetChildren() do if s:IsA("UIStroke") then s.Color = Theme.Warning; s.Transparency = 0.5 end end
			create("UIPadding", {
				PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9),
				PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = row,
			})
			local ico = icon("triangle-exclamation", 18, false, Theme.Warning)
			ico.AnchorPoint = Vector2.new(0, 0.5)
			ico.Position = UDim2.new(0, 0, 0.5, 0)
			ico.Parent = row
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Warning",
				FontFace = FONT_MAIN, TextColor3 = Theme.Warning, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -28, 0, 0), Position = UDim2.new(0, 28, 0, 0), Parent = row,
			})
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			Tab._order += 1
			local btnEl = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, 36), LayoutOrder = Tab._order, BorderSizePixel = 0, Parent = page,
			})
			corner(btnEl, 3); stroke(btnEl, Theme.Accent, STROKE_T)
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = bcfg.Name or "Button",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				Size = UDim2.new(1, 0, 1, 0), Parent = btnEl,
			})
			btnEl.MouseEnter:Connect(function()
				tween(btnEl, TI, { BackgroundColor3 = Theme.ElementHover })
				tween(lbl, TI, { TextColor3 = Theme.AccentGlow })
			end)
			btnEl.MouseLeave:Connect(function()
				tween(btnEl, TI, { BackgroundColor3 = Theme.Element })
				tween(lbl, TI, { TextColor3 = Theme.Text })
			end)
			btnEl.Activated:Connect(function()
				tween(btnEl, TI, { BackgroundColor3 = Theme.Accent })
				tween(lbl, TI, { TextColor3 = Theme.Text })
				task.wait(0.12); tween(btnEl, TI, { BackgroundColor3 = Theme.Element })
				if bcfg.Callback then task.spawn(bcfg.Callback) end
			end)
			return { Instance = btnEl }
		end

		function Tab:CreateToggle(tocfg)
			tocfg = tocfg or {}
			local state = tocfg.Default or false
			local row = newRow(36)
			local btnEl = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = tocfg.Name or "Toggle",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -70, 1, 0), Parent = btnEl,
			})
			local track = create("Frame", {
				BackgroundColor3 = state and Theme.Accent or Theme.Off,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(40, 20), BorderSizePixel = 0, Parent = btnEl,
			})
			corner(track, 10)
			stroke(track, Theme.Accent, state and 0.2 or 0.6)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Text, AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0, Parent = track,
			})
			corner(knob, 8)

			local api = {}
			function api:Set(v)
				state = v
				tween(track, TI, { BackgroundColor3 = state and Theme.Accent or Theme.Off })
				tween(knob, TI, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
				for _, s in track:GetChildren() do
					if s:IsA("UIStroke") then tween(s, TI, { Transparency = state and 0.2 or 0.6 }) end
				end
				if tocfg.Callback then task.spawn(tocfg.Callback, state) end
			end
			function api:Get() return state end
			btnEl.Activated:Connect(function() api:Set(not state) end)
			if state and tocfg.Callback then task.spawn(tocfg.Callback, true) end
			api.Instance = row
			return api
		end

		function Tab:CreateStat(scfg)
			scfg = scfg or {}
			local row = newRow(34)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = scfg.Name or "Stat",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.5, -10, 1, 0), Parent = row,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(scfg.Value or "-"),
				FontFace = FONT_TITLE, TextColor3 = Theme.AccentGlow, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0.5, -10, 1, 0), Parent = row,
			})
			return { Set = function(_, v) valLbl.Text = tostring(v) end, Instance = row }
		end

		function Tab:CreateSlider(slcfg)
			slcfg = slcfg or {}
			local min, max = slcfg.Min or 0, slcfg.Max or 100
			local inc = slcfg.Increment or 1
			local value = math.clamp(slcfg.Default or min, min, max)
			local row = newRow(50)

			create("TextLabel", {
				BackgroundTransparency = 1, Text = slcfg.Name or "Slider",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 10, 0, 6),
				Size = UDim2.new(1, -70, 0, 16), Parent = row,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(value),
				FontFace = FONT_TITLE, TextColor3 = Theme.AccentGlow, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 6), Size = UDim2.new(0, 60, 0, 16), Parent = row,
			})
			local track = create("Frame", {
				BackgroundColor3 = Theme.Off, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 1, -14), Size = UDim2.new(1, -20, 0, 6),
				BorderSizePixel = 0, Parent = row,
			})
			corner(track, 3)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent, Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
				BorderSizePixel = 0, Parent = track,
			})
			corner(fill, 3)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Text, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, ZIndex = 2, Parent = track,
			})
			corner(knob, 7)
			stroke(knob, Theme.Accent, 0.2)

			local api = {}
			local function apply(alpha, fire)
				local raw = min + (max - min) * alpha
				value = math.clamp(math.floor(raw / inc + 0.5) * inc, min, max)
				local a = (max - min) == 0 and 0 or (value - min) / (max - min)
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				valLbl.Text = tostring(value)
				if fire and slcfg.Callback then task.spawn(slcfg.Callback, value) end
			end
			bindDrag(track, function(ax) apply(ax, true) end)
			function api:Set(v) apply((math.clamp(v, min, max) - min) / (max - min), true) end
			function api:Get() return value end
			api.Instance = row
			return api
		end

		function Tab:CreateTextbox(txcfg)
			txcfg = txcfg or {}
			local row = newRow(36)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = txcfg.Name or "Textbox",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.4, -10, 1, 0), Parent = row,
			})
			local boxWrap = create("Frame", {
				BackgroundColor3 = Theme.Secondary, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 0, 0, 24),
				AutomaticSize = Enum.AutomaticSize.X, ClipsDescendants = true,
				BorderSizePixel = 0, Parent = row,
			}, {
				create("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }),
			})
			corner(boxWrap, 3)
			local tbStroke = stroke(boxWrap, Theme.Accent, 0.5)
			local tb = create("TextBox", {
				BackgroundTransparency = 1, Text = txcfg.Default or "",
				PlaceholderText = txcfg.Placeholder or "...", PlaceholderColor3 = Theme.SubText,
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 13,
				ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Parent = boxWrap,
			}, {
				create("UISizeConstraint", {
					MinSize = Vector2.new(txcfg.MinWidth or 56, 0),
					MaxSize = Vector2.new(txcfg.MaxWidth or 180, math.huge),
				}),
			})
			tb.Focused:Connect(function() tween(tbStroke, TI, { Color = Theme.AccentGlow, Transparency = 0 }) end)
			tb.FocusLost:Connect(function()
				tween(tbStroke, TI, { Color = Theme.Accent, Transparency = 0.5 })
				if txcfg.Callback then task.spawn(txcfg.Callback, tb.Text) end
			end)
			return {
				Set = function(_, t) tb.Text = t end,
				Get = function() return tb.Text end,
				Instance = row,
			}
		end

		function Tab:CreateColorPicker(ccfg)
			ccfg = ccfg or {}
			local color = ccfg.Default or Color3.fromRGB(255, 0, 0)
			local h, s, v = color:ToHSV()

			local row = newRow(36)
			row.ClipsDescendants = true
			local header = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = ccfg.Name or "Color",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -60, 1, 0), Parent = header,
			})
			local swatch = create("Frame", {
				BackgroundColor3 = color, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(34, 18),
				BorderSizePixel = 0, Parent = header,
			})
			corner(swatch, 3); stroke(swatch, Theme.Accent, 0.4)

			local body = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(1, 0, 0, 130), Visible = false, Parent = row,
			})
			create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = body })

			local sv = create("Frame", {
				BackgroundColor3 = Color3.fromHSV(h, 1, 1), Size = UDim2.new(1, -34, 1, 0),
				BorderSizePixel = 0, Parent = body,
			})
			corner(sv, 3)
			create("Frame", { BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }) }),
				create("UICorner", { CornerRadius = UDim.new(0,3) }),
			})
			create("Frame", { BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0,0,0)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }) }),
				create("UICorner", { CornerRadius = UDim.new(0,3) }),
			})
			local svCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0), Size = UDim2.fromOffset(8, 8),
				BorderSizePixel = 0, ZIndex = 5, Parent = sv,
			})
			corner(svCursor, 4); stroke(svCursor, Color3.new(0,0,0), 0.2)

			local hue = create("Frame", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 22, 1, 0), BorderSizePixel = 0, Parent = body,
			})
			corner(hue, 3)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
				}),
				Parent = hue,
			})
			local hueCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, h, 0), Size = UDim2.new(1, 4, 0, 4),
				BorderSizePixel = 0, ZIndex = 5, Parent = hue,
			})
			corner(hueCursor, 2); stroke(hueCursor, Color3.new(0,0,0), 0.2)

			local function refresh(fire)
				color = Color3.fromHSV(h, s, v)
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(0.5, 0, h, 0)
				swatch.BackgroundColor3 = color
				if fire and ccfg.Callback then task.spawn(ccfg.Callback, color) end
			end
			bindDrag(sv, function(ax, ay) s = ax; v = 1 - ay; refresh(true) end)
			bindDrag(hue, function(_, ay) h = ay; refresh(true) end)

			local open = false
			header.Activated:Connect(function()
				open = not open
				if open then body.Visible = true end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and 172 or 36) })
				if not open then task.delay(0.12, function() if not open then body.Visible = false end end) end
			end)

			local api = {}
			function api:Set(c) h, s, v = c:ToHSV(); refresh(true) end
			function api:Get() return color end
			api.Instance = row
			return api
		end

		function Tab:CreateDropdown(dcfg)
			dcfg = dcfg or {}
			local options = dcfg.Options or {}
			local multi = dcfg.Multi or false
			local selected = {}
			if dcfg.Default then
				if type(dcfg.Default) == "table" then
					for _, d in dcfg.Default do selected[d] = true end
				else selected[dcfg.Default] = true end
			end

			local row = newRow(36)
			row.ClipsDescendants = true
			local header = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = dcfg.Name or "Dropdown",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.5, 0, 1, 0), Parent = header,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = "",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -32, 0.5, 0),
				Size = UDim2.new(0.5, -8, 1, 0), Parent = header,
			})
			local chev = icon("chevron-down", 16, false, Theme.SubText)
			chev.AnchorPoint = Vector2.new(1, 0.5)
			chev.Position = UDim2.new(1, -10, 0.5, 0)
			chev.Parent = header

			local list = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false, Parent = row,
			}, {
				create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
				create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8) }),
			})

			local function updateValLabel()
				local picked = {}
				for _, o in options do if selected[o] then table.insert(picked, o) end end
				valLbl.Text = #picked == 0 and "None" or table.concat(picked, ", ")
			end

			local api = {}
			local optionBtns = {}

			local function rebuild()
				for _, b in optionBtns do b.btn:Destroy() end
				table.clear(optionBtns)
				for i, opt in options do
					local ob = create("TextButton", {
						Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Secondary,
						Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, BorderSizePixel = 0, Parent = list,
					})
					corner(ob, 3)
					local txt = create("TextLabel", {
						BackgroundTransparency = 1, Text = opt, FontFace = FONT_MAIN,
						TextColor3 = selected[opt] and Theme.AccentGlow or Theme.SubText, TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 8, 0, 0),
						Size = UDim2.new(1, -30, 1, 0), Parent = ob,
					})
					local check = icon("check", 14, false, Theme.AccentGlow)
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Position = UDim2.new(1, -8, 0.5, 0)
					check.Visible = selected[opt] == true
					check.Parent = ob

					ob.MouseEnter:Connect(function() tween(ob, TI, { BackgroundColor3 = Theme.ElementHover }) end)
					ob.MouseLeave:Connect(function() tween(ob, TI, { BackgroundColor3 = Theme.Secondary }) end)
					ob.Activated:Connect(function()
						if multi then
							selected[opt] = not selected[opt]
						else
							table.clear(selected); selected[opt] = true
						end
						for _, b in optionBtns do
							local on = selected[b.opt] == true
							b.check.Visible = on
							tween(b.txt, TI, { TextColor3 = on and Theme.AccentGlow or Theme.SubText })
						end
						updateValLabel()
						if dcfg.Callback then
							if multi then
								local out = {}
								for _, o in options do if selected[o] then table.insert(out, o) end end
								task.spawn(dcfg.Callback, out)
							else
								task.spawn(dcfg.Callback, opt)
							end
						end
						if not multi then
							task.wait(0.05)
							api._toggle(false)
						end
					end)
					table.insert(optionBtns, { btn = ob, opt = opt, txt = txt, check = check })
				end
				updateValLabel()
			end

			local function openHeight()
				local n = #options
				if n == 0 then return 44 end
				return 36 + (n * 28) + ((n - 1) * 2) + 8
			end

			local open = false
			function api._toggle(force)
				if force ~= nil then open = force else open = not open end
				if open then list.Visible = true end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and openHeight() or 36) })
				tween(chev, TI, { Rotation = open and 180 or 0, TextColor3 = open and Theme.AccentGlow or Theme.SubText })
				if not open then task.delay(0.12, function() if not open then list.Visible = false end end) end
			end
			header.Activated:Connect(function() api._toggle() end)

			function api:Refresh(newOpts)
				options = newOpts or options
				rebuild()
				if open then api._toggle(true) end
			end
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
			api.Instance = row
			rebuild()
			return api
		end

		return Tab
	end

	Window.Instance = BG
	return Window
end

return Library
