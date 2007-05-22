
--[[
  Collection of tests for Lua class library
--]]


require('luaunit')
require('class')



---- BASIC TESTS ----

TestBasic = {}

--[[
function TestBasic:test_?()
  ....
end
--]]

function TestBasic:test_class_created()
  class "A"
  assert(A, "NOT A")
  A = nil
end

function TestBasic:test_class_not_created()
  assertError(class)
  assertError(class,"")
  assertError(class," ")
  assertError(class,"10")
  assertError(class,"hello world")
  assertError(class,"@$*&@^")
  assertError(class,{})
  assertError(class,10)
  assertError(class,function()end)
  assertError(class,true)
  assertError(class,false)
  assertError(class,Class)
end

function TestBasic:test_instance_created()
  class "A"
  local a = A()
  assert(a, "NOT a")
  A = nil
end

function TestBasic:test_method_called()
  class "A" do
    function A:f(x)
      return self, x
    end
  end
  local x = {}
  local a = A()
  local _self, _x = a:f(x)
  assert(a==_self, "a ~= _self")
  assert(x==_x, "x ~= _x")
  A = nil
end

function TestBasic:test_method_not_found()
  class "A"
  assertError(function() A:f() end)
end

function TestBasic:test_method_deleted()
  class "A"
  function A:f() end
  A.f = nil
  assertError(function() A():f() end)
  A = nil
end

function TestBasic:test_initializer_called()
  class "A" do
    function A:initialize(x)
      self.x = x
    end
  end
  local x = {}
  local a = A(x)
  assert(a.x==x, "a.x ~= x")
  A = nil
end

function TestBasic:test_class_derived()
  class "A" do
    function A:f(x)
      return x
    end
  end
  class "B" (A)
  local x = {}
  local b = B()
  local _x = b:f(x)
  assert(x==_x, "x ~= _x")
  A = nil
  B = nil
end

function TestBasic:test_class_deriving_failed()
  local f = class "A"
  assertEquals(type(f),"function")
  assertError(f)
  assertError(f,"")
  assertError(f,true)
  assertError(f,false)
  assertError(f,10)
  assertError(f,{})
  assertError(f,function()end)
end

function TestBasic:test_supermethod_called()
  local x, y = {}, {}
  class "A"
  function A:f(x,y)
    return x, y
  end
  class "B" (A)
  function B:f(x,y)
    return super(x,y)
  end
  local _x, _y = B():f(x,y)
  assertEquals(x,_x)
  assertEquals(y,_y)
  A, B = nil
end

function TestBasic:test_deep_supermethod_called()
  class "A"
  function A:f(x,y)
    return x, y
  end
  class "B" (A)
  class "C" (B)
  class "D" (C)
  class "E" (D)
  function E:f(x,y)
    return super(x,y)
  end
  local x, y = {}, {}
  local _x, _y = E():f(x,y)
  assertEquals(x,_x)
  assertEquals(y,_y)
  A, B, C, D, E = nil
end

function TestBasic:test_supermethod_fail()
  function Object:f()
    super()
  end
  assertError(function() Object():f() end)
  ----
  class "A"
  class "B" (A)
  function B:f()
    super()
  end
  assertError(function() B():f() end)
  A, B = nil
end

function TestBasic:test_class_non_method_accessible()
  class "A"
  for _, x in ipairs{0, true, false, -10, 10, "lemon cake", {}, nil} do
    A.x = x
    assertEquals(A.x,nil)
    assertEquals(A().x,x)
  end
  A = nil
end

function TestBasic:test_finalizer_called()
  class "A"
  local t = {}
  local _t
  function A:finalize()
    _t = t
  end
  A()
  collectgarbage()
  assertEquals(_t,t)
  A = nil
end



---- CLASS-METHODS ----

TestClassMethods = {}

--[[
function TestClassMethods:test_?()
  ....
end
--]]

function TestClassMethods:test_class_method_called()
  class "A"
  local Aclass = A:classtable()
  function Aclass:f(x)
    return self, x
  end
  local t = {}
  local _self, _t = A:f(t)
  assertEquals(_self,A)
  assertEquals(_t,t)
  A = nil
end

function TestClassMethods:test_no_class_method()
  class "A"
  local Aclass = A:classtable()
  assertError(A.f)
  A = nil
end

function TestClassMethods:test_class_method_derived()
  class "A"
  local Aclass = A:classtable()
  function Aclass:f(x)
    return self, x
  end
  class "B" (A)
  local t = {}
  local _self, _t = B:f(t)
  assertEquals(_self,B)
  assertEquals(_t,t)
  A, B = nil
end

function TestClassMethods:test_deep_method_derived()
  class "A"
  local Aclass = A:classtable()
  function Aclass:f(x)
    return self, x
  end
  class "B" (A)
  class "C" (B)
  class "D" (C)
  class "E" (D)
  local t = {}
  local _self, _t = E:f(t)
  assertEquals(_self,E)
  assertEquals(_t,t)
  A, B, C, D, E = nil
end

function TestClassMethods:test_super_class_method_called()
  class "A"
  local Aclass = A:classtable()
  function Aclass:f(x)
    return self, x
  end
  class "B" (A)
  local Bclass = B:classtable()
  function Bclass:f(x)
    return super(x)
  end
  local t = {}
  local _self, _t = B:f(t)
  assertEquals(_self,B)
  assertEquals(_t,t)
  A, B = nil
end

function TestClassMethods:test_Objects_super()
  local Oclass = Object:classtable()
  function Oclass:f()
    super()
  end
  assertError(Object.f)
  Oclass.f = nil
end

function TestClassMethods:test_super_failed()
  class "A"
  class "B" (A)
  local Bclass = B:classtable()
  function Bclass:f(x)
    return super(x)
  end
  assertError(B.f)
  A, B = nil
end

function TestClassMethods:test_deep_super_called()
  class "A"
  local Aclass = A:classtable()
  function Aclass:f(x)
    return self, x
  end
  class "B" (A)
  class "C" (B)
  class "D" (C)
  class "E" (D)
  local Eclass = E:classtable()
  function Eclass:f(x)
    return super(x)
  end
  local t = {}
  local _self, _t = E:f(t)
  assertEquals(_self,E)
  assertEquals(_t,t)
  A, B, C, D, E = nil
end


---- META-METHODS ----

TestMetaMethods = {}

--[[
function TestMetaMethods:test_?()
  ....
end
--]]

local binoperators = {}
function binoperators.add(x,y) return x + y end
function binoperators.sub(x,y) return x - y end
function binoperators.mul(x,y) return x * y end
function binoperators.div(x,y) return x / y end
function binoperators.pow(x,y) return x ^ y end

function TestMetaMethods:test_binoperators()
  local t = {}
  class "A"
  for name in pairs(binoperators) do
    A['__'..name] = function(x,y)
      return t
    end
  end
  class "B"
  for _, f in pairs(binoperators) do
    local _t
    _t = f(A(),A())
    assertEquals(_t,t)
    _t = f(A(),B())
    assertEquals(_t,t)
    _t = f(B(),A())
    assertEquals(_t,t)
    _t = f(A(),{})
    assertEquals(_t,t)
    _t = f({},A())
    assertEquals(_t,t)
    _t = f(A(),nil)
    assertEquals(_t,t)
    _t = f(nil,A())
    assertEquals(_t,t)
    assertError(f,B(),B())
    assertError(f,B(),{})
    assertError(f,{},B())
  end
  A, B = nil
end

----
function TestMetaMethods:test_binoperators__()
  local t = {}
  class "A"
  for name in pairs(binoperators) do
    A['__'..name..'__'] = function(x,y)
      return t
    end
  end
  class "B"
  for _, f in pairs(binoperators) do
    local _t
    _t = f(A(),A())
    assertEquals(_t,t)
    _t = f(A(),B())
    assertEquals(_t,t)
    _t = f(B(),A())
    assertEquals(_t,t)
    _t = f(A(),{})
    assertEquals(_t,t)
    _t = f({},A())
    assertEquals(_t,t)
    _t = f(A(),nil)
    assertEquals(_t,t)
    _t = f(nil,A())
    assertEquals(_t,t)
    assertError(f,B(),B())
    assertError(f,B(),{})
    assertError(f,{},B())
  end
  A, B = nil
end
----

local compoperators = {}
function compoperators.lt(x,y) return x < y end
function compoperators.le(x,y) return x <= y end

function TestMetaMethods:test_compoperators()
  class "A"
  for name in pairs(compoperators) do
    A['__'..name] = function(x,y)
      return true
    end
  end
  class "B"
  for _, f in pairs(compoperators) do
    assert(f(A(),A()))
    assert(f(A(),B()))
    assert(f(B(),A()))
    assertError(f,B(),B())
  end
  A, B = nil
end

----
function TestMetaMethods:test_compoperators__()
  class "A"
  for name in pairs(compoperators) do
    A['__'..name..'__'] = function(x,y)
      return true
    end
  end
  class "B"
  for _, f in pairs(compoperators) do
    assert(f(A(),A()))
    assert(f(A(),B()))
    assert(f(B(),A()))
    assertError(f,B(),B())
  end
  A, B = nil
end
----

function TestMetaMethods:test_eq()
  class "A"
  class "B"
  assert(A() ~= A())
  assert(A() ~= B())
  function A:__eq(other)
    return true
  end
  assert(A() == A())
  assert(A() == B())
  A, B = nil
end

----
function TestMetaMethods:test_eq__()
  class "A"
  class "B"
  assert(A() ~= A())
  assert(A() ~= B())
  function A:__eq__(other)
    return true
  end
  assert(A() == A())
  assert(A() == B())
  A, B = nil
end
----

function TestMetaMethods:test_tostring()
  class "A"
  function A:__tostring()
    return "ABC"
  end
  assertEquals(tostring(A()),"ABC")
  A = nil
end

----
function TestMetaMethods:test_tostring__()
  class "A"
  function A:__tostring__()
    return "ABC"
  end
  assertEquals(tostring(A()),"ABC")
  A = nil
end
----

function TestMetaMethods:test_concat()
  class "A"
  function A:__concat(other)
    return "ABC"
  end
  class "B"
  assertEquals(A()..A(),'ABC')
  assertEquals(A()..B(),'ABC')
  assertEquals(type(B()..A()),'string')
  assertEquals(A()..{},'ABC')
  assertEquals({}..A(),'ABC')
  A = nil
end

----
function TestMetaMethods:test_concat__()
  class "A"
  function A:__concat__(other)
    return "ABC"
  end
  class "B"
  assertEquals(A()..A(),'ABC')
  assertEquals(A()..B(),'ABC')
  assertEquals(type(B()..A()),'string')
  assertEquals(A()..{},'ABC')
  assertEquals({}..A(),'ABC')
  A = nil
end
----

function TestMetaMethods:test_unm()
  local t = {}
  class "A"
  function A:__unm()
    return t
  end
  assertEquals(-A(),t)
  A = nil
end

----
function TestMetaMethods:test_unm__()
  local t = {}
  class "A"
  function A:__unm__()
    return t
  end
  assertEquals(-A(),t)
  A = nil
end
----

function TestMetaMethods:test_newindex()
  class "A"
  function A:__newindex(name,value)
    rawset(self,name,value)
  end
  local a = A()
  a.z = 13
  assertEquals(a.z,13)
  A = nil
end

----
function TestMetaMethods:test_newindex__()
  class "A"
  function A:__newindex__(name,value)
    rawset(self,name,value)
  end
  local a = A()
  a.z = 13
  assertEquals(a.z,13)
  A = nil
end
----

function TestMetaMethods:test_index()
  class "A"
  function A:__index(name)
    return name
  end
  assertEquals(A().x,'x')
  assertEquals(A()[10],10)
  assertEquals(A()[A],A)
  A = nil
end

----
function TestMetaMethods:test_index__()
  class "A"
  function A:__index__(name)
    return name
  end
  assertEquals(A().x,'x')
  assertEquals(A()[10],10)
  assertEquals(A()[A],A)
  A = nil
end
----

function TestMetaMethods:test_call()
  class "A"
  function A:__call(x,y)
    return x, y
  end
  local x, y = {}, {}
  local _x, _y = A()(x,y)
  assertEquals(_x,x)
  assertEquals(_y,y)
  A = nil
end

----
function TestMetaMethods:test_call__()
  class "A"
  function A:__call__(x,y)
    return x, y
  end
  local x, y = {}, {}
  local _x, _y = A()(x,y)
  assertEquals(_x,x)
  assertEquals(_y,y)
  A = nil
end
----

---- OBJECT API ----

TestObject = {}

function TestObject:test_new()
  class "A"
  local Aclass = A:classtable()
  function Aclass:new(x)
    local instance = super()
    instance.x = x
    return instance
  end
  local t = {}
  local a = A(t)
  assertEquals(a.x,t)
  A = nil
end

function TestObject:test_index()
  assertError(Object().f)
  function Object:f()
    return self
  end
  local o = Object()
  assertEquals(o:f(),o)
  Object.f = nil
end

function TestObject:test_class()
  class "A"
  assertEquals(A():class(),A)
  assertEquals(A:class(),Class)
  assertEquals(Class:class(),Class)
  assertEquals(Object:class(),Class)
  assertEquals(Object():class(),Object)
  assert(not rawequal(A():class(),Class))
  assert(not rawequal(A:class(),Object))
  assert(not rawequal(A():class(),Object))
  A = nil
end

function TestObject:test_instanceof()
  class "A"
  assert(A():instanceof(A))
  assert(not A():instanceof(Object))
  assert(A:instanceof(Class))
  assert(not A:instanceof(Object))
  assert(Object():instanceof(Object))
  assert(Object:instanceof(Class))
  assert(Class:instanceof(Class))
  A = nil
end

function TestObject:test_inherits()
  class "A"
  class "B" (A)
  class "C"
  local b = B()
  assert(b:inherits(B), "NOT b:inherits(B)")
  assert(b:inherits(A), "NOT b:inherits(A)")
  assert(not b:inherits(C), "YES b:inherits(C)")
  A, B, C = nil
end

function TestObject:test_totable()
  local isobject = classu.isobject
  local t = {}
  class "A"
  local a = A()
  a.x = t
  assert(isobject(a))
  local _a, info = a:totable()
  assertEquals(_a,a)
  assert(not isobject(a))
  assertEquals(type(a),'table')
  assertEquals(a.x,t)
  A = nil
end

function TestObject:test_totable_finalize()
  local t = {}
  local _t
  class "A"
  function A:finalize()
    _t = t
  end
  local a = A()
  a:totable()
  collectgarbage()
  assertEquals(_t,nil)
  local a2 = A()
  a2:totable(true)
  collectgarbage()
  assertEquals(_t,t)
  A = nil
end

function TestObject:test_concat()
  assertEquals(type(Object()..''),'string')
  assertEquals(type(''..Object()),'string')
end

function TestObject:test_address()
  class "A"
  local addr = A():address()
  assertEquals(type(addr),"string")
  assert(string.find(addr,'0x%x+'))
  A = nil
end

function TestObject:test_bound()
  class "A"
  function A:f(x)
    return x
  end
  local t = {}
  local f = A():bound('f')
  assertEquals(f(),A():f())
  A = nil
end

function TestObject:test_send()
  local t = {}
  class "A"
  function A:f(x)
    return x
  end
  assertEquals(A():send('f',t),A():f(t))
  A = nil
end

function TestObject:test_instanceeval()
  class "A"
  local t = {}
  local a = A()
  assertEquals(a:instanceeval(function(self)
                                return self
                              end),
               a)
  assertEquals(a:instanceeval(function(self,x)
                                return x
                              end,t),
               t)
  A = nil
end

--[[
function TestObject:test_methods()
  class "A"
  function A:f()
  end
  assert(table.key(A():methods(),'f'))
  A = nil
end
--]]

--[[
function TestObject:test_?()
  ....
end
--]]




---- CLASS API ----

TestClass = {}

--[[
function TestClass:test_?()
  ....
end
--]]

function TestClass:test_name()
  class "A"
  assertEquals(A:name(),'A')
  assertEquals(Object:name(),'Object')
  assertEquals(Class:name(),'Class')
  assertError(function() A():name() end)
  A = nil
end

function TestClass:test_super()
  class "A"
  class "B" (A)
  assert(rawequal(A:super(),Object))
  assert(rawequal(B:super(),A))
  assert(not Object:super())
  assert(rawequal(Class:super(),Object))
  assert(not rawequal(B:super(),Object))
  assert(not rawequal(A:super(),Class))
  assert(not rawequal(B:super(),Class))
  A, B = nil
end

function TestClass:test_derives()
  class "A"
  class "B" (A)
  class "C"
  assert(Class:derives(Object))
  assert(A:derives(Object))
  assert(B:derives(A))
  assert(B:derives(Object))
  assert(not B:derives(C))
  assert(not A:derives(Class))
  assert(not B:derives(Class))
  assert(not C:derives(Class))
  A, B, C = nil
end

function TestClass:test_adopt()
  local t = {}
  local u = {}
  class "A"
  function A:f()
    return t
  end
  function A:g()
    return self.x
  end
  local a = A:adopt {x = u}
  assertEquals(a:f(),t)
  assertEquals(a:g(),u)
  A = nil
end

function TestClass:test_adopt_initialize()
  local t = {}
  class "A"
  function A:initialize(x)
    self.x = x
  end
  local a = A:adopt {}
  assertEquals(a.x,nil)
  local a2 = A:adopt({},true,t)
  assertEquals(a2.x,t)
  A = nil
end

function TestClass:test_initialize()
  local _A = Class('A')
  assert(A)
  assertEquals(_A,A)
  assertEquals(A:super(),Object)
  local _B = Class('B',A)
  assert(B)
  assertEquals(_B,B)
  assertEquals(B:super(),A)
  A, B = nil
end


---- COMPLEX TESTS ----

TestComplex = {}

--[[
function TestComplex:test_?()
  ....
end
--]]

function TestComplex:test_totable_adopt()
  local t = {}
  class "A"
  function A:initialize()
    self.x = t
  end
  function A:f()
    return self.x
  end
  local a = A()
  assertEquals(a:f(),t)
  a:totable()
  assertError(function() a:f() end)
  A:adopt(a)
  assertEquals(a:f(),t)
  A = nil
end



---- UTILITIES ----

TestUtilities = {}

function TestUtilities:test_wrongarg()
  assertEquals(type(classu.wrongarg(1,2,3)),'string')
end

function TestUtilities:test_isname()
  assert(classu.isname('A'))
  assert(classu.isname('a'))
  assert(classu.isname('_'))
  assert(classu.isname('AbcDef'))
  assert(classu.isname('Abc_Def'))
  assert(classu.isname('_abc'))
  assert(classu.isname('__abc'))
  assert(classu.isname('ABCDEF'))
  assert(classu.isname('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'))
  assert(classu.isname('_______________________'))
  assert(classu.isname('abc44'))
  assert(not classu.isname(0))
  assert(not classu.isname(true))
  assert(not classu.isname(false))
  assert(not classu.isname({}))
  assert(not classu.isname(function()end))
  assert(not classu.isname(''))
  assert(not classu.isname(' '))
  assert(not classu.isname('a b c'))
  assert(not classu.isname(' a'))
  assert(not classu.isname('a '))
  assert(not classu.isname('44'))
  assert(not classu.isname('*%&(@'))
end

function TestUtilities:test_assert()
  assertError(classu.assert)
  assertError(classu.assert,false,'')
  assertError(classu.assert,false,function()
                                    return ''
                                  end)
  local t = {}
  local _t
  assertError(classu.assert,false,function()
                                    _t = t
                                    return ''
                                  end)
  assertEquals(_t,t)
  _t = nil
  assertError(classu.assert,false,function(x)
                                    _t = x
                                    return ''
                                  end,t)
  assertEquals(_t,t)
  _t = nil
end

function TestUtilities:test_fwrongarg()
  assertEquals(type(classu.fwrongarg(1,2,3)()),'string')
end

function TestUtilities:test_isobject()
  local isobject = classu.isobject
  ----
  assert(not isobject())
  assert(not isobject(0))
  assert(not isobject(true))
  assert(not isobject(false))
  assert(not isobject(function()end))
  assert(not isobject(''))
  assert(not isobject({}))
  assert(isobject(Object))
  assert(isobject(Class))
  assert(isobject(Object()))
  class "A"
  assert(isobject(A))
  assert(isobject(A()))
  A = nil
end

function TestUtilities:test_table_key()
  assertEquals(table.key({13,14,15},14),2)
  assertEquals(table.key({13,a=14,15},14),'a')
  assertEquals(table.key({13,14,15},16),nil)
end

--[[
function TestUtilities:test_?()
  ....
end
--]]





LuaUnit:run()