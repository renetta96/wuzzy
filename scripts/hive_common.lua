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

local function setowner(inst, owner)
  if owner and owner:HasTag("player") and owner.prefab == 'zeta' then
    inst._ownerid = owner.userid
  end
end


local function OnChildBuilt(inst, data)
  local builder = data.builder
  setowner(inst, builder)
end

return {
  OnSave = OnSave,
  OnLoad = OnLoad,
  OnChildBuilt = OnChildBuilt
}
