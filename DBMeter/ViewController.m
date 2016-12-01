//
//  ViewController.m
//  DBMeter
//
//  Created by 崔忠海 on 2016/12/1.
//  Copyright © 2016年 BFMe. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "ZLHistogramAudioPlot.h"
#import "EZAudio.h"

#import "GraphView.h"
#import "SpectrumView.h"

#define DinCondMedium(FONTSIZE)    [UIFont fontWithName:@"DINCond-Medium" size:(FONTSIZE)]

@interface ViewController () <EZMicrophoneDelegate, ZLHistogramAudioPlotDelegate>
{
    UILabel *dbDescLabel;
    NSInteger _timeCount;
    
    UIView *backImageView;
}
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *levelTimer;
@property (nonatomic, strong) GraphView *graphView;
@property (nonatomic, strong) NSMutableArray *decibeLineArray;// 分贝曲线数组
@property (nonatomic, strong) SpectrumView *spectrumView;     // 音频图

@property (nonatomic, strong) ZLHistogramAudioPlot *audioPlot;
@property (nonatomic, strong) EZMicrophone *microphone;
@end

@implementation ViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.microphone = [EZMicrophone microphoneWithDelegate:self];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor colorWithRed:0.06 green:0.11 blue:0.2 alpha:1]];
    self.decibeLineArray = [NSMutableArray array];
    
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    
    self.spectrumView = [[SpectrumView alloc] initWithFrame:CGRectMake(10, 84, kScreenWidth - 20, 100)];
    [self.view addSubview:self.spectrumView];
    self.audioPlot = [[ZLHistogramAudioPlot alloc] initWithFrame:CGRectMake(1000, 216, 355, 90)];
    self.audioPlot.plotType = EZPlotTypeBuffer;
    // Fill
    self.audioPlot.shouldFill = YES;
    // Mirror
    self.audioPlot.shouldMirror = YES;
    self.audioPlot.delegate = self;
    [self.view addSubview:self.audioPlot];
    
    
    dbDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 200, 200, 100)];
    dbDescLabel.backgroundColor = [UIColor lightGrayColor];
    dbDescLabel.textColor = [UIColor whiteColor];
    dbDescLabel.font = [UIFont systemFontOfSize:20];
    [self.view addSubview:dbDescLabel];
    
    backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"activity_concert_decibe"]];
    backImageView.frame  =CGRectMake(0, kScreenHeight - 200, kScreenWidth, 180);
    [self.view addSubview:backImageView];
    
    self.graphView = [[GraphView alloc] initWithFrame:CGRectMake(10, kScreenHeight-200, kScreenWidth-20, 180)];
    [self.graphView setStrokeColor:RGBCOLOR(20, 198, 232)];
    [self.graphView setFill:NO];
    [self.view addSubview:self.graphView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupDB];
    [self.microphone startFetchingAudio];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.microphone stopFetchingAudio];
    [self.levelTimer invalidate];
    self.levelTimer = nil;
}

#pragma mark - ZLHistogramAudioPlotDelegate
- (void)reloadDataArray:(NSArray *)array {
    [self.spectrumView reloadSpectrumWithArray:array];
}

#pragma mark - EZMicrophoneDelegate
// Note that any callback that provides streamed audio data (like streaming
// microphone input) happens on a separate audio thread that should not be
// blocked. When we feed audio data into any of the UI components we need to
// explicity create a GCD block on the main thread to properly get the UI to
// work.
- (void)microphone:(EZMicrophone *)microphone
  hasAudioReceived:(float **)buffer
    withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as an array of float buffer arrays. What does that
    // mean? Because the audio is coming in as a stereo signal the data is split
    // into a left and right channel. So buffer[0] corresponds to the float*
    // data for the left channel while buffer[1] corresponds to the float* data
    // for the right channel.
    
    // See the Thread Safety warning above, but in a nutshell these callbacks
    // happen on a separate audio thread. We wrap any UI updating in a GCD block
    // on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(), ^{
        // All the audio plot needs is the buffer data (float*) and the size.
        // Internally the audio plot will handle all the drawing related code,
        // history management, and freeing its own resources. Hence, one badass
        // line of code gets you a pretty plot :)
        [self.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}

- (void)setupDB {
    /* 必须添加这句话，否则在模拟器可以，在真机上获取始终是0  */
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
    /* 不需要保存录音文件 */
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                              nil];
    
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (self.recorder) {
        [self.recorder prepareToRecord];
        self.recorder.meteringEnabled = YES;
        [self.recorder record];
        
        if (!self.levelTimer) {
            self.levelTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(levelTimerCallback:) userInfo:nil repeats:YES];
            [self.levelTimer fire];
        }
    }else {
        
    }
}

/* 该方法确实会随环境音量变化而变化，但具体分贝值是否准确暂时没有研究 */
- (void)levelTimerCallback:(NSTimer *)timer {
    [self.recorder updateMeters];
    
    float   level;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = - 80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels    = [self.recorder averagePowerForChannel:0];
    
    if (decibels < minDecibels) {
        level = 0.0f;
    } else if (decibels >= 0.0f) {
        level = 1.0f;
    } else {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    /* level 范围[0 ~ 1], 转为[0 ~120] 之间 */
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *valueString = [NSString stringWithFormat:@"%.0f", level*120];
        NSString *string = [NSString stringWithFormat:@"%@ dB",valueString];
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:string];
        NSRange range2 = [string rangeOfString:valueString];
        [str addAttribute:NSFontAttributeName value:DinCondMedium(72) range:range2];
        
        if (_timeCount%10 == 0) {
            dbDescLabel.attributedText = str;
        }
        _timeCount++;
        
        if (self.decibeLineArray.count > kScreenWidth) {
            [self.decibeLineArray removeObjectAtIndex:0];
        }
        [self.decibeLineArray addObject:[NSString stringWithFormat:@"%.0f",level*120/167*18*5]];
        self.graphView.frame = CGRectMake(10, kScreenHeight-200, self.decibeLineArray.count, 180);
        [self.graphView setArray:self.decibeLineArray];
    });
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
