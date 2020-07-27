util.AddNetworkString( "zs_nail_destroyed" )
hook.Add("OnNailRemoved", "ZS.PropJournal.NailCheck", function(nail, ent1, ent2, remover)
	if nail and nail:IsValid() then
		net.Start("zs_nail_destroyed")
			net.WriteEntity(nail:GetBaseEntity())
			net.WriteInt(#nail:GetBaseEntity():GetNails(),5)
		net.Send( nail:GetDeployer() )
	end
end)