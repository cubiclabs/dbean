component extends="baseSQL"{

	variables._columnEscapeOpen = "`";
	variables._columnEscapeClose = "`";

	public string function SQLLimit(numeric limit){
		return " LIMIT #arguments.limit#";
	}

	public string function SQLLimitOffset(numeric limit, numeric offset=0){
		return SQLLimit(arguments.limit) & SQLOffset(arguments.offset);
		
	}

	public string function SQLTotal(struct declaration){
		if(arguments.declaration.withTotal){

			local.where = "";
			if(len(arguments.declaration.where)){
				local.where = " WHERE #arguments.declaration.where#";
			}

			arguments.declaration.cols = arguments.declaration.cols & ", (SELECT COUNT(*) FROM #arguments.declaration.tableName# #local.where#) AS _totalRows";
		}
	}
	
}