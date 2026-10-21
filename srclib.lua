local Lib = loadstring(game:HttpGet("..."))()
local Win = Lib:CreateWindow({ Title = "c00lgui Reborn", ToggleKey = Enum.KeyCode.RightShift })

local Main = Win:CreateTab({ Name = "Main" })

Main:CreateSection({ Name = "Admin Commands" })
Main:CreateButton({ Name = "i0rb", Callback = function()
    print("i0rb loaded")
end })
Main:CreateButton({ Name = "Rocky2u's Project Duck", Callback = function() print("duck") end })

Main:CreateSection({ Name = "Server Destruction" })
Main:CreateButton({ Name = "Flood", Callback = function()
    game.Workspace.Terrain:FillRegion(Region3int16.new(Vector3int16.new(-100,-100,-100), Vector3int16.new(100,100,100)), 4, Enum.Material.Plastic)
end })
Main:CreateButton({ Name = "Kill All", Callback = function()
    for _, p in game.Players:GetPlayers() do
        if p.Character and p.Character:FindFirstChild("Humanoid") then
            p.Character.Humanoid.Health = 0
        end
    end
end })

local Tools = Win:CreateTab({ Name = "Tools" })
Tools:CreateToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(on)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.MaxHealth = on and math.huge or 100
            char.Humanoid.Health = on and math.huge or 100
        end
    end,
})
Tools:CreateSlider({
    Name = "WalkSpeed",
    Min = 16, Max = 200, Increment = 1, Default = 16,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = v end
    end,
})
Tools:CreateDropdown({
    Name = "Target Player",
    Options = { "Me", "Nearest", "Random" },
    Default = "Me",
    Callback = function(sel) print("target:", sel) end,
})
Tools:CreateTextbox({
    Name = "Custom Gear ID",
    Placeholder = "1234567",
    Callback = function(id) print("gear:", id) end,
})
Tools:CreateColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c) print("color:", c) end,
})
Tools:CreateKeybind({
    Name = "Toggle Feature",
    Default = Enum.KeyCode.Z,
    Callback = function(key) print("pressed:", key.Name) end,
})

Lib:Notify({ Title = "Loaded", Content = "c00lgui Reborn ready", Duration = 3 })
