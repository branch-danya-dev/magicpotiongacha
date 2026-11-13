--!nonstrict
-- Stage A deterministic art prototype. No game state or accounting.
local P={seconds=2.4,maxPages=24,maxStreams=3,maxBooks=2}
local tau=2*math.pi
local function clamp(x) return math.clamp(x,0,1) end
function P.smooth(x) x=clamp(x); return x*x*(3-2*x) end
function P.quality(name,motion)
 local full,minimal=name=="full",name=="minimal"
 return {pages=motion and 0 or (full and 22 or minimal and 4 or 12),streams=motion and 0 or (full and 3 or minimal and 1 or 2),
  runes=full and 6 or minimal and 2 or 4,books=full and 2 or 1,range=full and 100 or minimal and 32 or 72,
  hz=full and 60 or minimal and 20 or 30,motion=not motion and not minimal,calm=motion,
  sparks=motion and 0 or (full and 28 or minimal and 4 or 14),light=not minimal}
end
function P.new()
 local self={started=nil,lastPulse=nil,confirmed=0,batches=0}
 function self.trigger(now)
  self.confirmed+=1;self.lastPulse=now
  if self.started and now-self.started<P.seconds then return false end
  self.started=now;self.batches+=1;return true
 end
 function self.cancel() self.started=nil;self.lastPulse=nil end
 return self
end
function P.flash(now,last)
 if not last then return 0 end
 local t=now-last
 return t>=0 and math.exp(-t*6)*P.smooth(t/.035) or 0
end
function P.envelope(age)
 return P.smooth(age/.07)*(1-P.smooth((age-1.45)/.95))
end
function P.rune(t,index,motion,velocity)
 local phase=index*2.39996323
 local a=phase+(motion and t*(.32+.045*(index%3))*(index%2==0 and -1 or 1)+velocity*(.8+.1*index) or 0)
 local r=1.8+(index%3)*.32+(motion and math.sin(t*.67+phase)*.15 or 0)
 return {x=math.cos(a)*r,z=math.sin(a)*r,y=.5+(index%3)*.48+(motion and math.sin(t*.9+phase)*.23 or 0),
  yaw=-a+math.pi/2+(motion and math.sin(t*.43+phase)*.35 or 0),roll=motion and math.sin(t*.6+phase)*.22 or 0,
  glow=.74+.14*math.sin(t*.75+phase)}
end
function P.page(age,index,count,calm)
 local delay=.08+(index%6)*.045
 local u=clamp((age-delay)/2.04)
 local a=index*2.39996323; local twist=(index%2==0 and 1 or -1)
 local spin=a+u*(index%3==0 and 5.8 or 2.3)*twist
 local r=.2+(1.2+(index%5)*.32)*P.smooth(u/.6)
 local y=.3+(2.8+(index%4)*.48)*math.sin(u*math.pi*.89)-1.7*u
 local burn=P.smooth((u-.28)/.55)
 return {x=math.cos(spin)*r,y=math.max(.2,y),z=math.sin(spin)*r,
  pitch=-.3+u*(2.2+(index%3))*.7,roll=a+math.sin(u*11+index)*.5,yaw=spin,
  fold=math.sin(u*8+index)*.36,alpha=age<delay and 0 or P.smooth(u/.055)*(1-P.smooth((u-.69)/.31)),
  burn=burn,scale=1-.76*P.smooth((u-.6)/.4),ash=P.smooth((u-.68)/.14)*(1-P.smooth((u-.87)/.13))}
end
function P.soul(u,index)
 u=clamp(u);local a=index*tau/3+u*tau*1.15;local r=math.sin(u*math.pi)*(1.15+.25*index)
 return {blend=P.smooth(u),x=math.cos(a)*r,y=math.sin(u*math.pi)*1.15,z=math.sin(a)*r}
end
function P.chest(character)
 -- Adapter passes a simple rig lookup in tests and actual Instances in Studio.
 return character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"))
end
return P
