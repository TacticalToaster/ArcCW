function SWEP:InBipod()
    local bip = self:GetInBipod()

    -- if !self:CanBipod() then
    --     self:ExitBipod()
    -- end

    if IsValid(self:GetOwner()) and self:GetBipodPos() != self:GetOwner():EyePos() then
        self:ExitBipod()
    end

    return bip
end

SWEP.CachedCanBipod = true
SWEP.CachedCanBipodTime = 0

function SWEP:CanBipod()
    if !(self:GetBuff_Override("Bipod") or self.Bipod_Integral) then return false end

    if self:GetOwner():InVehicle() then return false end

    if self.CachedCanBipodTime >= CurTime() then return self.CachedCanBipod end

    local pos = self:GetOwner():EyePos()
    local angle = self:GetOwner():EyeAngles()
    if self:GetOwner():GetVelocity():Length() > 0 then
        return false
    end

    local rangemult = 2
    if self:IsProne() then
        rangemult = rangemult * 1.25
    end
    rangemult = rangemult * self:GetBuff_Mult("Mult_BipodRange")

    local tr = util.TraceLine({
        start = pos,
        endpos = pos + (angle:Forward() * 24 * rangemult),
        filter = self:GetOwner(),
        mask = MASK_PLAYERSOLID
    })

    if tr.Hit then -- check for stuff in front of us
        return false, tr -- bad idea???
    end

    local maxs = Vector(8, 8, 0)
    local mins = Vector(-8, -8, -16)

    angle.p = angle.p + 20

    tr = util.TraceHull({
        start = pos,
        endpos = pos + (angle:Forward() * 24 * rangemult),
        filter = self:GetOwner(),
        maxs = maxs,
        mins = mins,
        mask = MASK_PLAYERSOLID
    })

    self.CachedCanBipodTime = CurTime()

    if tr.Hit then
        self.CachedCanBipod = true

        local tr2 = util.TraceHull({
            start = tr.HitPos,
            endpos = tr.HitPos + Vector(0, 0, -16),
            filter = self:GetOwner(),
            maxs = Vector(8, 8, 1),
            mins = Vector(-8, -8, 0),
            mask = MASK_PLAYERSOLID
        })
        return true, tr2
    else
        self.CachedCanBipod = false
        return false
    end
end

function SWEP:EnterBipod(sp)
    if !sp and self:GetInBipod() then return end
    local can, tr = self:CanBipod()
    if !sp and !can then return end

    if SERVER and game.SinglePlayer() then self:CallOnClient("EnterBipod", "true") end

    if self.Animations.enter_bipod then
        self:PlayAnimation("enter_bipod", nil, nil, 0, true)
    else
        -- Block actions for a tiny bit even if there is no animation
        self:SetNextPrimaryFire(CurTime() + 0.25)
    end

    if CLIENT and self:GetBuff_Override("LHIK") then
        self:DoLHIKAnimation("enter", 0.25)
    end

    local bipodang = tr.HitNormal:Angle()
    bipodang:RotateAroundAxis(self:GetOwner():EyeAngles():Right(), 90)

    --[[]
    debugoverlay.Axis(tr.HitPos, tr.HitNormal:Angle(), 16, 5, true)
    debugoverlay.Line(tr.HitPos, tr.HitPos + bipodang:Forward() * 32, 5, color_white, true)
    debugoverlay.Line(tr.HitPos, tr.HitPos + self:GetOwner():EyeAngles():Forward() * 32, 5, Color(255, 255, 0), true)
    ]]

    self:SetBipodPos(self:GetOwner():EyePos())
    self:SetBipodAngle(bipodang) --self:GetOwner():EyeAngles()
    self.BipodStartAngle = self:GetOwner():EyeAngles()

    if game.SinglePlayer() and CLIENT then return end

    self:MyEmitSound(self.EnterBipodSound)
    self:SetInBipod(true)
end

function SWEP:ExitBipod(sp)
    if !sp and !self:GetInBipod() then return end

    if SERVER and game.SinglePlayer() then self:CallOnClient("ExitBipod", "true") end

    if self.Animations.exit_bipod then
        self:PlayAnimation("exit_bipod", nil, nil, 0, true)
    else
        self:SetNextPrimaryFire(CurTime() + 0.25)
    end

    if CLIENT and self:GetBuff_Override("LHIK") then
        self:DoLHIKAnimation("exit", 0.5)
    end

    if game.SinglePlayer() and CLIENT then return end

    self:MyEmitSound(self.ExitBipodSound)
    self:SetInBipod(false)
end
