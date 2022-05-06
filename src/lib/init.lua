--!strict
local ApiDumpRaw = require(script.ApiDumpRaw)

local ApiDump = {}

local classes: { [string]: Class } = {}
local processedSubclasses = false

--[=[
	@class Class

	Represents the API dump for a class / instance type.
]=]

local Class = {}
Class.__index = Class

export type Property = ApiDumpRaw.Property
export type Method = ApiDumpRaw.Method
export type Event = ApiDumpRaw.Event
export type Callback = ApiDumpRaw.Callback
export type Member = ApiDumpRaw.Member

type Class = typeof(setmetatable(
	{} :: {
		Name: string,
		SuperName: string,
		Tags: { string },
		MemoryCategory: string,
		_combined: {
			properties: { [string]: Property }?,
			methods: { [string]: Method }?,
			events: { [string]: Event }?,
			callbacks: { [string]: Callback }?,
			members: { [string]: Member }?,
		},
		_my: {
			properties: { [string]: Property },
			methods: { [string]: Method },
			events: { [string]: Event },
			callbacks: { [string]: Callback },
			members: { [string]: Member },
		},
		-- Other internal nilable properties are stored under _other so that we
		-- can freeze the class objects.
		_other: {
			tagsSet: { [string]: boolean }?,
			subclasses: { [string]: Class }?,
			defaultInstance: Instance?,
			defaultProperties: { [string]: any }?,
		},
	},
	Class
))

function Class.new(definition: ApiDumpRaw.RawClass): Class
	local self = {}
	setmetatable(self, Class)

	local properties = {}
	local methods = {}
	local events = {}
	local callbacks = {}
	local members = {}

	for _, member in ipairs(definition.Members) do
		if member.MemberType == "Property" then
			properties[member.Name] = member
		elseif member.MemberType == "Function" then
			methods[member.Name] = member
		elseif member.MemberType == "Event" then
			events[member.Name] = member
		elseif member.MemberType == "Callback" then
			callbacks[member.Name] = member
		end

		members[member.Name] = member
	end

	-- We cannot assert all of the required fields for _combined and _my, so we
	-- must cast them to any.

	self._combined = {} :: any

	self._my = {
		properties = properties,
		methods = methods,
		events = events,
		callbacks = callbacks,
		members = members,
	} :: any

	self._other = {}

	self.Name = definition.Name
	self.SuperName = definition.Superclass
	self.Tags = definition.Tags or table.freeze({})
	self.MemoryCategory = definition.MemoryCategory

	table.freeze(self)
	table.freeze(self._my)

	return self
end

function Class._getCombined(
	self: Class,
	target: "properties" | "methods" | "events" | "callbacks" | "members"
): { [string]: Member }
	if not self._combined[target] then
		local combined = {}
		local super = self:Superclass()
		if super then
			for key, value in pairs(super:_getCombined(target)) do
				combined[key] = value
			end
		end

		for key, value in pairs(self._my[target]) do
			combined[key] = value
		end

		table.freeze(combined)

		self._combined[target] = combined
	end

	return self._combined[target]
end

-- We must cast the returns of these to any since the Luau typechecker is
-- incapable of knowing that GetCombined returns the wanted type instead of
-- Member.

--[=[
	Returns the properties this class has, includes those of its superclasses

	@method Properties
	@within Class
	@return { [string]: Property }
]=]
function Class.Properties(self: Class): { [string]: Property }
	return self:_getCombined("properties") :: any
end

--[=[
	Returns the methods this class has, includes those of its superclasses

	@method Methods
	@within Class
	@return { [string]: Method }
]=]
function Class.Methods(self: Class): { [string]: Method }
	return self:_getCombined("methods") :: any
end

--[=[
	Returns the events this class has, includes those of its superclasses

	@method Events
	@within Class
	@return { [string]: Event }
]=]
function Class.Events(self: Class): { [string]: Event }
	return self:_getCombined("events") :: any
end

--[=[
	Returns the callbacks this class has, includes those of its superclasses

	@method Callbacks
	@within Class
	@return { [string]: Callback }
]=]
function Class.Callbacks(self: Class): { [string]: Callback }
	return self:_getCombined("callbacks") :: any
end

--[=[
	Returns all members this class has, includes those of its superclasses

	@method Members
	@within Class
	@return { [string]: Member }
]=]
function Class.Members(self: Class): { [string]: Member }
	return self:_getCombined("members") :: any
end

--[=[
	Returns whether this class has a particular tag

	@method HasTag
	@within Class
	@param tag string
	@return boolean
]=]
function Class.HasTag(self: Class, tag: string): boolean
	if not self._other.tagsSet then
		local set = {}
		for _, tagInner in ipairs(self.Tags) do
			set[tagInner] = true
		end
		self._other.tagsSet = set
	end
	assert(self._other.tagsSet, "always") -- typechecker assert

	return self._other.tagsSet[tag] or false
end

--[=[
	Returns the superclass of this class

	@method Superclass
	@within Class
	@return Class?
]=]
function Class.Superclass(self: Class): Class?
	return classes[self.SuperName]
end

--[=[
	Returns a dictionary of this class's subclasses.

	@method Subclasses
	@within Class
	@return { [string]: Class }
]=]
function Class.Subclasses(self: Class): { [string]: Class }
	if not processedSubclasses then
		for className, class in pairs(classes) do
			local super = class:Superclass()
			if super then
				if not super._other.subclasses then
					super._other.subclasses = {}
				end
				assert(super._other.subclasses, "always") -- typechecker assert

				super._other.subclasses[className] = class
			end
		end
		for _className, class in pairs(classes) do
			if class._other.subclasses == nil then
				class._other.subclasses = {}
			end

			table.freeze(class._other.subclasses :: any)
		end

		processedSubclasses = true
	end

	return self._other.subclasses or {}
end

--[=[
	Returns the default value for one of this class's properties.

	@method GetPropertyDefault
	@within Class
	@param property string
	@return any
]=]
function Class.GetPropertyDefault(self: Class, property: string): any
	assert(self:Properties()[property] ~= nil, "Class " .. self.Name .. " does not have " .. tostring(property))

	if not self._other.defaultInstance then
		if self:HasTag("NotCreatable") then
			return
		end

		-- Instance.new must be cast to support creation from unknown
		-- strings
		self._other.defaultInstance = (Instance.new :: any)(self.Name)
	end
	assert(self._other.defaultInstance, "always") -- typechecker assert

	if not self._other.defaultProperties then
		self._other.defaultProperties = {}
	end
	assert(self._other.defaultProperties, "always") -- typechecker assert

	if self._other.defaultProperties[property] == nil then
		-- must be cast to support string indexing
		self._other.defaultProperties[property] = (self._other.defaultInstance :: any)[property]
	end

	return self._other.defaultProperties[property]
end

table.freeze(Class)

for _, definition in ipairs(ApiDumpRaw.Classes) do
	classes[definition.Name] = Class.new(definition)
end

table.freeze(classes)

--[=[
	@class ApiDump
	A static API dump
]=]

--[=[
	@prop Classes { [string]: Class }
	@within ApiDump
	The dictionary of classes
]=]
ApiDump.Classes = classes

--[=[
	@prop Raw ApiDumpRaw
	@within ApiDump
	The raw API dump
]=]
ApiDump.Raw = ApiDumpRaw

--[=[
	@prop RobloxVersion string
	@within ApiDump
	The version of Roblox this API dump is for
]=]
ApiDump.RobloxVersion = script.robloxVersion.Value

--[=[
	@prop PackageVersion string
	@within ApiDump
	The version of the package
]=]
ApiDump.PackageVersion = script.packageVersion.Value

table.freeze(ApiDump)

return ApiDump
