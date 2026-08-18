local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GrappleConfig = require(Shared:WaitForChild("GrappleConfig"))

-- Function to shoot a 3D laser from camera through mouse
local function findTarget()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end

	-- 1. Get 2D Mouse position on screen and turn it into a 3D directional ray
	local mousePos = UserInputService:GetMouseLocation()
	local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	-- 2. Tell Roblox to ignore our own character
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	-- 3. Shoot the ray up to MaxDistance studs into the 3D world
	local hitResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * GrappleConfig.MaxDistance, rayParams)
	return hitResult
end

-- Helper: Create a small glowing dot where we clicked to verify aiming works!
local function spawnDebugDot(position)
	local dot = Instance.new("Part")
	dot.Name = "GrappleTargetDot"
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.new(1.2, 1.2, 1.2)
	dot.Position = position
	dot.Color = Color3.fromRGB(0, 255, 200) -- Glowing cyan dot
	dot.Material = Enum.Material.Neon
	dot.Anchored = true
	dot.CanCollide = false
	dot.Parent = Workspace

	-- Automatically disappear after 1.5 seconds
	game:GetService("Debris"):AddItem(dot, 1.5)
end

-- Listen for mouse click
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == GrappleConfig.Keybinds.Primary then
		local hit = findTarget()
		if hit and hit.Instance then
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			local distance = rootPart and (hit.Position - rootPart.Position).Magnitude or 0

			print(string.format("🎯 Grapple Target Hit: %s | Distance: %.1f studs", hit.Instance.Name, distance))
			spawnDebugDot(hit.Position)
		else
			print("❌ No surface within grapple range.")
		end
	end
end)

print("✅ Stage 1 (Laser Aiming) Loaded Successfully!")
