component accessors="true"{

	variables.instance = {};
	variables.instancePrev = {};
	variables.isDirty = false;
	variables.service = "";
	variables.linkedData = {}; // used to hold additional data associated with the bean
	variables.linkedSaveData = {}; // contains many-to-many updates to be saved
	

	/**
	* @hint constructor
	*/
	public function init(any beanConfig){
		variables.config = arguments.beanConfig;
		pop(data:variables.config.buildInstance(), dirty:false);
		return this;
	}

	/**
	* @hint returns our config object
	*/
	public struct function getConfig(){
		return variables.config;
	}

	/**
	* @hint returns our parent db object
	*/
	public any function db(){
		return variables.config.db();
	}

	/**
	* @hint returns a duplicate of our instance data
	*/
	public struct function getSnapShot(boolean isPrev=false){
		if(arguments.isPrev){
			return duplicate(variables.instancePrev);
		}else{
			return duplicate(variables.instance);
		}
	}

	/**
	* @hint returns our bean definition
	*/
	public string function getDefinition(){
		return variables.definition;
	}

	/**
	* @hint returns our primary key column name
	*/
	public string function getPK(){
		return variables.config.getPK();
	}

	/**
	* @hint returns beans ID using our primary key value
	*/
	public string function getID(){
		return variables.instance[getPK()];
	}
	
	/**
	* @hint sets our beans ID for our primary key column
	*/
	public string function setID(any id){
		return variables.instance[getPK()] = arguments.id;
		setDirty();
	}

	/**
	* @hint returns true if instance data has changed since it was populated
	*/
	public boolean function isDirty(){
		return variables.isDirty;
	}

	/**
	* @hint clears our dirty flag
	*/
	public void function clearDirty(){
		variables.isDirty = false;
	}

	/**
	* @hint sets our dirty flag
	*/
	public void function setDirty(){
		variables.isDirty = true;
	}
		
	/**
	* @hint gets an instance value
	*/
	public any function get(string key, boolean isPrev=false){
		
		local.variableName = "instance";
		if(arguments.isPrev){
			local.variableName = "instancePrev";
		}

		if(structKeyExists(variables[local.variableName], arguments.key)){
			return variables[local.variableName][arguments.key];
		}

		return null;
	}
	
	/**
	* @hint sets an instance value
	*/
	public void function set(string key, any value){
		
		if(variables.config.isColumnDefined(arguments.key)){
			variables.instance[arguments.key] = arguments.value;
			setDirty();
		}else{
			//throw(message="Key name '#arguments.key#' is not defined in this instance", type="DB Bean");
		}
	}
	

	/**
	* @hint used to capture get and set methods
	*/
	public any function onMissingMethod(string missingMethodName, struct missingMethodArguments){

		if(len(arguments.missingMethodName) GTE 4){
			local.param = mid(arguments.missingMethodName, 4, len(arguments.missingMethodName));
			local.fnc = left(arguments.missingMethodName, 3);
			switch(local.fnc){
				case "get":
					return get(local.param);
					break;
				case "set":
					return set(local.param, arguments.missingMethodArguments.1);
					break;
			}
		}
		
		throw(message="Method name '#arguments.missingMethodName#' is not defined", type="DB Bean");
	}

	/**
	* @hint populate an instance from either a query or a struct
	*/
	public void function pop(any data, numeric row=1, boolean dirty=true){
		if(isStruct(arguments.data)){
			for(local.col in arguments.data){
				set(local.col, arguments.data[local.col]);
			}
		}else if(isQuery(arguments.data)){
			local.dataColumns = listToArray(arguments.data.columnList);
			for(local.col in local.dataColumns){
				set(local.col, arguments.data[local.col][arguments.row]);
			}
		}
		if(!arguments.dirty){
			variables.instancePrev = duplicate(variables.instance);
			clearDirty();
			clearLinkedSaveData();
			clearLinkedData();
		}
	}

	/**
	* @hint clears a bean and resets to defaul values
	*/
	public void function reset(){
		variables.instance = {};
		variables.instancePrev = {};
		pop(data:variables.config.buildInstance(), dirty:false);
	}

	/**
	* @hint returns the root name of our bean
	*/
	public string function rootName(){
		local.root = listLast(getMetaData(this).name, ".");
		if(right(local.root, 4) IS "Bean"){
			local.root = mid(local.root, 1, len(local.root) - 4);
		}
		return local.root;
	}

	/**
	* @hint returns the contents of a linked data key
	*/
	public any function getLinked(string manyToManyName, boolean forceRead=false, string condition="", struct params={}){
		return variables.service.getLinked(this, arguments.manyToManyName, arguments.forceRead, arguments.condition, arguments.params);
	}


	/**
	* @hint returns true if a linked data key exists
	*/
	public any function isLinkedDataDefined(string key=""){
		return structKeyExists(variables.linkedData, arguments.key);
	}

	/**
	* @hint returns the contents of a linked data key
	*/
	public any function getLinkedData(string key=""){
		if(!len(arguments.key)){
			return variables.linkedData;
		}
		if(isLinkedDataDefined(arguments.key)){
			return variables.linkedData[arguments.key];
		}
		return false;
	}

	/**
	* @hint sets a value for a linked data key
	*/
	public void function setLinkedData(string key, any value){
		variables.linkedData[arguments.key] = arguments.value;
	}

	/**
	* @hint clears linked save data for either a given key or completely
	*/
	public void function clearLinkedData(string key=""){
		if(!len(arguments.key)){
			variables.linkedData = {};
		}else{
			structDelete(variables.linkedData, arguments.key);
		}
	}

	/**
	* @hint returns the contents of a linked save data key
	*/
	public any function getLinkedSaveData(string key=""){
		if(!len(arguments.key)){
			return variables.linkedSaveData;
		}
		if(structKeyExists(variables.linkedSaveData, arguments.key)){
			return variables.linkedSaveData[arguments.key];
		}
		return false;
	}

	/**
	* @hint sets a value for a linked save data key
	*/
	public void function setLinkedSaveData(string key, any value){
		variables.linkedSaveData[arguments.key] = arguments.value;
	}

	/**
	* @hint clears linked save data for either a given key or completely
	*/
	public void function clearLinkedSaveData(string key=""){
		if(!len(arguments.key)){
			variables.linkedSaveData = {};
		}else{
			structDelete(variables.linkedSaveData, arguments.key);
		}
	}

}