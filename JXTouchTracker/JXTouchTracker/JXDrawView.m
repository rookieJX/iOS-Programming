//
//  JXDrawView.m
//  JXTouchTracker
//
//  Created by 王加祥 on 16/10/8.
//  Copyright © 2016年 王加祥. All rights reserved.
//

#import "JXDrawView.h"
#import "JXLine.h"

@interface JXDrawView ()
/** 保存当前正在绘制线条 */
@property (nonatomic,strong) JXLine * currentLine;
/** 保存已经绘制完成的线条 */
@property (nonatomic,strong) NSMutableArray * finishedLines;
/** 保存正在绘制的多条直线 */
@property (nonatomic,strong) NSMutableDictionary * linesInProgress;

@end

@implementation JXDrawView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.linesInProgress = [NSMutableDictionary dictionary];
        self.finishedLines = [NSMutableArray array];
        self.backgroundColor = [UIColor grayColor];
        
        // 支持多点触摸
        self.multipleTouchEnabled = YES;
    }
    return self;
}

- (void)strokeLine:(JXLine *)line {
    UIBezierPath * bp = [UIBezierPath bezierPath];
    bp.lineWidth = 3;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

- (void)drawRect:(CGRect)rect {
    // 用黑色表示已经绘制完成的线条
    [[UIColor blackColor] set];
    for (JXLine * line in self.finishedLines) {
        [self strokeLine:line];
    }
    
    // 用红色绘制正在画的线条
    [[UIColor redColor] set];
    for (NSValue * key in self.linesInProgress) {
        [self strokeLine:self.linesInProgress[key]];
    }
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    for (UITouch * t in touches) {
        CGPoint location = [t locationInView:self];
        
        JXLine * line = [[JXLine alloc] init];
        line.begin = location;
        line.end = location;
        
        NSValue * key = [NSValue valueWithNonretainedObject:t];
        self.linesInProgress[key] = line;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    for (UITouch * t in touches) {
        NSValue * key = [NSValue valueWithNonretainedObject:t];
        JXLine * line = self.linesInProgress[key];
        line.end = [t locationInView:self];
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *t in touches) {
        NSValue * key = [NSValue valueWithNonretainedObject:t];
        JXLine * line = self.linesInProgress[key];
        
        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        NSValue * key = [NSValue valueWithNonretainedObject:t];
        [self.linesInProgress removeObjectForKey:key];
    }
    [self setNeedsDisplay];
}


@end
