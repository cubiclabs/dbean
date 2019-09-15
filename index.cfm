
<cfset db = new com.dbean.db({
	schemas: {
		default: "test"
	},
	beanConfigPath: [
		"/models/beanConfigs/",
		"[model]"
	]
})>

<!--- <cfdump var="#db.getDefaultSchemaPath()#">
<cfdump var="#db.getSchemaDotPath()#"> --->

<cfset bean = db.bean("test")>
<cfdump var="#bean.getSnapshot()#">

<cfset bean.setName("Test Name")>

<cfdump var="#bean.getSnapshot()#">
<cfdump var="#db.getSettings()#">