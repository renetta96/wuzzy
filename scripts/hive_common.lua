local function OnSave(inst, data)
  if inst._ownerid then
    data._ownerid = inst._ownerid
  end

  if inst._gathertick then
    data._gathertick = inst._gathertick
  end
end

local function OnLoad(inst, data)
  if data and data._ownerid then
    inst._ownerid = data._ownerid
  end

  if data and data._gathertick then
    inst._gathertick = data._gathertick
  end
end

local function OnChildBuilt(inst, data)
  local owner = data.builder
  if owner and owner:HasTag("player") and owner.prefab == "zeta" then
    inst._ownerid = owner.userid

    if owner._hive ~= nil then
      owner._hive:OnSlave()
    end
  end
end

return {
  OnSave = OnSave,
  OnLoad = OnLoad,
  OnChildBuilt = OnChildBuilt
}
