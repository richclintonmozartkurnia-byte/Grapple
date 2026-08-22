--!strict
local GrappleConfig = {
	-- Input Settings
	Keybinds = {
		Primary = Enum.UserInputType.MouseButton1, -- Left Click to Web-Swing
		Secondary = Enum.KeyCode.E, -- Keyboard alternative
		MobileButton = true,
		JumpToRelease = true,
	},

	-- Web Reach & Distance
	MaxDistance = 300, -- Reach of web line (studs)
	MinDistance = 10, -- Minimum attach distance
	Cooldown = 0.1, -- Fast chaining between webs

	-- Spider-Man Web Physics (Pull & Reel-In)
	Web = {
		InwardPullForce = 2200, -- Inward spring pull toward the anchor point (Spider-Man web tension)
		ForwardSwoopForce = 1800, -- Forward push along camera aim
		ReelInSpeed = 55, -- Fast reel-in speed when holding W
		MinLength = 8, -- Minimum web length
	},

	-- Launch / Release Fling
	Launch = {
		ForwardBoost = 35, -- Forward velocity added on release
		UpwardBoost = 22, -- Upward lift on release
		VelocityPreservation = 1.15, -- Momentum multiplier when letting go
		MaxVelocity = 140, -- Maximum speed cap
		MinimumFlingSpeed = 35, -- Guaranteed minimum launch speed
	},

	-- Soft-Lock & Targeting
	Targeting = {
		SoftLockRadius = 18,
		RaycastLayers = RaycastParams.new(),
		ValidTag = "Grappleable",
		AllowAllSurfaces = true,
	},

	-- Visual & Sound Effects
	Visuals = {
		RopeColor = Color3.fromRGB(0, 220, 255),
		RopeWidth = 0.18,
		RopeTexture = "rbxassetid://6034177579",
		RopeTextureLength = 4,
		RopeTransparency = 0.1,
	},
}

return GrappleConfig
