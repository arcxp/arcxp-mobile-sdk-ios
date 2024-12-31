# Release Document: Arc XP SDK

## Building and Distributing the Arc XP SDK

The Arc XP SDK is distributed as a **precompiled binary framework**, deviating from the conventional open-source frameworks. It requires building for both the device and simulator on iOS.

### Deliverables:

1. **XCFramework Distribution**:
   - The XCFramework is compressed into a single zipfile.
   - Uploaded to an Amazon S3 bucket.

2. **CocoaPods Integration**:
   - Updated CocoaPods spec published to [internal GitHub spec repository](https://github.com/arcxp/arc-mobile-podspecs).
   - The CocoaPods spec references the zipfile in the S3 bucket.

3. **Swift Package Manager Integration**:
   - Updated package file published to [iOS internal SwiftPackage repository](https://github.com/arcxp/arcxpSDK-iOS-package) and [tvOS internal SwiftPackage repository](https://github.com/arcxp/arcxpSDK-tvOS-package).
   - The package file dependencies point to the zipfile in the S3 bucket.

4. **Public API Documentation**:
   - Xcode documentation catalog.

## Release Builds to CocoaPods

### Steps:

1. **Create Release Branch**:
   - Branch off `develop` and checkout.

2. **Update Version**:
   - Search the project for the previous version, and update all version references.
   - Open and update the version in the `Releases/ArcXPSDK.podspec` file.
   - Push changes to the branch.

3. **Pull Request**:
   - Create a PR against the `develop` branch.
   - Merge release branch into `develop`.

4. **Merge to Main**:
   - Create a PR against the `main` branch from the `develop` branch.
   - Merge the PR into `main`.

5. **Tag Release**:
   - Tag the release with the same version as in podspec using semantic versioning.
   - Provide release notes in GitHub release notes field.
   - Push tags to trigger Bitrise workflow `Build_And_Generate_SDK`.

### Bitrise Workflow:

1. **Generate XCFramework**:
   - Create binaries for iOS device and simulator.
   - Zip up the XCFramework.

2. **Upload to S3**:
   - Upload zipfile to AWS S3 bucket under `release_${version}` folder.
   - Upload checksum to the S3 bucket.

3. **Update CocoaPods Spec**:
   - Publish updated CocoaPods spec to `https://github.com/arcxp/arc-mobile-podspecs`.

## Release Builds to SwiftPackageManager

### Steps:

1. **Update Environment Variables**:
   - Navigate to Bitrise page for [arcxpSDK-iOS-package](https://app.bitrise.io/app/33596714-76da-405a-9f19-ed99ab905647) and [arcxpSDK-tvOS-package](https://app.bitrise.io/app/f51f0c47-cf07-4754-91be-b68d6502fcee).
   - Update `RELEASE_VERSION` param to the release number.

2. **Run Workflow**:
   - Run the `primary` workflow on the main branch with a release message.

#### Bitrise Workflow:

1. **Clone Repository**:
   - Clone [Arc XP SDK iOS SwiftPackage](https://github.com/arcxp/arcxpSDK-iOS-package) and [Arc XP SDK tvOS SwiftPackage](https://github.com/arcxp/arcxpSDK-tvOS-package).

2. **Update Checksum**:
   - Read updated checksum from S3 bucket under `release_${version}` folder.
   - Replace checksum and dependencies version in the Package file.
   - Push changes to the main branch.

3. **Tag Release**:
   - Tag the main branch with the `RELEASE_VERSION` and push tags.
   - Swift Package dependencies are ready to download from the release_version.