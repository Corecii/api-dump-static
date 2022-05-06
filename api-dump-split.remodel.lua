local apiDump = json.fromString(remodel.readFile("api-dump-split.remodel.json"))

local classes = {}
local enums = {}
local other = {}

print("#Classes: " .. #apiDump.Classes)
print("#Enums: " .. #apiDump.Enums)

local function split(arr, per)
	local new = { {} }

	for index, item in ipairs(arr) do
		table.insert(new[#new], item)

		if #json.toString(new[#new]) > 100000 then
			table.remove(new[#new])
			table.insert(new, {})
			table.insert(new[#new], item)
		end
	end

	return new
end

classes = split(apiDump.Classes, 50)
enums = split(apiDump.Enums, 50)

apiDump.Classes = nil
apiDump.Enums = nil
other = apiDump

remodel.createDirAll("src/lib/generated")

for _, file in ipairs(remodel.readDir("src/lib/generated")) do
	-- selene: allow(incorrect_standard_library_use)
	os.remove("src/lib/generated/" .. file)
end

for index, list in ipairs(classes) do
	remodel.writeFile("src/lib/generated/classes-" .. index .. ".json", json.toString({ Classes = list }))
end

for index, list in ipairs(enums) do
	remodel.writeFile("src/lib/generated/enums-" .. index .. ".json", json.toString({ Enums = list }))
end

remodel.writeFile("src/lib/generated/other.json", json.toString(other))
