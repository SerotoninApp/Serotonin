<div align="center">
   <h1> Serotonin 
      <br/> not/semi-jailbreak
   </h1>
</div>

<h6 align="center"> Supports iOS/iPadOS 16.2 - 16.6.1  </h6>


## How to use?
To use this app, you need to be on a supported version (mentionned above), and have [TrollStore](https://github.com/opa334/TrollStore/) installed. You can follow [this guide](https://ios.cfw.guide/installing-trollstore/) to install it on your device. Please note that this tool doesn't support iOS 17.0 despite of it having TrollStore.

1. Download and install [Bootstrap from RootHide](https://github.com/RootHide/Bootstrap)
2. Download the `.tipa` file from latest release of this repository
3. Open the downloaded file in TrollStore
4. Open the app and press Jailbreak button. Your device should (UserSpace) Reboot.

   
## How was this done? 
This tool uses a mix of different techniques and exploits available for most TrollStore users :
 - It replaces launchd by searching through /sbin's vp_namecache, then find launchd's name cache and kwrite it with a patch to our patched launchd (*you can have a look at a better explanation from AlfieCG [here](https://www.reddit.com/r/jailbreak/comments/18zehl2/comment/kgi5ya3/)*)
 - Patched launchd hooks posix_spawnp of SpringBoard and execs our own SpringBoard with springboardhook.dylib
 - Springboardhook loads in tweaks, ellekit, etc.
 - CoreTrust Bug found by [Alfie](https://github.com/alfiecg24)
 - [KFD Exploit](https://github.com/felix-pb/kfd)

## Todo in the future
 - Try adding support for lower iOS versions by overwriting NSGetExecutablePath
 - Add support for arm64
 - Add a boot splash screen
 - Fix `puaf_pages` picker crash in new UI

## Credits
- [DuyKhanhTran](https://github.com/khanhduytran0) - launchd and SpringBoard hooks
- [NSBedtime](https://twitter.com/NSBedtime) - initial launchdhax, helped out a ton!
- [AlfieCG](https://github.com/alfiecg24) - helped out a ton!
- [Nick Chan](https://github.com/asdfugil) - helped out a ton!
- [BomberFish](https://github.com/BomberFish) - main UI
- [haxi0](https://github.com/haxi0) - initial logger
- [Evelyne](https://github.com/evelyneee) for showing it was possible. 
