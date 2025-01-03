-- MADE BY YUKINO (@ifeq on Discord / YUKINO#7070)
-- Macsploit needs documentation
-- UPDATED FOR MACSPLOIT

local UserInputService = game:GetService("UserInputService") 
local RunService = game:GetService("RunService") 
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
    
local local_player = Players.LocalPlayer

local framework = {
    config = {
        player = {
            name = true,
            box = true,
            distance = true,

            color = Color3.fromRGB(0, 255, 157),

            tool = true, -- Exclusive to players
            health = true, -- Exclusive to players and humanoids

            distance_limit = 2500, -- It will skip calculation if the player is over this limit
            dead_check = true,
        },

        humanoid = {
            name = true,
            box = true,
            distance = true,

            color = Color3.fromRGB(7, 141, 250),

            health = true,

            distance_limit = 250, -- It will skip calculation if the humanoid is over this limit
            fade = true, -- Makes it fade the farther away you are away from it
        },

        object = {
            name = true,
            box = true,
            distance = true,

            color = Color3.fromRGB(255, 0, 0),

            distance_limit = 200, -- It will skip calculation if the object is over this limit
            fade = true -- Makes it fade the farther away you are away from it
        },

        global_distance_limit = 5000, -- It will skip calculation if the entity is over this limit
    },

    entities = {
        players = {}, -- Guess what it's used for
        humanoids = {}, -- Used for NPCs, stuff like zombies, or things that have humanoids
        objects = {}, -- Used for Abstract Objects, stuff like trinkets or items
    },
    
    drawings = {},
    connections = {},

    active = true,
    window_focused = true, -- Saves performance when not focused

    active_key = Enum.KeyCode.F1,
    unload_key = Enum.KeyCode.F2,
}

function framework:unload()
    for i,v in next, framework.connections do
        v:Disconnect()
        framework.connections[i] = nil
    end

    for _,v in next, framework.drawings do
        v:Remove()
    end
end

do -- Connection Management
    function framework:create_connection(script_signal, callback)
        local connection = script_signal:Connect(callback)
        table.insert(framework.connections, connection)
        return connection
    end
    
end

do -- Drawing Management
   function framework:create_drawing(drawing_type, properties)
       local drawing = Drawing.new(drawing_type)

       for i, v in next, properties do
           drawing[i] = v
       end

       self.drawings[drawing] = drawing
       return drawing 
   end 
end

do -- Calculation Management
    function framework:floor(x)
        return tonumber(string.split(tostring(x), ".")[1])        
    end

    function framework:get_screen_size()
        return Workspace.CurrentCamera.ViewportSize
    end

    function framework:can_render()
        return self.active and self.window_focused
    end

    function framework:calculate_bounding_box(entity)
        if entity.ClassName == "Model" then
            local orientation, size = entity:GetBoundingBox()
            local width = (Workspace.CurrentCamera.CFrame - Workspace.CurrentCamera.CFrame.Position) * Vector3.new((math.clamp(size.X, 1, 10) + 0.5) / 2, 0, 0)
            local height = (Workspace.CurrentCamera.CFrame - Workspace.CurrentCamera.CFrame.Position) * Vector3.new(0, (math.clamp(size.X, 1, 10) + 0.5) / 2, 0)
           
            width = math.abs(Workspace.CurrentCamera:WorldToViewportPoint(orientation.Position + width).X - Workspace.CurrentCamera:WorldToViewportPoint(orientation.Position - width).X)
            height =  math.abs(Workspace.CurrentCamera:WorldToViewportPoint(orientation.Position + height).Y - Workspace.CurrentCamera:WorldToViewportPoint(orientation.Position - height).Y)
            
            local bounding_box_size = Vector2.new(framework:floor(width), framework:floor(height))
            return bounding_box_size
        else
            local orientation, size = entity.CFrame, entity.Size
            local width = (Workspace.CurrentCamera.CFrame - Workspace.CurrentCamera.CFrame.Position) * Vector3.new((math.clamp(size.X, 1, 10) + 0.5) / 2, 0, 0)
            local height = (Workspace.CurrentCamera.CFrame - Workspace.CurrentCamera.CFrame.Position) * Vector3.new(0, (math.clamp(size.X, 1, 10) + 0.5) / 2, 0)
           
            width = math.abs(Workspace.CurrentCamera:WorldToViewportPoint(orientation.Position + width).X - Workspace.CurrentCamera:WorldToViewportPoint(orientation.Position - width).X)
            height =  math.abs(Workspace.CurrentCamera:WorldToViewportPoint(orientation.Position + height).Y - Workspace.CurrentCamera:WorldToViewportPoint(orientation.Position - height).Y)
            
            local bounding_box_size = Vector2.new(framework:floor(width), framework:floor(height))
            return bounding_box_size
        end
    end

end

do -- Registers
    function framework:register_player(player)
        assert(player ~= nil, "Missing data or object")
        local registry = {
            name = player.Name,
            player = player,
            drawings = {},
            color = framework.config.player.color,
            low_health = Color3.fromRGB(255,0,0),
        }

        do -- Create Drawings
            registry.drawings["name"] = self:create_drawing("Text", {
                Text = registry.name,
                Font = 2,
                Size = 13,
                Center = true,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["box"] = self:create_drawing("Square", {
                Thickness = 1,
                ZIndex = 2,      
                Color = registry.color,
            })

            registry.drawings["box_outline"] = self:create_drawing("Square", {   
                Thickness = 3,
                ZIndex = 1,     
                Color = Color3.fromRGB(0,0,0),
            })

            registry.drawings["health"] = self:create_drawing("Line", {
                Thickness = 2,           
                ZIndex = 2,
                Color = Color3.fromRGB(0, 255, 0),
            })

            registry.drawings["health_text"] = self:create_drawing("Text", {
                Text = "100",
                Font = 2,
                Size = 13,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["health_outline"] = self:create_drawing("Line", {
                Thickness = 5,           
                Color = Color3.fromRGB(0, 0, 0),
            })

            registry.drawings["tool"] = self:create_drawing("Text", {
                Text = registry.name,
                Font = 2,
                Size = 13,
                Center = true,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["distance"] = self:create_drawing("Text", {
                Text = registry.name,
                Font = 2,
                Size = 13,
                Center = true,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["offscreen"] = self:create_drawing("Triangle", {
                Color =  registry.color
            })
        end

        function registry:destruct()
            
            registry.update_connection:diconnect() -- Disconnect before deleting drawings so that the drawings don't cause an index error

            for _,v in next, registry.drawings do
                table.remove(framework.drawings, table.find(framework.drawings, v))
                v:Remove()
            end

        end

        registry.update_connection = framework:create_connection(RunService.RenderStepped, function()
            if framework:can_render() then
                if registry.player ~= nil then
                    if registry.player.Character and registry.player.Character:FindFirstChild("HumanoidRootPart") and registry.player.Character:FindFirstChildOfClass("Humanoid") and registry.player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                        local distance = (Workspace.CurrentCamera.CFrame.Position - registry.player.Character:FindFirstChild("HumanoidRootPart").CFrame.Position).Magnitude
                        if distance < framework.config.global_distance_limit and distance < framework.config.player.distance_limit then
                            local screen_position, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(registry.player.Character:FindFirstChild("HumanoidRootPart").Position)
                            if onscreen then
                                local bounding_box_size = framework:calculate_bounding_box(registry.player.Character)
                                local bounding_box_position = Vector2.new(framework:floor(screen_position.X), framework:floor(screen_position.Y)) - (bounding_box_size / 2)

                                local humanoid = registry.player.Character:FindFirstChildOfClass("Humanoid")
                                local equipped = registry.player.Character:FindFirstChildOfClass("Tool") and registry.player.Character:FindFirstChildOfClass("Tool").Name or "None"
                                local bottom_offset = 0

                                do -- Positioning
                                    if framework.config.player.box then
                                        registry.drawings.box.Position = bounding_box_position
                                        registry.drawings.box.Size = bounding_box_size
                                        
                                        registry.drawings.box_outline.Position = bounding_box_position
                                        registry.drawings.box_outline.Size = bounding_box_size
                                        
                                        registry.drawings.box.Visible = true
                                        registry.drawings.box_outline.Visible = true
                                        
                                    else
                                        registry.drawings.box.Visible = false
                                        registry.drawings.box_outline.Visible = false
                                    end

                                    if framework.config.player.health then
                                        registry.drawings.health.From = Vector2.new((bounding_box_position.X - 5), bounding_box_position.Y + bounding_box_size.Y)
                                        registry.drawings.health.To = Vector2.new(registry.drawings.health.From.X, registry.drawings.health.From.Y - (humanoid.Health / humanoid.MaxHealth) * bounding_box_size.Y)
                                        registry.drawings.health.Color = registry.low_health:Lerp(Color3.fromRGB(0,255,0), humanoid.Health / humanoid.MaxHealth)

                                        registry.drawings.health_outline.From = registry.drawings.health.From + Vector2.new(0, 1)
                                        registry.drawings.health_outline.To = Vector2.new(registry.drawings.health_outline.From.X, bounding_box_position.Y - 1)
                        
                                        registry.drawings.health_text.Text = tostring(math.floor(humanoid.Health))
                                        registry.drawings.health_text.Position = registry.drawings.health.To - Vector2.new((registry.drawings.health_text.TextBounds.X + 4), 0)
                                        
                                        registry.drawings.health_text.Visible = true
                                        registry.drawings.health_outline.Visible = true
                                        registry.drawings.health.Visible = true
                                    else
                                        registry.drawings.health_text.Visible = false
                                        registry.drawings.health_outline.Visible = false
                                        registry.drawings.health.Visible = false
                                    end


                                    if framework.config.player.name then
                                        registry.drawings.name.Position = Vector2.new(bounding_box_position.X + (bounding_box_size.X / 2), bounding_box_position.Y - (registry.drawings.name.TextBounds.Y + 2))
                                        
                                        registry.drawings.name.Visible = true
                                    else
                                        registry.drawings.name.Visible = false
                                    end

                                    if framework.config.player.tool then
                                        registry.drawings.tool.Text = equipped
                                        registry.drawings.tool.Position = Vector2.new(bounding_box_size.X/2 + bounding_box_position.X, bounding_box_size.Y + bounding_box_position.Y + 1 + bottom_offset)

                                        bottom_offset += 15
                                        registry.drawings.tool.Visible = true
                                    else
                                        registry.drawings.tool.Visible = false
                                    end

                                    if framework.config.player.distance then
                                        registry.drawings.distance.Text = tostring(framework:floor(distance)).."m"
                                        registry.drawings.distance.Position = Vector2.new(bounding_box_size.X/2 + bounding_box_position.X, bounding_box_size.Y + bounding_box_position.Y + 1 + bottom_offset)

                                        bottom_offset += 15
                                        registry.drawings.distance.Visible = true
                                    else
                                        registry.drawings.distance.Visible = false
                                    end

                                end
                                
                            else
                                for _,v in next, registry.drawings do
                                    v.Visible = false
                                end
                            end
                        else
                            for _,v in next, registry.drawings do
                                v.Visible = false
                            end
                        end
                    else
                        for _,v in next, registry.drawings do
                            v.Visible = false
                        end
                    end
                else
                    registry:destruct()
                end
            else
                for _,v in next, registry.drawings do
                    v.Visible = false
                end
            end
        end)

        table.insert(framework.entities.players, registry)
        return registry
    end

    function framework:register_humanoid(humanoid)
        assert(humanoid and humanoid.model, "Missing data or object")
        local registry = {
            name = humanoid.model.Name,
            model = humanoid.model,
            drawings = {},
            color = framework.config.humanoid.color,
            low_health = Color3.fromRGB(255,0,0)
        }

        do -- Create Drawings
            registry.drawings["name"] = self:create_drawing("Text", {
                Text = registry.name,
                Font = 2,
                Size = 13,
                Center = true,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["box"] = self:create_drawing("Square", {
                Thickness = 1,
                ZIndex = 2,      
                Color = registry.color,
            })

            registry.drawings["box_outline"] = self:create_drawing("Square", {   
                Thickness = 3,
                ZIndex = 1,     
                Color = Color3.fromRGB(0,0,0),
            })

            registry.drawings["health"] = self:create_drawing("Line", {
                Thickness = 2,           
                ZIndex = 2,
                Color = Color3.fromRGB(0, 255, 0),
            })

            registry.drawings["health_text"] = self:create_drawing("Text", {
                Text = "100",
                Font = 2,
                Size = 13,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["health_outline"] = self:create_drawing("Line", {
                Thickness = 5,           
                Color = Color3.fromRGB(0, 0, 0),
            })

            registry.drawings["tool"] = self:create_drawing("Text", {
                Text = registry.name,
                Font = 2,
                Size = 13,
                Center = true,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["distance"] = self:create_drawing("Text", {
                Text = registry.name,
                Font = 2,
                Size = 13,
                Center = true,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["offscreen"] = self:create_drawing("Triangle", {
                Color =  registry.color
            })
        end

        function registry:destruct()
            
            registry.update_connection:diconnect() -- Disconnect before deleting drawings so that the drawings don't cause an index error

            for _,v in next, registry.drawings do
                table.remove(framework.drawings, table.find(framework.drawings, v))
                v:Remove()
            end

        end

        registry.update_connection = framework:create_connection(RunService.RenderStepped, function()
            if framework:can_render() then
                if registry.model.Parent ~= nil then
                    if registry.model and registry.model:FindFirstChild("HumanoidRootPart") and registry.model:FindFirstChildOfClass("Humanoid") and registry.model:FindFirstChildOfClass("Humanoid").Health > 0 then
                        local distance = (Workspace.CurrentCamera.CFrame.Position - registry.model:FindFirstChild("HumanoidRootPart").CFrame.Position).Magnitude
                        if distance < framework.config.global_distance_limit and distance < framework.config.humanoid.distance_limit then
                            local screen_position, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(registry.model:FindFirstChild("HumanoidRootPart").Position)
                            if onscreen then
                                local bounding_box_size = framework:calculate_bounding_box(registry.model)
                                local bounding_box_position = Vector2.new(framework:floor(screen_position.X), framework:floor(screen_position.Y)) - (bounding_box_size / 2)

                                local humanoid = registry.model:FindFirstChildOfClass("Humanoid")

                                do -- Positioning
                                    if framework.config.humanoid.box then
                                        registry.drawings.box.Position = bounding_box_position
                                        registry.drawings.box.Size = bounding_box_size
                                        
                                        registry.drawings.box_outline.Position = bounding_box_position
                                        registry.drawings.box_outline.Size = bounding_box_size
                                        
                                        registry.drawings.box.Visible = true
                                        registry.drawings.box_outline.Visible = true
                                        
                                    else
                                        registry.drawings.box.Visible = false
                                        registry.drawings.box_outline.Visible = false
                                    end

                                    if framework.config.humanoid.health then
                                        registry.drawings.health.From = Vector2.new((bounding_box_position.X - 5), bounding_box_position.Y + bounding_box_size.Y)
                                        registry.drawings.health.To = Vector2.new(registry.drawings.health.From.X, registry.drawings.health.From.Y - (humanoid.Health / humanoid.MaxHealth) * bounding_box_size.Y)
                                        registry.drawings.health.Color = registry.low_health:Lerp(Color3.fromRGB(0,255,0), humanoid.Health / humanoid.MaxHealth)

                                        registry.drawings.health_outline.From = registry.drawings.health.From + Vector2.new(0, 1)
                                        registry.drawings.health_outline.To = Vector2.new(registry.drawings.health_outline.From.X, bounding_box_position.Y - 1)
                        
                                        registry.drawings.health_text.Text = tostring(math.floor(humanoid.Health))
                                        registry.drawings.health_text.Position = registry.drawings.health.To - Vector2.new((registry.drawings.health_text.TextBounds.X + 4), 0)
                                        
                                        registry.drawings.health_text.Visible = true
                                        registry.drawings.health_outline.Visible = true
                                        registry.drawings.health.Visible = true
                                    else
                                        registry.drawings.health_text.Visible = false
                                        registry.drawings.health_outline.Visible = false
                                        registry.drawings.health.Visible = false
                                    end

                                    if framework.config.humanoid.name then
                                        registry.drawings.name.Position = Vector2.new(bounding_box_position.X + (bounding_box_size.X / 2), bounding_box_position.Y - (registry.drawings.name.TextBounds.Y + 2))
                                        
                                        registry.drawings.name.Visible = true
                                    else
                                        registry.drawings.name.Visible = false
                                    end

                                    if framework.config.humanoid.distance then
                                        registry.drawings.distance.Text = tostring(framework:floor(distance)).."m"
                                        registry.drawings.distance.Position = Vector2.new(bounding_box_size.X/2 + bounding_box_position.X, bounding_box_size.Y + bounding_box_position.Y + 1)

                                        registry.drawings.distance.Visible = true
                                    else
                                        registry.drawings.distance.Visible = false
                                    end
                                end

                                if framework.config.humanoid.fade then
                                    local transparency = math.clamp(1 - distance/framework.config.humanoid.distance_limit, 0, 1)
                                    
                                    if transparency >= .5 then
                                        transparency = 1
                                    end
    
                                    for _,v in next, registry.drawings do
                                        v.Transparency = transparency
                                    end
                                end
                                
                            else
                                for _,v in next, registry.drawings do
                                    v.Visible = false
                                end
                            end
                        else
                            for _,v in next, registry.drawings do
                                v.Visible = false
                            end
                        end
                    else
                        registry:destruct()
                    end
                else
                    registry:destruct()
                end
            else
                for _,v in next, registry.drawings do
                    v.Visible = false
                end
            end
        end)

        table.insert(framework.entities.humanoids, registry)
        return registry
    end

    function framework:register_object(object)
        assert(object and object.model, "Missing data or object")
        local registry = {
            name = object.model.name,
            model = object.model,
            color = framework.config.object.color,
            drawings = {},
        }

        do -- Create Drawings
            registry.drawings["name"] = self:create_drawing("Text", {
                Text = registry.name,
                Font = 2,
                Size = 13,
                Center = true,
                Outline = true,
                Color = registry.color,
            })

            registry.drawings["box"] = self:create_drawing("Square", {
                Thickness = 1,
                ZIndex = 2,
                Color = registry.color
            })

            registry.drawings["box_outline"] = self:create_drawing("Square", {   
                Thickness = 3,
                ZIndex = 1,
                Color = Color3.fromRGB(0,0,0),
            })

            registry.drawings["distance"] = self:create_drawing("Text", {
                Text = "0m",
                Font = 2,
                Size = 13,
                Center = true,
                Outline = true,
                
                Color = registry.color,
            })
        end

        function registry:destruct()
            registry.update_connection:Disconnect()

            for _,v in next, registry.drawings do
                v:Remove()
            end

            table.remove(framework.entities.objects, table.find(framework.entities.objects, registry))
        end

        registry.update_connection = framework:create_connection(RunService.RenderStepped, function()
            if framework:can_render() then
                if registry.model.Parent ~= nil then
                    local distance = (Workspace.CurrentCamera.CFrame.Position - registry.model.CFrame.Position).Magnitude
                    if distance < framework.config.global_distance_limit and distance < framework.config.object.distance_limit then
                        local screen_position, onscreen = Workspace.CurrentCamera:WorldToViewportPoint(registry.model.CFrame.Position)
                        if onscreen then
                            local bounding_box_size = framework:calculate_bounding_box(registry.model)
                            local bounding_box_position = Vector2.new(framework:floor(screen_position.X), framework:floor(screen_position.Y)) - (bounding_box_size / 2)

                            do -- Positioning
                                if framework.config.object.box then
                                    registry.drawings.box.Position = bounding_box_position
                                    registry.drawings.box.Size = bounding_box_size
                                    
                                    registry.drawings.box_outline.Position = bounding_box_position
                                    registry.drawings.box_outline.Size = bounding_box_size
                                    
                                    registry.drawings.box.Visible = true
                                    registry.drawings.box_outline.Visible = true
                                    
                                else
                                    registry.drawings.box.Visible = false
                                    registry.drawings.box_outline.Visible = false
                                end

                                if framework.config.object.name then
                                    registry.drawings.name.Position = Vector2.new(bounding_box_position.X + (bounding_box_size.X / 2), bounding_box_position.Y - (registry.drawings.name.TextBounds.Y + 2))
                                    
                                    registry.drawings.name.Visible = true
                                else
                                    registry.drawings.name.Visible = false
                                end

                                if framework.config.object.distance then
                                    registry.drawings.distance.Position = Vector2.new(bounding_box_position.X + (bounding_box_size.X / 2), bounding_box_position.Y + bounding_box_size.Y)
                                    registry.drawings.distance.Text = tostring(framework:floor(distance)).."m"

                                    registry.drawings.distance.Visible = true
                                else
                                    registry.drawings.distance.Visible = false
                                end

                            end

                            if framework.config.object.fade then
                                local transparency = math.clamp(1 - distance/framework.config.object.distance_limit, 0, 1)
                                
                                if transparency >= .5 then
                                    transparency = 1
                                end

                                for _,v in next, registry.drawings do
                                    v.Transparency = transparency
                                end
                            end
                            
                        else
                            for _,v in next, registry.drawings do
                                v.Visible = false
                            end
                        end
                    else
                        for _,v in next, registry.drawings do
                            v.Visible = false
                        end
                    end
                else
                    registry:destruct()
                end
            else
                for _,v in next, registry.drawings do
                    v.Visible = false
                end
            end
        end)

        table.insert(framework.entities.objects, registry)
        return registry
    end
end

do -- Connections

    -- Add Player Register
    framework:create_connection(Players.PlayerAdded, function(player)
        framework:register_player(player)
    end)

    -- Add Humanoid Register


    -- Add Object Register


    -- Framework Connections
    framework:create_connection(UserInputService.InputBegan, function(input, processed)
        if not processed then
            if input.KeyCode == framework.unload_key then
                framework:unload()
            elseif input.KeyCode == framework.active_key then
                framework.active = not framework.active
            end
        end
    end)

    framework:create_connection(UserInputService.WindowFocused, function() 
        framework.window_focused = true
    end)

    framework:create_connection(UserInputService.WindowFocusReleased, function() 
        framework.window_focused = false
    end)
end

do -- Init

    -- Add Player Init
    for _,v in next, Players:GetPlayers() do
        if v ~= local_player then
            framework:register_player(v)
        end
    end

    -- Add Humanoid Init

    -- Add Object Init
end
