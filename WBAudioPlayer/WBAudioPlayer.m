//
//  WBAudioPlayer.m
//  WBAudioPlayer
//
//  Created by Bing on 15/4/2.
//  Copyright (c) 2015年 Bing. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

#import "WBAudioPlayer.h"


@implementation WBAudioPlayer
{
    AVAudioPlayer * _player;
}

- (void)dealloc
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.playCommand removeTarget:self];
    [commandCenter.pauseCommand removeTarget:self];
}


+ (WBAudioPlayer *)instance
{
    static WBAudioPlayer * audioPlayer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioPlayer = [[WBAudioPlayer alloc] init];
    });
    return audioPlayer;
}

- (void)initAudioSession
{
    AVAudioSession * avSession = [AVAudioSession sharedInstance];
    [avSession  setCategory:AVAudioSessionCategoryPlayback error:nil];
    [avSession setActive:YES error:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChangeNotificationCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionNotificationCallback:) name:AVAudioSessionInterruptionNotification object:nil];
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.playCommand addTarget:self action:@selector(didReceivePlayCommand:)];
    [commandCenter.pauseCommand addTarget:self action:@selector(didReceivePauseCommand:)];
    
}
#pragma mark- interface
- (BOOL)createAudioTrack:(NSString *)audio
{
    if (_player != nil)
    {
        [_player stop];
        _player = nil;
    }
    _duration = 0;
    if (audio != nil)
    {
        NSURL * url = [NSURL fileURLWithPath:audio];
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        if (_player != nil)
        {
            _player.enableRate = YES;
            _player.numberOfLoops = 0;
            _duration = _player.duration;
            _player.delegate = self;
            [self showSongInfoWithAudio:audio];
            return YES;
        }
 
    }
    return NO;
}

- (void)destroyAudioTrack
{
    if (_player != nil)
    {
        [_player stop];
        _player = nil;
        _duration = 0;
    }
}


#pragma mark- receiveRemoteCommand
- (void)didReceivePlayCommand:(MPRemoteCommandEvent *)event
{
    [_player play];
    if (_remoteEventBlock != nil)
    {
        _remoteEventBlock(WBAudioPlayerRemoteEventTypePlay);
    }
}

- (void)didReceivePauseCommand:(MPRemoteCommandEvent *)event
{
    [_player pause];
    if (_remoteEventBlock != nil)
    {
       _remoteEventBlock(WBAudioPlayerRemoteEventTypePause);
    }
}


#pragma mark- AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    _playFinishBlock();
}

#pragma mark - routeChangeNotificationCallback
- (void)routeChangeNotificationCallback:(NSNotification*)notification
{
    NSDictionary * userInfo = notification.userInfo;
    AVAudioSessionRouteChangeReason reason = (AVAudioSessionRouteChangeReason)[[userInfo objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    if (reason == AVAudioSessionRouteChangeReasonNewDeviceAvailable)
    {
       AVAudioSessionRouteDescription * ds = [AVAudioSession sharedInstance].currentRoute;
        for (AVAudioSessionPortDescription *pd in ds.outputs)
        {
            if ([pd.portType isEqualToString:@"Headphones"]) //耳机插入
            {
                //post耳机插入的通知
                if (_headPhonePlugBlock != nil)
                {
                    _headPhonePlugBlock(WBAudioPlayerHeadPhonePlugTypePlugin);
                }
            }
        }
    }else if (reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable)
    {
        AVAudioSessionRouteDescription *previousRoute = (AVAudioSessionRouteDescription*)[userInfo objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
        for (AVAudioSessionPortDescription *pd in previousRoute.outputs)
        {
            if ([pd.portType isEqualToString:@"Headphones"]) //耳机拔出
            {
                [self pause];
                //post耳机拔出的通知
                if (_headPhonePlugBlock != nil)
                {
                    _headPhonePlugBlock(WBAudioPlayerHeadPhonePlugTypePlugout);
                }
            }
        }
    }
}

#pragma mark - interruptionNotificationCallback
- (void)interruptionNotificationCallback:(NSNotification*)notification
{
    NSDictionary * userInfo = notification.userInfo;
    AudioSessionInterruptionType type = (AudioSessionInterruptionType)[[userInfo objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    if (type == AVAudioSessionInterruptionTypeBegan)
    {
        if (_interrutionBlock != nil)
        {
            _interrutionBlock(WBAudioPlayerinterruptionTypeBegin);
        }
        
    }else if (type == AVAudioSessionInterruptionTypeEnded)
    {
        AVAudioSessionInterruptionOptions optionType = [[userInfo objectForKey:AVAudioSessionInterruptionOptionKey] integerValue];

        if (optionType == AVAudioSessionInterruptionOptionShouldResume)
        {
            [self play];
            if (_interrutionBlock != nil)
            {
                _interrutionBlock(WBAudioPlayerinterruptionTypeEnd);
            }
        }
    }
}

#pragma mark- lock screen show song information
- (void)showSongInfoWithAudio:(NSString *)audio
{
    NSURL * url = [NSURL fileURLWithPath:audio];
    AVURLAsset * asset = [AVURLAsset assetWithURL:url];
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    NSArray * formats = [asset availableMetadataFormats];
    for(NSString * format in formats)
    {
        NSLog(@"%@",format);
        NSArray * items = [asset metadataForFormat:format];
        for (AVMetadataItem* item in items)
        {
            NSLog(@"%@\n",item.commonKey);
            
            if ([item.commonKey isEqualToString:@"artwork"])
            {
                NSLog(@"%@",item.dataType);
                UIImage* image = [UIImage imageWithData:(NSData*)item.value];
                MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:image];
                [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
            }else if ([item.commonKey isEqualToString:@"title"])
            {
                [songInfo setObject:item.value forKey:MPMediaItemPropertyTitle];
            }
            else if ([item.commonKey isEqualToString:@"albumName"])
            {
                [songInfo setObject:item.value forKey:MPMediaItemPropertyAlbumTitle];
            }
            else if ([item.commonKey isEqualToString:@"artist"])
            {
                [songInfo setObject:item.value forKey:MPMediaItemPropertyArtist];
            }
        }
    }
    [songInfo setObject:@(_player.duration) forKey:MPMediaItemPropertyPlaybackDuration];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}
#pragma mark- playback interface
- (void)play
{
    [_player prepareToPlay];
    [_player play];
}

- (void)pause
{
    [_player pause];
}

- (void)stop
{
    [_player stop];
}


- (NSTimeInterval)currentTime
{
    return _player.currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)time
{
    _player.currentTime = time;
}

- (float)rate
{
    return _player.rate;
}
- (void)setRate:(float)rate
{
    _player.rate = rate;
}
- (float)volume
{
    return _player.volume;
}
- (void)setVolume:(float)volume
{
    _player.volume = volume;
}

- (BOOL)playing
{
    return _player.playing;
}

- (float)deviceCurrentTime
{
    return _player.deviceCurrentTime;
};
@end