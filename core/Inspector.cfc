component{

	variables._settings = {
		"isDefaultDateUTC": false,
		"isBooleanNumeric": false
	};

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
	* @hint returns our dtabase flavour from our product name
	*/
	public string function getFlavour(string productName){
		if(arguments.productName CONTAINS "Microsoft SQL Server"){
			return "MSSQL";
		}
		if(arguments.productName CONTAINS "MYSQL"){
			return "MYSQL";
		}
		return "";
	}

	/**
	* @hint inspects a database and returns table information
	*/
	public any function inspectDatabase(string dsn, string schemaName="default"){
		cfdbinfo(
			datasource=arguments.dsn,
			type="tables",
			name="local.dbInfo");

		cfdbinfo(
			datasource=arguments.dsn,
			type="version",
			name="local.dbVersion");
		//return local.dbInfo;

		local.db = {
			"schemaName": arguments.schemaName,
			"dsn": arguments.dsn,
			"version": local.dbVersion.database_productName,
			"flavour": getFlavour(local.dbVersion.database_productName),
			"tables":{}
		};

		for(local.table in local.dbInfo){
			if(local.table.table_type IS "TABLE" 
				AND (!listFindNoCase(local.dbInfo.columnList, "table_schem")
					OR (local.table.table_schem IS NOT "sys")
				)){
				local.db.tables[local.table.table_name] = inspectTable(arguments.dsn, local.table.table_name);
			}
		}

		return local.db;
	}

	/**
	* @hint inspects a database table
	*/
	public struct function inspectTable(string dsn, string tableName){

		cfdbinfo(
			datasource=arguments.dsn,
			type="columns",
			table=arguments.tableName,
			name="local.qTable");

		local.schema = {
			"cols": [],
			"pk": "",
			"table": arguments.tableName
		};

		local.possiblePK = [];

		for(local.col in local.qTable){

			local.nullable = structKeyExists(local.col, "nullable") ? local.col.nullable ? true : false
				: structKeyExists(local.col, "is_nullable") ? local.col.is_nullable ? true : false : false;
			
			local.autoincrement = false;
			if(structKeyExists(local.col, "is_autoincrement")){
				local.autoincrement = local.col.is_autoincrement ? true : false;
			}else{
				if(local.col.is_primaryKey && len(local.col.column_default_value)){
					// primary key with a default value - we assume that this is some form of auto increment
					local.autoincrement = true;
				}else if(local.col.type_name CONTAINS "identity"){
					local.autoincrement = true;
				}
			}

			local.colData = {
				"name": local.col.column_name,
				"type": listFirst(local.col.type_name, " "),
				"size": local.col.column_size,
				"isNullable": local.nullable,
				"isAutoIncrement": local.autoincrement,
				"cfSQLDataType": getCFSQLDataType(local.col.type_name, local.col.column_size),
				"cfDataType": getCFDataType(local.col.type_name),
				"default": getDefaultForDataType(getCFDataType(local.col.type_name))
			};
			if(val(local.col.decimal_digits)){
				local.colData["scale"] = local.col.decimal_digits;
			}

			if(local.col.is_primaryKey){
				local.schema.pk = local.col.column_name;
				local.colData["pk"] = true;
			}else if(local.colData.isAutoIncrement){
				arrayAppend(local.possiblePK, local.colData);
			}

			arrayAppend(local.schema.cols, local.colData);
		}

		// if we do not have a primayr key, try to find one
		if(!len(local.schema.pk) AND arrayLen(local.possiblePK)){
			local.schema.pk = local.possiblePK[1].name;
			local.possiblePK[1]["pk"] = true;
		}

		return local.schema;
	}

	/**
	* @hint builds a model
	*/
	public void function buildModel(string dsn, string modelName, string tableName, string modelPath){
		
		// make sure a directory exists for our model
		local.fullModelPath = arguments.modelPath & arguments.modelName & "/";
		if(!directoryExists(local.fullModelPath)){
			directoryCreate(local.fullModelPath);
		}

		// always overwrite our schema
		local.schema = inspectTable(arguments.dsn, arguments.tableName);
		local.schemaFile = buildDefinition(local.schema);
		fileWrite(local.fullModelPath & "_" & arguments.modelName & "Schema.cfm", local.schemaFile);

		// config if not defined
		if(!fileExists(local.fullModelPath & arguments.modelName & "Config.cfc")){
			fileWrite(local.fullModelPath & arguments.modelName & "Config.cfc", buildCFC("config", arguments.modelName));
		}
		// bean if not defined
		if(!fileExists(local.fullModelPath & arguments.modelName & "Bean.cfc")){
			fileWrite(local.fullModelPath & arguments.modelName & "Bean.cfc", buildCFC("bean"));
		}
		// service if not defined
		if(!fileExists(local.fullModelPath & arguments.modelName & "Service.cfc")){
			fileWrite(local.fullModelPath & arguments.modelName & "Service.cfc", buildCFC("service"));
		}
		// gateway if not defined
		if(!fileExists(local.fullModelPath & arguments.modelName & "Gateway.cfc")){
			fileWrite(local.fullModelPath & arguments.modelName & "Gateway.cfc", buildCFC("gateway"));
		}
	}

	/**
	* @hint constructs our definition code
	*/
	public string function buildCFC(string type, string modelName="", string tableName="", string schemaName="default"){
		local.crlf = chr(13) & chr(10);
		local.tab = chr(9);
		local.lines = [];

		switch(arguments.type){
			case "config":
				local.table = "tbl_#arguments.modelName#"; 
				if(len(arguments.tableName)){
					local.table = arguments.tableName;
				}
				arrayAppend(local.lines, "component{");
				//arrayAppend(local.lines, local.tab & "include ""_#arguments.modelName#Schema.cfm"";");
				if(len(arguments.schemaName)){
					arrayAppend(local.lines, local.tab & "this.definition.schema = ""#arguments.schemaName#"";");	
				}
				arrayAppend(local.lines, local.tab & "this.definition.table = ""#local.table#"";");
				arrayAppend(local.lines, local.tab & "this.definition.joins = [];");
				arrayAppend(local.lines, local.tab & "this.definition.manyTomany = [];");
				arrayAppend(local.lines, local.tab & "this.definition.specialColumns = [];");
				arrayAppend(local.lines, "}");
				break;
			case "bean":
				arrayAppend(local.lines, "component extends=""db.dbBean""{");
				arrayAppend(local.lines, "}");
				break;
			case "service":
				arrayAppend(local.lines, "component extends=""db.dbService""{");
				arrayAppend(local.lines, "}");
				break;
			case "gateway":
				arrayAppend(local.lines, "component extends=""db.dbGateway""{");
				arrayAppend(local.lines, "}");
				break;
		}

		return arrayToList(local.lines, local.crlf);
	}

	/**
	* @hint constructs our definition code
	*/
	public string function buildDefinition(struct schema){
		local.crlf = chr(13) & chr(10);
		local.tab = chr(9);
		local.lines = [];
		arrayAppend(local.lines, "[cfscript>");
		arrayAppend(local.lines, local.tab & "// GENERATED FILE DO NOT EDIT");
		arrayAppend(local.lines, local.tab & "this.definition = {");
		arrayAppend(local.lines, repeatString(local.tab, 2) & "table:""" & arguments.schema.table & """,");
		arrayAppend(local.lines, repeatString(local.tab, 2) & "pk:""" & arguments.schema.pk & """,");
		arrayAppend(local.lines, repeatString(local.tab, 2) & "cols:[");

		local.cols = [];
		for(local.col in arguments.schema.cols){
			local.colLines = [];
			local.colLineKeys = [];
			arrayAppend(local.colLines, repeatString(local.tab, 3) & "{");
			for(local.key in structKeyArray(local.col)){
				local.valueString = local.col[local.key];
				if((local.key NEQ "default") AND !isBoolean(local.valueString) AND !isNumeric(local.valueString)){
					local.valueString = """" & local.valueString & """";
				}
				arrayAppend(local.colLineKeys, repeatString(local.tab, 4) & local.key & ":" & local.valueString);
			}
			arrayAppend(local.colLines, arrayToList(local.colLineKeys, "," & local.crlf));
			arrayAppend(local.colLines, repeatString(local.tab, 3) & "}");
			arrayAppend(local.cols, arrayToList(local.colLines, local.crlf));
		}
		arrayAppend(local.lines, arrayToList(local.cols, "," & local.crlf));

		arrayAppend(local.lines, repeatString(local.tab, 2) & "]");
		//arrayAppend(local.lines, repeatString(local.tab, 2) & "joins:[],");
		//arrayAppend(local.lines, repeatString(local.tab, 2) & "oneToMany:[],");
		//arrayAppend(local.lines, repeatString(local.tab, 2) & "manyTomany:[],");
		//arrayAppend(local.lines, repeatString(local.tab, 2) & "specialColumns:[]");
		arrayAppend(local.lines, local.tab & "};");
		arrayAppend(local.lines, "[/cfscript>");

		//convert to a string
		local.def = reReplaceNoCase(arrayToList(local.lines, local.crlf), "\[(\/?)cf", "<\1cf", "ALL");

		return local.def;
	}

	/**
	* @hint constructs our definition code
	*/
	public string function buildSchema(string dsn, string schemaName="default"){
		local.crlf = chr(13) & chr(10);
		local.tab = chr(9);
		local.lines = [];

		local.schema = inspectDatabase(arguments.dsn, arguments.schemaName);
		
		arrayAppend(local.lines, "// GENERATED FILE DO NOT EDIT");
		arrayAppend(local.lines, "component{");
		arrayAppend(local.lines, local.tab & "this.schema = {");
		arrayAppend(local.lines, repeatString(local.tab, 2) & "dsn:""" & local.schema.dsn & """,");
		arrayAppend(local.lines, repeatString(local.tab, 2) & "flavour:""" & local.schema.flavour & """,");
		arrayAppend(local.lines, repeatString(local.tab, 2) & "schemaName:""" & local.schema.schemaName & """,");
		arrayAppend(local.lines, repeatString(local.tab, 2) & "version:""" & local.schema.version & """,");
		arrayAppend(local.lines, repeatString(local.tab, 2) & "tables: {}");
		arrayAppend(local.lines, local.tab & "};");
		
		arrayAppend(local.lines, '

	variables.tableKeys = #serializeJSON(structKeyArray(local.schema.tables))#;

	function init(){
		for(local.table in variables.tableKeys){
			invoke(this, "addTable_##local.table##");
		}	
	}

');


		local.tables = [];
		for(local.table in structKeyArray(local.schema.tables)){
			local.tableLines = [];

			arrayAppend(local.tableLines, repeatString(local.tab, 1) & "function addTable_#local.table#(){");
			arrayAppend(local.tableLines, repeatString(local.tab, 2) & "this.schema.tables.#local.table# = {");
			
			local.tableSchema = local.schema.tables[local.table];

			arrayAppend(local.tableLines, repeatString(local.tab, 3) & "table:""" & local.tableSchema.table & """,");
			arrayAppend(local.tableLines, repeatString(local.tab, 3) & "pk:""" & local.tableSchema.pk & """,");
			arrayAppend(local.tableLines, repeatString(local.tab, 3) & "cols:[");

			local.cols = [];
			for(local.col in local.tableSchema.cols){
				local.colLines = [];
				local.colLineKeys = [];
				arrayAppend(local.colLines, repeatString(local.tab, 4) & "{");
				for(local.key in structKeyArray(local.col)){
					local.valueString = local.col[local.key];
					if((local.key NEQ "default") AND !isBoolean(local.valueString) AND !isNumeric(local.valueString)){
						local.valueString = """" & local.valueString & """";
					}
					arrayAppend(local.colLineKeys, repeatString(local.tab, 5) & """" & local.key & """" & ":" & local.valueString);
				}
				arrayAppend(local.colLines, arrayToList(local.colLineKeys, "," & local.crlf));
				arrayAppend(local.colLines, repeatString(local.tab, 4) & "}");
				arrayAppend(local.cols, arrayToList(local.colLines, local.crlf));
			}
			arrayAppend(local.tableLines, arrayToList(local.cols, "," & local.crlf));

			arrayAppend(local.tableLines, repeatString(local.tab, 3) & "]");
			arrayAppend(local.tableLines, repeatString(local.tab, 2) & "};");
			arrayAppend(local.tableLines, repeatString(local.tab, 1) & "}");

			arrayAppend(local.tables, arrayToList(local.tableLines, local.crlf));
		}
		arrayAppend(local.lines, arrayToList(local.tables, local.crlf));
		

		//arrayAppend(local.lines, repeatString(local.tab, 2) & "}");
		//arrayAppend(local.lines, local.tab & "};");
		arrayAppend(local.lines, "}");

		return arrayToList(local.lines, local.crlf);
	}



	/**
	* @hint returns the mapped CFSQLDatatype for a given column data type
	*/
	public string function getCFSQLDataType(string datatype, any size){

		arguments.datatype = listFirst(arguments.datatype, " ");
		arguments.datatype = listFirst(arguments.datatype, "(");

		switch(arguments.datatype){
			case "bigint":
				return "cf_sql_bigint";
			case "binary":
				return "cf_sql_binary";
			case "bit":
				return "cf_sql_bit";
			case "char":
				if(arguments.size > 800){
					return "cf_sql_clob";
				}
				return "cf_sql_char";
			case "datetime": case "datetime2":
				return "cf_sql_timestamp";
			case "decimal": case "double":
				return "cf_sql_decimal";
			case "float":
				return "cf_sql_float";
			case "image":
				return "cf_sql_longvarbinary";
			case "int": case "counter": case "integer":
				return "cf_sql_integer";
			case "money":
				return "cf_sql_money";
			case "nchar":
				if(arguments.size > 800){
					return "cf_sql_clob";
				}
				return "cf_sql_char";
			case "ntext": case "longchar":
				return "cf_sql_clob";
			case "numeric":
				return "cf_sql_varchar";
			case "nvarchar": case "guid":
				if(arguments.size > 800){
					return "cf_sql_clob";
				}
				return "cf_sql_varchar";
			case "real":
				return "cf_sql_real";
			case "smalldatetime":
				return "cf_sql_timestamp";
			case "smallint":
				return "cf_sql_smallint";
			case "smallmoney":
				return "cf_sql_decimal";
			case "sysname":
				return "cf_sql_varchar";
			case "text":
				return "cf_sql_clob";
			case "timestamp":
				return "cf_sql_timestamp";
			case "tinyint":
				return "cf_sql_tinyint";
			case "uniqueidentifier":
				return "cf_sql_char";
			case "varbinary":
				return "cf_sql_varbinary";
			case "varchar":
				if(arguments.size > 800){
					return "cf_sql_clob";
				}
				return "cf_sql_varchar";
			case "xml":
				return "cf_sql_clob";
		}

		return arguments.datatype;
	}


	/**
	* @hint returns a CF datatype for a given column dataType
	*/
	public string function getCFDataType(string datatype){

		arguments.datatype = listFirst(arguments.datatype, " ");
		arguments.datatype = listFirst(arguments.datatype, "(");

		switch(arguments.datatype){
			case "bigint":
				return "numeric";
			case "binary":
				return "binary";
			case "bit":
				return "boolean";
			case "char":
				return "string";
			case "datetime": case "datetime2":
				return "date";
			case "decimal": case "double":
				return "numeric";
			case "float":
				return "numeric";
			case "image":
				return "binary";
			case "int": case "counter": case "integer":
				return "numeric";
			case "money":
				return "numeric";
			case "nchar":
				return "string";
			case "ntext": case "longchar":
				return "string";
			case "numeric":
				return "numeric";
			case "nvarchar": case "guid":
				return "string";
			case "real":
				return "numeric";
			case "smalldatetime":
				return "date";
			case "smallint":
				return "numeric";
			case "smallmoney":
				return "numeric";
			case "text":
				return "string";
			case "timestamp":
				return "numeric";
			case "tinyint":
				return "numeric";
			case "uniqueidentifier":
				return "string";
			case "varbinary":
				return "binary";
			case "varchar":
				return "string";
		}

		return arguments.datatype;
	}


	public any function getDefaultForDataType(string CFDataType){
		switch(arguments.CFDataType){
			case "string":
				return """""";
			case "numeric":
				return 0;
			case "boolean":
				return getSettings().isBooleanNumeric ? 0 : false;
			case "date":
				return getSettings().isDefaultDateUTC ? "DateConvert('local2Utc', now())" : "now()";
		}

		return """""";
	}

	
}