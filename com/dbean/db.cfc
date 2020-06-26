component{

	variables._settings = {
		"schemas": {},
		"schemaPath": getDefaultSchemaPath(),
		"modelPath": "/models/",
		"beanConfigPath": [
			"/models/beanConfigs/",
			"[model]"
		],
		"tablePrefix": "tbl_"
	};
	
	variables._schemas = {};
	variables._beanConfigs = {};

	/**
	* @hint constructor
	*/
	public function init(struct settings={}){
		structAppend(variables._settings, arguments.settings);
		return this;
	}

	public struct function getSettings(){
		return variables._settings;
	}

	/** 
	* @hint Returns the absolute path to a given cfc
	*/
	public string function getLocalPath(any o=this){
		local.path = listToArray(getMetaData(arguments.o).path, "\");
		arrayDeleteAt(local.path, arrayLen(local.path)); // remove file name
		return arrayToList(local.path, "\") & "\";
	}

	/**
	* @hint converts a given path into dot notation from the site root
	*/
	public string function getDotPath(string path){
		local.rootPath = expandPath("/");
		if(!arguments.path CONTAINS ":"){
			arguments.path = expandPath(arguments.path);
		}
		local.relativePath = replaceNoCase(arguments.path, local.rootPath, "");
		local.relativePath = replaceNoCase(local.relativePath, "\", "/", "ALL");
		local.relativePath = replaceNoCase(local.relativePath, "//", "/", "ALL");
		local.dotPath = replaceNoCase(local.relativePath, "/", ".", "ALL");
		if(right(local.dotPath, 1) IS "."){
			local.dotPath = mid(local.dotPath, 1, len(local.dotPath)-1);
		}
		return local.dotPath;
	}

	/**
	* @hint returns a setting value
	*/
	public any function getSetting(string settingName){
		return variables._settings[arguments.settingName];
	}

	
	/**
	* @hint returns a table schema definition if it exists
	*/
	public any function getTableSchema(string table, string schemaName="default"){
		return getSchema(arguments.schemaName).tables[arguments.table];
	}


	/**
	* @hint parses a beanName string to split into the bean name and its schema
	*/
	public struct function parseBeanName(string beanName){
		local.ret = {
			schema: "default",
			beanName: arguments.beanName
		};
		if(listLen(arguments.beanName, ".") GT 1){
			local.ret.schema = listFirst(arguments.beanName, ".");
			local.ret.beanName = listLast(arguments.beanName, ".");
		}
		return local.ret;
	}


	/**
	* @hint returns a gateway object
	*/
	public any function gateway(string schema="default"){
		return getSchema(arguments.schema).gateway;
	}

	/**
	* @hint returns a bean iterator object
	*/
	public any function iterator(
		string beanName,
		string where="",
		any params={},
		string orderBy="",
		numeric limit=0,
		numeric limitOffset=0,
		boolean withTotal=false,
		any data){
		local.args = arguments;
		local.args.dbObject = this;
		return new core.Iterator(argumentCollection: local.args);
	}

	
	/**
	* @hint returns a bean object
	*/
	public any function bean(string beanName, any pkValue=0){
		local.beanInfo = parseBeanName(arguments.beanName);
		local.beanConfig = getBeanConfig(local.beanInfo.beanName, local.beanInfo.schema);
		local.bean = new core.Bean(local.beanConfig);
		
		if(arguments.pkValue NEQ 0){
			local.qData = gateway(local.beanInfo.schema).getBean(local.beanInfo.beanName, arguments.pkValue);
			if(local.qData.recordCount){
				local.bean.pop(local.qData);
			}
		}
		return local.bean;
	}

	/**
	* @hint proxy for our bean save method
	*/
	public boolean function save(any bean){
		return arguments.bean.save();
	}

	/**
	* @hint proxy for our bean delete method
	*/
	public boolean function delete(any bean){
		return arguments.bean.delete();	
	}

	
	// Schema
	// ======================================================
	/** 
	* @hint Returns path to the default schema storage location
	*/
	public string function getDefaultSchemaPath(){
		return getLocalPath() & "schemas\";
	}

	/**
	* @hint returns a database schema for a given schema alias name
	*/
	public any function getSchema(string schemaName="default", boolean rebuild=false){
		if(!arguments.rebuild && structKeyExists(variables._schemas, arguments.schemaName)){
			return variables._schemas[arguments.schemaName];
		}else{
			if(!arguments.rebuild && readSchema(arguments.schemaName)){
				return variables._schemas[arguments.schemaName];
			}else{
				// attempt to build our schema
				if(structKeyExists(getSetting("schemas"), arguments.schemaName)){
					//local.dsns = getDSNNames();
					local.schemaDSN = getSetting("schemas")[arguments.schemaName];
					//for(local.dsn in local.dsns){
					//	if(local.dsn IS local.schemaDSN ){
							//buildSchema(local.dsn, arguments.schemaName);
							buildSchema(local.schemaDSN, arguments.schemaName);
							if(readSchema(arguments.schemaName)){
								return variables._schemas[arguments.schemaName];
							}else{
								throw("Schema '#arguments.schemaName#' could not be built", "dbean.db");
							}
					//	}
					//}
					//throw("Schema '#arguments.schemaName#' dsn not found", "dbean.db");
				}
				throw("Schema '#arguments.schemaName#' not defined", "dbean.db");
			}
		}
	}

	/**
	* @hint rebuilds a schema and flushes our bean cache
	*/
	public void function flushSchema(string schemaName="default"){
		getSchema(arguments.schemaName, true);
		variables._beanConfigs[arguments.schemaName] = {};
	}

	/**
	* @hint returns a application defined datasources
	*/
	public struct function getDatasources(){
		local.app = getApplicationMetadata();
		if(structKeyExists(local.app, "datasources")){
			return local.app.datasources;
		}
		return {};
	}

	/**
	* @hint returns an array of application defined datasource names
	*/
	public array function getDSNNames(){
		return structKeyArray(getDatasources());
	}

	/**
	* @hint builds a configuration file for a given DSN and schema alias name
	*/
	public function buildSchema(string dsn, string schemaName="default"){
		local.inspector = new core.Inspector();
		local.schema = local.inspector.buildSchema(arguments.dsn, arguments.schemaName);
		fileWrite(getSchemaAbsolutePath(arguments.schemaName), local.schema);
	}


	/**
	* @hint reads a schema configuration file and adds it to our local cache for a given schema alias name
	*/
	public boolean function readSchema(string schemaName="default"){
		local.schemaCFCPath = getSchemaAbsolutePath(arguments.schemaName);
		if(fileExists(local.schemaCFCPath)){
			local.cfcDotPath = getSchemaDotPath(arguments.schemaName);
			local.schemaConfig = new "#local.cfcDotPath#"().schema;
			variables._schemas[arguments.schemaName] = local.schemaConfig;
			variables._schemas[arguments.schemaName].path = local.cfcDotPath;
			variables._schemas[arguments.schemaName].fullPath = local.schemaCFCPath;
			variables._schemas[arguments.schemaName].gateway = new core.Gateway(local.schemaConfig, this);
			return true;
		}
		return false;
	}

	/**
	* @hint returns the absolute path to a schema config file
	*/
	public string function getSchemaAbsolutePath(string schemaName="default"){
		local.schemaPath = getSetting("schemaPath");
		if(!local.schemaPath CONTAINS ":"){
			local.schemaPath = expandPath(local.schemaPath);
		}
		return local.schemaPath & "db-" & arguments.schemaName & ".cfc";
	}

	/**
	* @hint returns the dot path to a schema config file
	*/
	public string function getSchemaDotPath(string schemaName="default"){
		return "#getDotPath(getSetting("schemaPath"))#.db-#arguments.schemaName#";
	}


	// Bean Config
	// ======================================================
	/**
	* @hint returns the dot path to a schema config file
	*/
	public any function getBeanConfig(string beanName, string schema="default"){
		if(structKeyExists(variables._beanConfigs, arguments.schema) 
			AND structKeyExists(variables._beanConfigs[arguments.schema], arguments.beanName)){
			// cached config reader
			return variables._beanConfigs[arguments.schema][arguments.beanName];
		}
		// we need a new config reader
		local.beanConfig = new core.ConfigReader(arguments.beanName, this, arguments.schema);
		if(arguments.schema IS local.beanConfig.schema()){
			variables._beanConfigs[local.beanConfig.schema()][arguments.beanName] = local.beanConfig;
			return variables._beanConfigs[arguments.schema][arguments.beanName];
		}else{
			throw("Unmatched schema for '#arguments.beanName#'. '#local.beanConfig.schema()#' does not match '#arguments.schema#'", "dbean.db");
		}
	}


}