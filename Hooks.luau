-- Tiny event hub so services can announce things (Fuse, Survive, Collect, Steal, FirstFuse)
-- without requiring each other in circles.
local Hooks = {}
local listeners = {}

function Hooks.On(name, callback)
	listeners[name] = listeners[name] or {}
	table.insert(listeners[name], callback)
end

function Hooks.Fire(name, ...)
	for _, callback in listeners[name] or {} do
		task.spawn(callback, ...)
	end
end

return Hooks
