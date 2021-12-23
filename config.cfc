component{

	this.cfMapping = "dbean";
	this.register = "db";

	
	function configure(){

		var initWith = {};
		var moduleConfig = Bolt().getConfig().modules;
		
		if(structKeyExists(moduleConfig, "db") AND isStruct(moduleConfig.db)){
			structAppend(initWith, moduleConfig.db);
		}


		Bolt().register("#this.path#.db", this.subsystem)
			.as("db@DBean")
			.withInitArg(name:"settings", value:initWith);
	
	}
}