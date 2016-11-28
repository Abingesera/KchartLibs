//
//  RunChartView.m
//  RunChartAndKchart
//
//  Created by zsgjs on 15/12/16.
//  Copyright (c) 2015年 zsgjs. All rights reserved.
//

#import "RunChartView.h"
#import "Config.h"

/*
 参数类型：
 sections:{
           secs =     (
                        (
                          0,
                          0,
                          370,
                          400
                        )
                     );
           type = 1;
           kde = @"2";
         }

 secs字段:字段中数组个数分时图为1，K线图为2，传给父类绘制坐标系
 type字段:父类用来判断分时图类型，绘制不同的分时图坐标系
 kde字段：需要保留的小数点位数
 
 sectionDic:{
             close = "2969.000000";
             isK = 0;
             max = "0.000000";
             min = "0.000000";
             kde = "2";
            }
 
   close字段:收盘价
   isK字段:是否K线图
   max字段:分时图最大坐标值
   min字段:分时图最小坐标值
   kde字段：需要保留的小数点位数
 */


/*
 整体逻辑：
1. 在初始化方法里封装好分时图的坐标系信息(包括坐标系的X、Y坐标和宽高)，声明好需要显示指标数据的控件
2. 画图方法里， 首先根据1中封装好的坐标系信息，调用父类中的方法完成对坐标系的绘制
              然后对外界传过来的数据进行处理计算，计算出需要显示的坐标值里面的最大值、最小值、以及收盘价，再把这些数据封装起来
              然后根据上步封装好的坐标值信息，调用父类中的方法，完成对坐标值的绘制
              然后开始画价格线和均价线。根据外界传过来的type字段判断为几日分时图，以一日为例，先根据接口的价格数据计算出均价，封装成数组，然后把价格和均价值换算成实际的点坐标，横坐标是根据时间来定，纵坐标根据最大最小坐标值及纵轴的距离来定。在处理数据的过程中，定义一个数组A来记录下每个价格值所对应的点坐标，及所对应的均价值，以便在长按十字星显示历史信息中用。根据处理好的价格坐标数组和均价坐标数组，调用画折线方法来绘制价格线和均价线。并显示横坐标。一日的显示该商品的开始交易时间和结束交易时间，可以通过外部的接口获得，通过属性传值过来，多日分时横坐标显示的是交易日期，
3. 添加长按手势。设置1s时间。长按时显示十字星，并显示历史信息。可以遍历上步封装好的A数组，找到存储的点坐标的横坐标，跟手势点的横坐标做比较，如果间距在一定范围内，就取出此元素，包括该点坐标，该点位置的价格，该点位置的均价，然后显示。同时通过代理将这些数据传递给外界
4. 最后显示价格和均价值。如果没有进行任何手势操作，默认显示的是最新一条的价格和均价。我们可以取出数组A的最后一个元素，获得该点的价格和均价然后显示。当有手势操作时，根据上步取出的对应元素，对价格和均价做相应的显示改动。
 */


@interface RunChartView ()
{

    NSMutableDictionary *sections;//坐标系信息
    NSMutableDictionary *sectionDic;//坐标值信息
    NSArray             *aveArr;//存放均价数组
    NSMutableArray      *pointArray; // 分时图所有坐标数组  ,十字星定位用
    CGFloat              maxValue;//纵坐标最大值
    CGFloat              minValue;//纵坐标最小值
    CGPoint              touchViewPoint;//长按手势点
    UIView              *movelineone; // 手指按下后显示的两根白色十字线 竖线
    UIView              *movelinetwo; //手指按下后显示的两根白色十字线 横线
    UILabel             *priceLabel;//显示价格控件
    UILabel             *avePriceLabel;//显示均价控件
    CGFloat             paddingX;//分时图X坐标
    CGFloat             paddingY;//分时图Y坐标
    
}

@end

@implementation RunChartView


-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    self.backgroundColor = [UIColor clearColor]; //不设置背景色，刷新重绘时图像会重叠
    sections = [[NSMutableDictionary alloc]init];
    sectionDic = [[NSMutableDictionary alloc]init];
    aveArr = [[NSArray alloc]init];
    self.data = [[NSMutableArray alloc]init];
    self.category = [[NSMutableArray alloc]init];
    self.type = @"1";//默认1日分时
    
    NSString *width = [NSString stringWithFormat:@"%f",frame.size.width - 20];
    NSString *height = [NSString stringWithFormat:@"%f",frame.size.height - 20];
    NSArray *arr = @[@"10",@"5",width,height];//分时图frame
    paddingX = [arr[0] floatValue];
    paddingY = [arr[1] floatValue];
    self.xWidth = [arr[2] floatValue];
    self.yHeight = [arr[3] floatValue];
    NSMutableArray *array = [[NSMutableArray alloc]init];
    [array addObject:arr];
    [sections setObject:array forKey:@"secs"];
    
    
    _closePrice = @"3002";//昨收价
    _kde = @"2";//默认两位
    
    //价格，均价显示控件
    
    avePriceLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    if (isPad) {
        //        avePriceLabel.frame = CGRectMake(priceLabel.frame.origin.x + priceLabel.frame.size.width + 20, paddingY, 80, 20);
        avePriceLabel.frame = CGRectMake(paddingX + 80, paddingY, 80, 10);
    }else {
        //        avePriceLabel.frame = CGRectMake(priceLabel.frame.origin.x + priceLabel.frame.size.width + 10, paddingY, 60, 20);
        avePriceLabel.frame = CGRectMake(paddingX + 50, paddingY, 60, 10);
    }
    
    avePriceLabel.backgroundColor = [UIColor clearColor];
    avePriceLabel.font = [UIFont systemFontOfSize:9];
    if (isPad) {
        avePriceLabel.font = [UIFont systemFontOfSize:15];
    }
    avePriceLabel.adjustsFontSizeToFitWidth = YES;
    avePriceLabel.textColor = [@"#788C0E" hexStringToColor];
    [self addSubview:avePriceLabel];
    
    return self;
}



- (void)drawRect:(CGRect)rect {

    self.backgroundColor = [UIColor clearColor]; //不设置背景色，刷新重绘时图像会重叠
    
    [sections setObject:self.type forKey:@"type"];//封装坐标系信息
    
    //画坐标系
    [self drawSectionsWithDic:sections];
    
    //获得最大最小坐标值
    [self getMaxAndMinValue];
//    //显示坐标值
//    [self drawCoordvalueWithDic:sectionDic];
    
    //画价格线和均价线
    [self drawRunchartlineWithType:self.type];
    
    //添加长按手势
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
    [longPressGestureRecognizer addTarget:self action:@selector(gesturelongPressRecognizeHandle:)];
    [longPressGestureRecognizer setMinimumPressDuration:0.5f];
    [self addGestureRecognizer:longPressGestureRecognizer];
    
    
    //显示坐标值
    [self drawCoordvalueWithDic:sectionDic];
    
    //显示价格和均价
    [self drawPriceLineAndAver];
}


#pragma mark 获得最大最小坐标值
//获得最大最小坐标值
/*
 •	如果当日（最高价-昨收价）绝对值大于（最低价-昨收价）绝对值，则纵坐标最高价则为当日最高价，纵坐标最高价与昨收价之间进行坐标均分；此时【昨收价-（最高价-昨收价）绝对值】为纵坐标最低价；纵坐标最低价与昨日价之间进行坐标均分；同时右侧涨跌幅也与左侧价格对应表示；
 •	如果当日（最高价-昨收价）绝对值小于（最低价-昨收价）绝对值，则纵坐标最低价则为当日最低价，纵坐标最低价与昨收价之间进行坐标均分；此时【昨收价+（最低价-昨收价）绝对值】为纵坐标最高价；纵坐标最高价与昨收价之间进行坐标均分；同时右侧涨跌幅也与左侧价格对应表示；
 */

- (void)getMaxAndMinValue {
    
    if (self.data.count > 0) {
        maxValue = [[[self.data objectAtIndex:0] objectAtIndex:1] floatValue];//先取第一个数据作为基准
        minValue = [[[self.data objectAtIndex:0] objectAtIndex:1] floatValue];
        
        for (NSArray *arr in self.data) {
            maxValue = fmax([[arr objectAtIndex:1] floatValue], maxValue);
            minValue = fmin([[arr objectAtIndex:1] floatValue], minValue);
        }
        
        CGFloat Poorvalue = maxValue - [_closePrice floatValue];
        CGFloat maxabsoluteValue = fabs(Poorvalue);     //取绝对值
        
        CGFloat ReductionValue = minValue - [_closePrice floatValue];
        CGFloat minabsoluteValue = fabs(ReductionValue);
        
        if (maxabsoluteValue > minabsoluteValue) {
            minValue = [_closePrice floatValue] - maxabsoluteValue;
        }else {
            
            maxValue = [_closePrice floatValue] + minabsoluteValue;
        }
    }
    
    //封装坐标值信息，传给父类绘制坐标值
    [sectionDic setObject:@"0" forKey:@"isK"];
    
    
    //判断几位小数,根据收盘价价格位数确定坐标值的小数位数
    
    
    if ([self.kde integerValue] == 1) {
        
        [sectionDic setObject:[NSString stringWithFormat:@"%.1f",maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.1f",minValue] forKey:@"min"];
        
    }else if ([self.kde integerValue] == 2) {
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",minValue] forKey:@"min"];
        
    }else if ([self.kde integerValue] == 3){
        [sectionDic setObject:[NSString stringWithFormat:@"%.3f",maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.3f",minValue] forKey:@"min"];
        
    }else if ([self.kde integerValue] == 4) {
        [sectionDic setObject:[NSString stringWithFormat:@"%.4f",maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.4f",minValue] forKey:@"min"];
        
    }else if ([self.kde integerValue] == 0){
        [sectionDic setObject:[NSString stringWithFormat:@"%d",(int)maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%d",(int)minValue] forKey:@"min"];
        
    }
    
    //    [sectionDic setObject:[self notRoundingWith:maxValue afterPoint:0] forKey:@"max"];//最大值小数点只入不舍
    //    [sectionDic setObject:[self notRounding:minValue afterPoint:0] forKey:@"min"];//最小值小数点只舍不入
    
    [sectionDic setObject:[NSString stringWithFormat:@"%@",_closePrice] forKey:@"close"];
    [sectionDic setObject:self.kde forKey:@"kde"];
}


#pragma mark 画线，一日，两日，三日，四日分时图
- (void)drawRunchartlineWithType:(NSString *)type {
    
    if ([type intValue] == 1) {
        //处理数据，获取均价数组
        aveArr = [self handledataWithArr:self.data];
        //画线
        [self drawPriceLine];
        
    }else if ([type intValue] == 2) {
        [self drawTwodaysWithArr:self.data];
        
    }else if ([type intValue] == 3) {
        [self drawThreedaysWithArr:self.data];
        
    }else if ([type intValue] == 4) {
        [self drawFourdaysWithArr:self.data];
    }
}


#pragma mark 处理一日分时的数据，获取均价数组
//处理数据
- (NSArray *)handledataWithArr:(NSArray *)arr {
    
    NSMutableArray *Array = [[NSMutableArray alloc]init];
    CGFloat value = 0;
    
    for (int i = 0;  i < arr.count; i++) {
        NSMutableArray *tempArr = [[NSMutableArray alloc]init];
        
        NSArray *Arr = arr[i];
        
        CGFloat timeValue = [self handleDateWithString:Arr[0]];
        
        
        if (timeValue < [self.beginTime floatValue] + 2400 && (timeValue  > [self.endTime floatValue])) {
            continue;
        }
        
        value += [[Arr objectAtIndex:1] floatValue];
        
        float averValue = value / (i + 1);
        [tempArr addObject:Arr[0]];
        [tempArr addObject:[NSString stringWithFormat:@"%f",averValue]];
        
        [Array addObject:tempArr];
    }
    return Array;
}



#pragma mark 画一日的价格和均价线
//画线
- (void)drawPriceLine {
    //画价格线，橙色
    NSArray *tempArray = [self changePointWithData:self.data andMA:1]; // 把价格换算成实际坐标数组，并生成Pointarray（十字星用）
    [self drawlineWithArr:tempArray color:0 sec:1];
    
    //画均价线，黄色
    NSArray *temp = [self changePointWithData:aveArr type:1];//把均价换算成坐标
    [self drawlineWithArr:temp color:1 sec:1];
    
    //显示横坐标时间
    //开始时间
    if (self.beginTime.length > 0) {
        NSString *str = [self handleTimeWithString:self.beginTime];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        if (isPad) {
            [str drawAtPoint:CGPointMake(paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        }else {
            [str drawAtPoint:CGPointMake(paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
            
        }
        
        
        //中间坐标值
        //        CGFloat aveValue = ([self.endTime integerValue] - [self.beginTime integerValue]) / 4;
        //        for (int i = 1; i < 4; i++) {
        //
        //            NSString *time = [NSString stringWithFormat:@"%d",(int)([self.beginTime integerValue] + aveValue * i)];
        //            int num = (int)([time integerValue] / 100);
        //            time = [NSString stringWithFormat:@"%d",num * 100];
        //
        //            NSString *text = [self handleTimeWithString:time];
        //            CGRect contentRect = CGRectMake(0, 0, 0, 0);
        //            if (isPad) {
        //                contentRect = [text boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        //            }else {
        //                contentRect = [text boundingRectWithSize:CGSizeMake(80, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        //            }
        //
        //            CGContextSetShouldAntialias(context, YES);
        //            CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        //            if (isPad) {
        //                [text drawAtPoint:CGPointMake(self.xWidth / 4 * i - contentRect.size.width / 2 + paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        //
        //            }else {
        //                [text drawAtPoint:CGPointMake(self.xWidth / 4 * i - contentRect.size.width / 2 + paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
        //
        //
        //            }
        //
        //
        //        }
        
        NSLog(@"%@",self.endTime);
        //结束时间
        NSString *text =[self handleTimeWithString:self.endTime];
        
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        
        if (isPad) {
            contentRect = [text boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            contentRect = [text boundingRectWithSize:CGSizeMake(80, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        if (isPad) {
            [text drawAtPoint:CGPointMake(self.xWidth - contentRect.size.width + paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
            
        }else {
            [text drawAtPoint:CGPointMake(self.xWidth - contentRect.size.width + paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
            
            
        }
    }
}

#pragma mark 处理日期和时间
//处理日期和时间
/*
 2015-12-29 07:15    ---- 715
 */
- (CGFloat )handleDateWithString:(NSString *)str {
    
    NSMutableString *newString = [NSMutableString stringWithString:[str substringFromIndex:11]];
    NSMutableString *string = [NSMutableString string];
    
    [string appendString:[newString substringWithRange:NSMakeRange(0,2)]];
    [string appendString:[newString substringWithRange:NSMakeRange(3,2)]];
    
    
    if ([string floatValue] < [self.beginTime floatValue]) {
        string = [NSMutableString stringWithFormat:@"%f",[string floatValue] + 2400];
    }
    
    return [string floatValue];
}



#pragma mark 把行情数据转化为实际的点坐标数组

//处理价格数组,将价格转化为点坐标
-(NSArray*)changePointWithData:(NSArray*)data andMA:(int)MAIndex{
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    NSMutableArray *temp = [[NSMutableArray alloc]init];
//    for (int i = 0; i < data.count; i++) {
    for(int i = 0; i < aveArr.count; i++){
        NSArray *item = data[i];
        CGFloat currentValue = [[item objectAtIndex:MAIndex] floatValue];// 得到价格
        CGFloat currentTime = [self handleDateWithString:[item objectAtIndex:0]]; //得到时间
        // 换算成实际的坐标
        
        if (currentTime < [self.beginTime floatValue] + 2400 && (currentTime  > [self.endTime floatValue])) {
            continue;
        }
        
        CGFloat currentPointY = self.yHeight - ((currentValue - minValue) / (maxValue - minValue) * self.yHeight) + paddingY;
        
        //如果最高价等于最低价，至于中
        if (maxValue == minValue) {
            currentPointY = paddingY + self.yHeight / 2;
        }
        
        
//        CGFloat currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth + paddingX;
        
        CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
        CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
        CGFloat currentPointX = current / total * self.xWidth + paddingX;
        
        CGPoint currentPoint =  CGPointMake(currentPointX, currentPointY); // 换算到当前的坐标值
        [temp addObject:NSStringFromCGPoint(currentPoint)]; // 把坐标添加进新数组
        
        //计算涨跌幅
        
        CGFloat value = currentValue - [_closePrice floatValue];
        
        //        CGFloat absoValue = fabs(value);
        //        CGFloat incr = absoValue / [_closePrice floatValue] * 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        
        NSString *applyValue = [NSString stringWithFormat:@"%.2f%%",incr];
        
        // 实际坐标组装为数组
        NSArray *currentArray = [[NSArray alloc] initWithObjects:
                                 NSStringFromCGPoint(currentPoint),//坐标
                                 [self.category objectAtIndex:i], // 保存日期时间
                                 [item objectAtIndex:MAIndex],//价格
                                 [aveArr objectAtIndex:i], // 均价值
                                 applyValue,//涨跌幅
                                 nil];
        
        [tempArray addObject:currentArray]; // 把坐标添加进新数组
        
        currentArray = nil;
        
    }
    
    pointArray = tempArray;
    return temp;
    
}


//处理均价数组,将均价转化成点坐标
- (NSArray *)changePointWithData:(NSArray *)data type:(int)type{

    NSMutableArray *temp = [[NSMutableArray alloc]init];
    for (int i = 0; i < data.count; i++) {
        
        NSArray *item = data[i];
        float currentValue = [item[1] floatValue];// 得到均价价格
        CGFloat currentTime = [self handleDateWithString:[item objectAtIndex:0]]; //得到时间
        CGFloat currentPointX = 0.0f;
        
        if (currentTime < [self.beginTime floatValue] + 2400 && (currentTime  > [self.endTime floatValue])) {
            continue;
        }
        
        
        // 换算成实际的坐标
        CGFloat currentPointY = self.yHeight - ((currentValue - minValue) / (maxValue - minValue) * self.yHeight) + paddingY;
        
        //如果最高价等于最低价，置于中
        if (maxValue == minValue) {
            currentPointY = paddingY + self.yHeight / 2;
        }
        
        
        if (type == 1) {
            
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth + paddingX;
        }else if(type == 2) {
            
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth / 2 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 2 + paddingX;
        }else if (type == 3){
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth / 2 + self.xWidth / 2 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 2 + self.xWidth / 2 + paddingX;
            
        }else if (type == 4) {
            
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth / 3 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 3 + paddingX;
        }else if (type == 5) {
            
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth / 3 + self.xWidth / 3 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 3 + self.xWidth / 3 + paddingX;
        }else if (type == 6) {
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth / 3 + self.xWidth * 2 / 3 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 3 + 2 * self.xWidth / 3 + paddingX;
        }else if (type == 7){
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth / 4 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 4 + paddingX;
        }else if (type == 8){
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth / 4 + self.xWidth / 4 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 4 + self.xWidth / 4 + paddingX;
            
        }else if (type == 9){
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth / 4 + self.xWidth * 2 / 4 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 4 + 2 * self.xWidth / 4 + paddingX;
        }else if (type == 10) {
            CGFloat current = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%f",(currentTime - [self.beginTime intValue])]];
            CGFloat total = [self changeNumForMinutesWithIdx:[NSString stringWithFormat:@"%d",([self.endTime intValue] - [self.beginTime intValue])]];
            currentPointX = current / total * self.xWidth  / 4 + self.xWidth * 3 / 4 + paddingX;

//            currentPointX = ((currentTime - [self.beginTime intValue]) / ([self.endTime intValue] - [self.beginTime intValue])) * self.xWidth / 4 + 3 * self.xWidth / 4 + paddingX;
        }
        
        
        CGPoint currentPoint =  CGPointMake(currentPointX, currentPointY); // 换算到当前的坐标值
        
        [temp addObject:NSStringFromCGPoint(currentPoint)];
    }
    return temp;
}


#pragma mark 长按手势方法

//长按就开始生成十字线
-(void)gesturelongPressRecognizeHandle:(UILongPressGestureRecognizer*)longResture{
    
    if (pointArray.count == 0) {
        return;
    }
    
    touchViewPoint = [longResture locationInView:self];
    // 手指长按开始时
    if(longResture.state == UIGestureRecognizerStateBegan){
        [self updateNib];
    }
    // 手指移动时候开始显示十字线
    if (longResture.state == UIGestureRecognizerStateChanged) {
        [self isRunPointWithPoint:touchViewPoint];//显示历史信息
    }
    
    // 手指离开的时候移除十字线
    if (longResture.state == UIGestureRecognizerStateEnded) {
        [movelineone removeFromSuperview];
        [movelinetwo removeFromSuperview];
        
        movelineone = nil;
        movelinetwo = nil;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cancelShow)]) {
            [self.delegate cancelShow];//取消显示历史信息
        }
        
    }
}


//更新界面信息
-(void)updateNib{
    if (movelineone==Nil) {
        movelineone = [[UIView alloc] initWithFrame:CGRectMake(0,paddingY, 0.5,
                                                               self.yHeight)];
        movelineone.backgroundColor = [@"c9c9c9" hexStringToColor];
        [self addSubview:movelineone];
        movelineone.hidden = YES;
    }
    if (movelinetwo==Nil) {
        movelinetwo = [[UIView alloc] initWithFrame:CGRectMake(paddingX,0, self.xWidth,0.5)];
        movelinetwo.backgroundColor = [@"c9c9c9" hexStringToColor];
        movelinetwo.hidden = YES;
        [self addSubview:movelinetwo];
    }
    
    
    movelineone.frame = CGRectMake(touchViewPoint.x,paddingY, 0.5,self.yHeight);
    movelinetwo.frame = CGRectMake(paddingX,touchViewPoint.y, self.xWidth,0.5);
    
   
    if ([systemVersionString floatValue] >= 9.0) {
        movelineone.frame = CGRectMake(touchViewPoint.x,paddingY, 0.5,self.yHeight);
        movelinetwo.frame = CGRectMake(paddingX,touchViewPoint.y, self.xWidth,0.5);
    }
    
    movelineone.hidden = NO;
    movelinetwo.hidden = NO;
    
    [self isRunPointWithPoint:touchViewPoint];
}


#pragma mark  十字星显示方法
//十字线上显示提示信息
-(void)isRunPointWithPoint:(CGPoint)point{
    
    if (pointArray.count == 0) {
        return;
    }
    
    CGPoint firstPoint = CGPointFromString([pointArray[0] objectAtIndex:0]);
    CGFloat value = fabs(firstPoint.x - point.x);
    int idx = 0;
    
    for (int i = 0; i < pointArray.count; i++) {
        NSArray *item = pointArray[i];
        CGPoint itemPoint = CGPointFromString([item objectAtIndex:0]);
        
        if (fabs(itemPoint.x - point.x) < value) {
            value = fabs(itemPoint.x - point.x);
            idx = i;
        }
        
    }
    
    NSArray *item = pointArray[idx];
    CGPoint itemPoint = CGPointFromString([item objectAtIndex:0]);
    CGFloat itemPointX = itemPoint.x;
    
    //竖线
    movelineone.frame = CGRectMake(itemPointX,movelineone.frame.origin.y, movelineone.frame.size.width,  self.yHeight);
    //横线
    movelinetwo.frame = CGRectMake(movelinetwo.frame.origin.x,itemPoint.y,movelinetwo.frame.size.width, movelinetwo.frame.size.height);
    
    // 价格 均价值更新
    //            priceLabel.text = [[NSString alloc] initWithFormat:@"价格: %@",[item objectAtIndex:2]];
    
    if ([self.type intValue] == 1) {
        
        
        if ([self.kde integerValue] == 1) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价: %.1f", [[[item objectAtIndex:3] objectAtIndex:1] floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %.1f", [[[item objectAtIndex:3] objectAtIndex:1] floatValue]];
            
        }else if ([self.kde integerValue] == 2) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价: %.2f", [[[item objectAtIndex:3] objectAtIndex:1] floatValue]]];
             avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %.2f", [[[item objectAtIndex:3] objectAtIndex:1] floatValue]];
            
        }else if ([self.kde integerValue] == 3) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价: %.3f", [[[item objectAtIndex:3] objectAtIndex:1] floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %.3f", [[[item objectAtIndex:3] objectAtIndex:1] floatValue]];
            
        }else if ([self.kde integerValue] == 4) {
            
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价: %.4f", [[[item objectAtIndex:3] objectAtIndex:1] floatValue]]];
             avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %.4f", [[[item objectAtIndex:3] objectAtIndex:1] floatValue]];
        }else if ([self.kde integerValue] == 0){
            
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %ld", lroundf([[[item objectAtIndex:3] objectAtIndex:1] floatValue])];
        }
        
    }else {
        
        if ([self.kde integerValue] == 1) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价: %.1f", [[item objectAtIndex:3] floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %.1f", [[item objectAtIndex:3] floatValue]];
            
        }else if ([self.kde integerValue] == 2) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价: %.2f", [[item objectAtIndex:3] floatValue]]];
             avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %.2f", [[item objectAtIndex:3] floatValue]];
            
        }else if ([self.kde integerValue]== 3) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价: %.3f", [[item objectAtIndex:3] floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %.3f", [[item objectAtIndex:3] floatValue]];
            
        }else if ([self.kde integerValue] == 4) {
            
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价: %.4f", [[item objectAtIndex:3] floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %.4f", [[item objectAtIndex:3] floatValue]];
        }else if ([self.kde integerValue] == 0) {
            
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价: %ld", lroundf([[item objectAtIndex:3] floatValue])];
        }
        
    }
    
    
    
    //代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(showHistoryWithArr:)]) {
        [self.delegate showHistoryWithArr:item];
    }
    
}


#pragma mark 显示价格和均价

//显示价格和均价
- (void)drawPriceLineAndAver {
    
    // priceLabel 价格显示控件
    //    priceLabel.text = [[NSString alloc] initWithFormat:@"价格: %@",[[pointArray lastObject] objectAtIndex:2]];
    
    if (self.data.count == 0) {
        return;
    }else {
        
        CGFloat leftMaxWidth = [[XLArchiverHelper getObject:@"leftMaxWidth"] floatValue];
        if (!leftMaxWidth) {
            return;
        }else {
            if (isPad) {
                avePriceLabel.frame = CGRectMake(paddingX + leftMaxWidth + 5, paddingY + 1, 80, 10);
            }else{
                avePriceLabel.frame = CGRectMake(paddingX + leftMaxWidth + 5, paddingY + 1, 60, 10);
                
            }
            
        }
    }
    
    if ([self.type intValue] == 1) {
        NSArray *averAr = [[pointArray lastObject] objectAtIndex:3];
        NSString *avePrice = [averAr objectAtIndex:1];
        
        
        
        if ([self.kde integerValue] == 1) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价:%.1f", [avePrice floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%.1f", [avePrice floatValue]];
            
        }else if ([self.kde integerValue] == 2) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价:%.2f", [avePrice floatValue]]];
             avePriceLabel.text =[[NSString alloc] initWithFormat:@"均价:%.2f", [avePrice floatValue]];
            
        }else if ([self.kde integerValue] == 3) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价:%.3f", [avePrice floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%.3f", [avePrice floatValue]];
            
        }else if ([self.kde integerValue] == 4) {
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%.4f", [avePrice floatValue]];
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价:%.4f", [avePrice floatValue]]];
        }else if ([self.kde integerValue] == 0){
            
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%ld", lroundf([avePrice floatValue])];
        }
        
    }else  {
        
        
        if ([self.kde integerValue] == 1) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价:%.1f", [[[pointArray lastObject] objectAtIndex:3] floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%.1f", [[[pointArray lastObject] objectAtIndex:3] floatValue]];
            
        }else if ([self.kde integerValue] == 2) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价:%.2f", [[[pointArray lastObject] objectAtIndex:3] floatValue]]];
             avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%.2f", [[[pointArray lastObject] objectAtIndex:3] floatValue]];
            
        }else if ([self.kde integerValue] == 3) {
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价:%.3f", [[[pointArray lastObject] objectAtIndex:3] floatValue]]];
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%.3f", [[[pointArray lastObject] objectAtIndex:3] floatValue]];
            
        }else if ([self.kde integerValue] == 4) {
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%.4f", [[[pointArray lastObject] objectAtIndex:3] floatValue]];
//            avePriceLabel.text = [self changeFloat:[[NSString alloc] initWithFormat:@"均价:%.4f", [[[pointArray lastObject] objectAtIndex:3] floatValue]]];
        }else if ([self.kde integerValue] == 0) {
            
            avePriceLabel.text = [[NSString alloc] initWithFormat:@"均价:%d", [[[pointArray lastObject] objectAtIndex:3] intValue]];
        }
        
    }
    
}




//处理时间
/*
 600 --- 6:00
 */
- (NSString *)handleTimeWithString:(NSString *)str {
    NSMutableString *newStr = [NSMutableString stringWithString:str];
    if (str.length < 4) {
        if (str.length < 3) {
            newStr = [NSMutableString stringWithString:@"00:00"];
        }
        [newStr insertString:@":" atIndex:1];
        
    }else {
        if ([newStr intValue] <= 2400) {
            [newStr insertString:@":" atIndex:2];
        }else {
            newStr = [NSMutableString stringWithFormat:@"%d",[newStr intValue] - 2400];
            if (newStr.length < 4) {
                if (newStr.length < 3) {
                    newStr = [NSMutableString stringWithString:@"00:00"];
                }else{
                    [newStr insertString:@":" atIndex:1];
                }
            }else {
                [newStr insertString:@":" atIndex:2];
                
            }
            
        }
        
    }
    if ([newStr floatValue] == 0) {
        newStr = [NSMutableString stringWithFormat:@"0:00"];
    }
    return newStr;
    
}


#pragma mark 处理两日数据，并画线
//处理两日数据并画线
- (void)drawTwodaysWithArr:(NSArray *)arr {
    
    NSMutableArray *BeforeArr = [[NSMutableArray alloc]init];
    NSMutableArray *LastArr = [[NSMutableArray alloc]init];
    
    NSString *str = [[arr firstObject] objectAtIndex:2];//上一个交易日的交易日期
    for (NSArray *Arr in arr) {
        if ([Arr[2] isEqualToString:str]) {
            [BeforeArr addObject:Arr];
            
        }else {
            [LastArr addObject:Arr];
        }
    }
    
    NSArray *aveBefore = [self handledataWithArr:BeforeArr];//前一个交易日的均价数组
    NSArray *aveLast = [self handledataWithArr:LastArr];//后一个交易日的均价数组
    
    NSArray *beforePoint = [self changePointWithData:BeforeArr type:2];//前一个交易日的价格坐标数组
    NSArray *avebeforePoint = [self changePointWithData:aveBefore type:2];//前一个交易日的均价坐标数组
    NSArray *lastPoint = [self changePointWithData:LastArr type:3];//后一个交易日的价格坐标数组
    NSArray *avelastPoint = [self changePointWithData:aveLast type:3];//后一个交易日的均价坐标数组
    
    [self drawlineWithArr:beforePoint color:0 sec:1];
    [self drawlineWithArr:avebeforePoint color:1 sec:1];
    [self drawlineWithArr:lastPoint color:0 sec:2];
    [self drawlineWithArr:avelastPoint color:1 sec:2];
    
    //清空数据
    if (pointArray.count > 0) {
        
        [pointArray removeAllObjects];
    }
    pointArray = [NSMutableArray array];
    
    //整合所有信息，重新生成Pointarray,十字星定位用
    for (int i = 0;  i < aveBefore.count; i++) {
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        [arr addObject:beforePoint[i]];//添加价格坐标
        [arr addObject:[BeforeArr[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[BeforeArr[i] objectAtIndex:1]];//添加价格
        [arr addObject:[aveBefore[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[BeforeArr[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        
        //        CGFloat absoValue = fabs(value);
        //        CGFloat incr = absoValue / [_closePrice floatValue] * 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        
        [arr addObject:apply];//添加涨跌幅
        
        [pointArray addObject:arr];
    }
    
    for (int i = 0;  i < aveLast.count; i++) {
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        [arr addObject:lastPoint[i]];//添加价格坐标
        [arr addObject:[LastArr[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[LastArr[i] objectAtIndex:1]];//添加价格
        [arr addObject:[aveLast[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[LastArr[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        
        //        CGFloat absoValue = fabs(value);
        //        CGFloat incr = absoValue / [_closePrice floatValue] * 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        
        [arr addObject:apply];//添加涨跌幅
        
        [pointArray addObject:arr];
    }
    
    
    //显示交易日期
    if (BeforeArr.count > 0) {
        
        NSMutableString *beforeDate = [NSMutableString stringWithFormat:@"%@",[[BeforeArr[0] objectAtIndex:2] substringFromIndex:4]];//1218
        [beforeDate insertString:@"-" atIndex:2];//12-18
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        if (isPad) {
            [beforeDate drawAtPoint:CGPointMake(paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        }else {
            [beforeDate drawAtPoint:CGPointMake(paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
            
        }
    }
    
    if (LastArr.count > 0) {
        
        NSMutableString *endDate = [NSMutableString stringWithFormat:@"%@",[[LastArr[0] objectAtIndex:2] substringFromIndex:4]];
        [endDate insertString:@"-" atIndex:2];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            contentRect = [endDate boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            contentRect = [endDate boundingRectWithSize:CGSizeMake(80, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        
        
        if (isPad) {
            [endDate drawAtPoint:CGPointMake(self.xWidth/2 - contentRect.size.width / 2 + paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        }else {
            [endDate drawAtPoint:CGPointMake(self.xWidth/2 - contentRect.size.width / 2 + paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
        }
        
    }
    
}


#pragma mark 处理三日数据并画线
- (void)drawThreedaysWithArr:(NSArray *)arr {
    NSMutableArray *first = [[NSMutableArray alloc]init];
    NSMutableArray *second = [[NSMutableArray alloc]init];
    NSMutableArray *third = [[NSMutableArray alloc]init];
    
    NSString *str = [[arr firstObject] objectAtIndex:2];//第一个交易日的交易日期
    NSString *newStr = [[arr lastObject] objectAtIndex:2];//最新一个交易日的交易日期
    for (int i = 0; i < arr.count; i++) {
        if ([[arr[i] objectAtIndex:2] isEqualToString:str]) {
            [first addObject:arr[i]];
        }else if ([[arr[i] objectAtIndex:2] isEqualToString:newStr]) {
            
            [third addObject:arr[i]];
        }else {
            
            [second addObject:arr[i]];
        }
    }
    
    NSArray *aveFirst = [self handledataWithArr:first];//第一个交易日的均价数组
    NSArray *aveSecond = [self handledataWithArr:second];//第二个交易日的均价数组
    NSArray *aveThird = [self handledataWithArr:third];//最新交易日的均价数组
    
    NSArray *firstPoint = [self changePointWithData:first type:4];//第一个交易日的价格坐标数组
    NSArray *secondPoint = [self changePointWithData:second type:5];//第二个交易日的价格坐标数组
    NSArray *thirdPoint = [self changePointWithData:third type:6];//最新交易日的价格坐标数组
    
    NSArray *aveFirstPoint = [self changePointWithData:aveFirst type:4];//第一个交易日的均价坐标数组
    NSArray *aveSecondPoint = [self changePointWithData:aveSecond type:5];//第二个交易日的均价坐标数组
    NSArray *aveThirdPoint = [self changePointWithData:aveThird type:6];//最新交易日的均价坐标数组
    
    [self drawlineWithArr:firstPoint color:0 sec:1];//第一个交易日的价格线
    [self drawlineWithArr:aveFirstPoint color:1 sec:1];//第一个交易日的均价线
    [self drawlineWithArr:secondPoint color:0 sec:3];//第二个交易日的价格线
    [self drawlineWithArr:aveSecondPoint color:1 sec:3];//第二个交易日的均价线
    [self drawlineWithArr:thirdPoint color:0 sec:4];//最新交易日的价格线
    [self drawlineWithArr:aveThirdPoint color:1 sec:4];//最新交易日的均价线
    
    //清空数据
    if (pointArray.count > 0) {
        [pointArray removeAllObjects];
    }
    
    pointArray = [NSMutableArray array];
    
    //整合所有信息，重新生成Pointarray,十字星定位用
    //第一个交易日的所有信息
    for (int i = 0;  i < aveFirst.count; i++) {
        
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        
        [arr addObject:firstPoint[i]];//添加价格坐标
        [arr addObject:[first[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[first[i] objectAtIndex:1]];//添加价格
        [arr addObject:[aveFirst[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[first[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        //        CGFloat v = fabs(value);//取绝对值
        //        CGFloat incr = v / [_closePrice floatValue] * 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        [arr addObject:apply];//添加涨跌幅
        [pointArray addObject:arr];
        
    }
    
    
    //第二个交易日的所有信息
    for (int i = 0;  i < aveSecond.count; i++) {
        
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        
        [arr addObject:secondPoint[i]];//添加价格坐标
        [arr addObject:[second[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[second[i] objectAtIndex:1]];//添加价格
        [arr addObject:[aveSecond[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[second[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        //        CGFloat v = fabs(value);
        //        CGFloat incr = v / [_closePrice floatValue] * 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        [arr addObject:apply];//添加涨跌幅
        [pointArray addObject:arr];
        
    }
    
    //最新交易日的所有信息
    for (int i = 0;  i < aveThird.count; i++) {
        
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        
        [arr addObject:thirdPoint[i]];//添加价格坐标
        [arr addObject:[third[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[third[i] objectAtIndex:1]];//添加价格
        [arr addObject:[aveThird[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[third[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        //        CGFloat v = fabs(value);
        //        CGFloat incr = v / [_closePrice floatValue] * 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        [arr addObject:apply];//添加涨跌幅
        [pointArray addObject:arr];
        
    }
    
    
    //显示交易日期
    if (first.count > 0) {
        
        NSMutableString *beforeDate = [NSMutableString stringWithFormat:@"%@",[[first[0] objectAtIndex:2] substringFromIndex:4]];//1218
        [beforeDate insertString:@"-" atIndex:2];
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        if (isPad) {
            [beforeDate drawAtPoint:CGPointMake(paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
            
        }else {
            [beforeDate drawAtPoint:CGPointMake(paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
            
        }
    }
    
    if (second.count > 0) {
        
        NSMutableString *midDate = [NSMutableString stringWithFormat:@"%@",[[second[0] objectAtIndex:2] substringFromIndex:4]];
        [midDate insertString:@"-" atIndex:2];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            contentRect = [midDate boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            contentRect = [midDate boundingRectWithSize:CGSizeMake(80, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        
        if (isPad) {
            [midDate drawAtPoint:CGPointMake(self.xWidth/3 - contentRect.size.width / 2 +paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        }else {
            [midDate drawAtPoint:CGPointMake(self.xWidth/3 - contentRect.size.width / 2 +paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
            
        }
    }
    
    if (third.count > 0) {
        
        NSMutableString *laseDate = [NSMutableString stringWithFormat:@"%@",[[third[0] objectAtIndex:2] substringFromIndex:4]];
        [laseDate insertString:@"-" atIndex:2];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            contentRect = [laseDate boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            contentRect = [laseDate boundingRectWithSize:CGSizeMake(80, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        
        if (isPad) {
            [laseDate drawAtPoint:CGPointMake(self.xWidth/3 - contentRect.size.width / 2 + paddingX + self.xWidth /3, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
            
        }else {
            
            [laseDate drawAtPoint:CGPointMake(self.xWidth/3 - contentRect.size.width / 2 + paddingX + self.xWidth /3, self.yHeight + paddingY) withAttributes:LevelAttrs];
            
        }
    }
    
}


#pragma mark 处理四日数据并画线
- (void)drawFourdaysWithArr:(NSArray *)arr {

    NSMutableArray *array = [[NSMutableArray alloc]init];
    NSMutableArray *firstData = [[NSMutableArray alloc]init];
    NSMutableArray *secondData = [[NSMutableArray alloc]init];
    NSMutableArray *thirdData = [[NSMutableArray alloc]init];
    NSMutableArray *forthData = [[NSMutableArray alloc]init];
    
    NSString *date = [[arr firstObject] objectAtIndex:2];//第一个交易日的交易日期
    NSString *lastdate = [[arr lastObject] objectAtIndex:2];//最新交易日的交易日期
    for (int i = 0; i < arr.count; i++) {
        if ([[arr[i] objectAtIndex:2] isEqualToString:date]) {
            [firstData addObject:arr[i]];
        }else if([[arr[i] objectAtIndex:2] isEqualToString:lastdate]){
            [forthData addObject:arr[i]];
        }else {
            
            [array addObject:arr[i]];
        }
    }
    
    NSString *secdate = [[array firstObject] objectAtIndex:2];//第二个交易日的交易日期
    for (int i = 0; i < array.count; i++) {
        if ([[array[i] objectAtIndex:2] isEqualToString:secdate]) {
            [secondData addObject:array[i]];
        }else {
            
            [thirdData addObject:array[i]];
        }
    }
    
    NSArray *avefirst = [self handledataWithArr:firstData];//第一个交易日的均价数组
    NSArray *avesecond = [self handledataWithArr:secondData];//第二个交易日的均价数组
    NSArray *avethird = [self handledataWithArr:thirdData];//第三个交易日的均价数组
    NSArray *avefour = [self handledataWithArr:forthData];//最新交易日的均价数组
    
    NSArray *firstpoints = [self changePointWithData:firstData type:7];//第一个交易日的价格坐标数组
    NSArray *secondpoints = [self changePointWithData:secondData type:8];//第二个交易日的价格坐标数组
    NSArray *thirdpoints = [self changePointWithData:thirdData type:9];//第三个交易日的价格坐标数组
    NSArray *forthpoints = [self changePointWithData:forthData type:10];//最新交易日的价格坐标数组
    
    NSArray *avefirstpoint = [self changePointWithData:avefirst type:7];//第一个交易日的均价坐标数组
    NSArray *avesecondpoint = [self changePointWithData:avesecond type:8];//第二个交易日的均价坐标数组
    NSArray *avethirdpoint = [self changePointWithData:avethird type:9];//第三个交易日的均价坐标数组
    NSArray *aveforthpoint = [self changePointWithData:avefour type:10];//第四个交易日的均价坐标数组
    
    [self drawlineWithArr:firstpoints color:0 sec:1];//第一个交易日的价格线
    [self drawlineWithArr:avefirstpoint color:1 sec:1];//第一个交易日的均价线
    [self drawlineWithArr:secondpoints color:0 sec:5];//第二个交易日的价格线
    [self drawlineWithArr:avesecondpoint color:1 sec:5];//第二个交易日的均价线
    [self drawlineWithArr:thirdpoints color:0 sec:2];//第三个交易日的价格线
    [self drawlineWithArr:avethirdpoint color:1 sec:2];//第三个交易日的均价线
    [self drawlineWithArr:forthpoints color:0 sec:6];//最新交易日的价格线
    [self drawlineWithArr:aveforthpoint color:1 sec:6];//最新交易日的均价线
    
    //清空数据
    if (pointArray.count > 0) {
        
        [pointArray removeAllObjects];
    }
    
    pointArray = [NSMutableArray array];
    
    //整合所有信息，重新生成Pointarray,十字星定位用
    //第一个交易日的所有信息
    for (int i = 0;  i < avefirst.count; i++) {
        
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        
        [arr addObject:firstpoints[i]];//添加价格坐标
        [arr addObject:[firstData[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[firstData[i] objectAtIndex:1]];//添加价格
        [arr addObject:[avefirst[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[firstData[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        //        CGFloat v = fabs(value);
        //        CGFloat incr = v / [_closePrice floatValue] * 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        [arr addObject:apply];//添加涨跌幅
        
        [pointArray addObject:arr];
        
    }
    
    
    //第二个交易日的所有信息
    for (int i = 0;  i < avesecond.count; i++) {
        
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        
        [arr addObject:secondpoints[i]];//添加价格坐标
        [arr addObject:[secondData[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[secondData[i] objectAtIndex:1]];//添加价格
        [arr addObject:[avesecond[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[secondData[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        //        CGFloat v = fabs(value);
        //        CGFloat incr = v / [_closePrice floatValue]* 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        [arr addObject:apply];//添加涨跌幅
        
        [pointArray addObject:arr];
        
    }
    
    //第三个交易日的所有信息
    for (int i = 0;  i < avethird.count; i++) {
        
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        
        [arr addObject:thirdpoints[i]];//添加价格坐标
        [arr addObject:[thirdData[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[thirdData[i] objectAtIndex:1]];//添加价格
        [arr addObject:[avethird[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[thirdData[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        //        CGFloat v = fabs(value);
        //        CGFloat incr = v / [_closePrice floatValue]* 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        [arr addObject:apply];//添加涨跌幅
        
        [pointArray addObject:arr];
        
    }
    //最新交易日的所有信息
    for (int i = 0;  i < avefour.count; i++) {
        
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        
        [arr addObject:forthpoints[i]];//添加价格坐标
        [arr addObject:[forthData[i] objectAtIndex:0]];//添加日期时间
        [arr addObject:[forthData[i] objectAtIndex:1]];//添加价格
        [arr addObject:[avefour[i] objectAtIndex:1]];//添加均价
        
        //计算涨跌幅
        
        CGFloat value = [[forthData[i] objectAtIndex:1] floatValue] - [_closePrice floatValue];
        //        CGFloat v = fabs(value);
        //        CGFloat incr = v / [_closePrice floatValue] * 100;
        CGFloat incr = value / [_closePrice floatValue] * 100;
        NSString *apply = [NSString stringWithFormat:@"%.2f%%",incr];
        [arr addObject:apply];//添加涨跌幅
        
        [pointArray addObject:arr];
        
    }
    
    
    //显示交易日期
    if (firstData.count > 0) {
        
        NSMutableString *firstDate = [NSMutableString stringWithFormat:@"%@",[[firstData[0] objectAtIndex:2] substringFromIndex:4]];//1218
        [firstDate insertString:@"-" atIndex:2];
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        if (isPad) {
            [firstDate drawAtPoint:CGPointMake(paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        }else {
            
            [firstDate drawAtPoint:CGPointMake(paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
        }
    }
    
    if (secondData.count > 0) {
        
        NSMutableString *seconddate = [NSMutableString stringWithFormat:@"%@",[[secondData[0] objectAtIndex:2] substringFromIndex:4]];
        [seconddate insertString:@"-" atIndex:2];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            contentRect = [seconddate boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            contentRect = [seconddate boundingRectWithSize:CGSizeMake(80, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        
        if (isPad) {
            [seconddate drawAtPoint:CGPointMake(self.xWidth/4 - contentRect.size.width / 2 + paddingX, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        }else {
            [seconddate drawAtPoint:CGPointMake(self.xWidth/4 - contentRect.size.width / 2 + paddingX, self.yHeight + paddingY) withAttributes:LevelAttrs];
            
        }
    }
    
    if (thirdData.count > 0) {
        
        NSMutableString *thirddate = [NSMutableString stringWithFormat:@"%@",[[thirdData[0] objectAtIndex:2] substringFromIndex:4]];
        [thirddate insertString:@"-" atIndex:2];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            contentRect = [thirddate boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            contentRect = [thirddate boundingRectWithSize:CGSizeMake(80, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        
        if (isPad) {
            [thirddate drawAtPoint:CGPointMake(self.xWidth/4 - contentRect.size.width / 2 + paddingX + self.xWidth / 4, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        }else {
            
            [thirddate drawAtPoint:CGPointMake(self.xWidth/4 - contentRect.size.width / 2 + paddingX + self.xWidth / 4, self.yHeight + paddingY) withAttributes:LevelAttrs];
            
        }
    }
    
    if (forthData.count > 0) {
        
        NSMutableString *fordate = [NSMutableString stringWithFormat:@"%@",[[forthData[0] objectAtIndex:2] substringFromIndex:4]];
        [fordate insertString:@"-" atIndex:2];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetShouldAntialias(context, YES);
        CGContextSetRGBFillColor(context, 10,10, 10, 1.0);
        
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        if (isPad) {
            contentRect = [fordate boundingRectWithSize:CGSizeMake(100, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            contentRect = [fordate boundingRectWithSize:CGSizeMake(80, 30) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        
        if (isPad) {
            [fordate drawAtPoint:CGPointMake(self.xWidth/4 - contentRect.size.width / 2 + paddingX + 2 * self.xWidth / 4, self.yHeight + paddingY) withAttributes:PadLevelAttrs];
        }else {
            
            [fordate drawAtPoint:CGPointMake(self.xWidth/4 - contentRect.size.width / 2 + paddingX + 2 * self.xWidth / 4, self.yHeight + paddingY) withAttributes:LevelAttrs];
        }
    }
    
}


#pragma mark 画连接线方法
//画连接线方法
- (void)drawlineWithArr:(NSArray *)arr color:(int)color sec:(int)sec{

    if (arr.count == 0) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();// 获取绘图上下文
    CGContextSetLineDash(context, 0, 0, 0);
    CGContextSetLineWidth(context, 0.5);//线宽
    CGContextSetShouldAntialias(context, YES);//设置图形上下文的抗锯齿开启或关闭
    
    if (color == 0) {
        //        CGContextSetRGBStrokeColor(context, 1, 0.5, 0, 0.5);// 黄色
        CGContextSetRGBStrokeColor(context, 196 / 255.0, 90 / 255.0, 22 / 255.0, 1.0);
    }else if (color == 1) {
        //        CGContextSetRGBStrokeColor(context, 1, 1, 0, 0.5);// 橙色
        CGContextSetRGBStrokeColor(context, 120 / 255.0, 139 / 255.0, 14 / 255.0, 1.0);
    }
    
    if (sec == 1) {
        
        CGPoint firstPoint = CGPointFromString([arr firstObject]);
        CGPoint point = CGPointMake(paddingX, firstPoint.y);
        const CGPoint points[] = {point,firstPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
    }else if (sec == 2){
        
        CGPoint firstPoint = CGPointFromString([arr firstObject]);
        CGPoint point = CGPointMake(paddingX + self.xWidth / 2, firstPoint.y);
        const CGPoint points[] = {point,firstPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
        
    }else if (sec == 3) {
        CGPoint firstPoint = CGPointFromString([arr firstObject]);
        CGPoint point = CGPointMake(paddingX + self.xWidth / 3, firstPoint.y);
        const CGPoint points[] = {point,firstPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
        
    }else if (sec == 4) {
        
        CGPoint firstPoint = CGPointFromString([arr firstObject]);
        CGPoint point = CGPointMake(paddingX + 2 * self.xWidth / 3, firstPoint.y);
        const CGPoint points[] = {point,firstPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
    }else if (sec == 5) {
        
        CGPoint firstPoint = CGPointFromString([arr firstObject]);
        CGPoint point = CGPointMake(paddingX + self.xWidth / 4, firstPoint.y);
        const CGPoint points[] = {point,firstPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
    }else if (sec == 6) {
        
        CGPoint firstPoint = CGPointFromString([arr firstObject]);
        CGPoint point = CGPointMake(paddingX + 3 * self.xWidth / 4, firstPoint.y);
        const CGPoint points[] = {point,firstPoint};
        CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
    }
    
    
    // 定义多个个点 画多点连线
    
    for (id item in arr) {
        
        CGPoint currentPoint = CGPointFromString(item);
        
        if ((int)currentPoint.y<=(int)self.yHeight + paddingY && currentPoint.y>=paddingY) {
            
            if ([arr indexOfObject:item]==0) {
                
                CGContextMoveToPoint(context, currentPoint.x, currentPoint.y);
                
                continue;
                
            }
            
            CGContextAddLineToPoint(context, currentPoint.x, currentPoint.y);
            
            CGContextStrokePath(context); //开始画线
            
            if ([arr indexOfObject:item]<arr.count) {
                
                CGContextMoveToPoint(context, currentPoint.x, currentPoint.y);
                
            }
            
        }
    }
    
}


//把数字换算成分钟数
- (int)changeNumForMinutesWithIdx:(NSString *)idx{
   
    if (idx.length < 3) {
        return [idx intValue];
    }
    if ([idx intValue] > 3) {
        return [idx intValue] / 100 * 60+ [idx intValue] % 100;
    }
    return 0;
}

@end
