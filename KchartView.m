//
//  KchartView.m
//  RunChartAndKchart
//
//  Created by zsgjs on 15/12/16.
//  Copyright (c) 2015年 zsgjs. All rights reserved.
//

#import "KchartView.h"
#import "Config.h"



#define MIN_INTERVAL  3
#define LabWidth 50

/*
 参数类型：
 sections:{
 secs =     (
              (
                0,
                0,
                370,
                300
               )
              );
           （
              （
                0，
                0，
                370，
                80
             ）;
 type = nil;
 }
 
 secs字段:字段中数组个数分时图为1，K线图为2，传给父类绘制坐标系

 
 
 sectionDic:{
 isK = 0;
 max = "0.000000";
 min = "0.000000";
 volmax = "";
 volmin = "";
 start = "";
 end = "";
 }
 

 isK字段:是否K线图
 max字段:主图最大坐标值
 min字段:主图图最小坐标值
 volmax:副图最大坐标值
 volmin:副图最小坐标值
 start:左侧横坐标
 end:右侧横坐标
 */


/*
 整体逻辑：
 1.在初始化方法里封装好K线图，包括主图、副图的坐标系信息，初始化各种参数，包括主图、副图指标参数和用到的数组，并声明好所有要显示指标值的控件
 2.在画图方法里，首先根据1中封装好的主副图坐标系信息，调用父类的方法绘制主副图坐标系。
               然后计算指标值。根据外界传过来的主图、副图指标类型进行相应的指标值计算。生成各种指标数组
               比较上步的指标值数组，获得主副图最大最小值，并封装起来，调用父类的方法，完成对主副图的坐标系内坐标值的显示。
               画线。首先画指标线。主副图指标线都是折线。根据各自的指标值数组，把指标值换算成实际的点坐标数组,横坐标根据K线宽度和K线之间的间隔来定，纵坐标根据纵轴的最大最小值和纵轴实际高度来定。根据处理好的指标坐标数组，绘制指标线。
                   然后绘制K线。先根据开、高、低、收价定义一个画单根K线的方法。然后遍历展示区域的数据，绘制所有的K线。并会生成一个含K线坐标、该点坐标的对应开、高、低、收价，该点坐标对应的各种指标值的数组A，作为长按手势十字星的定位依据
 3.添加长按手势。设置1s时间。长按时显示十字星，并显示历史信息。可以遍历上步封装好的A数组，找到存储的点坐标的横坐标，跟手势点的横坐标做比较，如果间距在一定范围内，就取出此元素，包括该点K线坐标，该点位置的开、高、低、收价，该点位置的指标值，然后显示。同时通过代理将这些数据传递给外界
 4.添加平移、缩放手势操作方法。因为要实时画图，不能使用gestureRecognizer，只能使用touchbegan等方法来调用setNeedsDisplay实时刷新屏幕。在相应方法里根据手势点数判断，1为平移操作，2为缩放操作。平移则改变range、rangTo参数，对数据源重新截取，重新获取展示区域内的数据，然后调用setNeedsDisplay方法重绘。缩放则改变rang、rangTo参数的同时，对K线的宽度也进行相应的改变，同样调用setNeedsDisplay方法进行重绘。
 5.显示指标数据。如果没有进行任何手势操作，默认显示的是展示区域内最后一条数据的指标值。我们可以取出展示区域内数组的最后一个元素，获得该点的主副图指标值然后显示。当有手势操作时，则重新取展示区域内的最后一条数据，对指标值做相应的显示改动。
 */

/*
 常用数学函数:
 double sqrt (double);开平方 
 double pow(double x, double y）;计算以x为底数的y次幂
 double ceil (double); 取上整
 double floor (double); 取下整
 double fabs (double);求绝对值 
 round(3.5);   //result 4
 round(3.46);   //result 3  四舍五入
 fmin(5,10)   //result 5   最小值
 fmax(5,10)     //result10  最大值
 */


@interface KchartView ()
{
    
    NSMutableDictionary  *sections;//坐标系信息
    NSMutableDictionary  *sectionDic;//坐标值信息
    NSInteger             rangeFrom;
    NSInteger             range;//界面上总K线的范围
    NSInteger             rangeTo;//界面上总K线范围的终止位置
    NSMutableArray       *Uper; /* 主图指标数组   MA下为 5均线指标数组
                                          BOLL下为UP指标数组
                                          ENV下为UP指标数组
                           */
    NSMutableArray       *valueUper;
    NSMutableArray       *Mider; /* 主图指标数组  MA下为 10均线指标数组
                                          BOLL下为MID指标数组
                                          ENV下为MID指标数组
                            */
    NSMutableArray       *valueMider;
    NSMutableArray       *Lower; /* 主图指标数组   MA下为 20均线指标数组
                                           BOLL下为LOWER指标数组
                                           ENV下为LOWER指标数组
                            */
    NSMutableArray       *valueLower;
    NSMutableArray       *volUper;/* 副图指标数值  MACD下为 DIF指标数组
                                           BIAS下为BIAS1
                                           KDJ下为K
                                           RSI下位RSI1
                                           WR下为WR
                             */
    NSMutableArray       *valueVolUper;
    NSMutableArray       *volMider;/* 副图指标数值  MACD下为 DEA指标数组
                              BIAS下为BIAS2
                              KDJ下为D
                              RSI下位RSI2
                              WR下为空
                              */
    NSMutableArray      *valueVolMider;
    NSMutableArray       *volLower;/* 副图指标数值  MACD下为 MACD
                              BIAS下为空
                              KDJ下为J
                              RSI下位RSI3
                              WR下为空
                              */
    NSMutableArray      *valueVolLower;
    NSMutableArray      *applyArray;//涨跌幅数组
    NSMutableArray      *valueApplyArray;//展示区域内的涨跌幅数组
    UILabel             *startDateLab;
    UILabel             *endDateLab;
    NSMutableArray      *pointArray; // k线所有坐标数组
    CGPoint              touchViewPoint;//手势点
    UIView              *movelineone; // 手指按下后显示的三根白色十字线
    UIView              *movelinetwo;
    UIView              *movelinethree;
    UILabel             *uperLab;/*主图指标显示控件  MA下为MA5:--
                                      BOLL下为UP：--
                                      ENV下为UP:--
                      */
    UILabel             *miderLab;/*主图指标显示控件 MA下为MA10：--
                                      BOLL下为MID:--
                                      ENV下为MID:--
                       */
    UILabel             *lowerLab;/*主图指标显示控件 MA下为MA20:--
                                      BOLL下为LOW:--
                                      ENV下为LOW:--
                       */
    
    UILabel             *volUpLab;/*副图指标显示控件 MACD下为DIF:--
                                      BIAS下为BIAS1:--
                                      KDJ下为K:--
                                      RSI下为RSI1:--
                                      WR下为WR:--
                       */
    UILabel             *volMidLab;/*副图指标显示控件 MACD下为DEA:--
                                        BIAS下为BIAS2:--
                                        KDJ下为D:--
                                        RSI下为RSI2:--
                        */
    UILabel             *volLowLab;/*副图指标显示控件 MACD下为MACD:--
                        
                                       KDJ下为J:--
                                       RSI下为RSI3:--
                        */
    
    CGFloat            touchFloat;
    CGFloat            touchFlag;
    CGFloat            touchFlagTwo;
    UIFont             *font;
    
    UILabel            *KfirstLab;
    UILabel            *KsecondLab;
    UILabel            *KthirdLab;
    
 
}

@end

@implementation KchartView


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    self.backgroundColor = [UIColor clearColor]; //不设置背景色，刷新重绘时图像会重叠
    sections = [[NSMutableDictionary alloc]init];
    self.data = [[NSMutableArray alloc]init];
    self.categorys = [[NSMutableArray alloc]init];
    
    NSString *width = [NSString stringWithFormat:@"%f",self.frame.size.width - 20];//主图宽度
    NSString *height = [NSString stringWithFormat:@"%f",self.frame.size.height * 4 / 7 - 20 - 5];//主图高度
    
    NSArray *arr = @[@"10",@"5",width,height];
    self.padingX = [arr[0] floatValue]; //主图X坐标
    self.padingY = [arr[1] floatValue]; //主图Y坐标
    self.xWidth = [arr[2] floatValue];  //主图宽度
    self.yHeight = [arr[3] floatValue]; //主图高度
    
    NSString *y = [NSString stringWithFormat:@"%f",self.frame.size.height * 7.4 / 11];
    NSString *newHeight = [NSString stringWithFormat:@"%f",self.frame.size.height * 3.6 / 11 - 5];
    NSArray *Arr = @[@"10",y,width,newHeight];
    self.bottomY = [Arr[1] floatValue];     //副图Y坐标
    self.bottomHeight = [Arr[3] floatValue];//副图高度
    
    NSMutableArray *array = [[NSMutableArray alloc]init];
    [array addObject:arr];
    [array addObject:Arr];
    [sections setObject:array forKey:@"secs"];//封装坐标系信息
    
    sectionDic = [[NSMutableDictionary alloc]init];
    range = 45;//默认45根K线
    rangeTo = 200 ;
    
    self.kLineWidth = (self.xWidth - 44 * 2 - 5)/45;// k线实体的宽度
    self.kLinePadding = 2;                         // k实体的间隔
    font = [UIFont systemFontOfSize:9];
    
    Uper = [[NSMutableArray alloc]init];
    Mider = [[NSMutableArray alloc]init];
    Lower = [[NSMutableArray alloc]init];
    volUper = [[NSMutableArray alloc]init];
    volMider = [[NSMutableArray alloc]init];
    volLower = [[NSMutableArray alloc]init];
    pointArray = [[NSMutableArray alloc]init];
    _Kdata = [[NSMutableArray alloc]init];
    _cates = [[NSMutableArray alloc]init];
    valueUper = [[NSMutableArray alloc]init];
    valueMider = [[NSMutableArray alloc]init];
    valueLower = [[NSMutableArray alloc]init];
    valueVolUper = [[NSMutableArray alloc]init];
    valueVolMider = [[NSMutableArray alloc]init];
    valueVolLower = [[NSMutableArray alloc]init];
    applyArray = [[NSMutableArray alloc]init];
    valueApplyArray = [[NSMutableArray alloc]init];
    
    self.userInteractionEnabled = YES;
    
    //    _closePrice = @"226.97";//昨收价
    _closePrice = @"2";//kde字段
    
    _isShowLevelTime = NO;
    _islevel = NO;
    _isShowHistory = NO;//是否正在显示历史信息
    
    //设置默认参数
    self.MAUP = @"5";
    self.MAMID = @"10";
    self.MALOW = @"20";
    
    self.BOLLN = @"20";
    self.BOLLP = @"2";
    
    self.ENVN = @"14";
    
    self.MACDSHORT = @"12";
    self.MACDLONG = @"26";
    self.MACDM = @"9";
    
    self.BIASL1 = @"6";
    self.BIASL2 = @"12";
    
    self.KDJN = @"9";
    self.KDJM1 = @"3";
    self.KDJM2 = @"3";
    
    self.RSIN1 = @"6";
    self.RSIN2 = @"12";
    self.RSIN3 = @"24";
    
    self.WRN = @"14";
    
    //主图指标显示控件
    if (uperLab==nil) {
        uperLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        uperLab.backgroundColor = [UIColor clearColor];
        uperLab.font = font;
        if (isPad) {
            uperLab.font = [UIFont systemFontOfSize:13];
        }
        [self addSubview:uperLab];
    }
    
    if (miderLab==nil) {
        miderLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        miderLab.backgroundColor = [UIColor clearColor];
        miderLab.font = font;
        if (isPad) {
            miderLab.font = [UIFont systemFontOfSize:13];
        }
        [self addSubview:miderLab];
    }
    
    if (lowerLab==nil) {
        lowerLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        lowerLab.backgroundColor = [UIColor clearColor];
        lowerLab.font = font;
        if (isPad) {
            lowerLab.font = [UIFont systemFontOfSize:13];
        }
        [self addSubview:lowerLab];
    }
    
    //副图指标显示控件
    if (volUpLab==nil) {
        volUpLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        volUpLab.backgroundColor = [UIColor clearColor];
        volUpLab.font = font;
        if (isPad) {
            volUpLab.font = [UIFont systemFontOfSize:13];
        }
        [self addSubview:volUpLab];
    }
    
    if (volMidLab==nil) {
        volMidLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        volMidLab.backgroundColor = [UIColor clearColor];
        volMidLab.font = font;
        if (isPad) {
            volMidLab.font = [UIFont systemFontOfSize:13];
        }
        
        [self addSubview:volMidLab];
    }
    
    if (volLowLab==nil) {
        volLowLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        volLowLab.backgroundColor = [UIColor clearColor];
        volLowLab.font = font;
        if (isPad) {
            volLowLab.font = [UIFont systemFontOfSize:13];
        }
        
        [self addSubview:volLowLab];
    }
    
    uperLab.hidden = YES;
    miderLab.hidden = YES;
    lowerLab.hidden = YES;
    volUpLab.hidden = YES;
    volMidLab.hidden = YES;
    volLowLab.hidden = YES;
    
    
    if (KfirstLab == nil) {
        KfirstLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
        KfirstLab.backgroundColor = [UIColor clearColor];
        KfirstLab.font = font;
        if (isPad) {
            KfirstLab.font = [UIFont systemFontOfSize:13];
        }
        [self addSubview:KfirstLab];
    }
    if (KsecondLab == nil) {
        KsecondLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
        KsecondLab.backgroundColor = [UIColor clearColor];
        KsecondLab.font = font;
        if (isPad) {
            KsecondLab.font = [UIFont systemFontOfSize:13];
        }
        [self addSubview:KsecondLab];
    }
    if (KthirdLab == nil) {
        KthirdLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
        KthirdLab.backgroundColor = [UIColor clearColor];
        KthirdLab.font = font;
        if (isPad) {
            KthirdLab.font = [UIFont systemFontOfSize:13];
        }
        [self addSubview:KthirdLab];
    }

    KfirstLab.hidden = YES;
    KsecondLab.hidden = YES;
    KthirdLab.hidden = YES;
    
    return self;
}


- (void)drawRect:(CGRect)rect {
    
    //    self.layer.shouldRasterize = YES;//开启光栅化
    self.layer.drawsAsynchronously = YES;//异步绘制不影响用户交互
    self.backgroundColor = [UIColor clearColor]; //不设置背景色，刷新重绘时图像会重叠
    self.multipleTouchEnabled = YES;//打开多点触摸，默认关闭
    [sections setObject:@"nil" forKey:@"type"];//type字段用来区分几日分时
    
    //画坐标系//坐标系的大小固定以及位置
    [self drawSectionsWithDic:sections];
    
    //取出计算好的相应指标值
    [self handleDataForIndo];
    
    //显示坐标值
    if (self.data.count > 0) {
        
        //改变左侧纵坐标最大最小值
        [self changeMaxAndMinValue];
        //画坐标值
//        [self drawCoordvalueWithDic:sectionDic];
    }
    
    //画指标线
    [self drawLine];
    
    if (valueUper.count > 0) {
        
        //画K线
        [self drawKline];
    }
    
    //添加长按手势
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
    [longPressGestureRecognizer addTarget:self action:@selector(gestureRecognizerHandle:)];
    [longPressGestureRecognizer setMinimumPressDuration:0.5f];
    [self addGestureRecognizer:longPressGestureRecognizer];
    
 
    if (self.data.count > 0) {
        
        //画坐标值
        [self drawCoordvalueWithDic:sectionDic];
    }
    
    if (!_isShowHistory) {
        
        //显示指标数据
        [self showIndo];
    }
}


//改变左侧纵坐标最大最小值
/*
 为防止有的指标数据超过坐标系，所以要对指标数组进行一次遍历，比较最大最小坐标值
 */
/*
 cates: 2015-12-22   08:00
 kdata: {开，高，低，收}
 */

- (void)changeMaxAndMinValue{
    
    //主图坐标值
    //开，高，低，收
    if (self.data.count < range) {
        range = self.data.count;
        rangeTo = self.data.count;
    }
    
    _Kdata = [NSMutableArray arrayWithArray:[self.data objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//取指定的数据，获取展示区域的数组
    _cates = [NSMutableArray arrayWithArray:[self.categorys objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//取指定的日期数据，获取展示区域的日期数组
    
    //横坐标
    NSString *start = [[_cates firstObject] substringToIndex:10];
    NSString *startdate =  [self handledateWith:[start substringFromIndex:2]];
    NSString *end = [[_cates lastObject] substringToIndex:10];
    NSString *enddate = [self handledateWith:[end substringFromIndex:2]];
    
    if (_Kdata.count == 0) {
        return;
    }
    
    //纵坐标
    self.maxValue = [[[_Kdata objectAtIndex:0] objectAtIndex:1] floatValue];//取第一个数据作为基准
    self.minValue = [[[_Kdata objectAtIndex:0] objectAtIndex:2] floatValue];
    
    //分别遍历K线数组，指标数组，取出最大最小值
    for (NSArray *Arr in _Kdata) {
        //确定最高价
        self.maxValue = fmax([[Arr objectAtIndex:1] floatValue], self.maxValue);
        //确定最低价
        self.minValue = fmin([[Arr objectAtIndex:2] floatValue], self.minValue);
    }
    

    
    //遍历三个指标数值，比较最大、最小值
    if (valueUper.count > 0) {
        
        for (int i = 0; i < valueUper.count; i++) {
            NSString *uper = valueUper[i];
            NSString *mider = valueMider[i];
            NSString *lower = valueLower[i];
            
            if ([uper floatValue] > 0) {
                self.maxValue = fmax([uper floatValue], self.maxValue);
                self.minValue = fmin([uper floatValue], self.minValue);
            }
            
            if ([mider floatValue] > 0) {
                self.maxValue = fmax([mider floatValue], self.maxValue);
                self.minValue = fmin([mider floatValue], self.minValue);
            }
            
            if ([lower floatValue] > 0) {
                self.maxValue = fmax([lower floatValue], self.maxValue);
                self.minValue = fmin([lower floatValue], self.minValue);
            }
            
        }
    }
    
    
    //副图坐标值
    if ([self.ViceIndo isEqualToString:@"MACD"] || [self.ViceIndo isEqualToString:@"BIAS"]) {
        
        self.volMaxValue = [[valueVolUper lastObject] floatValue];//取最后一个数据作为基准
        self.volMinValue = [[valueVolUper lastObject] floatValue];
        
        for (NSString *value in valueVolUper) {
            if ([value isEqualToString:@"nil"]) {
                continue;
            }
            self.volMaxValue = fmax([value floatValue], self.volMaxValue);
            self.volMinValue = fmin([value floatValue], self.volMinValue);
        }
        
        for (NSString *value in valueVolMider) {
            if ([value isEqualToString:@"nil"]) {
                continue;
            }
            self.volMaxValue = fmax([value floatValue], self.volMaxValue);
            self.volMinValue = fmin([value floatValue], self.volMinValue);
        }
        
        for (NSString *value in valueVolLower) {
            if ([value isEqualToString:@"nil"]) {
                continue;
            }
            self.volMaxValue = fmax([value floatValue], self.volMaxValue);
            self.volMinValue = fmin([value floatValue], self.volMinValue);
        }
        
        if ([self.ViceIndo isEqualToString:@"MACD"]) {
            if (fabs(self.volMaxValue) > fabs(self.volMinValue)) {
                self.volMinValue = 0 - fabs(self.volMaxValue);
            }else {
                self.volMaxValue = fabs(self.volMinValue);
            }
        }
        
    }else  {
        self.volMaxValue = 100;
        self.volMinValue = 0;
    }
    
    [sectionDic setObject:@"1" forKey:@"isK"];
    
    //判断几位小数,根据收盘价价格位数确定坐标值的小数位数
    
    if ([_closePrice integerValue] == 1) {
        [sectionDic setObject:[NSString stringWithFormat:@"%.1f",_maxValue] forKey:@"max"];//主图最大坐标值
        [sectionDic setObject:[NSString stringWithFormat:@"%.1f",_minValue] forKey:@"min"];//主图最小坐标值
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",_volMaxValue] forKey:@"volMax"];//副图最大坐标值
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",_volMinValue] forKey:@"volMin"];//副图最小坐标值
    }else if ([_closePrice integerValue] == 2) {
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",_maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",_minValue] forKey:@"min"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",_volMaxValue] forKey:@"volMax"];//副图最大坐标值
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",_volMinValue] forKey:@"volMin"];//副图最小坐标值
    }else if ([_closePrice integerValue] == 3){
        [sectionDic setObject:[NSString stringWithFormat:@"%.3f",_maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.3f",_minValue] forKey:@"min"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.3f",_volMaxValue] forKey:@"volMax"];//副图最大坐标值
        [sectionDic setObject:[NSString stringWithFormat:@"%.3f",_volMinValue] forKey:@"volMin"];//副图最小坐标值
    }else if ([_closePrice integerValue] == 4) {
        
        [sectionDic setObject:[NSString stringWithFormat:@"%.4f",_maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.4f",_minValue] forKey:@"min"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.4f",_volMaxValue] forKey:@"volMax"];//副图最大坐标值
        [sectionDic setObject:[NSString stringWithFormat:@"%.4f",_volMinValue] forKey:@"volMin"];//副图最小坐标值
    }else if ([_closePrice integerValue] == 0){
        [sectionDic setObject:[NSString stringWithFormat:@"%d",(int)self.maxValue] forKey:@"max"];
        [sectionDic setObject:[NSString stringWithFormat:@"%d",(int)self.minValue] forKey:@"min"];
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",_volMaxValue] forKey:@"volMax"];//副图最大坐标值
        [sectionDic setObject:[NSString stringWithFormat:@"%.2f",_volMinValue] forKey:@"volMin"];//副图最小坐标值
    }
    
    //    [sectionDic setObject:[self notRoundingWith:self.volMaxValue afterPoint:[_closePrice intValue]] forKey:@"volMax"];//副图最大坐标值
    //    [sectionDic setObject:[self notRoundingWith:self.volMinValue afterPoint:[_closePrice intValue]] forKey:@"volMin"];//副图最小坐标值
    
    [sectionDic setObject:startdate forKey:@"start"];//横坐标
    [sectionDic setObject:enddate forKey:@"end"];//横坐标
    if (!_closePrice || [_closePrice isKindOfClass:[NSNull class]] || _closePrice == nil || _closePrice == NULL) {
        return;
    }
    [sectionDic setObject:_closePrice forKey:@"kde"];
    
}


#pragma mark 取指标数据

//计算指标
- (void)handleDataForIndo {
    if (valueUper.count > 0) {
        [valueUper removeAllObjects];
        [valueMider removeAllObjects];
        [valueLower removeAllObjects];
        [valueVolUper removeAllObjects];
        [valueVolMider removeAllObjects];
        [valueVolLower removeAllObjects];
    }
    
    //主图指标
    if ([self.indo isEqualToString:@"MA"]) {
        
        //若数据不够，重新截取数据
        if (Uper.count > 0) {
            if (Uper.count < range) {
                range = Uper.count;
                rangeTo = range;
            }
            
            valueUper = [NSMutableArray arrayWithArray:[Uper objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//获取展示区域内的指标值
            valueLower = [NSMutableArray arrayWithArray:[Lower objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
            valueMider = [NSMutableArray arrayWithArray:[Mider objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
            valueApplyArray = [NSMutableArray arrayWithArray:[applyArray objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
        }
        
    }else if ([self.indo isEqualToString:@"BOLL"]) {
        
        if (Uper.count > 0) {
            //若数据不够，重新截取数据
            if (Uper.count < range) {
                range = Uper.count;
                rangeTo = range;
            }
            
            valueUper = [NSMutableArray arrayWithArray:[Uper objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//获取展示区域内的指标值
            valueLower = [NSMutableArray arrayWithArray:[Lower objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
            valueMider = [NSMutableArray arrayWithArray:[Mider objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
            valueApplyArray = [NSMutableArray arrayWithArray:[applyArray objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
        }
        
    }else if ([self.indo isEqualToString:@"ENV"]){
        
        if (Uper.count > 0) {
            //若数据不够，重新截取数据
            if (Uper.count < range) {
                range = Uper.count;
                rangeTo = range;
            }
            
            valueUper = [NSMutableArray arrayWithArray:[Uper objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//获取展示区域内的指标值
            valueLower = [NSMutableArray arrayWithArray:[Lower objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
            valueMider = [NSMutableArray arrayWithArray:[Mider objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
            valueApplyArray = [NSMutableArray arrayWithArray:[applyArray objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
        }
    }
    
    //副图指标
    if ([self.ViceIndo isEqualToString:@"MACD"]) {
        
        if (volUper.count > 0) {
            //若数据不够，重新截取数据
            if (Uper.count < range) {
                range = Uper.count;
                rangeTo = range;
            }
            
            valueVolUper = [NSMutableArray arrayWithArray:[volUper objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//获取展示区域内的指标值
            valueVolMider = [NSMutableArray arrayWithArray:[volMider objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range , range)]]];
            valueVolLower = [NSMutableArray arrayWithArray:[volLower objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range , range)]]];
            valueApplyArray = [NSMutableArray arrayWithArray:[applyArray objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
        }
        
    }else if ([self.ViceIndo isEqualToString:@"BIAS"]) {
    
        
        if (volUper.count > 0) {
            //若数据不够，重新截取数据
            if (Uper.count < range) {
                range = Uper.count;
                rangeTo = range;
            }
            
            valueVolUper = [NSMutableArray arrayWithArray:[volUper objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//获取展示区域内的指标值
            valueVolMider = [NSMutableArray arrayWithArray:[volMider objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
            valueApplyArray = [NSMutableArray arrayWithArray:[applyArray objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
        }
        
    }else if ([self.ViceIndo isEqualToString:@"KDJ"]) {
        
        if (volUper.count > 0) {
            //若数据不够，重新截取数据
            if (Uper.count < range) {
                range = Uper.count;
                rangeTo = range;
            }
            
            valueVolUper = [NSMutableArray arrayWithArray:[volUper objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//获取展示区域内的指标值
            valueVolMider = [NSMutableArray arrayWithArray:[volMider objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range , range)]]];
            valueVolLower = [NSMutableArray arrayWithArray:[volLower objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range , range)]]];
            valueApplyArray = [NSMutableArray arrayWithArray:[applyArray objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
        }
        
    }else if ([self.ViceIndo isEqualToString:@"RSI"]) {
        
        if (volUper.count > 0) {
            //若数据不够，重新截取数据
            if (Uper.count < range) {
                range = Uper.count;
                rangeTo = range;
            }
            
            valueVolUper = [NSMutableArray arrayWithArray:[volUper objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//获取展示区域内的指标值
            valueVolMider = [NSMutableArray arrayWithArray:[volMider objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range , range)]]];
            valueVolLower = [NSMutableArray arrayWithArray:[volLower objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range , range)]]];
            valueApplyArray = [NSMutableArray arrayWithArray:[applyArray objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
        }
        
    }else if ([self.ViceIndo isEqualToString:@"WR"]) {
        
        if (volUper.count > 0) {
            //若数据不够，重新截取数据
            if (Uper.count < range) {
                range = Uper.count;
                rangeTo = range;
            }
            
            valueVolUper = [NSMutableArray arrayWithArray:[volUper objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];//获取展示区域内的指标值
            valueApplyArray = [NSMutableArray arrayWithArray:[applyArray objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(rangeTo - range, range)]]];
        }
    }
    
}



#pragma mark 计算主图MA指标
/*
 MA5=MA（Close，5）；
 MA10=MA（Close，10）；
 MA20=MA（Close，20）；
 */

- (NSMutableArray *)handleDataForIndi:(NSArray *)arr index:(int)index{
    
    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    NSMutableArray *temp = [[NSMutableArray alloc]init];
    
    for (NSArray *Arr in arr) {
        [temp addObject:[Arr objectAtIndex:3]];//收盘价
    }

    for (int i = 0; i < temp.count; i++) {
        
        if ( (i + 1) < index) {
            //最初几个数没值
            [tempArr addObject:@"nil"];
        }else {
            NSString *tempStr = [NSString stringWithFormat:@"%f",[self sumArrayWithData:temp andRange:NSMakeRange(i + 1 - index, index)]];
            [tempArr addObject:tempStr];
        }
    }
    return tempArr;
}


#pragma mark 计算主图BOLL指标
/*
 MID :  MA(CLOSE,N);
 UP: MID + P*STD(CLOSE,N);
 LOWER: MID - P*STD(CLOSE,N);
 */

- (NSArray *)handleDataForSTDWithArr:(NSArray *)arr index:(int)index {
    
    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    NSMutableArray *temp = [[NSMutableArray alloc]init];
    
    for (NSArray *Arr in arr) {
        [temp addObject:[Arr objectAtIndex:3]];//收盘价
    }
    
    for (int i = 0; i < temp.count; i++) {
        
        if ( (i + 1) < index) {
            [tempArr addObject:@"nil"];
        }else {
            
            NSString *tempStr = [NSString stringWithFormat:@"%f",[self STDArrayWithData:temp andRange:NSMakeRange(i + 1 - index, index)]];
            [tempArr addObject:tempStr];
        }
    }
    
    return tempArr;
    
}


#pragma mark 指标计算公式

//主图MA指标计算公式
/*
 最近N日的收盘价之和/N
 */
-(CGFloat)sumArrayWithData:(NSArray*)data andRange:(NSRange)ran{
    
    CGFloat value = 0;
    NSArray *newArray = [data objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:ran]];
    for (NSString *item in newArray) {
        value += [item floatValue];//收盘价的和
    }
    value = value / newArray.count;
    return value;
}

//求标准差

- (CGFloat)STDArrayWithData:(NSArray *)data andRange:(NSRange)ran {
    
    CGFloat Sumvalue = 0;
    CGFloat value = 0;
    NSArray *newArray = [data objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:ran]];
    
    for (NSString *item in newArray) {
        Sumvalue += pow([item floatValue], 2);
        value += [item floatValue];
    }
    
    CGFloat Sum = Sumvalue * newArray.count;//N倍的平方和
    CGFloat Poorvalue = (Sum - pow(value, 2)) / pow(newArray.count, 2);
    double lastValue = sqrt(Poorvalue);
    
    //    for (NSString *item in newArray) {
    //        value += [item floatValue];
    //    }
    //
    //    CGFloat ave = value / newArray.count;
    //
    //    for (NSString *item in newArray) {
    //        Sumvalue += pow([item floatValue] - ave, 2);
    //    }
    //
    //    double lastValue = sqrt(Sumvalue / newArray.count);
    
    return lastValue;
    
}

#pragma mark 处理两个数组(计算主图ENV指标,计算副图BIAS指标)
/*
 ENV:
 UP : MA(CLOSE,N)*1.06;
 LOWER : MA(CLOSE,N)*0.94;
 MID:(UP+LOWER)/2;
 */
/*
 BIAS:
 BIAS1 : (CLOSE-MA(CLOSE,L1))/MA(CLOSE,L1)*100;
 BIAS2 : (CLOSE-MA(CLOSE,L2))/MA(CLOSE,L2)*100;
 */

- (NSMutableArray *)handleWithArr:(NSArray *)arr Array:(NSArray *)newArr index:(int)idx{
    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < arr.count; i++) {
        
        if (idx == 0) {
            
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else{
                CGFloat value = [arr[i] floatValue] + [newArr[i] floatValue] * [self.BOLLP intValue];//BOLL 参数P默认为2
                [tempArr addObject:[NSString stringWithFormat:@"%f",value]];
            }
            
        }else if(idx == 1){
            
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else{
                
                CGFloat value = [arr[i] floatValue] - [newArr[i] floatValue] * [self.BOLLP intValue];//BOLL 参数P默认为2
                
                [tempArr addObject:[NSString stringWithFormat:@"%f",value]];
            }
            
        }else if(idx == 2){
            
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else{
                
                CGFloat value = [arr[i] floatValue] * 1.06;     //ENV
                [tempArr addObject:[NSString stringWithFormat:@"%f",value]];
            }
            
        }else if (idx == 3){
            
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else{
                CGFloat value = [arr[i] floatValue] * 0.94;     //ENV
                [tempArr addObject:[NSString stringWithFormat:@"%f",value]];
                
            }
            
        }else if (idx == 4) {
            
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else{
                
                CGFloat value = ([arr[i] floatValue]  + [newArr[i] floatValue]) / 2; //ENV
                [tempArr addObject:[NSString stringWithFormat:@"%f",value]];
            }
            
        }else if (idx == 5){
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else{
                CGFloat shortValue = [arr[i] floatValue];//MACD  DIF
                CGFloat longValue = [newArr[i] floatValue];
                CGFloat poor = shortValue - longValue;
                [tempArr addObject:[NSString stringWithFormat:@"%f",poor]];
            }
            
        }else if(idx == 6) {
            
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else {
                
                CGFloat shortValue = [arr[i] floatValue];//MACD  DIF
                CGFloat longValue = [newArr[i] floatValue];//MACD  DEA
                CGFloat poor = (shortValue - longValue) * 2;
                [tempArr addObject:[NSString stringWithFormat:@"%f",poor]];
            }
            
        }else if (idx == 7){
            
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else {
                
                CGFloat close = [arr[i] floatValue];//BIAS  CLOSE
                CGFloat MAValue = [newArr[i] floatValue];//BIAS  MA
                CGFloat poor = (close - MAValue) / MAValue * 100;
                [tempArr addObject:[NSString stringWithFormat:@"%f",poor]];
            }
            
        }else if (idx == 8) {
            if ([arr[i] isEqualToString:@"nil"] || [newArr[i] isEqualToString:@"nil"]) {
                [tempArr addObject:@"nil"];
            }else {
                
                CGFloat Kvalue = [arr[i] floatValue];//KDJ  K
                CGFloat Dvalue = [newArr[i] floatValue];//KDJ  D
                CGFloat poor = 3 * Kvalue - 2 * Dvalue;// KDJ   J
                [tempArr addObject:[NSString stringWithFormat:@"%f",poor]];
            }
            
        }
    }
    
    return tempArr;
}


#pragma mark 计算副图MACD指标
/*
 
 DIF : EMA(CLOSE,SHORT) - EMA(CLOSE,LONG);
 DEA : EMA(DIF,M);
 MACD : 2*(DIF-DEA), COLORSTICK;
 */

//副图MACD 指标  DIF
- (NSMutableArray *)EMAdataWithArr:(NSMutableArray *)arr index:(int)SHORT index:(int)LONG {

    NSMutableArray *closePrices = [[NSMutableArray alloc]init];
    for (NSArray *Arr in self.data) {
        [closePrices addObject:Arr[3]];//收盘价
    }
    
    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    NSMutableArray *temp = [[NSMutableArray alloc]init];
    NSMutableArray *newArr = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < closePrices.count; i++) {
        
        if (i < SHORT - 1) {
            [tempArr addObject:@"nil"];
            
        }else {
            
            CGFloat shortValue = 0;
            NSArray *price = [closePrices objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(i - SHORT + 1, SHORT)]];
            for (int j = 1; j <= price.count; j++) {
                
                CGFloat x = [price[j - 1] floatValue];
                shortValue += x * j;
            }
            shortValue = shortValue / ((SHORT * (SHORT + 1)) / 2);
            [tempArr addObject:[NSString stringWithFormat:@"%f",shortValue]];
            
        }
        
        if (i < LONG - 1) {
            
            [temp addObject:@"nil"];
            
        }else {
            
            CGFloat longValue = 0;
            
            NSArray *longs = [closePrices objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(i - LONG + 1, LONG)]];
            for (int j = 1; j <= longs.count; j++) {
                
                CGFloat x = [longs[j - 1] floatValue];
                longValue += x * j;
            }
            longValue = longValue / ((LONG * (LONG + 1)) / 2);
            [temp addObject:[NSString stringWithFormat:@"%f",longValue]];
            
        }
    }
    
    newArr = [self handleWithArr:tempArr Array:temp index:5];
    
    return newArr;
}


//副图指标 MACD DEA
- (NSMutableArray *)EMAdataWithArr:(NSMutableArray *)arr index:(int)idx {
    
    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    for (int i = 0; i < arr.count; i++) {
        
        if (i < [self.MACDLONG intValue] + [self.MACDM intValue] - 2) {
            [tempArr addObject:@"nil"];
            continue;
        }else {
            
            CGFloat Value = 0;
            NSArray *price = [arr objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(i + 1 - idx, idx)]];
            for (int j = 1; j <= price.count; j++) {
                
                CGFloat x = [price[j - 1] floatValue];
                Value += x * j;
            }
            Value = Value / ((idx * (idx + 1)) / 2);
            [tempArr addObject:[NSString stringWithFormat:@"%f",Value]];
            
        }
    }
    
    return tempArr;
    
}


#pragma mark 计算副图指标KDJ   RSV
//副图指标  KDJ RSV
/*
 RSV:=(CLOSE-LLV(LOW,N))/(HHV(HIGH,N)-LLV(LOW,N))*100;
 K:SMA(RSV,M1,1);
 D:SMA(K,M2,1);
 J:3*K-2*D;
 
 KDJ数值的计算为例，其计算公式为   n日RSV=（Cn－Ln）÷（Hn－Ln）×100   
 式中，Cn为第n日收盘价；Ln为n日内的最低价；Hn为n日内的最高价。RSV值始终在1—100间波动。

 */
- (NSMutableArray *)RSVdataWithArr:(NSMutableArray *)arr index:(int)idx {
    
    NSMutableArray *temp = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < arr.count; i++) {
        if (i < idx - 1) {
            [temp addObject:@"nil"];
            continue;
        }else {
            NSArray *price = [arr objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(i + 1 - idx, idx)]];
            CGFloat    max = [[price[0] objectAtIndex:1]floatValue];//最高价
            CGFloat    min = [[price[0] objectAtIndex:2] floatValue];//最低价
            
            for (int j = 0; j < price.count; j++) {
                max = fmax([[price[j] objectAtIndex:1] floatValue], max);
                min = fmin([[price[j] objectAtIndex:2] floatValue], min);
            }
            
            CGFloat value = ([[arr[i] objectAtIndex:3] floatValue] - min) / (max - min) * 100;
            [temp addObject:[NSString stringWithFormat:@"%f",value]];
            
        }
    }
    
    return temp;
}


#pragma mark  计算副图指标KDJ
/*
 当日K值=2/3×前一日K值＋1/3×当日RSV
 当日D值=2/3×前一日D值＋1/3×当日K值
 */
//副图指标  KDJ K
- (NSMutableArray *)KDJDataForIndi:(NSArray *)arr index:(int)idx index:(int)index {

    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < arr.count; i++) {
        if (i < idx + index - 2) {
            [tempArr addObject:@"nil"];
        }else {
            
            NSString *tempStr = [NSString stringWithFormat:@"%f",[self sumArrayWithData:arr andRange:NSMakeRange(i + 1 - idx, idx)]];
            [tempArr addObject:tempStr];
            
        }
    }
    return tempArr;
    
}

#pragma mark  计算副图指标RSI
/*
 
 RS(相对强度)=N日内收盘价涨数和之均值÷N日内收盘价跌数和之均值
 
 　　RSI(相对强弱指标)=100－100÷(1+RS)
 
 　　以14日RSI指标为例，从当起算，倒推包括当日在内的15个收盘价，以每一日的收盘价减去上一日的收盘价，得到14个数值，这些数值有正有负。这样，RSI指标的计算公式具体如下：
 
 　　A=14个数字中正数之和
 
 　　B=14个数字中负数之和乘以(—1)
 
 　　RSI(14)=A÷(A＋B)×100
 
 　　式中：A为14日中股价向上波动的大小
 
 　　B为14日中股价向下波动的大小
 
 　　A＋B为股价总的波动大小
 */
- (NSMutableArray *)RSIDataWithArr:(NSMutableArray *)arr index:(int)idx {

    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    for (int i = 0; i < arr.count; i++) {
        if (i < idx) {
            [tempArr addObject:@"nil"];
            continue;
        }else {
            
            CGFloat sumValue = 0;
            CGFloat sum = 0;
            
            NSArray *closeArr = [arr objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(i - idx , idx + 1)]];
            for (int j = 0;  j < closeArr.count - 1; j++) {
                CGFloat before = [[closeArr[j] objectAtIndex:3] floatValue];//前一日的收盘价
                CGFloat last = [[closeArr[j + 1] objectAtIndex:3] floatValue];//后一日的收盘价
                sumValue += fmax(last - before, 0);
                sum += fabs(last - before);
                
            }
            
            CGFloat ratio = sumValue / sum * 100;
            [tempArr addObject:[NSString stringWithFormat:@"%f",ratio]];
        }
    }
    
    return tempArr;
}


#pragma mark 计算副图指标WR
//副图指标WR
/*
 WR:100-100*(HHV(HIGH,N)-CLOSE)/(HHV(HIGH,N)-LLV(LOW,N));
 
 WR:100 -（Hn－Ct）/(Hn－Ln)×100。
 Ct为当天的收盘价；Hn和Ln是最近N日内（包括当天）出现的最高价和最低价
 N为14（最小1，最大100）
 */
- (NSMutableArray *)WRdataWithArr:(NSMutableArray *)arr index:(int)idx {
    
    NSMutableArray *temp = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < arr.count; i++) {
        if (i < idx - 1) {
            [temp addObject:@"nil"];
            continue;
        }else {
            NSArray *price = [arr objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(i + 1 - idx, idx)]];
            CGFloat    max = [[price[0] objectAtIndex:1]floatValue];//最高价
            CGFloat    min = [[price[0] objectAtIndex:2] floatValue];//最低价
            
            for (int j = 0; j < price.count; j++) {
                
                if ([[price[j] objectAtIndex:1] floatValue] > max) {
                    max = [[price[j] objectAtIndex:1] floatValue];
                }
                if ([[price[j] objectAtIndex:2] floatValue] < min) {
                    min = [[price[j] objectAtIndex:2] floatValue];
                }
            }
            
            CGFloat value = 100 - 100 * (max - [[arr[i] objectAtIndex:3] floatValue]) / (max - min);
            [temp addObject:[NSString stringWithFormat:@"%f",value]];
            
        }
    }
    
    return temp;
    
}


#pragma mark 画指标线
- (void)drawLine {
    
    //主图
    //MA指标线
    if ([self.indo isEqualToString:@"MA"]) {
        [self drawLineWithArray:valueUper Index:4 isMain:YES];  //MA5
        [self drawLineWithArray:valueMider Index:9 isMain:YES]; //MA10
        [self drawLineWithArray:valueLower Index:19 isMain:YES]; //MA20
    }else if ([self.indo isEqualToString:@"BOLL"]) {
        //BOLL指标线
        [self drawLineWithArray:valueUper Index:0 isMain:YES]; //UP
        [self drawLineWithArray:valueMider Index:1 isMain:YES]; //MID
        [self drawLineWithArray:valueLower Index:2 isMain:YES]; //LOWER
        
    }else if ([self.indo isEqualToString:@"ENV"]) {
        //ENV指标线
        [self drawLineWithArray:valueUper Index:0 isMain:YES];//UP
        [self drawLineWithArray:valueMider Index:1 isMain:YES];//MID
        [self drawLineWithArray:valueLower Index:2 isMain:YES];//LOWER
        
    }
    
    //副图
    if ([self.ViceIndo isEqualToString:@"MACD"]) {
        
        NSArray *tempArray = [self changeMAPointWithData:valueVolLower andMA:1];
        [self drawColuWithArr:tempArray];//画柱状体
        
        [self drawLineWithArray:valueVolUper Index:1 isMain:NO];//MACD  DIF
        [self drawLineWithArray:valueVolMider Index:19 isMain:NO];//MACD  DEA
    }else if ([self.ViceIndo isEqualToString:@"BIAS"]) {
        [self drawLineWithArray:valueVolUper Index:1 isMain:NO];//BIAS1
        [self drawLineWithArray:valueVolMider Index:19 isMain:NO];//BIAS2
        
    }else if ([self.ViceIndo isEqualToString:@"KDJ"]) {
        
        [self drawLineWithArray:valueVolUper Index:1 isMain:NO];//KDJ  K
        [self drawLineWithArray:valueVolMider Index:19 isMain:NO];//KDJ  D
        [self drawLineWithArray:valueVolLower Index:9 isMain:NO];//KDJ J
    }else if ([self.ViceIndo isEqualToString:@"RSI"]) {
        [self drawLineWithArray:valueVolUper Index:1 isMain:NO];//RSI  RSI1
        [self drawLineWithArray:valueVolMider Index:19 isMain:NO];//RSI  RSI2
        [self drawLineWithArray:valueVolLower Index:9 isMain:NO];//RSI RSI3
        
    }else if ([self.ViceIndo isEqualToString:@"WR"]){
        
        [self drawLineWithArray:valueVolUper Index:1 isMain:NO];
    }
    
}


//画指标线
- (void)drawLineWithArray:(NSArray *)arr Index:(int)idx isMain:(BOOL)isMain{
 
    //主图指标
    if (isMain) {
        
        NSArray *tempArr = [self changeMAPointWithData:arr andMA:0]; // 把主图指标换算成实际坐标数组
        CGContextRef context = UIGraphicsGetCurrentContext();// 获取绘图上下文
        CGContextSetLineWidth(context, 0.5);//线宽
        CGContextSetLineDash(context, 0, 0, 0);
        CGContextSetShouldAntialias(context, YES);//设置图形上下文的抗锯齿开启或关闭
        
        if (idx == 4) {
            //            CGContextSetRGBStrokeColor(context, 0, 0, 225, 1.0);// 设置颜色  MA5蓝色
            CGContextSetRGBStrokeColor(context, 36 / 255.0, 133 / 255.0, 189 / 255.0, 1.0);
            
        }else if(idx == 9){
            
            //            CGContextSetRGBStrokeColor(context, 0.5, 0, 0.5, 1.0);// MA10紫色
            CGContextSetRGBStrokeColor(context, 251 / 255.0, 75 / 255.0, 146 / 255.0, 1.0);
            
        }else if(idx == 19) {
            //            CGContextSetRGBStrokeColor(context, 1.0, 1.0, 0, 1.0);// MA20 黄色
            CGContextSetRGBStrokeColor(context, 246 / 255.0, 174 / 255.0, 2 / 255.0, 1.0);
            
        }else if (idx == 0) {
            
            //            CGContextSetRGBStrokeColor(context, 1.0, 1.0, 0, 1.0);// BOOL  UP 黄色
            CGContextSetRGBStrokeColor(context, 246 / 255.0, 174 / 255.0, 2 / 255.0, 1.0);
            
        }else if (idx == 1){
            
            CGContextSetRGBStrokeColor(context, 246 / 255.0, 174 / 255.0, 2 / 255.0, 1.0);// BOOL  MID 白色
            
        }else if (idx == 2) {
            
            //            CGContextSetRGBStrokeColor(context, 0.5, 0, 0.5, 1.0);// BOOL LOWER 紫色
            CGContextSetRGBStrokeColor(context, 251 / 255.0, 75 / 255.0, 146 / 255.0, 1.0);
        }
        
        if (tempArr.count > 0) {
            
            for (int i = 0;  i < tempArr.count - 1; i++) {
                
                CGMutablePathRef path = CGPathCreateMutable();
                CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);
                
                //                NSString *item = tempArr[i];
                //                CGPoint currtntPoint = CGPointFromString(item);
                NSValue *item = tempArr[i];
                CGPoint currtntPoint = [item CGPointValue];
                
                //                NSString *next = tempArr[i+1];
                //                CGPoint nextPoint = CGPointFromString(next);
                NSValue *next = tempArr[i+1];
                CGPoint nextPoint = [next CGPointValue];
                
                if (currtntPoint.y <= self.yHeight  + self.padingY && currtntPoint.y >= self.padingY
                    && nextPoint.y <= self.yHeight  + self.padingY && nextPoint.y >= self.padingY) {
                    
                    //                    CGContextMoveToPoint(context, currtntPoint.x, currtntPoint.y);//起点
                    CGPathMoveToPoint(path, &transform, currtntPoint.x, currtntPoint.y);
                }
                //                CGContextAddLineToPoint(context, nextPoint.x, nextPoint.y);//下一点
                CGPathAddLineToPoint(path, &transform,nextPoint.x , nextPoint.y);
                
                CGContextAddPath(context, path);
                CGPathRelease(path);
                CGContextStrokePath(context);
                
            }
        }
        
        //副图指标
    }else {
        
        NSArray *tempArray = [self changeMAPointWithData:arr andMA:1];//把副图指标换算成实际坐标数组
        CGContextRef context = UIGraphicsGetCurrentContext();// 获取绘图上下文
        CGContextSetLineWidth(context, 0.5);//线宽
        CGContextSetShouldAntialias(context, YES);//设置图形上下文的抗锯齿开启或关闭
        
        if (idx == 4) {
            //            CGContextSetRGBStrokeColor(context, 0, 0, 225, 1.0);// 设置颜色  MA5蓝色
            CGContextSetRGBStrokeColor(context, 36 / 255.0, 133 / 255.0, 189 / 255.0, 1.0);
            
        }else if(idx == 9){
            
            //            CGContextSetRGBStrokeColor(context, 0.5, 0, 0.5, 1.0);// MA10紫色
            CGContextSetRGBStrokeColor(context, 251 / 255.0, 75 / 255.0, 146 / 255.0, 1.0);
            
        }else if(idx == 19) {
            //            CGContextSetRGBStrokeColor(context, 1.0, 1.0, 0, 1.0);// MA20 黄色
            CGContextSetRGBStrokeColor(context, 246 / 255.0, 174 / 255.0, 2 / 255.0, 1.0);
            
        }else if (idx == 0) {
            
            //            CGContextSetRGBStrokeColor(context, 1.0, 1.0, 0, 1.0);// BOOL  UP 黄色
            CGContextSetRGBStrokeColor(context, 246 / 255.0, 174 / 255.0, 2 / 255.0, 1.0);
            
        }else if (idx == 1){
            
            CGContextSetRGBStrokeColor(context, 246 / 255.0, 174 / 255.0, 2 / 255.0, 1.0);// BOOL  MID 白色
        }else if (idx == 2) {
            
            //            CGContextSetRGBStrokeColor(context, 0.5, 0, 0.5, 1.0);// BOOL LOWER 紫色
            CGContextSetRGBStrokeColor(context, 251 / 255.0, 75 / 255.0, 146 / 255.0, 1.0);
        }
        
        if (tempArray.count > 0) {
            
            for (int i = 0;  i < tempArray.count - 1; i++) {
                
                CGMutablePathRef path = CGPathCreateMutable();
                CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);
                
                //                NSString *item = tempArray[i];
                //                CGPoint currtntPoint = CGPointFromString(item);
                NSValue *item = tempArray[i];
                CGPoint currtntPoint = [item CGPointValue];
                
                //                NSString *next = tempArray[i+1];
                //                CGPoint nextPoint = CGPointFromString(next);
                NSValue *next = tempArray[i+1];
                CGPoint nextPoint = [next CGPointValue];
                
                if (currtntPoint.y > self.bottomY + self.bottomHeight) {
                    currtntPoint.y = self.bottomHeight + self.bottomY;
                }
                if (currtntPoint.y < self.bottomY) {
                    
                    currtntPoint.y = self.bottomY;
                }
                if (nextPoint.y >self.bottomY + self.bottomHeight) {
                    
                    nextPoint.y = self.bottomHeight + self.bottomY;
                }
                if (nextPoint.y < self.bottomY) {
                    nextPoint.y = self.bottomY;
                }
                
                //                CGContextMoveToPoint(context, currtntPoint.x, currtntPoint.y);//起点
                //                CGContextAddLineToPoint(context, nextPoint.x, nextPoint.y);//下一点
                //                CGContextStrokePath(context);
                CGPathMoveToPoint(path, &transform, currtntPoint.x, currtntPoint.y);
                CGPathAddLineToPoint(path, &transform,nextPoint.x , nextPoint.y);
                CGContextAddPath(context, path);
                CGPathRelease(path);
                CGContextStrokePath(context);
                
            }
        }
    }
}


//处理MA指标数组
-(NSArray*)changeMAPointWithData:(NSArray*)array andMA:(int)MAIndex{
    
    //主图指标
    if (MAIndex == 0) {
        
        NSMutableArray *temp = [[NSMutableArray alloc]init];
        CGFloat PointStartX = self.kLineWidth / 2 + self.padingX; // 起始点坐标
        for (int i = 0; i < array.count; i++) {
            
            if ([array[i] isEqualToString:@"nil"]) {
                PointStartX += self.kLineWidth+self.kLinePadding; // 生成下一个点的x轴
                continue;
            }
            
            CGFloat currentValue = [array[i] floatValue];// 得到指标值
            // 换算成实际的坐标
            CGFloat currentPointY = self.yHeight - ((currentValue - self.minValue) / (self.maxValue - self.minValue) * self.yHeight) + self.padingY;
            
            CGPoint currentPoint =  CGPointMake(PointStartX, currentPointY); // 换算到当前的坐标值
            //            [temp addObject:NSStringFromCGPoint(currentPoint)]; // 把坐标添加进新数组
            [temp addObject:[NSValue valueWithCGPoint:currentPoint]];
            
            PointStartX += self.kLineWidth+self.kLinePadding; // 生成下一个点的x轴
        }
        
        return temp;
        //副图指标
    }else if (MAIndex == 1) {
        
        NSMutableArray *temp = [[NSMutableArray alloc]init];
        CGFloat PointStartX = self.kLineWidth / 2 + self.padingX; // 起始点坐标
        for (int i = 0; i < array.count; i++) {
            
            if ([array[i] isEqualToString:@"nil"]) {
                PointStartX += self.kLineWidth+self.kLinePadding; // 生成下一个点的x轴
                continue;
            }
            
            CGFloat currentValue = [array[i] floatValue];// 得到指标值
            
            if (self.volMinValue == self.volMaxValue) {
                continue;
            }
            
            // 换算成实际的坐标
            CGFloat currentPointY = self.bottomHeight + self.bottomY - ((currentValue - self.volMinValue) / (self.volMaxValue - self.volMinValue) * self.bottomHeight);
            
            //            if (self.volMinValue == self.volMaxValue) {
            //                currentPointY = -1.0;
            //            }
            
            CGPoint currentPoint =  CGPointMake(PointStartX, currentPointY); // 换算到当前的坐标值
            //            [temp addObject:NSStringFromCGPoint(currentPoint)]; // 把坐标添加进新数组
            [temp addObject:[NSValue valueWithCGPoint:currentPoint]];
            
            PointStartX += self.kLineWidth+self.kLinePadding; // 生成下一个点的x轴
        }
        
        return temp;
        
    }
    return 0;
    
}

#pragma mark画柱状体方法
//画柱状体方法
- (void)drawColuWithArr:(NSArray *)arr {
    
    for (int i = 0; i < arr.count; i++) {
        //        NSString *item = arr[i];
        //        CGPoint currtntPoint = CGPointFromString(item);
        NSValue *item = arr[i];
        CGPoint currtntPoint = [item CGPointValue];
        
        //排除开、高、低、收价一样的情况
        if (currtntPoint.y == 0 || currtntPoint.y < self.bottomY) {
            continue;
        }
        
        if (currtntPoint.y < self.bottomY + self.bottomHeight / 2) {
            //大于0，柱状体为红色
            CGContextRef context = UIGraphicsGetCurrentContext();// 获取绘图上下文
            CGContextSetLineWidth(context,self. kLineWidth);//线宽
            CGContextSetShouldAntialias(context, YES);//设置图形上下文的抗锯齿开启或关闭
            //            CGContextSetRGBStrokeColor(context, 1.0, 0, 0, 1.0);// 红色
            CGContextSetRGBStrokeColor(context, 233 / 255.0, 48 / 255.0, 48 / 255.0, 1.0);
            
            CGPoint startPoint = CGPointMake(currtntPoint.x, self.bottomY + self.bottomHeight / 2);
            const CGPoint point[] = {startPoint,currtntPoint};
            CGContextStrokeLineSegments(context, point, 2);//绘制两点连线
        }else {
            //小于0，柱状体为绿色
            CGContextRef context = UIGraphicsGetCurrentContext();// 获取绘图上下文
            CGContextSetLineWidth(context,self. kLineWidth);//线宽
            CGContextSetShouldAntialias(context, YES);//设置图形上下文的抗锯齿开启或关闭
            //            CGContextSetRGBStrokeColor(context, 0, 1.0, 0, 1.0);// 绿色
            CGContextSetRGBStrokeColor(context, 84 / 255.0 , 184 / 255.0, 73 / 255.0, 1.0);
            
            CGPoint startPoint = CGPointMake(currtntPoint.x, self.bottomY + self.bottomHeight / 2);
            const CGPoint point[] = {startPoint,currtntPoint};//常量数组,包含两个点
            CGContextStrokeLineSegments(context, point, 2);//绘制两点连线
            
            
        }
    }
    
}

#pragma mark  画K线
- (void)drawKline {
    
    CGContextRef context = UIGraphicsGetCurrentContext();// 获取绘图上下文
    
    NSArray *KtempArray = [self changeKPointWithData:self.Kdata];//将行情数据转化为坐标
    
    for (NSArray *item in KtempArray) {
        
        CGPoint heightPoint,lowPoint,openPoint,closePoint;
        //        heightPoint = CGPointFromString([item objectAtIndex:1]);//最高价坐标
        //        lowPoint = CGPointFromString([item objectAtIndex:2]);//最低价坐标
        //        openPoint = CGPointFromString([item objectAtIndex:0]);//开盘价坐标
        //        closePoint = CGPointFromString([item objectAtIndex:3]);//收盘价坐标
        heightPoint = [[item objectAtIndex:1] CGPointValue];
        lowPoint = [[item objectAtIndex:2] CGPointValue];
        openPoint = [[item objectAtIndex:0] CGPointValue];
        closePoint = [[item objectAtIndex:3] CGPointValue];
        
        //画K线
        [self drawKWithContext:context height:heightPoint Low:lowPoint open:openPoint close:closePoint width:self.kLineWidth];
    }
    
    //横屏状态下横坐标显示时间或日期
    if (_isShowLevelTime) {
        //显示时间
        
//         CGContextSetLineDash(context, 0, 0, 0);
        
        CGFloat value = self.xWidth / 4;
        int idx = 0;
        
        CGFloat secondValue = self.xWidth / 2;
        int secIdx = 0;
        
        CGFloat thirdValue = 3 * self.xWidth / 4;
        int thrIdx = 0;
        
        for (int i = 0; i < KtempArray.count; i++) {
            NSArray *item = KtempArray[i];
            CGFloat  PointX = [[item objectAtIndex:1] CGPointValue].x;
            if (fabs(PointX - self.padingX - self.xWidth / 4) < value) {
                
                value = fabs(PointX - self.padingX - self.xWidth / 4);
                idx = i;
                
            }
            
            if (fabs(PointX - self.padingX - self.xWidth / 2) < secondValue) {
                secondValue = fabs(PointX - self.padingX - self.xWidth / 2);
                secIdx = i;
            }
            
            if (fabs(PointX - self.padingX - 3 * self.xWidth / 4) < thirdValue) {
                thirdValue = fabs(PointX - self.padingX - 3 *  self.xWidth / 4);
                thrIdx = i;
            }
        }
        
        NSArray *item = KtempArray[idx];
        NSString *timeStr = [[item objectAtIndex:4] substringFromIndex:11]; //01:30
        if (_kLineTypeStr > 3000) {
            timeStr = [[item objectAtIndex:4] substringToIndex:10];
            timeStr = [self handledateWith:[timeStr substringFromIndex:2]];
        }
        CGRect contentRect = CGRectMake(0, 0, 0, 0);
        
        NSArray *secItem = KtempArray[secIdx];
        NSString *secTimeStr = [[secItem objectAtIndex:4] substringFromIndex:11];
        if (_kLineTypeStr > 3000) {
            secTimeStr = [[secItem objectAtIndex:4] substringToIndex:10];
            secTimeStr = [self handledateWith:[secTimeStr substringFromIndex:2]];
        }
        
        
        NSArray *thrItem = KtempArray[thrIdx];
        NSString *thrTimeStr = [[thrItem objectAtIndex:4] substringFromIndex:11];
        if (_kLineTypeStr > 3000) {
            thrTimeStr = [[thrItem objectAtIndex:4] substringToIndex:10];
            thrTimeStr = [self handledateWith:[thrTimeStr substringFromIndex:2]];
        }
        
        
        if (isPad) {
            contentRect = [timeStr boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:PadLevelAttrs context:nil];
        }else {
            contentRect = [timeStr boundingRectWithSize:CGSizeMake(150, 50) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:LevelAttrs context:nil];
        }
        
        KfirstLab.hidden = NO;
        KfirstLab.frame = CGRectMake(self.padingX + self.xWidth / 4 - contentRect.size.width / 2, self.yHeight + self.padingY, contentRect.size.width + 5,contentRect.size.height);
        KfirstLab.text = timeStr;
        KfirstLab.textColor = [@"#5B646B" hexStringToColor];
        
        KsecondLab.hidden = NO;
        KsecondLab.frame = CGRectMake(self.padingX + self.xWidth / 2 - contentRect.size.width / 2, self.yHeight + self.padingY, contentRect.size.width + 5, contentRect.size.height);
        KsecondLab.text = secTimeStr;
         KsecondLab.textColor = [@"#5B646B" hexStringToColor];
        
        KthirdLab.hidden = NO;
        KthirdLab.frame = CGRectMake(self.padingX + 3 * self.xWidth / 4 - contentRect.size.width / 2, self.yHeight + self.padingY, contentRect.size.width + 5, contentRect.size.height);
        KthirdLab.text = thrTimeStr;
         KthirdLab.textColor = [@"#5B646B" hexStringToColor];

        
    }
    
}


#pragma mark 把股市数据换算成实际的点坐标数组
-(NSArray*)changeKPointWithData:(NSArray*)array{
    
    if (pointArray.count > 0) {
        [pointArray removeAllObjects];
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    CGFloat PointStartX = self.kLineWidth/2 + self.padingX; // 起始点坐标
    
    for (int i = 0;i < array.count;i++) {
        NSArray *item = array[i];
        CGFloat heightvalue = [[item objectAtIndex:1] floatValue];// 得到最高价
        CGFloat lowvalue = [[item objectAtIndex:2] floatValue];// 得到最低价
        CGFloat openvalue = [[item objectAtIndex:0] floatValue];// 得到开盘价
        CGFloat closevalue = [[item objectAtIndex:3] floatValue];// 得到收盘价
        CGFloat yHeight = self.maxValue - self.minValue ; // y的价格高度
        CGFloat yViewHeight = self.yHeight ;// y的实际像素高度
        // 换算成实际的坐标
        CGFloat heightPointY = yViewHeight * (1 - (heightvalue - self.minValue) / yHeight) + self.padingY;
        CGPoint heightPoint =  CGPointMake(PointStartX, heightPointY); // 最高价换算为实际坐标值
        CGFloat lowPointY = yViewHeight * (1 - (lowvalue - self.minValue) / yHeight) + self.padingY;
        CGPoint lowPoint =  CGPointMake(PointStartX, lowPointY); // 最低价换算为实际坐标值
        CGFloat openPointY = yViewHeight * (1 - (openvalue - self.minValue) / yHeight) + self.padingY;
        CGPoint openPoint =  CGPointMake(PointStartX, openPointY); // 开盘价换算为实际坐标值
        CGFloat closePointY = yViewHeight * (1 - (closevalue - self.minValue) / yHeight) + self.padingY;
        CGPoint closePoint =  CGPointMake(PointStartX, closePointY); // 收盘价换算为实际坐标值
        // 实际坐标组装为数组
        //        NSArray *currentArray = [[NSArray alloc] initWithObjects:
        //                                 NSStringFromCGPoint(openPoint),//开盘价坐标
        //                                 NSStringFromCGPoint(heightPoint),//最高价坐标
        //                                 NSStringFromCGPoint(lowPoint),//最低价坐标
        //                                 NSStringFromCGPoint(closePoint),//收盘价坐标
        //                                 [self.category objectAtIndex:[data indexOfObject:item]], // 保存日期时间
        //                                 [item objectAtIndex:0],//开盘价
        //                                 [item objectAtIndex:1],//最高价
        //                                 [item objectAtIndex:2],//最低价
        //                                 [item objectAtIndex:3], // 收盘价
        //                                 [Uper objectAtIndex:[data indexOfObject:item]],//主图指标
        //                                 [Mider objectAtIndex:[data indexOfObject:item]],//主图指标
        //                                 [Lower objectAtIndex:[data indexOfObject:item]],//主图指标
        //                                 [volUper objectAtIndex:[data indexOfObject:item]],//副图指标
        //                                 [volMider objectAtIndex:[data indexOfObject:item]],//副图指标
        //                                 nil];
        //        [tempArray addObject:currentArray]; // 把坐标添加进新数组
        
        NSMutableArray *currentArray = [[NSMutableArray alloc]init];
        //        [currentArray addObject:NSStringFromCGPoint(openPoint)];//开盘价坐标
        [currentArray addObject:[NSValue valueWithCGPoint:openPoint]];
        //        [currentArray addObject:NSStringFromCGPoint(heightPoint)];//最高价坐标
        [currentArray addObject:[NSValue valueWithCGPoint:heightPoint]];
        //        [currentArray addObject:NSStringFromCGPoint(lowPoint)];//最低价坐标
        [currentArray addObject:[NSValue valueWithCGPoint:lowPoint]];
        //        [currentArray addObject:NSStringFromCGPoint(closePoint)];//收盘价坐标
        [currentArray addObject:[NSValue valueWithCGPoint:closePoint]];
        
        [currentArray addObject:[_cates objectAtIndex:i]];//保存日期时间
        [currentArray addObject:[item objectAtIndex:0]];//开盘价
        [currentArray addObject:[item objectAtIndex:1]];//最高价
        [currentArray addObject:[item objectAtIndex:2]];//最低价
        [currentArray addObject:[item objectAtIndex:3]];//收盘价
        [currentArray addObject:[valueUper objectAtIndex:i]];//主图指标
        [currentArray addObject:[valueMider objectAtIndex:i]];//主图指标
        [currentArray addObject:[valueLower objectAtIndex:i]];//主图指标
        [currentArray addObject:[valueVolUper objectAtIndex:i]];//副图指标
        if (valueVolMider.count > 0) {
            [currentArray addObject:[valueVolMider objectAtIndex:i]];//副图指标
        }
        if (valueVolLower.count > 0) {
            [currentArray addObject:[valueVolLower objectAtIndex:i]];//副图指标
        }
        [currentArray addObject:[valueApplyArray objectAtIndex:i]];//涨跌幅
        
        [tempArray addObject:currentArray];
        
        currentArray = Nil;
        PointStartX += self.kLineWidth+self.kLinePadding; // 生成下一个点的x轴
        
    }
    pointArray = tempArray;
    return tempArray;
}

#pragma mark 画一根K线

-(void)drawKWithContext:(CGContextRef)context height:(CGPoint)heightPoint Low:(CGPoint)lowPoint open:(CGPoint)openPoint close:(CGPoint)closePoint width:(CGFloat)width{
    
    CGContextSetShouldAntialias(context, NO);
    // 首先判断是绿的还是红的，根据开盘价和收盘价的坐标来计算
    BOOL isnil = NO;
    //设置颜色
    //    CGContextSetRGBStrokeColor(context, 1.0, 0, 0, 1.0);// 默认红色
    CGContextSetRGBStrokeColor(context, 233 / 255.0, 48 / 255.0, 48 / 255.0, 1.0);
    // 如果开盘价坐标在收盘价坐标上方 则为绿色 即空
    if (openPoint.y<closePoint.y) {
        isnil = YES;
        //        CGContextSetRGBStrokeColor(context, 0, 1.0, 0, 1.0);// 绿色
        CGContextSetRGBStrokeColor(context, 84 / 255.0, 184 / 255.0, 73 / 255.0, 1.0);
    }
    //
    if (openPoint.x == closePoint.x && openPoint.y == closePoint.y) {
        CGContextSetRGBStrokeColor(context, 184 / 255.0, 192 / 255.0, 200 / 255.0, 1.0);
    }
    // 首先画一个垂直的线包含上影线和下影线
    // 定义两个点 画两点连线
    CGContextSetLineWidth(context, 0.5); // 上下阴影线的宽度
    if (self.kLineWidth<=2) {
        CGContextSetLineWidth(context, 0.5); // 上下阴影线的宽度
    }
    const CGPoint points[] = {heightPoint,lowPoint};
    CGContextStrokeLineSegments(context, points, 2);  // 绘制线段（默认不绘制端点）
    
    // 再画中间的实体
    CGContextSetLineWidth(context, width); // 改变线的宽度ƒ
    CGFloat halfWidth = 0;//width/2;
    // 纠正实体的中心点为当前坐标
    openPoint = CGPointMake(openPoint.x-halfWidth, openPoint.y);
    closePoint = CGPointMake(closePoint.x-halfWidth, closePoint.y);
    
    // 开始画实体
    const CGPoint point[] = {openPoint,closePoint};
    CGContextStrokeLineSegments(context, point, 2);  // 绘制线段（默认不绘制端点）
    //CGContextSetLineCap(context, kCGLineCapSquare) ;// 设置线段的端点形状，方形
    //如果开盘价与收盘价一样，画一横线
    if (openPoint.x == closePoint.x && openPoint.y == closePoint.y) {
        CGPoint left = CGPointMake(closePoint.x - self.kLineWidth / 2, closePoint.y);
        CGPoint right = CGPointMake(closePoint.x + self.kLineWidth / 2, closePoint.y);
        
        CGContextSetLineWidth(context, 0.5);
        CGContextSetRGBStrokeColor(context, 184 / 255.0, 192 / 255.0, 200 / 255.0, self.alpha);
        
        const CGPoint point[] = {left,right};
        CGContextStrokeLineSegments(context, point, 2);
    }
}
#pragma mark 长按手势方法
//长按就开始生成十字线
-(void)gestureRecognizerHandle:(UILongPressGestureRecognizer*)longResture{
    
    if (pointArray.count == 0) {
        return;
    }
      _isShowHistory = YES;
    
    touchViewPoint = [longResture locationInView:self];
    // 手指长按开始时
    if(longResture.state == UIGestureRecognizerStateBegan){
        [self updateNib];
    }
    // 手指移动时候开始显示十字线
    if (longResture.state == UIGestureRecognizerStateChanged) {
        
        if (touchViewPoint.x >= self.padingX + self.kLineWidth / 2) {
            if (touchViewPoint.x < self.padingX + self.xWidth - 5) {
                [self isKPointWithPoint:touchViewPoint];
                
                //平移到最后一根K线，继续向右滑动
            }else {
                rangeTo++;
                if (rangeTo < self.data.count) {
                    
                }else {
                    
                    rangeTo = self.data.count;
                }
                
                [self setNeedsDisplay];
                [self isKPointWithPoint:touchViewPoint];
            }
            
            //平移到展示区域的第一根K线，继续向左滑动
        }else {
            
            rangeTo--;
            if (rangeTo > range) {
                
            }else {
                rangeTo = range;
            }
            
            [self setNeedsDisplay];
            [self isKPointWithPoint:touchViewPoint];
        }
        
    }
    
    
    // 手指离开的时候移除十字线
    if (longResture.state == UIGestureRecognizerStateEnded) {
        [movelineone removeFromSuperview];
        [movelinetwo removeFromSuperview];
        [movelinethree removeFromSuperview];
        
        movelineone = nil;
        movelinetwo = nil;
        movelinethree = nil;
        
        _isShowHistory = NO;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(hiddenData)]) {
            [self.delegate hiddenData];
        }
    }
}


//更新界面信息
-(void)updateNib{
    if (movelineone==Nil) {
        movelineone = [[UIView alloc] initWithFrame:CGRectMake(0,self.padingY, 0.5,self.yHeight)];
        movelineone.backgroundColor = [@"#c9c9c9" hexStringToColor];
        [self addSubview:movelineone];
        movelineone.hidden = YES;
    }
    if (movelinetwo==Nil) {
        movelinetwo = [[UIView alloc] initWithFrame:CGRectMake(self.padingX,0, self.xWidth,0.5)];
        movelinetwo.backgroundColor = [@"#c9c9c9" hexStringToColor];
        movelinetwo.hidden = YES;
        [self addSubview:movelinetwo];
    }
    if (movelinethree == Nil) {
        movelinethree = [[UIView alloc] initWithFrame:CGRectMake(self.bottomY,0, 0.5,self.bottomHeight)];
        movelinethree.backgroundColor = [@"#c9c9c9" hexStringToColor];
        movelinethree.hidden = YES;
        [self addSubview:movelinethree];
    }
    
    movelineone.frame = CGRectMake(touchViewPoint.x,self.padingY, 0.5,self.yHeight);
    movelinetwo.frame = CGRectMake(self.padingX,touchViewPoint.y, self.xWidth,0.5);
    movelinethree.frame = CGRectMake(touchViewPoint.x, self.bottomY, 0.5, self.bottomHeight);
    
    if ([systemVersionString floatValue] > 9.0) {
        movelineone.frame = CGRectMake(touchViewPoint.x,self.padingY, 1.0,
                                       self.yHeight);
        movelinetwo.frame = CGRectMake(self.padingX,touchViewPoint.y, self.xWidth,1.0);
        movelinethree.frame = CGRectMake(touchViewPoint.x, self.bottomY, 1.0, self.bottomHeight);
    }
    
    movelineone.hidden = NO;
    movelinetwo.hidden = NO;
    movelinethree.hidden = NO;
    
    [self isKPointWithPoint:touchViewPoint];
}


#pragma mark  十字星显示方法
//十字线上显示提示信息
-(void)isKPointWithPoint:(CGPoint)point{
    
    if (pointArray.count == 0) {
        return;
    }
    
    CGPoint firstPoint = [[pointArray[0] objectAtIndex:3] CGPointValue];
    CGFloat value = fabs(firstPoint.x - point.x);
    int idx = 0;
    
    for (int i = 0; i < pointArray.count; i++) {
        NSArray *item = pointArray[i];
        CGPoint itemPoint = [[item objectAtIndex:3] CGPointValue];
        
        if (fabs(itemPoint.x - point.x) < value) {
            value = fabs(itemPoint.x - point.x);
            idx = i;
        }
    }
    
    NSArray *item = pointArray[idx];
    CGPoint itemPoint = [[item objectAtIndex:3] CGPointValue];
    CGFloat itemPointX = itemPoint.x;
    
    //主图上的竖线
    movelineone.frame = CGRectMake(itemPointX,movelineone.frame.origin.y, movelineone.frame.size.width, movelineone.frame.size.height);
    //横线
    movelinetwo.frame = CGRectMake(movelinetwo.frame.origin.x,itemPoint.y, movelinetwo.frame.size.width, movelinetwo.frame.size.height);
    //副图上的竖线
    movelinethree.frame = CGRectMake(itemPointX,movelinethree.frame.origin.y, movelinethree.frame.size.width, movelinethree.frame.size.height);
    
    if ([self.indo isEqualToString:@"MA"]) {
        if (item.count < 12) {
            return;
        }
        uperLab.text = [self showtext:[NSString stringWithFormat:@"MA%@",self.MAUP] WithArr:item index:9];
        if ([[item objectAtIndex:9] isEqualToString:@"nil"]) {
            
            uperLab.text = [NSString stringWithFormat:@"MA%@:--",self.MAUP];
        }
        
        [uperLab sizeToFit];
        
        miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth, 20);
        miderLab.text = [self showtext:[NSString stringWithFormat:@"MA%@",self.MAMID] WithArr:item index:10];
        if ([[item objectAtIndex:10] isEqualToString:@"nil"]) {
            
            miderLab.text = [NSString stringWithFormat:@"MA%@:--",self.MAMID];
        }
        [miderLab sizeToFit];
        
        lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth, 20);
        lowerLab.text = [self showtext:[NSString stringWithFormat:@"MA%@",self.MALOW] WithArr:item index:11];
        if ([[item objectAtIndex:11] isEqualToString:@"nil"]) {
            
            lowerLab.text = [NSString stringWithFormat:@"MA%@:--",self.MALOW];
        }
        [lowerLab sizeToFit];
        
    }else if ([self.indo isEqualToString:@"BOLL"]) {
        
        if (item.count < 12) {
            return;
        }
        uperLab.text = [self showtext:@"UP" WithArr:item index:9];
        if ([[item objectAtIndex:9] isEqualToString:@"nil"]) {
            uperLab.text = @"UP:--";
        }
        [uperLab sizeToFit];
        
        miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth, 20);
        miderLab.text = [self showtext:@"MID" WithArr:item index:10];
        if ([[item objectAtIndex:10] isEqualToString:@"nil"]) {
            miderLab.text = @"MID:--";
        }
        [miderLab sizeToFit];
        
        lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth, 20);
        lowerLab.text = [self showtext:@"DN" WithArr:item index:11];
        if ([[item objectAtIndex:11] isEqualToString:@"nil"]) {
            lowerLab.text = @"DN:--";
        }
        [lowerLab sizeToFit];
        
    }else if ([self.indo isEqualToString:@"ENV"]) {
        
        if (item.count < 12) {
            return;
        }
        uperLab.text = [self showtext:@"UP" WithArr:item index:9];
        if ([[item objectAtIndex:9] isEqualToString:@"nil"]) {
            uperLab.text = @"UP:--";
        }
        [uperLab sizeToFit];
        
        miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth, 20);
        miderLab.text = [self showtext:@"MID" WithArr:item index:10];
        if ([[item objectAtIndex:10] isEqualToString:@"nil"]) {
            miderLab.text = @"MID:--";
        }
        [miderLab sizeToFit];
        
        lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth, 20);
        lowerLab.text = [self showtext:@"DN" WithArr:item index:11];
        if ([[item objectAtIndex:11] isEqualToString:@"nil"]) {
            lowerLab.text = @"DN:--";
        }
        [lowerLab sizeToFit];
        
    }
    
    if ([self.ViceIndo isEqualToString:@"MACD"]) {
        if (item.count  <15) {
            return;
        }
//        volUpLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"DIF: %.2f",[[item objectAtIndex:12]floatValue]]];
        volUpLab.text = [NSString stringWithFormat:@"DIF:%.2f",[[item objectAtIndex:12]floatValue]];
        if ([_closePrice integerValue] == 4) {
            
//            volUpLab.text = [self showtext:@"DIF" WithArr:item index:12];
             volUpLab.text = [NSString stringWithFormat:@"DIF:%.4f",[[item objectAtIndex:12]floatValue]];
        }
        if ([[item objectAtIndex:12] isEqualToString:@"nil"]) {
            volUpLab.text = @"DIF:--";
        }
        [volUpLab sizeToFit];
        
//        volMidLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"DEA: %.2f",[[item objectAtIndex:13]floatValue]]];
        volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth, 20);
        volMidLab.text = [NSString stringWithFormat:@"DEA:%.2f",[[item objectAtIndex:13]floatValue]];
        if ([_closePrice integerValue] == 4) {
            
//            volMidLab.text = [self showtext:@"DEA" WithArr:item index:13];
            volMidLab.text = [NSString stringWithFormat:@"DEA:%.4f",[[item objectAtIndex:13]floatValue]];
        }
        if ([[item objectAtIndex:13] isEqualToString:@"nil"]) {
            volMidLab.text = @"DEA:--";
        }
        [volMidLab sizeToFit];
        
        volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth, 20);
//        volLowLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"MACD: %.2f",[[item objectAtIndex:14]floatValue]]];
        volLowLab.text = [NSString stringWithFormat:@"MACD:%.2f",[[item objectAtIndex:14]floatValue]];
        if ([_closePrice integerValue] == 4) {
            
//            volLowLab.text = [self showtext:@"MACD" WithArr:item index:14];
            volLowLab.text = [NSString stringWithFormat:@"MACD:%.4f",[[item objectAtIndex:14]floatValue]];
        }
        if ([[item objectAtIndex:14] isEqualToString:@"nil"]) {
            volLowLab.text = @"MACD:--";
        }
        if ([[item objectAtIndex:14] floatValue] > 0) {
            volLowLab.textColor = [@"#e93030" hexStringToColor]; //MACD 红色

        }else {
            volLowLab.textColor = [@"#45943e" hexStringToColor]; //MACD 绿色
                    }
        [volLowLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"BIAS"]) {
        if (item.count < 14) {
            return;
        }
//        volUpLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"BIAS%@: %.2f",self.BIASL1,[[item objectAtIndex:12]floatValue]]];
        volUpLab.text = [NSString stringWithFormat:@"BIAS%@:%.2f",self.BIASL1,[[item objectAtIndex:12]floatValue]];
        if ([_closePrice integerValue] == 4) {
            volUpLab.text = [NSString stringWithFormat:@"BIAS%@:%.4f",self.BIASL1,[[item objectAtIndex:12]floatValue]];
//            volUpLab.text = [self showtext:[NSString stringWithFormat:@"BIAS%@",self.BIASL1] WithArr:item index:12];
        }
        if ([[item objectAtIndex:12] isEqualToString:@"nil"]) {
            volUpLab.text = [NSString stringWithFormat:@"BIAS%@:--",self.BIASL1];
        }
        [volUpLab sizeToFit];
        
//        volMidLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"BIAS%@: %.2f",self.BIASL2,[[item objectAtIndex:13]floatValue]]];
        
        volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth, 20);
        volMidLab.text = [NSString stringWithFormat:@"BIAS%@:%.2f",self.BIASL2,[[item objectAtIndex:13]floatValue]];
        if ([_closePrice integerValue] == 4) {
          volMidLab.text = [NSString stringWithFormat:@"BIAS%@:%.4f",self.BIASL2,[[item objectAtIndex:13]floatValue]];
//            volMidLab.text = [self showtext:[NSString stringWithFormat:@"BIAS%@",self.BIASL2] WithArr:item index:13];
        }
        if ([[item objectAtIndex:13] isEqualToString:@"nil"]) {
            volMidLab.text = [NSString stringWithFormat:@"BIAS%@:--",self.BIASL2];
        }
        [volMidLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"KDJ"]) {
        if (item.count < 15) {
            return;
        }
//        volUpLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"K: %.2f",[[item objectAtIndex:12]floatValue]]];
        volUpLab.text = [NSString stringWithFormat:@"K:%.2f",[[item objectAtIndex:12]floatValue]];
        if ([_closePrice integerValue] == 4) {
            volUpLab.text = [NSString stringWithFormat:@"K:%.4f",[[item objectAtIndex:12]floatValue]];
//            volUpLab.text = [self showtext:@"K" WithArr:item index:12];
        }
        if ([[item objectAtIndex:12] isEqualToString:@"nil"]) {
            volUpLab.text = @"K:--";
        }
        [volUpLab sizeToFit];
        
        volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth, 20);
//        volMidLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"D: %.2f",[[item objectAtIndex:13]floatValue]]];
        volMidLab.text = [NSString stringWithFormat:@"D:%.2f",[[item objectAtIndex:13]floatValue]];
        if ([_closePrice integerValue] == 4) {
            volMidLab.text = [NSString stringWithFormat:@"D:%.4f",[[item objectAtIndex:13]floatValue]];
//            volMidLab.text = [self showtext:@"D" WithArr:item index:13];
        }
        if ([[item objectAtIndex:13] isEqualToString:@"nil"]) {
            volMidLab.text = @"D:--";
        }
        [volMidLab sizeToFit];
        
        volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth, 20);
//        volLowLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"J: %.2f",[[item objectAtIndex:14]floatValue]]];
        volLowLab.text = [NSString stringWithFormat:@"J:%.2f",[[item objectAtIndex:14]floatValue]];
        if ([_closePrice integerValue] == 4) {
            volLowLab.text = [NSString stringWithFormat:@"J:%.4f",[[item objectAtIndex:14]floatValue]];
//            volLowLab.text = [self showtext:@"J" WithArr:item index:14];
        }
        if ([[item objectAtIndex:14] isEqualToString:@"nil"]) {
            volLowLab.text = @"J:--";
        }
        [volLowLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"RSI"]) {
        if (item.count < 15) {
            return;
        }
//        volUpLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"RSI%@: %.2f",self.RSIN1,[[item objectAtIndex:12]floatValue]]];
        volUpLab.text = [NSString stringWithFormat:@"RSI%@:%.2f",self.RSIN1,[[item objectAtIndex:12]floatValue]];
        if ([_closePrice integerValue] == 4) {
            
            volUpLab.text = [self showtext:[NSString stringWithFormat:@"RSI%@",self.RSIN1] WithArr:item index:12];
        }
        if ([[item objectAtIndex:12] isEqualToString:@"nil"]) {
            volUpLab.text = [NSString stringWithFormat:@"RSI%@:--",self.RSIN1];
        }
        [volUpLab sizeToFit];
        
        volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth, 20);
//        volMidLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"RSI%@: %.2f",self.RSIN2,[[item objectAtIndex:13]floatValue]]];
        volMidLab.text = [NSString stringWithFormat:@"RSI%@:%.2f",self.RSIN2,[[item objectAtIndex:13]floatValue]];
        if ([_closePrice integerValue] == 4) {
             volMidLab.text = [NSString stringWithFormat:@"RSI%@:%.4f",self.RSIN2,[[item objectAtIndex:13]floatValue]];
//            volMidLab.text = [self showtext:[NSString stringWithFormat:@"RSI%@",self.RSIN2] WithArr:item index:13];
        }
        if ([[item objectAtIndex:13] isEqualToString:@"nil"]) {
            volMidLab.text = [NSString stringWithFormat:@"RSI%@:--",self.RSIN2];
        }
        [volMidLab sizeToFit];
        
//        volLowLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"RSI%@: %.2f",self.RSIN3,[[item objectAtIndex:14]floatValue]]];
        volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth, 20);
        volLowLab.text = [NSString stringWithFormat:@"RSI%@:%.2f",self.RSIN3,[[item objectAtIndex:14]floatValue]];
        if ([_closePrice integerValue] == 4) {
            volLowLab.text = [NSString stringWithFormat:@"RSI%@:%.4f",self.RSIN3,[[item objectAtIndex:14]floatValue]];
//            volLowLab.text = [self showtext:[NSString stringWithFormat:@"RSI%@",self.RSIN3] WithArr:item index:14];
        }
        if ([[item objectAtIndex:14] isEqualToString:@"nil"]) {
            volLowLab.text = [NSString stringWithFormat:@"RSI%@:--",self.RSIN3];
        }
        [volLowLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"WR"]) {
        if (item.count < 13) {
            return;
        }
//        volUpLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"WR: %.2f",[[item objectAtIndex:12]floatValue]]];
        volUpLab.text = [NSString stringWithFormat:@"WR:%.2f",[[item objectAtIndex:12]floatValue]];
        if ([_closePrice integerValue] == 4) {
            volUpLab.text = [NSString stringWithFormat:@"WR:%.4f",[[item objectAtIndex:12]floatValue]];
//            volUpLab.text = [self showtext:@"WR" WithArr:item index:12];
        }
        if ([[item objectAtIndex:12] isEqualToString:@"nil"]) {
            volUpLab.text = @"WR:--";
        }
        [volUpLab sizeToFit];
    }
    
    //代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(showKchartHistoryWithArr:)]) {
        [self.delegate showKchartHistoryWithArr:item];
    }
    
}



#pragma mark 显示指标信息

- (void)showIndo{
    
    
    //主图
    // uperLab 主图指标显示控件
    
    if ([self.indo isEqualToString:@"MA"]) {
        uperLab.hidden = NO;
        uperLab.textColor = [@"#2485BD" hexStringToColor]; //MA5 蓝色
        
        uperLab.text = [self showtext:[NSString stringWithFormat:@"MA%@",self.MAUP] withIndex:9];
        
        if (self.data.count == 0) {
            return;
        }else {
        CGFloat maxWidth = [[XLArchiverHelper getObject:@"maxWidth"] floatValue];
        if (!maxWidth) {
            return;
        }else {
        
        if (isPad) {
            uperLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.padingY, LabWidth + 40, 20);
        }else {
            uperLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.padingY, LabWidth, 20);
        }
    }
}
        [uperLab sizeToFit];
        
    }else if ([self.indo isEqualToString:@"BOLL"]) {
        uperLab.hidden = NO;
        uperLab.textColor = [@"#F6AE02" hexStringToColor]; //BOLL   UP 黄色
    
        uperLab.text = [self showtext:@"UP" withIndex:9];
        if (self.data.count == 0) {
            return;
        }else {
            CGFloat maxWidth = [[XLArchiverHelper getObject:@"maxWidth"] floatValue];
            if (!maxWidth) {
                return;
            }else {
                    if (isPad) {
                            uperLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.padingY, LabWidth + 40, 20);
                        }else {
                            uperLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.padingY, LabWidth, 20);
                        }
            }
        }

        [uperLab sizeToFit];
        
    }else if ([self.indo isEqualToString:@"ENV"]) {
        uperLab.hidden = NO;
        uperLab.textColor = [@"#F6AE02" hexStringToColor]; //ENV   UP 黄色
        
        uperLab.text = [self showtext:@"UP" withIndex:9];
        
        if (self.data.count == 0) {
            return;
        }else {
            CGFloat maxWidth = [[XLArchiverHelper getObject:@"maxWidth"] floatValue];
            if (!maxWidth) {
                return;
            }else {
                
                        if (isPad) {
                            uperLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.padingY, LabWidth + 40, 20);
                        }else {
                            uperLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.padingY, LabWidth, 20);
                        }
            }
        }

        
    }
    [uperLab sizeToFit];
    
    // miderLab  主图指标显示控件
    
    if ([self.indo isEqualToString:@"MA"]) {
        miderLab.hidden = NO;
        if (isPad) {
            miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth, 20);
        }
        miderLab.textColor = [@"FB4B92" hexStringToColor];//MA10  紫色
        
        miderLab.text = [self showtext:[NSString stringWithFormat:@"MA%@",self.MAMID] withIndex:10];
        
        [miderLab sizeToFit];
        
    }else if ([self.indo isEqualToString:@"BOLL"]) {
        miderLab.hidden = NO;
        if (isPad) {
            miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth, 20);
        }
        
        miderLab.textColor = [@"#c9c9c9" hexStringToColor];//BOLL  MID  白色
        
        miderLab.text = [self showtext:@"MID" withIndex:10];
      
        
        [miderLab sizeToFit];
        
    }else if ([self.indo isEqualToString:@"ENV"]) {
        miderLab.hidden = NO;
        if (isPad) {
            miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            miderLab.frame = CGRectMake(uperLab.frame.origin.x +uperLab.frame.size.width + 5, uperLab.frame.origin.y, LabWidth, 20);
        }
        miderLab.textColor = [@"#c9c9c9" hexStringToColor];//ENV  MID  白色
        
        miderLab.text = [self showtext:@"MID" withIndex:10];
        
        
        [miderLab sizeToFit];
        
    }
    
    //lowerLab 主图指标显示控件
    
    if ([self.indo isEqualToString:@"MA"]) {
        lowerLab.hidden = NO;
        if (isPad) {
            lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth, 20);
        }
        lowerLab.textColor = [@"#F6AE02" hexStringToColor];  //MA20  黄色
        
        lowerLab.text = [self showtext:[NSString stringWithFormat:@"MA%@",self.MALOW] withIndex:11];
        [lowerLab sizeToFit];
        
    }else if ([self.indo isEqualToString:@"BOLL"]) {
        lowerLab.hidden = NO;
        if (isPad) {
            lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth, 20);
        }
        lowerLab.textColor = [@"FB4B92" hexStringToColor];  //BOLL  LOWER  紫色
        lowerLab.text = [self showtext:@"DN" withIndex:11];
        [lowerLab sizeToFit];
        
    }else if ([self.indo isEqualToString:@"ENV"]) {
        lowerLab.hidden = NO;
        if (isPad) {
            lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            lowerLab.frame = CGRectMake(miderLab.frame.origin.x +miderLab.frame.size.width + 5, miderLab.frame.origin.y, LabWidth, 20);
        }
        
        lowerLab.textColor = [@"#FB4B92" hexStringToColor];  //ENV  LOWER  紫色
        lowerLab.text = [self showtext:@"DN" withIndex:11];
        [lowerLab sizeToFit];
        
    }
    
    //副图
    
    // volUpLab 副图指标显示控件
    
    if ([self.ViceIndo isEqualToString:@"MACD"]) {
        volUpLab.hidden = NO;
        volUpLab.textColor = [@"#c9c9c9" hexStringToColor]; //DIF 白色
//        volUpLab.text = [self changeFloat:[[NSString alloc] initWithFormat:@"DIF:%.2f",[[[pointArray lastObject] objectAtIndex:12]floatValue]]];
        volUpLab.text = [NSString stringWithFormat:@"DIF:%.2f",[[[pointArray lastObject] objectAtIndex:12]floatValue]];
        if ([_closePrice integerValue] == 4) {
            
//            volUpLab.text = [self showtext:@"DIF" withIndex:12];
             volUpLab.text = [NSString stringWithFormat:@"DIF:%.4f",[[[pointArray lastObject] objectAtIndex:12]floatValue]];
        }
        
        if (self.data.count == 0) {
            return;
        }else {
            CGFloat maxWidth = [[XLArchiverHelper getObject:@"volMaxWidth"] floatValue];
            if (!maxWidth) {
                return;
            }else {

                if (isPad) {
                    volUpLab.frame =  CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth + 40, 20);
                }else {
                    volUpLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth, 20);
                }

            }
        }

        [volUpLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"BIAS"]) {
        volUpLab.hidden = NO;
        volUpLab.textColor = [@"#c9c9c9" hexStringToColor]; //BIAS   BIAS1 白色
//        volUpLab.text = [[NSString alloc] initWithFormat:@"BIAS%@: %.2f",self.BIASL1,[[[pointArray lastObject] objectAtIndex:12]floatValue]];
        NSString *str = [[NSString alloc] initWithFormat:@"BIAS%@:%.2f",self.BIASL1,[[[pointArray lastObject] objectAtIndex:12]floatValue]];
//        volUpLab.text = [self changeFloat:str];
        volUpLab.text = str;
        
        if ([_closePrice integerValue] == 4) {
            
//            volUpLab.text = [self showtext:[NSString stringWithFormat:@"BIAS%@",self.BIASL1] withIndex:12];
            volUpLab.text = [[NSString alloc] initWithFormat:@"BIAS%@:%.4f",self.BIASL1,[[[pointArray lastObject] objectAtIndex:12]floatValue]];
        }
        
        if (self.data.count == 0) {
            return;
        }else {
            CGFloat maxWidth = [[XLArchiverHelper getObject:@"volMaxWidth"] floatValue];
            if (!maxWidth) {
                return;
            }else {
                
                if (isPad) {
                    volUpLab.frame =  CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth + 40, 20);
                }else {
                    volUpLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth, 20);
                }
                
            }
        }

        [volUpLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"KDJ"]) {
        volUpLab.hidden = NO;
        volUpLab.textColor = [@"#c9c9c9" hexStringToColor]; //KDJ   K 白色
//        volUpLab.text = [[NSString alloc] initWithFormat:@"K: %.2f",[[[pointArray lastObject] objectAtIndex:12] floatValue]];
        NSString *str = [[NSString alloc] initWithFormat:@"K:%.2f",[[[pointArray lastObject] objectAtIndex:12] floatValue]];
//        volUpLab.text = [self changeFloat:str];
        volUpLab.text = str;
        
        if ([_closePrice integerValue] == 4) {
            
//            volUpLab.text = [self showtext:@"K" withIndex:12];
            volUpLab.text = [[NSString alloc] initWithFormat:@"K:%.4f",[[[pointArray lastObject] objectAtIndex:12] floatValue]];
        }
        
        if (self.data.count == 0) {
            return;
        }else {
            CGFloat maxWidth = [[XLArchiverHelper getObject:@"volMaxWidth"] floatValue];
            if (!maxWidth) {
                return;
            }else {
                
                if (isPad) {
                    volUpLab.frame =  CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth + 40, 20);
                }else {
                    volUpLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth, 20);
                }
                
            }
        }

        [volUpLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"RSI"]) {
        volUpLab.hidden = NO;
        volUpLab.textColor = [@"#c9c9c9" hexStringToColor]; //RSI   RSI1 白色
        volUpLab.text = [[NSString alloc] initWithFormat:@"RSI%@:%.2f",self.RSIN1,[[[pointArray lastObject] objectAtIndex:12] floatValue]];
//        NSString *str = [[NSString alloc] initWithFormat:@"RSI%@:%.2f",self.RSIN1,[[[pointArray lastObject] objectAtIndex:12] floatValue]];
//        volUpLab.text = [self changeFloat:str];
        
        if ([_closePrice integerValue] == 4) {
            
//            volUpLab.text = [self showtext:[NSString stringWithFormat:@"RSI%@",self.RSIN1] withIndex:12];
             volUpLab.text = [[NSString alloc] initWithFormat:@"RSI%@:%.4f",self.RSIN1,[[[pointArray lastObject] objectAtIndex:12] floatValue]];
        }
        
        if (self.data.count == 0) {
            return;
        }else {
            CGFloat maxWidth = [[XLArchiverHelper getObject:@"volMaxWidth"] floatValue];
            if (!maxWidth) {
                return;
            }else {
                
                if (isPad) {
                    volUpLab.frame =  CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth + 40, 20);
                }else {
                    volUpLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth, 20);
                }
                
            }
        }

        [volUpLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"WR"]) {
        volUpLab.hidden = NO;
        volUpLab.textColor = [@"#c9c9c9" hexStringToColor]; //WR   WR 白色
        volUpLab.text = [[NSString alloc] initWithFormat:@"WR:%.2f",[[[pointArray lastObject] objectAtIndex:12] floatValue]];
//        NSString *str =[[NSString alloc] initWithFormat:@"WR:%.2f",[[[pointArray lastObject] objectAtIndex:12] floatValue]];
//        volUpLab.text = [self changeFloat:str];
        
        if ([_closePrice integerValue] == 4) {
            
//            volUpLab.text = [self showtext:@"WR" withIndex:12];
            volUpLab.text = [[NSString alloc] initWithFormat:@"WR:%.4f",[[[pointArray lastObject] objectAtIndex:12] floatValue]];
        }
        
        if (self.data.count == 0) {
            return;
        }else {
            CGFloat maxWidth = [[XLArchiverHelper getObject:@"volMaxWidth"] floatValue];
            if (!maxWidth) {
                return;
            }else {
                
                if (isPad) {
                    volUpLab.frame =  CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth + 40, 20);
                }else {
                    volUpLab.frame = CGRectMake(self.padingX + maxWidth + 5, self.bottomY, LabWidth, 20);
                }
                
            }
        }
        [volUpLab sizeToFit];
        
    }
    
    // volMidLab 副图指标显示控件
    
    if ([self.ViceIndo isEqualToString:@"MACD"]) {
        volMidLab.hidden = NO;
        if (isPad) {
            volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth, 20);
        }
        volMidLab.textColor = [@"F6AE02" hexStringToColor]; //DEA 黄色
        volMidLab.text = [[NSString alloc] initWithFormat:@"DEA:%.2f",[[[pointArray lastObject] objectAtIndex:13]floatValue]];
//        NSString *str =[[NSString alloc] initWithFormat:@"DEA:%.2f",[[[pointArray lastObject] objectAtIndex:13]floatValue]];
//        volMidLab.text = [self changeFloat:str];
        
        if ([_closePrice integerValue] == 4) {
            
//            volMidLab.text =[self showtext:@"DEA" withIndex:13];
            volMidLab.text = [[NSString alloc] initWithFormat:@"DEA:%.4f",[[[pointArray lastObject] objectAtIndex:13]floatValue]];

        }
        [volMidLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"BIAS"]) {
        volMidLab.hidden = NO;
        if (isPad) {
            volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth, 20);
        }
        
        volMidLab.textColor = [@"F6AE02" hexStringToColor]; //BIAS   BIAS2 黄色
        volMidLab.text = [[NSString alloc] initWithFormat:@"BIAS%@:%.2f",self.BIASL2,[[[pointArray lastObject] objectAtIndex:13]floatValue]];
//        NSString *str =[[NSString alloc] initWithFormat:@"BIAS%@:%.2f",self.BIASL2,[[[pointArray lastObject] objectAtIndex:13]floatValue]];
//        volMidLab.text = [self changeFloat:str];
        
        if ([_closePrice integerValue] == 4) {
            
//            volMidLab.text = [self showtext:[NSString stringWithFormat:@"BIAS%@",self.BIASL2] withIndex:13];
            volMidLab.text = [[NSString alloc] initWithFormat:@"BIAS%@:%.4f",self.BIASL2,[[[pointArray lastObject] objectAtIndex:13]floatValue]];
        }
        [volMidLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"KDJ"]) {
        volMidLab.hidden = NO;
        if (isPad) {
            volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth, 20);
        }
        
        volMidLab.textColor = [@"F6AE02" hexStringToColor]; //KDJ   D 黄色
        volMidLab.text = [[NSString alloc] initWithFormat:@"D:%.2f",[[[pointArray lastObject] objectAtIndex:13] floatValue]];
//        NSString *str =[[NSString alloc] initWithFormat:@"D:%.2f",[[[pointArray lastObject] objectAtIndex:13] floatValue]];
//        volMidLab.text = [self changeFloat:str];

        if ([_closePrice integerValue] == 4) {
            
//            volMidLab.text = [self showtext:@"D" withIndex:13];
            volMidLab.text = [[NSString alloc] initWithFormat:@"D:%.4f",[[[pointArray lastObject] objectAtIndex:13] floatValue]];
        }
        [volMidLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"RSI"]) {
        volMidLab.hidden = NO;
        if (isPad) {
            volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            volMidLab.frame = CGRectMake(volUpLab.frame.origin.x + volUpLab.frame.size.width + 5, volUpLab.frame.origin.y, LabWidth, 20);
        }
        
        volMidLab.textColor = [@"F6AE02" hexStringToColor]; //RSI   RSI2 黄色
        volMidLab.text = [[NSString alloc] initWithFormat:@"RSI%@:%.2f",self.RSIN2,[[[pointArray lastObject] objectAtIndex:13] floatValue]];
//        NSString *str =[[NSString alloc] initWithFormat:@"RSI%@:%.2f",self.RSIN2,[[[pointArray lastObject] objectAtIndex:13] floatValue]];
//        volMidLab.text = [self changeFloat:str];
        
        if ([_closePrice integerValue] == 4) {
            
//            volMidLab.text = [self showtext:[NSString stringWithFormat:@"RSI%@",self.RSIN2] withIndex:13];
            volMidLab.text = [[NSString alloc] initWithFormat:@"RSI%@:%.4f",self.RSIN2,[[[pointArray lastObject] objectAtIndex:13] floatValue]];
        }
        [volMidLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"WR"]) {
        volMidLab.hidden = YES;
        
    }
    
    // volLowLab 副图指标显示控件
    
    if ([self.ViceIndo isEqualToString:@"MACD"]) {
        volLowLab.hidden = NO;
        if (isPad) {
            volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth, 20);
        }
        volLowLab.text = [[NSString alloc] initWithFormat:@"MACD:%.2f",[[[pointArray lastObject] objectAtIndex:14]floatValue]];
//        NSString *str =[[NSString alloc] initWithFormat:@"MACD:%.2f",[[[pointArray lastObject] objectAtIndex:14]floatValue]];
//        volLowLab.text = [self changeFloat:str];
        
        if ([_closePrice integerValue] == 4) {
            
//            volLowLab.text = [self showtext:@"MACD" withIndex:14];
              volLowLab.text = [[NSString alloc] initWithFormat:@"MACD:%.4f",[[[pointArray lastObject] objectAtIndex:14]floatValue]];
        }
        if ([[[pointArray lastObject] objectAtIndex:14] floatValue] > 0) {
            volLowLab.textColor = [@"#e93030" hexStringToColor]; //MACD 红色
        }else {
            volLowLab.textColor = [@"#45943e" hexStringToColor]; //MACD 绿色
            
        }
        [volLowLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"BIAS"]) {
        volLowLab.hidden = YES;
        
    }else if ([self.ViceIndo isEqualToString:@"KDJ"]) {
        volLowLab.hidden = NO;
        if (isPad) {
            volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth, 20);
        }
        
        volLowLab.textColor = [@"FB4B92" hexStringToColor]; //KDJ   J 紫色
        volLowLab.text = [[NSString alloc] initWithFormat:@"J:%.2f",[[[pointArray lastObject] objectAtIndex:14] floatValue]];
//        NSString *str =[[NSString alloc] initWithFormat:@"J:%.2f",[[[pointArray lastObject] objectAtIndex:14]floatValue]];
//        volLowLab.text = [self changeFloat:str];

        
        if ([_closePrice integerValue] == 4) {
            
//            volLowLab.text = [self showtext:@"J" withIndex:14];
             volLowLab.text = [[NSString alloc] initWithFormat:@"J:%.4f",[[[pointArray lastObject] objectAtIndex:14] floatValue]];
        }
        [volLowLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"RSI"]) {
        volLowLab.hidden = NO;
        if (isPad) {
            volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth + 40, 20);
        }else {
            volLowLab.frame = CGRectMake(volMidLab.frame.origin.x + volMidLab.frame.size.width + 5, volMidLab.frame.origin.y, LabWidth, 20);
        }
        
        volLowLab.textColor = [@"FB4B92" hexStringToColor]; //RSI   RSI3 紫色
        volLowLab.text = [[NSString alloc] initWithFormat:@"RSI%@:%.2f",self.RSIN3,[[[pointArray lastObject] objectAtIndex:14] floatValue]];
//        NSString *str =[[NSString alloc] initWithFormat:@"RSI%@:%.2f",self.RSIN3,[[[pointArray lastObject] objectAtIndex:14] floatValue]];
//        volLowLab.text = [self changeFloat:str];

        
        if ([_closePrice integerValue] == 4) {
            
//            volLowLab.text = [self showtext:[NSString stringWithFormat:@"RSI%@",self.RSIN3] withIndex:14];
            volLowLab.text = [[NSString alloc] initWithFormat:@"RSI%@:%.2f",self.RSIN3,[[[pointArray lastObject] objectAtIndex:14] floatValue]];
        }
        [volLowLab sizeToFit];
        
    }else if ([self.ViceIndo isEqualToString:@"WR"]) {
        volLowLab.hidden = YES;
        
    }
    
}



#pragma mark --------//若要实时画图，不能使用gestureRecognizer，只能使用touchbegan等方法来调用setNeedsDisplay实时刷新屏幕
//平移、缩放操作
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    //触摸K线区域时，禁止滚动视图滚动，防止与K线区域内的手势操作冲突
    if (self.delegate && [self.delegate respondsToSelector:@selector(notScrolling)]) {
        [self.delegate notScrolling];
    }
    
    [super touchesBegan:touches withEvent:event];
    
    NSArray *ts = [touches allObjects];
    
    touchFlag = 0;
    touchFlagTwo = 0;
    
    if (ts.count == 1) {
        
        touchFloat = [[ts objectAtIndex:0] locationInView:self].x;
        
    }else if (ts.count == 2) {
        touchFlag = [[ts objectAtIndex:0] locationInView:self].x ;
        touchFlagTwo = [[ts objectAtIndex:1] locationInView:self].x;
    }
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //如果数据不够，限制平移和缩放
    
    if (!_islevel) {
        if (self.data.count < 45) {
            return;
        }
        
    }else {
        
        if (self.data.count < 115) {
            return;
        }
    }
    
    NSArray *ts = [touches allObjects];
    
    //平移
    if([ts count]==1){
        
        UITouch *touch = [ts objectAtIndex:0];
        float currentFlag = [touch locationInView:self].x;
        
        //右移
        if ((currentFlag - touchFloat) > 0) {
            
            if ((currentFlag - touchFloat) > self.kLineWidth) {
                
                if (rangeTo - 2 > range) {
                    rangeTo = rangeTo - 2;
                }else {
                    
                    rangeTo = range;
                }
                
                touchFloat = currentFlag;
                
                //重绘
                [self setNeedsDisplay];
            }
            
            //左移
        }else if((currentFlag - touchFloat) < 0) {
            
            if ((touchFloat - currentFlag) > self.kLineWidth) {
                
                if (rangeTo + 2 < self.data.count ) {
                    rangeTo = rangeTo + 2;
                }else {
                    
                    rangeTo = self.data.count;
                    
                }
                
                touchFloat = currentFlag;
                
                //重绘
                [self setNeedsDisplay];
                
            }
        }
        
        //缩放
    } else if (ts.count == 2){
        
        float currFlag = [[ts objectAtIndex:0] locationInView:self].x;
        float currFlagTwo = [[ts objectAtIndex:1] locationInView:self].x;
        if(touchFlag == 0){
            touchFlag = currFlag;
            touchFlagTwo = currFlagTwo;
        }else{
            
            if(fabs(fabsf(currFlagTwo-currFlag)-fabs(touchFlagTwo-touchFlag)) >= MIN_INTERVAL){
                
                if(fabsf(currFlagTwo-currFlag)-fabs(touchFlagTwo-touchFlag) > 0){
                    
                    if ((currFlagTwo + currFlag) / 2 > self.xWidth / 4  &&  (currFlag + currFlagTwo) / 2 < self.xWidth * 3 / 4) {
                        
                        // 放大手势
                        rangeTo -= 1;
                        range -= 2;
                    }else if ((currFlagTwo + currFlag) / 2 < self.xWidth / 4){
                        
                        rangeTo -= 2;
                        range -= 1;
                    }else if ((currFlagTwo + currFlag) / 2 > self.xWidth * 3 / 4){
                        
                        rangeTo += 1;
                        range -= 1;
                    }
                    
                    if (range > 15) {
                        
                    }else {
                        range = 15;
                    }
                    
                    
                    if (range > self.data.count) {
                        range = self.data.count;
                    }
                    
                    
                    if (rangeTo > range) {
                        
                    }else {
                        
                        rangeTo = range;
                        
                    }
                    
                    
                    if ((range == self.data.count) && (rangeTo == self.data.count)) {
                        self.kLineWidth++;
                        if (self.kLineWidth > (self.xWidth -(15 - 2)*2 - 5) / 15) {
                            self.kLineWidth = (self.xWidth -(15 - 2)*2 - 5) / 15;
                        }
                    }else {
                        
                        self.kLineWidth  = (self.xWidth -(range - 2)*2 - 5) / range;
                        
                    }
                    
                    [self setNeedsDisplay];
                    
                }else {
                    
                    // 缩小手势
                    rangeTo += 1;
                    if (rangeTo < self.data.count) {
                        
                    }else {
                        rangeTo = self.data.count;
                        
                    }
                    range += 2;
                    
                    if (range < 150) {
                        
                    }else {
                        range = 150;
                        
                    }
                    
                    if (range > self.data.count) {
                        range = self.data.count;
                    }
                    
                    if (rangeTo > range) {
                        
                    }else {
                        
                        rangeTo = range;
                        
                    }
                    
                    if ((range == rangeTo == self.data.count)) {
                        self.kLineWidth--;
                        if (self.kLineWidth < (self.xWidth -(150- 2)*2 - 5) / 150) {
                            self.kLineWidth =  (self.xWidth -(150- 2)*2 - 5) / 150;
                        }
                    }else {
                        
                        self.kLineWidth  = (self.xWidth -(range - 2)*2 - 5) / range;
                        
                    }
                    
                    [self setNeedsDisplay];
                    
                }
            }
            
        }
        
        touchFlag = currFlag;
        touchFlagTwo = currFlagTwo;
        
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //手势操作结束后，开启滚动视图滚动，方便刷新
    if (self.delegate && [self.delegate respondsToSelector:@selector(canScrolling)]) {
        [self.delegate canScrolling];
    }
}


#pragma mark 处理日期
/*
 string:2015-12-23   ------  15/12/23
 */
- (NSString *)handledateWith:(NSString *)string {
    if (string.length < 8) {
        return @"";
    }
    
    NSMutableString *str = [[NSMutableString alloc]init];
    [str appendString:[string substringToIndex:2]];//15
    [str appendString:@"/"];
    [str appendString:[string substringWithRange:NSMakeRange(3,2)]];
    [str appendString:@"/"];
    [str appendString:[string substringWithRange:NSMakeRange(6, 2)]];
    return str;
    
}

//更新
/*
 参数isautoreRefresh 来确定K线刷新时的保留位置，手动刷新时停留在最新位置，自动刷新时停留在当前位置
 参数isLevel   来确定是否横竖屏状态，横屏状态下默认显示K线115根，竖屏状态下默认显示K线45根
 参数ischangeRange 来确定是否改变range参数，横竖屏切换时需要改变，单纯刷新时不需要改变
 */
- (void)updateWithBool:(BOOL)isautoreRefresh level:(BOOL)isLevel changeRange:(BOOL)ischangeRange{
    _islevel = isLevel;
    if (range == rangeTo) {
        //在最新位置
        if (ischangeRange) {
            range = 45;
            if (isLevel) {
                range = 115;
                _isShowLevelTime = YES;//显示横屏时横轴时间
            }
        }
        if (isautoreRefresh == true) {
            //判断是否是实时刷新
            rangeTo = self.data.count;
        }
        
        if (range > self.data.count) {
            range = self.data.count;
        }
        if (rangeTo > self.data.count) {
            rangeTo = self.data.count;
        }
        if (rangeTo < range) {
            rangeTo = range;
        }
        
        if (range == rangeTo && rangeTo == self.data.count) {
            //计算单根K线宽度和两根K线之间的间距，竖屏
            self.kLineWidth =  (self.xWidth -(range- 2)*2 - 5) / 45;
            self.kLinePadding = 2;
            //横屏
            if (isLevel) {
                self.kLineWidth = (self.xWidth - (range - 2) * 2 - 5)/ 115;
                self.kLinePadding = 2;
                _isShowLevelTime = YES;//显示横轴时间
            }
            
        }else {
            
            self.kLineWidth  = (self.xWidth -(range - 2)*2 - 5) / range;// k线实体的宽度
            self.kLinePadding = 2; // k实体的间隔
            
        }
        
        
    }else {
        
        if (isLevel) {
            if (ischangeRange) {
                
                range = 115;
            }
            _isShowLevelTime = YES;
        }else {
            if (ischangeRange) {
                
                range = 45;
            }
            _isShowLevelTime = NO;
        }
        
        if (isautoreRefresh == true) {
            
            rangeTo = self.data.count;
        }
        
        
        if (range > self.data.count) {
            range = self.data.count;
        }
        if (rangeTo > self.data.count) {
            rangeTo = self.data.count;
        }
        if (rangeTo < range) {
            rangeTo = range;
        }
        if (range == rangeTo && rangeTo == self.data.count) {
            self.kLineWidth =  (self.xWidth -(range- 2)*2 - 5) / 45;
            self.kLinePadding = 2;
            
            if (isLevel) {
                self.kLineWidth = (self.xWidth - (range - 2) * 2 - 5)/ 115;
                self.kLinePadding = 2;
                _isShowLevelTime = YES;
            }
            
            
        }else {
            
            self.kLineWidth  = (self.xWidth -(range - 2)*2 - 5) / range;// k线实体的宽度
            self.kLinePadding = 2; // k实体的间隔
            
        }
        
    }
    
    [self calcuteData];//计算指标数据
    [self setNeedsDisplay];//进行绘制，drawrect方法不能手动调用，只能自动调用。
}


//根据小数点位数显示指标
- (NSString *)showtext:(NSString *)str withIndex:(int)idx {
    NSString *text = [[NSString alloc]init];
    
    if ([_closePrice integerValue] == 1) {
        text = [self changeFloat:[[NSString alloc] initWithFormat:@"%@:%.1f",str,[[[pointArray lastObject] objectAtIndex:idx]floatValue]]];
        
    }else if ([_closePrice integerValue] == 2) {
        text = [self changeFloat:[[NSString alloc] initWithFormat:@"%@:%.2f",str,[[[pointArray lastObject] objectAtIndex:idx]floatValue]]];
        
    }else if ([_closePrice integerValue] == 3){
        text = [self changeFloat:[[NSString alloc] initWithFormat:@"%@:%.3f",str,[[[pointArray lastObject] objectAtIndex:idx]floatValue]]];
        
    }else if ([_closePrice integerValue] == 4) {
        
        text = [self changeFloat:[[NSString alloc] initWithFormat:@"%@:%.4f",str,[[[pointArray lastObject] objectAtIndex:idx]floatValue]]];
        
    }else if ([_closePrice integerValue] == 0){
        text = [[NSString alloc] initWithFormat:@"%@:%ld",str,lroundf([[[pointArray lastObject] objectAtIndex:idx]floatValue])];
    }
    
    return text;
    
}


//十字星显示指标
- (NSString *)showtext:(NSString *)str WithArr:(NSArray *)arr index:(int)idx {
    NSString *text = [[NSString alloc]init];
    
    if ([_closePrice integerValue] == 1) {
        text = [self changeFloat:[[NSString alloc] initWithFormat:@"%@:%.1f",str,[[arr objectAtIndex:idx]floatValue]]];
        
    }else if ([_closePrice integerValue] == 2) {
        text = [self changeFloat:[[NSString alloc] initWithFormat:@"%@:%.2f",str,[[arr objectAtIndex:idx]floatValue]]];
        
    }else if ([_closePrice integerValue] == 3){
        text = [self changeFloat:[[NSString alloc] initWithFormat:@"%@:%.3f",str,[[arr objectAtIndex:idx]floatValue]]];
        
    }else if ([_closePrice integerValue] == 4) {
        text = [self changeFloat:[[NSString alloc] initWithFormat:@"%@:%.4f",str,[[arr objectAtIndex:idx]floatValue]]];
        
    }else if ([_closePrice integerValue] == 0) {
        text = [[NSString alloc] initWithFormat:@"%@:%ld",str,lroundf([[arr objectAtIndex:idx]floatValue])];
    }
    
    return text;
    
}

#pragma mark 计算指标数据
- (void)calcuteData {
    
    if (Uper.count > 0) {
        [Uper removeAllObjects];
        [Mider removeAllObjects];
        [Lower removeAllObjects];
        [volUper removeAllObjects];
        [volMider removeAllObjects];
        [volLower removeAllObjects];
    }
    
    
    applyArray = [self handleApplyValueWithArr:self.data];//计算涨跌幅
    
    //主图指标
    if ([self.indo isEqualToString:@"MA"]) {
        //处理数据，计算指标值
        
        Uper =  [self handleDataForIndi:self.data index:[self.MAUP intValue]];//默认参数5，10，20
        Mider =  [self handleDataForIndi:self.data index:[self.MAMID intValue]];
        Lower =  [self handleDataForIndi:self.data index:[self.MALOW intValue]];

        
    }else if ([self.indo isEqualToString:@"BOLL"]) {
        
        
        Mider = [self handleDataForIndi:self.data index:[self.BOLLN intValue]];// 参数 N 默认20
        NSArray *STD = [self handleDataForSTDWithArr:self.data index:[self.BOLLN intValue]];
        
        Uper = [self handleWithArr:Mider Array:STD index:0];
        Lower = [self handleWithArr:Mider Array:STD index:1];
        
    }else if ([self.indo isEqualToString:@"ENV"]){
        
        NSArray *new = [self handleDataForIndi:self.data index:[self.ENVN intValue]];//参数N 默认14
        Uper = [self handleWithArr:new Array:nil index:2];
        Lower = [self handleWithArr:new Array:nil index:3];
        Mider = [self handleWithArr:Uper Array:Lower index:4];
        
    }
    
    
    //副图指标
    if ([self.ViceIndo isEqualToString:@"MACD"]) {
        
        //EMA(CLOSE,SHORT)
        
        volUper = [self EMAdataWithArr:self.data index:[self.MACDSHORT intValue] index:[self.MACDLONG intValue]]; //DIF指标数组
        volMider = [self EMAdataWithArr:volUper index:[self.MACDM intValue]]; //MACD M默认9   DEA指标数组
        volLower = [self handleWithArr:volUper Array:volMider index:6];//MACD
        
        
    }else if ([self.ViceIndo isEqualToString:@"BIAS"]) {
        
        NSMutableArray *closePrice = [[NSMutableArray alloc]init];//收盘价数组
        for (NSArray *Arr in self.data) {
            [closePrice addObject:Arr[3]];//收盘价
        }
        
        NSMutableArray *MAarr = [self handleDataForIndi:self.data index:[self.BIASL1 intValue]];//BIAS  L1默认为6
        NSMutableArray *MAanotherarr = [self handleDataForIndi:self.data index:[self.BIASL2 intValue]];//BIAS  L2默认为12
     
       
        volUper  = [self handleWithArr:closePrice Array:MAarr index:7];
        volMider = [self handleWithArr:closePrice Array:MAanotherarr index:7];
        
        
    }else if ([self.ViceIndo isEqualToString:@"KDJ"]) {
        
        NSArray *RSVarr = [self RSVdataWithArr:self.data index:[self.KDJN intValue]];//KDJ N
        volUper = [self KDJDataForIndi:RSVarr index:[self.KDJM1 intValue] index:[self.KDJN intValue]]; //KDJ  M1
        volMider = [self KDJDataForIndi:volUper index:[self.KDJM2 intValue] index:([self.KDJN intValue] + [self.KDJM1 intValue] - 1)];
        volLower = [self handleWithArr:volUper Array:volMider index:8];
        
        
    }else if ([self.ViceIndo isEqualToString:@"RSI"]) {
        
        volUper = [self RSIDataWithArr:self.data index:[self.RSIN1 intValue]];//RSI  RSIL1
        volMider = [self RSIDataWithArr:self.data index:[self.RSIN2 intValue]];//RSI  RSIN2
        volLower = [self RSIDataWithArr:self.data index:[self.RSIN3 intValue]];//RSI RSIN3
        
        
    }else if ([self.ViceIndo isEqualToString:@"WR"]) {
        
        volUper = [self WRdataWithArr:self.data index:[self.WRN intValue]];//WR WR
    }
}


#pragma mark  计算涨跌幅 
- (NSMutableArray *)handleApplyValueWithArr:(NSMutableArray *)arr {
    
    NSMutableArray *tempArr = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < arr.count; i++) {
        if (i == 0) {
            [tempArr addObject:@"0.00%"];
            continue;
        }
        
        CGFloat before = [[arr[i - 1] objectAtIndex:3] floatValue];//前一日收盘价
        CGFloat next = [[arr[i] objectAtIndex:3] floatValue];//后一日的收盘价
        CGFloat apply = (next - before) / before;
        
        [tempArr addObject:[NSString stringWithFormat:@"%.2f%%",apply * 100]];
    }
    
    return tempArr;
    
}

@end
