--- Functional iteration utilities using coroutines.
--Modified version of <a href="https://github.com/aperezdc/lua-itertools">itertools.lua</a>.
--Documentation can be found
--<a href="https://aperezdc.github.io/lua-itertools/">here</a>.
-- @module itertools.lua
-- @author aperezdc
-- @license MIT
-- @copyright aperezdc 2016

local pairs, ipairs, t_sort = pairs, ipairs, table.sort
local co_yield, co_wrap = coroutine.yield, coroutine.wrap
local co_resume = coroutine.resume
itertools = {}
---

---
function itertools.values (table)
   return co_wrap(function ()
      for _, v in pairs(table) do
         co_yield(v)
      end
   end)
end
---

---
function itertools.each (table)
   return co_wrap(function ()
      for _, v in ipairs(table) do
         co_yield(v)
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
   return co_wrap(function ()
      while true do
         co_yield(n)
         n = n + step
      end
   end)
end
---

---
function itertools.cycle (iterable)
   local saved = {}
   local nitems = 0
   return co_wrap(function ()
      for element in iterable do
         co_yield(element)
         nitems = nitems + 1
         saved[nitems] = element
      end
      while nitems > 0 do
         for i = 1, nitems do
            co_yield(saved[i])
         end
      end
   end)
end
---

---
function itertools.value (value, times)
   if times then
      return co_wrap(function ()
         while times > 0 do
            times = times - 1
            co_yield(value)
         end
      end)
   else
      return co_wrap(function ()
         while true do co_yield(value) end
      end)
   end
end
---

---
function itertools.islice (iterable, start, stop)
   if start == nil then
      start = 1
   end
   return co_wrap(function ()
      if stop ~= nil and stop - start < 1 then
         return
      end

      local current = 0
      for element in iterable do
         current = current + 1
         if stop ~= nil and current > stop then
            return
         end
         if current >= start then
            co_yield(element)
         end
      end
   end)
end
---

---
function itertools.takewhile (predicate, iterable)
   return co_wrap(function ()
      for element in iterable do
         if predicate(element) then
            co_yield(element)
         else
            break
         end
      end
   end)
end
---

---
function itertools.map (func, iterable)
   return co_wrap(function ()
      for element in iterable do
         co_yield(func(element))
      end
   end)
end
---

---
function itertools.filter (predicate, iterable)
   return co_wrap(function ()
      for element in iterable do
         if predicate(element) then
            co_yield(element)
         end
      end
   end)
end

local function make_comp_func(key)
   if key == nil then
      return nil
   end
   return function (a, b)
      return key(a) < key(b)
   end
end

local _collect = itertools.collect
---

---
function itertools.sorted (iterable, key, reverse)
   local t, n = _collect(iterable)
   t_sort(t, make_comp_func(key))
   if reverse then
      return co_wrap(function ()
         for i = n, 1, -1 do co_yield(t[i]) end
      end)
   else
      return co_wrap(function ()
         for i = 1, n do co_yield(t[i]) end
      end)
   end
end

--shortcut for iterating
iter = itertools.values

