<cfscript>
db = new db({
	schemas: {
		default: "test"
	},
	schemaPath: "/sample/schemas/",
	beanConfigPath: [
		"/models/beanConfigs/"
	]
});

db.flushSchema();

writeOutput("OK");
</cfscript>