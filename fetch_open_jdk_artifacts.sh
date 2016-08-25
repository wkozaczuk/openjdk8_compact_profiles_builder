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

#Run autoconf
cp $WORKING_DIR/../configure.ac $WORKING_DIR/common/autoconf/configure.ac
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
