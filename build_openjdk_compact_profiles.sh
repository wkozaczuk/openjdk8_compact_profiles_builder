WORKING_DIR=`pwd $0`/work
PLATFORM_NAME=linux-x86_64-normal-server-release

cp spec.gmk $WORKING_DIR/build/$PLATFORM_NAME

#Generate Version.java for each profile based on a souurce template
cd $WORKING_DIR/jdk/make
cp $WORKING_DIR/../GenerateVersionJava.gmk .
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_1/sun/misc/Version.java
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_2/sun/misc/Version.java
make -f GenerateVersionJava.gmk $WORKING_DIR/build/$PLATFORM_NAME/jdk/gen_profile_3/sun/misc/Version.java
