util.AddNetworkString("SlashUI.Emitter")

function SlashUI.Emit(name, amount, parent, args)
	net.Start("SlashUI.Emitter")
	net.WriteString(name)
	net.WriteInt(amount, 32)
	net.WriteEntity(parent)
	net.WriteTable(args or {})
	net.Broadcast()
end