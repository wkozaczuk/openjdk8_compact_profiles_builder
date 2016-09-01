# OpenJDK 8 Compact Profiles Build Tool

## Motivation ##
Believe it or not it is very hard to find pre-built compact profiles for OpenJDK 8 unlike full JRE (Java Runtime Environment) or JDK (Java Development Kit). One can always follows instructions (http://www.linuxfromscratch.org/blfs/view/svn/general/openjdk.html) and run "make profiles" to build OpenJDK 8 from scratch from source but it is not a trivial process that requires installation of many dev tools (gcc, etcc) and typically takes 30-60 minutes. So the idea of this tool is to provide an altenative "light-weight" and very fast way (under a minute) to produce any compact profile 1,2,3 JRE based on a corresponding OpenJDK 8 JDK base image.  

Why compact profiles? First off most articles about compact profiles (http://www.oracle.com/technetwork/java/embedded/resources/tech/compact-profiles-overview-2157132.html) give an impression that they are available for embedded platforms only (ARM, etc) however OpenJDK make supports the profiles target that produces all three compact profiles JREs for x86_64 platform. And the work if your app uses only part of JRE library per corresponding profile. The main advantage of the compact profile is its foot print size. Typical size of the "headless" OpenJDK JRE is around 100MB where compact profile 1 JRE is around 34MB, profile 2 - 46MB and profile 3 - 53MB.  

More about compact profiles:
* https://blogs.oracle.com/jtc/entry/a_first_look_at_compact
* https://docs.oracle.com/javase/8/docs/technotes/guides/compactprofiles/compactprofiles.html

## Usage
fetch_open_jdk_artifacts.sh <JDK_DOWNLOAD_URL> <JDK_PROFILE_NUMBER>
### Examples:
* ./build_compact_profile.sh http://download.oracle.com/otn-pub/java/jdk/8u101-b13/jdk-8u101-linux-x64.tar.gz 1
* ./build_compact_profile.sh http://cdn.azul.com/zulu/bin/zulu8.17.0.3-jdk8.0.102-linux_x64.tar.gz 3

## Implementation ##
Step by step:
* Download base JDK
* java -version to determine build version parameters
* Identify mercurial tag based on the version
* Fetch all necessary OpenJDK make files
* Run autoconf
* Unpack base JDK to prepare build with binaries (*.so, etc) and classfiles
* Run make targets to create rt.jar and resources.jar and eventually target image

## TODO LIST ##
* Add more error checks to both scripts
* Change build script to determine PLATFORM_NAME from spec.gmk (CONF_NAME value or simply location of generated spec.gmk under work folder)
* Add ability to generate profile 3 with java beans
* Investigate what it would take to add ability to generate custom compact profiles

