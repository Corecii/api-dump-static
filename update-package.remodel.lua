local function capture(cmd)
	local pipe = assert(io.popen(cmd, "r"))
	local result = assert(pipe:read("*a"))
	pipe:close()
	return result
end

local function run(cmd)
	return assert(os.execute(cmd), "Command failed: " .. cmd)
end

local function read(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

local diff = capture("git diff --numstat roblox-version.txt")

if #diff == 0 then
	print("Roblox version has not changed; not releasing new package version.")
	local marker_file = assert(io.open("no-changes", "w"))
	marker_file:close()
	return
end

if (...) == "check" then
	return
end

local roblox_version_full = assert(read("roblox-version.txt"))
local roblox_version_single = assert(roblox_version_full:match("^%d+%.%d+%.%d+%.(%d+)$"))

local wally_toml = assert(read("wally.toml"))
local wally_version = assert(wally_toml:match('version = "(%d+%.%d+%.%d+)"'))
local wally_version_no_patch = assert(wally_version:match("^(%d+%.%d+)"))

local new_version = ("%s.%s"):format(wally_version_no_patch, roblox_version_single)

local wally_file = assert(io.open("wally.toml", "w"))
wally_file:write((wally_toml:gsub('version = "(%d+%.%d+%.%d+)"', 'version = "' .. new_version .. '"')))
wally_file:close()

os.rename("package-version.txt", "previous-package-version.txt")

local marker_file = assert(io.open("package-version.txt", "w"))
marker_file:write(new_version)
marker_file:close()
