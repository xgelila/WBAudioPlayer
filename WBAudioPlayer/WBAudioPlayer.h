//
//  WBAudioPlayer.h
//  WBAudioPlayer
//
//  Created by Bing on 15/4/2.
//  Copyright (c) 2015年 Bing. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#pragma mark -- enumerations --
//音频中断通知类型
typedef NS_ENUM(NSInteger, WBAudioPlayerinterruptionType)
{
    WBAudioPlayerinterruptionTypeBegin = 0, //中断开始
    WBAudioPlayerinterruptionTypeEnd        //中断结束
};

//远程事件通知类型
typedef NS_ENUM(NSInteger, WBAudioPlayerRemoteEventType)
{
    WBAudioPlayerRemoteEventTypePlay = 0, //播放
    WBAudioPlayerRemoteEventTypePause     //暂停
};

//耳机插拔事件通知类型
typedef NS_ENUM(NSInteger, WBAudioPlayerHeadPhonePlugType)
{
    WBAudioPlayerHeadPhonePlugTypePlugin = 0, //插入耳机
    WBAudioPlayerHeadPhonePlugTypePlugout     //拔出耳机
};

#pragma mark -- block
typedef void (^InterruptionBlock)(WBAudioPlayerinterruptionType type);
typedef void (^RemoteEventBlock)(WBAudioPlayerRemoteEventType type);
typedef void (^HeadPhonePlugBlock)(WBAudioPlayerHeadPhonePlugType type);
typedef void (^PlayFinishBlock)();

@interface WBAudioPlayer : NSObject<AVAudioPlayerDelegate>
@property (nonatomic ,readonly)  NSTimeInterval  duration;

@property (nonatomic ,copy)      InterruptionBlock  interrutionBlock;
@property (nonatomic ,copy)      RemoteEventBlock   remoteEventBlock;
@property (nonatomic ,copy)      HeadPhonePlugBlock headPhonePlugBlock;
@property (nonatomic ,copy)      PlayFinishBlock    playFinishBlock;

+ (WBAudioPlayer *)instance;

- (void)initAudioSession;

- (BOOL)createAudioTrack:(NSString *)audio;

- (void)play;

- (void)pause;

- (void)stop;

- (NSTimeInterval)currentTime;

- (void)setCurrentTime:(NSTimeInterval)time;

- (float)rate;

- (void)setRate:(float)rate;

- (float)volume;

- (void)setVolume:(float)volume;

- (BOOL)playing;

- (float)deviceCurrentTime;

- (void)updateNowPlayingInfoWithRate:(CGFloat)rate;
@end