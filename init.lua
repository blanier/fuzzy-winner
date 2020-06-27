F = require 'pl.tablex'
D = require 'pl.pretty'
geometry = require("hs.geometry")

-- clean up console output for ui-less apps
hs.window.filter.ignoreAlways['Atom Helper'] = true
hs.window.filter.ignoreAlways['Notes Networking'] = true
hs.window.filter.ignoreAlways['Mail Networking'] = true
hs.window.filter.ignoreAlways['Slack Helper (Renderer)'] = true
hs.window.filter.ignoreAlways['Spotlight'] = true
hs.application.enableSpotlightForNameSearches(true)

-- Handle various webex annoyances

-- remove the tabs left in google by WebEx
function webexTabDestroyer()
  local browsers = {hs.window.find("Google Chrome")}
  local tab_path = {"Tab", "Apple Inc. WebEx Enterprise Site"}
  local close_path = {"File", "Close Tab"}

  -- grab current focused window
  local w = hs.window.focusedWindow()

  F.foreach(browsers, function(b)
    b:focus()

    while (b:application():findMenuItem(tab_path)) do
      b:application():selectMenuItem(tab_path)
      b:application():selectMenuItem(close_path)
    end
  end)

  -- restore previous focus
  if (w) then w:focus() end
end

-- bind that to a hotkey
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "T", webexTabDestroyer)

-- and try to do it whenever a new webex window is created
webexWindowFilter = hs.window.filter.new(false):setAppFilter("Cisco Webex Meetings", {allowRoles="AXStandardWindow"})
webexWindowFilter:subscribe(hs.window.filter.windowCreated, function(w)
  webexTabDestroyer()
  w:move(geometry.rect(0.28,0.2, 0.60, 0.60), left())
end)

-- auto-click the annoying "Are You Sure"
webexDialogFilter = hs.window.filter.new(false):setAppFilter("Cisco Webex Meetings", {allowRoles="AXDialog",
                                                                                      allowTitles={"End Meeting","Leave Meeting"}})
webexDialogFilter:subscribe(hs.window.filter.windowCreated, function(w)
  -- DISGUSTING: webex has to be killed twice, once for the "helper" and once for the actual window
  w:application():kill9()
  w:application():kill9()
end)


-- Settup Screen for basic layout
  -- this is _really_ specific to my personal screen layout
function right()
  return hs.screen.allScreens()[1]
end

function middle()
  return hs.screen.allScreens()[2]
end

function left()
  return hs.screen.allScreens()[3]
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "1", function()
  local windowLayout = {
          -- MBP Main Screen
          {"Sonos S1 Controller",  nil, right,  geometry.rect(0.00,0.0, 0.50, 0.75), nil, nil },

          -- Far Left Big Screen
              -- Note the order is important as it establishes stacking order and these regions overlap
          {"Notes",                nil, left,   geometry.rect(0.28,0.1, 0.60, 0.80), nil, nil},
          {"Calendar",             nil, left,   geometry.rect(0,   0.0, 0.40, 0.50), nil, nil},
          {"Messages",             nil, left,   geometry.rect(0,   0.5, 0.40, 0.50), nil, nil},
          {"Slack",                nil, left,   geometry.rect(0.50,0.3, 0.50, 0.70), nil, nil},
          {"Mail",                 nil, left,   geometry.rect(0.55,0.0, 0.45, 0.75), nil, nil},

          -- Center Screen
              -- Currently a non-overlapping layout
          {"Google Chrome",        nil, middle, geometry.rect(0.50,0.0, 0.50, 1.00), nil, nil},
          {"Atom",                 nil, middle, geometry.rect(0,   0.0, 0.50, 0.70), nil, nil},
          {"Terminal",             nil, middle, geometry.rect(0,   0.7, 0.50, 0.30), nil, nil},
      }

      -- make sure everyone is open
      F.foreach (windowLayout, function(v) hs.application.open(v[1], 5, true) end )

      -- and position them
      hs.layout.apply(windowLayout)

end)

-- custom Console toolbar (adds Clear button)
local toolbar = require("hs.webview.toolbar")
local console = require("hs.console")
local image = require("hs.image")
console.defaultToolbar = toolbar.new("CustomToolbar", {
    { id="prefs", label="Preferences", image=image.imageFromName("NSPreferencesGeneral"), tooltip="Open Preferences", fn=function() hs.openPreferences() end },
    { id = "NSToolbarSpaceItem" },
    { id="reload", label="Reload config", image=image.imageFromName("NSSynchronize"), tooltip="Reload configuration", fn=function() hs.reload() end },
    { id="openCfg", label="Open config", image=image.imageFromName("NSActionTemplate"), tooltip="Edit configuration", fn=function() openConfig() end },
    { id="clearLog", label="Clear Console", image = hs.image.imageFromName("NSTrashEmpty"), tooltip="Clear Console", fn=function() console.clearConsole() end },
    { id = "NSToolbarFlexibleSpaceItem" },
    { id="help", label="Help", image=image.imageFromName("NSInfo"), tooltip="Open API docs browser", fn=function() hs.doc.hsdocs.help() end }
  }):canCustomize(true):autosaves(true)
console.toolbar(console.defaultToolbar)

-- Handle reloading the config w/o user intervention
function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end

-- move the current window into my "work window" spot
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  local win = hs.window.focusedWindow()
  win:move(geometry.rect(0.15,0.2, 0.60, 0.60), left())
end)

-- automaticaly reload the config when it changes
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.notify.new({title="Hammerspoon", informativeText="Config Reloaded"}):send()
