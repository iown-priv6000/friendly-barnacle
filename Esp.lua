

if not LPH_OBFUSCATED then
    lph_jit = LPH_JIT or function(...)
        return ...
    end
    lph_jit_max = LPH_JIT_MAX or function(...)
        return ...
    end
    lph_no_virtualize = LPH_NO_VIRTUALIZE or function(...)
        return ...
    end
    lph_no_upvalues = LPH_NO_UPVALUES or function(f)
        return function(...)
            return f(...)
        end
    end
    lph_encstr = LPH_ENCSTR or function(...)
        return ...
    end
    lph_encnum = LPH_ENCNUM or function(...)
        return ...
    end
    lph_encfunc = LPH_ENCFUNC or function(func, key1, key2)
        if key1 ~= key2 then
            return print("LPH_ENCFUNC mismatch")
        end
        return func
    end
    lph_crash = LPH_CRASH or function()
        return print(debug.traceback())
    end
end

local user_input_service = game:GetService("UserInputService")
local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local core_gui = game:GetService("CoreGui")
local workspace = game:GetService("Workspace")
local http_service = game:GetService("HttpService")
local local_player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local wt_s = Camera.WorldToViewportPoint
local ui_container = gethui and gethui() or CoreGui
local bootstrap_players = Players
local lph_no_virtualize = LPH_NO_VIRTUALIZE
local esp = {}
local ChamsContainer
local MeshChamsFolder
local ScreenGui
local PlayerRemovingConnection
local InputBeganConnection
local current_run_id = HttpService:GenerateGUID(false)

if getgenv().SensoryESP_Unload then
    pcall(getgenv().SensoryESP_Unload)
end

local oldchams = UIContainer:FindFirstChild("SensoryESP_Chams")
if oldChams then
    pcall(function() oldChams:Destroy() end)
end

local oldmesh_folder = Workspace:FindFirstChild("SensoryESP_MeshChams")
if oldMeshFolder then
    pcall(function() oldMeshFolder:Destroy() end)
end

local function is_mesh_cham_artifact(obj)
    if not obj then
        return false
    end

    if obj:GetAttribute("SensoryESP_MeshCham") == true then
        return true
    end

    if obj:IsA("Model") and obj.name == "ChamShells" then
        return true
    end

    if obj:IsA("BasePart") and obj.Name:match("^ChamShell_") then
        return true
    end

    if obj:IsA("Highlight") and obj.name == "ChamShellHighlight" then
        return true
    end

    return false
end

local function cleanup_mesh_chams(root)
    if not root then
        return
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if IsMeshChamArtifact(obj) then
            pcall(function() obj:Destroy() end)
        end
    end
end

local function cleanup_character_mesh_chams(character)
    if not character then
        return
    end

    for _, child in ipairs(character:GetChildren()) do
        if IsMeshChamArtifact(child) then
            pcall(function() child:Destroy() end)
        end
    end
end

CleanupMeshChams(Workspace)

for _, player in ipairs(BootstrapPlayers:GetPlayers()) do
    CleanupCharacterMeshChams(player.Character)
end

local function ensure_root_instances()
    if not ChamsContainer or not ChamsContainer.Parent then
        chams_container = Instance.new("Folder")
        ChamsContainer.name = "SensoryESP_Chams"
        ChamsContainer.parent = UIContainer
    end

    if not MeshChamsFolder or not MeshChamsFolder.Parent then
        mesh_chams_folder = Instance.new("Folder")
        MeshChamsFolder.name = "SensoryESP_MeshChams"
        MeshChamsFolder.parent = Workspace
    end

    if not ScreenGui or not ScreenGui.Parent then
        screen_gui = Instance.new("ScreenGui")
        ScreenGui.name = "SensoryESP"
        ScreenGui.reset_on_spawn = false
        ScreenGui.ignore_gui_inset = true
        ScreenGui.z_index_behavior = Enum.ZIndexBehavior.Global
        getgenv().sensory_esp_ui = ScreenGui

        local success = pcall(function()
            ScreenGui.parent = CoreGui
        end)
        if not success then
            ScreenGui.parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end
end

local labelstroke_map = setmetatable({}, { __mode = "k" })
local draw_line = LPHNoVirtualize(function(line, p1, p2, thickness, color)
    local diff = p2 - p1
    local dist = diff.Magnitude
    local angle = math.deg(math.atan2(diff.Y, diff.X))

    line.size = UDim2.new(0, math.floor(dist + 0.5), 0, thickness)
    line.position = UDim2.new(0, math.floor(p1.X + diff.X / 2 - dist / 2 + 0.5), 0,
        math.floor(p1.Y + diff.Y / 2 - thickness / 2 + 0.5))
    line.rotation = angle
    line.background_color3 = color
    line.visible = true
end)

local esp_config = {
    
    enabled = true,
    keybind = {
        enabled = false,
        key = Enum.KeyCode.Insert,
    },
    players = true,
    local_player = false,
    limit_fps = 70, 
    dynamic_boxes = true,
    dynamic_boxes_cheap = false,           
    dynamic_boxes_include_all = false,      
    visibility_check_rate = 0.3,

    
    boxes = false,
    box_type = "Normal", 
    box_color = Color3.fromRGB(255, 255, 255),
    box_thickness = 1,
    outlines = {
        style = "Full", 
        color = Color3.fromRGB(0, 0, 0),
        thickness = 1,
    },

    
    box_fill = {
        enabled = false,
        color = Color3.fromRGB(255, 255, 255),
        transparency = 0.9,
        gradient = {
            enabled = false,
            color1 = Color3.fromRGB(180, 255, 255),
            color2 = Color3.fromRGB(0, 255, 255),
            color3 = Color3.fromRGB(0, 120, 255),
            rotation = 0,
            animated = false,
            speed = 64,          
            direction = "Right", 
        }
    },

    
    health_bar = {
        enabled = false,
        position = "Left", 
        side_gap = 1,
        width = 1,
        show_text = false,
        text_follow_bar = false,
        hide_when_full_hp = false,
        follow_gradient_color_text = false,
        font = "Smallest Pixel-7",
        text_size = 9,
        outline = {
            style = "Full",
            color = Color3.fromRGB(0, 0, 0),
        },
        gradient = {
            enabled = false,
            color1 = Color3.fromRGB(0, 255, 0),   
            color2 = Color3.fromRGB(255, 255, 0), 
            color3 = Color3.fromRGB(255, 0, 0),   
        }
    },

    
    names = false,
    text_size = 12,
    text_color = Color3.fromRGB(255, 255, 255),
    text_outline = false,
    text_outline_style = "Full", 
    text_gap = 3,
    font = "Proggy Clean",
    team_indicator = {
        enabled = false,
        position = "Right", 
        use_team_color = false,
        color = Color3.fromRGB(255, 255, 255),
        compact = false,
        text_size = 10,
    },
    friendly_indicator = {
        enabled = false,
        position = "Right", 
        check_team = false,
        check_friends = false,
        text = "[F]",
        color = Color3.fromRGB(0, 255, 0),
    },
    weapon = {
        enabled = false,
        gap = 1,
        outline_style = "Full",
        font = "Proggy Clean",
        text_size = 12,
        color = Color3.fromRGB(255, 255, 255),
        inventory_path = "ReplicatedStorage.Players.%NAME%.Inventory",
        use_tool_fallback = false,
    },

    
    flags = {
        enabled = false,
        position = "Right",
        gap = 2,
        side_gap = 4,
        text_gap = 2,
        outline_style = "Full",
        font = "Smallest Pixel-7",
        text_size = 9,
        options = {
            idle = false,
            moving = false,
            jumping = false,
            swimming = false,
        },
        colors = {
            idle = Color3.fromRGB(255, 255, 255),
            moving = Color3.fromRGB(255, 255, 255),
            jumping = Color3.fromRGB(255, 255, 255),
            swimming = Color3.fromRGB(65, 65, 255),
        }
    },

    
    skeleton = {
        enabled = false,
        color = Color3.fromRGB(255, 255, 255),
        outline = false,
        outline_color = Color3.fromRGB(0, 0, 0),
        gradient = {
            enabled = false,
            color1 = Color3.fromRGB(255, 255, 255),
            color2 = Color3.fromRGB(100, 200, 255),
        },
    },

    
    off_screen_arrows = {
        enabled = false,
        size = 14,
        color = Color3.fromRGB(255, 255, 255),
        orbit_radius = 100,
        arrow_mode = "Camera",
        outline = false,
        outline_color = Color3.fromRGB(0, 0, 0),
        names = {
            enabled = false,
            font = "Smallest Pixel-7",
            text_size = 9,
            color = Color3.fromRGB(255, 255, 255),
            outline = true,
            outline_color = Color3.fromRGB(0, 0, 0),
            side = "Bottom",
            gap = 4,
        },
        distance = {
            enabled = false,
            font = "Smallest Pixel-7",
            text_size = 9,
            color = Color3.fromRGB(255, 255, 255),
            outline = false,
            outline_color = Color3.fromRGB(0, 0, 0),
            side = "Bottom",
            gap = 2,
        },
    },

    
    distance = {
        enabled = false,
        unit = "Meters",
        studs_per_meter = 3,
        ending = "m",
        gap = 3,
        outline_style = "Full",
        font = "Proggy Clean",
        text_size = 12,
        color = Color3.fromRGB(255, 255, 255),
    },

    
    chams = {
        enabled = false,
        type = "MeshChams", 

        highlight = {
            fill_color = Color3.fromRGB(255, 255, 255),
            fill_transparency = 1,
            outline_color = Color3.fromRGB(255, 255, 255),
            outline_transparency = 0,
            visible_check = false, 
        },

        adornment = {
            color = Color3.fromRGB(59, 144, 204),
            visible_color = Color3.fromRGB(59, 204, 90),
            transparency = 0.7,
            always_on_top = false,
            visible_check = false,
        },

        
        
        mesh_chams = {
            fill_color = Color3.fromRGB(59, 144, 204),
            fill_transparency = 0.6,
            outline_color = Color3.fromRGB(255, 255, 255),
            outline_transparency = 0,
            visible_check = false, 
        },
    },

    
    directories = {
        {
            display_name = "Characters",
            path = "workspace.Characters",
            multiple = true,
            cheap = false,
            recursive = true,
            contains = {},
            names = {}
        },
        
    }
}

local function deep_copy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end

    local copy = {}
    for key, value in pairs(tbl) do
        copy[key] = DeepCopy(value)
    end
    return copy
end

local function deep_merge(base, override)
    if type(override) ~= "table" then
        return base
    end

    for key, value in pairs(override) do
        if type(value) == "table" and type(base[key]) == "table" then
            DeepMerge(base[key], value)
        else
            base[key] = value
        end
    end

    return base
end

local default_esp_config = DeepCopy(ESPConfig)

local function compact_team_name(teamName)
    if type(teamName) ~= "string" or teamname == "" then
        return ""
    end

    local parts = {}
    for part in teamName:gmatch("[^%s%-_]+") do
        if part ~= "" then
            table.insert(parts, part)
        end
    end

    if #parts == 0 then
        return teamName
    end

    if #parts == 1 then
        local single = parts[1]
        if #single <= 4 then
            return single:upper()
        end
        return single:sub(1, 1):upper()
    end

    local compact = {}
    for _, part in ipairs(parts) do
        table.insert(compact, part:sub(1, 1):upper())
    end
    return table.concat(compact)
end

local function color_to_hex(color)
    local r = math.clamp(math.floor(color.R * 255 + 0.5), 0, 255)
    local g = math.clamp(math.floor(color.G * 255 + 0.5), 0, 255)
    local b = math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end



local _fontmap = {
    ["Proggy Clean"] = Enum.Font.SourceSans,
    ["Smallest Pixel-7"] = Enum.Font.SourceSans,
    ["Tahoma"] = Enum.Font.SourceSans,
    ["Minecraftia"] = Enum.Font.SourceSans,
    ["Tahoma Modern Bold"] = Enum.Font.SourceSansBold,
}

local fonts_to_download = {
    ["Tahoma"] = { ttf = "https://github.com/LuckyHub1/LuckyHub/raw/main/zekton_rg.ttf" },
    ["Minecraftia"] = { ttf = "https://github.com/LuckyHub1/LuckyHub/raw/refs/heads/main/Minecraftia.ttf" },
    ["Smallest Pixel-7"] = { ttf = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/smallest_pixel-7.ttf" },
    ["Proggy Clean"] = { ttf = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf" },
    ["Tahoma Modern Bold"] = { ttf = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Tahoma-Modern-Bold.ttf" },
}

local esp_fonts = { loaded = {} }
local fonts_still_loading = true


local skeleton_bone_defs = {
    
    { "UpperTorso", "LowerTorso" },
    
    { "Head", "UpperTorso" },
    
    { "UpperTorso", "LeftUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    
    { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "RightLowerArm", "RightHand" },
    
    { "LowerTorso", "LeftUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    
    { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "RightLowerLeg", "RightFoot" },
}

local function get_bone_position(character, boneName)
    local part = character:FindFirstChild(boneName)
    if part then return part.Position end

    
    if bonename == "Head" then
        part = character:FindFirstChild("Head")
    elseif bonename == "UpperTorso" then
        part = character:FindFirstChild("Torso")
    elseif bonename == "LowerTorso" then
        part = character:FindFirstChild("Torso")
        if part then return (part.CFrame * CFrame.new(0, -1.2, 0)).Position end
    elseif bonename == "LeftUpperArm" then
        part = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftArm")
    elseif bonename == "LeftLowerArm" then
        part = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftArm")
        if part then return (part.CFrame * CFrame.new(0, -0.8, 0)).Position end
    elseif bonename == "LeftHand" then
        part = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftArm")
        if part then return (part.CFrame * CFrame.new(0, -1.5, 0)).Position end
    elseif bonename == "RightUpperArm" then
        part = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightArm")
    elseif bonename == "RightLowerArm" then
        part = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightArm")
        if part then return (part.CFrame * CFrame.new(0, -0.8, 0)).Position end
    elseif bonename == "RightHand" then
        part = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightArm")
        if part then return (part.CFrame * CFrame.new(0, -1.5, 0)).Position end
    elseif bonename == "LeftUpperLeg" then
        part = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftLeg")
    elseif bonename == "LeftLowerLeg" then
        part = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftLeg")
        if part then return (part.CFrame * CFrame.new(0, -0.8, 0)).Position end
    elseif bonename == "LeftFoot" then
        part = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftLeg")
        if part then return (part.CFrame * CFrame.new(0, -1.5, 0)).Position end
    elseif bonename == "RightUpperLeg" then
        part = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightLeg")
    elseif bonename == "RightLowerLeg" then
        part = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightLeg")
        if part then return (part.CFrame * CFrame.new(0, -0.8, 0)).Position end
    elseif bonename == "RightFoot" then
        part = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightLeg")
        if part then return (part.CFrame * CFrame.new(0, -1.5, 0)).Position end
    end

    return part and part.Position
end
local font_loading_capable = writefile and isfile and getcustomasset
local function load_custom_font(Name, Link)
    if not FontLoadingCapable then return end
    local fn = Name:gsub("%s+", "")
    local okDL, data = pcall(function() return game:HttpGet(Link) end)
    if not okDL or not data or data == "" then return end
    local okwrite = pcall(writefile, fn .. ".ttf", data)
    if not okWrite then return end
    local okconfig = pcall(function()
        local config = {
            name = fn,
            faces = { { name = "Regular", weight = 400, style = "normal", assetid = getcustomasset(fn .. ".ttf") } }
        }
        writefile(fn .. ".ttf.json", HttpService:JSONEncode(config))
    end)
    if not okConfig then return end
    local okLoad, font = pcall(Font.new, getcustomasset(fn .. ".ttf.json"), Enum.FontWeight.Regular)
    if okLoad and font then
        ESPFonts.Loaded[Name] = font
    end
end

local function attempt_load_fonts()
    if not FontLoadingCapable then fonts_still_loading = false; return end
    for Name, Table in pairs(FontsToDownload) do
        if ESPFonts.Loaded[Name] then continue end
        LoadCustomFont(Name, Table.TTF)
    end
    fonts_still_loading = false
    for Name in pairs(FontsToDownload) do
        if not ESPFonts.Loaded[Name] then fonts_still_loading = true; break end
    end
end

task.spawn(function()
    task.wait(1)
    AttemptLoadFonts()
end)



local tracked_instances = {}


local function get_instance_from_path(path)
    local parts = string.split(path, ".")
    local current = game
    for _, partName in ipairs(parts) do
        if current == game and (partname == "Workspace" or partname == "workspace") then
            current = Workspace
        elseif current == game and partname == "Players" then
            current = Players
        else
            local found = current:FindFirstChild(partName)
            if found then
                current = found
            else
                return nil
            end
        end
    end
    return current ~= game and current or nil
end

local function create_line(parent)
    local line = Instance.new("Frame")
    line.border_size_pixel = 0
    line.background_color3 = ESPConfig.BoxColor
    line.parent = parent

    local outline = Instance.new("Frame")
    outline.border_size_pixel = 0
    outline.background_color3 = ESPConfig.Outlines.Color
    outline.z_index = 0
    outline.parent = line

    return line, outline
end

local create_esp_obj = LPHNoVirtualize(function(name)
    local espobj = {
        visible = false,
        lines = {},
        outlines = {},
        corner_lines = {},
        corner_outlines = {},

        flag_labels = {},
        last_vis_check = 0,
        cached_model_visible = true
    }

    local container = Instance.new("Frame")
    container.background_transparency = 1
    container.name = "ESPObj"
    container.parent = ScreenGui
    espObj.container = container

    local boxfill = Instance.new("Frame")
    boxFill.border_size_pixel = 0
    boxFill.z_index = 0
    boxFill.visible = false
    boxFill.parent = container
    espObj.box_fill = boxFill

    local fillgradient = Instance.new("UIGradient")
    fillGradient.parent = boxFill
    espObj.box_fill_gradient = fillGradient

    for i = 1, 4 do
        local line, outline = CreateLine(container)
        espObj.Lines[i] = line
        espObj.Outlines[i] = outline
    end

    for i = 1, 8 do
        local line, outline = CreateLine(container)
        line.visible = false
        outline.visible = false
        espObj.CornerLines[i] = line
        espObj.CornerOutlines[i] = outline
    end

    local function setup_label(label)
        label.background_transparency = 1
        label.size = UDim2.new(0, 100, 0, ESPConfig.TextSize)
        label.font = _fontMap[ESPConfig.Font] or Enum.Font.Code
        if ESPFonts.Loaded[ESPConfig.Font] then
            label.font_face = ESPFonts.Loaded[ESPConfig.Font]
        end
        label.text_size = ESPConfig.TextSize
        label.text_color3 = ESPConfig.TextColor
        label.text_stroke_transparency = 1
        label.z_index = 2
        label.parent = container

        local stroke = Instance.new("UIStroke")
        stroke.thickness = 1
        stroke.color = ESPConfig.TextOutlineColor or ESPConfig.Outlines.Color
        stroke.line_join_mode = Enum.LineJoinMode.Miter
        stroke.enabled = ESPConfig.TextOutline
        stroke.parent = label
        labelStrokeMap[label] = stroke
    end

    local nametext = Instance.new("TextLabel")
    SetupLabel(nameText)
    nameText.text_y_alignment = Enum.TextYAlignment.Bottom
    nameText.rich_text = true
    nameText.text = name
    nameText.visible = ESPConfig.Names
    espObj.text = nameText

    espObj.team_text = nil
    espObj.team_text_stroke = nil
    espObj.friendly_text = nil
    espObj.friendly_text_stroke = nil

    local disttext = Instance.new("TextLabel")
    SetupLabel(distText)
    distText.text_y_alignment = Enum.TextYAlignment.Top
    distText.visible = false
    espObj.distance_text = distText

    local weapontext = Instance.new("TextLabel")
    SetupLabel(weaponText)
    weaponText.text_y_alignment = Enum.TextYAlignment.Top
    weaponText.visible = false
    espObj.weapon_text = weaponText

    local healthbar_outline = Instance.new("Frame")
    healthBarOutline.background_color3 = ESPConfig.Outlines.Color
    healthBarOutline.border_size_pixel = 0
    healthBarOutline.visible = false
    healthBarOutline.z_index = 1
    healthBarOutline.parent = container
    espObj.health_bar_outline = healthBarOutline

    local healthbar_container = Instance.new("Frame")
    healthBarContainer.background_transparency = 1
    healthBarContainer.clips_descendants = true
    healthBarContainer.border_size_pixel = 0
    healthBarContainer.z_index = 2
    healthBarContainer.parent = healthBarOutline
    espObj.health_bar_container = healthBarContainer

    local healthbar = Instance.new("Frame")
    healthBar.background_color3 = Color3.fromRGB(255, 255, 255)
    healthBar.border_size_pixel = 0
    healthBar.z_index = 2
    healthBar.parent = healthBarContainer
    espObj.health_bar = healthBar

    local healthgradient = Instance.new("UIGradient")
    healthGradient.enabled = ESPConfig.HealthBar.Gradient.Enabled
    healthGradient.color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ESPConfig.HealthBar.Gradient.Color1),
        ColorSequenceKeypoint.new(0.5, ESPConfig.HealthBar.Gradient.Color2),
        ColorSequenceKeypoint.new(1, ESPConfig.HealthBar.Gradient.Color3)
    })
    healthGradient.parent = healthBar
    espObj.health_gradient = healthGradient

    local healthtext = Instance.new("TextLabel")
    SetupLabel(healthText)
    healthText.text_y_alignment = Enum.TextYAlignment.Center
    healthText.z_index = 3
    healthText.visible = false
    espObj.health_text = healthText

    for i = 1, 5 do 
        local flag = Instance.new("TextLabel")
        SetupLabel(flag)
        flag.text_size = ESPConfig.Flags.TextSize
        flag.font = _fontMap[ESPConfig.Flags.Font] or Enum.Font.Code
        if ESPFonts.Loaded[ESPConfig.Flags.Font] then
            flag.font_face = ESPFonts.Loaded[ESPConfig.Flags.Font]
        end
        flag.visible = false
        espObj.FlagLabels[i] = flag
    end

    espObj.bones = {}
    espObj.bone_outlines = {}
    for i = 1, #SKELETON_BONE_DEFS do
        local outline = Instance.new("Frame")
        outline.border_size_pixel = 0
        outline.visible = false
        outline.z_index = 1
        outline.parent = container
        espObj.BoneOutlines[i] = outline

        local bone = Instance.new("Frame")
        bone.border_size_pixel = 0
        bone.visible = false
        bone.z_index = 2
        bone.parent = container
        espObj.Bones[i] = bone
    end

    local arrowinner = Instance.new("TextLabel")
    arrowInner.background_transparency = 1
    arrowInner.text = "▲"
    arrowInner.text_color3 = ESPConfig.OffScreenArrows.Color
    arrowInner.text_size = ESPConfig.OffScreenArrows.Size
    arrowInner.font = Enum.Font.SourceSans
    arrowInner.size = UDim2.new(0, ESPConfig.OffScreenArrows.Size * 2, 0, ESPConfig.OffScreenArrows.Size * 2)
    arrowInner.z_index = 100
    arrowInner.visible = false
    arrowInner.parent = ScreenGui
    espObj.arrow_inner = arrowInner

    local arrowoutline = Instance.new("TextLabel")
    arrowOutline.background_transparency = 1
    arrowOutline.text = "▲"
    arrowOutline.text_color3 = ESPConfig.OffScreenArrows.OutlineColor
    arrowOutline.text_size = ESPConfig.OffScreenArrows.Size + 2
    arrowOutline.font = Enum.Font.SourceSans
    arrowOutline.size = UDim2.new(0, (ESPConfig.OffScreenArrows.Size + 2) * 2, 0, (ESPConfig.OffScreenArrows.Size + 2) * 2)
    arrowOutline.z_index = 99
    arrowOutline.visible = false
    arrowOutline.parent = ScreenGui
    espObj.arrow_outline = arrowOutline

    local function makeArrowLabel()
        local l = Instance.new("TextLabel")
        l.background_transparency = 1
        l.size = UDim2.new(0, 150, 0, 12)
        l.text_stroke_transparency = 1
        l.z_index = 110
        l.text_color3 = Color3.fromRGB(255, 255, 255)
        l.visible = false
        l.parent = ScreenGui
        local stroke = Instance.new("UIStroke")
        stroke.parent = l
        labelStrokeMap[l] = stroke
        return l
    end
    espObj.arrow_name = makeArrowLabel()
    espObj.arrow_dist = makeArrowLabel()

    espObj.adornments = {}
    espObj.highlight = nil

    espObj.destroy = function()
        container:Destroy()
        if espObj.Highlight then espObj.Highlight:Destroy() end
        if espObj.MeshShell then espObj.MeshShell:Destroy() end
        for _, a in pairs(espObj.Adornments) do a:Destroy() end
        if espObj.ArrowInner then espObj.ArrowInner:Destroy() end
        if espObj.ArrowOutline then espObj.ArrowOutline:Destroy() end
        if espObj.ArrowName then espObj.ArrowName:Destroy() end
        if espObj.ArrowDist then espObj.ArrowDist:Destroy() end
    end

    return espObj
end)

local update_esp_obj = LPHNoVirtualize(function(espObj, position, size, name, distanceStuds, instance, isCheap, nonHuman,
                                              noStatus,
                                              configOverride, onScreen)
    local cfgcache = {}
    local function get_cfg(path)
        local cached = cfgCache[path]
        if cached ~= nil then return cached end
        local keys = path:split(".")
        local current = configOverride
        local default = ESPConfig

        local foundoverride = true
        for _, key in ipairs(keys) do
            if type(current) == "table" and current[key] ~= nil then
                current = current[key]
            else
                foundoverride = false
                break
            end
        end

        if foundOverride then
            cfgCache[path] = current
            return current
        end

        local currentdefault = default
        for _, key in ipairs(keys) do
            currentdefault = currentDefault[key]
        end
        cfgCache[path] = currentDefault
        return currentDefault
    end

    local _now = tick()
    local humanoid = not nonHuman and instance:FindFirstChild("Humanoid") or nil

    
    local isdead = (humanoid and humanoid.Health <= 0)
    local chamsenabled = GetCfg("Chams.Enabled")
    if chamsEnabled and not isDead then
        local chamtype = GetCfg("Chams.Type")
        if chamtype == "Highlight" and (instance:IsA("Model") or instance:IsA("BasePart")) then
            
            if espObj.MeshShell then
                espObj.MeshShell:Destroy()
                espObj.mesh_shell = nil
                espObj.mesh_highlight = nil
            end
            if not espObj.Highlight then
                espObj.highlight = Instance.new("Highlight")
            end
            local h = espObj.Highlight
            h.parent = ChamsContainer
            h.adornee = instance
            h.fill_color = GetCfg("Chams.Highlight.FillColor")
            h.fill_transparency = GetCfg("Chams.Highlight.FillTransparency")
            h.outline_color = GetCfg("Chams.Highlight.OutlineColor")
            h.outline_transparency = GetCfg("Chams.Highlight.OutlineTransparency")
            h.depth_mode = GetCfg("Chams.Highlight.VisibleCheck") and Enum.HighlightDepthMode.Occluded or
                Enum.HighlightDepthMode.AlwaysOnTop
            h.enabled = true

            
            if espObj.Adornments then
                for _, a in pairs(espObj.Adornments) do a.visible = false end
            end
        elseif chamtype == "Adornment" then
            if espObj.Highlight then
                espObj.Highlight:Destroy()
                espObj.highlight = nil
            end
            
            if espObj.MeshShell then
                espObj.MeshShell:Destroy()
                espObj.mesh_shell = nil
                espObj.mesh_highlight = nil
            end

            local parts = instance:IsA("Model") and instance:GetChildren() or { instance }
            local idx = 0

            local vischeck = GetCfg("Chams.Adornment.VisibleCheck")
            local visrate = GetCfg("VisibilityCheckRate") or 0.1
            local now = _now
            local last = espObj.LastVisCheck or 0
            local shouldupdate = (now - last) > visRate

            if visCheck and shouldUpdate then
                espObj.last_vis_check = now
                local ignore = { UIContainer }
                if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
                if instance:IsA("Model") then
                    for _, v in ipairs(instance:GetDescendants()) do table.insert(ignore, v) end
                else
                    table.insert(ignore, instance)
                end

                local root = instance:IsA("Model") and
                    (instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChildWhichIsA("BasePart")) or
                    instance
                if root and root:IsA("BasePart") then
                    local obscuring = Camera:GetPartsObscuringTarget({ root.Position }, ignore)
                    espObj.cached_model_visible = (#obscuring == 0)
                end
            end

            local occludedcolor = GetCfg("Chams.Adornment.Color")
            local visiblecolor = GetCfg("Chams.Adornment.VisibleColor")
            local finalcolor = (visCheck and espObj.CachedModelVisible) and visibleColor or occludedColor

            for _, p in ipairs(parts) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    idx = idx + 1
                    local a = espObj.Adornments[idx]
                    if not a then
                        a = Instance.new("BoxHandleAdornment")
                        a.name = "Cham"
                        a.parent = ChamsContainer
                        espObj.Adornments[idx] = a
                    end

                    a.adornee = p
                    a.size = p.Size
                    a.color3 = finalColor
                    a.transparency = GetCfg("Chams.Adornment.Transparency")
                    a.always_on_top = GetCfg("Chams.Adornment.AlwaysOnTop")
                    a.z_index = 10
                    a.visible = true
                end
            end
            
            for i = idx + 1, #espObj.Adornments do
                espObj.Adornments[i].visible = false
            end
        elseif chamtype == "MeshChams" then
            
            
            local playerowner = Players:GetPlayerFromCharacter(instance)
            if not playerOwner then
                if espObj.MeshShell then
                    espObj.MeshShell:Destroy()
                    espObj.mesh_shell = nil
                    espObj.mesh_highlight = nil
                end
            else
                
                if espObj.Highlight then
                    espObj.Highlight:Destroy()
                    espObj.highlight = nil
                end
                if espObj.Adornments then
                    for _, a in pairs(espObj.Adornments) do a.visible = false end
                end

                
                if not espObj.MeshShell or not espObj.MeshShell.Parent then
                    if espObj.MeshShell then
                        espObj.MeshShell:Destroy()
                        espObj.mesh_shell = nil
                        espObj.mesh_highlight = nil
                    end

                    CleanupCharacterMeshChams(instance)

                    local r6parts = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
                    local r15parts = {
                        "Head", "UpperTorso", "LowerTorso",
                        "LeftUpperArm", "LeftLowerArm", "LeftHand",
                        "RightUpperArm", "RightLowerArm", "RightHand",
                        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
                        "RightUpperLeg", "RightLowerLeg", "RightFoot",
                    }
                    local humanoidinst = instance:FindFirstChild("Humanoid")
                    local isr15 = humanoidInst and (humanoidInst.rig_type == Enum.HumanoidRigType.R15)
                    local bodyparts = isR15 and r15Parts or r6Parts

                    local shellmodel = Instance.new("Model")
                    shellModel.name = "ChamShells"
                    shellModel:SetAttribute("SensoryESP_MeshCham", true)
                    shellModel:SetAttribute("SensoryESP_RunId", CurrentRunId)
                    shellModel.parent = instance

                    for _, partName in ipairs(bodyParts) do
                        local realpart = instance:FindFirstChild(partName)
                        if realPart and realPart:IsA("BasePart") then
                            local shell = Instance.new("Part")
                            shell.name = "ChamShell_" .. partName
                            shell:SetAttribute("SensoryESP_MeshCham", true)
                            shell:SetAttribute("SensoryESP_RunId", CurrentRunId)
                            shell.size = realPart.Size * 1.015
                            shell.transparency = 0.9999999
                            shell.cast_shadow = false
                            shell.can_collide = false
                            shell.can_query = false
                            shell.can_touch = false
                            shell.anchored = false
                            shell.massless = true
                            shell.c_frame = realPart.CFrame
                            shell.parent = shellModel

                            local weld         = Instance.new("Weld")
                            weld.part0 = shell
                            weld.part1 = realPart
                            weld.c0 = CFrame.new()
                            weld.c1 = CFrame.new()
                            weld.parent = shell
                        end
                    end

                    
                    local hl = Instance.new("Highlight")
                    hl.name = "ChamShellHighlight"
                    hl:SetAttribute("SensoryESP_MeshCham", true)
                    hl:SetAttribute("SensoryESP_RunId", CurrentRunId)
                    hl.adornee = shellModel
                    hl.parent = shellModel
                    espObj.mesh_shell = shellModel
                    espObj.mesh_highlight = hl
                end

                
                if espObj.MeshHighlight then
                    local hl               = espObj.MeshHighlight
                    hl.fill_color = GetCfg("Chams.MeshChams.FillColor")
                    hl.fill_transparency = GetCfg("Chams.MeshChams.FillTransparency")
                    hl.outline_color = GetCfg("Chams.MeshChams.OutlineColor")
                    hl.outline_transparency = GetCfg("Chams.MeshChams.OutlineTransparency")
                    hl.depth_mode = GetCfg("Chams.MeshChams.VisibleCheck")
                        and Enum.HighlightDepthMode.Occluded
                        or Enum.HighlightDepthMode.AlwaysOnTop
                    hl.enabled = true
                end
            end
        end
    else
        
        if espObj.Highlight then
            espObj.Highlight:Destroy()
            espObj.highlight = nil
        end
        if espObj.Adornments then
            for _, a in pairs(espObj.Adornments) do a.visible = false end
        end
        if espObj.MeshShell then
            espObj.MeshShell:Destroy()
            espObj.mesh_shell = nil
            espObj.mesh_highlight = nil
        end
    end

    local function apply_text_outline(label, style, color)
        local stroke = labelStrokeMap[label] or label:FindFirstChildOfClass("UIStroke")
        if not stroke then return end
        if style == "None" then
            stroke.enabled = false
        elseif style == "Shadow" then
            stroke.enabled = true
            stroke.thickness = 1
            stroke.color = color or Color3.fromRGB(0, 0, 0)
        else
            stroke.enabled = true
            stroke.thickness = 1
            stroke.color = color or Color3.fromRGB(0, 0, 0)
        end
    end

    
    if espObj.ArrowInner and GetCfg("OffScreenArrows.Enabled") and instance:IsA("Model") then
        local rp = instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChildWhichIsA("BasePart")
        if rp then
            local sp = Camera:WorldToViewportPoint(rp.Position)
            local vp = Camera.ViewportSize
            local cx, cy = vp.X / 2, vp.Y / 2
            local onvp = sp.Z > 0 and sp.X >= 0 and sp.X <= vp.X and sp.Y >= 0 and sp.Y <= vp.Y
            if not onVp then
                local orbit = GetCfg("OffScreenArrows.OrbitRadius")
                local nx, ny, rot
                if GetCfg("OffScreenArrows.ArrowMode") == "Compass" then
                    
                    local playerroot = LocalPlayer.Character and (
                        LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or
                        LocalPlayer.Character:FindFirstChild("Torso") or
                        LocalPlayer.Character:FindFirstChildWhichIsA("BasePart")
                    )
                    local frompos = playerRoot and playerRoot.Position or Camera.CFrame.Position
                    local totarget = (Vector3.new(rp.Position.X, 0, rp.Position.Z) - Vector3.new(fromPos.X, 0, fromPos.Z)).Unit
                    local rel = playerRoot and playerRoot.CFrame:VectorToObjectSpace(toTarget) or toTarget
                    nx, ny = rel.X, rel.Z
                    rot = math.deg(math.atan2(rel.Z, rel.X)) + 90
                else
                    
                    local dir = (rp.Position - Camera.CFrame.Position).Unit
                    local viewdir = Camera.CFrame:VectorToObjectSpace(dir)
                    nx, ny = viewDir.X, -viewDir.Y
                    rot = math.deg(math.atan2(-viewDir.Y, viewDir.X)) + 90
                end
                local d = math.sqrt(nx * nx + ny * ny)
                if d > 0.001 then
                    nx, ny = nx / d, ny / d
                else
                    nx, ny = 0, -1
                end
                local ax, ay = cx + nx * orbit, cy + ny * orbit
                local sz = GetCfg("OffScreenArrows.Size")
                local col = GetCfg("OffScreenArrows.Color")

                if GetCfg("OffScreenArrows.Outline") then
                    espObj.ArrowOutline.text_size = sz + 2
                    espObj.ArrowOutline.text_color3 = GetCfg("OffScreenArrows.OutlineColor")
                    espObj.ArrowOutline.position = UDim2.new(0, ax - sz - 2, 0, ay - sz - 2)
                    espObj.ArrowOutline.rotation = rot
                    espObj.ArrowOutline.visible = true
                else
                    espObj.ArrowOutline.visible = false
                end

                local arrowfont_obj = _fontMap[GetCfg("OffScreenArrows.Font")] or Enum.Font.SourceSans
                espObj.ArrowInner.text = "▲"
                espObj.ArrowInner.font = arrowFontObj
                espObj.ArrowInner.text_size = sz
                espObj.ArrowInner.text_color3 = col
                espObj.ArrowInner.position = UDim2.new(0, ax - sz, 0, ay - sz)
                espObj.ArrowInner.size = UDim2.new(0, sz * 2, 0, sz * 2)
                espObj.ArrowInner.rotation = rot
                espObj.ArrowInner.visible = true

                
                local textY = ay + sz + 4

                if GetCfg("OffScreenArrows.Names.Enabled") and name and name ~= "" then
                    local nfont = GetCfg("OffScreenArrows.Names.Font")
                    local ntxt_sz = GetCfg("OffScreenArrows.Names.TextSize")
                    local nfont_obj = _fontMap[nFont] or Enum.Font.Code
                    local nfont_loaded = ESPFonts.Loaded[nFont]
                    local nside = GetCfg("OffScreenArrows.Names.Side")
                    local ngap = GetCfg("OffScreenArrows.Names.Gap") or 4
                    local ncol = GetCfg("OffScreenArrows.Names.Color")
                    local nout = GetCfg("OffScreenArrows.Names.Outline")
                    local nout_col = GetCfg("OffScreenArrows.Names.OutlineColor")
                    espObj.ArrowName.font = nFontObj
                    if nFontLoaded then espObj.ArrowName.font_face = nFontLoaded end
                    espObj.ArrowName.text_size = nTxtSz
                    espObj.ArrowName.text_color3 = nCol
                    espObj.ArrowName.text = name
                    if nside == "Top" then
                        espObj.ArrowName.position = UDim2.new(0, ax - 75, 0, ay - sz - nGap - nTxtSz)
                    elseif nside == "Left" then
                        espObj.ArrowName.position = UDim2.new(0, ax - sz - nGap - 150, 0, ay - 6)
                    elseif nside == "Right" then
                        espObj.ArrowName.position = UDim2.new(0, ax + sz + nGap, 0, ay - 6)
                    else
                        espObj.ArrowName.position = UDim2.new(0, ax - 75, 0, textY)
                        textY = textY + nTxtSz + 1
                    end
                    ApplyTextOutline(espObj.ArrowName, nOut and "Full" or "None", nOutCol or Color3.fromRGB(0, 0, 0))
                    espObj.ArrowName.visible = true
                else
                    espObj.ArrowName.visible = false
                end

                if GetCfg("OffScreenArrows.Distance.Enabled") then
                    local dfont = GetCfg("OffScreenArrows.Distance.Font")
                    local dtxt_sz = GetCfg("OffScreenArrows.Distance.TextSize")
                    local dfont_obj = _fontMap[dFont] or Enum.Font.Code
                    local dfont_loaded = ESPFonts.Loaded[dFont]
                    local dside = GetCfg("OffScreenArrows.Distance.Side")
                    local dgap = GetCfg("OffScreenArrows.Distance.Gap") or 2
                    local dcol = GetCfg("OffScreenArrows.Distance.Color")
                    local dout = GetCfg("OffScreenArrows.Distance.Outline")
                    local dout_col = GetCfg("OffScreenArrows.Distance.OutlineColor")
                    local dunit = GetCfg("Distance.Unit")
                    local dVal
                    if dunit == "Meters" then
                        dval = math.floor(distanceStuds / GetCfg("Distance.StudsPerMeter"))
                    else
                        dval = math.floor(distanceStuds)
                    end
                    espObj.ArrowDist.font = dFontObj
                    if dFontLoaded then espObj.ArrowDist.font_face = dFontLoaded end
                    espObj.ArrowDist.text_size = dTxtSz
                    espObj.ArrowDist.text_color3 = dCol
                    espObj.ArrowDist.text = dVal .. GetCfg("Distance.Ending")
                    if dside == "Top" then
                        espObj.ArrowDist.position = UDim2.new(0, ax - 75, 0, ay - sz - dGap - dTxtSz)
                    elseif dside == "Left" then
                        espObj.ArrowDist.position = UDim2.new(0, ax - sz - dGap - 150, 0, ay - 6)
                    elseif dside == "Right" then
                        espObj.ArrowDist.position = UDim2.new(0, ax + sz + dGap, 0, ay - 6)
                    else
                        espObj.ArrowDist.position = UDim2.new(0, ax - 75, 0, textY)
                    end
                    ApplyTextOutline(espObj.ArrowDist, dOut and "Full" or "None", dOutCol or Color3.fromRGB(0, 0, 0))
                    espObj.ArrowDist.visible = true
                else
                    espObj.ArrowDist.visible = false
                end
            else
                espObj.ArrowInner.visible = false
                espObj.ArrowOutline.visible = false
                espObj.ArrowName.visible = false
                espObj.ArrowDist.visible = false
            end
        else
            espObj.ArrowInner.visible = false
            espObj.ArrowOutline.visible = false
            espObj.ArrowName.visible = false
            espObj.ArrowDist.visible = false
        end
    else
        if espObj.ArrowInner then
            espObj.ArrowInner.visible = false
            espObj.ArrowOutline.visible = false
            espObj.ArrowName.visible = false
            espObj.ArrowDist.visible = false
        end
    end

    if not onScreen or not position or not size then
        espObj.Container.visible = false
        return
    end

    espObj.Container.visible = true
    espObj.Container.z_index = nonHuman and 1 or 10
    if GetCfg("Names") then
        espObj.Text.text = name
    end

    local textoutline_style = GetCfg("TextOutlineStyle")
    
    if GetCfg("TextOutline") == false then textoutline_style = "None" end
    local textoutline_color = GetCfg("TextOutlineColor") or GetCfg("Outlines.Color")

    local t = GetCfg("BoxThickness")
    local o = GetCfg("Outlines.Thickness")
    local textsize = GetCfg("TextSize")
    local textcolor = GetCfg("TextColor")
    local fontname = GetCfg("Font")
    local fontobj = _fontMap[fontName] or Enum.Font.Code
    local fontloaded = ESPFonts.Loaded[fontName]
    local boxcolor = GetCfg("BoxColor")
    
    espObj.Text.text_size = textSize
    espObj.Text.text_color3 = textColor
    espObj.Text.font = fontObj
    if fontLoaded then
        espObj.Text.font_face = fontLoaded
    end
    ApplyTextOutline(espObj.Text, textOutlineStyle, textOutlineColor)

    do
        local distfont = GetCfg("Distance.Font")
        local distfont_obj = _fontMap[distFont] or Enum.Font.Code
        espObj.DistanceText.text_size = GetCfg("Distance.TextSize") or textSize
        espObj.DistanceText.text_color3 = GetCfg("Distance.Color")
        espObj.DistanceText.font = distFontObj
        if ESPFonts.Loaded[distFont] then
            espObj.DistanceText.font_face = ESPFonts.Loaded[distFont]
        end
        ApplyTextOutline(espObj.DistanceText, GetCfg("Distance.OutlineStyle") or textOutlineStyle, textOutlineColor)
    end

    do
        local wepfont = GetCfg("Weapon.Font")
        local wepfont_obj = _fontMap[wepFont] or Enum.Font.Code
        espObj.WeaponText.text_size = GetCfg("Weapon.TextSize") or textSize
        espObj.WeaponText.text_color3 = GetCfg("Weapon.Color")
        espObj.WeaponText.font = wepFontObj
        if ESPFonts.Loaded[wepFont] then
            espObj.WeaponText.font_face = ESPFonts.Loaded[wepFont]
        end
        ApplyTextOutline(espObj.WeaponText, GetCfg("Weapon.OutlineStyle") or textOutlineStyle, textOutlineColor)
    end

    local px, py = math.floor(position.X), math.floor(position.Y)
    local sx, sy = math.floor(size.X), math.floor(size.Y)
    local x, y = math.floor(px - sx / 2), math.floor(py - sy / 2)

    
    local health, maxHealth, healthpercent = 100, 100, 1
    if humanoid then
        health = humanoid.Health
        maxhealth = humanoid.MaxHealth
        healthpercent = math.clamp(health / maxHealth, 0, 1)
    end

    
    local topoffset = 0
    local bottomoffset = 0
    local leftoffset = 0
    local rightoffset = 0
    if GetCfg("HealthBar.Enabled") and instance:IsA("Model") and humanoid then
        local hppos = GetCfg("HealthBar.Position")
        local thickness = GetCfg("HealthBar.Width") + 2 + GetCfg("HealthBar.SideGap")
        local isright = GetCfg("Flags.Position") == "Right"
        local textextra = (GetCfg("HealthBar.ShowText") and health < maxHealth) and 20 or 0

        if hppos == "Top" then
            topoffset = thickness
        elseif hppos == "Bottom" then
            bottomoffset = thickness
        elseif hppos == "Left" then
            leftoffset = thickness + textExtra
        elseif hppos == "Right" then
            rightoffset = thickness + textExtra
        end
    end

    if isCheap then
        for i = 1, 4 do
            espObj.Lines[i].visible = false
            espObj.Outlines[i].visible = false
        end
        espObj.HealthBarOutline.visible = false
        espObj.HealthText.visible = false
        espObj.WeaponText.visible = false
        for _, l in ipairs(espObj.FlagLabels) do l.visible = false end

        local distunit = GetCfg("Distance.Unit")
        local distval = distanceStuds
        if distunit == "Meters" then
            distval = math.floor(distanceStuds / GetCfg("Distance.StudsPerMeter"))
        else
            distval = math.floor(distanceStuds)
        end

        espObj.Text.text = name .. " " .. distVal .. GetCfg("Distance.Ending")
        espObj.Text.position = UDim2.new(0, px - 50, 0, py - (textSize / 2))
        espObj.Text.visible = GetCfg("Names")
        espObj.DistanceText.visible = false
        return
    end

    
    espObj.Lines[1].position = UDim2.new(0, x, 0, y)
    espObj.Lines[1].size = UDim2.new(0, sx, 0, t)
    
    espObj.Lines[2].position = UDim2.new(0, x, 0, y + sy)
    espObj.Lines[2].size = UDim2.new(0, sx + t, 0, t)
    
    espObj.Lines[3].position = UDim2.new(0, x, 0, y)
    espObj.Lines[3].size = UDim2.new(0, t, 0, sy)
    
    espObj.Lines[4].position = UDim2.new(0, x + sx, 0, y)
    espObj.Lines[4].size = UDim2.new(0, t, 0, sy + t)

    local boxesenabled = GetCfg("Boxes")
    local boxtype = GetCfg("BoxType") or "Normal"
    local usecorner_boxes = boxtype == "Corner"

    local outlinestyle = GetCfg("Outlines.Style")
    local outlinecolor = GetCfg("Outlines.Color")
    local outlinethickness = GetCfg("Outlines.Thickness")
    
    if GetCfg("Outlines.Enabled") == false then outlinestyle = "None" end
    local outlinetransparency = 0
    local hasoutline = outlineStyle ~= "None"

    if useCornerBoxes then
        local cornerwidth = math.max(math.floor(sx * 0.25), t * 3)
        local cornerheight = math.max(math.floor(sy * 0.25), t * 3)

        local cornerdata = {
            { x,                        y,                         cornerWidth, t },
            { x,                        y,                         t,           cornerHeight },
            { x + sx - cornerWidth + t, y,                         cornerWidth, t },
            { x + sx,                   y,                         t,           cornerHeight },
            { x,                        y + sy,                    cornerWidth, t },
            { x,                        y + sy - cornerHeight + t, t,           cornerHeight },
            { x + sx - cornerWidth + t, y + sy,                    cornerWidth, t },
            { x + sx,                   y + sy - cornerHeight + t, t,           cornerHeight },
        }

        for i = 1, 8 do
            local data = cornerData[i]
            espObj.CornerLines[i].position = UDim2.new(0, data[1], 0, data[2])
            espObj.CornerLines[i].size = UDim2.new(0, data[3], 0, data[4])
        end
    end

    for i = 1, 4 do
        espObj.Lines[i].visible = boxesEnabled and not useCornerBoxes
        espObj.Outlines[i].visible = boxesEnabled and hasOutline and not useCornerBoxes

        espObj.Outlines[i].position = UDim2.new(0, -outlineThickness, 0, -outlineThickness)
        espObj.Outlines[i].size = UDim2.new(1, outlineThickness * 2, 1, outlineThickness * 2)
        espObj.Outlines[i].background_transparency = outlineTransparency
        espObj.Lines[i].background_color3 = boxColor
        espObj.Outlines[i].background_color3 = outlineColor
    end

    for i = 1, 8 do
        espObj.CornerLines[i].visible = boxesEnabled and useCornerBoxes
        espObj.CornerOutlines[i].visible = boxesEnabled and hasOutline and useCornerBoxes

        espObj.CornerOutlines[i].position = UDim2.new(0, -outlineThickness, 0, -outlineThickness)
        espObj.CornerOutlines[i].size = UDim2.new(1, outlineThickness * 2, 1, outlineThickness * 2)
        espObj.CornerOutlines[i].background_transparency = outlineTransparency
        espObj.CornerLines[i].background_color3 = boxColor
        espObj.CornerOutlines[i].background_color3 = outlineColor
    end

    
    local fill = espObj.BoxFill
    local grad = espObj.BoxFillGradient
    if GetCfg("BoxFill.Enabled") and boxesEnabled then
        fill.visible = true
        fill.position = UDim2.new(0, x, 0, y)
        fill.size = UDim2.new(0, sx, 0, sy)
        fill.background_transparency = GetCfg("BoxFill.Transparency")

        if GetCfg("BoxFill.Gradient.Enabled") then
            grad.enabled = true
            local bgc1 = GetCfg("BoxFill.Gradient.Color1")
            local bgc2 = GetCfg("BoxFill.Gradient.Color2")
            local bgc3 = GetCfg("BoxFill.Gradient.Color3")
            grad.color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, bgC1),
                ColorSequenceKeypoint.new(0.5, bgC2),
                ColorSequenceKeypoint.new(1, bgC3)
            })

            local rot = GetCfg("BoxFill.Gradient.Rotation")
            if GetCfg("BoxFill.Gradient.Animated") then
                local speed = GetCfg("BoxFill.Gradient.Speed")
                local dir = GetCfg("BoxFill.Gradient.Direction") == "Left" and -1 or 1
                rot = (rot + (_now * speed * dir)) % 360
            end
            grad.rotation = rot
            fill.background_color3 = Color3.fromRGB(255, 255, 255)
        else
            grad.enabled = false
            fill.background_color3 = GetCfg("BoxFill.Color")
        end
    else
        fill.visible = false
    end

    local nameY = y - textSize - (GetCfg("TextGap") or 0) - topOffset
    local teamowner = instance:IsA("Model") and Players:GetPlayerFromCharacter(instance) or nil
    local lefttags = {}
    local righttags = {}

    if GetCfg("TeamIndicator.Enabled") and teamOwner and teamOwner.Team then
        local teamcolor = GetCfg("TeamIndicator.UseTeamColor") and teamOwner.TeamColor.Color or
        GetCfg("TeamIndicator.Color")
        local teamname = teamOwner.Team.Name
        local compactteam = GetCfg("TeamIndicator.Compact") and CompactTeamName(teamName) or teamName
        local teamtag = string.format('<font color="%s">[%s]</font>', ColorToHex(teamColor), compactTeam)
        if GetCfg("TeamIndicator.Position") == "Left" then
            table.insert(leftTags, teamTag)
        else
            table.insert(rightTags, teamTag)
        end
    end

    local isfriendly = false
    if teamOwner and GetCfg("FriendlyIndicator.Enabled") then
        if GetCfg("FriendlyIndicator.CheckTeam") and (false) then
            isfriendly = true
        end
        if not isFriendly and GetCfg("FriendlyIndicator.CheckFriends") then
            local ok, result = pcall(function()
                return LocalPlayer:IsFriendsWith(teamOwner.UserId)
            end)
            if ok and result then
                isfriendly = true
            end
        end
    end

    if isFriendly then
        local friendlytag = string.format('<font color="%s">%s</font>', ColorToHex(GetCfg("FriendlyIndicator.Color")),
            GetCfg("FriendlyIndicator.Text"))
        if GetCfg("FriendlyIndicator.Position") == "Left" then
            table.insert(leftTags, friendlyTag)
        else
            table.insert(rightTags, friendlyTag)
        end
    end

    local finalname_text = name
    if #leftTags > 0 then
        finalname_text = table.concat(leftTags, " ") .. " " .. finalNameText
    end
    if #rightTags > 0 then
        finalname_text = finalNameText .. " " .. table.concat(rightTags, " ")
    end

    if GetCfg("Names") then
        espObj.Text.text = finalNameText
        espObj.Text.position = UDim2.new(0, px - 50, 0, nameY)
        espObj.Text.visible = true
    else
        espObj.Text.visible = false
    end

    local distgap = GetCfg("Distance.Gap") or 0
    local currentbottom_y = y + sy + distGap + bottomOffset
    if GetCfg("Distance.Enabled") then
        espObj.DistanceText.visible = true
        espObj.DistanceText.position = UDim2.new(0, px - 50, 0, currentBottomY)

        local distunit = GetCfg("Distance.Unit")
        local distval = distanceStuds
        if distunit == "Meters" then
            distval = math.floor(distanceStuds / GetCfg("Distance.StudsPerMeter"))
        else
            distval = math.floor(distanceStuds)
        end
        espObj.DistanceText.text = distVal .. GetCfg("Distance.Ending")
        currentbottom_y = currentBottomY + (GetCfg("Distance.TextSize") or textSize) + (GetCfg("Weapon.Gap") or 0)
    else
        espObj.DistanceText.visible = false
    end

    
    if GetCfg("Weapon.Enabled") then
        local weaponname = nil

        
        local holding = instance:FindFirstChild("Holding")
        if holding then
            if holding:IsA("ValueBase") then
                if holding.Value then
                    weaponname = tostring(holding.Value)
                end
            else
                weaponname = holding.Name
            end
        end

        
        if (not weaponName or weaponname == "" or weaponname == "nil") and GetCfg("Weapon.UseToolFallback") then
            local tool = instance:FindFirstChildWhichIsA("Tool")
            if tool then weaponname = tool.Name end
        end

        if weaponName and weaponName ~= "" and weaponName ~= "nil" then
            espObj.WeaponText.visible = true
            espObj.WeaponText.text = weaponName
            espObj.WeaponText.position = UDim2.new(0, px - 50, 0, currentBottomY)
        else
            espObj.WeaponText.visible = false
        end
    else
        espObj.WeaponText.visible = false
    end

    
    if GetCfg("HealthBar.Enabled") and instance:IsA("Model") and humanoid then
        
        local hppos = GetCfg("HealthBar.Position")
        local ishorizontal = (hppos == "Top" or hppos == "Bottom")
        local hpwidth = GetCfg("HealthBar.Width")
        local hpside_gap = GetCfg("HealthBar.SideGap")
        local hptext_follow_bar = GetCfg("HealthBar.TextFollowBar")

        local hpoutline_style = GetCfg("HealthBar.Outline.Style")
        
        if GetCfg("HealthBar.Outline.Enabled") == false then hpoutline_style = "None" end
        espObj.HealthBarOutline.visible = hpOutlineStyle ~= "None"
        espObj.HealthBarOutline.background_transparency = 0
        espObj.HealthBarOutline.background_color3 = GetCfg("HealthBar.Outline.Color")
        local barWidth

        if isHorizontal then
            barwidth = math.floor((sx + 1) * healthPercent)
            espObj.HealthBarOutline.size = UDim2.new(0, sx + 3, 0, hpWidth + 2)

            if hppos == "Top" then
                espObj.HealthBarOutline.position = UDim2.new(0, x - 1, 0,
                    y - o - hpSideGap - hpWidth - 1)
            else 
                espObj.HealthBarOutline.position = UDim2.new(0, x - 1, 0, y + sy + o + hpSideGap)
            end

            espObj.HealthBarContainer.size = UDim2.new(0, barWidth, 0, hpWidth)
            espObj.HealthBarContainer.position = UDim2.new(0, 1, 0, 1)

            espObj.HealthBar.size = UDim2.new(0, sx + 1, 0, hpWidth)
            espObj.HealthBar.position = UDim2.new(0, 0, 0, 0)
        else 
            local barheight = math.floor((sy + 1) * healthPercent)
            espObj.HealthBarOutline.size = UDim2.new(0, hpWidth + 2, 0, sy + 3)

            if hppos == "Left" then
                espObj.HealthBarOutline.position = UDim2.new(0,
                    x - o - hpSideGap - hpWidth - 1, 0, y - 1)
            else 
                espObj.HealthBarOutline.position = UDim2.new(0, x + sx + o + hpSideGap, 0, y - 1)
            end

            espObj.HealthBarContainer.size = UDim2.new(0, hpWidth, 0, barHeight)
            espObj.HealthBarContainer.position = UDim2.new(0, 1, 0, (sy + 1) - barHeight + 1)

            espObj.HealthBar.size = UDim2.new(0, hpWidth, 0, sy + 1)
            espObj.HealthBar.position = UDim2.new(0, 0, 0, -(sy + 1 - barHeight))
        end

        
        local gradientenabled = GetCfg("HealthBar.Gradient.Enabled")
        local showtext = GetCfg("HealthBar.ShowText")
        if GetCfg("HealthBar.HideWhenFullHP") and health >= maxHealth then
            showtext = false
        end
        local followcolor_text = showText and GetCfg("HealthBar.FollowGradientColorText")
        local healthcolor = Color3.fromHSV(healthPercent * 0.3, 1, 1)

        if gradientEnabled and not isHorizontal then
            espObj.HealthGradient.rotation = 90
            espObj.HealthBar.background_color3 = Color3.fromRGB(255, 255, 255)

            if followColorText then
                if healthPercent > 0.5 then
                    local ratio = (1 - healthPercent) * 2
                    healthcolor = GetCfg("HealthBar.Gradient.Color1"):Lerp(GetCfg("HealthBar.Gradient.Color2"), ratio)
                else
                    local ratio = (0.5 - healthPercent) * 2
                    healthcolor = GetCfg("HealthBar.Gradient.Color2"):Lerp(GetCfg("HealthBar.Gradient.Color3"), ratio)
                end
            end
        else
            espObj.HealthBar.background_color3 = healthColor
        end

        if showText then
            espObj.HealthText.visible = true
            espObj.HealthText.text = math.floor(health)
            espObj.HealthText.text_size = GetCfg("HealthBar.TextSize")
            local hpfont = GetCfg("HealthBar.Font")
            local hpfont_obj = _fontMap[hpFont] or Enum.Font.Code
            espObj.HealthText.font = hpFontObj
            if ESPFonts.Loaded[hpFont] then
                espObj.HealthText.font_face = ESPFonts.Loaded[hpFont]
            end
            espObj.HealthText.text_color3 = followColorText and healthColor or GetCfg("TextColor")
            ApplyTextOutline(espObj.HealthText, hpOutlineStyle, textOutlineColor)

            if isHorizontal then
                barwidth = math.floor((sx + 1) * healthPercent)
                local barleft_x = x + barWidth - 1
                local textY = espObj.HealthBarOutline.Position.Y.Offset

                espObj.HealthText.text_x_alignment = Enum.TextXAlignment.Center
                espObj.HealthText.size = UDim2.new(0, 0, 0, 0)

                if hpTextFollowBar then
                    espObj.HealthText.position = UDim2.new(0, barLeftX, 0, textY + (hpWidth / 2) + 1)
                else
                    espObj.HealthText.position = UDim2.new(0, x + sx, 0, textY + (hpWidth / 2) + 1)
                end
            else
                local barheight = math.floor((sy + 1) * healthPercent)
                local baroutline_x = espObj.HealthBarOutline.Position.X.Offset
                local bartop_y = y + (sy + 1) - barHeight

                espObj.HealthText.text_x_alignment = hppos == "Left" and Enum.TextXAlignment.Right or
                    Enum.TextXAlignment.Left
                espObj.HealthText.size = UDim2.new(0, 0, 0, 0)

                local textX = hppos == "Left" and (barOutlineX - 2) or (barOutlineX + hpWidth + 4)
                local textY = hpTextFollowBar and barTopY or y
                espObj.HealthText.position = UDim2.new(0, textX, 0, textY)
            end
        else
            espObj.HealthText.visible = false
        end
    else
        espObj.HealthBarOutline.visible = false
        espObj.HealthText.visible = false
    end

    
    for _, label in ipairs(espObj.FlagLabels) do label.visible = false end
    if GetCfg("Flags.Enabled") and instance:IsA("Model") and not noStatus and humanoid then
            local state = humanoid:GetState()
            local ismoving = humanoid.MoveDirection.Magnitude > 0
            local isjumping = (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Freefall)
            local isswimming = state == Enum.HumanoidStateType.Swimming
            local flagoptions_moving = GetCfg("Flags.Options.Moving")
            local flagoptions_jumping = GetCfg("Flags.Options.Jumping")
            local flagoptions_swimming = GetCfg("Flags.Options.Swimming")
            local flagoptions_idle = GetCfg("Flags.Options.Idle")
            local flagcolors_moving = GetCfg("Flags.Colors.Moving")
            local flagcolors_jumping = GetCfg("Flags.Colors.Jumping")
            local flagcolors_swimming = GetCfg("Flags.Colors.Swimming")
            local flagcolors_idle = GetCfg("Flags.Colors.Idle")
            local flagfont = GetCfg("Flags.Font")
            local flagtext_size = GetCfg("Flags.TextSize")
            local flagtext_gap = GetCfg("Flags.TextGap")
            local flaggap = GetCfg("Flags.Gap") or 2
            local flagside_gap = GetCfg("Flags.SideGap")
            local flagposition = GetCfg("Flags.Position")
            local flags = {}

            if isMoving and isJumping and flagOptionsMoving and flagOptionsJumping then
                table.insert(flags, { text = "Moving & Jumping", color = flagColorsMoving })
            elseif isJumping and flagOptionsJumping then
                table.insert(flags, { text = "Jumping", color = flagColorsJumping })
            elseif isMoving and flagOptionsMoving then
                table.insert(flags, { text = "Moving", color = flagColorsMoving })
            elseif isSwimming and flagOptionsSwimming then
                table.insert(flags, { text = "Swimming", color = flagColorsSwimming })
            elseif flagOptionsIdle then
                table.insert(flags, { text = "Idle", color = flagColorsIdle })
            end

            local isright = flagposition == "Right"
            local fx = isRight and (x + sx + flagSideGap + rightOffset) or
                (x - 100 - flagSideGap - leftOffset)
            local fy = y - flagGap

            if flagfont == "Smallest Pixel-7" then
                fy = fy - 3
            end

            local flagsfont_obj = _fontMap[flagFont] or Enum.Font.Code
            local flagsfont_loaded = ESPFonts.Loaded[flagFont]
            local flagoutline_style = GetCfg("Flags.OutlineStyle") or textOutlineStyle

            for i, data in ipairs(flags) do
                local label = espObj.FlagLabels[i]
                if label then
                    label.visible = true
                    label.text = data.text
                    label.text_color3 = data.color
                    label.font = flagsFontObj
                    if flagsFontLoaded then
                        label.font_face = flagsFontLoaded
                    end
                    label.text_size = flagTextSize
                    label.text_x_alignment = isRight and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
                    label.position = UDim2.new(0, fx, 0,
                        fy + (i - 1) * (flagTextSize + flagTextGap))
                    ApplyTextOutline(label, flagOutlineStyle, textOutlineColor)
                end
        end
    end

    
    if GetCfg("Skeleton.Enabled") and instance:IsA("Model") then
        local skeletonoutline = GetCfg("Skeleton.Outline")
        local skeletoncolor = GetCfg("Skeleton.Color")
        local skeletonoutline_color = GetCfg("Skeleton.OutlineColor")

        local bonepositions = {}
        for _, def in ipairs(SKELETON_BONE_DEFS) do
            for _, bn in ipairs(def) do
                if bonePositions[bn] == nil then
                    local wp = GetBonePosition(instance, bn)
                    local sp, on = wp and WtS(Camera, wp)
                    bonePositions[bn] = (wp and on) and Vector2.new(sp.X, sp.Y) or false
                end
            end
        end

        for i, def in ipairs(SKELETON_BONE_DEFS) do
            local pA = bonePositions[def[1]]
            local pB = bonePositions[def[2]]

            if pA and pB then
                if skeletonOutline then
                    DrawLine(espObj.BoneOutlines[i], pA, pB, 3, skeletonOutlineColor)
                else
                    espObj.BoneOutlines[i].visible = false
                end

                DrawLine(espObj.Bones[i], pA, pB, 1, skeletonColor)
            else
                espObj.Bones[i].visible = false
                espObj.BoneOutlines[i].visible = false
            end
        end
    else
        if espObj.Bones then
            for _, b in ipairs(espObj.Bones) do b.visible = false end
            for _, b in ipairs(espObj.BoneOutlines) do b.visible = false end
        end
    end
end)



local get2_d_bounding_box = LPHNoVirtualize(function(instance)
    local rootPart
    if instance:IsA("Model") then
        rootpart = instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso") or
            instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
    elseif instance:IsA("BasePart") then
        rootpart = instance
    end

    if not rootPart then return false, nil, nil end

    local position, onscreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then return false, nil, nil end

    if not ESPConfig.DynamicBoxes then
        
        local humanoid = instance:IsA("Model") and instance:FindFirstChild("Humanoid")
        if humanoid then
            
            local isr6 = humanoid.rig_type == Enum.HumanoidRigType.R6
            local topoffset = isR6 and 2.8 or 3.0
            local bottomoffset = isR6 and 3.0 or 3.5

            local toppos = rootPart.Position + Vector3.new(0, topOffset, 0)
            local bottompos = rootPart.Position - Vector3.new(0, bottomOffset, 0)
            local top2D = Camera:WorldToViewportPoint(topPos)
            local bottom2D = Camera:WorldToViewportPoint(bottomPos)
            local height = math.abs(top2D.Y - bottom2D.Y)
            return true, Vector2.new(position.X, (top2D.Y + bottom2D.Y) / 2), Vector2.new(height * 0.65, height)
        end

        
        local cf, size
        if instance:IsA("Model") then
            cf, size = instance:GetBoundingBox()
        else
            cf, size = instance.CFrame, instance.Size
        end

        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local corners = {
            cf * Vector3.new(size.X / 2, size.Y / 2, size.Z / 2),
            cf * Vector3.new(-size.X / 2, size.Y / 2, size.Z / 2),
            cf * Vector3.new(size.X / 2, -size.Y / 2, size.Z / 2),
            cf * Vector3.new(-size.X / 2, -size.Y / 2, size.Z / 2),
            cf * Vector3.new(size.X / 2, size.Y / 2, -size.Z / 2),
            cf * Vector3.new(-size.X / 2, size.Y / 2, -size.Z / 2),
            cf * Vector3.new(size.X / 2, -size.Y / 2, -size.Z / 2),
            cf * Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
        }
        for _, corner in ipairs(corners) do
            local screenpos = Camera:WorldToViewportPoint(corner)
            if screenPos.X < minX then minX = screenPos.X end
            if screenPos.X > maxX then maxX = screenPos.X end
            if screenPos.Y < minY then minY = screenPos.Y end
            if screenPos.Y > maxY then maxY = screenPos.Y end
        end
        return true, Vector2.new((minX + maxX) / 2, (minY + maxY) / 2), Vector2.new(maxX - minX, maxY - minY)
    else
        
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local parts = {}
        if instance:IsA("Model") then
            local includeall = ESPConfig.DynamicBoxesIncludeAll
            for _, v in ipairs(instance:GetChildren()) do
                if v:IsA("BasePart") and (includeAll or (v.Name ~= "HumanoidRootPart" and v.Transparency ~= 1)) then
                    table.insert(parts, v)
                end
            end
        else
            table.insert(parts, instance)
        end

        if #parts == 0 then return false, nil, nil end

        if ESPConfig.DynamicBoxesCheap then
            for _, part in ipairs(parts) do
                local cf, size = part.CFrame, part.Size
                local hs = size / 2
                local p1 = cf * Vector3.new(hs.X, hs.Y, hs.Z)
                local p2 = cf * Vector3.new(-hs.X, -hs.Y, -hs.Z)
                local s1 = Camera:WorldToViewportPoint(p1)
                local s2 = Camera:WorldToViewportPoint(p2)
                if s1.X < minX then minX = s1.X end
                if s1.X > maxX then maxX = s1.X end
                if s1.Y < minY then minY = s1.Y end
                if s1.Y > maxY then maxY = s1.Y end
                if s2.X < minX then minX = s2.X end
                if s2.X > maxX then maxX = s2.X end
                if s2.Y < minY then minY = s2.Y end
                if s2.Y > maxY then maxY = s2.Y end
            end
        else
            for _, part in ipairs(parts) do
                local cf, size = part.CFrame, part.Size
                local corners = {
                    cf * Vector3.new(size.X / 2, size.Y / 2, size.Z / 2),
                    cf * Vector3.new(-size.X / 2, size.Y / 2, size.Z / 2),
                    cf * Vector3.new(size.X / 2, -size.Y / 2, size.Z / 2),
                    cf * Vector3.new(-size.X / 2, -size.Y / 2, size.Z / 2),
                    cf * Vector3.new(size.X / 2, size.Y / 2, -size.Z / 2),
                    cf * Vector3.new(-size.X / 2, size.Y / 2, -size.Z / 2),
                    cf * Vector3.new(size.X / 2, -size.Y / 2, -size.Z / 2),
                    cf * Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
                }
                for _, corner in ipairs(corners) do
                    local screenpos = Camera:WorldToViewportPoint(corner)
                    if screenPos.X < minX then minX = screenPos.X end
                    if screenPos.X > maxX then maxX = screenPos.X end
                    if screenPos.Y < minY then minY = screenPos.Y end
                    if screenPos.Y > maxY then maxY = screenPos.Y end
                end
            end
        end
        return true, Vector2.new((minX + maxX) / 2, (minY + maxY) / 2), Vector2.new(maxX - minX, maxY - minY)
    end
end)



local function check_contains(instance, containsList)
    if type(containsList) ~= "table" or #containslist == 0 then return true end
    if #containslist == 1 and containsList[1] == "" then return true end
    for _, containName in ipairs(containsList) do
        local found = false
        for _, child in ipairs(instance:GetChildren()) do
            if child.name == containName then
                found = true
                break
            end
        end
        if not found then return false end
    end
    return true
end

local function check_names(instance, namesList)
    if type(namesList) ~= "table" or #nameslist == 0 then return true end
    if #nameslist == 1 and namesList[1] == "" then return true end
    for _, name in ipairs(namesList) do
        if instance.name == name then
            return true
        end
    end
    return false
end

local function check_block_names(inst, blockList)
    if not blockList or #blocklist == 0 then return false end
    local current = inst
    while current and current ~= game do
        for _, name in ipairs(blockList) do
            if name ~= "" and current.Name:find(name) then
                return true
            end
        end
        current = current.Parent
    end
    return false
end

local scan_directories = LPHNoVirtualize(function()
    local newtracked = {}

    if ESPConfig.Players then
        for _, player in ipairs(Players:GetPlayers()) do
            if not ESPConfig.LocalPlayer and player == LocalPlayer then continue end
            if player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    newTracked[player.Character] = { name = player.Name, cheap = false }
                end
            end
        end
    end

    for key, config in pairs(ESPConfig.Directories) do
        local displayname = nil
        if type(config) == "table" and config.DisplayName and config.DisplayName ~= "" then
            displayname = config.DisplayName
        elseif type(key) == "string" then
            displayname = key
        end

        if type(config) == "string" then
            local inst = GetInstanceFromPath(config)
            if inst then
                newTracked[inst] = { name = displayName or inst.Name, cheap = false }
            end
        elseif type(config) == "table" then
            local path = config.Path
            if not path then continue end
            local inst = GetInstanceFromPath(path)
            if not inst then continue end

            local ischeap = config.Cheap or false
            local nonhuman = config.NonHuman or false
            local nostatus = config.NoStatus or false
            local customconfig = config.Config or {}
            local isrecursive = config.Recursive or false

            if config.Multiple then
                local children = isRecursive and inst:GetDescendants() or inst:GetChildren()
                for _, child in ipairs(children) do
                    if (child:IsA("Model") or child:IsA("BasePart")) then
                        
                        local hastracked_ancestor = false
                        local p = child.Parent
                        while p and p ~= inst and p ~= game do
                            if newTracked[p] then
                                hastracked_ancestor = true
                                break
                            end
                            p = p.Parent
                        end

                        if not hasTrackedAncestor and CheckNames(child, config.Names) and CheckContains(child, config.Contains) and not CheckBlockNames(child, config.BlockNames) then
                            local humanoid = child:FindFirstChild("Humanoid")
                            if nonHuman or (not humanoid or humanoid.Health > 0) then
                                local actualname = (displayName and displayName ~= "") and displayName or child.Name
                                newTracked[child] = {
                                    name = actualName,
                                    cheap = isCheap,
                                    non_human = nonHuman,
                                    no_status = noStatus,
                                    config = customConfig
                                }
                            end
                        end
                    end
                end
            else
                if CheckNames(inst, config.Names) and CheckContains(inst, config.Contains) and not CheckBlockNames(inst, config.BlockNames) then
                    local humanoid = inst:FindFirstChild("Humanoid")
                    if nonHuman or (not humanoid or humanoid.Health > 0) then
                        local actualname = (displayName and displayName ~= "") and displayName or inst.Name
                        newTracked[inst] = {
                            name = actualName,
                            cheap = isCheap,
                            non_human = nonHuman,
                            no_status = noStatus,
                            config = customConfig
                        }
                    end
                end
            end
        end
    end

    for inst, data in pairs(newTracked) do
        if not TrackedInstances[inst] then
            TrackedInstances[inst] = {
                espobj = CreateESPObj(data.name),
                name = data.name,
                cheap = data.Cheap,
                non_human = data.NonHuman,
                no_status = data.NoStatus,
                config = data.Config
            }
        else
            TrackedInstances[inst].name = data.name
            TrackedInstances[inst].cheap = data.Cheap
            TrackedInstances[inst].non_human = data.NonHuman
            TrackedInstances[inst].no_status = data.NoStatus
            TrackedInstances[inst].config = data.Config
        end
    end

    for inst, data in pairs(TrackedInstances) do
        if not newTracked[inst] or not inst.Parent then
            data.espObj:Destroy()
            TrackedInstances[inst] = nil
        end
    end
end)

local lastscan = 0
local lastrender = 0
local lastfont_retry = 0
local function runtime_step()
    if not ESPConfig.Enabled then
        for inst, data in pairs(TrackedInstances) do
            if data.espObj then
                local disabledconfig = DeepCopy(data.Config or {})
                disabledConfig.chams = disabledConfig.Chams or {}
                disabledConfig.Chams.enabled = false
                UpdateESPObj(data.espObj, nil, nil, "", 0, inst, data.Cheap, data.NonHuman, data.NoStatus, disabledConfig,
                    false)
            end
        end
        return
    end

    local now = tick()

    if FontsStillLoading and now - lastFontRetry > 5 then
        lastfont_retry = now
        AttemptLoadFonts()
    end

    if ESPConfig.LimitFPS and ESPConfig.LimitFPS > 0 then
        if now - lastRender < (1 / ESPConfig.LimitFPS) then return end
        lastrender = now
    end

    if now - lastScan > 1 then
        lastscan = now
        ScanDirectories()
    end

    for inst, data in pairs(TrackedInstances) do
        if not inst or not inst.Parent then
            data.espObj:Destroy()
            TrackedInstances[inst] = nil
            continue
        end

        local humanoid = not data.NonHuman and inst:FindFirstChild("Humanoid") or nil
        if humanoid and humanoid.Health <= 0 then
            data.espObj:Destroy()
            TrackedInstances[inst] = nil
            continue
        end

        local rootpart = inst:IsA("Model") and
            (inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChildWhichIsA("BasePart")) or
            (inst:IsA("BasePart") and inst)

        if rootPart then
            local onscreen, pos2d, size2d = Get2DBoundingBox(inst)
            local distancestuds = (Camera.CFrame.Position - rootPart.Position).Magnitude
            UpdateESPObj(data.espObj, pos2d, size2d, data.name, distanceStuds, inst, data.Cheap, data.NonHuman,
                data.NoStatus, data.Config, onscreen)
        else
            UpdateESPObj(data.espObj, nil, nil, data.name, 0, inst, data.Cheap, data.NonHuman, data.NoStatus, data
                .Config, false)
        end
    end
end

function esp:Unload()
    for inst, data in pairs(TrackedInstances) do
        if data.espObj then
            data.espObj:Destroy()
        end
        TrackedInstances[inst] = nil
    end

    if PlayerRemovingConnection then
        PlayerRemovingConnection:Disconnect()
        player_removing_connection = nil
    end
    if InputBeganConnection then
        InputBeganConnection:Disconnect()
        input_began_connection = nil
    end
    if getgenv().SensoryESP_Loop then
        getgenv().SensoryESP_Loop:Disconnect()
        getgenv().sensory_esp__loop = nil
    end
    if ScreenGui then
        ScreenGui:Destroy()
        screen_gui = nil
    end
    if ChamsContainer then
        ChamsContainer:Destroy()
        chams_container = nil
    end
    if MeshChamsFolder then
        MeshChamsFolder:Destroy()
        mesh_chams_folder = nil
    end

    CleanupMeshChams(Workspace)
    for _, player in ipairs(BootstrapPlayers:GetPlayers()) do
        CleanupCharacterMeshChams(player.Character)
    end

    getgenv().sensory_esp_ui = nil
end

function esp:Load(config)
    self:Unload()

    esp_config = DeepMerge(DeepCopy(DefaultESPConfig), config or {})
    EnsureRootInstances()
    current_run_id = HttpService:GenerateGUID(false)
    lastscan = 0
    lastrender = 0

    player_removing_connection = Players.PlayerRemoving:Connect(function(player)
        for inst, data in pairs(TrackedInstances) do
            if Players:GetPlayerFromCharacter(inst) == player then
                data.espObj:Destroy()
                TrackedInstances[inst] = nil
            end
        end
    end)

    input_began_connection = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and ESPConfig.Keybind.Enabled and input.key_code == ESPConfig.Keybind.Key then
            ESPConfig.enabled = not ESPConfig.Enabled
        end
    end)

    getgenv().sensory_esp__loop = RunService.RenderStepped:Connect(RuntimeStep)
    ScanDirectories()
    return self
end

function esp:GetConfig()
    return ESPConfig
end

getgenv().sensory_esp__unload = function()
    ESP:Unload()
end

return ESP
