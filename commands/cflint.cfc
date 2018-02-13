/**
* Lint CFML code using CFLint. Can be run on a single file or aginst a list of files defined by a file globbing pattern.
* {code:bash}
* cflint **.cfc|**.cfm
* {code}
* .
* Run for all components in the models directory.
* {code:bash}
* cflint models/**.cfc
* {code}
* .
* Generate html report instead of console output.
* .
* {code:bash}
* cflint models/**.cfc --html
* {code}
*/
component {

	/* 
	* Constructor
	*/
	function init() {
		variables.workDirectory  = fileSystemUtil.resolvePath( "." );
		variables.rootPath       = REReplaceNoCase( getDirectoryFromPath( getCurrentTemplatePath() ), "commands(\\|/)", "" );
		variables.cflintJAR      = rootPath & "lib/cflint-1.3.0-all/cflint-1.3.0-all.jar";
		variables.reportTemplate = "/commandbox-cflint/resources/report.cfm" ;
		variables.htmlResultFile = workDirectory & "cflint-results.html";

		return this;
	}

	/* 
	 * Default target
	 */
	public function run( pattern = "**.cfc|**.cfm", html = false ) {
		var fullFilePaths = globber( workDirectory & arguments.pattern ).matches();
		
		// Remove path from files to shorten the command string. Limit is 8191 characters on windows
		var files = fullFilePaths.map( function(item) {
			return replace( item, workDirectory, "" );
		});

		/* Run the report */
		runReport( files, arguments.html );
	
	}

	private void function runReport( required files , html = false ) {
		var reportData = getReportData( files );

		if ( html ) {
			htmlReport( reportData );
			print.greenLine( "Report generated at #htmlResultFile#" );
		}
		else {
			displayReport( reportData );
		}

		/* Make the task fail if an error exists */
		if ( reportData.errorExists ) {
			/* Flush any output to the console */
			print.line().toConsole();
			error( "Please fix errors found by CFLint!" );
		}
	}

	/* 
	 * Get results from cflint and create a data structure we can use to display results
	 */
	private struct function getReportData( required array files ) {

		var data = {
			"version" = "1.2.3",
			"timestamp" = now(),
			"files" = {},
			"errorExists" = false
		};

		var cflintResults = runCFLint( arguments.files );

		data.counts = cflintResults.counts;

		for ( var issue in cflintResults.issues ) {
			
			for ( var item in issue.locations ) {

				/* I wanted store store results by file */
				if ( !structKeyExists( data.files, item.file ) ) {
					data.files[ item.file ] = [];
				}

				/* Combine issue data into a single structure */
				var newIssue = {
					severity = issue.severity,
					id = issue.id,
					message = item.message,
					line = item.line,
					column = item.column,
					expression = item.expression
				};

				/* What color to use in console output? */
				switch ( issue.severity ) {
					case "ERROR":
						newIssue.color = "red";
						data.errorExists = true;
						break;
					case "WARNING":
						newIssue.color = "yellow";
						break;
					default:
						newIssue.color = "magenta";
				}

				data.files[ item.file ].append( newIssue );

			}

		}

		return data;
	}

	/* 
	 * Run cflint on files and get result data structure
	 */
	private any function runCFLint( required array files ) {
		/* Currently we output to a file since redirecting output for OS commands currently does not work in CommandBox. This may change in 4.0. */
		var outputFile = getTempDirectory() & "cflint-output-#createUUID()#.json";

		/* Get JSON data so we can change the structure of the results */
		var commandString = "!java -jar ""#cflintJAR#"" -logerror -quiet -file ""#files.toList()#"" -json -jsonfile ""#outputFile#""";
		command( commandString )
			.inWorkingDirectory( workDirectory )
			.run();

		var output = fileRead( outputFile );
		fileDelete( outputFile );

		return deserializeJSON( output );
	}

	/* 
	 * Generate an html report
	 */
	private string function htmlReport( required data ) {
		var content = "";
		savecontent variable="content" {
			include reportTemplate;
		}

		if ( fileExists( htmlResultFile ) ) {
			fileDelete( htmlResultFile );
		}

		fileWrite( htmlResultFile, content );
	}

	
	/* 
	 * Display the report in the console
	 */
	private void function displayReport( required data ) {

		displaySummary( data );

		print.line();

		for ( var file in data.files ) {

			print.greenLine( chr(9) & file & "   " & data.files[ file ].len() );

			for (var issue in data.files[ file ]) {
				print.text( repeatString( chr(9),2 ) );
				
				print.text(issue.severity, issue.color);
				print.text( ": ");
				print.boldText(issue.id);
				print.text(", #issue.message# ");
				print.cyanLine("[#issue.line#,#issue.column#]");
			}
			
		}
	}

	
	/* 
	 * Displays summary of results in the console
	 */
	private void function displaySummary( required data ) {

		print.line();
		print.greenLine( chr(9) & "Total Files:" & chr(9) & data.counts.totalFiles );
		print.greenLine( chr(9) & "Total Lines:" & chr(9) & data.counts.totalLines );
		for (var item in data.counts.countBySeverity ) {
			print.text(chr(9));
			switch (item.severity) {
				case "ERROR":
					print.boldRedText("ERRORS:" & chr(9) & chr(9));
					break;
				case "WARNING":
					print.boldYellowText( "WARNINGS:" & chr(9) );
					break;
				default:
					print.boldMagentaText( item.severity & ":" & chr(9) & chr(9) );					
			}

			print.line( item.count );
		}
		
	}


}