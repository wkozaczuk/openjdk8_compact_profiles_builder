WORKING_DIR=`pwd $0`/work
JDK_FOLDER_HG_REVISION="48c99b423839"
ROOT_FOLDER_HG_REVISION="daafd7d3a76a"

mkdir -p $WORKING_DIR/jdk
cd $WORKING_DIR/jdk
wget --no-host-directories --force-directories --cut-dirs=5 --base="http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/raw-file/$JDK_FOLDER_HG_REVISION/" \
     --input-file=$WORKING_DIR/../open_jdk_jdk_folder_files_to_fetch

cd $WORKING_DIR
wget --no-host-directories --force-directories --cut-dirs=4 --base="http://hg.openjdk.java.net/jdk8u/jdk8u/raw-file/$ROOT_FOLDER_HG_REVISION/" \
     --input-file=$WORKING_DIR/../open_jdk_root_folder_files_to_fetch

#TODO Replace with wget to fetch source openjdk 8 tar gz
cp /home/ubuntu/openjdk-8u/build/linux-x86_64-normal-server-release/images/j2sdk.tar.gz $WORKING_DIR

cd $WORKING_DIR
tar xfz j2sdk.tar.gz
rm j2sdk.tar.gz

#Run java -version from the source JDK and identify all parameters and replace in spec.gmk.in
$WORKING_DIR/j2sdk-image/bin/java -version 2>&1 | head -n 2 | tail -n 1 | grep -o '(build.*)' > $WORKING_DIR/java_build.version

JDK_MAJOR_VERSION=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\1/'`
JDK_MINOR_VERSION=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\2/'`
JDK_UPDATE_VERSION=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\3/'`
JDK_MILESTONE=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\4/' | grep -o '[^-]*'`
JDK_BUILD_NUMBER=`cat java_build.version | sed -E 's/.*build ([0-9])\.([0-9])\.0_([0-9]*)-([^\s\)]+-)?([^\s\)]+).*/\5/'`
COOKED_JDK_UPDATE_VERSION=$JDK_UPDATE_VERSION"0"

#Set milestone if empty
if [ -z "$JDK_MILESTONE" ]; then
  JDK_MILESTONE='fcs'
fi

sed -i "s/@JDK_MAJOR_VERSION@/$JDK_MAJOR_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_MINOR_VERSION@/$JDK_MINOR_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_MICRO_VERSION@/0/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_UPDATE_VERSION@/$JDK_UPDATE_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_BUILD_NUMBER@/$JDK_BUILD_NUMBER/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@MILESTONE@/$JDK_MILESTONE/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@JDK_VERSION@/$JDK_MAJOR_VERSION.$JDK_MINOR_VERSION.0_$JDK_UPDATE_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@COOKED_JDK_UPDATE_VERSION@/$COOKED_JDK_UPDATE_VERSION/g" $WORKING_DIR/common/autoconf/spec.gmk.in
sed -i "s/@USER_RELEASE_SUFFIX@//g" $WORKING_DIR/common/autoconf/spec.gmk.in

#Run autoconf
cp $WORKING_DIR/../configure.ac $WORKING_DIR/common/autoconf/configure.ac
cp $WORKING_DIR/../linux_x64_binaries_extensions.m4 $WORKING_DIR/common/autoconf/linux_x64_binaries_extensions.m4
cd $WORKING_DIR/common/autoconf
autoconf configure.ac > configure
chmod u+x configure

#Run generated configure 
PLATFORM_NAME=linux-x86_64-normal-server-release
cd $WORKING_DIR
mkdir -p build/$PLATFORM_NAME
cd $WORKING_DIR/build/$PLATFORM_NAME
export PATH=$WORKING_DIR/j2sdk-image/bin:$PATH
$WORKING_DIR/common/autoconf/configure

cd $WORKING_DIR
mkdir -p build/$PLATFORM_NAME/jdk/classes
cd build/$PLATFORM_NAME/jdk/classes/
jar -xf $WORKING_DIR/j2sdk-image/jre/lib/rt.jar
jar -xf $WORKING_DIR/j2sdk-image/jre/lib/resources.jar
rm sun/misc/Version.class

mkdir -p $WORKING_DIR/build/$PLATFORM_NAME/langtools/dist/bootstrap/lib/
cp $WORKING_DIR/j2sdk-image/lib/tools.jar $WORKING_DIR/build/$PLATFORM_NAME/langtools/dist/bootstrap/lib/javac.jar

mkdir -p $WORKING_DIR/build/$PLATFORM_NAME/images/lib/
cp -rf $WORKING_DIR/j2sdk-image/jre/lib $WORKING_DIR/build/$PLATFORM_NAME/images
cp -rf $WORKING_DIR/j2sdk-image/jre/bin $WORKING_DIR/build/$PLATFORM_NAME/jdk
