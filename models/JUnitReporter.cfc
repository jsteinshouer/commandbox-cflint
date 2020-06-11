/**
 *
 * Creates a JUnit report
 *
 *
 */
component output="false" singleton="true" {

	property name="fileSystemUtil" inject="FileSystem";

	/**
	 *
	 * Create the JUNit XML Report
	 *
	 * @files Files that were scanned with CFLint
	 * @results CFLint results structure
	 * @totalTime Time it took to get the CFLint results
	 *
	 */
	public string function createReport(
		required array files,
		required struct results,
		numeric totalTime = 0
	){
		var workDirectory = fileSystemUtil.resolvePath( "." );

		var output = "<?xml version=""1.0"" encoding=""UTF-8""?>";
		output &= "<testsuites name=""CFLint.ScanResults"" time=""#totalTime#"" tests=""#files.len()#"" errors=""0"">";

		for ( var file in arguments.files ) {
			var fullPath     = fileSystemUtil.resolvePath( file );
			var relativePath = replace(
				replace( file, workDirectory, "" ),
				"\",
				"/",
				"all"
			);
			var package = replace(
				replace( relativePath, "/", ".", "all" ),
				"." & relativePath.listLast( "/" ),
				""
			);
			var classname = replace(
				relativePath,
				relativePath.right( 4 ),
				""
			);
			var hasErrors  = structKeyExists( results.files, fullPath );
			var errorCount = hasErrors ? results.files[ fullPath ].len() : 0;
			output &= "<testsuite package=""#package#"" time=""0"" tests=""#errorCount#"" errors=""#errorCount#"" name=""#relativePath#"">";

			if ( hasErrors ) {
				for ( var issue in results.files[ fullPath ] ) {
					output &= "<testcase time=""0"" name=""#issue.id#"" classname=""#classname#"">";
					output &= "<failure type=""#issue.severity#"" message=""#encodeForXMLAttribute( issue.message )#"">";
					output &= "<![CDATA[";
					output &= "line #issue.line#, col ";
					output &= "#issue.column#, #issue.severity#";
					output &= " - #encodeForXML( issue.message )#";
					output &= "(#issue.id#)";
					output &= "]]>";
					output &= "</failure>";
					output &= "</testcase>";
				}
			} else {
				output &= "<testcase time=""0"" name=""NO_ISSUES_FOUND"" classname=""#classname#"" />";
			}

			output &= "</testsuite>";
		}

		output &= "</testsuites>";

		return output;
	}

}
