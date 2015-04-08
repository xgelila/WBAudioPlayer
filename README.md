## WBAudioPlayer
---
WBAudioPlayer is a audio player which can play local audio file.

Handle interruptions such as a phone call,a alarm of Clock or Calendar,or another app activating its audio session.

Handle Headphone plugin or plugout.

Handle Remote Control Events.

Display song's info and the status of playback on the locked screen.

##Require
---
MediaPlayer.framework

AVFoundation.framework

##Usage
Import the header.

```
#import "WBAudioPlayer.h"
```

start audiosession when your app launch.

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[WBAudioPlayer instance] initAudioSession];
    return YES;
}

```

Setup the player in your ViewController

```    
NSString * audioFile = [[NSBundle mainBundle] pathForResource:@"test"   ofType:@"mp3"];
WBAudioPlayer *player = [WBAudioPlayer instance];
[player createAudioTrack:audioFile];
[player play];
```

Hanlde interruptions,Headphone and Remote Control Events.

```
__weak typeof(self) weakSelf = self;
_player.interrutionBlock = ^(WBAudioPlayerinterruptionType type){
        if (type == WBAudioPlayerinterruptionTypeBegin)
        {
            [weakSelf _destroyTimer];
        }else if (type == WBAudioPlayerinterruptionTypeEnd)
        {
            [weakSelf _initionalTimer];
        }
    };
    _player.remoteEventBlock = ^(WBAudioPlayerRemoteEventType type){
        if (type == WBAudioPlayerRemoteEventTypePlay)
        {
            
            [weakSelf _initionalTimer];
            
        }else if(type == WBAudioPlayerRemoteEventTypePause){
            [weakSelf _destroyTimer];
        }
    };
    _player.headPhonePlugBlock = ^(WBAudioPlayerHeadPhonePlugType type){
        if (type == WBAudioPlayerHeadPhonePlugTypePlugin)
        {
            
        }else{
            
           [weakSelf _destroyTimer];
        }

    };
```
