<div align="center">
   <h1> Serotonin 
      <br/> not/semi-jailbreak
   </h1>
</div>

<h6 align="center"> Supports iOS/iPadOS 16.2 - 16.6.1  </h6>


## How do I use this?
To use this app, you need to be on a supported version (mentioned above), and have [TrollStore](https://github.com/opa334/TrollStore/) installed. You can follow [this guide](https://ios.cfw.guide/installing-trollstore/) to install it on your device. Please note that this tool doesn't support iOS 17.0 despite of it having TrollStore.

1. Download and install [Bootstrap from RootHide](https://github.com/RootHide/Bootstrap)
2. Install Ellekit in Sileo
3. Download the `.tipa` file from the [latest release](https://github.com/hrtowii/Serotonin/releases/latest)
4. Install the downloaded file in TrollStore
5. Open the app and press the Jelbrek button. Your device should userspace reboot, and you should be (not/semi) jailbroken!

   
## How was this done? 
 - It replaces launchd by searching through /sbin's vp_namecache, finds launchd's name cache and kwrites it with a patch to `lunchd`, our patched `launchd` (*you can have a look at a better explanation from AlfieCG [here](https://www.reddit.com/r/jailbreak/comments/18zehl2/comment/kgi5ya3/)*)
 - Patched launchd hooks posix_spawnp of SpringBoard and execs our own SpringBoard with springboardhook.dylib
 - Springboardhook loads in tweaks, ellekit, etc.
 - CoreTrust Bug found by [AlfieCG](https://github.com/alfiecg24)
 - [KFD Exploit](https://github.com/felix-pb/kfd)

## TODO
 - Try adding support for lower iOS versions by overwriting NSGetExecutablePath
 - Add support for arm64
 - Add a boot splash screen
 - Fix `puaf_pages` picker crash in new UI

## Credits
- [DuyKhanhTran](https://github.com/khanhduytran0) - launchd and SpringBoard hooks
- [NSBedtime](https://twitter.com/NSBedtime) - initial launchdhax, helped out a ton!
- [AlfieCG](https://github.com/alfiecg24) - helped out a ton!
- [Nick Chan](https://github.com/asdfugil) - helped out a ton!
- [BomberFish](https://github.com/BomberFish) - new UI, `lunchd` name idea :trollface:
- [haxi0](https://github.com/haxi0) - old UI
- [Evelyne](https://github.com/evelyneee) for showing it was possible. 
