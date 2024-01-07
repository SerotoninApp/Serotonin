# Serotonin - not/semi-jailbreak for iOS 16.2 - 16.6.1

## How do I use it?
* Download tipa, install via TrollStore
* Press jailbreak
* Be happy

## How is this done?
* Replace launchd by searching through /sbin's vp_namecache, then find launchd's name cache and kwrite it with a patch to our patched launchd.
* Better explanation from AlfieCG [here](https://www.reddit.com/r/jailbreak/comments/18zehl2/comment/kgi5ya3/)
* patched launchd hooks posix_spawnp of SpringBoard and execs our own SpringBoard with springboardhook.dylib
* springboardhook loads in tweaks, ellekit, etc.
* CoreTrust bug used to bypass codesigning and allow any binary to run with arbitrary entitlements
* KFD / Any other kernel read/write bug to write to the name cache in the first place

## Todo in the future
* Try adding support for lower iOS versions by overwriting NSGetExecutablePath
* Add support for arm64
* Add a boot splash screen
* Fix `puaf_pages` picker crash in new UI

## Credits
* hrtowii / sacrosanctuary - main dev
* DuyKhanhTran - launchd and SpringBoard hooks
* NSBedtime - initial launchdhax, helped out a ton!
* AlfieCG - helped out a ton!
* Nick Chan - helped out a ton!
* BomberFish - main UI
* haxi0 - initial logger
* Evelyne for showing it was possible. I wouldn't have gotten motivated without that initial tweet lol

