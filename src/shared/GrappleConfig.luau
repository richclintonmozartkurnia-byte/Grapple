--!strict
local GrappleConfig = {
	-- Input Settings
	Keybinds = {
		Primary = Enum.UserInputType.MouseButton1, -- Left Click to Grapple / Hold to Swing
		Secondary = Enum.KeyCode.E, -- Keyboard alternative
		MobileButton = true, -- Auto-generate on-screen button for mobile/touch
		JumpToRelease = true, -- Pressing Space while swinging releases with extra boost
	},

	-- Grapple Hook Parameters
	MaxDistance = 300, -- Maximum reach of the grappling hook (studs)
	MinDistance = 12, -- Minimum distance to attach (prevents attaching right into player's face)
	GrappleSpeed = 160, -- Reel-in / Pull speed if pulling directly (studs/sec)
	Cooldown = 0.1, -- Delay between swings (kept very low for continuous chaining)

	-- Swing Physics (Spider-Man & Stickman Hook style)
	Swing = {
		TangentialForce = 2800, -- Acceleration applied in direction of swing to pump momentum
		ReelInSpeed = 30, -- How fast the rope shortens if holding W while swinging
		MinRopeLength = 14, -- Minimum rope length (prevents "pet-on-leash" physics snapping)
		GravityMultiplier = 1.15, -- Gravity factor while swinging
		AirResistance = 0.998, -- Velocity retention factor in air
	},

	-- Launch / Release Boost (Stickman Hook style fling)
	Launch = {
		ForwardBoost = 35, -- Forward velocity added on release (snappy forward fling)
		UpwardBoost = 14, -- Reduced upward lift so player doesn't catapult into outer space
		VelocityPreservation = 1.1, -- Momentum multiplier when letting go
		MaxVelocity = 160, -- Maximum speed cap to keep physics stable
		MinimumFlingSpeed = 30, -- Guaranteed minimum fling speed even if standing still
	},

	-- Soft-Lock & Targeting
	Targeting = {
		SoftLockRadius = 18, -- Cone radius around cursor to snap to valid grapple surfaces
		RaycastLayers = RaycastParams.new(),
		ValidTag = "Grappleable",
		AllowAllSurfaces = true, -- Can grapple to any solid wall (Spider-Man style)
	},

	-- Visual & Sound Effects
	Visuals = {
		RopeColor = Color3.fromRGB(0, 210, 255), -- Electric cyan
		RopeColorActive = Color3.fromRGB(255, 170, 0),
		RopeWidth = 0.18,
		RopeTexture = "rbxassetid://6034177579",
		RopeTextureLength = 4,
		RopeTransparency = 0.1,
		ShowHookPointMarker = true,
		ReticleColorValid = Color3.fromRGB(0, 255, 180),
		ReticleColorInvalid = Color3.fromRGB(255, 80, 80),
		ReticleColorInRange = Color3.fromRGB(0, 200, 255),
	},
}

return GrappleConfig
