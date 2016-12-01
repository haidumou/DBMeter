//
//  SpectrumView.h
//  DBMeter
//
//  Created by bfme on 2016/12/1.
//  Copyright © 2016年 BFMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpectrumView : UIView

// 更新音频图
- (void)reloadSpectrumWithArray:(NSArray *)array;

@end
