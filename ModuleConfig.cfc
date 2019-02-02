component {

	this.name = "commandbox-cflint";
	this.cfmapping = "commandbox-cflint";

	function configure() {

	}

	function onLoad(){

		var bundleService = wirebox.getInstance("BundleService@commandbox-cflint");
		var jarFile = modulePath & "/lib/CFLint-1.4.1-all/CFLint-1.4.1-all.jar";

		if ( !bundleService.isBundleInstalled( "com.cflint.CFLint", "1.4.1" ) ) {
			bundleService.installBundle( jarFile );
		}
		
	}

}