
<cfset db = new com.dbean.db({
	schemas: {
		default: "test"
	},
	beanConfigPath: [
		"/models/beanConfigs/",
		"[model]"
	]
})>

<cfset bean = db.bean("test", 6)>
<cfset bean.delete()>

<!--- <cfdump var="#db.getDefaultSchemaPath()#">
<cfdump var="#db.getSchemaDotPath()#"> --->

<cfset bean = db.bean("test")>
<cfdump var="#bean.snapshot()#">

<cfset bean.setName("Test Name")>

<cfdump var="#bean.snapshot()#">
<!--- <cfset bean.save()> --->



<cfdump var="#db.gateway()
	.fromBean("test")
	//.select("test_id, name, startDate")
	//.where("bool = :bool")
	//.withParam("bool", 1)
	.orderBy("startDate ASC")
	.get()#">

<cfdump var="#db.gateway()
	.from("tbl_test")
	//.select("test_id, name, startDate")
	.where("bool = :bool")
	.withParam("bool", 1, {model: "test"})
	//.withParam("bool", 1)
	.orderBy("startDate ASC")
	//.usingBeanConfig(db.getBeanConfig("test"))
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


<cfset it = db.iterator("test")>
<cfloop condition="it.hasNext()">
	<cfset item = it.next()>
	<!-- do stuff in here -->
	<cfdump var="#item.snapshot()#">
	<cfdump var="#item.getLinked("categories")#">
</cfloop>