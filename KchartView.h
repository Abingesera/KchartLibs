//
//  KchartView.h
//  RunChartAndKchart
//
//  Created by zsgjs on 15/12/16.
//  Copyright (c) 2015年 zsgjs. All rights reserved.
//

#import "lineView.h"
#import "XLConstant.h"

@protocol KchartViewDelegate <NSObject>
//十字星显示历史信息
//显示历史信息
- (void)showKchartHistoryWithArr:(NSArray *)arr;
//取消显示
- (void)hiddenData;

- (void)notScrolling;

- (void)canScrolling;
@end

@interface KchartView : lineView

@property (nonatomic,assign)id<KchartViewDelegate>delegate;

@property (nonatomic,copy)   NSString       *indo;//主图指标类型
@property (nonatomic,copy)   NSString       *ViceIndo;//副图指标
@property(nonatomic,retain)  NSMutableArray *data;//存放日期，价格的数组
@property (nonatomic,retain) NSMutableArray *categorys;//存放日期的数组

@property(nonatomic,retain)  NSMutableArray *Kdata;//画k线用的数组
@property (nonatomic,retain) NSMutableArray *cates;

@property (nonatomic,assign) CGFloat         padingX;//主图X坐标
@property (nonatomic,assign) CGFloat         padingY;//主图Y坐标
@property (nonatomic,assign) CGFloat         xWidth; // x轴宽度
@property (nonatomic,assign) CGFloat         yHeight; // y轴高度
@property (nonatomic,assign) CGFloat         bottomHeight;//副图高度
@property (nonatomic,assign) CGFloat         bottomY;


@property(nonatomic,assign)  CGFloat         maxValue;//主图纵坐标最大值
@property(nonatomic,assign)  CGFloat         minValue;//主图纵坐标最小值

@property(nonatomic,assign)  CGFloat         volMaxValue;//副图纵坐标最大值
@property(nonatomic,assign)  CGFloat         volMinValue;//副图纵坐标最小值

@property (nonatomic,assign) CGFloat         kLineWidth; // k线的宽度 用来计算可存放K线实体的个数，也可以由此计算出起始日期和结束日期的时间段
@property (nonatomic,assign) CGFloat         kLinePadding;//K线之间间隔

@property (nonatomic,copy)   NSString        *MAUP;//主图MA指标参数MA5
@property (nonatomic,copy)   NSString        *MAMID;//主图MA指标参数MA10
@property (nonatomic,copy)   NSString        *MALOW;//主图MA指标参数MA20

@property (nonatomic,copy)   NSString        *BOLLN;//主图BOLL指标参数N
@property (nonatomic,copy)   NSString        *BOLLP;//主图BOLL指标参数P

@property (nonatomic,copy)   NSString        *ENVN;//主图ENV指标参数N

@property (nonatomic,copy)   NSString        *MACDSHORT;//副图MACD指标参数SHORT
@property (nonatomic,copy)   NSString        *MACDLONG;//副图MACD指标参数LONG
@property (nonatomic,copy)   NSString        *MACDM; //副图MACD指标参数M

@property (nonatomic,copy)   NSString        *BIASL1;//副图BIAS指标参数L1
@property (nonatomic,copy)   NSString        *BIASL2;//副图BIAS指标参数L2

@property (nonatomic,copy)   NSString        *KDJN;//副图KDJ指标参数N
@property (nonatomic,copy)   NSString        *KDJM1;//副图KDJ指标参数M1
@property (nonatomic,copy)   NSString        *KDJM2;//副图KDJ指标参数M2

@property (nonatomic,copy)   NSString        *RSIN1;//副图RSI指标参数N1
@property (nonatomic,copy)   NSString        *RSIN2;//副图RSI指标参数N2
@property (nonatomic,copy)   NSString        *RSIN3;//副图RSI指标参数N3

@property (nonatomic,copy)   NSString        *WRN;//副图WR指标参数N

@property (nonatomic,copy)   NSString        *closePrice;//存储收盘价，获取小数点位数
@property (nonatomic,assign)   BOOL  isShowLevelTime;//是否显示横坐标时间
@property (nonatomic,assign)   ShowKLineType        kLineTypeStr;//区分K线类型，显示日期还是时间
@property (nonatomic,assign) BOOL islevel;//是否横屏


@property (nonatomic, )BOOL isShowHistory;

- (void)updateWithBool:(BOOL)isautoreRefresh level:(BOOL)isLevel changeRange:(BOOL)ischangeRange;


@end


