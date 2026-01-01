local bindKeysYOffset = 0
local DrawBindActions = {}
local lastActionTime = 0
local keyHooked, keyHookedLast

local function DrawBindKeys(x, y, key, bind, action)
	if not key then
		key = "Key not bound! Action " .. bind
	end

	local margin = 10
	local halfMargin = margin * 0.5

	surface.SetFont("ChatFont")
	local keyW, keyH = surface.GetTextSize(key)
	local actionW, actionH = surface.GetTextSize(action)

	local frameW = math.max(keyW, keyH) + margin
	local frameH = keyH + margin

	y = y + bindKeysYOffset

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(x - frameW, y, frameW, frameH)

	surface.SetDrawColor(120, 120, 120, 255)
	surface.DrawOutlinedRect(x - frameW, y, frameW, frameH)

	draw.SimpleText(
		key,
		"ChatFont",
		x - frameW * 0.5,
		y + halfMargin,
		COLOR_DARK,
		TEXT_ALIGN_CENTER
	)

	draw.SimpleText(
		action,
		"ChatFont",
		x + halfMargin,
		y + halfMargin,
		COLOR_DARK
	)

	bindKeysYOffset = bindKeysYOffset + frameH + 2
end

local function AddBindKey(bind, action, altBind)
	local key = input.LookupBinding(bind)

	if not key and altBind then
		key = input.LookupBinding(altBind)
	end

	if key then
		key = string.upper(key)
	end

	table.insert(DrawBindActions, { key, bind, action })
end

local function HelpKeyHud()
	if keyHooked and lastActionTime < CurTime() - 5 then
		return
	end

	local w, h = ScrW(), ScrH()
	local baseX = w * 0.6
	local baseY = h * 0.6

	bindKeysYOffset = 0

	for _, v in pairs(DrawBindActions) do
		DrawBindKeys(baseX, baseY, v[1], v[2], v[3])
	end
end

local function KeyPressChecker(pl, key)
	if key == IN_FORWARD
	or key == IN_BACK
	or key == IN_MOVELEFT
	or key == IN_MOVERIGHT
	or key == IN_DUCK
	or (pl:GetObserverMode() == OBS_MODE_ROAMING and key == IN_JUMP) then
		return
	end

	lastActionTime = CurTime()
end

local function HelpKeyThink()
	if not (MySelf and MySelf:IsValid()) then return end

	table.Empty(DrawBindActions)
	keyHooked = false

	if MySelf:Team() == TEAM_HUMAN then
		local bleed = MySelf.Bleed
		if IsValid(bleed) and not MySelf:KeyDown(IN_SPEED) then
			AddBindKey("+speed", "Slow bleeding")
		end

		local holding = MySelf.status_human_holding
		if IsValid(holding) then
			if not holding:GetIsHeavy() then
				AddBindKey("+walk",  "Rotate")
				AddBindKey("+speed", "Hold in place")
				AddBindKey("+reload", "Align")
			end
			return
		end

		local tr = MySelf:TraceLine(64, MASK_SOLID, team.GetPlayers(TEAM_HUMAN))
		if tr.Hit and IsValid(tr.Entity) then
			local entity = tr.Entity
			local classPrefix = string.sub(entity:GetClass(), 1, 12)

			if (classPrefix == "prop_physics" or classPrefix == "func_physbox")
			and not entity:IsNailed() then
				AddBindKey("+use", "Pick up object")
				return
			end

			if entity.IsUsable then
				AddBindKey("+use", "Use")
			end

			if entity.IsItemStore then
				AddBindKey("+walk", "Open inventory")
			end

			if entity.CanPackUp then
				AddBindKey("+speed", "Pack up")
			end

			if entity.IsBarricadeObject or entity:IsNailed() then
				AddBindKey("undo", "Walk through barricades", "gmod_undo")
			end
		end

	elseif MySelf:Team() == TEAM_UNDEAD then
		local obsMode = MySelf:GetObserverMode()

		if obsMode ~= OBS_MODE_NONE then
			AddBindKey("+attack2", "Change target")
			AddBindKey("+jump", "Free spectate")
			keyHooked = true
		end

		if GAMEMODE:GetWaveActive() and not MySelf:Alive() then
			AddBindKey("gm_showspare1", "Choose zombie class")
			AddBindKey("+attack", "Spawn")
			AddBindKey("+reload", "Reset spawn point")

			if obsMode == OBS_MODE_CHASE then
				local target = MySelf:GetObserverTarget()
				if IsValid(target)
				and target:GetClass() == "prop_creepernest"
				and target:GetNestBuilt() then
					AddBindKey("+duck", "Set this nest as primary")
				end
			end
		end
	end

	if keyHooked ~= keyHookedLast then
		if keyHooked then
			hook.Add("KeyPress", "HelpKeyKeyPress", KeyPressChecker)
			lastActionTime = CurTime()
		else
			hook.Remove("KeyPress", "HelpKeyKeyPress")
		end
		keyHookedLast = keyHooked
	end
end

local function HelpKeyEnable(enable)
	if not enable then
		hook.Remove("HUDPaint", "HelpKeyHUDPaint")
		timer.Destroy("HelpKeyThink")
		return
	end

	hook.Add("HUDPaint", "HelpKeyHUDPaint", HelpKeyHud)
	timer.Create("HelpKeyThink", 0.1, 0, HelpKeyThink)
end

local enableHelpKey = CreateClientConVar("zs_keyhelp", "1", true, false):GetBool()

cvars.AddChangeCallback("zs_keyhelp", function(_, _, newValue)
	HelpKeyEnable(tonumber(newValue) == 1)
end)

HelpKeyEnable(enableHelpKey)
