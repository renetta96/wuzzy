local function debugstring(stack)
  if stack == nil then
    return "<nil>"
  end

  return string.format("damage=%d, ticskleft=%d", stack.damage, stack.ticksleft)
end

local DOTable =
  Class(
  function(self, inst)
    self.inst = inst
    self.stacks = {}
    self.tickinterval = 1 -- every sec
    self.sources = {}

    self._gc = nil
    self._ticktask = nil

    self.ontickfn = nil

    self.inst:ListenForEvent(
      "death",
      function(inst)
        self:StopTicking()
      end
    )
    self.inst:ListenForEvent(
      "onremove",
      function(inst)
        self:StopTicking()
      end
    )
  end
)

local function _gc(inst, self)
  -- print("GC")

  self.stacks = self:GetEffectiveStacks()

  if not self:HasEffectiveStack() then
    self:StopTicking()
  end
end

function DOTable:GetEffectiveStacks()
  local remainstacks = {}

  for source, stacks in pairs(self.stacks) do
    remainstacks[source] = {}

    for i, s in ipairs(stacks) do
      if s.ticksleft > 0 then
        table.insert(remainstacks[source], s)
      end
    end
  end

  return remainstacks
end

function DOTable:HasEffectiveStack()
  for source, stacks in pairs(self.stacks) do
    if #stacks > 0 then
      return true
    end
  end

  return false
end

function DOTable:DoDamage(source, damage)
  -- print("DOT DAMAGE: ", source, damage)

  if self.inst:IsValid() and self.inst.components.health and not self.inst.components.health:IsDead() then
    local delta = math.min(damage, self.inst.components.health.currenthealth - 1)
    self.inst.components.health:DoDelta(-delta, true, "dot_tick_" .. source)
  end
end

local function OnTick(inst, self)
  -- print("ON TICK")

  local damaged_sources = {}
  local all_damage = 0

  for source, stacks in pairs(self.stacks) do
    -- print("SOURCE", source)
    local total_damage = 0

    for i, stack in ipairs(stacks) do
      if stack.ticksleft > 0 then
        -- print("BEFORE", debugstring(stacks[i]))
        stack.ticksleft = stack.ticksleft - 1

        total_damage = total_damage + stack.damage

      -- print("AFTER", debugstring(stacks[i]))
      end
    end

    all_damage = all_damage + total_damage

    if total_damage > 0 then
      self:DoDamage(source, total_damage)
      table.insert(damaged_sources, source)
    end
  end

  if self.ontickfn ~= nil then
    self.ontickfn(self.inst, damaged_sources, all_damage)
  end
end

function DOTable:StartTicking()
  if self._ticktask == nil then
    self._ticktask = self.inst:DoPeriodicTask(self.tickinterval, OnTick, nil, self)
  end

  if not self._gc then
    self._gc = self.inst:DoPeriodicTask(5, _gc, nil, self)
  end
end

function DOTable:StopTicking()
  if self._ticktask ~= nil then
    self._ticktask:Cancel()
    self._ticktask = nil
  end

  if self._gc then
    self._gc:Cancel()
    self._gc = nil
  end
end

function DOTable:AddSource(name, maxstacks)
  -- allow overwrite
  self.sources[name] = {
    maxstacks = maxstacks
  }
end

local function getLastNElements(array, n)
  local result = {}
  local length = #array

  -- Ensure n is not greater than the length of the array
  n = math.min(n, length)

  -- Start index for copying elements
  local startIndex = length - n + 1

  -- Copy last N elements into the result table
  for i = startIndex, length do
    table.insert(result, array[i])
  end

  return result
end

function DOTable:Add(source, damage, numticks)
  if self.sources[source] == nil then
    print("WARNING: source does not exist:", source)
    return
  end

  if numticks > 0 then
    if self.stacks[source] == nil then
      self.stacks[source] = {}
    end

    table.insert(
      self.stacks[source],
      {
        damage = damage,
        ticksleft = numticks
      }
    )

    if self.sources[source].maxstacks ~= nil then
      self.stacks[source] = getLastNElements(self.stacks[source], self.sources[source].maxstacks)
    end

    self:StartTicking()
  end
end

function DOTable:OnSave()
  -- print("ON SAVE")
  return {
    stacks = self:GetEffectiveStacks(),
    sources = self.sources,
    add_component_if_missing = true
  }
end

function DOTable:OnLoad(data)
  -- print("ON LOAD")
  if data and data.sources ~= nil then
    self.sources = data.sources
  end

  if data and data.stacks ~= nil then
    self.stacks = data.stacks
    self.stacks = self:GetEffectiveStacks()

    if self:HasEffectiveStack() then
      -- print("CONTINUE FROM LOAD")
      self:StartTicking()
    end
  end
end

return DOTable
