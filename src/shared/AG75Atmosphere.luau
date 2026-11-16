--!nonstrict
-- AG75 presentation tuning over the one existing Lighting/EnvironmentView owner.
-- Studio-only until the daytime, rain and distance views are approved in Studio.
local Style={}
function Style.enabled(studio,flag)
 return studio==true and flag~=false
end
function Style.project(sample,look,quality)
 local daylight=math.clamp((1-sample.night)*(1-sample.warm*.85)*(1-sample.dawn*.70),0,1)
 local rain=math.clamp(sample.rain,0,1)
 local bloomFactor=quality=="minimal" and 1 or (quality=="full" and 1.4 or 1.65)
 return {
  brightness=look.brightness*(1-.22*daylight),
  exposure=look.exposure-.16*daylight,
  contrast=look.contrast-.035*daylight,
  bloom=look.bloom*bloomFactor,
  threshold=1.65,
  haze=look.haze+.23*rain,
  fogFactor=1+.32*rain,
 }
end
function Style.rainTrail(alpha,rain)
 return math.clamp(alpha*1.35*math.clamp(rain,0,1),0,.72)
end
function Style.meteor(time,night,quality,reduceMotion)
 if quality=="minimal" or reduceMotion or night<.65 then return nil end
 local period=19
 local phase=time%period
 if phase>=1.65 then return nil end
 return {t=phase/1.65,side=math.floor(time/period)%2==0 and -1 or 1}
end
return Style
