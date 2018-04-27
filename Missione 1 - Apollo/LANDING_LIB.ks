// LANDING LIBRARY

function BodyGravity {
	return body:mu/(altitude + body:radius)^2. //1.63.
}.

function AltitudeToBurn
{
  local m is ship:mass.
  local surfSpeed is ship:velocity:surface:mag. //ship:verticalspeed.
  local g is BodyGravity.
  local accel is ship:maxthrust/m - g.

	//print "m" + m + "  srfspeed" + surfSpeed + "  g " + g + "  accel" + accel + "  srfsp^2" + (surfSpeed^2).

  return abs((surfSpeed^2)/(2*accel)).
}

function doSuicideBurn
{

  // set ship to known state
  clearscreen.
  brakes off.
  rcs on.
  sas off.

  // set algorithm parameters
  set landingSpeed to -2.
  set runmode to 1.
  set isLanded to 0.
  set counter to 0.

  // set ship parameters
  set g to BodyGravity.
  lock shipAltitude to alt:radar.
  lock speed to ship:verticalspeed.
  lock speedErr to (landingSpeed - speed).
  lock hoverThrottle to ((ship:mass*g)/ship:maxthrust).
  set TVAL to 0.
  lock throttle to TVAL.

  // Main loop
  until (runmode = 0)
  {
    // initial setup
  	if runmode = 1
    {
  		set TVAL to 0.
  		lock steering to retrograde.
  		if (altitude < 50000 and ship:body:atm:exists)
  		{
  			lock steering to srfretrograde.
  			brakes on.
  		}
  		if shipAltitude < AltitudeToBurn() + 100
  		{
  			// brakes off.
  			set runmode to 2.
  		}
  	}

  	// start suicide burn
  	if runmode = 2
    {
  		if (shipAltitude < AltitudeToBurn() - speed)
      {
  			lock steering to srfretrograde.
				set TVAL to 1.
  		}
  		else
  		{
  			lock steering to srfretrograde.
				set TVAL to 0.
  		}
  		if shipAltitude/abs(speed) < 5
      {
  			gear on.
  		}

  		if (speed > -5 and alt:radar < 200)
      {
  			lock steering to up.
  			set runmode to 3.
  		}
  	}

  	// landing
  	if runmode = 3
    {
  		if speedErr > 0
      {
  			set TVAL to (hoverThrottle + 0.1).
  		}
  		if speedErr < 0
      {
  			set TVAL to (hoverThrottle - 0.1).
  		}
  		if ship:status = "LANDED" //abs(speed) < 0.1 and shipAltitude < 20
      {
  			set counter to counter + 1.
  			wait 0.1.
  		}
  		if counter > 10
      {
  			set runmode to 0.
  		}
  	}

  	// instructions for all runmodes
  	// lock throttle to TVAL.

  	// display data
  	print "Vertical speed: " + round(speed, 2) at (5,4).
  	print "Burn altitude: " + round(AltitudeToBurn(), 2) at (5,5).
  	print "Run mode: " + runmode at (5,6).
  	print "Time to burn: " + round((AltitudeToBurn() - alt:radar)/speed, 2) at (5,7).

  	// loop wait
  	wait 0.01.
  }

  // program end
  set TVAL to 0.
  rcs off.
  unlock throttle.
  brakes off.
  print "Landed".
  wait 5.
}
