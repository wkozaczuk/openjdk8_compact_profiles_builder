# OpenJDK 8 Compact Profiles Build Tool

## Motivation ##
Believe it or not it is close to impossible to find **pre-built** compact profiles for OpenJDK 8. One can follow instructions (http://www.linuxfromscratch.org/blfs/view/svn/general/openjdk.html) and run **make profiles** to build OpenJDK 8 from scratch from source but it is not a trivial process and it requires installation of many dev tools like gcc and typically takes 30-60 minutes to complete. So the main premise of this tool is to provide an altenative **"light-weight"** and **very fast** way (under a minute) to produce a compact profile 1, 2 or 3 JRE from a corresponding OpenJDK 8 JDK base image. For now the tool supports Linux x86_64 platform only. 

What are compact profiles and what so special about them? Java 8 compact profiles are a reduced size JRE (Java Runtime Environment) that provide a subset of Java APIs from a regular JRE. The JVM app will run on compact profile JRE if it uses only part of Java APIs prescribed by corresponding profile. The main advantage of the compact profile is its foot print size. Typical size of the "headless" OpenJDK JRE is a little over 100MB whereas compact profile 1 JRE is around 34MB, profile 2 - 46MB and profile 3 - 53MB. Smaller size leads to slightly faster boot time, less memory used by JRE bytecode and smaller security attack line. Project Jigsaw that is part of Java 9 is going to come with jlink tool that will let one create custom compact profile JRE.

More about compact profiles:
* https://blogs.oracle.com/jtc/entry/a_first_look_at_compact
* https://docs.oracle.com/javase/8/docs/technotes/guides/compactprofiles/compactprofiles.html
* http://www.oracle.com/technetwork/java/embedded/resources/tech/compact-profiles-overview-2157132.html

## Usage
```build_compact_profile.sh <JDK_DOWNLOAD_URL> <JDK_PROFILE_NUMBER> <<add_java_beans>>```
##### Examples:
* ./build_compact_profile.sh http://download.oracle.com/otn-pub/java/jdk/8u101-b13/jdk-8u101-linux-x64.tar.gz 1
* ./build_compact_profile.sh http://cdn.azul.com/zulu/bin/zulu8.17.0.3-jdk8.0.102-linux_x64.tar.gz 3
* ./build_compact_profile.sh http://cdn.azul.com/zulu/bin/zulu8.17.0.3-jdk8.0.102-linux_x64.tar.gz 3 add_java_beans
 
## Background
Open JDK build process involves compiling C source code that comprises the JVM runtime as well as Java source code that makes up content of rt.jar, resources.jar and other standard JRE and JDK jars. It is based on set of make files (Makefile, *.gmk files) and standard m4 and autoconf template files. The default make target produces regular (aka full) JRE and JDK images.The profiles target on other hand creates corresponding compact profile images by essentially repackaging original binaries based on profile-includes.txt and creating corresponding rt.jar and resources.jar based on profile-rtjar-includes.txt. In short one can make an observation that it should be possible to take regular JRE, extract its content and rt.jar and resources.jar and follow same steps that are part of the profiles target to create compact profile JRE without a need to compile any C nor Java code with some exceptions.

## Implementation ##
Step by step (simplified):
* Download base JDK and unpack its content as well as rt.jar and resources.jar
* Run java -version in base JDK to determine build version parameters
* Identify mercurial tag based on the version parameters determines in previous step
* Fetch all necessary OpenJDK make files as well as Java source code of 4 tool programs from http://hg.openjdk.java.net/jdk8u/jdk8u/
* Run autoconf to produce spec.gmk and configure
* Run make targets to create rt.jar and resources.jar and eventually target image
* Optionally add java.beans to the rt.jar if add_java_beans specified

## TODO LIST ##
* Add more error checks to both scripts
* Change build script to determine PLATFORM_NAME from spec.gmk (CONF_NAME value or simply location of generated spec.gmk under work folder)
* Investigate what it would take to add ability to generate custom compact profiles
