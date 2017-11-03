//
//  do_Canvas_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_Canvas_IView <NSObject>

@required
//属性方法
- (void)change_isFull:(NSString *)newValue;
- (void)change_strokeCap:(NSString *)newValue;
- (void)change_strokeColor:(NSString *)newValue;
- (void)change_strokeWidth:(NSString *)newValue;

//同步或异步方法
- (void)defineArc:(NSArray *)parms;
- (void)defineImage:(NSArray *)parms;
- (void)defineCircle:(NSArray *)parms;
- (void)defineLine:(NSArray *)parms;
- (void)defineOval:(NSArray *)parms;
- (void)definePoint:(NSArray *)parms;
- (void)defineRect:(NSArray *)parms;
- (void)defineText:(NSArray *)parms;
- (void)paint:(NSArray *)parms;
- (void)clear:(NSArray *)parms;
- (void)saveAsBitmap:(NSArray *)parms;
@end
