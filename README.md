# OnionKit for iOS

This fork of the OnionKit is going to be used in a Relay Application, which may later turn into more. It will implement things like a TOR controller for acute and intimate control over TOR. It will be more expansive, and TOR will likely be badly hacked in the process. To be forthcoming, I have little programming experience, and this should not be taken as a secure implementation of TOR. It is not. If that changes, I will change this. Also, I assume all of the following still applies: Below is the previous read me.


Objective-C Tor Wrapper Framework for iOS. **Don't actually use this yet.** This project is based on [iOS-OnionBrowser](https://github.com/mtigas/iOS-OnionBrowser) and [Tor.framework](https://github.com/hivewallet/Tor.framework).

To clone:

    $ git clone git://github.com/ChatSecure/OnionKit.git
    $ cd OnionKit        
    $ git submodule update --init --recursive
   
This will clone all of the required dependencies into the Submodules directory.

## Build

Build OpenSSL, libevent and libtor static libaries for iOS.

    $ bash build-libssl.sh
    $ bash build-libevent.sh
    $ bash build-tor.sh

## Usage

To include in a standard project:

1. Drag the `./dependencies/lib` folder into your project and make sure the static libs are added to your target.
2. In "Search Headers" for your target make to to include `$(SRCROOT)/Submodules/OnionKit/dependencies/include` or something similar.