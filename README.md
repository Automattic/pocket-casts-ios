# Pocket Casts iOS

## Setup

If you don't already have it, you need to install Bundler:

`gem install bundler`

Next you'll need to install all the dependencies needed for CocoaPods and FastLane using this script:

`make install_dependencies`

Then you'll need to install secret config values. [Follow this guide to get access to the shared Mobile Secrets](https://fieldguide.automattic.com/mobile-native-development/updating-mobile-secrets/) and then:

## External contributors

If you're an external contributor run `make external_contributor`. After that you should be able to build and run the project.

## Swift Formatting

We use a tool called Swift Format to ensure our code is spaced and formatted the same way and follows the same general conventions. We have a script that will run it over the whole project. The necessary depedencies will be installed with CocoaPods but you can also install it globally using:

```
brew update
brew install swiftformat
```
***Note:*** Homebrew doesn't enforce versioning so if you use the brew version it _may_ get out of sync with the CocoaPods install.

Once the required dependencies are installed, you can run:

`make swiftformat`

You should do this before making a pull request.

## Running

Open the .xcworkspace file, select the Pocket Casts project and the Simulator Device you want to run on, and hit the play button.

## Localization

You can learn more about localization at [docs/Localization.md](./documentation/localization.md)

## Protocol Buffers

The app uses [Google Protocol Buffers](https://developers.google.com/protocol-buffers) to define our server objects.

To update server objects you'll need to install the protobuf command line tool as well as the [Swift Protobuf](https://github.com/apple/swift-protobuf) translators. This can be done via Homebrew with:

```
brew install protobuf
brew install swift-protobuf
```

To update the protobuf files you can then run:

Replace the `{API_PATH}` with the full path to the `pocketcasts-api/api/modules/protobuf/src/main/proto` folder

```
make update_proto API_PATH={API_PATH}
```
