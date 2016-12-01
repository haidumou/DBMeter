//
//  UIImage+Color.h
//  letv
//
//  Created by xjshi on 1/25/16.
//  Copyright © 2016 jzkj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Color)

/**
 *  用一个颜色绘制一张图片
 */
+ (UIImage *)imageFromColor:(UIColor *)color;

/**
 *  返回一张纯色图片
 *
 *  @param color 颜色
 *  @param size  尺寸
 *
 *  @return 图片
 */
+ (UIImage *)imageFromColor:(UIColor *)color withSize:(CGSize)size;

@end
