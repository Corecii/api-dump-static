# API Dump (Static)

A library that provides static Roblox API dumps.

API dumps are updated when Roblox updates and you pull a new version of the package.

[Documentation](https://corecii.github.io/api-dump-static/)

Install with [wally](https://wally.run):
```toml
# wally.toml
[dependencies]
ApiDumpStatic = "corecii/api-dump-static@^1.0"
```

[or use a packaged release model](https://github.com/Corecii/api-dump-static/releases/latest)

When using Wally, `wally install` will automatically grab the newest version by default.
This is because we only update the *patch* version for API dump changes, and by default
wally grabs the newest version that isn't a breaking change.

---

The primary advantages that this package provides over including the raw API dump in your project are:
* the dump is pre-processed into multiple files so that it syncs in with Rojo correctly
* the dump is automatically generated when Roblox updates
* methods to get all members of a class are provided, where the raw API dump requires you to get the superclass members yourself

---

This package allows you to inspect instances at runtime without having to download the API dump with HttpService.

For example:
```lua
local ApiDump = require(game.ReplicatedStorage.Packages.ApiDumpStatic)

local thing = workspace.Baseplate

local thingApi = ApiDump.Classes[thing.ClassName]

for name, info in pairs(thingApi:Properties()) do
    if info.Security == "None" or info.Security.Read == "None" and not table.find(info.Tags or {}, "NotScriptable") then
      print("Property", name, "of", thing:GetFullName(),"=", thing[name])
    end
end
```

The API is fairly light. It's just a wrapper around [Roblox-Client-Tracker/API-Dump.json](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/API-Dump.json) with nice methods for getting *all* members of a class (incl. of superclasses) and caching generated members lists. As such, it follows naming conventions of *Mini-API-Dump.json* for external access (i.e. UpperCamelCase / PascalCase for everything).

The raw API dump can be accessed using `ApiDump.Raw`. This is equivalent to loading [Roblox-Client-Tracker/API-Dump.json](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/API-Dump.json) directly.