//
//  Config.h
//  RunChartAndKchart
//
//  Created by zsgjs on 15/12/28.
//  Copyright (c) 2015年 zsgjs. All rights reserved.
//

#ifndef RunChartAndKchart_Config_h
#define RunChartAndKchart_Config_h

#define lableWidth 80
#define paddingSpace 5

#define MAXVALUE(a,b) (a>b?a:b)
#define MINVALUE(a,b) (a>b?b:a)


#define systemVersionString [[UIDevice currentDevice] systemVersion]
#define systemName [[UIDevice currentDevice] systemName]

//[[UIDevice currentDevice] systemName]：系统名称，如iPhone OS
//[[UIDevice currentDevice] systemVersion]：系统版本，如4.2.1
//[[UIDevice currentDevice] model]：The model of the device，如iPhone或者iPod touch
//[[UIDevice currentDevice] uniqueIdentifier]：设备的惟一标识号，deviceID
//[[UIDevice currentDevice] name]：设备的名称，如 张三的iPhone
//[[UIDevice currentDevice] localizedModel]：The model of the device as a localized string，类似model

//iPhone下
#define blueAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, [UIColor colorWithRed:0/255.0f green:0/255.0f blue:255/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//蓝色

#define purpleAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, [UIColor colorWithRed:0.5 green:0 blue:0.5 alpha:1.0f], NSForegroundColorAttributeName, nil]//紫色

#define yellowAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, [UIColor colorWithRed:255/255.0f green:255/255.0f blue:0/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//黄色

#define whiteAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//白色

#define redAttrs  [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, [UIColor colorWithRed:255/255.0f green:0/255.0f blue:0/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//红色

#define greenAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, [UIColor colorWithRed:0/255.0f green:255/255.0f blue:0/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//白色

#define orangeAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, [UIColor colorWithRed:1.0f green:0.5f blue:0/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//橙色

#define Attrs     [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:9], NSFontAttributeName, [@"#C9C9C9" hexStringToColor], NSForegroundColorAttributeName, nil]//文本属性

#define LevelAttrs  [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:9], NSFontAttributeName, [@"#5B646B" hexStringToColor], NSForegroundColorAttributeName, nil]//横坐标时间文本属性

//获取屏幕 宽度、高度
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

// 是否iPad
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

//iPad情况下
#define PadblueAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [UIColor colorWithRed:0/255.0f green:0/255.0f blue:255/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//蓝色

#define PadpurpleAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [UIColor colorWithRed:0.5 green:0 blue:0.5 alpha:1.0f], NSForegroundColorAttributeName, nil]//紫色

#define PadyellowAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [UIColor colorWithRed:255/255.0f green:255/255.0f blue:0/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//黄色

#define PadwhiteAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//白色

#define PadredAttrs  [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [UIColor colorWithRed:255/255.0f green:0/255.0f blue:0/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//红色

#define PadgreenAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [UIColor colorWithRed:0/255.0f green:255/255.0f blue:0/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//白色

#define PadAttrs     [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [@"#C9C9C9" hexStringToColor], NSForegroundColorAttributeName, nil]//文本属性
#define PadLevelAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [@"#5B646B" hexStringToColor], NSForegroundColorAttributeName, nil]//横坐标时间文本属性

#define PadorangeAttrs [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15], NSFontAttributeName, [UIColor colorWithRed:1.0f green:0.5f blue:0/255.0f alpha:1.0f], NSForegroundColorAttributeName, nil]//橙色

#endif
