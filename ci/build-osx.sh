set -e
mkdir build
cd build

if [ -n "${ELECTRON_VERSION}" ]
then
    NODEJS_VERSION_PARAM="-DNODEJS_VERSION=${ELECTRON_VERSION}"
else
    NODEJS_VERSION_PARAM=""
fi

if [ -n "${ARCHITECTURE}" ]
then
    CMAKE_OSX_ARCHITECTURES_PARAM="-DCMAKE_OSX_ARCHITECTURES=${ARCHITECTURE}"
else
    CMAKE_OSX_ARCHITECTURES_PARAM=""
fi

# Configure
cmake .. \
-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
-DCMAKE_BUILD_TYPE=RelWithDebInfo \
${NODEJS_VERSION_PARAM} \
${CMAKE_OSX_ARCHITECTURES_PARAM} \
-DCMAKE_INSTALL_PREFIX=${DISTRIBUTE_DIRECTORY}/font-manager

cd ..

# Build
cmake --build build --target install --config RelWithDebInfo

#Upload debug files
curl -sL https://sentry.io/get-cli/ | bash
dsymutil $PWD/${BUILD_DIRECTORY}/RelWithDebInfo/node_fontmanager.node
sentry-cli --auth-token ${SENTRY_AUTH_TOKEN} upload-dif --org streamlabs-desktop --project obs-client $PWD/${BUILD_DIRECTORY}/RelWithDebInfo/node_fontmanager.node.dSYM/Contents/Resources/DWARF/node_fontmanager.node 
