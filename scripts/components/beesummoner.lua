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

local function OnSummonerRemove(self, summoner)
	self:RemoveAllChildren()
end

local BeeSummoner = Class(function(self, inst)
	self.inst = inst
	self.children = {}
	self.numchildren = 0
	self.maxchildren = 0
	self.childname = "mutantkillerbee"
	self.summonchance = 0.3
	self.radius = 0.5
	self.maxstore = 6
	self.numstore = self.maxstore
	self.regentask = nil
	self.regentick = 5
	self.tickscale = 3
	self.maxticks = 6
	self.currenttick = 0

	self._onchildkilled = function(child) self:OnChildKilled(child) end
	self._onattack = function(inst, data) self:SummonChild(data.target) end
	self._onsummonerremove = function(inst) OnSummonerRemove(self, inst) end

	self.inst:ListenForEvent("onattackother", self._onattack, inst)
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

function BeeSummoner:SetMaxStore(num)
	self.maxstore = num
	self.numstore = math.min(self.numstore, self.maxstore)

	if self.numstore < self.maxstore then
		self:StartRegen()
	end
end

function BeeSummoner:OnChildKilled(child)
	RemoveChildListeners(self, child)
	RemoveChild(self, child)
end

function BeeSummoner:TakeOwnership(child)
	if child.components.knownlocations ~= nil then
        child.components.knownlocations:RememberLocation("home", self.inst:GetPosition())
    end

	child:AddComponent("follower")

	if self.inst.components.leader ~= nil then
		self.inst.components.leader:AddFollower(child)
	end

	AddChildListeners(self, child)
	AddChild(self, child)
end

function BeeSummoner:GetRegenTick()
	if self.inst.components.hunger then
		local hungerpercent = self.inst.components.hunger:GetPercent()
		return self.regentick * (self.tickscale - (self.tickscale - 1) * hungerpercent)
	end

	return self.regentick
end

local function DoRegenTick(inst, self)
	self.currenttick = self.currenttick + 1
	-- print("REGEN, TICK : ", self.currenttick)

	if self.currenttick >= self.maxticks then
		self.numstore = math.min(self.numstore + 1, self.maxstore)
		self.currenttick = 0

		if self.numstore == self.maxstore then
			self:StopRegen()
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
	if self.numstore >= self.maxstore then
		self:StopRegen()
		return
	end

	if not self.regentask then
		self.currenttick = tick or 0
		local regentick = self:GetRegenTick()
		-- print("START REGEN, REGEN TICK : ", regentick)
		self.regentask = self.inst:DoTaskInTime(regentick, DoRegenTick, self)
	end
end

function BeeSummoner:CanSummonChild()
	return self.numchildren < self.maxchildren
		and math.random() < self.summonchance
		and self.numstore > 0
end

function BeeSummoner:DoSummonChild(target)
	if not self.childname then
		print("No child prefab defined")
		return
	end

	if self:CanSummonChild() then
		local pos = Vector3(self.inst.Transform:GetWorldPosition())
		local start_angle = math.random() * PI * 2
	    local rad = self.radius or 0.5
	    if self.inst.Physics then
	        rad = rad + self.inst.Physics:GetRadius()
	    end
	    local offset = FindWalkableOffset(pos, start_angle, rad, 8, false)
	    if offset == nil then
	        return
	    end

	    pos = pos + offset
	    local child = SpawnPrefab(self.childname)

		if child ~= nil then
			child.Transform:SetPosition(pos:Get())
			if target ~= nil and child.components.combat ~= nil then
				child.components.combat:SetTarget(target)
			end

			self.numstore = self.numstore - 1
			self:StartRegen()
		end

		return child
	end
end

function BeeSummoner:SummonChild(target)
	local child = self:DoSummonChild(target)
	if child ~= nil then
		self:TakeOwnership(child)
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