component{

	/*

	USAGE
	====================

	it = db.iterator(beanName:"News", data:variables.qNews)>

	while( it.hasNext() ){
		item = it.next();
		// do stuff here

	}


	*/

	variables._db = "";
	variables._bean = "";
	variables._qData = "";
	variables._i = 0;

	/**
	* @hint constructor
	*/
	public function init(
		any dbObject,
		string beanName,
		string where="",
		any params={},
		string orderBy="",
		numeric limit=0,
		numeric limitOffset=0,
		boolean withTotal=false,
		any data){
		
		variables._db = arguments.dbObject;

		local.beanInfo = db().parseBeanName(arguments.beanName);
		
		if(structKeyExists(arguments, "data")){
			variables._qData = arguments.data;
		}else{
			local.dec = db().gateway(local.beanInfo.schema)
				.fromBean(local.beanInfo.beanName)
				.where(arguments.where)
				.withParams(arguments.params)
				.orderBy(arguments.orderBy);

			// test for limit
			if(arguments.limit){
				local.dec.limit(arguments.limit, arguments.limitOffset, arguments.withTotal);
			}

			variables._qData = local.dec.get();
		}
		
		variables._bean = db().bean(arguments.beanName);
		variables._i = 0;

		return this;
	}


	/**
	* @hint returns our db object
	*/
	public any function db(){
		return variables._db;
	}

	/**
	* @hint returns the object using data from the current index position. this also forces a reset of hte bean
	*/
	public any function getBean(){
		if(variables._i EQ 0 AND recordCount()){
			variables._i = 1;
		}
		variables._bean.pop(variables._qData, variables._i, false);
		return variables._bean;
	}

	/**
	* @hint returns the query data in the iterator
	*/
	public query function getQueryData(){
		return variables._qData;
	}
	
	/**
	* @hint returns the number of rows in our data query
	*/
	public numeric function recordCount(){
		return variables._qData.recordCount;
	}

	/**
	* @hint returns the total number of records that the query can contain
	*/
	public numeric function totalRows(){
		if(variables._qData.keyExists("_totalRows")){
			return val(variables._qData._totalRows);
		}
		return recordCount(); 
	}

	/**
	* @hint returns the current index position
	*/
	public numeric function currentPos(){
		return variables._i;
	}
		
	/**
	* @hint move our index to a given position
	*/
	public boolean function move(numeric position=1){
		if ((int(arguments.position) LTE variables._qData.recordCount) 
			AND (int(arguments.position) GT 0)){
			variables._i = arguments.position;
			return true;
		}
		return false;
	}

	/**
	* @hint resets our index to zero - useful if we need to iterate through our collectionmore than once
	*/
	public void function resetIndex(){
		variables._i = 0;
	}

	
	/**
	* @hint move our index to the first position
	*/
	public void function moveFirst(){
		variables._i = 1;
	}

	/**
	* @hint move our index to the last position
	*/
	public void function moveLast(){
		variables._i = variables._qData.recordCount;
	}

	/**
	* @hint move our index to the last position
	*/
	public void function moveNext(){
		if(variables._i LT variables._qData.recordCount){
			variables._i++;
		}
	}

	/**
	* @hint returns true if we can move on to the next position
	*/
	public boolean function hasNext(){
		if(variables._i LT variables._qData.recordCount){
			return true;
		}
		return false;
	}

	/**
	* @hint returns true if we can move back to the previous position
	*/
	public boolean function hasPrev(){
		if(variables._i GT 1){
			return true;
		}
		return false;
	}

	/**
	* @hint moves our index on one and returns the bean at that position
	*/
	public any function next(){
		moveNext();
		return getBean();
	}

	/**
	* @hint move our index to the previous position
	*/
	public void function movePrev(){
		if(variables._i GT 1){
			variables._i--;
		}
	}

	/**
	* @hint is the index in the last position
	*/
	public boolean function isLast(){
		if(variables._i GTE variables._qData.recordCount){
			return true;
		}
		return false;
	}
	
	/**
	* @hint is the index in the first position
	*/
	public boolean function isFirst(){
		if(variables._i LTE 1){
			return true;
		}
		return false;
	}

	/**
	* @hint returns an array of bean represenations
	*/
	public array function representationOf(string fields="*", string exclude="", struct fieldMapping={}, struct modifiers={}){
		local.out = [];
		resetIndex();

		while( hasNext() ){
			local.bean = next();
			// do stuff here
			arrayAppend(local.out, db().representationOf(local.bean, arguments.fields, arguments.exclude, arguments.fieldMapping, arguments.modifiers));
		}

		return local.out;
	}
}