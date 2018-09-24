component {

	this.name = "commandbox-cflint";
	this.cfmapping = "commandbox-cflint";

	function configure() {

	}

	function onLoad(){

		var bundleService = wirebox.getInstance("BundleService@commandbox-cflint");
		var jarFile = modulePath & "/lib/CFLint-1.4.0-all/CFLint-1.4.0-all.jar";

		if ( !bundleService.isBundle( jarFile ) ) {
			createCFLintBundle( jarFile );
		}

		if ( !bundleService.isBundleInstalled( "com.cflint.CFLint", "1.4.0" ) ) {
			bundleService.installBundle( jarFile );
		}
		
	}

	private function createCFLintBundle( required string jarFile ) {

		bundleManifest = modulePath & "/resources/MANIFEST.MF"

        cfzip( action = "delete", file = jarFile, entryPath = "/META-INF/MANIFEST.MF" );
        cfzip( action = "zip", file = jarFile ) {
            cfzipparam( source = bundleManifest, entryPath = "META-INF/MANIFEST.MF" );
        }

    }

}