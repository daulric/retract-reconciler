local Children = require(script.Parent.Parent.Parent:WaitForChild("markers").Children)

function updateFunctional(virtualNode, newElement, reconciler)
    local children = newElement.class(newElement.props)
    reconciler.updateChildren(virtualNode, virtualNode.hostParent, children)
    return virtualNode
end

function updateGateway(virtualNode, newElement, reconciler)
    local oldElement = virtualNode.currentElement
    local oldPath = oldElement.props.path

    local hostPath = newElement.props.path

    if oldPath ~= hostPath then
        return reconciler.replaceVirtualNode(virtualNode, newElement)
    end

    local children = newElement.props[Children]

    reconciler.updateChildren(virtualNode, hostPath, children)

    return virtualNode
end

function updateFragment(virtualNode, newElement, reconciler)
    reconciler.updateChildren(virtualNode, virtualNode.hostParent, newElement.elements)
    return virtualNode
end

return {
    fragment = updateFragment,
    functional = updateFunctional,
    gateway = updateGateway,
}