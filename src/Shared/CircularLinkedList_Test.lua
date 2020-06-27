local CircularLinkedList_Test = {}

CircularLinkedList_Test["Inserting an element moves the head"] =
function(state)
    -- GIVEN:
    local cll = state.Shared.CircularLinkedList.new()

    -- WHEN:
    cll:Insert(1)
    cll:Insert(2)
    cll:Insert(3)

    -- EXPECT:
    state:Expect(cll:Iter():Current()):Equals(3)
end

CircularLinkedList_Test["Looping is cyclic"] =
function(state)
    -- GIVEN:
    local cll = state.Shared.CircularLinkedList.new()

    -- WHEN:
    cll:Insert(1)
    cll:Insert(2)
    cll:Insert(3)

    local iter = cll:Iter()
    local result = {}
    for _ = 1, 6 do
        result[#result + 1] = iter:Current()
        iter:Next()
    end

    -- EXPECT:
    state:Expect(result):Equals({3, 1, 2, 3, 1, 2})
end

CircularLinkedList_Test["Removing an element from the list"] =
function(state)
	-- GIVEN:
	local cll = state.Shared.CircularLinkedList.new()

	-- WHEN:
	cll:Insert(1)
	cll:Insert(2)
	cll:Insert(3)

	cll:Remove(1)
	cll:Remove(2)
	cll:Remove(3)

	-- EXPECT:
	state:Expect(cll:Iter():IsEmpty()):IsTruthy()
end

return CircularLinkedList_Test
