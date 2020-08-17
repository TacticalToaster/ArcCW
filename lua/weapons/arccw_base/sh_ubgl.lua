
function SWEP:SelectUBGL()
    self:SetNWBool("ubgl", true)
    self:EmitSound(self.SelectUBGLSound)
    self:SetNWInt("firemode", 1)

    if CLIENT then
        if !ArcCW:ShouldDrawHUDElement("CHudAmmo") then
            self:GetOwner():ChatPrint("Selected " .. self:GetBuff_Override("UBGL_PrintName") or "UBGL")
        end
        if !self:GetLHIKAnim() then
            self:DoLHIKAnimation("enter")
        end
    end

    if self:GetBuff_Override("UBGL_BaseAnims") and self.Animations.enter_ubgl_empty and self:Clip2() == 0 then
        self:PlayAnimation("enter_ubgl_empty", 1, false, 0, true)
        self:SetNextSecondaryFire(CurTime() + self.Animations.enter_ubgl_empty.Time)
    elseif self:GetBuff_Override("UBGL_BaseAnims") and self.Animations.enter_ubgl then
        self:PlayAnimation("enter_ubgl", 1, false, 0, true)
        self:SetNextSecondaryFire(CurTime() + self.Animations.enter_ubgl.Time)
    end
end

function SWEP:DeselectUBGL()
    self:SetNWBool("ubgl", false)
    self:EmitSound(self.ExitUBGLSound)

    if CLIENT then
        if !ArcCW:ShouldDrawHUDElement("CHudAmmo") then
            self:GetOwner():ChatPrint("Deselected " .. self:GetBuff_Override("UBGL_PrintName") or "UBGL")
        end
        if !self:GetLHIKAnim() then
            self:DoLHIKAnimation("exit")
        end
    end

    if self:GetBuff_Override("UBGL_BaseAnims") and self.Animations.exit_ubgl_empty and self:Clip2() == 0 then
        self:PlayAnimation("exit_ubgl_empty", 1, false, 0, true)
    elseif self:GetBuff_Override("UBGL_BaseAnims") and self.Animations.exit_ubgl then
        self:PlayAnimation("exit_ubgl", 1, false, 0, true)
    end
end

function SWEP:RecoilUBGL()
    if !game.SinglePlayer() and !IsFirstTimePredicted() then return end
    if game.SinglePlayer() and self:GetOwner():IsValid() and SERVER then
        self:CallOnClient("RecoilUBGL")
    end

    local amt = self:GetBuff_Override("UBGL_Recoil")

    local r = math.Rand(-1, 1)
    local ru = math.Rand(0.75, 1.25)

    local m = 1 * amt
    local rs = 1 * amt * 0.1
    local vsm = 1

    local vpa = Angle(0, 0, 0)

    vpa = vpa + (Angle(1, 0, 0) * amt * m * vsm)

    vpa = vpa + (Angle(0, 1, 0) * r * amt * m * vsm)

    if CLIENT then
        self:OurViewPunch(vpa)
    end
    -- self:SetNWFloat("recoil", self.Recoil * m)
    -- self:SetNWFloat("recoilside", r * self.RecoilSide * m)

    if CLIENT or game.SinglePlayer() then

        self.RecoilAmount = self.RecoilAmount + (amt * m)
        self.RecoilAmountSide = self.RecoilAmountSide + (r * amt * m * rs)

        self.RecoilPunchBack = amt * 1 * m

        if self.MaxRecoilBlowback > 0 then
            self.RecoilPunchBack = math.Clamp(self.RecoilPunchBack, 0, self.MaxRecoilBlowback)
        end

        self.RecoilPunchSide = rs * rs * m * 0.1 * vsm
        self.RecoilPunchUp = ru * amt * m * 0.3 * vsm
    end
end

function SWEP:ShootUBGL()
    if self:GetNextSecondaryFire() > CurTime() then return end

    self.Primary.Automatic = self:GetBuff_Override("UBGL_Automatic")

    local ubglammo = self:GetBuff_Override("UBGL_Ammo")

    if self:Clip2() <= 0 and self:GetOwner():GetAmmoCount(ubglammo) <= 0 then
        self.Primary.Automatic = false
        self:DeselectUBGL()
        return
    end

    if self:Clip2() <= 0 then
        return
    end

    self:RecoilUBGL()

    local func, slot = self:GetBuff_Override("UBGL_Fire")

    if func then
        func(self, self.Attachments[slot].VElement)
    end

    self:SetNextSecondaryFire(CurTime() + (60 / self:GetBuff_Override("UBGL_RPM")))
end

function SWEP:ReloadUBGL()
    if self:GetNextSecondaryFire() > CurTime() then return end

    local reloadfunc, slot = self:GetBuff_Override("UBGL_Reload")

    if reloadfunc then
        reloadfunc(self, self.Attachments[slot].VElement)
    end
end