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
	MinDistance = 12, -- Minimum attach distance
	Cooldown = 0.1, -- Fast chaining between webs

	-- Spider-Man Web Physics (Smooth & Controllable)
	Web = {
		Stiffness = 1800, -- Smooth stiffness
		Damping = 120, -- Smooth damping
		SwoopBoost = 1200, -- Reduced from 3800 -> 1200 for smooth, controllable swing speed!
		ReelInSpeed = 20, -- Controlled reel-in speed when holding W
		MinLength = 12, -- Minimum web length
	},

	-- Launch / Release Fling (Controlled & Snappy)
	Launch = {
		ForwardBoost = 25, -- Controlled forward fling boost
		UpwardBoost = 18, -- Smooth upward lift
		VelocityPreservation = 1.05, -- Momentum multiplier on release
		MaxVelocity = 110, -- Capped at 110 studs/sec so you never lose control!
		MinimumFlingSpeed = 25, -- Minimum launch speed
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
