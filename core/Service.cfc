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
	public boolean function save(any bean, boolean forceInsert=false){
		return db().save(arguments.bean, arguments.forceInsert);
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

	/**
	* @hint return a bean snapshot with an option to return specific columns you can pass in either a bean or a primary key value
	*/
	public struct function snapshot(any pk=0, string fields="*", struct fieldMapping={}){
		if(isSimpleValue(arguments.pk)){
			local.bean = bean(arguments.pk);
		}else{
			local.bean = arguments.pk;
		}
		return DB().representationOf(
			input: local.bean.snapshot(),
			limit: arguments.fields,
			mapping: arguments.fieldMapping,
			singleRow: true);
	}

	/**
	* @hint return a bean iterator
	*/
	public any function iterator(){
		if(!structKeyExists(arguments, "beanName")){
			arguments.beanName = variables._bean
		}
		return db().iterator(argumentCollection:arguments);
	}

	/**
	* @hint used to capture getBy[columnName] which can be used to get a bean using a specific column
	*/
	public any function onMissingMethod(string missingMethodName, struct missingMethodArguments){

		if(len(arguments.missingMethodName) GTE 6){
			local.param = mid(arguments.missingMethodName, 6, len(arguments.missingMethodName));
			local.fnc = left(arguments.missingMethodName, 5);
			switch(local.fnc){
				case "getBy":
					local.beanParams = {};
					local.beanParams[local.param] = arguments.missingMethodArguments.1;
					return bean(local.beanParams);
					break;
			}
		}
		
		throw(message="Method name '#arguments.missingMethodName#' is not defined", type="DB Service");
	}
}

