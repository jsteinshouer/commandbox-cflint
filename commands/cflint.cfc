/**
 * Lint CFML code using CFLint. Can be run on a single file or aginst a list of files defined by a file globbing pattern.
 * {code:bash}
 * cflint **.cfc,**.cfm
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
 *
 * Hide INFO level results.
 * {code:bash}
 * box cflint reportLevel=WARNING
 * {code}
 *
 * Hide INFO and WARNING level results.
 *
 * {code:bash}
 * box cflint reportLevel=ERROR
 * {code}
 *
 * Generate JUnit report.
 * .
 * {code:bash}
 * cflint models/**.cfc --junit
 * {code}
 */
component {

	// What cflint version we are using.
	variables.CFLINT_VERSION  = "1.5.0";
	variables.REPORT_TEMPLATE = "/commandbox-cflint/resources/report.cfm";

	/*
	 * Constructor
	 */
	function init(){
		variables.rootPath = reReplaceNoCase(
			getDirectoryFromPath( getCurrentTemplatePath() ),
			"commands(\\|/)",
			""
		);
		variables.cflintJAR = rootPath & "lib/CFLint-#variables.CFLINT_VERSION#-all/CFLint-#variables.CFLINT_VERSION#-all.jar";

		return this;
	}

	/**
	 * Run the lint command
	 *
	 * @pattern The globbing pattern to lint. You can pass a comma delimited list of patterns as well: models/**.cfc,modules_app/**.cfc
	 * @html Output the report as an HTML file, defaults to `cflint-results.html` unless you use the `fileName` argument
	 * @text Output the report as a text file, defaults to `cflint-results.txt` unless you use the `fileName` argument
	 * @json Output the report as raw JSON to a file, defaults to `cflint-results.json` unelss you use the `fileName` argument.
	 * @junit Output the report as JUnit XML format to a file, defaults to `cflint-results.xml` unelss you use the `fileName` argument.
	 * @fileName The name of the file used for output
	 * @suppress If passed and using output files, it will suppress the console report. Defaults to false
	 * @exitOnError By default, if an error is detected on the linting process we will exit of the shell with an error exit code.
	 * @reportLevel By default this is INFO which means it will display all the found cflint issues. Values are ERROR,WARNING,INFO from showing least to most.
	 */
	public function run(
		pattern             = "**.cfc,**.cfm",
		boolean html        = false,
		boolean text        = false,
		boolean json        = false,
		boolean junit       = false,
		fileName            = "cflint-results",
		boolean suppress    = false,
		boolean exitOnError = true,
		string reportLevel  = "INFO",
		excludePattern		= ""
	){
		var fullFilePaths = [];
		var workDirectory = fileSystemUtil.resolvePath( "." );
		var excludePattern = arguments.excludePattern;

		// Split pattern for lists of globbing patterns
		arguments.pattern
			.listToArray()
			.each( function( item ){
				fullFilePaths.append(
					globber( workDirectory & item )
						.setExcludePattern( listToArray( excludePattern ).map( ( pattern ) => workDirectory & pattern ) )
						.matches(),
					true
				);
			} );

		/* Run the report */
		var reportData = runReport(
			fullFilePaths,
			arguments.html,
			arguments.text,
			arguments.json,
			arguments.junit,
			arguments.fileName,
			arguments.suppress,
			arguments.reportLevel
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
	 * @reportLevel By default this is INFO which means it will display all the found cflint issues. Values are ERROR,WARNING,INFO from showing least to most.
	 *
	 * @return The cflint reportdata struct
	 */
	private function runReport(
		required files,
		boolean html  = false,
		boolean text  = false,
		boolean json  = false,
		boolean junit = false,
		fileName,
		boolean suppress   = false,
		string reportLevel = "INFO"
	){
		// Run the linter
		var timer1     = getTickCount();
		var reportData = getReportData(
			arguments.files,
			arguments.reportLevel
		);
		var timer2        = getTickCount();
		var workDirectory = fileSystemUtil.resolvePath( "." );
		var outputFile    = workDirectory & "/" & reReplaceNoCase(
			arguments.filename,
			"\.xml|\.txt|\.html|\.json",
			""
		);

		// Run Display Procedures
		displayReport( reportData );

		// Store console output from print buffer
		var textReport = print.getResult();

		// Supress Console Output by clearing the output buffer
		if ( arguments.suppress ) {
			print.clear();
		}

		// Text Output
		if ( arguments.text ) {
			fileWrite( outputFile & ".txt", print.unansi(textReport) );
			print.printLine().greenBoldLine( "==> Report generated at #outputFile#.txt" );
		}

		// HTML Output
		if ( arguments.html ) {
			htmlReport( reportData, outputFile & ".html" );
			print.printLine().greenBoldLine( "==> Report generated at #outputFile#.html" );
		}

		// JSON Output
		if ( arguments.json ) {
			fileWrite(
				outputFile & ".json",
				serializeJSON( reportData )
			);
			print.printLine().greenBoldLine( "==> Report generated at #outputFile#.json" );
		}

		// JUnit Output
		if ( arguments.junit ) {
			var totalTime = timer2 - timer1;
			fileWrite(
				outputFile & ".xml",
				getInstance( "JUnitReporter@commandbox-cflint" ).createReport(
					arguments.files,
					reportData,
					totalTime
				)
			);
			print.printLine().greenBoldLine( "==> Report generated at #outputFile#.xml" );
		}

		return reportData;
	}

	/*
	 * Get results from cflint and create a data structure we can use to display results
	 */
	private struct function getReportData(
		required array files,
		string reportLevel = "INFO"
	){
		var data = {
			"version"     : variables.CFLINT_VERSION,
			"timestamp"   : now(),
			"files"       : structNew("ordered"),
			"errorExists" : false
		};

		var cflintResults  = runCFLint( arguments.files );
		var levelsToReport = determineWhatToReport( reportLevel );
		var fileNames = [];
		fileNames.addAll(
			//Using HashSet to dedup
			createObject("java", "java.util.HashSet").init(
				cflintResults.issues
					.map( (issue) => issue.locations )
					.map( (location) => location[1].file )
			)
		);
		fileNames.sort("textnocase");
		//Adding keys in alphabetical order
		for ( var file in fileNames ){
			data.files[ file ] = [];
		}
		data.counts       = cflintResults.counts;
		var codesToRemove = {};

		for ( var issue in cflintResults.issues ) {
			if (
				!structKeyExists(
					levelsToReport,
					uCase( issue.severity )
				)
			) {
				codesToRemove[ issue.id ] = true;
				continue;
			}
			for ( var item in issue.locations ) {

				/* Combine issue data into a single structure */
				var newIssue = {
					severity   : issue.severity,
					id         : issue.id,
					message    : item.message,
					line       : item.line,
					column     : item.column,
					expression : item.expression
				};

				/* What color to use in console output? */
				switch ( issue.severity ) {
					case "ERROR":
						newIssue.color   = "red";
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

		data.counts = filterDataCounts(
			data.counts,
			codesToRemove,
			levelsToReport
		);

		return data;
	}

	private struct function filterDataCounts(
		required any counts,
		required struct codesToRemove,
		required struct levelsToReport
	){
		var newCounts = duplicate( counts );
		for ( var key in codesToRemove ) {
			var index = 0;
			var codes = newCounts[ "countByCode" ];
			for ( var i = 1; i <= arrayLen( codes ); i++ ) {
				if ( uCase( codes[ i ][ "code" ] ) == uCase( key ) ) {
					index = i;
					break;
				}
			}

			if ( index > 0 ) {
				arrayDeleteAt( codes, index );
			}
		}

		for ( var i = arrayLen( newCounts[ "countBySeverity" ] ); i > 0; i-- ) {
			if (
				!structKeyExists(
					levelsToReport,
					newCounts[ "countBySeverity" ][ i ][ "severity" ]
				)
			) {
				arrayDeleteAt( newCounts[ "countBySeverity" ], i );
			}
		}

		return newCounts;
	}

	private struct function determineWhatToReport( required string reportLevel ){
		switch ( reportLevel ) {
			case "WARNING":
				return { "WARNING" : true, "ERROR" : true };
				break;
			case "ERROR":
				return { "ERROR" : true };
				break;
			case "INFO":
			default:
				return {
					"INFO"    : true,
					"WARNING" : true,
					"ERROR"   : true
				};
				break;
		}
	}

	/**
	 * Runs CFLint using the Java API
	 */
	private any function runCFLint( required array files ){
		try {
			var api = createObject(
				"java",
				"com.cflint.api.CFLintAPI",
				"com.cflint.CFLint"
			).init();
		} catch ( any e ) {
			getInstance( "BundleService@commandbox-cflint" ).installBundle( cflintJAR );
			var api = createObject(
				"java",
				"com.cflint.api.CFLintAPI",
				"com.cflint.CFLint"
			).init();
		}

		api.setQuiet( true );
		api.setLogError( true );

		var result = api.scan( files );

		return deserializeJSON( result.getJSON() );
	}

	/**
	 * Generate an html report
	 *
	 * @data The data results
	 * @outputFile The output file location
	 */
	private string function htmlReport( required data, required outputFile ){
		var content = "";

		savecontent variable="content" {
			include REPORT_TEMPLATE;
		}

		if ( fileExists( arguments.outputFile ) ) {
			fileDelete( arguments.outputFile );
		}

		fileWrite( arguments.outputFile, content );
	}

	/*
	 * Display the report in the console
	 */
	private void function displayReport( required data ){
		displaySummary( data );

		print.line();

		for ( var file in data.files ) {
			print.greenLine( chr( 9 ) & file & "   " & data.files[ file ].len() );

			for ( var issue in data.files[ file ] ) {
				print.text( repeatString( chr( 9 ), 2 ) );

				print.text( issue.severity, issue.color );
				print.text( ": " );
				print.boldText( issue.id );
				print.text( ", #issue.message# " );
				print.cyanLine( "[#issue.line#,#issue.column#]" );
			}
		}
	}

	/*
	 * Displays summary of results in the console
	 */
	private void function displaySummary( required data ){
		print.line();
		print.greenLine( chr( 9 ) & "Total Files:" & chr( 9 ) & data.counts.totalFiles );
		print.greenLine( chr( 9 ) & "Total Lines:" & chr( 9 ) & data.counts.totalLines );
		for ( var item in data.counts.countBySeverity ) {
			print.text( chr( 9 ) );
			switch ( item.severity ) {
				case "ERROR":
					print.boldRedText( "ERRORS:" & chr( 9 ) & chr( 9 ) );
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
