component{

	variables._settings = {
		"schemas": {},
		"schemaPath": getDefaultSchemaPath(),
		"modelPath": "/models/",
		"beanConfigPath": "/models/beanConfigs/",
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
		local.relativePath = replaceNoCase(expandPath(arguments.path), local.rootPath, "");
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
	* @hint parses a model string to split into the model name and its namespace
	*/
	public struct function parseModelNamespace(string model){
		local.model = {
			name: listFirst(arguments.model, "@"),
			namespace: "model"
		}
		if(listLen(arguments.model, "@") GT 1){
			local.model.namespace = listLast(arguments.model, "@");
		}
		return local.model;
	}


	/**
	* @hint returns a gateway object
	*/
	public any function gateway(string model){
		local.model = parseModelNamespace(arguments.model);
		return Bolt().getObject("#local.model.name#Gateway@#local.model.namespace#", {db:this});
	}

	/**
	* @hint returns a service object
	*/
	public any function service(string model){
		local.model = parseModelNamespace(arguments.model);
		return Bolt().getObject("#local.model.name#Service@#local.model.namespace#", {db:this});
	}

	/**
	* @hint returns a bean object
	*/
	public any function bean(string beanName, any pkValue=0){
		local.schema = "default";
		if(listlen(arguments.beanName, ".") EQ 2){
			local.schema = listFirst(arguments.beanName, ".");
			arguments.beanName = listLast(arguments.beanName, ".");
		}
		local.beanConfig = getBeanConfig(arguments.beanName, local.schema);
		local.bean = new core.Bean(local.beanConfig);
		// set our service and gateway for our bean

		if(arguments.pkValue NEQ 0){
			local.qData = gateway(arguments.model).get(arguments.pkValue);
			if(local.qData.recordCount){
				local.bean.pop(local.qData);
			}
		}
		return local.bean;
	}

	/**
	* @hint proxy for our service save method
	*/
	public any function save(any bean){
		return service(arguments.bean.rootName()).save(arguments.bean);
	}

	/**
	* @hint proxy for our service delete method
	*/
	public any function delete(any bean){
		return service(arguments.bean.rootName()).delete(arguments.bean);	
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
	public any function getSchema(string schemaName="default"){
		if(structKeyExists(variables._schemas, arguments.schemaName)){
			return variables._schemas[arguments.schemaName];
		}else{
			if(readSchema(arguments.schemaName)){
				return variables._schemas[arguments.schemaName];
			}else{
				// attempt to build our schema
				if(structKeyExists(getSetting("schemas"), arguments.schemaName)){
					local.dsns = getDSNNames();
					local.schemaDSN = getSetting("schemas")[arguments.schemaName];
					for(local.dsn in local.dsns){
						if(local.dsn IS local.schemaDSN ){
							buildSchema(local.dsn, arguments.schemaName);
							if(readSchema(arguments.schemaName)){
								return variables._schemas[arguments.schemaName];
							}else{
								throw("Schema '#arguments.schemaName#' could not be built", "dbean.db");
							}
						}
					}
					throw("Schema '#arguments.schemaName#' dsn not found", "dbean.db");
				}
				throw("Schema '#arguments.schemaName#' not defined", "dbean.db");
			}
		}
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
			variables._schemas[arguments.schemaName] = new "#local.cfcDotPath#"().schema;
			variables._schemas[arguments.schemaName].path = local.cfcDotPath;
			variables._schemas[arguments.schemaName].fullPath = local.schemaCFCPath;
			return true;
		}
		return false;
	}

	/**
	* @hint returns the absolute path to a schema config file
	*/
	public string function getSchemaAbsolutePath(string schemaName="default"){
		return expandPath(getSetting("schemaPath")) & "db-" & arguments.schemaName & ".cfc";
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