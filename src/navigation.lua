--- Generic navigation algorithms for GUI-based apps
-- @module navigation


---- Tree object
-- @type TransitionTree
TransitionTree = class('TransitionTree')

function TransitionTree:__init(name, parent, forward, backward)
  self.name = name or 'root'
  self.parent = parent
  if is.Nil(backward) then self.backward = forward
  else
    self.forward = forward
    self.backward = backward
  end
  self.nodes = {}
end

function TransitionTree:__index(value)
  return rawget(TransitionTree, value) or rawget(self, value) or self.nodes[value]
end

---- Add a node to the tree
-- @param name
-- @param forward
-- @param backward
function TransitionTree:add(name, forward, backward)
  self.nodes[name] = TransitionTree(name, self, forward, backward)
end

---- Get the path from the current node to the root node
function TransitionTree:path_to_root()
  local path = list{self}
  local parent = self.parent
  while Not.Nil(parent) do
    path:append(parent)
    parent = parent.parent
  end
  return path
end

---- Get the path from the current node to the named node
-- @param name
function TransitionTree:path_to(name)
  local q = list()
  for i, v in pairs(self.nodes) do q:append({i, v}) end
  local item
  while len(q) > 0 do
    item = q:pop(1)
    for i, v in pairs(item[2].nodes) do q:append({i, v}) end
    if item[1] == name then return reversed(item[2]:path_to_root()) end
  end
end

---- Least common ancestor of two nodes
-- @param name1
-- @param name2
function TransitionTree:lca(name1, name2)
  local lca = 'root'
  local v1, v2
  local path1, path2 = self:path_to(name1), self:path_to(name2)
  for i=2, math.min(len(path1), len(path2)) do
    v1, v2 = path1[i], path2[i]
    if v1.name == v2.name then lca = v1.name; break end
    if v1.parent ~= v2.parent then break else lca = v1.parent.name end
  end
  return lca 
end

---- Navigate the tree calling forward and backward functions
-- @param start
-- @param _end
function TransitionTree:navigate(start, _end)
  local counting = false
  local lca = self:lca(start, _end)
  local path1, path2 = reversed(self:path_to(start)), self:path_to(_end)
  for i, v in pairs(path1) do 
    if v.name == lca then break end
    v.backward()
  end

  for i, v in pairs(path2) do 
    if counting then v.forward() end
    if v.name == lca then counting = true end
  end
end

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------


Navigator = class('Navigator')
