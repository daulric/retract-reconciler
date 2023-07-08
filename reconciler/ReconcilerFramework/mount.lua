local Children = require(script.Parent.Parent.Parent:WaitForChild("markers").Children)

function mountFunctionalNode(virtualNode, reconciler)
    local currentElement = virtualNode.currentElement
    local stuff = currentElement.class(currentElement.props)
    reconciler.updateChildren(virtualNode, virtualNode.hostParent, stuff)
end

function mountGatewayNode(virtualNode, reconciler)
    local currentElement = virtualNode.currentElement
    local target = currentElement.props.path
    reconciler.updateChildren(virtualNode, target, currentElement.props[Children])
end

function mountFragment(virtualNode, reconciler)
    local currentElement = virtualNode.currentElement

    local elements

    if currentElement.class then
        elements = currentElement.class.elements
    else
        elements = currentElement.elements
    end

    reconciler.updateChildren(virtualNode, virtualNode.hostParent, elements)
end

return {
    fragment = mountFragment,
    functional = mountFunctionalNode,
    gateway = mountGatewayNode
}