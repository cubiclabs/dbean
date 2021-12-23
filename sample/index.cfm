
<cfset db = new db({
	schemas: {
		default: "test"
	},
	schemaPath: "/sample/schemas/",
	beanConfigPath: [
		"/sample/models/beanConfigs/"
	]
})>

<cfset bean = db.bean("test", 6)>
<cfset bean.delete()>

<!--- <cfdump var="#db.getDefaultSchemaPath()#">
<cfdump var="#db.getSchemaDotPath()#"> --->

<cfset bean = db.bean("test")>
<cfdump var="#bean.snapshot()#">

<cfset bean.setName("Test Name")>
<cfset bean.setDec(23.24)>
<cfset bean.setNotes("This is a test note")>

<cfset bean.setLinked("categories", [1,4])>


<cfset bean.save()>
<cfdump var="#bean.snapshot()#">
<cfdump var="#bean.getLinked("categories")#">
<cfset db.delete(bean)>

<cfdump var="#db.gateway()
	.fromBean("test")
	<!---.select("test_id, name, startDate")
	.where("bool = :bool")
	.withParam("bool", 1) --->
	.limit(3, 0, true)
	.orderBy("startDate ASC")
	.get()#">

<cfdump var="#db.gateway()
	.from("tbl_test")
	<!--- .select("test_id, name, startDate") --->
	.where("bool = :bool")
	.withParam("bool", 1, {model: "test"})
	<!--- .withParam("bool", 1) --->
	.orderBy("startDate ASC")
	<!--- .usingBeanConfig(db.getBeanConfig("test")) --->
	.get()#">


<cfset bean = db.bean("test", 4)>
<cfdump var="#bean.snapshot()#">
<cfdump var="#bean.getLinked("categories")#">
<!--- <cfset bean.setStartDate(now())> --->
<cfset bean.setDec(1.236)>
<cfset bean.setLinked("categories", [1,4])>
<cfset bean.save()>


<cfset testService = new models.test.testService(db)>
<cfset bean = testService.bean(1)>
<cfdump var="#bean.snapshot()#">
<cfdump var="#bean.getLinked("categories")#">

GET BY ARG
<cfset bean = testService.bean({
	"name": "Dave Wagga",
	"bool": true
})>
<cfdump var="#bean.representation("name,test_id,startDate", {
	"#bean.PK()#": "id"
})#">


<cfset it = db.iterator("test")>
<cfloop condition="it.hasNext()">
	<cfset item = it.next()>
	<!-- do stuff in here -->
	<cfoutput>#it.currentPos()#</cfoutput>
	<cfdump var="#item.snapshot()#">
	<cfdump var="#item.getLinked("categories")#">
</cfloop>