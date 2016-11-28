//
//  lineView.h
//  RunChartAndKchart
//
//  Created by zsgjs on 15/12/16.
//  Copyright (c) 2015年 zsgjs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface lineView : UIView


- (void)drawSectionsWithDic:(NSDictionary *)dic;//画坐标系
- (void)drawCoordvalueWithDic:(NSDictionary *)dic;//画坐标值

-(NSString *)notRounding:(float)price afterPoint:(int)position;//小数点只舍不入
-(NSString *)notRoundingWith:(float)price afterPoint:(int)position;//小数点只入不舍
-(NSString *)changeFloat:(NSString *)stringFloat;//去除float无效的0
@end
