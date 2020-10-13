{
  "assets": [
    "base",
    "scene/solarsystem/missions/insight/edl",
    "scene/solarsystem/missions/perseverance/perseverance"
  ],
  "camera": {
    "anchor": "Mars",
    "latitude": 58.5877,
    "longitude": 16.1924,
    "type": "goToGeo"
  },
  "keybindings": [
    {
      "documentation": "Set and goto Insight Landing",
      "gui_path": "/Missions/Insight",
      "is_local": false,
      "key": "I",
      "name": "Setup scene for insight EDL",
      "script": "openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.Mola_Utah.Settings.Offset', -469.300000);openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.OnMarsHiRISELS.Settings.Offset', -470.800006);openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.OnMarsHiRISELS.Enabled', true);openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.ColorLayers.OnMarsHiRISELS.Enabled', true);openspace.time.setPause(true);openspace.time.setTime('2018 NOV 26 19:39:03.68');openspace.navigation.setNavigationState({Anchor = 'Insight',Pitch = 0.567457E-4,Position = { 1.240506E1,-1.369270E1,-2.423553E0 },ReferenceFrame = 'Root',Up = { 0.441211E0,0.247019E0,0.862737E0 },Yaw = -0.446853E-4});"
    },
    {
      "documentation": "Disable Mars layer settings used for insight EDL",
      "gui_path": "/Missions/Insight",
      "is_local": false,
      "key": "SHIFT+I",
      "name": "Unset Insight Landing",
      "script": "openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.Mola_Utah.Settings.Offset', 0);openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.OnMarsHiRISELS.Settings.Offset', 0);openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.OnMarsHiRISELS.Enabled', false);openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.ColorLayers.OnMarsHiRISELS.Enabled', false);"
    },
    {
      "documentation": "Sets time and layers for Perseverance landing",
      "gui_path": "/Missions/Perseverance",
      "is_local": false,
      "key": "P",
      "name": "Setup and Goto Perseverance",
      "script": "openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.Mola_Utah.Settings.Offset', -1677.088867);openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.OnMarsHiRISELS.Settings.Offset', -1677.088867);openspace.time.setPause(true);openspace.time.setTime('2021 FEB 18 20:32:16');openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.HeightLayers.OnMarsHiRISELS.Enabled', true);openspace.setPropertyValueSingle('Scene.Mars.Renderable.Layers.ColorLayers.OnMarsHiRISELS.Enabled', true);openspace.navigation.setNavigationState({Anchor = 'Perseverance',Pitch = 0.567457E-4,Position = { 1.240506E1,-1.369270E1,-2.423553E0 },ReferenceFrame = 'Root',Up = { 0.441211E0,0.247019E0,0.862737E0 },Yaw = -0.446853E-4});"
    }
  ],
  "mark_nodes": [
    "Mars",
    "Insight",
    "Perseverance"
  ],
  "meta": {
    "author": "OpenSpace Team",
    "description": "This profile shows the landing of the NASA InSight lander on Mars. The final minutes of the approach are shown with the lander finishing on the surface of Mars.  This profile also includes the landing trail and model for the Mars2020 rover Perseverence. ",
    "license": "MIT License",
    "name": "Mars",
    "url": "https://www.openspaceproject.com",
    "version": "1.0"
  },
  "time": {
    "type": "relative",
    "value": "-1d"
  },
  "version": {
    "major": 1,
    "minor": 0
  }
}