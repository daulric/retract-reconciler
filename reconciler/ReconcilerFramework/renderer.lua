local renderer = {}
local markers = script.Parent.Parent.Parent:WaitForChild("markers")
local Type = require(markers:WaitForChild("Type"))

local Children = require(markers.Children)
local Data = require(markers.data)
local SingleEventManager = require(script.Parent.Parent.Parent:WaitForChild("SingleEventManager"))

local function identity(...)
    return ...
end

local function applyProp(virtualNode, key, newValue, oldValue)
    if newValue == oldValue then
        return
    end

    if key == Children then
        return
    end

    if key.Event then
        virtualNode.eventManager = SingleEventManager.new(virtualNode.object)
        virtualNode.eventManager:connect2(key, newValue)
    elseif key.Type == Type.Attribute then
        virtualNode.object:SetAttribute(key.name, newValue)
    else
        virtualNode.object[key] = newValue
    end

end

local function applyProps(virtualNode, props)
    for key, value in pairs(props) do
        applyProp(virtualNode, key, value, nil)
    end
end

function updateProps(virtualNode, oldProps, newProps)

    for key, newValue in pairs(newProps) do
        local oldValue = oldProps[key]
        applyProp(virtualNode, key, newValue, oldValue)
    end

    for key, oldValue in pairs(oldProps) do
        local newValue = newProps[key]

        if newValue == nil then
            applyProp(virtualNode, key, nil, oldValue)
        end

    end

end

function renderer.mountHostNode(virtualNode, reconciler)
    local element = virtualNode.currentElement
    local hostParent = virtualNode.hostParent

    local instance = Instance.new(element.class)
    virtualNode.object = instance
    instance.Name = tostring(virtualNode.hostKey)

    local success, errorMessage = xpcall(function()
        applyProps(virtualNode, element.props)
    end, identity)

    if not success then

        local source = element.source

		if source == nil then
			source = "<enable element tracebacks>"
		end

        error(errorMessage)

    end

    local children = element.props[Children]

    if children ~= nil then
        reconciler.updateChildren(virtualNode,virtualNode.object, children)
    end

    instance.Parent = hostParent
    virtualNode.object = instance

end

function renderer.unmountHostNode(virtualNode, reconciler)

    for i, node in pairs(virtualNode.children) do
        reconciler.unmountNode(node)
    end

    virtualNode.object:Destroy()
end

function renderer.updateHostNode(virtualNode, reconciler, newElement)
    local oldProps = virtualNode.currentElement.props
    local newProps = newElement.props

    if virtualNode.eventManager then
        virtualNode.eventManager:suspend()
    end

    local success, err = xpcall(function()
        updateProps(virtualNode, oldProps, newProps)
    end, identity)

    if not success then
        local source = newElement.source

        if source == nil then
            source = "<element tracebacks>"
        end

        error(`{source}:{err}`)
    end

    local children = newElement.props[Children]

    if children ~= nil or oldProps[Children] ~= nil then
        reconciler.updateChildren(virtualNode, virtualNode.hostParent, children)
    end

    if virtualNode.eventManager then
        virtualNode.eventManager:resume()
    end

    return virtualNode
end

return renderer