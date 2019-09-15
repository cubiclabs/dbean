component{

	variables._beanName = "";
	variables._config = {};
	variables._schema = "";

	/**
	* @hint constructor
	*/
	public function init(string beanName, any db, string schema="default"){
		variables.db = arguments.db;
		variables._schema = arguments.schema;
		setBeanName(arguments.beanName);
		readConfig();
		return this;
	}

	public any function db(){
		return variables.db;
	}
	

	public void function setBeanName(string beanName){
		local.root = arguments.beanName;
		if(right(local.root, 4) IS "Bean"){
			local.root = mid(local.root, 1, len(local.root) - 4);
		}else{
			local.r7 = right(local.root, 7);
			if(local.r7 IS "Gateway" OR local.r7 IS "Service"){
				local.root = mid(local.root, 1, len(local.root) - 7);
			}
		}
		variables._beanName = local.root;
	}



	public function getConfigObject(){

		// scan our paths
		local.beanPaths = variables.db.getSetting("beanConfigPath");
		if(!isArray(local.beanPaths)){
			local.beanPaths = listToArray(local.beanPaths);
		}

		local.modelPaths = variables.db.getSetting("modelPath");
		if(!isArray(local.modelPaths)){
			local.modelPaths = listToArray(local.modelPaths);
		}

		for(local.beanPath in local.beanPaths){
			if(local.beanPath IS "[model]"){
				// config is stored within model directory

				for(local.modelPath in local.modelPaths){
					local.fullModelPath = expandPath(local.modelPath);
					if(fileExists(local.fullModelPath & variables._beanName & "\" & variables._beanName & "Config.cfc")){
						local.configPath = variables.db.getDotPath(local.modelPath) & "." & variables._beanName & "." & variables._beanName & "Config";
						local.oConfig = new "#local.configPath#"();
						if(isMatchedSchema(local.oConfig)){
							return local.oConfig;
						}
					}
				}

				
			}else{
				// configs are stored together in a single directory
				local.fullConfigPath = expandPath(local.beanPath);
				if(fileExists(local.fullConfigPath & variables._beanName &".cfc")){
					local.configPath = variables.db.getDotPath(local.beanPath) & "." & variables._beanName;
					local.oConfig = new "#local.configPath#"();
					if(isMatchedSchema(local.oConfig)){
						return local.oConfig;
					}
				}
			}	
		}

		throw("Config not found for bean '#variables._beanName#' using schema '#variables._schema#'.", "dbean.core.configreader");
	}

	public boolean function isMatchedSchema(any oConfig){
		local.config = arguments.oConfig.definition;

		if(!structKeyExists(local.config, "schema")){
			local.config.schema = "default";
		}

		if(local.config.schema IS variables._schema){
			return true;
		}

		return false;
	}

	public void function readConfig(){
		
		variables._configObject = getConfigObject();
		variables._config = variables._configObject.definition;

		// set our default schema if one is not defined
		if(!structKeyExists(variables._config, "schema")){
			variables._config.schema = "default";	
		}

		// set our default table if one is not defined
		if(!structKeyExists(variables._config, "table")){
			variables._config.table = "#variables.db.getSetting("tablePrefix")##variables._beanName#";
		}
		
		// find our table columns and flavour and dsn from our schema definition
		local.table = variables.db.getTableSchema(variables._config.table, variables._config.schema);
		local.schema = variables.db.getSchema(variables._config.schema);
		
		structAppend(variables._config, local.table);
		variables._config.dsn = local.schema.dsn;
		variables._config.flavour = local.schema.flavour;

		variables._config.colList = "";
		variables._config.hasPK = false;
		variables._config.colHash = {};
		for(local.col in variables._config.cols){
			variables._config.colList = listAppend(variables._config.colList, local.col.name);
			variables._config.colHash[local.col.name] = local.col;
			if(structKeyExists(local.col, "pk") AND local.col.pk){
				variables._config.pk = local.col;
				variables._config.hasPK = true;
			}
		}

		// joins
		variables._config.joinColList = "";
		variables._config.joinCols = [];
		if(structKeyExists(variables._config, "joins")){
			for(local.join in variables._config.joins){
				variables._config.joinColList = listAppend(variables._config.joinColList, local.join.cols);
			}
			local.tempJoinCols = listToArray(variables._config.joinColList);
			for(local.joinCol in local.tempJoinCols){
				local.joinCol = replaceNoCase(local.joinCol, " AS ", "~");
				local.joinCol = trim(listLast(local.joinCol, "~"));
				arrayAppend(variables._config.joinCols, local.joinCol);
				variables._config.colHash[local.joinCol] = "JOIN";
			}
		}
	}

	public struct function buildInstance(){
		local.inst = {};
		for(local.col in variables._config.cols){
			local.inst[local.col.name] = local.col.default;
			// check for default date value
			if(isDate(local.col.default) AND local.col.cfDataType IS "date"){
				local.inst[local.col.name] = now();
			}
		}
		for(local.joinCol in variables._config.joinCols){
			local.inst[local.joinCol] = "";
		}
		return local.inst;
	}

	public any function getConfig(){
		return variables._config;
	}

	public any function columnList(){
		if(len(variables._config.joinColList)){
			return listAppend(variables._config.colList, variables._config.joinColList);
		}
		return variables._config.colList;
	}

	public any function columns(){
		return variables._config.cols;
	}

	public any function joins(){
		if(structKeyExists(variables._config, "joins")){
			return variables._config.joins;
		}
		return [];
	}

	public any function manyToMany(){
		if(structKeyExists(variables._config, "manyTomany")){
			return variables._config.manyTomany;
		}
		return [];
	}

	public any function getManyToMany(string name){
		local.def = manyToMany();
		for(local.manyInfo in local.def){
			if(local.manyInfo.name IS arguments.name){
				return local.manyInfo;
			}
		}
		return false;
	}

	public any function table(){
		return variables._config.table;
	}

	public any function schema(){
		return variables._config.schema;
	}

	public struct function getColumn(string colName){
		return variables._config.colHash[arguments.colName]
	}

	public boolean function isColumnDefined(string colName){
		return structKeyExists(variables._config.colHash, arguments.colName);
	}

	public string function getPK(){
		if(variables._config.hasPK){
			return variables._config.pk.name
		}
		return "";
	}

}