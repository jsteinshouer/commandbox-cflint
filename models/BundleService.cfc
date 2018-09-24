/**
 * OSGi Bundle installer utility
 */
component singleton="true" {

    public any function init() {
        variables.OSGiUtil =  createObject( "java", "lucee.runtime.osgi.OSGiUtil" );
    }

    public void function installBundle( required string bundleFile ) {
		var CFMLEngineFactoryStatic = createObject( "java", "lucee.loader.engine.CFMLEngineFactory" );
        var CFMLEngine = CFMLEngineFactoryStatic.getInstance();
        var resource = CFMLEngine.getResourceUtil().toResourceExisting( getPageContext(), bundleFile );
        
        OSGiUtil.installBundle(
            CFMLEngine.getBundleContext(),
            resource,
            true
        );
    }
    
    public void function removeBundle( required string bundleName, required string bundleVersion ) {
        var version = OSGiUtil.toVersion( arguments.bundleVersion );
        
        var bundle = OSGiUtil.getBundleLoaded(
            arguments.bundleName,
            version,
            javaCast("null","")
        );

		if ( !isNull(bundle) ) {
            bundle.uninstall();
        }
        else {
            throw( "The bundle #bundleName# version #bundleVersion# is not installed" );
        }
			
    }

    public boolean function isBundleInstalled( required string bundleName, required string bundleVersion ) {
        var version = OSGiUtil.toVersion( arguments.bundleVersion );
        
        var bundle = OSGiUtil.getBundleLoaded(
            arguments.bundleName,
            version,
            javaCast("null","")
        );

        return !isNull( bundle );
    }

    public boolean function isBundle( required string filePath ) {
        var file = createObject("java", "java.io.File").init( filePath );
        var bundleInfo = createObject("java", "lucee.runtime.osgi.BundleInfo").init( file );
        
        return bundleInfo.isBundle();
    }
    
}