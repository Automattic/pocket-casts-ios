<p align="center">
    <img src="https://user-images.githubusercontent.com/7040243/190481901-1b47101c-da98-400f-b92b-bca9e66f4c8c.svg" />
</p>

<p align="center">
    <a href="https://buildkite.com/automattic/pocket-casts-ios"><img src="https://badge.buildkite.com/6c995de3d1584006341cc4dfda1312619f375385f5c0319dfe.svg?branch=trunk" /></a>
    <a href="https://github.com/Automattic/pocket-casts-ios/blob/trunk/LICENSE.md"><img src="https://img.shields.io/badge/license-MPL-black" /></a>
    <img src="https://img.shields.io/badge/platform-ios%20%7C%20watchos-lightgrey" />
</p>

<p align="center">
    Pocket Casts is the world's most powerful podcast platform, an app by listeners, for listeners.
</p>

## Setup

If you don't already have it, you need to install Bundler:

`gem install bundler`

Next you'll need to install all the dependencies needed for CocoaPods and FastLane using this script:

`make install_dependencies`

Then you'll need to install secret config values. [Follow this guide to get access to the shared Mobile Secrets](https://fieldguide.automattic.com/mobile-native-development/updating-mobile-secrets/) and then:

## External contributors

If you're an external contributor run `make external_contributor`. After that you should be able to build and run the project.

## Swift Formatting

We use [SwiftLint](https://github.com/realm/SwiftLint) to is spaced and formatted the same way and follows the same [general conventions](https://github.com/Automattic/swiftlint-config). We have a script that will run it over the whole project.

Once the required dependencies are installed via `bundle exec pod install`, you can run:

`make format`

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
