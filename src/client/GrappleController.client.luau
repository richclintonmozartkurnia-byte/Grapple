local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GrappleConfig = require(Shared:WaitForChild("GrappleConfig"))

-- State variables for active Spider-Man Web Swing
local isSwinging = false
local activeSpring = nil
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

-- Spider-Man Release Fling
local function stopGrapple(isJumpLaunch)
	if not isSwinging then
		return
	end
	isSwinging = false

	local character, rootPart, humanoid = getCharacterParts()

	-- Read velocity BEFORE detaching web
	local currentVelocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.zero
	local currentSpeed = currentVelocity.Magnitude

	-- Clean up physical spring and attachments
	if activeVectorForce then
		activeVectorForce:Destroy()
		activeVectorForce = nil
	end
	if activeSpring then
		activeSpring:Destroy()
		activeSpring = nil
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

	-- Restore Humanoid controls
	if humanoid then
		humanoid.AutoRotate = true
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	-- High-Speed Spider-Man Web Fling
	if rootPart then
		local cameraLook = Camera.CFrame.LookVector
		local forwardLook = Vector3.new(cameraLook.X, math.max(0.15, cameraLook.Y), cameraLook.Z).Unit

		local launchDirection = forwardLook
		if currentSpeed > 3 and currentVelocity.Magnitude > 0 then
			launchDirection = (forwardLook * 0.75 + currentVelocity.Unit * 0.25).Unit
		end

		local boostSpeed = math.clamp(
			currentSpeed * GrappleConfig.Launch.VelocityPreservation + GrappleConfig.Launch.ForwardBoost,
			GrappleConfig.Launch.MinimumFlingSpeed,
			GrappleConfig.Launch.MaxVelocity
		)

		local upwardBoost = GrappleConfig.Launch.UpwardBoost
		if isJumpLaunch then
			upwardBoost = upwardBoost * 1.5 -- High arc jump launch on Spacebar!
		end

		local finalVelocity = (launchDirection * boostSpeed) + Vector3.new(0, upwardBoost, 0)
		rootPart.AssemblyLinearVelocity = finalVelocity

		-- ApplyImpulse with full character mass for guaranteed physics launch
		local mass = rootPart:GetMass()
		if character then
			for _, part in character:GetDescendants() do
				if part:IsA("BasePart") then
					mass = mass + part:GetMass()
				end
			end
		end

		rootPart:ApplyImpulse(finalVelocity * mass)
		print(string.format("🕸️ Spider-Man Web Launch! Speed: %.1f studs/sec", boostSpeed))
	else
		print("🕸️ Web released.")
	end
end

-- Spider-Man Attach & Web Swoop
local function startGrapple(hitPosition)
	local _, rootPart, humanoid = getCharacterParts()
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	local initialDistance = (hitPosition - rootPart.Position).Magnitude
	if initialDistance < GrappleConfig.MinDistance then
		print("❌ Too close to surface to attach web.")
		return
	end

	isSwinging = true
	currentHookPosition = hitPosition

	-- 1. Create anchor attachment at the hit point in the world
	local hookAttachment = Instance.new("Attachment")
	hookAttachment.Name = "WebAnchorPoint"
	hookAttachment.WorldPosition = hitPosition
	hookAttachment.Parent = Workspace.Terrain
	activeHookAttachment = hookAttachment

	-- 2. Create attachment inside your character's HumanoidRootPart
	local rootAttachment = Instance.new("Attachment")
	rootAttachment.Name = "WebPlayerAnchor"
	rootAttachment.Position = Vector3.new(0, 0.5, 0)
	rootAttachment.Parent = rootPart
	activeRootAttachment = rootAttachment

	-- 3. Create Spider-Man Elastic SpringConstraint (Catches drop & swoops up!)
	local spring = Instance.new("SpringConstraint")
	spring.Name = "SpiderWebSpring"
	spring.Attachment0 = rootAttachment
	spring.Attachment1 = hookAttachment
	spring.FreeLength = initialDistance * 0.88 -- Elastic initial tension to catch drop
	spring.Stiffness = GrappleConfig.Web.Stiffness
	spring.Damping = GrappleConfig.Web.Damping
	spring.MaxForce = 150000
	spring.Thickness = 0.18
	spring.Color = BrickColor.new("Cyan")
	spring.Visible = true
	spring.Parent = rootPart
	activeSpring = spring

	-- 4. Create VectorForce for tangential web swoop push
	local force = Instance.new("VectorForce")
	force.Name = "WebSwoopForce"
	force.Attachment0 = rootAttachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.Force = Vector3.zero
	force.Parent = rootPart
	activeVectorForce = force

	-- 5. Enable PlatformStand & Freefall so physics swoops character naturally
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	print(string.format("🕸️ Web Attached! Length: %.1f studs", initialDistance))
end

-- Physics loop: Spider-Man Web Swoop acceleration
RunService.Stepped:Connect(function(_, deltaTime)
	if not isSwinging or not activeSpring or not currentHookPosition then
		return
	end

	local _, rootPart, humanoid = getCharacterParts()
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		stopGrapple(false)
		return
	end

	local distToAnchor = (currentHookPosition - rootPart.Position).Magnitude

	-- Auto-release if pulled too close to anchor point
	if distToAnchor <= GrappleConfig.Web.MinLength then
		stopGrapple(false)
		return
	end

	-- Reel in web smoothly if holding W
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		local newLength = math.max(
			GrappleConfig.Web.MinLength,
			activeSpring.FreeLength - (GrappleConfig.Web.ReelInSpeed * deltaTime)
		)
		activeSpring.FreeLength = newLength
	end

	-- Apply smooth tangential web swoop force
	if activeVectorForce then
		local cameraLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
		local currentVelocity = rootPart.AssemblyLinearVelocity
		local webDir = (currentHookPosition - rootPart.Position).Unit

		-- Calculate arc swoop tangent
		local tangent = (currentVelocity - (currentVelocity:Dot(webDir) * webDir))
		if tangent.Magnitude > 1 then
			activeVectorForce.Force = (tangent.Unit * 0.7 + cameraLook * 0.3).Unit * GrappleConfig.Web.SwoopBoost
		else
			activeVectorForce.Force = cameraLook * GrappleConfig.Web.SwoopBoost
		end
	end
end)

-- Input Listeners
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == GrappleConfig.Keybinds.Primary or input.KeyCode == GrappleConfig.Keybinds.Secondary then
		local hit = findTarget()
		if hit and hit.Instance then
			startGrapple(hit.Position)
		end
	elseif input.KeyCode == Enum.KeyCode.Space and isSwinging then
		stopGrapple(true) -- Spacebar Web Jump Fling!
	end
end)

UserInputService.InputEnded:Connect(function(input, _)
	if input.UserInputType == GrappleConfig.Keybinds.Primary or input.KeyCode == GrappleConfig.Keybinds.Secondary then
		if isSwinging then
			stopGrapple(false)
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		stopGrapple(false)
	end)
end)

print("🕸️ Spider-Man Web Swoop Engine Loaded Successfully!")
