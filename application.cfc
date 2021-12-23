component{

	this.name = "DBean_" & hash(getCurrentTemplatePath());

	// Life span, as a real number of days, of the application, including all Application scope variables.
	this.applicationTimeout = createTimeSpan(0, 1, 0, 0);
	this.clientManagement = false;
	this.sessionManagement = false;
	this.setClientCookies = false;
	//this.sessioncookie.httponly = true;
	//this.sessionTimeout = createTimeSpan(0, 0, 30, 0);

	include ".secrets.cfm";

	this.datasources["test"] = {
		class: 'com.microsoft.sqlserver.jdbc.SQLServerDriver',
		bundleName: 'mssqljdbc4',
		bundleVersion: '4.0.2206.100',
		connectionString: 'jdbc:sqlserver://#secrets.DBSERVER#;DATABASENAME=#secrets.DBNAME#;sendStringParametersAsUnicode=true;SelectMethod=direct',
		username: secrets.DBUSERNAME,
		password: secrets.DBPASSWORD,
		connectionLimit: 100 // default:-1
	};
	
	// Whether to send CFID and CFTOKEN cookies to the client browser.
	//this.setClientCookies = false;

	// Whether to set CFID and CFTOKEN cookies for a domain (not just a host).
	//this.setDomainCookies = false;

	// Whether to protect variables from cross-site scripting attacks.
	//this.scriptProtect = false;

	// A struct that contains the following values: server, username, and password.If no value is specified, takes the value in the administrator.
	//this.smtpServersettings = {};

	// Request timeout. Overrides the default administrator settings.
	this.timeout = 30; // seconds

	// Overrides the default administrator settings. It does not report compile-time exceptions.
	//this.enablerobustexception = false;


	// Java Integration
	/*this.javaSettings = { 
		loadPaths = [ ".\lib" ], 
		loadColdFusionClassPath = true, 
		reloadOnChange= false 
	};*/

	
}