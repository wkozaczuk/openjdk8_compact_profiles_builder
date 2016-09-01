#!/bin/bash
JDK_DOWNLOAD_URL=$1
JDK_PROFILE_NUMBER=$2

# Validate parameters
if [ -z "$JDK_DOWNLOAD_URL" ] || [ -z "$JDK_PROFILE_NUMBER" ]; then
  echo "Usage: build_compact_profile.sh <JDK_DOWNLOAD_URL> <JDK_PROFILE_NUMBER>"
  exit 1
fi

if [ "$JDK_PROFILE_NUMBER" != "1" ] && [ "$JDK_PROFILE_NUMBER" != "2" ] && [ "$JDK_PROFILE_NUMBER" != "3" ]; then
  echo "Usage: the profile name needs to be 1, 2 or 3"
  exit 1
fi

# Clean up work directory if present
WORKING_DIR=`pwd $0`/work
rm -rf $WORKING_DIR

# Fetch JDK using wget if URL starts with http otherwise assume local file and copy using cp
BASE_JDK_MAGE_DIR=$WORKING_DIR/base_jdk_image
mkdir -p $BASE_JDK_MAGE_DIR
cd $BASE_JDK_MAGE_DIR
JDK_DOWNLOAD_URL_PROTOCOL=`echo $JDK_DOWNLOAD_URL | grep -o '^http'`
if [ "$JDK_DOWNLOAD_URL_PROTOCOL" == "http" ]; then
  wget --no-cookies --no-check-certificate --header "Cookie:oraclelicense=accept-securebackup-cookie" $JDK_DOWNLOAD_URL
elif [ -f "$JDK_DOWNLOAD_URL" ]; then
  cp $JDK_DOWNLOAD_URL .
else 
  echo "The JDK download URL: $JDK_DOWNLOAD_URL is neither accesible through wget or can be copied locally"
fi

# Extract JDK tarball
TARBALL=`find . -name \*tar.gz`
tar xfz $TARBALL
rm $TARBALL

# Identify JDK directory root
JAVAC_FILE=`find . -name javac`
if [ ! -f "$JAVAC_FILE" ]; then
  echo "Extracted tarball does not have javac in it -> does not look like a JDK"
  exit 1
fi
JDK_DIRECTORY="$BASE_JDK_MAGE_DIR"/`dirname $JAVAC_FILE`"/.."
echo "Identified source root JDK directory: $JDK_DIRECTORY"

# Run java -version from the source JDK and capture output 
$JDK_DIRECTORY/bin/java -version 2>&1 | head -n 2 | tail -n 1 | grep -o '(build.*)' > $WORKING_DIR/java_build.version

# Identify all version parameters and replace in spec.gmk.in
cd $WORKING_DIR
JDK_MAJOR_VERSION=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\1/'`
JDK_MINOR_VERSION=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\2/'`
JDK_UPDATE_VERSION=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\3/'`
JDK_MILESTONE=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\4/' | grep -o '[^-]*'`
JDK_BUILD_NUMBER=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\5/'`
COOKED_JDK_UPDATE_VERSION=$JDK_UPDATE_VERSION"0"

# Set milestone if empty
if [ -z "$JDK_MILESTONE" ]; then
  JDK_MILESTONE='fcs'
fi

JDK_BUILD_TAG_SEARCH_STRING="$JDK_UPDATE_VERSION-$JDK_BUILD_NUMBER"

echo "Searching release revisions by $JDK_BUILD_TAG_SEARCH_STRING"
wget -q http://hg.openjdk.java.net/jdk8u/jdk8u/tags -O root_jdk_tags
ROOT_FOLDER_HG_REVISION=`tr "\n" " " < root_jdk_tags | grep -o "\w*\">\s*jdk8u$JDK_BUILD_TAG_SEARCH_STRING" | grep -o '^\w*'`
echo "JDK root folder revision: "$ROOT_FOLDER_HG_REVISION
rm root_jdk_tags

wget -q http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/tags -O jdk_jdk_tags
JDK_FOLDER_HG_REVISION=`tr "\n" " " < jdk_jdk_tags | grep -o "\w*\">\s*jdk8u$JDK_BUILD_TAG_SEARCH_STRING" | grep -o '^\w*'`
echo "JDK jdk folder revision: "$JDK_FOLDER_HG_REVISION
rm jdk_jdk_tags

# Fetch open JDK artifacts
mkdir -p $WORKING_DIR/jdk
cd $WORKING_DIR/jdk
echo "Downloading Open JDK artificats from http://hg.openjdk.java.net/jdk8u/jdk8u/jdk based on the list in open_jdk_jdk_folder_files_to_fetch"
wget --no-host-directories --force-directories --cut-dirs=5 --base="http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/raw-file/$JDK_FOLDER_HG_REVISION/" \
     --input-file=$WORKING_DIR/../open_jdk_jdk_folder_files_to_fetch -o open_jdk_jdk_folder_files_to_fetch.log

cd $WORKING_DIR
echo "Downloading Open JDK artificats from http://hg.openjdk.java.net/jdk8u/jdk8u based on the list in open_jdk_root_folder_files_to_fetch"
wget --no-host-directories --force-directories --cut-dirs=4 --base="http://hg.openjdk.java.net/jdk8u/jdk8u/raw-file/$ROOT_FOLDER_HG_REVISION/" \
     --input-file=$WORKING_DIR/../open_jdk_root_folder_files_to_fetch -o open_jdk_root_folder_files_to_fetch.log

# Replace version parameters in spec.gmk.in
echo "Setting up JDK version parameters"
sed -i "s/@JDK_MAJOR_VERSION@/$JDK_MAJOR_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_MINOR_VERSION@/$JDK_MINOR_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_MICRO_VERSION@/0/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_UPDATE_VERSION@/$JDK_UPDATE_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_BUILD_NUMBER@/$JDK_BUILD_NUMBER/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@MILESTONE@/$JDK_MILESTONE/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_VERSION@/$JDK_MAJOR_VERSION.$JDK_MINOR_VERSION.0_$JDK_UPDATE_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@COOKED_JDK_UPDATE_VERSION@/$COOKED_JDK_UPDATE_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@USER_RELEASE_SUFFIX@//g" $WORKING_DIR/common/autoconf/spec.gmk.in

# Run autoconf
echo "Running autoconf to generate configure for this platform"
cp $WORKING_DIR/../configure.ac $WORKING_DIR/common/autoconf/configure.ac
cp $WORKING_DIR/../linux_x64_binaries_extensions.m4 $WORKING_DIR/common/autoconf/linux_x64_binaries_extensions.m4
cd $WORKING_DIR/common/autoconf
autoconf configure.ac > configure
chmod u+x configure

# Run generated configure 
echo "Executing configure"
PLATFORM_NAME=linux-x86_64-normal-server-release
cd $WORKING_DIR
mkdir -p build/$PLATFORM_NAME
cd $WORKING_DIR/build/$PLATFORM_NAME
export PATH=$JDK_DIRECTORY/bin:$PATH
$WORKING_DIR/common/autoconf/configure > $WORKING_DIR/configure.log

# Copy rt.jar, resources.jar from the source JDK and extract it
echo "Extracting rt.jar, resources.jar and copying all binaries from base JDK base into build subdirectories"
cd $WORKING_DIR
mkdir -p build/$PLATFORM_NAME/jdk/classes
cd build/$PLATFORM_NAME/jdk/classes/
jar -xf $JDK_DIRECTORY/jre/lib/rt.jar
jar -xf $JDK_DIRECTORY/jre/lib/resources.jar
rm sun/misc/Version.class

mkdir -p $WORKING_DIR/build/$PLATFORM_NAME/langtools/dist/bootstrap/lib/
cp $JDK_DIRECTORY/lib/tools.jar $WORKING_DIR/build/$PLATFORM_NAME/langtools/dist/bootstrap/lib/javac.jar

# Copy *.so and other artifacts from source JDK to the build subdirectories
mkdir -p $WORKING_DIR/build/$PLATFORM_NAME/images/lib/
cp -rf $JDK_DIRECTORY/jre/lib $WORKING_DIR/build/$PLATFORM_NAME/images
cp -rf $JDK_DIRECTORY/jre/bin $WORKING_DIR/build/$PLATFORM_NAME/jdk

# Generate Version.java for each profile based on a source template
cd $WORKING_DIR/jdk/make
cp $WORKING_DIR/../GenerateVersionJava.gmk .
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_1/sun/misc/Version.java
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_2/sun/misc/Version.java
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_3/sun/misc/Version.java

# Compile 5 BUILD tool classes
mkdir -p $WORKING_DIR/build/$PLATFORM_NAME/jdk/btclasses
$JDK_DIRECTORY/bin/javac -classpath $JDK_DIRECTORY/lib/tools.jar -d $WORKING_DIR/build/$PLATFORM_NAME/jdk/btclasses $(find $WORKING_DIR/jdk/make/src/classes  -name "*.java")
touch $WORKING_DIR/build/$PLATFORM_NAME/jdk/btclasses/_the.BUILD_TOOLS_batch

# Build rt.jar 
mkdir -p $WORKING_DIR/jdk/src/solaris/classes/sun/awt/X11/generator
cd $WORKING_DIR/jdk/make
make ALL_FILES_IN_CLASSES="" SPEC=$WORKING_DIR/build/$PLATFORM_NAME/spec.gmk PROFILE=profile_$JDK_PROFILE_NUMBER -I ../../make/common -f CreateJars.gmk \
 $WORKING_DIR/build/$PLATFORM_NAME/images/libprofile_$JDK_PROFILE_NUMBER/rt.jar
#META-INF/MANIFEST.MF differs in order of elements
#
#sun/misc/Version.class in original build of JDK 8 compact profiles is of version 51 (Java 7) which seems to be wrong 
#The one this script creates is version 52 (Java 8) which seems to be more correct as other classes are of 
# bytecode version 52

# Build resources.jar
make ALL_FILES_IN_CLASSES="" SPEC=$WORKING_DIR/build/$PLATFORM_NAME/spec.gmk PROFILE=profile_$JDK_PROFILE_NUMBER -I ../../make/common -f CreateJars.gmk \
  $WORKING_DIR/build/$PLATFORM_NAME/images/libprofile_$JDK_PROFILE_NUMBER/resources.jar
#TODO Figure out why META-INF/MANIFEST.MF differs (same as above?)

# Build compact JRE image
touch $WORKING_DIR/build/$PLATFORM_NAME/source_tips #TODO FIGUURE how to create it 
make SPEC=$WORKING_DIR/build/$PLATFORM_NAME/spec.gmk PROFILE=profile_$JDK_PROFILE_NUMBER -I ../../make/common -f Images.gmk \
  JRE_IMAGE_DIR=$WORKING_DIR/build/$PLATFORM_NAME/images/j2re-compact$JDK_PROFILE_NUMBER-image profile-image

# It looks like lib/meta-index has same content as originally created one but differs in order
echo "Created profile image under $WORKING_DIR/build/$PLATFORM_NAME/images/j2re-compact$JDK_PROFILE_NUMBER-image"
