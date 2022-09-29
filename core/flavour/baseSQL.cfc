component{

	variables.tableSelects = {};

	variables._columnEscapeOpen = "[";
	variables._columnEscapeClose = "]";

	/**
	* @hint constructor
	*/
	public any function init(){
		return this;
	}

	public string function columnEscapeOpen(){
		return variables._columnEscapeOpen;
	}

	public string function columnEscapeClose(){
		return variables._columnEscapeClose;
	}


	/**
	* @hint build a string from our config for use in select statements
	*/
	public string function tableSelect(any beanConfig){
		if(structKeyExists(variables.tableSelects, arguments.beanConfig.schema())
			AND structKeyExists(variables.tableSelects[arguments.beanConfig.schema()], arguments.beanConfig.getBeanName())){
			return variables.tableSelects[arguments.beanConfig.schema()][arguments.beanConfig.getBeanName()];
		}

		local.tableString = arguments.beanConfig.table();
		for(local.join in arguments.beanConfig.joins()){
			local.joinType = "LEFT OUTER";
			if(structKeyExists(local.join, "joinType")){
				local.joinType = local.join.joinType;
			}
			if(structKeyExists(local.join, "condition")){
				local.tableString = local.tableString & " #local.joinType# JOIN #local.join.table# ON #local.join.condition# ";
			}else{
				local.joinFromTable = arguments.beanConfig.table();
				local.joinFromCol = local.join.from;
				if(listLen(local.joinFromCol, ".") EQ 2){
					local.joinFromTable = listFirst(local.joinFromCol, ".");
					local.joinFromCol = listLast(local.joinFromCol, ".");
				}
				local.tableString = local.tableString & " #local.joinType# JOIN #local.join.table# ON #local.join.table#.#local.join.on# = #local.joinFromTable#.#local.joinFromCol# ";
			}
		}

		// cache this
		variables.tableSelects[arguments.beanConfig.schema()][arguments.beanConfig.getBeanName()] = local.tableString;

		return local.tableString;
	}


	public string function SQLOffset(numeric offset){
		return " OFFSET #arguments.offset#";
	}

	public string function SQLLimit(numeric limit){
		return " FETCH NEXT #arguments.limit#";
	}

	public string function SQLLimitOffset(numeric limit, numeric offset=0){
		return SQLOffset(arguments.offset) & SQLLimit(arguments.limit);
		
	}

	public string function SQLTotal(struct declaration){
		if(arguments.declaration.withTotal){
			arguments.declaration.cols = arguments.declaration.cols & ", COUNT(*) AS _totalRows";
		}
	}
	


	/**
	* @hint convert a DSL struct to an SQL string
	*/
	public string function toSQL(struct declaration){
		local.declaration = arguments.declaration.q;
		switch(local.declaration.type){
			case "SELECT":
				SQLTotal(local.declaration);
				savecontent variable="local.sql"{
					writeOutput("SELECT #local.declaration.cols# FROM #local.declaration.tableName#");
					if(len(local.declaration.where)){
						writeOutput(" WHERE #local.declaration.where#");
					}
					if(len(local.declaration.orderBy)){
						writeOutput(" ORDER BY #local.declaration.orderBy#");
					}
					if(local.declaration.limit GT 0){
						writeOutput(SQLLimitOffset(local.declaration.limit, local.declaration.offset));
					}
				}
				break;
			case "UPDATE":
				savecontent variable="local.sql"{
					writeOutput("UPDATE #local.declaration.tableName# SET ");
					local.setter = [];
					for(local.col in local.declaration.cols){
						arrayAppend(local.setter, columnEscapeOpen() & local.col.name & columnEscapeClose() & " = :" & local.col.name);
					}
					writeOutput(arrayToList(local.setter, ", "));
					if(len(local.declaration.where)){
						writeOutput(" WHERE #local.declaration.where#");
					}
				}
				break;
			case "INSERT": 
				savecontent variable="local.sql"{
					writeOutput("INSERT INTO #local.declaration.tableName# (");

					local.setter = [];
					local.values = [];
					for(local.col in local.declaration.cols){
						arrayAppend(local.setter, columnEscapeOpen() & local.col.name & columnEscapeClose());
						arrayAppend(local.values, ":" & local.col.name);
					}
					writeOutput(arrayToList(local.setter, ", ") & ") VALUES (" & arrayToList(local.values, ", ") & ")");
				}
				break;
			case "DELETE":
				savecontent variable="local.sql"{
					writeOutput("DELETE FROM #local.declaration.tableName#");
					if(len(local.declaration.where)){
						writeOutput(" WHERE #local.declaration.where#");
					}
				}
				break;
		}
		

		return local.sql;
	}
	
}