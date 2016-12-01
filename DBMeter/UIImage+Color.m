//
//  UIImage+Color.m
//  letv
//
//  Created by xjshi on 1/25/16.
//  Copyright © 2016 jzkj. All rights reserved.
//

#import "UIImage+Color.h"

@implementation UIImage (Color)

+ (UIImage *)imageFromColor:(UIColor *)color
{

    UIImage *resultImage = [UIImage imageFromColor:color withSize:CGSizeMake(1.0f, 1.0f)];
    return resultImage;
}

+ (UIImage *)imageFromColor:(UIColor *)color withSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}




@end
