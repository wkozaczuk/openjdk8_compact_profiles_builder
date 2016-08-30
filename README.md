# openjdk8_compact_profiles_builder
OpenJDK 8 compact profiles build too

## TODO LIST ##
* Change fetch script to first pull JDK using wget (URL as a parameter) and extract all version parameters 
* Add logic to fetch script to determine HG revisions based on JDK version
* Change all scripts to take profile number to be created as a parameter
* Add logic to the scripts to verify the JDK downloadable URL actually works and if JDK is runnable on the platform
* Change build script to determine PLATFORM_NAME from spec.gmk (CONF_NAME value or simply location of generated spec.gmk under work folder)
