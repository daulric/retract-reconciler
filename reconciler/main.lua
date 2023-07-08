local Markers = script.Parent.Parent:WaitForChild("markers")

local createNode = require(script.Parent:WaitForChild("createNode"))
local ReconcilerFramework = script.Parent:WaitForChild("ReconcilerFramework")

local Symbol = require(Markers:WaitForChild("Symbol"))
local InternalData = Symbol.assign("Internal Data")

local mount = require(ReconcilerFramework:WaitForChild("mount"))
local update = require(ReconcilerFramework:WaitForChild("update"))

local ElementType = require(Markers:WaitForChild("ElementType"))

type VirtualNode = typeof(createNode())

return function (renderer)
    local reconciler

    local mountNode
    local updateNode
    local unmountNode

    function mountNode(element, hostParent, hostKey)
        local virtualNode = createNode(element, hostParent, hostKey)

        if element.Type == ElementType.Types.Host then
            renderer.mountHostNode(virtualNode, reconciler)
        elseif element.Type == ElementType.Types.Functional then
            mount.functional(virtualNode, reconciler)
        elseif element.Type == ElementType.Types.Fragment then
            mount.fragment(virtualNode, reconciler)
        elseif element.Type == ElementType.Types.Gateway then
            mount.gateway(virtualNode, reconciler)
        elseif element.Type == ElementType.Types.StatefulComponent then
            element.class:__mount2(virtualNode, reconciler)
        else
            error(`There is an issue with the node created! node id: {virtualNode}`)
        end

        return virtualNode
    end

    local function updateChildren(virtualNode: VirtualNode, hostParent, newChildElements)

		virtualNode.updateChildrenCount = virtualNode.updateChildrenCount + 1

		local currentUpdateChildrenCount = virtualNode.updateChildrenCount

		local removeKeys = {}

		for childKey, childNode in pairs(virtualNode.children) do
			local newElement = ElementType.getElementByID(newChildElements, childKey)

			local newNode = updateNode(childNode, newElement)

			if virtualNode.updateChildrenCount ~= currentUpdateChildrenCount then
				if newNode and newNode ~= virtualNode.children[childKey] then
					unmountNode(newNode)
				end

				return
			end

			if newNode ~= nil then
				virtualNode.children[childKey] = newNode
			else
				removeKeys[childKey] = true
			end
		end

		for childKey in pairs(removeKeys) do
			virtualNode.children[childKey] = nil
		end

		for childKey, newElement in ElementType.iterateElements(newChildElements) do
			local concreteKey = childKey

			if childKey == ElementType.Key then
				concreteKey = virtualNode.hostKey
			end

			if virtualNode.children[childKey] == nil then
				local childNode = mountNode(
					newElement,
					hostParent,
					concreteKey
				)

				if virtualNode.updateChildrenCount ~= currentUpdateChildrenCount then
					if childNode then
						unmountNode(childNode)
					end

					return
				end

				if childNode ~= nil then
					childNode.depth = virtualNode.depth + 1
					childNode.parent = virtualNode
					virtualNode.children[childKey] = childNode
				end

			end
		end
	end

    local function mountVirtualTree(element, hostParent, hostKey)
        local tree = {
            Type = ElementType.Types.VirtualTree,
            [InternalData] = {
                rootNode = nil,
                mounted = true
            }
        }

        if hostKey == nil then
            hostKey = "Retract Node"
        end

        tree[InternalData].rootNode = mountNode(element, hostParent, hostKey)
        return tree
    end

    function unmountNode(virtualNode: VirtualNode)
        local currentElement = virtualNode.currentElement
        virtualNode.unmounted = true

        if currentElement.Type == ElementType.Types.Host then
            renderer.unmountHostNode(virtualNode, reconciler)
        elseif currentElement.Type == ElementType.Types.Fragment then
            for i, elements in pairs(virtualNode.children) do
                unmountNode(elements)
            end
        elseif currentElement.Type == ElementType.Types.Functional then
            for i, elements in pairs(virtualNode.children) do
                unmountNode(elements)
            end
        elseif currentElement.Type == ElementType.Types.Gateway then
            for i, elements in pairs(virtualNode.children) do
                unmountNode(elements)
            end
        elseif currentElement.Type == ElementType.Types.StatefulComponent then
            currentElement.class:__unmount2(virtualNode, reconciler)
        else
            error(`Unknown Element Virtual Tree ID: {currentElement}`)
        end
    end

    local function unmountVirtualTree(VirtualTree)
        if VirtualTree[InternalData].rootNode then
            local rootNode = VirtualTree[InternalData].rootNode
            unmountNode(rootNode)
        end
    end

    local function replaceVirtualNode(virtualNode: VirtualNode, newElement)
        local hostParent = virtualNode.hostParent
        local parent = virtualNode.parent

        if not virtualNode.unmounted then
            unmountNode(virtualNode)
        end

        local newNode = mountNode(newElement, hostParent)

        if newNode ~= nil then
            newNode.parent = parent
        end

        return newNode
    end

    function updateNode(virtualNode: VirtualNode, newElement, newState)

        if virtualNode.currentElement == newElement and newState == nil then
            return virtualNode
        end

        if typeof(newElement) == "boolean" or newElement == nil then
            reconciler.unmountNode(virtualNode)
            return nil
        end

        if virtualNode.currentElement and virtualNode.currentElement.class ~= newElement.class then
            return reconciler.replaceVirtualNode(virtualNode, newElement)
        end

        local Type = virtualNode.currentElement.Type

        if Type == ElementType.Types.Host then
            virtualNode = renderer.updateHostNode(virtualNode, reconciler, newElement)
        elseif Type == ElementType.Types.Fragment then
            virtualNode = update.fragment(virtualNode, newElement, reconciler)
        elseif Type == ElementType.Types.Functional then
            virtualNode = update.functional(virtualNode, newElement, reconciler)
        elseif Type == ElementType.Types.StatefulComponent then
            virtualNode = virtualNode.currentElement.class:__update2(newElement, newState)
        elseif Type == ElementType.Types.Gateway then
            virtualNode = update.gateway(virtualNode, newElement, reconciler)
        else
            error("Unknown Element Type! Unable to Update this Element!", 2)
        end

        virtualNode.currentElement = newElement
        return virtualNode
    end

    local function updateVirtualTree(tree, newElement)
        local InternalData = tree[InternalData]

        InternalData.rootNode = updateNode(InternalData.rootNode, newElement)

        return tree
    end

    reconciler = {
        mountNode = mountNode,
        unmountNode = unmountNode,
        replaceVirtualNode = replaceVirtualNode,
        updateNode = updateNode,

        mountVirtualTree = mountVirtualTree,
        unmountVirtualTree = unmountVirtualTree,
        updateVirtualTree = updateVirtualTree,

        updateChildren = updateChildren,
    }

    return reconciler

end