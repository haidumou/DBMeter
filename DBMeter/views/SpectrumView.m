//
//  SpectrumView.m
//  DBMeter
//
//  Created by bfme on 2016/12/1.
//  Copyright © 2016年 BFMe. All rights reserved.
//

#import "SpectrumView.h"
#import "UIImage+Color.h"

@implementation SpectrumView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [self setupSubviews];
    }
    
    return self;
}

- (void)reloadSpectrumWithArray:(NSArray *)array {
    CGFloat width = self.frame.size.width/40.0;
    CGFloat height = self.frame.size.height/18.0;
    [UIView animateWithDuration:.1 animations:^{
        for (int i = 0; i < array.count; i++) {
            UIView *view = [self viewWithTag:100 + i];
            view.frame = CGRectMake(width*i, self.frame.size.height - (height*([array[i] intValue])), width - 1, self.frame.size.height);
        }
    }];
}

- (void)setupSubviews {
    CGFloat width = self.frame.size.width/40.0;
    CGFloat height = self.frame.size.height/18.0;
    for (int i = 0; i < 40; i++) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(width*i, self.frame.size.height, width - 1, self.frame.size.height)];
        view.tag = 100 + i;
        [self addSubview:view];
        for (int j = 0; j < 18; j++) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - (height*(j+1)), width - 1, height - 1)];
            if (j > 14) {
                imageView.image = [UIImage imageFromColor:RGBCOLOR(20, 192, 239)];
            }else {
                imageView.image = [UIImage imageFromColor:RGBCOLOR(0, 64, 86)];
            }
            [view addSubview:imageView];
        }
    }
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
