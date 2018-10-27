--- Functional iteration utilities using coroutines.
--Modified version of <a href="https://github.com/aperezdc/lua-itertools">itertools.lua</a>.
--Documentation can be found
--<a href="https://aperezdc.github.io/lua-itertools/">here</a>.
-- @module itertools.lua
-- @author aperezdc
-- @license MIT
-- @copyright aperezdc 2016

itertools = {}

---
function itertools.values (table)
   return coroutine.wrap(function ()
      for _, v in pairs(table) do
         coroutine.yield(v)
      end
   end)
end
---

---
function itertools.each (table)
   return coroutine.wrap(function ()
      for _, v in ipairs(table) do
         coroutine.yield(v)
      end
   end)
end
---

---
function itertools.collect (iterable)
   local t, n = {}, 0
   for element in iterable do
      n = n + 1
      t[n] = element
   end
   return t, n
end
---

---
function itertools.count (n, step)
   if n == nil then n = 1 end
   if step == nil then step = 1 end
   return coroutine.wrap(function ()
      while true do
         coroutine.yield(n)
         n = n + step
      end
   end)
end
---

---
function itertools.cycle (iterable)
   local saved = {}
   local nitems = 0
   return coroutine.wrap(function ()
      for element in iterable do
         coroutine.yield(element)
         nitems = nitems + 1
         saved[nitems] = element
      end
      while nitems > 0 do
         for i = 1, nitems do
            coroutine.yield(saved[i])
         end
      end
   end)
end
---

---
function itertools.value (value, times)
   if times then
      return coroutine.wrap(function ()
         while times > 0 do
            times = times - 1
            coroutine.yield(value)
         end
      end)
   else
      return coroutine.wrap(function ()
         while true do coroutine.yield(value) end
      end)
   end
end
---

---
function itertools.islice (iterable, start, stop)
   if start == nil then
      start = 1
   end
   return coroutine.wrap(function ()
      -- these sections are covered but do not register
      -- luacov: disable
      if stop ~= nil and stop - start < 1 then return end
      -- luacov: enable
      local current = 0
      for element in iterable do
         current = current + 1
         -- luacov: disable
         if stop ~= nil and current > stop then return end
         -- luacov: enable
         if current >= start then
            coroutine.yield(element)
         end
      end
   end)
end
---

---
function itertools.takewhile (predicate, iterable)
   return coroutine.wrap(function ()
      for element in iterable do
         if predicate(element) then
            coroutine.yield(element)
         else
            break
         end
      end
   end)
end
---

---
function itertools.map (func, iterable)
   return coroutine.wrap(function ()
      for element in iterable do
         coroutine.yield(func(element))
      end
   end)
end
---

---
function itertools.filter (predicate, iterable)
   return coroutine.wrap(function ()
      for element in iterable do
         if predicate(element) then
            coroutine.yield(element)
         end
      end
   end)
end
---

---
local function make_comp_func(key)
   if type(key) == 'function' then
    return function (a, b)
        return key(a) < key(b)
    end
  end
end
---

---
function itertools.sorted (iterable, key, reverse)
   local t, n = itertools.collect(iterable)
   table.sort(t, make_comp_func(key))
   if reverse then
      return coroutine.wrap(function ()
         for i = n, 1, -1 do coroutine.yield(t[i]) end
      end)
   else
      return coroutine.wrap(function ()
         for i = 1, n do coroutine.yield(t[i]) end
      end)
   end
end
