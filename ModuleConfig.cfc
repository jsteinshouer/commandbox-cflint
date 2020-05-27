component {

	this.name      = "commandbox-cflint";
	this.cfmapping = "commandbox-cflint";

	function configure(){
		settings = { cflint_version : "1.5.0" };
	}

	function onLoad(){
		var bundleService = wirebox.getInstance( "BundleService@commandbox-cflint" );
		var jarFile       = modulePath & "/lib/CFLint-#settings.cflint_version#-all/CFLint-#settings.cflint_version#-all.jar";

		if (
			!bundleService.isBundleInstalled(
				"com.cflint.CFLint",
				settings.cflint_version
			)
		) {
			bundleService.installBundle( jarFile );
		}
	}

}
