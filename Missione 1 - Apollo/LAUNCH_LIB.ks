// LAUNCH LIBRARY

function tilt
{
  parameter minAlt.
  parameter angle.

  until (altitude > minAlt)
  {
    // check if some engine is out of fuel and stage
    if (CheckFlameout())
    {
      local prevThrottle is throttle.
      lock throttle to 0.
      wait 1.
      stage.
      wait 1.
      lock throttle to prevThrottle.
    }
  }
  lock steering to heading(90,angle) + R(0,0,-90).
}

function CheckFlameout
{
  list engines in enginesList.
  for eng in enginesList
  {
    if (eng:flameout)
    {
      return 1.
    }
  }
  return 0.
}
