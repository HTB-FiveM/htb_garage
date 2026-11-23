eTraceFlags = {
    None             = 0,
    IntersectWorld   = 1,     -- 1 << 0
    IntersectVehicles= 2,     -- 1 << 1
    IntersectPeds    = 4,     -- 1 << 2
    IntersectRagdolls= 8,     -- 1 << 3
    IntersectObjects = 16,    -- 1 << 4
    IntersectPickup  = 32,    -- 1 << 5
    IntersectGlass   = 64,    -- 1 << 6
    IntersectRiver   = 128,   -- 1 << 7
    IntersectFoliage = 256,   -- 1 << 8
  
    -- sum of all bits above
    IntersectEverything = 511 -- (1+2+4+8+16+32+64+128+256)
  }
  
  -- Trace-option flags
  eTraceOptionFlags = {
    None                = 0,
    OptionIgnoreGlass   = 1,  -- 1 << 0
    OptionIgnoreSeeThrough = 2,-- 1 << 1
    OptionIgnoreNoCollision = 4,-- 1 << 2
  
    -- combine all options
    OptionDefault       = 7   -- (1+2+4)
  }
