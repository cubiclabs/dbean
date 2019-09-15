component accessors="true"{

	//property name="FB" inject="framework";
	// property name="dsn" inject="setting:modules.db.dsn.name";
	// property name="flavour" inject="setting:modules.db.dsn.flavour";

	property name="db";
	//


	/**
	* @hint constructor
	*/
	public function init(any db){
		variables.db = arguments.db;
		variables.config = variables.db.rootName.getBeanConfig(rootName());
		return this;
	}

	public any function getConfig(){
		return variables.config.getConfig();
	}

	public any function getConfigReader(){
		return variables.config;
	}

	public string function getDSN(){
		return getConfig().dsn;
	}

	public string function getFlavour(){
		return getConfig().flavour;
	}

	public any function getSQLWriter(){
		if(!structKeyExists(variables, "SQLWriter")){
			local.type = "baseSQL";
			if(len(getFlavour())){
				local.type = getFlavour();
			}
			variables.SQLWriter = createObject("component", "flavour.#local.type#").init(variables.config);
		}
		return variables.SQLWriter;
	}

	/**
	* @hint returns the root name of our bean
	*/
	public string function rootName(){
		local.root = listLast(getMetaData(this).name, ".");
		if(right(local.root, 7) IS "Gateway"){
			local.root = mid(local.root, 1, len(local.root) - 7);
		}
		return local.root;
	}
	

	/* =================================== */

	public query function get(any pkValue){
		return from()
			.where(getConfig().pk.name & "= :pk")
			.withParams({
				pk: arguments.pkValue
			})
			.get();
	}

	public query function getAll(){
		return from().get();
	}

	/**
	* @hint our default columns
	*/	
	public string function cols(){
		return variables.config.columnList();;
	}

	/**
	* @hint SELECT query syntax DSL
	*/
	public struct function from(string tableName=getSQLWriter().tableSelect()){
		var declaration = {
			q: {
				type: "SELECT",
				tableName: arguments.tableName,
				where: "",
				params: {},
				joins: [],
				cols: cols(),
				orderBy: "",
				limit: 0,
				offset: 0,
				withTotal: false,
				options: {
					dsn: getDSN()
				}
			}
		};

		structAppend(declaration, {
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
			get: function(string cols="", struct options={}){
				structAppend(declaration.q.options, arguments.options);
				if(len(arguments.cols)){
					declaration.q.cols = arguments.cols;
				}
				return execute(declaration);
			}
		});

		return declaration;
	}

	/**
	* @hint UPDATE query syntax DSL
	*/
	public struct function update(string tableName=getConfig().table){
		var declaration = {
			q: {
				type: "UPDATE",
				tableName: arguments.tableName,
				where: "",
				params: {},
				cols: [],
				options: {
					dsn: getDSN()
				}
			}
		};

		structAppend(declaration, {
			set: function(string col, any value, any param=""){
				arrayAppend(declaration.q.cols, {
					name: arguments.col,
					value: arguments.value
				});
				
				local.null = false;
				if(!len(arguments.value) AND variables.config.isColumnDefined(arguments.col)){
					if(variables.config.getColumn(arguments.col).isNullable){
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
					}
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

		});

		return declaration;
	}


	/**
	* @hint INSERT query syntax DSL
	*/
	public struct function insert(string tableName=getConfig().table){
		var declaration = {
			q: {
				type: "INSERT",
				tableName: arguments.tableName,
				params: {},
				cols: [],
				options: {
					dsn: getDSN()
				}
			}
		};

		structAppend(declaration, {
			set: function(string col, any value, any param=""){
				arrayAppend(declaration.q.cols, {
					name: arguments.col,
					value: arguments.value
				});
				
				local.null = false;
				if(!len(arguments.value) AND variables.config.isColumnDefined(arguments.col)){
					if(variables.config.getColumn(arguments.col).isNullable){
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
					}
				}
				return declaration;
			},
			go: function(){
				return execute(declaration);
			}

		});

		return declaration;
	}


	/**
	* @hint DELETE query syntax DSL
	*/
	public struct function delete(string tableName=getConfig().table){
		var declaration = {
			q: {
				type: "DELETE",
				tableName: arguments.tableName,
				where: "",
				params: {},
				options: {
					dsn: getDSN()
				}
			}
		};

		structAppend(declaration, {
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
		});

		return declaration;
	}


	/**
	* @hint executes an query from a DSL declaration
	*/
	public any function execute(struct declaration){
		local.sql = getSQLWriter().toSQL(arguments.declaration);
		local.q = runQuery(local.sql, arguments.declaration.q.params, arguments.declaration.q.options);
		return local.q;
	}

	/**
	* @hint executes an query
	*/
	public any function runQuery(string sql, any params={}, struct options={}){
		local.params = processParams(arguments.params);
		if(!structKeyExists(arguments.options, "datasource")){
			arguments.options.datasource = getDSN();
		}
		return queryExecute(arguments.sql, local.params, arguments.options);
	}
	
	/**
	* @hint checks parameters for sql types
	*/
	public any function processParams(any params){
		if(isStruct(arguments.params)){
			for(local.key in arguments.params){
				local.value = arguments.params[local.key];
				if((isStruct(local.value) AND NOT structKeyExists(local.value, "cfsqltype")) OR isSimpleValue(local.value)){
					if(variables.config.isColumnDefined(local.key)){
						if(isStruct(local.value)){
							arguments.params[local.key].cfsqltype = variables.config.getColumn(local.key).cfSQLDataType;
						}else{
							arguments.params[local.key] = {
								value: local.value,
								cfsqltype: variables.config.getColumn(local.key).cfSQLDataType
							};
						}
					}else if(local.key IS "pk"){
						if(isStruct(local.value)){
							arguments.params[local.key].cfsqltype = variables.config.getConfig().pk.cfSQLDataType;
						}else{
							arguments.params[local.key] = {
								value: local.value,
								cfsqltype: variables.config.getConfig().pk.cfSQLDataType
							};
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
	public any function getInsertID(query q){
		local.testKeys = listToArray("IDENTITYCOL,ROWID,SYB_IDENTITY,SERIAL_COL,KEY_VALUE,GENERATED_KEY");
		for(local.key in local.testKeys){
			if(isDefined("arguments.q.#local.key#")){
				return arguments.q[local.key];
			}
		}
		local.qGetID = runQuery("SELECT @@identity AS insertID");
		return local.qGetID.insertID;
	}

	

}
