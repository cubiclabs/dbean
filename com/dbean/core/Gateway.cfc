component{

	variables._schema = {};
	

	/**
	* @hint constructor
	*/
	public function init(struct schema, any db){
		variables._db = arguments.db;
		variables._schema = arguments.schema;
		return this;
	}

	public any function schema(){
		return variables._schema;
	}

	public any function schemaName(){
		return schema().schemaName;
	}

	public string function DSN(){
		return schema().dsn;
	}

	public string function flavour(){
		return schema().flavour;
	}

	public any function db(){
		return variables._db;
	}

	public any function SQLWriter(){
		if(!structKeyExists(variables, "_SQLWriter")){
			local.type = "baseSQL";
			if(len(flavour())){
				local.type = flavour();
			}
			variables._SQLWriter = createObject("component", "flavour.#local.type#").init(schema());
		}
		return variables._SQLWriter;
	}

	public query function getBean(string beanName, any pkValue=0, any params={}){
		local.beanConfig = db().getBeanConfig(arguments.beanName, schemaName());

		if(isNumeric(arguments.pkValue)){
			local.where = local.beanConfig.getPK(true) & "= :pk";
			local.params = {
				pk: arguments.pkValue
			};
		}else if(isStruct(arguments.pkValue)){
			// we are expecting key value pairs where the key is a column and the value is the value to match
			local.where = [];
			for(local.col in structKeyArray(arguments.pkValue)){
				arrayAppend(local.where, "#local.col# = :#local.col#");
				arguments.params[local.col] = arguments.pkValue[local.col];
			}
			local.where = arrayToList(local.where, " AND ");
			local.params = arguments.params;
		}else{
			local.where = arguments.pkValue;
			local.params = arguments.params;
		}

		return fromBean(arguments.beanName)
			.where(local.where)
			.withParams(local.params)
			.get();
	}

	public query function getAll(string beanName){
		local.dec = fromBean(arguments.beanName);
		return local.dec.get();
	}

	/**
	* @hint SELECT query syntax DSL
	*/
	public struct function fromBean(string beanName){
		return from(arguments.beanName, true);
	}
	

	/**
	* @hint SELECT query syntax DSL
	*/
	public struct function from(string tableName, boolean isBean=false){
		local.cols = "*";
		local.beanConfig = "";
		if(arguments.isBean){
			local.beanConfig = db().getBeanConfig(arguments.tableName, schemaName());
			local.cols = local.beanConfig.columnList();
			arguments.tableName = SQLWriter().tableSelect(local.beanConfig);
		}

		var declaration = {
			q: {
				beanConfig: local.beanConfig,
				type: "SELECT",
				tableName: arguments.tableName,
				where: "",
				params: {},
				joins: [],
				cols: local.cols,
				orderBy: "",
				limit: 0,
				offset: 0,
				withTotal: false,
				options: {
					dsn: DSN()
				}
			}
		};

		var dsl = {
			select: function(string cols){
				declaration.q.cols = arguments.cols;
				return declaration;
			},
			where: function(string whereClause){
				declaration.q.where = arguments.whereClause;
				return declaration;
			},
			withParams: function(any params){
				declaration.q.params = arguments.params;
				return declaration;
			},
			withParam: function(string paramName, any paramValue, struct paramOptions={}){
				arguments.paramOptions.value = arguments.paramValue;
				declaration.q.params[arguments.paramName] = arguments.paramOptions;
				return declaration;
			},
			orderBy: function(string orderBy){
				declaration.q.orderBy = arguments.orderBy;
				return declaration;
			},
			limit: function(numeric limitRows, numeric offset=0, boolean withTotal=false){
				declaration.q.limit = arguments.limitRows;
				declaration.q.offset = arguments.offset;
				declaration.q.withTotal = arguments.withTotal;
				return declaration;
			},
			using: function(string dsn){
				declaration.q.options.datasource = arguments.dsn;
				return declaration;
			},
			cacheFor: function(numeric cacheLength){
				declaration.q.options.cachedWithin = arguments.cacheLength;
				return declaration;
			},
			usingBeanConfig: function(any beanConfig){
				declaration.q.beanConfig = arguments.beanConfig;
				return declaration;
			},
			get: function(string cols="", struct options={}){
				structAppend(declaration.q.options, arguments.options);
				if(len(arguments.cols)){
					declaration.q.cols = arguments.cols;
				}
				return execute(declaration).q;
			}
		};

		structAppend(declaration, dsl);

		return declaration;
	}

	/**
	* @hint UPDATE query syntax DSL for a given bean name
	*/
	public struct function updateBean(string beanName){
		return update(arguments.beanName, true);
	}

	/**
	* @hint UPDATE query syntax DSL
	*/
	public struct function update(string tableName, boolean isBean=false){
		var beanConfig = "";
		var hasBeanConfig = false;
		if(arguments.isBean){
			local.beanConfig = db().getBeanConfig(arguments.tableName, schemaName());
			arguments.tableName = local.beanConfig.table();
			hasBeanConfig = true;
		}

		var declaration = {
			q: {
				beanConfig: beanConfig,
				type: "UPDATE",
				tableName: arguments.tableName,
				where: "",
				params: {},
				cols: [],
				options: {
					dsn: DSN()
				}
			}
		};

		var dsl = {
			set: function(string col, any value, any param=""){
				arrayAppend(declaration.q["cols"], {
					name: arguments.col,
					value: arguments.value
				});
				
				local.null = false;
				if(!len(arguments.value) AND hasBeanConfig AND beanConfig.isColumnDefined(arguments.col)){
					if(beanConfig.getColumn(arguments.col).isNullable){
						local.null = true;
					}
				}

				if(isStruct(arguments.param)){
					arguments.param.value = arguments.value;
					if(!structKeyExists(arguments.param, "null")){
						arguments.param.null = local.null;
					}
					arguments.param.value = local.null;
					declaration.q.params[arguments.col] = arguments.param;
				}else{
					declaration.q.params[arguments.col] = {
						value: arguments.value,
						null: local.null
					};
				}
				return declaration;
			},
			where: function(string whereClause){
				declaration.q.where = arguments.whereClause;
				return declaration;
			},
			withParam: function(string paramName, any paramValue, struct paramOptions={}){
				arguments.paramOptions.value = arguments.paramValue;
				declaration.q.params[arguments.paramName] = arguments.paramOptions;
				return declaration;
			},
			go: function(){
				return execute(declaration);
			}
		};

		structAppend(declaration, dsl);

		return declaration;
	}

	/**
	* @hint INSERT query syntax DSL for a given bean name
	*/
	public struct function insertBean(string beanName){
		return this.insert(arguments.beanName, true);
	}

	/**
	* @hint INSERT query syntax DSL
	*/
	public struct function insert(string tableName, boolean isBean=false){
		var beanConfig = "";
		var hasBeanConfig = false;
		if(arguments.isBean){
			local.beanConfig = db().getBeanConfig(arguments.tableName, schemaName());
			local.cols = local.beanConfig.columnList();
			arguments.tableName = local.beanConfig.table();
			hasBeanConfig = true;
		}

		var declaration = {
			q: {
				beanConfig: beanConfig,
				type: "INSERT",
				tableName: arguments.tableName,
				params: {},
				cols: [],
				options: {
					dsn: DSN()
				}
			}
		};

		var dsl = {
			set: function(string col, any value, any param=""){
				arrayAppend(declaration.q["cols"], {
					name: arguments.col,
					value: arguments.value
				});
				
				local.null = false;
				if(!len(arguments.value) AND hasBeanConfig AND beanConfig.isColumnDefined(arguments.col)){
					if(beanConfig.getColumn(arguments.col).isNullable){
						local.null = true;
					}
				}

				if(isStruct(arguments.param)){
					arguments.param.value = arguments.value;
					if(!structKeyExists(arguments.param, "null")){
						arguments.param.null = local.null;
					}
					arguments.param.value = local.null;
					declaration.q.params[arguments.col] = arguments.param;
				}else{
					declaration.q.params[arguments.col] = {
						value: arguments.value,
						null: local.null
					};
				}
				return declaration;
			},
			go: function(){
				return execute(declaration);
			}
		};

		structAppend(declaration, dsl);

		return declaration;
	}


	/**
	* @hint DELETE query syntax DSL for a given bean name
	*/
	public struct function deleteBean(string beanName){
		return delete(arguments.beanName, true);
	}

	/**
	* @hint DELETE query syntax DSL
	*/
	public struct function delete(string tableName, boolean isBean=false){
		var beanConfig = "";
		var hasBeanConfig = false;
		if(arguments.isBean){
			local.beanConfig = db().getBeanConfig(arguments.tableName, schemaName());
			arguments.tableName = local.beanConfig.table();
			hasBeanConfig = true;
		}

		var declaration = {
			q: {
				beanConfig: beanConfig,
				type: "DELETE",
				tableName: arguments.tableName,
				where: "",
				params: {},
				options: {
					dsn: DSN()
				}
			}
		};

		var dsl = {
			where: function(string whereClause){
				declaration.q.where = arguments.whereClause;
				return declaration;
			},
			withParams: function(any params){
				declaration.q.params = arguments.params;
				return declaration;
			},
			withParam: function(string paramName, any paramValue, struct paramOptions={}){
				arguments.paramOptions.value = arguments.paramValue;
				declaration.q.params[arguments.paramName] = arguments.paramOptions;
				return declaration;
			},
			using: function(string dsn){
				declaration.q.options.datasource = arguments.dsn;
				return declaration;
			},
			go: function(struct options={}){
				structAppend(declaration.q.options, arguments.options);
				return execute(declaration);
			}
		};

		structAppend(declaration, dsl);
		
		return declaration;
	}


	/**
	* @hint executes an query from a DSL declaration
	*/
	public struct function execute(struct declaration){
		local.sql = SQLWriter().toSQL(arguments.declaration);
		local.beanConfig = "";
		if(structKeyExists(arguments.declaration.q, "beanConfig")) local.beanConfig = arguments.declaration.q.beanConfig;
		return runQuery(local.sql, arguments.declaration.q.params, arguments.declaration.q.options, local.beanConfig);
		//return local.q;
	}

	/**
	* @hint executes an query
	*/
	public struct function runQuery(string sql, any params={}, struct options={}, any beanConfig=""){
		local.params = processParams(arguments.params, arguments.beanConfig);
		if(!structKeyExists(arguments.options, "datasource")){
			arguments.options.datasource = DSN();
		}
		arguments.options.result = "local.result";

		try{
			local.q = queryExecute(arguments.sql, local.params, arguments.options);
		}catch(any e){
			throw(message:e.message, type:"dbean.core.Gateway", detail:e.detail,
				extendedinfo: "Generated SQL : #arguments.sql#<br />SQL Parameters : #serializeJSON(arguments.params)#");
		}
		local.ret = {
			result: local.result,
			q: isNull(local.q) ? "" : local.q
		}
		return local.ret;

		if(isNull(local.q) || left(trim(arguments.sql), 6) == "INSERT"){
			return local.result;
		}else{
			return local.q;
		}
		
	}
	
	/**
	* @hint checks parameters for sql types
	*/
	public any function processParams(any params, any beanConfig=""){
		local.hasBeanConfig = false;
		if(!isSimpleValue(arguments.beanConfig)) local.hasBeanConfig = true;
		if(isStruct(arguments.params)){
			for(local.key in arguments.params){
				local.value = arguments.params[local.key];
				if((isStruct(local.value) AND NOT structKeyExists(local.value, "cfsqltype")) OR isSimpleValue(local.value)){
					local.columnConfig = "";
					local.configCol = local.key;
					if(local.hasBeanConfig){
						local.columnConfig = arguments.beanConfig;
					}
					if(isStruct(local.value)){
						if(structKeyExists(local.value, "model")){
							local.columnConfig = db().getBeanConfig(local.value.model, schemaName());
						}
						if(structKeyExists(local.value, "modelCol")){
							local.configCol = local.value.modelCol;
						}
					}

					if(!isSimpleValue(local.columnConfig)){

						if(local.columnConfig.isColumnDefined(local.configCol)){
							local.col = local.columnConfig.getColumn(local.configCol);
							if(isStruct(local.value)){
								arguments.params[local.key].cfsqltype = local.col.cfSQLDataType;
							}else{
								arguments.params[local.key] = {
									value: local.value,
									cfsqltype: local.col.cfSQLDataType
								};
							}
							// check fro numeric scale
							if(local.col.type IS "numeric" 
								AND structKeyExists(local.col, "scale")
								AND !structKeyExists(arguments.params[local.key], "scale")){
								arguments.params[local.key].scale = local.col.scale;
							}
						}else if(local.key IS "pk"){
							if(isStruct(local.value)){
								arguments.params[local.key].cfsqltype = local.columnConfig.getConfig().pk.cfSQLDataType;
							}else{
								arguments.params[local.key] = {
									value: local.value,
									cfsqltype: local.columnConfig.getConfig().pk.cfSQLDataType
								};
							}
						}
					}
				}
			}
		}
		return arguments.params;
	}

	/**
	* @hint attempts to determine an insert ID from a given query
	*/
	public any function getInsertID(any q){
		local.testKeys = listToArray("IDENTITYCOL,ROWID,SYB_IDENTITY,SERIAL_COL,KEY_VALUE,GENERATED_KEY,generatedKey");
		for(local.key in local.testKeys){
			if(isDefined("arguments.q.result.#local.key#")){
				return arguments.q.result[local.key];
			}
		}
		local.qGetID = runQuery("SELECT @@identity AS insertID").q;
		return local.qGetID.insertID;
	}

	
	/**
	* @hint gets linked data from a defined many-to-many relationship
	*/
	public any function getLinked(any bean, string manyToManyName, boolean forceRead=false, string condition="", struct params={}){

	}

	/**
	* @hint save linked save data for a given bean
	*/
	public any function saveLinkedData(any bean){

	}

}
