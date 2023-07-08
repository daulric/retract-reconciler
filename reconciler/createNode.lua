local ElementType = require(script.Parent.Parent:WaitForChild("markers").ElementType)

return function (element, hostParent, key)
    return {
        Type = ElementType.Types.Element,
        currentElement = element,
        children = {},
        parent = nil,
        unmounted = false,
        hostParent = hostParent,
        hostKey = key,
        object = nil,
        updateChildrenCount = 0,
        depth = 0,
    }
end