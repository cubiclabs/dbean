component accessors="true"{

	variables._config = "";
	variables._instance = {};
	variables._instancePrev = {};
	variables._isDirty = false;
	variables._linkedData = {}; // used to hold additional data associated with the bean
	variables._linkedSaveData = {}; // contains many-to-many updates to be saved
	

	/**
	* @hint constructor
	*/
	public function init(any beanConfig){
		variables._config = arguments.beanConfig;
		pop(data:config().buildInstance(), dirty:false);
		return this;
	}

	/**
	* @hint returns our config object
	*/
	public struct function config(){
		return variables._config;
	}

	/**
	* @hint returns our parent db object
	*/
	public any function db(){
		return config().db();
	}

	/**
	* @hint returns a duplicate of our instance data
	*/
	public struct function snapShot(boolean isPrev=false){
		if(arguments.isPrev){
			return duplicate(variables._instancePrev);
		}else{
			return duplicate(variables._instance);
		}
	}

	/**
	* @hint returns our bean name
	*/
	public string function name(){
		return config().getBeanName();
	}

	/**
	* @hint returns a gateway for our bean
	*/
	public any function gateway(){
		return db().gateway(config().schema());
	}

	/**
	* @hint returns our primary key column name
	*/
	public string function PK(){
		return config().getPK();
	}

	/**
	* @hint returns beans ID using our primary key value
	*/
	public string function getID(){
		return variables._instance[PK()];
	}
	
	/**
	* @hint sets our beans ID for our primary key column
	*/
	public string function setID(any id){
		return variables._instance[PK()] = arguments.id;
		setDirty();
	}

	/**
	* @hint returns true if instance data has changed since it was populated
	*/
	public boolean function isDirty(){
		return variables._isDirty;
	}

	/**
	* @hint clears our dirty flag
	*/
	public void function clearDirty(){
		variables._isDirty = false;
	}

	/**
	* @hint sets our dirty flag
	*/
	public void function setDirty(){
		variables._isDirty = true;
	}
	
	/**
	* @hint save our bean to the database
	*/
	public boolean function save(){

		if(getID()){
			// UPDATE
			local.dec = gateway().updateBean(name());
			setBeanDeclarationParamters(local.dec, "update");

			// TODO: special columns

			local.dec.where(PK() & "= :pk")
				.withParam("pk", getID())
				.go();

		}else{
			// INSERT
			local.dec = gateway().insertBean(name());
			setBeanDeclarationParamters(local.dec, "insert");

			// TODO: special columns

			local.result = local.dec.go();
			local.id = gateway().getInsertID(local.result);
			setID(local.id);
		}

		// check for many-to-many data
		saveLinkedData();
		
		return true;
	}

	/**
	* @hint set query declaration parameters, checking for special columns as we go
	*/
	public void function setBeanDeclarationParamters(any dec, string type=""){
		for(local.col in config().columns()){
			if(!structKeyExists(local.col, "pk") OR !local.col.pk){

				// check for 'special' column
				local.addCol = true;
				local.colVal = get(local.col.name);

				if(config().isSpecialColumn(local.col.name)){
					local.special = config().getSpecialColumn(local.col.name);
					if(structKeyExists(local.special, arguments.type)){
						local.instruction = local.special[arguments.type];
						if(!local.instruction){
							local.addCol = false;
						}
					}
					if(structKeyExists(local.special, arguments.type & "Value")){
						local.specialVal = local.special[arguments.type & "Value"];
						if(isCustomFunction(local.specialVal)){
							local.colVal = local.specialVal(this);
						}else{
							local.colVal = local.specialVal;
						}
					}
				}

				if(local.addCol){
					arguments.dec.set(local.col.name, local.colVal);
				}
			}
		}
	}


	/**
	* @hint deletes our bean from the database
	*/
	public boolean function delete(){
		if(getID()){
			gateway().deleteBean(name())
				.where(PK() & "= :pk")
				.withParam("pk", getID())
				.go();

			// TODO: check for many-to-many data

			return true;
		}else{
			return false;
		}
	}
	

	/**
	* @hint gets an instance value
	*/
	public any function get(string key, boolean isPrev=false){
		
		local.variableName = "_instance";
		if(arguments.isPrev){
			local.variableName = "_instancePrev";
		}

		if(structKeyExists(variables[local.variableName], arguments.key)){
			return variables[local.variableName][arguments.key];
		}

		return;
	}
	
	/**
	* @hint sets an instance value
	*/
	public void function set(string key, any value){
		
		if(config().isColumnDefined(arguments.key)){
			variables._instance[arguments.key] = arguments.value;
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
			variables._instancePrev = duplicate(variables._instance);
			clearDirty();
			clearLinkedSaveData();
			clearLinkedData();
		}
	}

	/**
	* @hint clears a bean and resets to defaul values
	*/
	public void function reset(){
		variables._instance = {};
		variables._instancePrev = {};
		pop(data:config().buildInstance(), dirty:false);
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
	* @hint returns linked data
	*/
	public any function getLinked(string manyToManyName, boolean forceRead=false, string condition="", struct params={}){
		local.linkedConfig = config().getManyToMany(arguments.manyToManyName);
		if(isBoolean(local.linkedConfig)){
			throw(message="Many To Many relationship '#arguments.manyToManyName#' is not defined in bean '#name()#'", type="dbean.bean");
		}

		if(isLinkedDataDefined(arguments.manyToManyName) AND !arguments.forceRead){
			return getLinkedData(arguments.manyToManyName);
		}

		local.relatedModel = db().getBeanConfig(local.linkedConfig.model);
		local.relatedPK = local.relatedModel.getPK();
		
		// query parameters
		local.params = {
			FK1: {
				value: getID(),
				cfsqltype: config().getConfig().pk.cfSQLDataType
			}
		}

		if(!structKeyExists(local.linkedConfig, "FK1")){
			local.linkedConfig.FK1 = replaceNoCase(PK(), "_id", "ID");
		}
		if(!structKeyExists(local.linkedConfig, "FK2")){
			local.linkedConfig.FK2 = replaceNoCase(local.relatedPK, "_id", "ID");
		}

		// build our query
		local.dec = gateway().fromBean(local.relatedModel.getBeanName());
		local.where = "#local.relatedPK# IN (SELECT #local.linkedConfig.FK2# FROM #local.linkedConfig.intermediary# WHERE #local.linkedConfig.FK1# = :FK1)";
		if(len(arguments.condition)){
			local.where = local.where & " AND " & arguments.condition;
		}
		local.dec.where(local.where);

		// merge params
		structAppend(local.params, arguments.params);
		local.dec.withParams(local.params);

		// order
		if(structKeyExists(local.linkedConfig, "order")){
			local.dec.orderBy(local.linkedConfig.order);
		}

		// execute our query
		local.q = local.dec.get();

		// save data into our bean
		setLinkedData(arguments.manyToManyName, local.q);

		return getLinkedData(arguments.manyToManyName);
	}

	/**
	* @hint save any linked data within our bean
	*/
	public any function saveLinkedData(){
		local.linkedDataToSave = getLinkedSaveData();
		for(local.linkedKey in local.linkedDataToSave){

			local.linkedConfig = config().getManyToMany(local.linkedKey);
			if(isStruct(local.linkedConfig)){
				local.linkedData = local.linkedDataToSave[local.linkedKey];

				local.relatedModel = db().getBeanConfig(local.linkedConfig.model);
				local.relatedPK = local.relatedModel.getPK();
				
				if(!structKeyExists(local.linkedConfig, "FK1")){
					local.linkedConfig.FK1 = replaceNoCase(PK(), "_id", "ID");
				}
				if(!structKeyExists(local.linkedConfig, "FK2")){
					local.linkedConfig.FK2 = replaceNoCase(local.relatedPK, "_id", "ID");
				}

				local.params = {
					FK1: {
						value: getID(),
						cfsqltype: config().getConfig().pk.cfSQLDataType
					}
				}

				local.sqlDELETE = "DELETE FROM #local.linkedConfig.intermediary# 
					WHERE #local.linkedConfig.FK1# = :FK1 ;";
				local.sqlINSERT = "";
				if(arrayLen(local.linkedData)){
					local.sqlINSERT = "INSERT INTO #local.linkedConfig.intermediary# (#local.linkedConfig.FK1#, #local.linkedConfig.FK2#) 
						SELECT :FK1 AS #local.linkedConfig.FK1#, #local.relatedPK# 
						FROM #local.relatedModel.table()# 
						WHERE #local.relatedPK# IN (:linked);";
					local.params.linked = {
						value: arrayToList(local.linkedData),
						cfsqltype: local.relatedModel.getConfig().pk.cfSQLDataType,
						list: true
					}
				}

				gateway().runQuery(local.sqlDELETE & chr(13) & chr(10) & local.sqlINSERT, local.params);
			}
		}
	}


	/**
	* @hint returns true if a linked data key exists
	*/
	public any function isLinkedDataDefined(string key=""){
		return structKeyExists(variables._linkedData, arguments.key);
	}

	/**
	* @hint returns the contents of a linked data key
	*/
	public any function getLinkedData(string key=""){
		if(!len(arguments.key)){
			return variables._linkedData;
		}
		if(isLinkedDataDefined(arguments.key)){
			return variables._linkedData[arguments.key];
		}
		return false;
	}

	/**
	* @hint sets a value for a linked data key
	*/
	public void function setLinkedData(string key, any value){
		variables._linkedData[arguments.key] = arguments.value;
	}

	/**
	* @hint clears linked save data for either a given key or completely
	*/
	public void function clearLinkedData(string key=""){
		if(!len(arguments.key)){
			variables._linkedData = {};
		}else{
			structDelete(variables._linkedData, arguments.key);
		}
	}

	/**
	* @hint returns the contents of a linked save data key
	*/
	public any function getLinkedSaveData(string key=""){
		if(!len(arguments.key)){
			return variables._linkedSaveData;
		}
		if(structKeyExists(variables._linkedSaveData, arguments.key)){
			return variables._linkedSaveData[arguments.key];
		}
		return false;
	}

	/**
	* @hint sets a value for a linked save data key
	*/
	public void function setLinked(string manyToManyName, any value){
		variables._linkedSaveData[arguments.manyToManyName] = arguments.value;
	}

	/**
	* @hint clears linked save data for either a given key or completely
	*/
	public void function clearLinkedSaveData(string key=""){
		if(!len(arguments.key)){
			variables._linkedSaveData = {};
		}else{
			structDelete(variables._linkedSaveData, arguments.key);
		}
	}

	/**
	* @hint builds a default SELECT statement based on our bean config
	*/
	public string function tableSelect(){
		if(structKeyExists(variables, "tableSelectString")){
			return variables.tableSelectString;
		}

		local.tableString = config().table();
		for(local.join in config().joins()){
			local.joinType = "LEFT OUTER";
			if(structKeyExists(local.join, "joinType")){
				local.joinType = local.join.joinType;
			}
			if(structKeyExists(local.join, "condition")){
				local.tableString = local.tableString & " #local.joinType# JOIN #local.join.table# ON #local.join.condition# ";
			}else{
				local.joinFromTable = config().table();
				local.joinFromCol = local.join.from;
				if(listLen(local.joinFromCol, ".") EQ 2){
					local.joinFromTable = listFirst(local.joinFromCol, ".");
					local.joinFromCol = listLast(local.joinFromCol, ".");
				}
				local.tableString = local.tableString & " #local.joinType# JOIN #local.join.table# ON #local.join.table#.#local.join.on# = #local.joinFromTable#.#local.joinFromCol# ";
			}
		}

		// cache this
		variables.tableSelectString = local.tableString;

		return local.tableString;
	}

}