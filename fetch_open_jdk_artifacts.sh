WORKING_DIR=`pwd $0`/work
JDK_FOLDER_HG_REVISION="48c99b423839"
ROOT_FOLDER_HG_REVISION="daafd7d3a76a"

mkdir -p $WORKING_DIR/jdk
cd $WORKING_DIR/jdk
wget --no-host-directories --force-directories --cut-dirs=5 --base="http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/raw-file/$JDK_FOLDER_HG_REVISION/" \
     --input-file=$WORKING_DIR/../open_jdk_jdk_folder_files_to_fetch

# THIS MIGHT BE TEMPORARY AS ENTIRE data folder needs to be fetched
#characterdata
#charsetmapping
#checkdeps
#classlist
#cryptopolicy/limited
#cryptopolicy/unlimited
#dtdbuilder
#jdwp
#mainmanifest
#swingbeaninfo/images
#swingbeaninfo/javax/swing
#swingbeaninfo/sun/swing
#swingbeaninfo/SwingBeanInfo.template
#swingbeaninfo/manifest.mf
#tzdata
#unicodedata

cd $WORKING_DIR
wget --no-host-directories --force-directories --cut-dirs=4 --base="http://hg.openjdk.java.net/jdk8u/jdk8u/raw-file/$ROOT_FOLDER_HG_REVISION/" \
     --input-file=$WORKING_DIR/../open_jdk_root_folder_files_to_fetch
