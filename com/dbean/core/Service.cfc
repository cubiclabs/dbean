component{

	variables._db = "";
	variables._schema = "default";
	variables._bean = "";
	
	/**
	* @hint constructor
	*/
	public function init(any db){
		variables._db = arguments.db;
		return this;
	}

	/**
	* @hint returns our db object
	*/
	public any function db(){
		return variables._db;
	}

	/**
	* @hint returns a gateway object for our schema
	*/
	public any function gateway(string schema=variables._schema){
		return db().gateway(arguments.schema);
	}


	/**
	* @hint bean helper function
	*/
	public any function bean(numeric pk=0, any params={}, string beanName=variables._bean){
		local.schemaBeanName = variables._schema & "." & arguments.beanName;

		local.args = {
			beanName: local.schemaBeanName,
			pkValue: arguments.pk,
			params: arguments.params
		};

		return db().bean(argumentCollection:local.args);
	}

}

