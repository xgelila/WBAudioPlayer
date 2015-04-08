//
//  ViewController.m
//  WBAudioPlayer
//
//  Created by Bing on 15/3/31.
//  Copyright (c) 2015年 Bing. All rights reserved.
//
#import "WBAudioPlayer.h"
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISlider * volume;
@property (weak, nonatomic) IBOutlet UISlider * rate;
@property (weak, nonatomic) IBOutlet UILabel  * time;
@property (weak, nonatomic) IBOutlet UISlider * progress;

@end



@implementation ViewController
{
    WBAudioPlayer * _player;
    NSString      * _duration;
    NSTimer       * _timer;
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString * audioFile = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"];
    _player = [WBAudioPlayer instance];
    BOOL rt =  [_player createAudioTrack:audioFile];
    if (rt)
    {
        [_player play];
        _duration = [self _timeFormatted:_player.duration];
        [self _configCallback];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_player.playing)
    {
        [self _initionalTimer];
    }
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self _destroyTimer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_configCallback
{
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
            //响应远程播放事件
            NSLog(@"响应远程播放事件");
            [weakSelf _initionalTimer];
            
        }else if(type == WBAudioPlayerRemoteEventTypePause){
            //响应远程暂停事件
            NSLog(@"响应远程暂停事件");
            [weakSelf _destroyTimer];
        }
    };
    _player.headPhonePlugBlock = ^(WBAudioPlayerHeadPhonePlugType type){
        if (type == WBAudioPlayerHeadPhonePlugTypePlugin)
        {
            //响应耳机插入事件
            NSLog(@"响应耳机插入事件");
        }else{
            //响应耳机拔出事件
            NSLog(@"响应耳机拔出事件");
            [weakSelf _destroyTimer];
        }

    };
    _player.playFinishBlock = ^(){
        [weakSelf _destroyTimer];
        NSLog(@"播放结束");
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundCallback:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActiveCallback:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)_updateUI
{
    _time.text = [NSString stringWithFormat:@"%@/%@",[self _timeFormatted:_player.currentTime],_duration];
    _progress.value = _player.currentTime/_player.duration;

}

- (NSString *)_timeFormatted:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

#pragma mark -- NSTimer
- (void)_initionalTimer
{
    [self _destroyTimer];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_updateUI) userInfo:nil repeats:YES];
    [_timer fire];
}

- (void)_destroyTimer
{
    if (_timer != nil)
    {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark -- UI controller
- (IBAction)volumeChange:(UISlider *)sender
{
   [_player setVolume:sender.value];
}

- (IBAction)rateChage:(UISlider *)sender
{
    [_player setRate:sender.value*2.0];
}

- (IBAction)finishSeek:(UISlider *)sender
{
    [_player setCurrentTime:sender.value*_player.duration];
    [self _initionalTimer];
}

- (IBAction)beginSeek:(UISlider *)sender
{
    [self _destroyTimer];
}

#pragma mark -- UIApplicationDidEnterBackgroundNotification UIApplicationDidBecomeActiveNotification

- (void)enterBackgroundCallback:(NSNotification *)notification
{
    [self _destroyTimer];
}

- (void)becomeActiveCallback:(NSNotification *)notification
{
    [self _initionalTimer];
}
@end
