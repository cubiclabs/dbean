component{



	/**
	* @hint constructor
	*/
	public any function init(any config){
		variables.config = arguments.config;
		return this;
	}


	/**
	* @hint build a string from our config for use in select statements
	*/
	public string function tableSelect(){
		if(structKeyExists(variables, "tableSelectString")){
			return variables.tableSelectString;
		}

		local.tableString = variables.config.getConfig().table;
		for(local.join in variables.config.joins()){
			local.joinType = "LEFT OUTER";
			if(structKeyExists(local.join, "joinType")){
				local.joinType = local.join.joinType;
			}
			if(structKeyExists(local.join, "condition")){
				local.tableString = local.tableString & " #local.joinType# JOIN #local.join.table# ON #local.join.condition# ";
			}else{
				local.joinFromTable = variables.config.getConfig().table;
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


	public string function SQLOffset(numeric offset){
		return " OFFSET #arguments.offset#";
	}

	public string function SQLLimit(numeric limit){
		return " FETCH NEXT #arguments.limit#";
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
					if(local.declaration.offset GT 0){
						writeOutput(SQLOffset(local.declaration.offset));
					}
					if(local.declaration.limit GT 0){
						writeOutput(SQLLimit(local.declaration.limit));
					}
				}
				break;
			case "UPDATE":
				savecontent variable="local.sql"{
					writeOutput("UPDATE #local.declaration.tableName# SET ");
					local.setter = [];
					for(local.col in local.declaration.cols){
						arrayAppend(local.setter, local.col.name & " = :" & local.col.name);
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
						arrayAppend(local.setter, local.col.name);
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