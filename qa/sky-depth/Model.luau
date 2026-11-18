--!nonstrict
-- Fixed world positions, calibrated once at the spawn eye. No camera tracking.
local M={}
M.reference={0,6,20}
M.depths={rear=900,middle=0,front=-900,cloudBack=460,cloudFront=-1180}
M.textureBytes=4194304
M.maxAddedInstances=26
local function sub(a,b)return {a[1]-b[1],a[2]-b[2],a[3]-b[3]}end
local function dot(a,b)return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]end
local function unit(a)local n=math.sqrt(dot(a,a));return {a[1]/n,a[2]/n,a[3]/n},n end
function M.frame(center)
 local away,distance=unit(sub(center,M.reference))
 local right=unit({-away[3],0,away[1]})
 local up={right[2]*away[3]-right[3]*away[2],right[3]*away[1]-right[1]*away[3],right[1]*away[2]-right[2]*away[1]}
 return {away=away,right=right,up=up,distance=distance,center=center}
end
function M.position(frame,x,y,depth,calibrate)
 local scale=calibrate and (frame.distance+depth)/frame.distance or 1
 local p={}
 for i=1,3 do p[i]=frame.center[i]+frame.away[i]*depth+(frame.right[i]*x+frame.up[i]*y)*scale end
 return p,scale
end
function M.mode(requested,quality,ready)
 return requested=="R4" and quality~="minimal" and ready==true and "R4" or "R3"
end
function M.valid(mode)return mode=="R3" or mode=="R4"end
function M.project(frame,point,eye,focal)
 local v=sub(point,eye);local depth=dot(v,frame.away)
 return {x=dot(v,frame.right)*focal/depth,y=dot(v,frame.up)*focal/depth,depth=depth}
end
function M.lighting(current,quality)
 local c=current.color
 local light=math.clamp(current.lightTop+current.lightLeft+current.lightRight,0,1)
 local scale=quality=="reduced" and .65 or 1
 return {
  rear={c[1]*.78,c[2]*.83,c[3]*.91},middle={c[1]*.92,c[2]*.94,c[3]*.98},front=c,
  accent=math.clamp((.12+light*.65)*scale,0,.65),color=current.lightColor,
  accentRotation=math.deg(math.atan2(-current.lightTop,current.lightLeft-current.lightRight)),
  bark={.34+.12*light*current.lightColor[1],.30+.12*light*current.lightColor[2],.36+.12*light*current.lightColor[3]},
 }
end
return M
