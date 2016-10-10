//
//  JXDrawView.m
//  JXTouchTracker
//
//  Created by 王加祥 on 16/10/8.
//  Copyright © 2016年 王加祥. All rights reserved.
//

#import "JXDrawView.h"
#import "JXLine.h"

@interface JXDrawView ()<UIGestureRecognizerDelegate>

/** 保存已经绘制完成的线条 */
@property (nonatomic,strong) NSMutableArray * finishedLines;
/** 保存正在绘制的多条直线 */
@property (nonatomic,strong) NSMutableDictionary * linesInProgress;
/** 保存选中的线条 */
@property (nonatomic,weak) JXLine * selectedLine;
/** 移动手势 */
@property (nonatomic,strong) UIPanGestureRecognizer * moveRecognizer;

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
        
        // 添加点击事件
        UITapGestureRecognizer * doubleTapRecoginzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapRecoginzer.numberOfTapsRequired = 2;
        // 为了避免在识别出点击手势之前出发touches手势
        doubleTapRecoginzer.delaysTouchesBegan  = YES;
        [self addGestureRecognizer:doubleTapRecoginzer];
        
        // 添加单机事件
        UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tapRecognizer.delaysTouchesBegan = YES;
        // 用来防止将双击事件拆分为单击
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecoginzer];
        [self addGestureRecognizer:tapRecognizer];
        
        // 添加长按手势
        UILongPressGestureRecognizer * pressRecoginzer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [self addGestureRecognizer:pressRecoginzer];
        
        // 移动手势
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        self.moveRecognizer.delegate = self;
        self.moveRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:self.moveRecognizer];
    }
    return self;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.moveRecognizer) {
        return YES;
    }
    return NO;
}

- (void)moveLine:(UIPanGestureRecognizer *)panGesture {
    // 如果没有选中的线条就直接返回
    if (!self.selectedLine) {
        return;
    }
    
    // 如果 UIPanGestureRecoginzer 对象处于 “变化后”的状态
    if (panGesture.state == UIGestureRecognizerStateChanged) {
        // 获取手指的拖移距离
        CGPoint translation = [panGesture translationInView:self];
        
        // 将拖动距离加至选中的线条的起点和终点
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        begin.x += translation.x;
        begin.y += translation.y;
        end.x += translation.x;
        end.y += translation.y;
        
        // 为选中的线条设置新的起点和终点
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;
        
        // 重画视图
        [self setNeedsDisplay];
        
        // 每次移动过后将手指的当前位置设置为手指的起始位置
        [panGesture setTranslation:CGPointZero inView:self];
    }
}

// 添加长按手势
- (void)longPress:(UIGestureRecognizer *)press {
    if (press.state == UIGestureRecognizerStateBegan) {
        
        CGPoint point = [press locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
        }
    } else if (press.state == UIGestureRecognizerStateEnded) {
        self.selectedLine = nil;
    }
    [self setNeedsDisplay];
}
// 添加单机事件
- (void)tap:(UIGestureRecognizer *)tap {

    CGPoint point = [tap locationInView:self];
    self.selectedLine = [self lineAtPoint:point];
    
    // 当有选中线条时
    if (self.selectedLine) {
        
        // 是视图成为 UIMenuItem 动作消息的目标
        [self becomeFirstResponder];
        
        // 获取 UIMenuController 对象
        UIMenuController * menu = [UIMenuController sharedMenuController];
        
        // 创建一个新的标题为“Delete”的UIMenuItem对象
        UIMenuItem * deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
        menu.menuItems = @[deleteItem];
        
        // 先为 UIMenuController 对象设置显示区域，然后将其设置为可见
        [menu setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    } else {
        // 如果没有选中的线条，就隐藏 UIMenuController 对象
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    [self setNeedsDisplay];
}

- (void)deleteLine:(id)sender {
    // 从已经完成的小太中删除选中的线条
    [self.finishedLines removeObject:self.selectedLine];
    
    // 重画整个视图
    [self setNeedsDisplay];
}

// 添加手势
- (void)doubleTap:(UIGestureRecognizer *)tap {
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

// 将某个自定义的UIView子类对象设置为第一响应对象，就必须覆盖此类方法
- (BOOL)canBecomeFirstResponder {
    return YES;
}
// 画线
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
    
    if (self.selectedLine) {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
    
}

// 根据传入的位置找出距离最近的那个对象
- (JXLine *)lineAtPoint:(CGPoint)p {
    
    // 找出离p最近的JXLine对象
    for (JXLine * line in self.finishedLines) {
        CGPoint start = line.begin;
        CGPoint end = line.end;
        
        // 检查线条的若干个点
        for (float t = 0.0; t <= 1.0; t += 0.05) {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);
            
            // 如果线条的某个点和p的距离在20点以内，就返回响应的JXLIne对象
            if (hypot(x-p.x, y-p.y) < 20.0) {
                return line;
            }
        }
    }
    
    // 如果没有找到符合条件的线条，就返回nil
    return nil;
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
