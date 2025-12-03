local ColorPulser = Class(function(self, inst)
    self.inst = inst
    self.timepassed = 0
    self.period = 1.5

    -- will crash if do not set
    self.t_r = nil
    self.t_g = nil
    self.t_b = nil

    self.stopped = false
end)

function ColorPulser:SetTargetColor(t_r, t_g, t_b)
    self.t_r = t_r
    self.t_g = t_g
    self.t_b = t_b
end

function ColorPulser:Start()
    self.timepassed = 0
    self.inst.AnimState:SetAddColour(0, 0, 0, 0)
    self.stopped = false

    self.inst:DoTaskInTime(math.random() * self.period, function()
        if not self.stopped then
            self.inst:StartUpdatingComponent(self)
        end
    end)
end

function ColorPulser:Stop()
    self.stopped = true
    self.inst.AnimState:SetAddColour(0, 0, 0, 0)
    self.inst:StopUpdatingComponent(self)
end

function ColorPulser:OnUpdate(dt)
    if self.stopped then
        return
    end

    self.timepassed = self.timepassed + dt
    if self.timepassed > self.period then
        self.timepassed = self.timepassed % self.period
    end

    local v = (math.sin(self.timepassed * 2 * math.pi / self.period) + 1) * 0.5

    self.inst.AnimState:SetAddColour(v * self.t_r, v * self.t_g, v * self.t_b, 0)
end

return ColorPulser