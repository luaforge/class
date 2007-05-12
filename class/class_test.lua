
require('luaunit')
----
require('class')
----


TestClass = {}

function TestClass:test_class_created()
  class "A"
  assert(A, "NOT A")
  -- check class name ?
  A = nil
end

function TestClass:test_instance_created()
  class "A"
  local a = A()
  assert(a, "NOT a")
  -- check class ?
  -- check class name ?
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

function TestClass:test_metamethods()  --FIXME: write test for each meta-method
  local x = {}
  class "A" do
    function A:__add__(other)
      return x
    end
  end
  assert(A()+{}==x, "A()+{} ~= x")
  assert({}+A()==x, "{}+A() ~= x")
  A = nil
end

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

--function TestClass:test_index()
--function TestClass:test_newindex()
--function TestClass:test_Class_derives()
--function TestClass:test_Class_findmethod()

--function TestClass:test_?()


LuaUnit:run()