<cfset db = new db({
	schemas: {
		default: "test"
	},
	schemaPath: "/sample/schemas/",
	beanConfigPath: [
		"/sample/models/beanConfigs/"
	]
})>


<h1>DBean Samples</h1>


<h2>Read a bean</h2>
<code>testBean = db.bean("test", 1);</code>
<cfset testBean = db.bean("test", 1)>
<cfdump var="#testBean.snapshot()#">

<h2>Update / set a value</h2>
<code>testBean.setBool(false);</code>
<cfset testBean.setBool(false)>

<h2>Get a value</h2>
<code>testBean.getBool();</code>
<cfdump var="#testBean.getBool()#">

<h2>Get a new bean</h2>
<code>testBean = db.bean("test");</code>
<cfset testBean = db.bean("test")>
<cfdump var="#testBean.snapshot()#">

<h2>Save a bean</h2>
<code>testBean.save();</code>
<!--- <cfset testBean.setBool(false)> --->

<h2>Delete a bean</h2>
<code>testBean.delete();</code>

<h2>Get linked data</h2>
<code><pre>
testBean = db.bean("test", 1);
testBean.linked("categories");
</pre></code>
<cfset testBean = db.bean("test", 1)>
<cfdump var="#testBean.linked("categories")#">

<h2>Set linked data</h2>
<code>testBean.makeLinked("categories", [1,4]);</code>



<h2>Gateway query DSL</h2>
<code><pre>
qData = db.gateway()
	.fromBean("test")
	.select("test_id, name, startDate")
	.where("bool = :bool")
	.withParam("bool", 1)
	.limit(2, 0, true)
	.orderBy("startDate ASC")
	.get();
</pre></code>
<cfdump var="#db.gateway()
	.fromBean("test")
	.select("test_id, name, startDate")
	.where("bool = :bool")
	.withParam("bool", 1)
	.limit(2, 0, true)
	.orderBy("startDate ASC")
	.get()#">

<h2>Gateway DSL also available for update, insert and delete</h2>

<h2>Bean representation</h2>
<code><pre>
data = testBean.representation("name,test_id,startDate", {
	"#testBean.PK()#": "id"
})/
</pre></code>
<cfset testBean = db.bean("test", 1)>
<cfdump var="#testBean.representation("name,test_id,startDate", {
	"#testBean.PK()#": "id"
})#">

<h2>Service layer</h2>
<code><pre>
testService = new models.test.testService(db);
testBean = testService.bean(1);
</pre></code>
<cfset testService = new models.test.testService(db)>

<h2>Get bean from Service using arguments</h2>
<code><pre>
testBean = testService.bean({
	"name": "Dave Wagga",
	"bool": true
});
</pre></code>
<cfset testBean = testService.bean({
	"name": "Dave Wagga",
	"bool": true
})>
<cfdump var="#testBean.snapshot()#">

<h2>Bean iterator</h2>
<code><pre>
it = db.iterator("test");
// or
it = testService.iterator();

while(it.hasNext()){
	item = it.next();		
	writeOutput(it.currentPosition() & " of " & it.recordCount());
	writeDump(item.snapshot());
	writeDump(item.linked("categories"));
}
</pre></code>
<cfset it = db.iterator("test")>
<cfloop condition="it.hasNext()">
	<cfset item = it.next()>
	<!-- do stuff in here -->
	<cfoutput>#it.currentPos()# of #it.recordCount()#</cfoutput>
	<cfdump var="#item.snapshot()#">
	<cfdump var="#item.linked("categories")#">
</cfloop>