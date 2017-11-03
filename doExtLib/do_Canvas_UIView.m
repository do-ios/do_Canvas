//
//  do_Canvas_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Canvas_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doJsonHelper.h"
#import "doDefines.h"
#import "doIOHelper.h"
#import "doTextHelper.h"
#import "doDefines.h"
#import "doIPage.h"
#import "doIBitmap.h"
#import "doMultitonModule.h"

#import<CoreText/CoreText.h>

#define FONT_OBLIQUITY 15.0

@implementation do_Canvas_UIView
{
    NSString *_strokeColor;
    int _strokeCap;
    float _strokeWidth;
    
    NSMutableDictionary *_paths;
    
    BOOL _isFull;
    
    id<doIScriptEngine> _scritEngine;
    
}

#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    
    _paths = [NSMutableDictionary dictionary];
    
    //设置一个默认的背景色，防止多次绘制重影问题
    UIColor *bgColor = self.backgroundColor;
    if (!bgColor) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    
    _strokeColor = @"000000FF";
    _strokeCap = 0;
    _strokeWidth = 1.0f;
    [_model SetPropertyValue:@"strokeWidth" :@"1"];
    _isFull = YES;

    self.clearsContextBeforeDrawing = NO;
}

//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    [_paths removeAllObjects];
    _paths = nil;
    
    _scritEngine = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
}


#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_strokeCap:(NSString *)newValue
{
    //自己的代码实现
    _strokeCap = [newValue intValue];
}
- (void)change_strokeColor:(NSString *)newValue
{
    //自己的代码实现
    _strokeColor = newValue;
}
- (void)change_strokeWidth:(NSString *)newValue
{
    //自己的代码实现
    float scale = (_model.XZoom + _model.YZoom) * 0.5;
    if ([newValue integerValue] <= 0){
        _strokeWidth = 1.0f;
    }else {
        _strokeWidth = [newValue integerValue] * scale;
    }
}
- (void)change_isFull:(NSString *)newValue
{
    _isFull = [newValue boolValue];
}

#pragma mark - draw
- (void)drawRect:(CGRect)rect
{
    for (NSDictionary *tmp in [_paths allValues]) {
        for (NSString *key in [tmp allKeys]) {
            NSMutableString *methodName = [NSMutableString stringWithString:key];
            if (!methodName || methodName.length==0) {
                return;
            }
            [methodName insertString:@"_draw" atIndex:methodName.length-1];
            SEL selector = NSSelectorFromString(methodName);
            if ([self respondsToSelector:selector]) {
                SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING([self performSelector:selector withObject:tmp]);
            }
        }
    }
}

- (void)defineArc_draw:(NSDictionary *)parms
{
    [self define:parms :NSStringFromSelector(_cmd)];
}
- (void)defineImage_draw:(NSDictionary *)parms
{
    [self define:parms :NSStringFromSelector(_cmd)];
}
- (void)defineCircle_draw:(NSDictionary *)parms
{
    [self define:parms :NSStringFromSelector(_cmd)];
}
- (void)defineLine_draw:(NSDictionary *)parms
{
    [self define:parms :NSStringFromSelector(_cmd)];
}
- (void)defineOval_draw:(NSDictionary *)parms
{
    [self define:parms :NSStringFromSelector(_cmd)];
}
- (void)definePoint_draw:(NSDictionary *)parms
{
    [self define:parms :NSStringFromSelector(_cmd)];
}
- (void)defineRect_draw:(NSDictionary *)parms
{
    [self define:parms :NSStringFromSelector(_cmd)];
}
- (void)defineText_draw:(NSDictionary *)parms
{
    [self define:parms :NSStringFromSelector(_cmd)];
}
- (void)define:(NSDictionary *)parms :(NSString *)name
{
    NSString *key = [name stringByReplacingOccurrencesOfString:@"_draw" withString:@""];

    UIColor *color = [parms objectForKey:@"strokeColor"];
    int strokeCap = [[parms objectForKey:@"strokeCap"] intValue];
    CGLineCap cap = strokeCap==0?kCGLineCapSquare:kCGLineCapRound;
    int strokeWidth = [[parms objectForKey:@"strokeWidth"] intValue];
    BOOL isFull = [[parms objectForKey:@"isFull"] boolValue];
    CGFloat zoom = (_model.XZoom+_model.YZoom)/2.0f;
    
    //draw
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineCap(context, cap);
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    //data
    NSMutableDictionary *draw = [NSMutableDictionary dictionaryWithDictionary:[doJsonHelper GetOneNode:parms :key]];
    NSDictionary *point = [doJsonHelper GetOneNode:draw :@"point"];
    CGFloat x = [doJsonHelper GetOneFloat:point :@"x" :0]*_model.XZoom;
    CGFloat y = [doJsonHelper GetOneFloat:point :@"y" :0]*_model.YZoom;
    CGFloat radius = [doJsonHelper GetOneFloat:draw :@"radius" :0]*zoom;

    NSDictionary *start = [doJsonHelper GetOneNode:draw :@"start"];
    CGFloat startX = [doJsonHelper GetOneFloat:start :@"x" :0]*_model.XZoom;
    CGFloat startY = [doJsonHelper GetOneFloat:start :@"y" :0]*_model.YZoom;
    
    NSDictionary *end = [doJsonHelper GetOneNode:draw :@"end"];
    CGFloat endX = [doJsonHelper GetOneFloat:end :@"x" :0]*_model.XZoom;
    CGFloat endY = [doJsonHelper GetOneFloat:end :@"y" :0]*_model.YZoom;
    
    NSString *source = [doJsonHelper GetOneText:draw :@"source" :@""];
    NSDictionary *coord = [doJsonHelper GetOneNode:draw :@"coord"];
    CGFloat coordX = [doJsonHelper GetOneFloat:coord :@"x" :0]*_model.XZoom;
    CGFloat coordY = [doJsonHelper GetOneFloat:coord :@"y" :0]*_model.YZoom;
    
    CGFloat startAngle = [doJsonHelper GetOneFloat:draw :@"startAngle" :0];
    CGFloat sweepAngle = [doJsonHelper GetOneFloat:draw :@"sweepAngle" :90];
    BOOL useCenter = [doJsonHelper GetOneBoolean:draw :@"useCenter" :YES];
    
    //draw points
    NSArray *points = [doJsonHelper GetOneArray:draw :@"points"];
    
    //draw text
    NSString *text = [doJsonHelper GetOneText:draw :@"text" :@""];
    NSString *fontStyle = [doJsonHelper GetOneText:draw :@"fontStyle" :@"normal"];
    NSString *textFlag = [doJsonHelper GetOneText:draw :@"textFlag" :@"normal"];
    NSString *textAlign = [doJsonHelper GetOneText:draw :@"textAlign" :@"left"];
    int fontSize = [doJsonHelper GetOneInteger:draw :@"fontSize" :17];
    float angle = [doJsonHelper GetOneInteger:draw :@"angle" :0];
    fontSize = [doUIModuleHelper GetDeviceFontSize:fontSize :_model.XZoom :_model.YZoom];

    
    if ([[key lowercaseString] rangeOfString:@"circle"].location != NSNotFound) {
        if (!isFull) {
            CGContextAddArc(context, x, y, radius, 0, 2*M_PI, 0);
            CGContextStrokePath(context);
        }else{
            CGContextAddEllipseInRect(context, CGRectMake(x-radius, y-radius, radius*2, radius*2));
            [color set];
            CGContextFillPath(context);
        }
    }else if ([[key lowercaseString] rangeOfString:@"oval"].location != NSNotFound) {
        CGRect r = CGRectMake(startX, startY, endX-startX, endY-startY);
        CGContextAddEllipseInRect(context, r);
        if (!isFull) {
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextStrokePath(context);
        }else{
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextFillPath(context);
        }
    }else if ([[key lowercaseString] rangeOfString:@"line"].location != NSNotFound) {
        CGContextBeginPath(context);

        CGContextMoveToPoint(context, startX, startY);
        CGContextAddLineToPoint(context, endX, endY);
        
        CGContextStrokePath(context);
    }else if ([[key lowercaseString] rangeOfString:@"rect"].location != NSNotFound){
        CGRect r = CGRectMake(startX, startY, endX-startX, endY-startY);
        if (!isFull) {
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            CGContextStrokeRect(context, r);
        }else{
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextFillRect(context, r);
        }
    }else if ([[key lowercaseString] rangeOfString:@"image"].location != NSNotFound){
        NSString * imgPath = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :source];
        UIImage *img = nil;
        if (imgPath.length==0 || !imgPath) {
            //bitmap
            doMultitonModule *_multitonModule = [doScriptEngineHelper ParseMultitonModule:_scritEngine :source];
            id<doIBitmap> bitmap = (id<doIBitmap>)_multitonModule;
            img = [bitmap getData];
        }else
            img = [UIImage imageWithContentsOfFile:imgPath];
        CGRect r = CGRectMake(coordX, coordY, img.size.width*_model.XZoom, img.size.height*_model.YZoom);
        UIGraphicsPushContext(context);
        [img drawInRect:r];
        UIGraphicsPopContext();
    }else if ([[key lowercaseString] rangeOfString:@"arc"].location != NSNotFound){
        CGFloat width = endX - startX;
        CGFloat height = endY - startY;
        CGPoint center = CGPointMake(startX + width / 2.0, startY + height / 2.0);
        CGFloat radius = MAX(width/2, height/2);
        CGContextAddArc(context, center.x, center.y, radius, (startAngle/180)*M_PI, ((startAngle+sweepAngle)/180)*M_PI, 0);
        
        if (!isFull) {
            
            CGContextStrokePath(context);
            //不填充时useCenter为true时显示中心点
            if (useCenter) {
                //画中心点
                
                UIColor *color = [doUIModuleHelper GetColorFromString:_strokeColor :[UIColor blackColor]];
                [color set];
                
                UIBezierPath * path = [UIBezierPath bezierPath];
                path.lineWidth = _strokeWidth;
                path.lineCapStyle = kCGLineCapRound;
                path.lineJoinStyle = kCGLineCapRound;
                
                CGPoint p0 = CGPointMake(center.x, center.y);
                CGPoint p1 = CGPointMake(center.x, center.y);

                [path moveToPoint:p0];
                [path addLineToPoint:p1];
                [path stroke];
                
                //画中心点与两点连线
                CGPoint point1 = CGPointMake(center.x+radius*cos((startAngle/180)*M_PI), center.y+radius*sin((startAngle/180)*M_PI));
                CGPoint point2 = CGPointMake(center.x+radius*cos(((startAngle+sweepAngle)/180)*M_PI), center.y+radius*sin(((startAngle+sweepAngle)/180)*M_PI));
                
                [path moveToPoint:p0];
                [path addLineToPoint:point1];
                [path stroke];
                
                [path moveToPoint:p0];
                [path addLineToPoint:point2];
                [path stroke];
                
            }
        }else{
            //没有中心点则为一条弧线
            if (!useCenter) {
                               
                CGPoint point1 = CGPointMake(center.x+radius*cos((startAngle/180)*M_PI), center.y+radius*sin((startAngle/180)*M_PI));
                CGPoint point2 = CGPointMake(center.x+radius*cos(((startAngle+sweepAngle)/180)*M_PI), center.y+radius*sin(((startAngle+sweepAngle)/180)*M_PI));
                CGContextMoveToPoint(context, point2.x, point2.y);
                CGContextAddLineToPoint(context, point1.x, point1.y);
                CGContextSetFillColorWithColor(context, color.CGColor);

                CGContextDrawPath(context, kCGPathFillStroke);
                CGContextClosePath(context);
            } else {
               
                CGContextSetFillColorWithColor(context, color.CGColor);
                CGContextMoveToPoint(context, center.x, center.y);
                CGContextAddArc(context, center.x, center.y, radius, (startAngle/180)*M_PI, ((startAngle+sweepAngle)/180)*M_PI, 0);
                CGContextClosePath(context);
                CGContextDrawPath(context, kCGPathFillStroke);

            }
        }
    }else if ([[key lowercaseString] rangeOfString:@"point"].location != NSNotFound){
        for (NSDictionary *p in points) {
            CGFloat px = [doJsonHelper GetOneFloat:p :@"x" :0]*_model.XZoom;
            CGFloat py = [doJsonHelper GetOneFloat:p :@"y" :0]*_model.YZoom;
            CGPoint startP = CGPointMake(px-strokeWidth/2, py-strokeWidth/2);
            CGRect rectP = CGRectMake(startP.x, startP.y, strokeWidth, strokeWidth);
            if (cap == kCGLineCapSquare) {
                CGContextSetFillColorWithColor(context, color.CGColor);
                CGContextFillRect(context, rectP);
            }else if (cap == kCGLineCapRound) {
                CGContextAddEllipseInRect(context, rectP);
                [color set];
                CGContextFillPath(context);
            }
        }
    }else if ([[key lowercaseString] rangeOfString:@"text"].location != NSNotFound){
        NSMutableAttributedString *t = [[NSMutableAttributedString alloc] initWithString:text];
        NSMutableDictionary * attrs = [NSMutableDictionary dictionary];
        NSRange contentRange = {0,[t length]};
        
        //color
        [attrs setObject:color forKey:NSForegroundColorAttributeName];

        //style
        UIFont *font = [UIFont systemFontOfSize:fontSize];
        if([fontStyle isEqualToString:@"normal"]){}
        else if([fontStyle isEqualToString:@"bold"])
            font = [UIFont boldSystemFontOfSize:fontSize];
        else if([fontStyle isEqualToString:@"italic"])
        {
            CGAffineTransform matrix =  CGAffineTransformMake(1, 0, tanf(FONT_OBLIQUITY * (CGFloat)M_PI / 180), 1, 0, 0);
            UIFontDescriptor *desc = [ UIFontDescriptor fontDescriptorWithName :[ UIFont systemFontOfSize :fontSize ]. fontName matrix :matrix];
            font = [ UIFont fontWithDescriptor :desc size :fontSize];
        }
        else if([fontStyle isEqualToString:@"bold_italic"]){}
        [attrs setObject:font forKey:NSFontAttributeName];

        //flag
        BOOL isFlag = YES;
        if (!IOS_8 && fontSize < 14) {
            isFlag = NO;
        }
        if (isFlag) {
            
            [t removeAttribute:NSUnderlineStyleAttributeName range:contentRange];
            [t removeAttribute:NSStrikethroughStyleAttributeName range:contentRange];
            if ([textFlag isEqualToString:@"normal" ]) {
            }else if ([textFlag isEqualToString:@"underline" ]) {
                [attrs setObject:@(NSUnderlineStyleSingle) forKey:NSUnderlineStyleAttributeName];
            }else if ([textFlag isEqualToString:@"strikethrough" ]) {
                [attrs setObject:@(NSUnderlineStyleSingle|NSUnderlinePatternSolid) forKey:NSStrikethroughStyleAttributeName];
                [attrs setObject:@(NSUnderlineStyleSingle) forKey:NSBaselineOffsetAttributeName];
            }
        }

        [t beginEditing];
        [t setAttributes:attrs range:contentRange];
        [t endEditing];
        
        CGFloat maxW = 99999;
        CGFloat maxH = 99999;

        NSStringDrawingOptions options =  NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
        CGRect maxRect = [t boundingRectWithSize:CGSizeMake(maxW, maxH)
                                            options:options
                                            context:nil];

        UILabel *label = [[UILabel alloc] init];
        CGFloat originX = 0,originY = coordY;
        //align
        if([textAlign isEqualToString:@"left"]){
            originX = coordX;
            label.layer.anchorPoint = CGPointMake(0, 0);
        }else if([textAlign isEqualToString:@"center"]){
            originX = coordX-CGRectGetWidth(maxRect)/2;
            label.layer.anchorPoint = CGPointMake(.5, .5);
        }else if([textAlign isEqualToString:@"right"]){
            originX = coordX-CGRectGetWidth(maxRect);
            label.layer.anchorPoint = CGPointMake(1, 1);
        }
        maxRect = CGRectMake(originX, originY, CGRectGetWidth(maxRect), CGRectGetHeight(maxRect));

        label.frame = maxRect;
        label.numberOfLines = 0;
        label.attributedText = t;
        CGAffineTransform transform = CGAffineTransformIdentity;
        label.transform = CGAffineTransformRotate(transform, (angle/180)*M_PI);

        [self addSubview:label];
    }
}

#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)generateState:(NSDictionary *)dict :(NSString *)draw
{
    NSInteger key = [_paths allKeys].count;
    NSNumber *k ;
    //wtc code 删除这段代码画布上已经存在的图形不会消失
//    if (key>0) {
//        for (NSNumber *kk in [_paths allKeys]) {
//            NSDictionary *_tmp = [_paths objectForKey:kk];
//            NSDictionary *_tmp1 = [_tmp objectForKey:draw];
//            if ([dict isEqualToDictionary:_tmp1]) {
//                k = kk;
//                break;
//            }
//        }
//    }
    
    if (k) {
        [_paths removeObjectForKey:k];
    }
    
    NSMutableDictionary *state = [NSMutableDictionary dictionary];
    
    UIColor *color = [doUIModuleHelper GetColorFromString:_strokeColor :[UIColor blackColor]];

    [state setObject:color forKey:@"strokeColor"];
    [state setObject:@(_strokeWidth) forKey:@"strokeWidth"];
    [state setObject:@(_strokeCap) forKey:@"strokeCap"];
    [state setObject:@(_isFull) forKey:@"isFull"];
    [state setObject:dict forKey:draw];

    [_paths setObject:state forKey:@(key)];
}
- (void)definePoint:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];

    NSDictionary *definePoint = [doJsonHelper GetNode:_dictParas];
    if (definePoint) {
        NSString *name = NSStringFromSelector(_cmd);
        [self generateState:definePoint :name];
    }
}
- (void)defineLine:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];

    NSDictionary *defineLine = [doJsonHelper GetNode:_dictParas];
    if (defineLine) {
        NSString *name = NSStringFromSelector(_cmd);
        [self generateState:defineLine :name];
    }
    
}
- (void)defineCircle:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];

    NSDictionary *defineCircle = [doJsonHelper GetNode:_dictParas];
    if (defineCircle) {
        NSString *name = NSStringFromSelector(_cmd);
        [self generateState:defineCircle :name];
    }
}
- (void)defineOval:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];

    NSDictionary *defineOval = [doJsonHelper GetNode:_dictParas];
    if (defineOval) {
        NSString *name = NSStringFromSelector(_cmd);
        [self generateState:defineOval :name];
    }
}
- (void)defineArc:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];

    NSDictionary *defineArc = [doJsonHelper GetNode:_dictParas];
    if (defineArc) {
        NSString *name = NSStringFromSelector(_cmd);
        [self generateState:defineArc :name];
    }
}
- (void)defineRect:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];

    NSDictionary *defineRect = [doJsonHelper GetNode:_dictParas];
    if (defineRect) {
        NSString *name = NSStringFromSelector(_cmd);
        [self generateState:defineRect :name];
    }
}
- (void)defineText:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];

    NSDictionary *defineText = [doJsonHelper GetNode:_dictParas];
    if (defineText) {
        NSString *name = NSStringFromSelector(_cmd);
        [self generateState:defineText :name];
    }
}
- (void)defineImage:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    _scritEngine = [parms objectAtIndex:1];
    
    NSDictionary *defineBitmap = [doJsonHelper GetNode:_dictParas];
    if (defineBitmap) {
        NSString *name = NSStringFromSelector(_cmd);
        [self generateState:defineBitmap :name];
    }
}

- (void)paint:(NSArray *)parms
{
    //重新绘制之前清空上次绘制的，避免多次绘制导致重影
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UILabel class]]) {
            [obj removeFromSuperview];
        }
    }];
    [self setNeedsDisplay];
}

- (void)clear:(NSArray *)parms {
    [_paths removeAllObjects];
    //重新绘制之前清空上次绘制的，避免多次绘制导致重影
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UILabel class]]) {
            [obj removeFromSuperview];
        }
    }];
    [self setNeedsDisplay];
}

//异步
- (void)saveAsBitmap:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    
    //自己的代码实现
    NSString * bitmapAddress = [doJsonHelper GetOneText:_dictParas :@"bitmap" :@""];
    UIImage * img = [self getImageFromView:self];
    doMultitonModule * _multitionModule = [doScriptEngineHelper ParseMultitonModule:_scriptEngine :bitmapAddress];
    id<doIBitmap> bitmap = (id<doIBitmap>)_multitionModule;
    
    [bitmap setData:img];
    
    NSString * _callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    doInvokeResult * _invokeRssult = [[doInvokeResult alloc] init];
    //_invokeRssult设置返回值
    
    [_scriptEngine Callback:_callbackName :_invokeRssult];
}

- (UIImage *)getImageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:ctx];
    //3.从上下文当中生成一张图片
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    //4.关闭上下文
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

// Canvas直接继承UIView, UIView默认可响应事件。当事件传递到当前时，会被Canvas给消费掉。当前组件功能要求Canvas不处理事件,return nil 将事件抛给父类处理。
#pragma mark - 重写该方法，动态选择事件的施行或无效
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return nil;
}

@end
