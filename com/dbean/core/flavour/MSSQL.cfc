component extends="baseSQL"{

	public string function SQLOffset(numeric offset){
		return " OFFSET #arguments.offset# ROWS";
	}

	public string function SQLLimit(numeric limit){
		return " FETCH NEXT #arguments.limit# ROWS ONLY";
	}

	public string function SQLTotal(struct declaration){
		if(arguments.declaration.withTotal){
			arguments.declaration.cols = arguments.declaration.cols & ", COUNT(*) OVER() AS _totalRows";
		}
	}
	
	
}