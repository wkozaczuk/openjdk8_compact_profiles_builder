WORKING_DIR=`pwd $0`/work
PLATFORM_NAME=linux-x86_64-normal-server-release

cp spec.gmk $WORKING_DIR/build/$PLATFORM_NAME

#Generate Version.java for each profile based on a souurce template
cd $WORKING_DIR/jdk/make
cp $WORKING_DIR/../GenerateVersionJava.gmk .
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_1/sun/misc/Version.java
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_2/sun/misc/Version.java
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_3/sun/misc/Version.java

#Compile 5 BUILD tool classes
mkdir -p $WORKING_DIR/build/$PLATFORM_NAME/jdk/btclasses
$WORKING_DIR/j2sdk-image/bin/javac -classpath $WORKING_DIR/j2sdk-image/lib/tools.jar -d $WORKING_DIR/build/$PLATFORM_NAME/jdk/btclasses $(find $WORKING_DIR/jdk/make/src/classes  -name "*.java")
touch $WORKING_DIR/build/$PLATFORM_NAME/jdk/btclasses/_the.BUILD_TOOLS_batch

#Build rt.jar 
mkdir -p $WORKING_DIR/jdk/src/solaris/classes/sun/awt/X11/generator
cd $WORKING_DIR/jdk/make
make SPEC=$WORKING_DIR/build/$PLATFORM_NAME/spec.gmk PROFILE=profile_1 -I ../../make/common -f CreateJars.gmk $WORKING_DIR/build/$PLATFORM_NAME/images/libprofile_1/rt.jar
#META-INF/MANIFEST.MF differs in order of elements
#
#sun/misc/Version.class in original build of JDK 8 compact profiles is of version 51 (Java 7) which seems to be wrong 
#The one this script creates is version 52 (Java 8) which seems to be more correct as other classes are of 
# bytecode version 52

#Build resources.jar
make SPEC=$WORKING_DIR/build/$PLATFORM_NAME/spec.gmk PROFILE=profile_1 -I ../../make/common -f CreateJars.gmk $WORKING_DIR/build/$PLATFORM_NAME/images/libprofile_1/resources.jar
#TODO Fugure out why META-INF/MANIFEST.MF differs (same as above?)

#Build compact JRE image
touch $WORKING_DIR/build/$PLATFORM_NAME/source_tips #TODO FIGUURE how to create it 
make SPEC=$WORKING_DIR/build/$PLATFORM_NAME/spec.gmk PROFILE=profile_1 -I ../../make/common -f Images.gmk JRE_IMAGE_DIR=$WORKING_DIR/build/$PLATFORM_NAME/images/j2re-compact1-image profile-image

#It looks like lib/meta-index has same contenst as originally created one but differes in order
