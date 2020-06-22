local CircularLinkedList = {}
CircularLinkedList.__index = CircularLinkedList

function CircularLinkedList.new()
    local Sentinel = {value = nil};
    Sentinel._next = Sentinel;
    Sentinel._prev = Sentinel;

    local self = setmetatable({_head = Sentinel, _tail = Sentinel}, CircularLinkedList)

    return self
end

function CircularLinkedList:Insert(value)
    local newNode = {value = value, _next = self._head._next, _prev = self._head}
    self._head._next._prev = newNode
    self._head._next = newNode
    self._head = newNode
end

function CircularLinkedList:Remove(value)
    local cur = self._head
    while cur.value ~= value do
        cur = cur._next
        if cur == self._head then
            return nil
        end
    end

    if cur == self._head then
        self._head = cur._next
    elseif cur == self._tail then
        self._tail = cur._prev
    end

    cur._next._prev = cur._prev
    cur._prev._next = cur._next
    cur._removed = true
end

function CircularLinkedList:Iter()
    local iter = {_list = self, _cur = self._head}

    function iter:moveToPresentItem(direction)
        local shouldSkip = self._cur._removed or not self._cur.value
        local isSingleNode = self._cur == self._cur._next
        while shouldSkip and not isSingleNode do
            if direction == "right" then
                self._cur = self._cur._next
            else
                self._cur = self._cur._prev
            end
            shouldSkip = self._cur._removed or not self._cur.value
            isSingleNode = self._cur == self._cur._next
        end
    end

    function iter:Current()
        self:moveToPresentItem("right")
        return self._cur.value
    end

    function iter:Next()
        self._cur = self._cur._next
        self:moveToPresentItem("right")
        return self._cur.value
    end

    function iter:Prev()
        self._cur = self._cur._prev
        self:moveToPresentItem("left")
        return self._cur.value
    end

    function iter:IsEmpty() return self._cur.value == nil end

    return iter
end

return CircularLinkedList
