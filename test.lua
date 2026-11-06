local Globals = getgenv()

if not game:IsLoaded() then game.Loaded:Wait() end

local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")
local RemoteFunc = ReplicatedStorage:WaitForChild("RemoteFunction")
local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local PlayersService = game:GetService("Players")
local LocalPlayer = PlayersService.LocalPlayer or PlayersService.PlayerAdded:Wait()
local mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local FileName = "ADS_Config.json"

task.spawn(function()
    local function DisableIdled()
        local success, connections = pcall(getconnections, LocalPlayer.Idled)
        if success then
            for _, v in pairs(connections) do
                v:Disable()
            end
        end
    end

    DisableIdled()
end)

task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    local overlay = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")

    overlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' then
            while true do
                TeleportService:Teleport(3260590327)
                task.wait(5)
            end
        end
    end)
end)

local function IdentifyGameState()
    local players = game:GetService("Players")
    local TempPlayer = players.LocalPlayer or players.PlayerAdded:Wait()
    local TempGui = TempPlayer:WaitForChild("PlayerGui")

    while true do
        if TempGui:FindFirstChild("ReactLobbyHud") then
            return "LOBBY"
        elseif TempGui:FindFirstChild("ReactUniversalHotbar") then
            return "GAME"
        end
        task.wait(1)
    end
end

local GameState = IdentifyGameState()

local function StartAntiAfk()
    task.spawn(function()
        local LobbyTimer = 0
        while GameState == "LOBBY" do 
            task.wait(1)
            LobbyTimer = LobbyTimer + 1
            if LobbyTimer >= 600 then
                TeleportService:Teleport(3260590327)
                break 
            end
        end
    end)
end

StartAntiAfk()

local AntiLagRunning = false
local CurrentEquippedTowers = {"None"}

local StackEnabled = false
local StackAmount = 1
local SelectedTower = nil
local StackSphere = nil
local LastStackPosition = nil

local DefaultSettings = {
    AntiLag = false,
    AutoUpgrade = false,
    UpgradeLimit = 6,
    UpgradePath = 1,
    Disable3DRendering = false,
    StreamerMode = false,
    HideUsername = false,
    StreamerName = "",
    tagName = "None",
}

TDS = {
    PlacedTowers = {},
    ActiveStrat = true,
    MatchmakingMap = {
        ["Hardcore"] = "hardcore",
        ["Pizza Party"] = "halloween",
        ["Badlands"] = "badlands",
        ["Polluted"] = "polluted"
    }
}
TDS["placed_towers"] = TDS.PlacedTowers
TDS["active_strat"] = TDS.ActiveStrat
TDS["matchmaking_map"] = TDS.MatchmakingMap

local function GetPlayerCash()
    local cashLabel = LocalPlayer.PlayerGui:FindFirstChild("ReactUniversalHotbar")
        and LocalPlayer.PlayerGui.ReactUniversalHotbar:FindFirstChild("Frame")
        and LocalPlayer.PlayerGui.ReactUniversalHotbar.Frame:FindFirstChild("values")
        and LocalPlayer.PlayerGui.ReactUniversalHotbar.Frame.values:FindFirstChild("cash")
        and LocalPlayer.PlayerGui.ReactUniversalHotbar.Frame.values.cash:FindFirstChild("amount")
    if cashLabel then
        local text = cashLabel.Text
        local numStr = text:gsub("[$,]", "")
        local num = tonumber(numStr)
        if num then return num end
    end

    local StateReplicators = ReplicatedStorage:FindFirstChild("StateReplicators")
    if StateReplicators then
        for _, folder in ipairs(StateReplicators:GetChildren()) do
            if folder.Name == "PlayerReplicator"
            and folder:GetAttribute("UserId") == LocalPlayer.UserId
            and folder:GetAttribute("Cash") ~= nil then
                return tonumber(folder:GetAttribute("Cash")) or 0
            end
        end
    end
    return 0
end

local AutoUpgradeRunning = false

shared.TDSTable = TDS
shared["TDS_Table"] = TDS

local function SaveSettings()
    local DataToSave = {}
    for key, _ in pairs(DefaultSettings) do
        DataToSave[key] = Globals[key]
    end
    writefile(FileName, HttpService:JSONEncode(DataToSave))
end

local function LoadSettings()
    if isfile(FileName) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(FileName))
        end)

        if success and type(data) == "table" then
            for key, DefaultVal in pairs(DefaultSettings) do
                if data[key] ~= nil then
                    Globals[key] = data[key]
                else
                    Globals[key] = DefaultVal
                end
            end
            return
        end
    end

    for key, value in pairs(DefaultSettings) do
        Globals[key] = value
    end
    SaveSettings()
end

local function SetSetting(name, value)
    if DefaultSettings[name] ~= nil then
        Globals[name] = value
        SaveSettings()
    end
end

local function Apply3dRendering()
    if Globals.Disable3DRendering then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    else
        RunService:Set3dRenderingEnabled(true)
    end
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local gui = PlayerGui and PlayerGui:FindFirstChild("ADS_BlackScreen")
    if Globals.Disable3DRendering then
        if PlayerGui and not gui then
            gui = Instance.new("ScreenGui")
            gui.Name = "ADS_BlackScreen"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn = false
            gui.DisplayOrder = -1000
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.Parent = PlayerGui
            local frame = Instance.new("Frame")
            frame.Name = "Cover"
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.Size = UDim2.fromScale(1, 1)
            frame.ZIndex = 0
            frame.Parent = gui
        end
        gui.Enabled = true
    else
        if gui then
            gui.Enabled = false
        end
    end
end

LoadSettings()
Apply3dRendering()

local isTagChangerRunning = false
local tagChangerConn = nil
local tagChangerTag = nil
local tagChangerOrig = nil

local function collectTagOptions()
    local list = {}
    local seen = {}
    local function addFolder(folder)
        if not folder then return end
        for _, child in ipairs(folder:GetChildren()) do
            local childName = child.Name
            if childName and not seen[childName] then
                seen[childName] = true
                list[#list + 1] = childName
            end
        end
    end
    local content = ReplicatedStorage:FindFirstChild("Content")
    if content then
        local nametag = content:FindFirstChild("Nametag")
        if nametag then
            addFolder(nametag:FindFirstChild("Basic"))
            addFolder(nametag:FindFirstChild("Exclusive"))
        end
    end
    table.sort(list)
    table.insert(list, 1, "None")
    return list
end

local function stopTagChanger()
    if tagChangerConn then
        tagChangerConn:Disconnect()
        tagChangerConn = nil
    end
    if tagChangerTag and tagChangerTag.Parent and tagChangerOrig ~= nil then
        pcall(function()
            tagChangerTag.Value = tagChangerOrig
        end)
    end
    tagChangerTag = nil
    tagChangerOrig = nil
end

local function startTagChanger()
    if isTagChangerRunning then return end
    isTagChangerRunning = true
    task.spawn(function()
        while Globals.tagName and Globals.tagName ~= "" and Globals.tagName ~= "None" do
            local tag = LocalPlayer:FindFirstChild("Tag")
            if tag then
                if tagChangerTag ~= tag then
                    if tagChangerConn then
                        tagChangerConn:Disconnect()
                        tagChangerConn = nil
                    end
                    tagChangerTag = tag
                    if tagChangerOrig == nil then
                        tagChangerOrig = tag.Value
                    end
                end
                if tag.Value ~= Globals.tagName then
                    tag.Value = Globals.tagName
                end
                if not tagChangerConn then
                    tagChangerConn = tag:GetPropertyChangedSignal("Value"):Connect(function()
                        if Globals.tagName and Globals.tagName ~= "" and Globals.tagName ~= "None" then
                            if tag.Value ~= Globals.tagName then
                                tag.Value = Globals.tagName
                            end
                        end
                    end)
                end
            end
            task.wait(0.5)
        end
        isTagChangerRunning = false
    end)
end

if Globals.tagName and Globals.tagName ~= "" and Globals.tagName ~= "None" then
    startTagChanger()
end

local OriginalDisplayName = LocalPlayer.DisplayName
local OriginalUserName = LocalPlayer.Name

local SpoofTextCache = setmetatable({}, {__mode = "k"})
local PrivacyRunning = false
local LastSpoofName = nil
local PrivacyConns = {}
local PrivacyTextNodes = setmetatable({}, {__mode = "k"})
local StreamerTag = nil
local StreamerTagOrig = nil
local StreamerTagConn = nil

local function AddPrivacyConn(conn)
    if conn then
        PrivacyConns[#PrivacyConns + 1] = conn
    end
end

local function ClearPrivacyConns()
    for _, c in ipairs(PrivacyConns) do
        pcall(function() c:Disconnect() end)
    end
    PrivacyConns = {}
    for inst in pairs(PrivacyTextNodes) do
        PrivacyTextNodes[inst] = nil
    end
end

local function MakeSpoofName()
    return "BelowNatural"
end

local function EnsureSpoofName()
    local nm = Globals.StreamerName
    if not nm or nm == "" then
        nm = MakeSpoofName()
        SetSetting("StreamerName", nm)
    end
    return nm
end

local function IsTagChangerActive()
    return Globals.tagName and Globals.tagName ~= "" and Globals.tagName ~= "None"
end

local function SetLocalDisplayName(nm)
    if not nm or nm == "" then return end
    pcall(function()
        LocalPlayer.DisplayName = nm
    end)
end

local function ReplacePlain(str, old, new)
    if not str or str == "" or not old or old == "" or old == new then
        return str, false
    end
    local start = 1
    local out = {}
    local changed = false
    while true do
        local i, j = string.find(str, old, start, true)
        if not i then
            out[#out + 1] = string.sub(str, start)
            break
        end
        changed = true
        out[#out + 1] = string.sub(str, start, i - 1)
        out[#out + 1] = new
        start = j + 1
    end
    if changed then
        return table.concat(out), true
    end
    return str, false
end

local function ApplySpoofToInstance(inst, OldA, OldB, NewName)
    if not inst then return end
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        local txt = inst.Text
        if type(txt) == "string" and txt ~= "" then
            local HasA = OldA and OldA ~= "" and string.find(txt, OldA, 1, true)
            local HasB = OldB and OldB ~= "" and string.find(txt, OldB, 1, true)
            if not HasA and not HasB then return end
            local t = txt
            local changed = false
            local ch
            if OldA and OldA ~= "" then
                t, ch = ReplacePlain(t, OldA, NewName)
                if ch then changed = true end
            end
            if OldB and OldB ~= "" then
                t, ch = ReplacePlain(t, OldB, NewName)
                if ch then changed = true end
            end
            if changed then
                if SpoofTextCache[inst] == nil then
                    SpoofTextCache[inst] = txt
                end
                inst.Text = t
            end
        end
    end
end

local function RestoreSpoofText()
    for inst, txt in pairs(SpoofTextCache) do
        if inst and inst.Parent then
            pcall(function() inst.Text = txt end)
        end
        SpoofTextCache[inst] = nil
    end
end

local function GetPrivacyName()
    if Globals.StreamerMode then
        return EnsureSpoofName()
    end
    if Globals.HideUsername then
        return "████████"
    end
    return nil
end

local function AddPrivacyNode(inst)
    if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then
        return
    end
    PrivacyTextNodes[inst] = true
    local nm = GetPrivacyName()
    if nm then
        ApplySpoofToInstance(inst, OriginalDisplayName, OriginalUserName, nm)
    end
end

local function HookPrivacyRoot(root)
    if not root then return end
    for _, inst in ipairs(root:GetDescendants()) do
        AddPrivacyNode(inst)
    end
    AddPrivacyConn(root.DescendantAdded:Connect(function(inst)
        if GetPrivacyName() then
            AddPrivacyNode(inst)
        end
    end))
end

local function SweepPrivacyText(nm)
    for inst in pairs(PrivacyTextNodes) do
        if inst and inst.Parent then
            ApplySpoofToInstance(inst, OriginalDisplayName, OriginalUserName, nm)
        else
            PrivacyTextNodes[inst] = nil
        end
    end
end

local function ApplyStreamerTag()
    if IsTagChangerActive() then
        if StreamerTagConn then
            StreamerTagConn:Disconnect()
            StreamerTagConn = nil
        end
        StreamerTag = nil
        StreamerTagOrig = nil
        return
    end
    local nm = EnsureSpoofName()
    local tag = LocalPlayer:FindFirstChild("Tag")
    if not tag then return end
    if StreamerTag and StreamerTag ~= tag then
        if StreamerTagConn then
            StreamerTagConn:Disconnect()
            StreamerTagConn = nil
        end
    end
    if StreamerTag ~= tag then
        StreamerTag = tag
        StreamerTagOrig = tag.Value
    end
    if tag.Value ~= nm then
        tag.Value = nm
    end
    if StreamerTagConn then
        StreamerTagConn:Disconnect()
        StreamerTagConn = nil
    end
    StreamerTagConn = tag:GetPropertyChangedSignal("Value"):Connect(function()
        if not Globals.StreamerMode then return end
        if IsTagChangerActive() then return end
        local nm2 = EnsureSpoofName()
        if tag.Value ~= nm2 then
            tag.Value = nm2
        end
    end)
end

local function RestoreStreamerTag()
    if StreamerTagConn then
        StreamerTagConn:Disconnect()
        StreamerTagConn = nil
    end
    if IsTagChangerActive() then
        StreamerTag = nil
        StreamerTagOrig = nil
        return
    end
    if StreamerTag and StreamerTag.Parent and StreamerTagOrig ~= nil then
        pcall(function() StreamerTag.Value = StreamerTagOrig end)
    end
    StreamerTag = nil
    StreamerTagOrig = nil
end

local function ApplyPrivacyOnce()
    local nm = GetPrivacyName()
    if not nm then return end
    if LastSpoofName and LastSpoofName ~= nm then
        RestoreSpoofText()
    end
    if Globals.StreamerMode then
        ApplyStreamerTag()
    else
        RestoreStreamerTag()
    end
    SetLocalDisplayName(nm)
    SweepPrivacyText(nm)
    LastSpoofName = nm
end

local function StopPrivacyMode()
    ClearPrivacyConns()
    RestoreSpoofText()
    LastSpoofName = nil
    RestoreStreamerTag()
    SetLocalDisplayName(OriginalDisplayName)
    PrivacyRunning = false
end

local function StartPrivacyMode()
    if PrivacyRunning then return end
    PrivacyRunning = true
    ClearPrivacyConns()
    ApplyPrivacyOnce()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then HookPrivacyRoot(pg) end
    local CoreGui = game:GetService("CoreGui")
    if CoreGui then HookPrivacyRoot(CoreGui) end
    local TagsRoot = workspace:FindFirstChild("Nametags")
    if TagsRoot then HookPrivacyRoot(TagsRoot) end
    local ch = LocalPlayer.Character
    if ch then HookPrivacyRoot(ch) end
    AddPrivacyConn(LocalPlayer.CharacterAdded:Connect(function(NewChar)
        if GetPrivacyName() then
            HookPrivacyRoot(NewChar)
            ApplyPrivacyOnce()
        end
    end))
    AddPrivacyConn(workspace.ChildAdded:Connect(function(inst)
        if GetPrivacyName() and inst.Name == "Nametags" then
            HookPrivacyRoot(inst)
            ApplyPrivacyOnce()
        end
    end))
    local function step()
        if not GetPrivacyName() then
            StopPrivacyMode()
            return
        end
        ApplyPrivacyOnce()
        task.delay(0.5, step)
    end
    task.defer(step)
end

local function UpdatePrivacyState()
    if GetPrivacyName() then
        if not PrivacyRunning then
            StartPrivacyMode()
        else
            ApplyPrivacyOnce()
        end
    else
        if PrivacyRunning then
            StopPrivacyMode()
        end
    end
end

UpdatePrivacyState()

local function GetEquippedTowers()
    local towers = {}
    local StateReplicators = ReplicatedStorage:FindFirstChild("StateReplicators")

    if StateReplicators then
        for _, folder in ipairs(StateReplicators:GetChildren()) do
            if folder.Name == "PlayerReplicator" and folder:GetAttribute("UserId") == LocalPlayer.UserId then
                local equipped = folder:GetAttribute("EquippedTowers")
                if type(equipped) == "string" then
                    local CleanedJson = equipped:match("%[.*%]") 
                    local success, TowerTable = pcall(function()
                        return HttpService:JSONDecode(CleanedJson)
                    end)

                    if success and type(TowerTable) == "table" then
                        for i = 1, 5 do
                            if TowerTable[i] then
                                table.insert(towers, TowerTable[i])
                            end
                        end
                    end
                end
            end
        end
    end
    return #towers > 0 and towers or {"None"}
end

CurrentEquippedTowers = GetEquippedTowers()

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/DuxiiT/auto-strat/refs/heads/main/Sources/UI.lua"))()

local Window = Library:Window({
    Title = "nyaw:3",
    Desc = "wahhh",
    Theme = "Dark",
    DiscordLink = "",
    Icon = 126403638319957,
    Config = {
        Keybind = Enum.KeyCode.LeftControl,
        Size = UDim2.new(0, 500, 0, 400)
    }
})

local Main = Window:Tab({Title = "Main", Icon = "stamp"}) do
    Main:Section({Title = "Tower Options"})
    local TowerDropdown = Main:Dropdown({
        Title = "Tower:",
        List = CurrentEquippedTowers,
        Value = CurrentEquippedTowers[1],
        Callback = function(choice)
            SelectedTower = choice
        end
    })

    local function RefreshDropdown()
        local NewTowers = GetEquippedTowers()
        if table.concat(NewTowers, ",") ~= table.concat(CurrentEquippedTowers, ",") then
            TowerDropdown:Clear() 

            for _, TowerName in ipairs(NewTowers) do
                TowerDropdown:Add(TowerName)
            end

            CurrentEquippedTowers = NewTowers
        end
    end

    task.spawn(function()
        while task.wait(2) do
            RefreshDropdown()
        end
    end)

    Main:Toggle({
        Title = "Stack Tower",
        Desc = "Enables Stacking placement",
        Value = false,
        Callback = function(v)
            StackEnabled = v

            if StackEnabled then
                Window:Notify({
                    Title = "ADS",
                    Desc = "Make sure not to equip the tower, only select it and then place where you want to!",
                    Time = 5,
                    Type = "normal"
                })
            end
        end
    })

    Main:Slider({
        Title = "Amount",
        Desc = "How many towers to place at once (1-10)",
        Min = 1,
        Max = 40,
        Rounding = 0,
        Value = 1,
        Callback = function(v)
            StackAmount = v
        end
    })

    Main:Button({
        Title = "Place Again",
        Desc = "Places one more tower at the last Stack Tower position",
        Callback = function()
            if not SelectedTower then
                Window:Notify({
                    Title = "ADS",
                    Desc = "No tower selected! Select a tower in the Tower: dropdown first.",
                    Time = 3,
                    Type = "error"
                })
                return
            end
            if not LastStackPosition then
                Window:Notify({
                    Title = "ADS",
                    Desc = "No position saved yet! Place a tower with Stack Tower first.",
                    Time = 3,
                    Type = "error"
                })
                return
            end
            local pos = LastStackPosition
            local newpos = Vector3.new(pos.X, pos.Y + 25, pos.Z)
            RemoteFunc:InvokeServer("Troops", "Place", {Rotation = CFrame.new(), Position = newpos}, SelectedTower)
            Window:Notify({
                Title = "ADS",
                Desc = "Placed " .. tostring(SelectedTower) .. " at last stack position!",
                Time = 3,
                Type = "normal"
            })
        end
    })

    Main:Button({
        Title = "Upgrade Selected",
        Desc = "",
        Callback = function()
            if SelectedTower then
                local towersFolder = workspace:FindFirstChild("Towers")
                if towersFolder then
                    for _, v in pairs(towersFolder:GetChildren()) do
                        local rep = v:FindFirstChild("TowerReplicator")
                        if rep and rep:GetAttribute("Name") == SelectedTower and rep:GetAttribute("OwnerId") == LocalPlayer.UserId then
                            RemoteFunc:InvokeServer("Troops", "Upgrade", "Set", {Troop = v, Path = Globals.UpgradePath or 1})
                        end
                    end
                end
                Window:Notify({
                    Title = "ADS",
                    Desc = "Attempted to upgrade all the selected towers!",
                    Time = 3,
                    Type = "normal"
                })
            end
        end
    })

    Main:Button({
        Title = "Sell Selected",
        Desc = "",
        Callback = function()
            if SelectedTower then
                local towersFolder = workspace:FindFirstChild("Towers")
                if towersFolder then
                    for _, v in pairs(towersFolder:GetChildren()) do
                        local rep = v:FindFirstChild("TowerReplicator")
                        if rep and rep:GetAttribute("Name") == SelectedTower and rep:GetAttribute("OwnerId") == LocalPlayer.UserId then
                            RemoteFunc:InvokeServer("Troops", "Sell", {Troop = v})
                        end
                    end
                end
                Window:Notify({
                    Title = "ADS",
                    Desc = "Attempted to sell all the selected towers!",
                    Time = 3,
                    Type = "normal"
                })
            end
        end
    })

    Main:Button({
        Title = "Upgrade All",
        Desc = "",
        Callback = function()
            local towersFolder = workspace:FindFirstChild("Towers")
            if towersFolder then
                for _, v in pairs(towersFolder:GetChildren()) do
                    local rep = v:FindFirstChild("TowerReplicator")
                    if rep and rep:GetAttribute("OwnerId") == LocalPlayer.UserId then
                        RemoteFunc:InvokeServer("Troops", "Upgrade", "Set", {Troop = v, Path = Globals.UpgradePath or 1})
                    end
                end
            end
            Window:Notify({
                Title = "ADS",
                Desc = "Attempted to upgrade all the towers!",
                Time = 3,
                Type = "normal"
            })
        end
    })

    Main:Toggle({
        Title = "Auto Upgrade",
        Desc = "Automatically upgrades your towers when you have enough cash",
        Value = Globals.AutoUpgrade,
        Callback = function(v)
            SetSetting("AutoUpgrade", v)
            if not v then
                AutoUpgradeRunning = false
            end
        end
    })

    Main:Slider({
        Title = "Upgrade Limit",
        Desc = "Max upgrade level (1-6). Towers at or above this level won't be upgraded",
        Min = 1,
        Max = 6,
        Rounding = 0,
        Value = Globals.UpgradeLimit or 6,
        Callback = function(v)
            SetSetting("UpgradeLimit", v)
        end
    })

    Main:Dropdown({
        Title = "Upgrade Path",
        Desc = "Select upgrade path (for towers with 2 paths)",
        List = {"1", "2"},
        Value = tostring(Globals.UpgradePath or 1),
        Callback = function(choice)
            SetSetting("UpgradePath", tonumber(choice) or 1)
        end
    })

    Main:Button({
        Title = "Sell All",
        Desc = "",
        Callback = function()
            Window:Dialog({
                Title = "Do you want to sell all the towers?",
                Button1 = {
                    Title = "Confirm",
                    Color = Color3.fromRGB(226, 39, 6),
                    Callback = function()
                        local towersFolder = workspace:FindFirstChild("Towers")
                        if towersFolder then
                            for _, v in pairs(towersFolder:GetChildren()) do
                                local rep = v:FindFirstChild("TowerReplicator")
                                if rep and rep:GetAttribute("OwnerId") == LocalPlayer.UserId then
                                    RemoteFunc:InvokeServer("Troops", "Sell", {Troop = v})
                                end
                            end
                        end

                        Window:Notify({
                            Title = "ADS",
                            Desc = "Attempted to sell all the towers!",
                            Time = 3,
                            Type = "normal"
                        })
                    end
                },
                Button2 = {
                    Title = "Cancel",
                    Color = Color3.fromRGB(0, 188, 0)
                }
            })
        end
    })
end

local Misc = Window:Tab({Title = "Misc", Icon = "box"}) do
    Misc:Section({Title = "Misc"})
    Misc:Toggle({
        Title = "Enable Anti-Lag",
        Desc = "Boosts your FPS",
        Value = Globals.AntiLag,
        Callback = function(v)
            SetSetting("AntiLag", v)
        end
    })

    Misc:Toggle({
        Title = "Disable 3d rendering",
        Desc = "Turns off 3d rendering",
        Value = Globals.Disable3DRendering,
        Callback = function(v)
            SetSetting("Disable3DRendering", v)
            Apply3dRendering()
        end
    })
end

local Settings = Window:Tab({Title = "Settings", Icon = "settings"}) do
    Settings:Section({Title = "Settings"})
    Settings:Button({
        Title = "Save Settings",
        Callback = function()
            Window:Notify({
                Title = "ADS",
                Desc = "Settings Saved!",
                Time = 3,
                Type = "normal"
            })
            LoadSettings()
        end
    })

    Settings:Button({
        Title = "Load Settings",
        Callback = function()
            Window:Notify({
                Title = "ADS",
                Desc = "Settings Loaded!",
                Time = 3,
                Type = "normal"
            })
            SaveSettings()
        end
    })

    Settings:Section({Title = "Privacy"})
    Settings:Toggle({
        Title = "Hide Username",
        Desc = "",
        Value = Globals.HideUsername,
        Callback = function(v)
            SetSetting("HideUsername", v)
            UpdatePrivacyState()
        end
    })

    Settings:Textbox({
        Title = "Streamer Name",
        Desc = "",
        Placeholder = "Spoof Name",
        Value = Globals.StreamerName or "",
        ClearTextOnFocus = false,
        Callback = function(value)
            SetSetting("StreamerName", value or "")
            UpdatePrivacyState()
        end
    })

    Settings:Toggle({
        Title = "Streamer Mode",
        Desc = "",
        Value = Globals.StreamerMode,
        Callback = function(v)
            SetSetting("StreamerMode", v)
            UpdatePrivacyState()
        end
    })

    Settings:Section({Title = "Tags"})
    local tagOptions = collectTagOptions()
    local tagValue = Globals.tagName or "None"
    if not table.find(tagOptions, tagValue) then
        tagValue = "None"
    end
    Settings:Dropdown({
        Title = "Tag Changer",
        Desc = "",
        List = tagOptions,
        Value = tagValue,
        Callback = function(choice)
            local selected = choice
            if type(choice) == "table" then
                selected = choice[1]
            end
            if not selected or selected == "" then
                selected = "None"
            end
            SetSetting("tagName", selected)
            if selected == "None" then
                stopTagChanger()
            else
                startTagChanger()
            end
        end
    })
end

RunService.RenderStepped:Connect(function()
    if StackEnabled then
        if not StackSphere then
            StackSphere = Instance.new("Part")
            StackSphere.Shape = Enum.PartType.Ball
            StackSphere.Size = Vector3.new(1.5, 1.5, 1.5)
            StackSphere.Color = Color3.fromRGB(0, 255, 0)
            StackSphere.Transparency = 0.5
            StackSphere.Anchored = true
            StackSphere.CanCollide = false
            StackSphere.Material = Enum.Material.Neon
            StackSphere.Parent = workspace
            mouse.TargetFilter = StackSphere
        end
        local hit = mouse.Hit
        if hit then StackSphere.Position = hit.Position end
    elseif StackSphere then
        StackSphere:Destroy()
        StackSphere = nil
    end
end)

mouse.Button1Down:Connect(function()
    if StackEnabled and StackSphere and SelectedTower then
        local pos = StackSphere.Position
        LastStackPosition = pos
        local newpos = Vector3.new(pos.X, pos.Y + 25, pos.Z)
        for i = 1, StackAmount do
            task.spawn(function()
                RemoteFunc:InvokeServer("Troops", "Place", {Rotation = CFrame.new(), Position = newpos}, SelectedTower)
            end)
        end
    end
end)

local function StartAutoUpgrade()
    if AutoUpgradeRunning then return end
    AutoUpgradeRunning = true

    task.spawn(function()
        while Globals.AutoUpgrade do
            local limit = Globals.UpgradeLimit or 6

            local TowersFolder = workspace:FindFirstChild("Towers")
            if TowersFolder then
                for _, tower in ipairs(TowersFolder:GetChildren()) do
                    if not Globals.AutoUpgrade then break end
                    local rep = tower:FindFirstChild("TowerReplicator")
                    if rep and rep:GetAttribute("OwnerId") == LocalPlayer.UserId
                    and (not SelectedTower or rep:GetAttribute("Name") == SelectedTower) then
                        local currentLevel = rep:GetAttribute("Upgrade") or 0

                        if currentLevel < limit then
                            local path = Globals.UpgradePath or 1
                            pcall(function()
                                RemoteFunc:InvokeServer("Troops", "Upgrade", "Set", {
                                    Troop = tower,
                                    Path = path
                                })
                            end)
                            task.wait(0.05)
                        end
                    end
                end
            end

            task.wait(0.5)
        end
        AutoUpgradeRunning = false
    end)
end

local function StartAntiLag()
    AntiLagRunning = true

    local settings = settings().Rendering
    local OriginalQuality = settings.QualityLevel
    settings.QualityLevel = Enum.QualityLevel.Level01

    task.spawn(function()
        while Globals.AntiLag do
            local TowersFolder = workspace:FindFirstChild("Towers")
            local ClientUnits = workspace:FindFirstChild("ClientUnits")
            local enemies = workspace:FindFirstChild("NPCs")

            if TowersFolder then
                for _, tower in ipairs(TowersFolder:GetChildren()) do
                    local anims = tower:FindFirstChild("Animations")
                    local weapon = tower:FindFirstChild("Weapon")
                    local projectiles = tower:FindFirstChild("Projectiles")

                    if anims then anims:Destroy() end
                    if projectiles then projectiles:Destroy() end
                    if weapon then weapon:Destroy() end
                end
            end
            if ClientUnits then
                for _, unit in ipairs(ClientUnits:GetChildren()) do
                    unit:Destroy()
                end
            end
            if enemies then
                for _, npc in ipairs(enemies:GetChildren()) do
                    npc:Destroy()
                end
            end
            task.wait(0.5)
        end
        AntiLagRunning = false
    end)
end

task.spawn(function()
    while true do
        if Globals.AutoUpgrade and not AutoUpgradeRunning then
            StartAutoUpgrade()
        end
        if Globals.AntiLag and not AntiLagRunning then
            StartAntiLag()
        end
        task.wait(1)
    end
end)

return TDS
