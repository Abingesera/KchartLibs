//
//  lineView.m
//  RunChartAndKchart
//
//  Created by zsgjs on 15/12/16.
//  Copyright (c) 2015年 zsgjs. All rights reserved.
//

#import "lineView.h"
#import "Config.h"



@interface lineView ()
{
    CGFloat paddingX;//分时图X坐标      K线主图X坐标
    CGFloat paddingY;//分时图Y坐标      K线主图Y坐标
    CGFloat paddingWidth;//分时图宽度   K线主图宽度
    CGFloat paddingHeight;//分时图高度  K线主图高度
    
    CGFloat bottomX;//K线副图X坐标
    CGFloat bottomY;//K线副图Y坐标
    CGFloat bottomWidth;//K线副图宽度
    CGFloat bottomHeight;//K线副图高度
    
}

@end

@implementation lineView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark 画坐标系和坐标轴
- (void)drawSectionsWithDic:(NSDictionary *)dic {
    NSArray *arr = dic[@"secs"];
    //分时图坐标系
    if (arr.count == 1) {
        paddingX = [[arr[0] objectAtIndex:0] floatValue];//X
        paddingY = [[arr[0] objectAtIndex:1] floatValue];//Y
        paddingWidth = [[arr[0] objectAtIndex:2] floatValue];//宽
        paddingHeight = [[arr[0] objectAtIndex:3] floatValue];//高
        
        NSString *type = dic[@"type"];//区别分时图类型
        //根据type字段画分时图坐标系
        [self drawRunChartBoxWithString:type];
    }else {
        //K线图坐标系
        paddingX = [[arr[0] objectAtIndex:0] floatValue];//主图X
        paddingY = [[arr[0] objectAtIndex:1] floatValue];//主图Y
        paddingWidth = [[arr[0] objectAtIndex:2] floatValue];//主图宽
        paddingHeight = [[arr[0] objectAtIndex:3] floatValue];//主图高
        
        bottomX = [[arr[1] objectAtIndex:0] floatValue];//副图X
        bottomY = [[arr[1] objectAtIndex:1] floatValue];//副图Y
        bottomWidth = [[arr[1] objectAtIndex:2] floatValue];//副图宽
        bottomHeight = [[arr[1] objectAtIndex:3] floatValue];//副图高
        //画K线图坐标系
        [self drawKchartbox];
        
    }
}


#pragma mark 绘制分时图坐标系

- (void)drawRunChartBoxWithString:(NSString *)type {
    
    //画长方形
    CGContextRef context = UIGraphicsGetCurrentContext();
    //绘图之前清除内容
    CGContextClearRect(context, self.frame);
//    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:26 green:34 blue:44 alpha:0.1] CGColor]); //设置颜色，仅填充4条边
      CGContextSetStrokeColorWithColor(context, [[@"#EBEBEB" hexStringToColor] CGColor]);
    //    CGContextSetLineWidth(context, 0.5); //设置线宽为0.5
    
    CGPoint poins[] = {CGPointMake(paddingX, paddingY),CGPointMake(paddingX + paddingWidth, paddingY),CGPointMake(paddingX+ paddingWidth, paddingY +paddingHeight),CGPointMake(paddingX, paddingY + paddingHeight)};    //设置长方形4个顶点
    CGContextAddLines(context,poins,4);
    CGContextClosePath(context);
    CGContextStrokePath(context);
    
    //画分割线
    //横线
    CGFloat padRealValue = paddingHeight / 6;
    for (int i = 1; i<6; i++) {
        CGFloat y = paddingHeight-padRealValue * i + paddingY;
        CGPoint startPoint = CGPointMake(paddingX, y);
        CGPoint endPoint = CGPointMake(paddingX+ paddingWidth, y);
        // 定义两个点 画两点连线
        
        //分时图0轴虚线
        if (i == 3) {
            //            CGContextSetLineWidth(context, 1.0); //虚线加宽
            //            //画虚线
            //            CGFloat lengths[] = {5,5};
            //            CGContextSetLineDash(context, 0, lengths, 2);
            //            CGContextMoveToPoint(context, startPoint.x, startPoint.y);
            //            CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            //            CGContextStrokePath(context);
            
            continue;
            
        }else {
            
            const CGPoint points[] = {startPoint,endPoint};
            CGContextSetLineWidth(context, 0.5); //设置线宽为0.5
            CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
            
        }
    }
    
    //竖线
    if ([type intValue] == 1 || [type intValue] == 4) {
        
        CGFloat padValue = paddingWidth / 4;
        for (int j = 1;  j < 4; j++) {
            CGFloat x = padValue * j;
            CGPoint startPoint = CGPointMake(x + paddingX, paddingY);
            CGPoint endPoint = CGPointMake(x + paddingX,paddingY+ paddingHeight);
            
            // 定义两个点 画两点连线
            const CGPoint points[] = {startPoint,endPoint};
            CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
            
            //            CGContextSetLineWidth(context, 1.5); //虚线加宽
            //            //画虚线
            //            CGFloat lengths[] = {5,5};
            //            CGContextSetLineDash(context, 0, lengths, 2);
            //            CGContextMoveToPoint(context, startPoint.x, startPoint.y);
            //            CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            //            CGContextStrokePath(context);
            
        }
    }else if ([type intValue] == 2) {
        
        CGContextSetLineWidth(context, 0.5);
        CGFloat padValue = paddingWidth / 2;
        CGFloat x = padValue;
        CGPoint startPoint = CGPointMake(x + paddingX, paddingY);
        CGPoint endPoint = CGPointMake(x + paddingX,paddingY+ paddingHeight);
        
        // 定义两个点 画两点连线
        const CGPoint points[] = {startPoint,endPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
        
        //画虚线
        //        CGFloat lengths[] = {5,5};
        //
        //        CGContextSetLineDash(context, 0, lengths, 2);
        //        CGContextMoveToPoint(context, startPoint.x, startPoint.y);
        //        CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
        //        CGContextStrokePath(context);
        
        
    }else if ([type intValue] == 3) {
        
        CGContextSetLineWidth(context, 0.5);
        
        CGFloat padValue = paddingWidth / 3;
        for (int j = 1;  j < 3; j++) {
            CGFloat x = padValue * j;
            CGPoint startPoint = CGPointMake(x + paddingX, paddingY);
            CGPoint endPoint = CGPointMake(x + paddingX,paddingY+ paddingHeight);
            
            // 定义两个点 画两点连线
            const CGPoint points[] = {startPoint,endPoint};
            CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
            //            //画虚线
            //            CGFloat lengths[] = {5,5};
            //            CGContextSetLineDash(context, 0, lengths, 2);
            //            CGContextMoveToPoint(context, startPoint.x, startPoint.y);
            //            CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            //            CGContextStrokePath(context);
            
        }
        
    }
    
    
    //0轴虚线
    CGFloat y = paddingHeight - padRealValue * 3 + paddingY;
    CGPoint startPoint = CGPointMake(paddingX, y);
    CGPoint endPoint = CGPointMake(paddingX + paddingWidth, y);
    
    CGContextSetLineWidth(context, 0.5); //虚线加宽
    
    //画虚线
    
    CGFloat lengths[] = {5,5};
    
    CGContextSetLineDash(context, 0, lengths, 2);
    
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    
    CGContextStrokePath(context);
    
}


#pragma mark 绘制K线图坐标系
- (void)drawKchartbox {

    //画主图
    
    //画长方形
    CGContextRef context = UIGraphicsGetCurrentContext();
    //绘图之前清除内容
    CGContextClearRect(context, self.frame);
    
    //设置颜色，仅填充4条边
    CGContextSetStrokeColorWithColor(context, [[@"#EBEBEB" hexStringToColor] CGColor]);
    //设置线宽为0.5
    CGContextSetLineWidth(context, 0.5);
    
    //设置长方形4个顶点
    CGPoint poins[] = {CGPointMake(paddingX, paddingY),CGPointMake(paddingWidth + paddingX, paddingY),CGPointMake(paddingWidth + paddingX, paddingY + paddingHeight),CGPointMake(paddingX, paddingHeight + paddingY)};
    CGContextAddLines(context,poins,4);
    CGContextClosePath(context);
    CGContextStrokePath(context);
    
    
    //画分割线
    CGFloat padRealValue = paddingHeight / 4;
    CGFloat padValue = paddingWidth / 4;
    
    for (int i = 1; i<4; i++) {
        //横线
        CGContextSetLineDash(context, 0, 0, 0);
        CGFloat y = paddingHeight + paddingY-padRealValue * i;
        CGPoint startPoint = CGPointMake(paddingX, y );
        CGPoint endPoint = CGPointMake(paddingX + paddingWidth, y);
        // 定义两个点 画两点连线
        const CGPoint points[] = {startPoint,endPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
        
        //竖线
        CGFloat x = padValue * i;
        CGPoint startPoint1 = CGPointMake(x + paddingX, paddingY);
        CGPoint endPoint1 = CGPointMake(x + paddingX, paddingY + paddingHeight);
        
        // 定义两个点 画两点连线
        const CGPoint points1[] = {startPoint1,endPoint1};
        CGContextStrokeLineSegments(context, points1, 2);  // 绘制线段（默认不绘制端点）
        
        //        //画虚线
        //        CGFloat lengths[] = {5,5};
        //        CGContextSetLineDash(context, 0, lengths, 2);
        //        CGContextMoveToPoint(context, startPoint1.x, startPoint1.y);
        //        CGContextAddLineToPoint(context, endPoint1.x, endPoint1.y);
        //        CGContextStrokePath(context);
        
    }
    
    
    
    //画副图
    
    //设置颜色，仅填充4条边
    CGContextSetStrokeColorWithColor(context, [[@"#EBEBEB" hexStringToColor] CGColor]);
    //设置线宽为0.5
    CGContextSetLineWidth(context, 0.5);
    CGContextSetLineDash(context, 0, 0, 0);
    //设置长方形4个顶点
    CGPoint points[] = {CGPointMake(bottomX, bottomY),CGPointMake(bottomX + bottomWidth, bottomY),CGPointMake(bottomX + bottomWidth, bottomY + bottomHeight),CGPointMake(bottomX, bottomY + bottomHeight)};
    CGContextAddLines(context,points,4);
    CGContextClosePath(context);
    CGContextStrokePath(context);
    
    //画分割线
    
    
    //竖线
    CGFloat padValue2 = bottomWidth / 4;
    for (int j = 1;  j < 4; j++) {
        CGFloat x = padValue2 * j;
        CGPoint startPoint = CGPointMake(bottomX + x, bottomY);
        CGPoint endPoint = CGPointMake(bottomX + x , bottomY + bottomHeight);
        
        // 定义两个点 画两点连线
        const CGPoint points[] = {startPoint,endPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
        
        //        //画虚线
        //        CGFloat lengths[] = {5,5};
        //        CGContextSetLineDash(context, 0, lengths, 2);
        //        CGContextMoveToPoint(context, startPoint.x, startPoint.y);
        //        CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
        //        CGContextStrokePath(context);
    }
    
    //横线  虚线
    CGFloat pValue = bottomHeight / 2;
    CGFloat y =bottomY + bottomHeight-pValue;
    CGPoint startPoint = CGPointMake(bottomX,  y);
    CGPoint endPoint = CGPointMake(bottomX + bottomWidth, y);
    // 定义两个点 画两点连线
    //    const CGPoint pointsArr[] = {startPoint,endPoint};
    //    CGContextStrokeLineSegments(context, pointsArr, 2);  // 绘制线段（默认不绘制端点）
    
    CGFloat lengths[] = {5,5};
    CGContextSetLineDash(context, 0, lengths, 2);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextStrokePath(context);
}



#pragma mark 显示坐标值

- (void)drawCoordvalueWithDic:(NSDictionary *)dic {

    //分时图
    if ([dic[@"isK"] floatValue] == 0) {
        
        NSString * max = dic[@"max"];//纵坐标最大值
        NSString * min = dic[@"min"];//纵坐标最小值
        NSString * close = dic[@"close"];//收盘价
        int kde = [dic[@"kde"] intValue];
        [self drawCoordValueWithMax:max Min:min Close:close kde:kde];
    }else {
        //K线图
        NSString * max = dic[@"max"];
        NSString * min = dic[@"min"];
        NSString * volMax = dic[@"volMax"];
        NSString * volMin = dic[@"volMin"];
        NSString *start = dic[@"start"];
        NSString *end = dic[@"end"];
        int kde = [dic[@"kde"] intValue];
        
        [self drawKcoordValueWithMax:max Min:min volMax:volMax volMin:volMin start:start end:end kde:kde];
        
    }
}



//画分时图坐标值（跟根据最大坐标，最小坐标，收盘价）
- (void)drawCoordValueWithMax:(NSString *)max Min:(NSString *)min Close:(NSString *)close kde:(int)kde{
    // 平均线
    
    CGFloat padValue = ([max floatValue] - [min floatValue]) / 6;
    CGFloat padRealValue = paddingHeight / 6;
    
    
    for (int i = 1; i<6; i++) {
        //左侧纵坐标
        CGFloat y = paddingHeight-padRealValue * i ;
        // lable
        
        NSString *text = [[NSString alloc]init];
        
        if (kde == 1) {
            text = [self changeFloat:[NSString stringWithFormat:@"%.1f",padValue*i+[min floatValue]]];
        }else if (kde == 2) {
            text = [self changeFloat:[NSString stringWithFormat:@"%.2f",padValue*i+[min floatValue]]];
            
        }else if (kde == 3) {
            text = [self changeFloat:[NSString stringWithFormat:@"%.3f",padValue*i+[min floatValue]]];
            
        }else if (kde == 4) {
            
            text = [self changeFloat:[NSString stringWithFormat:@"%.4f",padValue*i+[min floatValue]]];
        }else if(kde ==0) {
            
            text = [NSString stringWithFormat:@"%d",(int)roundf(padValue*i+[min floatValue])];
        }
        // NSString *text =[[NSString alloc] initWithFormat:@"%d",(int)roundf(padValue*i+min)];

        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        //        [text drawAtPoint:CGPointMake(paddingX, y + paddingY) withFont:[UIFont systemFontOfSize:10]]; //此方法在ios7后已废弃，用下面方法替代
        //从ios7开始，drawAtPoint:WithFont:等方法已经deprecated，取而代之应该使用drawAtPoint:WithAttributes方法，来设置字体的颜色和大小等
        //        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, [UIColor colorWithRed:114/255.0f green:128/255.0f blue:137/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil];
        
        CGRect leftContentrect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            leftContentrect = [text boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadAttrs context:nil];
        }else {
            
            leftContentrect = [text boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:Attrs context:nil];
        }
        
        
        if (isPad) {
            [text drawAtPoint:CGPointMake(paddingX, y + paddingY - leftContentrect.size.height / 2) withAttributes:PadAttrs];
        }else {
            [text drawAtPoint:CGPointMake(paddingX, y + paddingY - leftContentrect.size.height / 2) withAttributes:Attrs];
            
        }
        
        //右侧纵坐标(涨跌幅)
        CGFloat p = padValue*i+[min floatValue];
        CGFloat v = p - [close floatValue];
        CGFloat value = fabs(v);
        CGFloat incr = value / [close floatValue] * 100;
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        //        apply = [self changeFloat:apply];
        CGContextRef context1 = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context1, YES);
        CGContextSetRGBFillColor(context1, 10,10, 10, 1.0);
        
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            contentRect = [apply boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadAttrs context:nil];
        }else {
            contentRect = [apply boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:Attrs context:nil];
        }
        
        
        if (isPad) {
            [apply drawAtPoint:CGPointMake(paddingWidth - contentRect.size.width + paddingX, y + paddingY - contentRect.size.height / 2) withAttributes:PadAttrs];
        }else {
            [apply drawAtPoint:CGPointMake(paddingWidth - contentRect.size.width + paddingX, y + paddingY - contentRect.size.height / 2) withAttributes:Attrs];
        }
        
    }
    
    //最底下坐标的特殊处理
    
    //左侧纵坐标
    CGFloat y = paddingHeight;
    NSString *text =[[NSString alloc] initWithFormat:@"%@",min];
    //    text = [self changeFloat:text];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context, YES);
    CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
    
    if (isPad) {
        [text drawAtPoint:CGPointMake(paddingX , y + paddingY - 15) withAttributes:PadAttrs];
    }else {
        [text drawAtPoint:CGPointMake(paddingX, y + paddingY - 10) withAttributes:Attrs];
        
    }
    
    //右侧纵坐标
    CGFloat p = [min floatValue];
    CGFloat v = p - [close floatValue];
    CGFloat value = fabs(v);
    CGFloat incr = value / [close floatValue] * 100;
    
    
    
    NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
    //    apply = [self changeFloat:apply];
    CGContextRef context1 = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context1, YES);
    CGContextSetRGBFillColor(context1, 10,10, 10, 1.0);
    
    CGRect contentRect1 = CGRectMake(0, 0, 0, 0);
    if (isPad) {
        contentRect1 = [apply boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadAttrs context:nil];
    }else {
        contentRect1 = [apply boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:Attrs context:nil];
    }
    
    
    
    if (isPad) {
        [apply drawAtPoint:CGPointMake(paddingWidth - contentRect1.size.width + paddingX, y + paddingY - 15) withAttributes:PadAttrs];
    }else {
        [apply drawAtPoint:CGPointMake(paddingWidth - contentRect1.size.width + paddingX, y + paddingY - 10) withAttributes:Attrs];
        
    }
    
    
    //最上面的坐标处理
    
    //左侧纵坐标
    NSString *leftMaxtext =[[NSString alloc] initWithFormat:@"%@",max];
    //    text = [self changeFloat:text];
    
    
    if (isPad) {
        [leftMaxtext drawAtPoint:CGPointMake(paddingX , paddingY ) withAttributes:PadAttrs];
    }else {
        [leftMaxtext drawAtPoint:CGPointMake(paddingX,  paddingY) withAttributes:Attrs];
        
    }
    
    CGRect leftMaxRect = CGRectMake(0, 0, 0, 0);
    if (isPad) {
        leftMaxRect = [leftMaxtext boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        
    }else {
          leftMaxRect = [leftMaxtext boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
    }
    
    CGFloat leftMaxWidth = [[XLArchiverHelper getObject:@"leftMaxWidth"] floatValue];
    if (!leftMaxtext) {
        [XLArchiverHelper setObject:[NSString stringWithFormat:@"%f",leftMaxRect.size.width] forKey:@"leftMaxWidth"];
    }else {
        leftMaxWidth = leftMaxRect.size.width;
         [XLArchiverHelper setObject:[NSString stringWithFormat:@"%f",leftMaxWidth] forKey:@"leftMaxWidth"];
    }
    
    
    
    //右侧纵坐标
    CGFloat pMax = [max floatValue];
    CGFloat vMax = pMax - [close floatValue];
    CGFloat Maxvalue = fabs(vMax);
    CGFloat Maxincr = Maxvalue / [close floatValue] * 100;
    
    
    NSString *Maxapply = [NSString stringWithFormat:@"%.2f%%",Maxincr];
    //    apply = [self changeFloat:apply];
    
    CGRect MaxcontentRect = CGRectMake(0, 0, 0, 0);
    if (isPad) {
        MaxcontentRect = [Maxapply boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadAttrs context:nil];
    }else {
        MaxcontentRect = [Maxapply boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:Attrs context:nil];
    }
    if (isPad) {
        [Maxapply drawAtPoint:CGPointMake(paddingWidth - MaxcontentRect.size.width + paddingX, paddingY ) withAttributes:PadAttrs];
    }else {
        [Maxapply drawAtPoint:CGPointMake(paddingWidth - MaxcontentRect.size.width + paddingX,  paddingY) withAttributes:Attrs];
        
    }
}
#pragma mark -- 画K线坐标值
- (void)drawKcoordValueWithMax:(NSString *)max Min:(NSString *)min volMax:(NSString *)volMax volMin:(NSString *)volMin start:(NSString *)start end:(NSString *)end kde:(int)kde{
    //主图
    //横坐标
    CGContextRef context = UIGraphicsGetCurrentContext();
//  CGContextSetShouldAntialias(context, YES);
//  CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
    CGContextSetShouldAntialias(context, YES);
    CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
    CGRect contentRect = CGRectMake(0, 0, 0, 0);
    if (isPad) {
        [start drawAtPoint:CGPointMake(paddingX, paddingHeight + paddingY) withAttributes:PadLevelAttrs];
        contentRect = [end boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        [end drawAtPoint:CGPointMake(paddingWidth - contentRect.size.width + paddingX, paddingHeight + paddingY) withAttributes:PadLevelAttrs];
    }else {
        //绘制开始的时间
        [start drawAtPoint:CGPointMake(paddingX, paddingHeight + paddingY) withAttributes:LevelAttrs];
        contentRect = [end boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        //绘制结束的时间
        [end drawAtPoint:CGPointMake(paddingWidth - contentRect.size.width + paddingX, paddingHeight + paddingY) withAttributes:LevelAttrs];
    }
    // 纵坐标
    CGRect leftContentRect = CGRectMake(0, 0, 0, 0);
    CGFloat padValue = ([max floatValue] - [min floatValue]) / 4;
    CGFloat padRealValue = paddingHeight / 4;
    for (int i = 1; i<4; i++) {
        //左侧纵坐标
        CGFloat y = paddingY+ paddingHeight-padRealValue * i;
        // lable
        
        NSString *text = [[NSString alloc]init];
        
        if (kde == 1) {
            text =[self changeFloat:[[NSString alloc] initWithFormat:@"%.1f",padValue*i+[min floatValue]]];
        }else if (kde == 2) {
            text =[self changeFloat:[[NSString alloc] initWithFormat:@"%.2f",padValue*i+[min floatValue]]];
        }else if (kde == 3){
            text =[self changeFloat:[[NSString alloc] initWithFormat:@"%.3f",padValue*i+[min floatValue]]];
        }else if (kde == 4) {
            text =[self changeFloat:[[NSString alloc] initWithFormat:@"%.4f",padValue*i+[min floatValue]]];
        }else if(kde == 0){
            text =[[NSString alloc] initWithFormat:@"%d",(int)(padValue*i+[min floatValue])];
        }
        
        
        if (isPad) {
            
            leftContentRect = [text boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
            
        }else {
            leftContentRect = [text boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        
        if (isPad) {
            [text drawAtPoint:CGPointMake(paddingX, y - leftContentRect.size.height / 2) withAttributes:PadAttrs];
        }else {
            [text drawAtPoint:CGPointMake(paddingX, y - leftContentRect.size.height / 2) withAttributes:Attrs];
            
        }
        
    }
    
    //最底下坐标的特殊处理
    
    //左侧纵坐标
    CGFloat y = paddingHeight;
    
    NSString *volText = [[NSString alloc]init];
    
    if (kde == 1) {
        volText =[self changeFloat:[[NSString alloc] initWithFormat:@"%.1f",[min floatValue]]];
        
    }else if (kde == 2) {
        volText =[self changeFloat:[[NSString alloc] initWithFormat:@"%.2f",[min floatValue]]];
        
        
    }else if (kde == 3){
        volText =[self changeFloat:[[NSString alloc] initWithFormat:@"%.3f",[min floatValue]]];
        
    }else if (kde == 4) {
        volText =[self changeFloat:[[NSString alloc] initWithFormat:@"%.4f",[min floatValue]]];
        
    }else if(kde == 0) {
        
        volText =[[NSString alloc] initWithFormat:@"%d",[min intValue]];
    }
    if (isPad) {
        [volText drawAtPoint:CGPointMake(paddingX, y + paddingY - 15) withAttributes:PadAttrs];
    }else {
        [volText drawAtPoint:CGPointMake(paddingX, y + paddingY - 10) withAttributes:Attrs];
        
    }
    //最上面坐标的特殊处理
    NSString *MaxvolText = [[NSString alloc]init];
    if (kde == 1) {
        MaxvolText =[self changeFloat:[[NSString alloc] initWithFormat:@"%.1f",[max floatValue]]];
        
    }else if (kde == 2) {
        MaxvolText =[self changeFloat:[[NSString alloc] initWithFormat:@"%.2f",[max floatValue]]];
        
        
    }else if (kde == 3){
        MaxvolText =[self changeFloat:[[NSString alloc] initWithFormat:@"%.3f",[max floatValue]]];
        
    }else if (kde == 4) {
        MaxvolText =[self changeFloat:[[NSString alloc] initWithFormat:@"%.4f",[max floatValue]]];
        
    }else if(kde == 0) {
        
        MaxvolText =[[NSString alloc] initWithFormat:@"%d",[max intValue]];
    }
    
    
    if (isPad) {
        [MaxvolText drawAtPoint:CGPointMake(paddingX,  paddingY) withAttributes:PadAttrs];
    }else {
        [MaxvolText drawAtPoint:CGPointMake(paddingX,  paddingY) withAttributes:Attrs];
        
    }
    
    CGRect maxRectWidth = CGRectMake(0, 0, 0, 0);
    if (isPad) {
        maxRectWidth = [MaxvolText boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        
    }else {
        maxRectWidth = [MaxvolText boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        
    }
    
    CGFloat maxWidth = [[XLArchiverHelper getObject:@"maxWidth"] floatValue];
    if (!maxWidth) {
        [XLArchiverHelper setObject:[NSString stringWithFormat:@"%f",maxRectWidth.size.width] forKey:@"maxWidth"];
    }else {
        maxWidth = maxRectWidth.size.width;
        [XLArchiverHelper setObject:[NSString stringWithFormat:@"%f",maxWidth] forKey:@"maxWidth"];
    }
    
    
    //副图
    
    //BIAS  KDJ  RSI  WR指标的坐标系
    if ([volMax floatValue] == 100) {
        
        //左侧纵坐标
        NSString *textMax =[[NSString alloc] initWithFormat:@"100"];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        
        NSString *textMid =[[NSString alloc] initWithFormat:@"50"];
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            contentRect =  [textMid boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
            
            [textMax drawAtPoint:CGPointMake(bottomX, bottomY) withAttributes:PadAttrs];
            [textMid drawAtPoint:CGPointMake(bottomX, bottomY + bottomHeight / 2 - contentRect.size.height / 2) withAttributes:PadAttrs];
        }else {
            contentRect =  [textMid boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
            
            [textMax drawAtPoint:CGPointMake(bottomX, bottomY) withAttributes:Attrs];
            [textMid drawAtPoint:CGPointMake(bottomX, bottomY + bottomHeight / 2 - contentRect.size.height / 2) withAttributes:Attrs];
            
        }
        
        CGRect textMaxRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            textMaxRect =  [textMax boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
        
            textMaxRect =  [textMax boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        CGFloat volMaxWidth = [[XLArchiverHelper getObject:@"volMaxWidth"] floatValue];
        if (!volMaxWidth) {
            [XLArchiverHelper setObject:[NSString stringWithFormat:@"%f",textMaxRect.size.width] forKey:@"volMaxWidth"];
        }else {
        
            volMaxWidth = textMaxRect.size.width;
            [XLArchiverHelper setObject:[NSString stringWithFormat:@"%f",volMaxWidth] forKey:@"volMaxWidth"];
        }
        
        //最底下坐标的特殊处理
        NSString *textLow =[[NSString alloc] initWithFormat:@"0"];
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        if (isPad) {
            [textLow drawAtPoint:CGPointMake(bottomX, bottomY + bottomHeight - 15) withAttributes:PadAttrs];
        }else {
            [textLow drawAtPoint:CGPointMake(bottomX, bottomY + bottomHeight - 10) withAttributes:Attrs];
        }
    }else {
        
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        if (isPad) {
            [volMax drawAtPoint:CGPointMake(bottomX, bottomY) withAttributes:PadAttrs];
        }else {
            [volMax drawAtPoint:CGPointMake(bottomX, bottomY) withAttributes:Attrs];
        }
        
        
        CGRect textMaxRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            textMaxRect =  [volMax boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            
            textMaxRect =  [volMax boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        CGFloat volMaxWidth = [[XLArchiverHelper getObject:@"volMaxWidth"] floatValue];
        if (!volMaxWidth) {
            [XLArchiverHelper setObject:[NSString stringWithFormat:@"%f",textMaxRect.size.width] forKey:@"volMaxWidth"];
        }else {
            
            volMaxWidth = textMaxRect.size.width;
            [XLArchiverHelper setObject:[NSString stringWithFormat:@"%f",volMaxWidth] forKey:@"volMaxWidth"];
        }

        
        
        
        //最底下坐标的特殊处理
        
        //左侧纵坐标
        CGFloat yy = bottomHeight + bottomY;
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        if (isPad) {
            [volMin drawAtPoint:CGPointMake(bottomX, yy - 15) withAttributes:PadAttrs];
        }else {
            [volMin drawAtPoint:CGPointMake(bottomX, yy - 10) withAttributes:Attrs];
            
        }
        
    }
    
}




#pragma mark  小数点只舍不入
//处理小数，只舍不入方法
-(NSString *)notRounding:(float)price afterPoint:(int)position{
    NSDecimalNumberHandler* roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown scale:position raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    NSDecimalNumber *ouncesDecimal;
    NSDecimalNumber *roundedOunces;
    
    ouncesDecimal = [[NSDecimalNumber alloc] initWithFloat:price];
    roundedOunces = [ouncesDecimal decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
    
    return [NSString stringWithFormat:@"%@",roundedOunces];
}


#pragma mark 小数点只入不舍
//处理小数，只入不舍
-(NSString *)notRoundingWith:(float)price afterPoint:(int)position{
    NSDecimalNumberHandler* roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundUp scale:position raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    NSDecimalNumber *ouncesDecimal;
    NSDecimalNumber *roundedOunces;
    
    ouncesDecimal = [[NSDecimalNumber alloc] initWithFloat:price];
    roundedOunces = [ouncesDecimal decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
    
    return [NSString stringWithFormat:@"%@",roundedOunces];
}


//取出float类型无效的0
-(NSString *)changeFloat:(NSString *)stringFloat
{
    const char *floatChars = [stringFloat UTF8String];
    NSUInteger length = [stringFloat length];
    NSUInteger zeroLength = 0;
    int i = (int)length-1;
    for(; i>=0; i--)
    {
        if(floatChars[i] == '0'/*0x30*/) {
            zeroLength++;
        } else {
            if(floatChars[i] == '.')
                i--;
            break;
        }
    }
    NSString *returnString;
    if(i == -1) {
        returnString = @"0";
    } else {
        returnString = [stringFloat substringToIndex:i+1];
    }
    return returnString;
}

@end
