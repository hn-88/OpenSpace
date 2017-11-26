return {
    -- Barycenter module
    {
        Name = "NeptuneBarycenter",
        Parent = "SolarSystemBarycenter",
        Transform = {
            Translation = {
                Type = "SpiceTranslation",
                Target = "NEPTUNE BARYCENTER",
                Observer = "SUN",
                Kernels = "${OPENSPACE_DATA}/spice/de430_1850-2150.bsp"
            }
        },
        GuiPath = "/Solar System/Planets/Neptune"
    },
    -- RenderableGlobe module
    {   
        Name = "Neptune",
        Parent = "NeptuneBarycenter",
        Transform = {
            Rotation = {
                Type = "SpiceRotation",
                SourceFrame = "IAU_NEPTUNE",
                DestinationFrame = "GALACTIC"
            }
        },
        Renderable = {
            Type = "RenderableGlobe",
            Radii = { 24764000, 24764000, 24314000 },
            SegmentsPerPatch = 64,
            Layers = {
                ColorLayers = {
                    {
                        Name = "Texture",
                        FilePath = "textures/neptune.jpg",
                        Enabled = true
                    }
                }
            }
        },
        Tag = { "planet_solarSystem", "planet_giants" },
        GuiPath = "/Solar System/Planets/Neptune"

    },
    -- Trail module
    {   
        Name = "NeptuneTrail",
        Parent = "SolarSystemBarycenter",
        Renderable = {
            Type = "RenderableTrailOrbit",
            Translation = {
                Type = "SpiceTranslation",
                Target = "NEPTUNE BARYCENTER",
                Observer = "SUN"
            },
            Color = {0.2, 0.5, 1.0 },
            -- Period  = 60200,
            -- Yes, this period is wrong, but the SPICE kernel we load by default only
            -- goes back to 1850.  Neptunes orbit is 164 years, which would mean that we
            -- exceed the SPICE kernel if we go back before 2014, if we try to compute the
            -- entire orbit.  Cutting the orbit length to 100 years allows us to go back
            -- to 1950 instead, which is good enough.
            -- If the positions are needed before that, a different set of kernels are
            -- needed, namely:
            -- https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de431_part-1.bsp
            -- https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de431_part-2.bsp
            -- that cover a larger time span:  -13201-MAY-06 00:00 to  17191-MAR-15 00:00
            Period  = 36500,
            Resolution = 1000
        },
        Tag = { "planetTrail_solarSystem", "planetTrail_giants" },
        GuiPath = "/Solar System/Planets/Neptune"
    }
}
