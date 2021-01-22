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
	* @hint proxy for our bean save method
	*/
	public boolean function save(any bean){
		return db().save(arguments.bean);
	}

	/**
	* @hint proxy for our bean delete method
	*/
	public boolean function delete(any bean){
		return db().delete(arguments.bean);	
	}


	/**
	* @hint bean helper function
	*/
	public any function bean(any pk=0, any params={}, string beanName=variables._bean){
		local.schemaBeanName = variables._schema & "." & arguments.beanName;

		local.args = {
			beanName: local.schemaBeanName,
			pkValue: arguments.pk,
			params: arguments.params
		};

		return db().bean(argumentCollection:local.args);
	}

}

