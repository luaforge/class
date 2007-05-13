
require('luaunit')
require('class')


TestClass = {}

function TestClass:test_class_created()
  class "A"
  assert(A, "NOT A")
  A = nil
end

function TestClass:test_instance_created()
  class "A"
  local a = A()
  assert(a, "NOT a")
  A = nil
end

function TestClass:test_method_called()
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

function TestClass:test_initializer_called()
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

function TestClass:test_class_derived()
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

---- META-METHODS ----

local binoperators = {}
function binoperators.add(x,y) return x + y end
function binoperators.sub(x,y) return x - y end
function binoperators.mul(x,y) return x * y end
function binoperators.div(x,y) return x / y end
function binoperators.pow(x,y) return x ^ y end
function binoperators.concat(x,y) return x..y end

function TestClass:test_binoperators()
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

local compoperators = {}
function compoperators.lt(x,y) return x < y end
function compoperators.le(x,y) return x <= y end
function compoperators.eq(x,y) return x == y end

function TestClass:test_compoperators()
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
    --assert(f(B(),A()))      -- 'cause Object:__eq__
    --assertError(f,B(),B())
  end
  A, B = nil
end

function TestClass:test_tostring()
  class "A"
  function A:__tostring__()
    return "ABC"
  end
  assertEquals(tostring(A()),"ABC")
  A = nil
end

function TestClass:test_unm()
  local t = {}
  class "A"
  function A:__unm__()
    return t
  end
  assertEquals(-A(),t)
  A = nil
end

function TestClass:test_newindex()
  class "A"
  function A:__newindex__(name,value)
    rawset(self,name,value)
  end
  local a = A()
  a.z = 13
  assertEquals(a.z,13)
  A = nil
end

function TestClass:test_index()
  class "A"
  function A:__index__(name)
    return name
  end
  assertEquals(A().x,'x')
  assertEquals(A()[10],10)
  assertEquals(A()[A],A)
  A = nil
end

function TestClass:test_call()
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

--------------

function TestClass:test_inherits()
  class "A"
  class "B" (A)
  class "C"
  local b = B()
  assert(b:inherits(B), "NOT b:inherits(B)")
  assert(b:inherits(A), "NOT b:inherits(A)")
  assert(not b:inherits(C), "YES b:inherits(C)")
  --assert(B:inherits(A), "NOT B:inherits(A)")  --it is actually `implements()'
  A, B, C = nil
end

function TestClass:test_super()
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

--[[       --currently fails--
function TestClass:test_class_non_method_accessible()
  local x = {}
  class "A"
  A.x = x
  assertEquals(A.x,nil)
  assertEquals(A().x,x)
  A = nil
end
--]]



-- TODO: test classes API

--function TestClass:test_Class_derives()
--function TestClass:test_Class_findmethod()

--[[
function TestClass:test_?()
  ....
end
--]]


LuaUnit:run()