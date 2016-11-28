//
//  RunChartView.h
//  RunChartAndKchart
//
//  Created by zsgjs on 15/12/16.
//  Copyright (c) 2015年 zsgjs. All rights reserved.
//

#import "lineView.h"

@protocol RunChartViewDelegate <NSObject>
//十字星显示历史信息
- (void)showHistoryWithArr:(NSArray *)arr;
//取消显示
- (void)cancelShow;

@end

@interface RunChartView : lineView

@property (nonatomic,assign) id<RunChartViewDelegate>delegate;
@property(nonatomic,retain)  NSMutableArray *data;//存放日期，价格的数组
@property (nonatomic,retain) NSMutableArray *category;//存放日期的数组
@property(nonatomic,strong)    NSString       * closePrice;//中间坐标值，昨收价
@property(nonatomic,strong)    NSString       *type;//分时图类型
@property(nonatomic,strong)    NSString       *beginTime;//交易开始时间
@property(nonatomic,strong)    NSString       *endTime;//交易结束时间
@property (nonatomic,assign) CGFloat         xWidth; // 分时图x轴宽度
@property (nonatomic,assign) CGFloat         yHeight; // 分时图y轴高度

@property (nonatomic,strong) NSString *kde;//判断小数点位数

@end
