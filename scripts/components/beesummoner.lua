local function AddChild(self, child)
	if self.children[child] ~= nil then
		print("Already added child", child)
		return
	end

	child.persists = false
	self.children[child] = child
	self.numchildren = GetTableSize(self.children)
end

local function RemoveChild(self, child)
	if self.children[child] == nil then
		print("Not our child or already removed child", child)
		return
	end

	self.children[child] = nil
	self.numchildren = GetTableSize(self.children)
end

local function AddChildListeners(self, child)
    self.inst:ListenForEvent("ontrapped", self._onchildkilled, child)
    self.inst:ListenForEvent("death", self._onchildkilled, child)
    self.inst:ListenForEvent("detachchild", self._onchildkilled, child)
    self.inst:ListenForEvent("onremove", self._onchildkilled, child)
end

local function RemoveChildListeners(self, child)
    self.inst:RemoveEventCallback("ontrapped", self._onchildkilled, child)
    self.inst:RemoveEventCallback("death", self._onchildkilled, child)
    self.inst:RemoveEventCallback("detachchild", self._onchildkilled, child)
    self.inst:RemoveEventCallback("onremove", self._onchildkilled, child)
end

local function OnPlayerLeft(self, player)
	if self.inst.userid and self.inst.userid == player.userid then
		self:RemoveAllChildren()
	end
end

local function OnSummonerRemove(self, summoner)
	self:RemoveAllChildren()
end

local BeeSummoner = Class(function(self, inst)
	self.inst = inst
	self.children = {}
	self.numchildren = 0
	self.maxchildren = 0
	self.childname = "mutantkillerbee"
	self.childprefabfn = nil
	self.summonchance = 0.3
	self.radius = 0.5
	self.maxstore = 6
	self.numstore = self.maxstore
	self.regentask = nil
	self.regentick = 5
	self.tickscale = 3
	self.maxticks = 6
	self.currenttick = 0
	self.store_modifiers_add = {}
	self.regentick_modifiers_mult = {}

	self._onchildkilled = function(child) self:OnChildKilled(child) end
	self._onattack = function(inst, data) self:SummonChild(data.target) end
	self._onplayerleft = function(src, player) OnPlayerLeft(self, player) end
	self._onsummonerremove = function(inst) OnSummonerRemove(self, inst) end

	self.inst:ListenForEvent("onattackother", self._onattack, inst)
	self.inst:ListenForEvent("ms_playerleft", self._onplayerleft, TheWorld)
	self.inst:ListenForEvent("onremove", self._onsummonerremove, self.inst)
end)

function BeeSummoner:OnRemoveFromEntity()
	for k, v in pairs(self.children) do
		RemoveChildListeners(self, v)
	end
end

function BeeSummoner:RemoveAllChildren()
	for k, v in pairs(self.children) do
		if v.components.health then
			v.components.health:Kill()
		else
			v:Remove()
		end
	end
end

function BeeSummoner:SetMaxChildren(num)
	self.maxchildren = num
end

function BeeSummoner:SetSummonChance(chance)
	self.summonchance = math.min(math.max(chance, 0), 1.0)
end

local function Refresh(self)
	local currentnumstore = self.numstore

	self.numstore = math.min(self.numstore, self:GetTotalStore())

	if currentnumstore ~= self.numstore then
		self.inst:PushEvent("onnumstorechange", {numstore = self.numstore})
	end

	if self.numstore < self:GetTotalStore() then
		self:StartRegen()
	end
end

function BeeSummoner:SetMaxStore(num)
	self.maxstore = num
	Refresh(self)
end

function BeeSummoner:OnChildKilled(child)
	RemoveChildListeners(self, child)
	RemoveChild(self, child)
end

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

function BeeSummoner:TakeOwnership(child)
	if child.components.knownlocations ~= nil then
        child.components.knownlocations:RememberLocation("home", self.inst:GetPosition())
    end

	child:AddComponent("follower")
	child.components.follower:KeepLeaderOnAttacked()
	child.components.follower.keepdeadleader = true

	if self.inst.components.leader ~= nil then
		self.inst.components.leader:AddFollower(child)
	end

	AddChildListeners(self, child)
	AddChild(self, child)
end

function BeeSummoner:AddStoreModifier_Additive(key, mod)
	self.store_modifiers_add[key] = mod
	Refresh(self)
end

function BeeSummoner:RemoveStoreModifier_Additive(key)
	self.store_modifiers_add[key] = nil
	Refresh(self)
end

function BeeSummoner:GetTotalStore()
	local total = self.maxstore

	for k, v in pairs(self.store_modifiers_add) do
		total = total + v
	end

	return total
end

function BeeSummoner:AddRegenTickModifier_Mult(key, mod)
	self.regentick_modifiers_mult[key] = mod
end

function BeeSummoner:RemoveRegenTickModifier_Mult(key)
	self.regentick_modifiers_mult[key] = nil
end

function BeeSummoner:GetRegenTickMultiplier()
	local mult = 1

	for k, v in pairs(self.regentick_modifiers_mult) do
		mult = mult * v
	end

	return mult
end

function BeeSummoner:GetRegenTick()
	if self.inst.components.hunger then
		local hungerpercent = self.inst.components.hunger:GetPercent()
		return self.regentick * (self.tickscale - (self.tickscale - 1) * hungerpercent) * self:GetRegenTickMultiplier()
	end

	return self.regentick * self:GetRegenTickMultiplier()
end

function BeeSummoner:GetRegenTickPercent()
	return self.currenttick / self.maxticks
end

function BeeSummoner:SetTick(tick)
	self.currenttick = tick
	self.inst:PushEvent("onregentick", {currenttick = self.currenttick})
end

function BeeSummoner:AddNumStore(num)
	self.numstore = math.min(math.max(0, self.numstore + num), self:GetTotalStore())
	self.inst:PushEvent("onnumstorechange", {numstore = self.numstore})

	if self.numstore >= self:GetTotalStore() then
		self:SetTick(0)
		self:StopRegen()
	end
end

function BeeSummoner:GetNumStoreRegen()
	local totalstore = self:GetTotalStore()
	local added = totalstore - self.maxstore

	if added < 1 then
		return 1
	end

	return 1 + math.floor(math.log(added))
end

local function DoRegenTick(inst, self)
	self:SetTick(self.currenttick + 1)
	-- print("REGEN, TICK : ", self.currenttick)

	if self.currenttick >= self.maxticks then
		self:AddNumStore(self:GetNumStoreRegen())
		self:SetTick(0)

		if self.numstore >= self:GetTotalStore() then
			return
		end
	end

	local regentick = self:GetRegenTick()
	-- print("REGEN, REGEN TICK : ", regentick)
	self.regentask = self.inst:DoTaskInTime(regentick, DoRegenTick, self)
end

function BeeSummoner:StopRegen()
	if self.regentask ~= nil then
		-- print("STOP REGEN")
		self.regentask:Cancel()
		self.regentask = nil
	end
end

function BeeSummoner:StartRegen(tick)
	if self.numstore >= self:GetTotalStore() then
		self:StopRegen()
		return
	end

	if not self.regentask then
		self:SetTick(tick or 0)
		local regentick = self:GetRegenTick()
		-- print("START REGEN, REGEN TICK : ", regentick)
		self.regentask = self.inst:DoTaskInTime(regentick, DoRegenTick, self)
	end
end

function BeeSummoner:GetChildPrefab()
	if self.childprefabfn then
		return self.childprefabfn(self.inst)
	end

	return self.childname
end

function BeeSummoner:CanSummonChild()
	return self.numchildren < self.maxchildren
		and math.random() < self.summonchance
		and self.numstore > 0
end

function BeeSummoner:DoSummonChild(target)
	if not self:CanSummonChild() then
		return
	end

	local childprefab = self:GetChildPrefab()

	if not childprefab then
		print("No child prefab defined")
		return
	end

	local pos = self.inst:GetPosition()
	local start_angle = math.random() * PI * 2
  local rad = self.radius or 0.5
  if self.inst.Physics then
      rad = rad + self.inst.Physics:GetRadius()
  end
  local offset = FindWalkableOffset(pos, start_angle, rad, 8, false, true, NoHoles, true, true)
  if offset == nil then
      return
  end

 	local child = SpawnPrefab(childprefab)

	if child ~= nil then
		child.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
		if target ~= nil and target ~= self.inst and child.components.combat ~= nil then
			child.components.combat:SetTarget(target)
		end

		self:AddNumStore(-1)
		self:StartRegen()

		self.inst:PushEvent("onsummonchild", { child = child })
	end

	return child
end

function BeeSummoner:SummonChild(target)
	local child = self:DoSummonChild(target)
	if child ~= nil then
		self:TakeOwnership(child)
	end
end

function BeeSummoner:Despawn(child)
	if self.children[child] then
		child:Remove()
		self:AddNumStore(1)
		return true
	end
end

function BeeSummoner:OnSave()
	local children = {}
	local references = {}

	for k, v in pairs(self.children) do
		if v then
			local record, refs = v:GetSaveRecord()
			table.insert(children, record)

			if refs then
				for k, v in pairs(refs) do
					table.insert(references, v)
				end
			end
		end
	end

	local data = {}
	data.children = children
	data.numstore = self.numstore
	data.currenttick = self.currenttick

	return data, references
end

function BeeSummoner:OnLoad(data, newents)
	if data and data.children then
		for k, v in pairs(data.children) do
			local child = SpawnSaveRecord(v, newents)
			if child then
				self:TakeOwnership(child)
			end
		end
	end

	self.numstore = data.numstore or self.numstore
	self.currenttick = data.currenttick or self.currenttick
	self:StartRegen(self.currenttick)
end


return BeeSummoner
