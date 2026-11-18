--!nonstrict
local T=require("./Test")
local M=require("../qa/sky-depth/Model")
local C=require("../qa/sky-landmark/Config")
local R3=require("../qa/sky-landmark/Model")
local Lunar=require("../qa/lunar/Cycle")
local f=M.frame(C.offset)
T.test("R4 orthonormal basis is upright and fixed at the R3 landmark",function()
 T.truthy(f.up[2]>.95);T.same(f.center,C.offset)
 for _,a in ipairs({f.up,f.right,f.away})do T.near(a[1]^2+a[2]^2+a[3]^2,1,1e-9)end
 T.near(f.up[1]*f.away[1]+f.up[2]*f.away[2]+f.up[3]*f.away[3],0,1e-9)
end)
T.test("Reference framing and size agree for all three depths",function()
 local baseline=M.project(f,M.position(f,1300,700,0,true),M.reference,1000)
 for _,d in ipairs({-900,0,900})do
  local p=M.position(f,1300,700,d,true);local q=M.project(f,p,M.reference,1000)
  T.near(q.x,baseline.x,1e-9);T.near(q.y,baseline.y,1e-9)
 end
end)
T.test("Island movement produces measurable natural parallax without anchor writes",function()
 local rear=M.position(f,0,0,900,true);local front=M.position(f,0,0,-900,true)
 local eyes={};for _,x in ipairs({-62,62})do table.insert(eyes,{M.reference[1]+f.right[1]*x,6,M.reference[3]+f.right[3]*x})end
 local a=M.project(f,front,eyes[1],1000).x-M.project(f,rear,eyes[1],1000).x
 local b=M.project(f,front,eyes[2],1000).x-M.project(f,rear,eyes[2],1000).x
 T.truthy(a>3 and b< -3);T.truthy(a-b>7 and a-b<15)
 T.same(rear,M.position(f,0,0,900,true))
end)
T.test("Interleaved clouds and crown keep strict depth separation",function()
 T.truthy(M.depths.rear>M.depths.cloudBack and M.depths.cloudBack>M.depths.middle)
 T.truthy(M.depths.middle>M.depths.front and M.depths.front>M.depths.cloudFront)
end)
T.test("Minimal, unsupported mode and allocation failure all select intact R3",function()
 for _=1,20 do
  T.equal(M.mode("R4","full",true),"R4");T.equal(M.mode("R4","reduced",true),"R4")
  T.equal(M.mode("R4","minimal",true),"R3");T.equal(M.mode("R4","full",false),"R3")
  T.equal(M.mode("bad","full",true),"R3");T.equal(M.mode("R3","full",true),"R3")
 end
end)
T.test("Rear canopy is shaded and Reduced accents stay cheaper/dimmer",function()
 local c=R3.project({night=0,warm=0,cloud=0},{1,0,0},"full",0,false,{sun={.5,.8,.8},moon={0,-1,-1}})
 local a=M.lighting(c,"full");local b=M.lighting(c,"reduced")
 for i=1,3 do T.truthy(a.rear[i]<a.middle[i] and a.middle[i]<a.front[i])end
 T.truthy(b.accent<a.accent and a.accent<=.65)
end)
T.test("All moons retain inherited directional colors without state/economy changes",function()
 local colors={}
 for _,w in ipairs({{1,0,0},{0,1,0},{0,0,1}})do
  local c=R3.project({night=1,warm=0,cloud=0},w,"full",0,true,{sun={0,-1,-1},moon={.5,.8,.8}})
  table.insert(colors,M.lighting(c,"full").color)
 end
 T.truthy(colors[2][2]<colors[1][2]);T.truthy(colors[3][2]>colors[1][2])
 T.same(Lunar.weights,{60,20,20});T.equal(Lunar.seconds,1500)
end)
T.test("Foreground highlight tracks the lit side instead of only total intensity",function()
 local function lit(x)
  return M.lighting(R3.project({night=0,warm=0,cloud=0},{1,0,0},"full",0,false,{sun={x,.8,.8},moon={0,-1,-1}}),"full")
 end
 local a,b=lit(-.8),lit(.8);T.near(a.accent,b.accent,1e-9);T.truthy(math.abs(a.accentRotation-b.accentRotation)>45)
end)
T.test("Light interpolation is continuous through dusk and weather",function()
 local prior
 for i=0,1000 do
  local t=i/1000;local c=R3.project({night=t,warm=math.sin(t*math.pi),cloud=t},{1-t,t,0},"full",0,true,{sun={.2,1,1-t},moon={-.4,.7,t}})
  local nextValue=M.lighting(c,"full")
  if prior then for j=1,3 do T.truthy(math.abs(prior.color[j]-nextValue.color[j])<.01)end end
  prior=nextValue
 end
end)
T.finish()
