
<cfset insp = new com.dbean.core.Inspector()>

<cfdump var="#insp.inspectDatabase("test")#">
<cfscript>
cfdbinfo(
	datasource="test",
	type="tables",
	name="local.dbInfo");

writeDump(local.dbInfo);

cfdbinfo(
	datasource="test",
	type="columns",
	table="tbl_test",
	name="local.qTable");

writeDump(local.qTable);
</cfscript>
