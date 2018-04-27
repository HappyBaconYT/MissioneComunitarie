// MANEUVERS LIBRARY

function MNVLIB_DeltaVCircularization
{
  local mu is body:mu.
  local apo is body:radius + apoapsis.
  local peri is body:radius + periapsis.

  return sqrt(mu/apo) - sqrt((peri*mu)/(apo*(peri + apo)/2)).
}

function MNVLIB_ManeuverTime
{
  parameter deltaV.
  return deltaV/ship:maxthrust/ship:mass.
}

function MNVLIB_ManeuverTimePrecise
{
  parameter deltaV.

  local e is constant():e.
  // get active engine isp
  list engines in eng_list.
  for eng in eng_list
  {
    if (eng:ignition)
    set isp to eng:isp.
  }
  local mass_in is ship:mass.
  local mass_fin is mass_in/(e^(deltaV/isp/9.81)).
  local thrust is ship:maxthrust.

  return 9.81*ship:mass*isp*(1 - e^(-deltaV/9.81/isp))/thrust.
}

function MNVLIB_HohmannDeltaV
{
  parameter desApo.

  local mu is body:mu.
  local r1 is ship:obt:semimajoraxis.
  local r2 is body:radius + desApo.

  local v1 is sqrt(mu/r1)*(sqrt(2*r2/(r2 + r1)) - 1).
  local v2 is sqrt(mu/r2)*(1 - sqrt(2*r1/(r1 + r2))).

  return list(v1, v2).
}

function MNVLIB_ExecuteMnvNode
{
  parameter doWarp.

  local node is nextnode.
  local startVector is node:burnvector.

  local mnvStartTime is time:seconds + node:eta - MNVLIB_ManeuverTimePrecise(node:burnvector:mag)/2.

  lock steering to startVector.
  if (doWarp)
  {
    warpto(mnvStartTime - 90).
  }

  wait until time:seconds > mnvStartTime.
  lock throttle to min(MNVLIB_ManeuverTimePrecise(node:burnvector:mag), 1).
  wait until (vdot(node:burnvector, startVector) < 0).
  lock throttle to 0.
  unlock steering.
  remove node.
}
