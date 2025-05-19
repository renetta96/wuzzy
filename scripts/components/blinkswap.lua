-- private entity, non-networked, minimal for blink only
local function createBlinkStaff(enable_fx)
	local inst = CreateEntity()

	inst:AddTag("CLASSIFIED")
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst:AddComponent("blinkstaff")
	if enable_fx then
		inst.components.blinkstaff:SetFX("sand_puff_large_front", "sand_puff_large_back")
	else
		inst.components.blinkstaff:SetSoundFX(nil, nil)
	end

	return inst
end

local BlinkSwap = Class(function(self, inst)
	self.inst = inst
	self.blinkstaff_doer = createBlinkStaff(true)
	self.blinkstaff_target = createBlinkStaff(false)
end)

local function validBlinkPos(pt)
	return TheWorld.Map:IsPassableAtPoint(pt:Get()) and not TheWorld.Map:IsGroundTargetBlocked(pt)
end

function BlinkSwap:SetOnBlinkDoerFn(onblinkfn)
	self.blinkstaff_doer.components.blinkstaff.onblinkfn = onblinkfn
end

function BlinkSwap:SetOnBlinkTargetFn(onblinkfn)
	self.blinkstaff_target.components.blinkstaff.onblinkfn = onblinkfn
end

function BlinkSwap:Swap(doer, target)
	local targetPos = target:GetPosition()
	local doerPos = doer:GetPosition()

	if not validBlinkPos(targetPos) then
		return false
	end

	if not validBlinkPos(doerPos) then
		return false
	end

	-- print("BLINK", target, targetPos, doer, doerPos)

	local actOK = self.blinkstaff_doer.components.blinkstaff:Blink(targetPos, doer)
	if actOK and target.sg ~= nil then
		-- print("ACT OK")
		target._lastcombattime = GetTime()
		target:ClearBufferedAction()

		target.sg:GoToState("quicktele")

		-- temp func to be called in stategraph
		target._blinkfn = function()
			-- async func so need to check valid to safeguard
			if target:IsValid() then
				self.blinkstaff_target.components.blinkstaff:Blink(doerPos, target)
				-- print("BLINK TARGET RESULT", ok)
			end
		end
	end

	return actOK
end

return BlinkSwap
