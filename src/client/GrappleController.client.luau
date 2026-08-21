local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GrappleConfig = require(Shared:WaitForChild("GrappleConfig"))

-- State variables for the active swing
local isSwinging = false
local activeRope = nil
local activeHookAttachment = nil
local activeRootAttachment = nil
local activeVectorForce = nil
local currentHookPosition = nil

-- Helper: Safely get current character parts
local function getCharacterParts()
	local character = LocalPlayer.Character
	if not character then
		return nil, nil, nil
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return character, rootPart, humanoid
end

-- Stage 1: Shoot 3D laser from camera through mouse
local function findTarget()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end

	local mousePos = UserInputService:GetMouseLocation()
	local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local hitResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * GrappleConfig.MaxDistance, rayParams)
	return hitResult
end

-- Stage 3: Stop grappling AND apply launch momentum fling!
local function stopGrapple(isJumpLaunch)
	if not isSwinging then
		return
	end
	isSwinging = false

	local _, rootPart, humanoid = getCharacterParts()

	-- 1. Read current velocity BEFORE destroying the rope
	local currentVelocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.zero
	local currentSpeed = currentVelocity.Magnitude

	-- 2. Delete physical rope, force, and anchor attachments
	if activeVectorForce then
		activeVectorForce:Destroy()
		activeVectorForce = nil
	end
	if activeRope then
		activeRope:Destroy()
		activeRope = nil
	end
	if activeHookAttachment then
		activeHookAttachment:Destroy()
		activeHookAttachment = nil
	end
	if activeRootAttachment then
		activeRootAttachment:Destroy()
		activeRootAttachment = nil
	end

	currentHookPosition = nil

	-- 3. Restore character rotation
	if humanoid then
		humanoid.AutoRotate = true
	end

	-- 4. STAGE 3 LAUNCH: Fling the player forward with accumulated momentum!
	if rootPart and currentSpeed > 2 then
		local cameraLook = Camera.CFrame.LookVector
		local launchDirection = (currentVelocity.Unit * 0.7 + cameraLook * 0.3).Unit

		local boostSpeed = math.min(
			currentSpeed * GrappleConfig.Launch.VelocityPreservation + GrappleConfig.Launch.ForwardBoost,
			GrappleConfig.Launch.MaxVelocity
		)

		local upwardBoost = GrappleConfig.Launch.UpwardBoost
		if isJumpLaunch then
			upwardBoost = upwardBoost * 1.4 -- Extra lift if triggered via Spacebar Jump!
		end

		rootPart.AssemblyLinearVelocity = (launchDirection * boostSpeed) + Vector3.new(0, upwardBoost, 0)
		print(string.format("🚀 Fling Launch! Speed: %.1f studs/sec", boostSpeed))
	else
		print("🪝 Detached grapple rope.")
	end
end

-- Stage 2: Attach physical rope and start swinging
local function startGrapple(hitPosition)
	local _, rootPart, humanoid = getCharacterParts()
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	isSwinging = true
	currentHookPosition = hitPosition

	-- 1. Create anchor attachment at the hit point in the world
	local hookAttachment = Instance.new("Attachment")
	hookAttachment.Name = "GrappleHookAnchor"
	hookAttachment.WorldPosition = hitPosition
	hookAttachment.Parent = Workspace.Terrain
	activeHookAttachment = hookAttachment

	-- 2. Create attachment inside your character's HumanoidRootPart
	local rootAttachment = Instance.new("Attachment")
	rootAttachment.Name = "GrapplePlayerAnchor"
	rootAttachment.Position = Vector3.new(0, 0.5, 0)
	rootAttachment.Parent = rootPart
	activeRootAttachment = rootAttachment

	-- 3. Connect them with a physical RopeConstraint!
	local rope = Instance.new("RopeConstraint")
	rope.Name = "GrappleRope"
	rope.Attachment0 = rootAttachment
	rope.Attachment1 = hookAttachment
	rope.Length = (hitPosition - rootPart.Position).Magnitude
	rope.Restitution = 0.1
	rope.Thickness = 0.15
	rope.Color = BrickColor.new("Cyan")
	rope.Visible = true
	rope.Parent = rootPart
	activeRope = rope

	-- 4. Create a forward vector force to pump swing momentum cleanly
	local force = Instance.new("VectorForce")
	force.Name = "SwingForce"
	force.Attachment0 = rootAttachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.Force = Vector3.zero
	force.Parent = rootPart
	activeVectorForce = force

	-- 5. Enable freefall state so Roblox physics swings your character naturally
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	humanoid.AutoRotate = false

	print(string.format("🪝 Attached rope! Rope Length: %.1f studs", rope.Length))
end

-- Physics loop: Pumping swing acceleration smoothly
RunService.Stepped:Connect(function(_, deltaTime)
	if not isSwinging or not activeRope or not currentHookPosition then
		return
	end

	local _, rootPart, humanoid = getCharacterParts()
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		stopGrapple(false)
		return
	end

	-- Shorten rope smoothly if holding W (Reeling in for faster swing speed)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		local newLength = math.max(
			GrappleConfig.Swing.MinRopeLength,
			activeRope.Length - (GrappleConfig.Swing.ReelInSpeed * deltaTime)
		)
		activeRope.Length = newLength
	end

	-- Apply smooth tangential force along the swing curve
	if activeVectorForce then
		local currentVelocity = rootPart.AssemblyLinearVelocity
		local ropeDir = (currentHookPosition - rootPart.Position).Unit
		local cameraLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit

		local tangent = (currentVelocity - (currentVelocity:Dot(ropeDir) * ropeDir))
		if tangent.Magnitude > 1 then
			activeVectorForce.Force = (tangent.Unit + cameraLook * 0.4).Unit * GrappleConfig.Swing.TangentialForce
		else
			activeVectorForce.Force = cameraLook * (GrappleConfig.Swing.TangentialForce * 0.5)
		end
	end
end)

-- Listen for mouse button press & Spacebar Jump
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == GrappleConfig.Keybinds.Primary or input.KeyCode == GrappleConfig.Keybinds.Secondary then
		local hit = findTarget()
		if hit and hit.Instance then
			startGrapple(hit.Position) -- ✅ FIXED: Passes hit.Position to startGrapple!
		else
			print("❌ Missed! No wall in range to hook onto.")
		end
	elseif input.KeyCode == Enum.KeyCode.Space and isSwinging then
		stopGrapple(true) -- Spacebar Jump Launch (Extra Upward Lift!)
	end
end)

-- Listen for mouse button release (Standard Fling Launch)
UserInputService.InputEnded:Connect(function(input, _)
	if input.UserInputType == GrappleConfig.Keybinds.Primary or input.KeyCode == GrappleConfig.Keybinds.Secondary then
		if isSwinging then
			stopGrapple(false)
		end
	end
end)

-- Clean up if character dies
LocalPlayer.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		stopGrapple(false)
	end)
end)

print("✅ Fixed GrappleController loaded successfully!")
