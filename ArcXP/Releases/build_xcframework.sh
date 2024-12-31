echo "Building iOS simulator and device frameworks for release."

PRODUCT_NAME=ArcXP
PROJECT=./${PRODUCT_NAME}.xcodeproj
SCHEME_iOS=${PRODUCT_NAME}
 SCHEME_tvOS=${PRODUCT_NAME}tvOS
CONFIGURATION=Release
FLAGS="ONLY_ACTIVE_ARCH=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO"
ACTIONS="clean archive"
OUTPUT_DIR=./XCFramework
OUTPUT_FRAMEWORK_PATH=./Products/Library/Frameworks/${PRODUCT_NAME}.framework

if [ -z "$GITHUB_WORKSPACE" ]
then
    DEPLOY_DIR=./Frameworks/
    LOG_FILE=${OUTPUT_DIR}/build.log
else
    DEPLOY_DIR=$GITHUB_WORKSPACE/Frameworks
    LOG_FILE=$GITHUB_WORKSPACE/build.log
fi

rm -rf ${OUTPUT_DIR}/*
mkdir -p ${OUTPUT_DIR}
mkdir -p ${DEPLOY_DIR}

 echo -n "Building for iPhone device....................." \
  && xcodebuild archive -scheme ${SCHEME_iOS} -configuration ${CONFIGURATION} -archivePath ${OUTPUT_DIR}/${PRODUCT_NAME}-iphoneos -sdk iphoneos ${FLAGS} ${ACTIONS} >& ${LOG_FILE} \
&& echo "done." \
&& echo -n "Building for iPhone simulator.................." \
  && xcodebuild archive -scheme ${SCHEME_iOS} -configuration ${CONFIGURATION} -archivePath ${OUTPUT_DIR}/${PRODUCT_NAME}-iphonesimulator -sdk iphonesimulator ${FLAGS} ${ACTIONS} >> ${LOG_FILE} 2>&1  \
&& echo "done." \
&& echo -n "Building for AppleTV device...................." \
&& xcodebuild archive -scheme ${SCHEME_tvOS} -configuration ${CONFIGURATION} -archivePath ${OUTPUT_DIR}/${PRODUCT_NAME}-appletvos -sdk appletvos ${FLAGS} ${ACTIONS} >> ${LOG_FILE} 2>&1 \
&& echo "done." \
&& echo -n "Building for AppleTV simulator................." \
&& xcodebuild archive -scheme ${SCHEME_tvOS} -configuration ${CONFIGURATION} -archivePath ${OUTPUT_DIR}/${PRODUCT_NAME}-appletvsimulator -sdk appletvsimulator ${FLAGS} ${ACTIONS} >> ${LOG_FILE} 2>&1 \
&& echo "done." \

echo -n "Combining the frameworks into an XCFramework..." \
  && xcodebuild -create-xcframework \
    -framework ${OUTPUT_DIR}/${PRODUCT_NAME}-iphoneos.xcarchive/${OUTPUT_FRAMEWORK_PATH} \
    -framework ${OUTPUT_DIR}/${PRODUCT_NAME}-iphonesimulator.xcarchive/${OUTPUT_FRAMEWORK_PATH} \
    -framework ${OUTPUT_DIR}/${PRODUCT_NAME}-appletvos.xcarchive/${OUTPUT_FRAMEWORK_PATH} \
    -framework ${OUTPUT_DIR}/${PRODUCT_NAME}-appletvsimulator.xcarchive/${OUTPUT_FRAMEWORK_PATH} \
    -output ${DEPLOY_DIR}/${PRODUCT_NAME}.xcframework \
    >> ${LOG_FILE} \
&& echo "done." \
&& echo "Successfully built $DEPLOY_DIR/${PRODUCT_NAME}.xcframework" \
    
