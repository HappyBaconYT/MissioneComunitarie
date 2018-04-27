// missioni comunitarie 1

// brakes on = execute maneuver node
// gear = RESERVED for anding gear
// rcs = RESERVED for rcs
// ag1 = toggle solar panels
// ag2 = deploy fairings
// ag3 = toggle dish antenna
// ag4 = toggle small antenna
// ag5 = all the scienceee

// import libraries
runpath("0:LAUNCH_LIB.ks").
runpath("0:MNV_LIB.ks").
runpath("0:LANDING_LIB.ks").

// calculate angle to the mun
function MunAngle
{
  set munLongitude to body("Mun"):longitude.
  set vesselLongitude to ship:longitude.

  if (munLongitude < 0)
  {
    set munLongitude to munLongitude + 360.
  }
  if (vesselLongitude < 0)
  {
    set vesselLongitude to vesselLongitude + 360.
  }

  return mod(body("Mun"):longitude - ship:longitude + 720, 360).
}


// ----------------- MAIN PROGRAM ----------------- //

// set ship to known state
brakes off.
sas off.
rcs off.

// set launch parametes
set dir to 90.
set desTWR to 2.0.
set desApo to 80000.

lock steering to heading(dir,90) + R(0,0,-90).
lock throttle to 1.

// launch
stage.

// pitch-over
wait until (airspeed > 50).
lock steering to heading(dir,80) + R(0,0,-90).
until (airspeed > 150)
{
  if (CheckFlameout())
  {
    stage.
  }
  if (maxthrust > 0)
  {
    set newThrottle to desTWR*9.8*ship:mass/maxthrust.
    lock throttle to newThrottle.
  }
  wait 0.1.
}

// gravity turn
until (apoapsis > desApo)
{
  if (CheckFlameout())
  {
    stage.
  }
  if (maxthrust > 0)
  {
    set newThrottle to desTWR*9.8*ship:mass/maxthrust.
    lock throttle to newThrottle.
  }
  if (altitude < 40000)
  {
    lock steering to srfprograde + R(0,0,-90).
  }
  else
  {
    lock steering to prograde + R(0,-3,-90).
  }
  wait 0.1.
}
lock throttle to 0.

// deploy fairings
ag2 on.
wait 3.

// circularization
rcs on.
wait until (altitude > 70000).
lock steering to heading(dir,0) + R(0,0,-90).
set mnvTime to MNVLIB_ManeuverTimePrecise(MNVLIB_DeltaVCircularization()).
wait until (eta:apoapsis < mnvTime/2).
set start_mnv to time:seconds.
until (time:seconds > start_mnv + mnvTime)
{
  lock throttle to 1.
  if (CheckFlameout())
  {
    stage.
  }
  wait 0.1.
}
lock throttle to 0.
wait 1.

print "Parking orbit achieved!".

// extend solar panels
ag1 on.
wait 3.

// detach launcher
lock throttle to 0.
wait 2.
stage.
wait 20.

// align for max sun exposure
lock steering to sun:position.

wait 20.


// wait for launch window
print "Waiting for launch window".
until (MunAngle() < 140 and MunAngle() > 130)
{
  print "angle = " + MunAngle().
  wait (10).
}
set warp to 0.

// munar injection burn
print "Beginning transfer burn".
set dir to prograde.
lock steering to prograde.
wait 30.
lock throttle to 1.
wait until (apoapsis > body("Mun"):apoapsis).
lock throttle to 0.
print "transfer burn completed".
lock steering to sun:position.
wait 10.

// wait for correction burn
print "waiting for correction burn".
wait until (brakes).
print "executing correction burn".
brakes off.
MNVLIB_ExecuteMnvNode(true).

// align for max sun exposure
lock steering to sun:position.

// warp to moon SOI
//warpto(eta:transition).
wait until (ship:orbit:body:name = "Mun").
set warp to 0.
wait 10.

// capture burn
// lock steering to retrograde.
// warpto(time:seconds + eta:periapsis - 120).
// wait until (eta:periapsis < 5).
// lock throttle to 1.
// wait until (abs(ship:groundspeed) < 100).
// lock throttle to 0.
// wait 5.
// stage.
// wait 1.
// stage.
// wait 5.

// wait for capture burn
print "waiting for capture burn".
wait until (brakes).
print "executing capture burn".
brakes off.
MNVLIB_ExecuteMnvNode(true).
wait 5.

// wait for deorbit burn
print "waiting for deorbit burn".
wait until (brakes).
print "executing deorbit burn".
brakes off.
MNVLIB_ExecuteMnvNode(true).
wait 5.
stage.
wait 1.
stage.
wait 5.

// landing
doSuicideBurn().

// take off to a 20km orbit
print "Waiting for take-off comand".
wait until (brakes).
brakes off.
lock steering to heading(90,80).
wait 1.
lock throttle to 1.
wait until (apoapsis > 10000).
gear off.
lock steering to heading(90,15).
wait until (apoapsis > 20000).
lock throttle to 0.

lock steering to heading(90,0).
set mnvTime to MNVLIB_ManeuverTimePrecise(MNVLIB_DeltaVCircularization()).
wait until (eta:apoapsis < mnvTime/2).
set start_mnv to time:seconds.
until (time:seconds > start_mnv + mnvTime)
{
  lock throttle to 1.
  if (CheckFlameout())
  {
    stage.
  }
  wait 0.1.
}
lock throttle to 0.

// wait for 1st return burn
print "waiting for 1st return burn".
wait until (brakes).
print "executing 1st return burn".
brakes off.
MNVLIB_ExecuteMnvNode(true).

wait 10.

// wait for 2nd return burn
print "waiting for 2nd return burn".
wait until (brakes).
print "executing 2nd return burn".
brakes off.
MNVLIB_ExecuteMnvNode(true).

// align for max sun exposure
lock steering to sun:position.
wait 5.

// wait until close to kerbin atmo
wait until (altitude < 100000).
set warp to 0.
print "align for reentry".
lock steering to srfretrograde.
print "retracting solar panels".
ag1 on.
wait 5.

// detach engine
print "detach engine".
stage.
wait 5.

// arm parachutes
print "arm parachute".
//wait until (alt:radar < 3000).
stage.


wait until (alt:radar < 100).
unlock steering.
for mod in ship:modulesnamed("ModuleDecouple") {
    if mod:hasevent("jettison heat shield") {
        mod:doevent("jettison heat shield").
    }.
}.

// wait until landed
wait until (alt:radar < 20).
wait 30.
