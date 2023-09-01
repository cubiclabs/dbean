component{

	this.cfMapping = "dbean";
	this.register = "db";

	
	function configure(){

		Bolt().register("#this.path#.db", this.subsystem)
			.as("db@DBean")
			.withInitArg(name:"settings", value:Bolt().getModuleConfig("dbean"));
	
	}
}