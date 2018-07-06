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
	self.summonchance = 0.3
	self.radius = 0.5
	self.counter = 0

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

function BeeSummoner:DoSummonChild(target)
	if not self.childname then
		print("No child prefab defined")
		return
	end

	if self.numchildren < self.maxchildren and math.random() < self.summonchance then		
		local pos = self.inst:GetPosition()
		local start_angle = math.random() * PI * 2
	    local rad = self.radius or 0.5
	    if self.inst.Physics then
	        rad = rad + self.inst.Physics:GetRadius()
	    end
	    local offset = FindWalkableOffset(pos, start_angle, rad, 8, false, true, NoHoles)
	    if offset == nil then
	        return
	    end

	    local child = SpawnPrefab(self.childname)

		if child ~= nil then
			child.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
			if target ~= nil and child.components.combat ~= nil then
				child.components.combat:SetTarget(target)
			end
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

	return {children = children}, references
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
end


return BeeSummoner