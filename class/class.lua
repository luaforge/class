
--[[
  Class library for lua 5.0 (& 5.1)

  o  one metatable for all objects
  o  one special attribute `__info' holding all object's information
  o  Object and Class are two predefined classes
  o  no multiple inheritance support (currently)
  o  lua5.0 meta-methods support for objects
  o  call super() function to access superclass method
--]]


-- TODO: write complete tests (5.0 & 5.1)
-- TODO: add class-methods
-- TODO: simplify super() mechanism
-- TODO: add __r***__ meta-methods
-- TODO: add finalize() method support
-- TODO: revise methods set for Class and Object
-- TODO: add lua 5.1 meta-methods support (# ?)
-- ?: who need trailing '__' in meta-methods' name?



---- HELPER FUNCTIONS ----

function wrongarg(n,expected,got)
  return 'arg '..n..' expected to be '..expected..' (got '..tostring(got)..')'
end

function isname(name)
  return type(name)=='string' and string.find(name,'^[_%a][_%w]*$')
end

function default(what,value)
  if value==nil then
    return what
  end
  return value
end

function fassert(value,errmsg,...)
  if value then
    return value
  else
    if type(errmsg)=='nil' then
      error('assertion failed!',2)
    elseif type(errmsg)=='string' then
      error(errmsg,2)
    else
      --trying to call second arg
      error(errmsg(unpack(arg)),2)
    end
  end
end

function fwrongarg(...)
  return function()
    return wrongarg(unpack(arg))
  end
end



----
local INFO = '__info'
----



---- METATABLE ----

local METAMETHODS = {
  '__tostring',
  '__add',
  '__sub',
  '__mul',
  '__div',
  '__pow',
  '__lt',
  '__le',
  '__eq',
  '__call',
  '__unm',
  '__concat',
  '__newindex',
}


local metatable = {}

-- FIXME: Add to error message all lookup results

for _, name in ipairs(METAMETHODS) do
  local name = name
  metatable[name] = function(...)
    local name = name..'__'
    local a, b = unpack(arg)
    local f
    if isobject(a) then
      f = a[name]
    end
    if not f and isobject(b) then
      f = b[name]
    end
    fassert(f, function()
                 local class = rawget(a,INFO).__class
                 local cname = rawget(class,INFO).__name
                 return 'meta-method not found: '..cname..':'..name
               end)
    return f(unpack(arg))
  end
end




---- PRIMITIVES ----

local
function table2object(t)
  fassert(type(t)=='table', fwrongarg(1,'table',t))
  rawset(t,INFO,{})
  setmetatable(t,metatable)
  return t
end

function isobject(o)
  return type(o)=='table' and rawget(o,INFO)
end

local
function object2table(o)
  fassert(isobject(o), fwrongarg(1,'object',o))
  setmetatable(o,nil)
  rawset(o,INFO,nil)
  return o
end

local
function givename(o,name)
  fassert(isobject(o), fwrongarg(1,'object',o))
  fassert(isname(name), fwrongarg(2,'name',name))
  rawget(o,INFO).__name = name
  getfenv(2)[name] = o
end

local
function setclass(o,class)
  fassert(isobject(o), fwrongarg(1,'object',o))
  fassert(isobject(class), fwrongarg(2,'object',class))
  rawget(o,INFO).__class = class
end

local
function setsuper(class,superclass)
  fassert(isobject(class), fwrongarg(1,'object',class))
  fassert(isobject(superclass), fwrongarg(2,'object',superclass))
  rawget(class,INFO).__super = superclass
end

local
function object2class(o,name)
  fassert(isobject(o), fwrongarg(1,'object',o))
  fassert(isname(name), fwrongarg(2,'name',name))
  givename(o,name)
  rawget(o,INFO).__methods = {}
end

-------------------
local
function findmethod(class,name)
  while class do
    local info = rawget(class,INFO)
    value = info.__methods[name]
    if value then
      return value
    end
    class = info.__super
  end
end


function metatable:__index(name)
  local value
  ----
  -- instance method lookup
  local class = rawget(self,INFO).__class
  value = findmethod(class,name)
  if value then
    return value
  end
  ----
  -- custom lookup
  if name ~= '__index__' then
    local index = self.__index__  -- recursion
    if index then
      value = {index(self,name)}
      if value[1] then
        return unpack(value)
      end
    end
  end
end
-------------------





---- OBJECT CLASS ----

local _Object = table2object{}
object2class(_Object,"Object")



---- CLASS CLASS ----

local _Class = table2object{}
object2class(_Class,"Class")



---- SETUP ----

setclass(Object,Class)
setclass(Class,Class)
setsuper(Class,Object)



---- INSTANCE METHODS REGISTRATION ----

local
function makesupermethod(self,name)
  return function(...)
    local method
    local class = rawget(self,INFO).__class
    local classinfo = rawget(class,INFO)
    local super = classinfo.__super
    if super then
      method = findmethod(super,name)
    end
    assert(method, "no super method for "..classinfo.__name..":"..name)
    return method(self,unpack(arg))
  end
end

local methodsmeta = {}

function methodsmeta:__call(object,...)
  local env = getfenv(self.__f)
  local metafenv = {
    __newindex = env,
    __index = env,
  }
  local fenv = {
    super = makesupermethod(object,self.__name),
  }
  setmetatable(fenv,metafenv)
  setfenv(self.__f,fenv)
  local result = {self.__f(object,unpack(arg))}
  setfenv(self.__f,env)
  return unpack(result)
end

----
rawget(Class,INFO).__methods.__newindex__ =
  function(self,name,method)
    ----
    --rawget(self,INFO).__methods[name] = method
    ----
    local t = {
      __name = name,
      __f = method,
    }
    setmetatable(t,methodsmeta)
    rawget(self,INFO).__methods[name] = t
  end
----



---- OBJECT METHODS ----

function Object:new()      -- FIXME: Object.CLASS:new()
  return table2object{}
end

function Object:initialize()
end

function Object:class()
  return rawget(self,INFO).__class
end

function Object:__eq__(other)
  return rawequal(self,other)
end

function Object:__newindex__(name,value)
  rawset(self,name,value)
end

function Object:instanceof(class)
  --assert?
  return self:class() == class
end

function Object:inherits(class)
  --assert?
  local _class = self:class()
  return _class == class or _class:derives(class)
end

--[[
function Object:isclass()
  return self:inherits(Class)
end
--]]

function Object:__tostring__()
  return 'instance of '..self:class():name()
end

--[[
function Object:variables(retset)
  local vars = {}
  for name in pairs(self) do
    vars[name] = true
  end
  vars[INFO] = nil
  if retset then
    return vars
  end
  local t = {}
  for name in pairs(vars) do
    table.insert(t,name)
  end
  return t
end
--]]

--[[
function Object:methods(listinherited)
  listinherited = default(true,listinherited)
  if self:isclass() then
    local vset = self:variables(true)
    if listinherited then
      for name in ? do
      end
      ....
    end
    ?
    ....
  else
    return self:class():methods()
  end
end
--]]

--Object:totable()  -> table, info
--Object:__***__
--Object:address()  --?



function Class:__call__(...)
  local instance = self:new(unpack(arg))  --FIXME: self.CLASS:new() !!!
  setclass(instance,self)
  instance:initialize(unpack(arg))
  return instance
end

function Class:initialize(name,superclass)
  fassert(isname(name), fwrongarg(1,'name',name))
  object2class(self,name)
  superclass = superclass or Object
  fassert(isobject(superclass), fwrongarg(2,'object',superclass))
  setsuper(self,superclass or Object)
end

function Class:name()
  return rawget(self,INFO).__name
end

function Class:super()
  return rawget(self,INFO).__super
end

function Class:__tostring__()
  return self:name()
end

function Class:derives(class)
  local superclass = self:super()
  if superclass then
    return superclass == class or superclass:derives(class)
  end
end

--function Class:findmethod(name)

--[[
function Class:definition()
  local s = 'class "'..self:name()..'"'
  local super = self:super()
  if super and super ~= Object then
    s = s..' ('..super:name()..')'
  end
  s = s..' do\n'
  for name, _ in pairs(self) do
    ....
  end
  ....
  return 'class "'....'"'..super_s..' do\n'..
    ..?..
    'end'
end
--]]

--Class:adopt(t,initialize)



-- weak class list ?



function class(name)
  fassert(isname(name), fwrongarg(1,'name',name))
  local _class = Class(name)
  return function(superclass)
    fassert(isobject(superclass), fwrongarg(1,'object',superclass))
    setsuper(_class,superclass)
  end
end