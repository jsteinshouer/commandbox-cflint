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
component{

	// What cflint version we are using.
	variables.CFLINT_VERSION = "1.3.0";

	/*
	* Constructor
	*/
	function init(){
		variables.workDirectory  = fileSystemUtil.resolvePath( "." );
		variables.rootPath       = REReplaceNoCase( getDirectoryFromPath( getCurrentTemplatePath() ), "commands(\\|/)", "" );
		variables.cflintJAR      = rootPath & "lib/CFLint-#variables.CFLINT_VERSION#-all/CFLint-#variables.CFLINT_VERSION#-all.jar";
		variables.reportTemplate = "/commandbox-cflint/resources/report.cfm" ;

		return this;
	}

	/**
	 * Run the lint command
	 *
	 * @pattern The globbing pattern to lint. You can pass a comma delimmitted list of patterns as well: models/**.cfc,modules_app/**.cfc
	 * @html Output the report as an HTML file, defaults to `cflint-results.html` unless you use the `fileName` argument
	 * @text Output the report as a text file, defaults to `cflint-results.txt` unless you use the `fileName` argument
	 * @json Output the report as raw JSON to a file, defaults to `cflint-results.json` unelss you use the `fileName` argument.
	 * @fileName The name of the file used for output
	 * @suppress If passed and using output files, it will suppress the console report. Defaults to false
	 * @exitOnError By default, if an error is detected on the linting process we will exit of the shell with an error exit code.
	 */
	public function run(
		pattern = "**.cfc|**.cfm",
		boolean html = false,
		boolean text = false,
		boolean json = false,
		fileName = "cflint-results",
		boolean suppress = false,
		boolean exitOnError = true
	) {
		var fullFilePaths = [];
		// Split pattern for lists of globbing patterns
		arguments.pattern
			.listToArray()
			.each( function( item ){
				fullFilePaths.append(
					globber( workDirectory & item ).matches(), true
				);
			} );

		// Remove path from files to shorten the command string. Limit is 8191 characters on windows
		var files = fullFilePaths.map( function( item ){
			return replace( item, workDirectory, "" );
		} );

		/* Run the report */
		var reportData = runReport(
			files,
			arguments.html,
			arguments.text,
			arguments.json,
			arguments.fileName,
			arguments.suppress
		);

		/* Make the task fail if an error exists */
		if ( reportData.errorExists && arguments.exitOnError ) {
			/* Flush any output to the console */
			print.line().toConsole();
			error( "Please fix errors found by CFLint!" );
		}
	}

	/****************************************** PRIVATE ************************************/

	/**
	 * Run the report for the following files and output conditions
	 *
	 * @files The array of files to lint
	 * @html Output the report as an HTML file, defaults to `cflint-results.html` unless you use the `fileName` argument
	 * @text Output the report as a text file, defaults to `cflint-results.txt` unless you use the `fileName` argument
	 * @json Output the report as raw JSON to a file, defaults to `cflint-results.json` unelss you use the `fileName` argument.
	 * @fileName The name of the file used for output
	 * @suppress If passed and using output files, it will suppress the console report. Defaults to false
	 *
	 * @return The cflint reportdata struct
	 */
	private function runReport(
		required files,
		boolean html = false,
		boolean text = false,
		boolean json = false,
		fileName,
		boolean suppress=false
	){
		// Run the linter
		var reportData = getReportData( arguments.files );
		var outputFile = variables.workDirectory & "/" & arguments.fileName;

		// Run Display Procedures
		displayReport( reportData );

		// Store console output from print buffer
		var textReport = print.getResult();

		// Supress Console Output by clearing the output buffer
		if( arguments.suppress ){
			print.clear();
		}

		// Text Output
		if( arguments.text ){
			fileWrite( outputFile & ".txt", textReport );
			print.printLine()
				.greenBoldLine( "==> Report generated at #outputFile#.txt" );
		}

		// HTML Output
		if ( arguments.html ) {
			htmlReport( reportData, outputFile & ".html" );
			print.printLine()
				.greenBoldLine( "==> Report generated at #outputFile#.html" );
		}

		// JSON Output
		if( arguments.json ){
			fileWrite( outputFile & ".json", serializeJSON( reportData ) );
			print.printLine()
				.greenBoldLine( "==> Report generated at #outputFile#.json" );
		}

		return reportData;
	}

	/*
	 * Get results from cflint and create a data structure we can use to display results
	 */
	private struct function getReportData( required array files ) {

		var data = {
			"version"     = variables.CFLINT_VERSION,
			"timestamp"   = now(),
			"files"       = {},
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

	/**
	 * Generate an html report
	 *
	 * @data The data results
	 * @outputFile The output file location
	 */
	private string function htmlReport( required data, required outputFile ) {
		var content 	= "";

		savecontent variable="content" {
			include reportTemplate;
		}

		if ( fileExists( arguments.outputFile ) ) {
			fileDelete( arguments.outputFile );
		}

		fileWrite( arguments.outputFile, content );
	}


	/*
	 * Display the report in the console
	 */
	private void function displayReport( required data ) {

		displaySummary( data );

		print.line();

		for ( var file in data.files ) {

			print.greenLine( chr( 9 ) & file & "   " & data.files[ file ].len() );

			for( var issue in data.files[ file ] ){
				print.text( repeatString( chr( 9 ), 2 ) );

				print.text( issue.severity, issue.color );
				print.text( ": ");
				print.boldText( issue.id );
				print.text( ", #issue.message# " );
				print.cyanLine( "[#issue.line#,#issue.column#]" );
			}

		}
	}

	/*
	 * Displays summary of results in the console
	 */
	private void function displaySummary( required data ) {

		print.line();
		print.greenLine( chr( 9 ) & "Total Files:" & chr( 9 ) & data.counts.totalFiles );
		print.greenLine( chr( 9 ) & "Total Lines:" & chr( 9 ) & data.counts.totalLines );
		for( var item in data.counts.countBySeverity ){
			print.text( chr( 9 ) );
			switch (item.severity) {
				case "ERROR":
					print.boldRedText("ERRORS:" & chr( 9 ) & chr( 9 ));
					break;
				case "WARNING":
					print.boldYellowText( "WARNINGS:" & chr( 9 ) );
					break;
				default:
					print.boldMagentaText( item.severity & ":" & chr( 9 ) & chr( 9 ) );
			}

			print.line( item.count );
		}

	}

}