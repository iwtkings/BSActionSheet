//
//  BSActionSheet.m
//  wangtong
//
//  Created by BSoft on 16/6/15.
//  Copyright © 2016年 BSoft. All rights reserved.
//

#import "BSActionSheet.h"

#define kAnimationTime 0.3
#define kSeparator_Height 6
#define kSeparatorLine_Height 0.5
#define kContentCount 5

#define kMaskAlpha 0.3
#define kBottomContentAlpha 0.7
#define kPerItemAlpha_Normal 0.9
#define kPerItemAlpah_Selected 0.7

#define kFontTitle_Default 13
#define kFontContent_Default 17

#define kPerCotnentHeight 50

#define ColorContentSelected [UIColor colorWithRed:1 green:1 blue:1 alpha:kPerItemAlpah_Selected]
#define CellLineColor [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.9]

//获取屏幕 宽度、高度
#define AS_SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define AS_SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

// 获取RGB颜色
#define ASRGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define ASRGB(r,g,b) ASRGBA(r,g,b,1.0f)

typedef NS_ENUM(NSUInteger, ActionSheetCloseType) {
    ActionSheetCloseType_TapSelf,
    ActionSheetCloseType_ClickCancel,
    ActionSheetCloseType_ClickContent,
};

#pragma mark - scrollview
@interface ASScrollView : UIScrollView

@end

@implementation ASScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    if ([view isKindOfClass:[UIButton class]]) {
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end

#pragma mark - ActionSheet
@interface BSActionSheet ()

//UI
@property (nonatomic, strong) UILabel *labelTitle;
@property (nonatomic, strong) UIButton *btnCancel;
@property (nonatomic, strong) UIView *viewContent;
@property (nonatomic, strong) ASScrollView *scrollViewContent;
@property (nonatomic, strong) UIButton *btnCurrentClick;//记录当前点击的button
//数据源
@property (nonatomic, strong) NSString *strTitle;
@property (nonatomic, strong) NSArray *arrCotnents;
@property (nonatomic, assign) ActionSheetCloseType actionSheetCloseType;//记录当前actionsheet关闭类型
//action
@property (nonatomic, copy) BlockClickCancel clickCancelBlock;
@property (nonatomic, copy) BlockClickContent clickContentBlock;

@end

@implementation BSActionSheet

- (instancetype)initWithTitle:(NSString *)title contents:(NSArray *)contents blockClickContent:(BlockClickContent)blockClickContent blockClickCancel:(BlockClickCancel)blockClickCancel
{
    self = [super init];
    if (self) {
        self.strTitle = title;
        self.arrCotnents = contents;
        self.clickContentBlock = blockClickContent;
        self.clickCancelBlock = blockClickCancel;
        self.frame = CGRectMake(0, 0, AS_SCREEN_WIDTH, AS_SCREEN_HEIGHT);
        //
        [self configureUI];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title contents:(NSArray *)contents blockClickContent:(BlockClickContent)blockClickContent
{
    self = [super init];
    if (self) {
        self.strTitle = title;
        self.arrCotnents = contents;
        self.clickContentBlock = blockClickContent;
        self.clickCancelBlock = nil;
        self.frame = CGRectMake(0, 0, AS_SCREEN_WIDTH, AS_SCREEN_HEIGHT);
        //
        [self configureUI];
    }
    return self;
}

#pragma mark - Private Method
- (void)configureUI
{
    self.backgroundColor = ASRGBA(0, 0, 0, kMaskAlpha);
    UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSelf)];
    [self addGestureRecognizer:tapG];
    //content
    CGRect frameCotnent = [self getBottomCotnentFrame];
    self.viewContent = [[UIView alloc] initWithFrame:CGRectMake(0, AS_SCREEN_HEIGHT, frameCotnent.size.width, frameCotnent.size.height)];
    self.viewContent.backgroundColor = ASRGBA(255, 255, 255, kBottomContentAlpha);
    [self addSubview:self.viewContent];
    UITapGestureRecognizer *tapGContent = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBottomContent)];
    [self.viewContent addGestureRecognizer:tapGContent];
    //
    CGFloat y = 0;//记录下一个控件的 y
    if (self.strTitle) {//有标题
        self.labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, AS_SCREEN_WIDTH, kPerCotnentHeight)];
        self.labelTitle.backgroundColor = ASRGBA(255, 255, 255, kPerItemAlpha_Normal);
        self.labelTitle.text = self.strTitle;
        self.labelTitle.textAlignment = NSTextAlignmentCenter;
        self.labelTitle.font = [UIFont systemFontOfSize:kFontTitle_Default];
        self.labelTitle.textColor = ASRGB(111, 111, 111);
        [self.viewContent addSubview:self.labelTitle];
        //
        y += kPerCotnentHeight;
    }
    
    //内容 滚动 视图
    self.scrollViewContent = [[ASScrollView alloc] initWithFrame:CGRectMake(0, y, AS_SCREEN_WIDTH, [self getScrollContentHeight])];
    self.scrollViewContent.backgroundColor = [UIColor clearColor];
    self.scrollViewContent.delaysContentTouches = NO;
    self.scrollViewContent.contentSize = CGSizeMake(AS_SCREEN_WIDTH, self.arrCotnents.count * kPerCotnentHeight);
    [self.viewContent addSubview:self.scrollViewContent];
    //循环创建button
    for (int i = 0; i < self.arrCotnents.count; i++) {
        UIButton *btnContent = [UIButton buttonWithType:(UIButtonTypeCustom)];
        btnContent.frame = CGRectMake(0, i * kPerCotnentHeight, AS_SCREEN_WIDTH, kPerCotnentHeight);
        btnContent.tag = 10000 + i;
        btnContent.titleLabel.font = [UIFont systemFontOfSize:kFontContent_Default];
        [btnContent setBackgroundImage:[self imageWithColor:ASRGBA(255, 255, 255, kPerItemAlpha_Normal)] forState:(UIControlStateNormal)];
        [btnContent setBackgroundImage:[self imageWithColor:ColorContentSelected] forState:(UIControlStateHighlighted)];
        [btnContent addTarget:self action:@selector(btnClickContent:) forControlEvents:(UIControlEventTouchUpInside)];
        
        if ([self.arrCotnents[i] isKindOfClass:[NSDictionary class]]) {//字典数组
            NSDictionary *dicObj = self.arrCotnents[i];
            [btnContent setTitle:dicObj[BSActionSheetContentTitleKey] forState:(UIControlStateNormal)];
            [btnContent setTitleColor:dicObj[BSActionSheetContentColorKey] forState:(UIControlStateNormal)];
        } else {//字符串数组
            [btnContent setTitle:self.arrCotnents[i] forState:(UIControlStateNormal)];
            [btnContent setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
        }
        
        [self.scrollViewContent addSubview:btnContent];
    }
    
    //取消按钮
    if (self.arrCotnents.count > kContentCount) {
        y += (kContentCount * kPerCotnentHeight + kSeparator_Height);
    } else {
        y += (self.arrCotnents.count * kPerCotnentHeight + kSeparator_Height);
    }
    self.btnCancel = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.btnCancel.frame = CGRectMake(0, y, AS_SCREEN_WIDTH, kPerCotnentHeight);
    [self.btnCancel setTitle:@"取消" forState:(UIControlStateNormal)];
    self.btnCancel.titleLabel.font = [UIFont systemFontOfSize:kFontContent_Default];
    [self.btnCancel setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
    [self.btnCancel setBackgroundImage:[self imageWithColor:[UIColor whiteColor]] forState:(UIControlStateNormal)];
    [self.btnCancel setBackgroundImage:[self imageWithColor:ColorContentSelected] forState:(UIControlStateHighlighted)];
    [self.btnCancel addTarget:self action:@selector(btnClickCancel) forControlEvents:(UIControlEventTouchUpInside)];
    [self.viewContent addSubview:self.btnCancel];
    //添加标题栏 线条
    if (self.strTitle) {
        UIView *viewLine = [[UIView alloc] initWithFrame:CGRectMake(0, kPerCotnentHeight, AS_SCREEN_WIDTH, kSeparatorLine_Height)];
        viewLine.backgroundColor = CellLineColor;
        [self.viewContent addSubview:viewLine];
    }
    //添加内容 线条
    if (self.arrCotnents.count > 0) {
        NSInteger lineCount = self.arrCotnents.count - 1;
        //线条
        for (int i = 0; i < lineCount; i++) {
            UIView *viewLine = [[UIView alloc] initWithFrame:CGRectMake(0, (i + 1) * kPerCotnentHeight, AS_SCREEN_WIDTH, kSeparatorLine_Height)];
            viewLine.backgroundColor = CellLineColor;
            [self.scrollViewContent addSubview:viewLine];
        }
    }
}

- (CGRect)getBottomCotnentFrame
{
    return CGRectMake(0, AS_SCREEN_HEIGHT - [self getMainContentHeight], AS_SCREEN_WIDTH, [self getMainContentHeight]);
}

- (CGFloat)getMainContentHeight
{
    //内容条目 最多有5个, 超过5个内容部分采用滚动模式
    if (self.strTitle) {//有标题
        if (self.arrCotnents.count > kContentCount) {
            return (kContentCount + 1) * kPerCotnentHeight + kSeparator_Height + kPerCotnentHeight;
        } else {
            return (self.arrCotnents.count + 1) * kPerCotnentHeight + kSeparator_Height + kPerCotnentHeight;
        }
    } else {//没有标题
        if (self.arrCotnents.count > kContentCount) {
            return kContentCount * kPerCotnentHeight + kSeparator_Height + kPerCotnentHeight;
        } else {
            return self.arrCotnents.count * kPerCotnentHeight + kSeparator_Height + kPerCotnentHeight;
        }
    }
}

- (CGFloat)getScrollContentHeight
{
    if (self.arrCotnents.count > kContentCount) {
        return kContentCount * kPerCotnentHeight;
    } else {
        return self.arrCotnents.count * kPerCotnentHeight;
    }
}

#pragma mark - action
- (void)tapSelf
{
    self.actionSheetCloseType = ActionSheetCloseType_TapSelf;
    [self closeSelf];
}

- (void)tapBottomContent
{
    
}

- (void)btnClickContent:(UIButton *)sender
{
    self.actionSheetCloseType = ActionSheetCloseType_ClickContent;
    self.btnCurrentClick = sender;
    [self closeSelf];
}

- (void)btnClickCancel
{
    self.actionSheetCloseType = ActionSheetCloseType_ClickCancel;
    [self closeSelf];
}

- (void)show
{
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.backgroundColor = ASRGBA(0, 0, 0, 0);
    //
    [UIView animateWithDuration:kAnimationTime animations:^{
        self.backgroundColor = ASRGBA(0, 0, 0, kMaskAlpha);
        self.viewContent.frame = [self getBottomCotnentFrame];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)closeSelf
{
    [UIView animateWithDuration:kAnimationTime animations:^{
        CGRect rectContent = [self getBottomCotnentFrame];
        self.viewContent.frame = CGRectMake(0, AS_SCREEN_HEIGHT, rectContent.size.width, rectContent.size.height);
        self.backgroundColor = ASRGBA(0, 0, 0, 0);
    } completion:^(BOOL finished) {
        switch (self.actionSheetCloseType) {
            case ActionSheetCloseType_TapSelf:
                break;
            case ActionSheetCloseType_ClickContent:
                if (self.clickContentBlock) {
                    self.clickContentBlock(self.btnCurrentClick.tag - 10000);
                }
                break;
            case ActionSheetCloseType_ClickCancel:
                if (self.clickCancelBlock) {
                    self.clickCancelBlock();
                }
                break;
            default:
                break;
        }
        //
        [self removeFromSuperview];
    }];
}

#pragma mark - 颜色生成图片
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - getter & setter
- (void)setColorTxtTitle:(UIColor *)colorTxtTitle
{
    if (_colorTxtTitle != colorTxtTitle) {
        _colorTxtTitle = colorTxtTitle;
    }
    self.labelTitle.textColor = colorTxtTitle;
}

- (void)setColorBtnCancel:(UIColor *)colorBtnCancel
{
    if (_colorBtnCancel != colorBtnCancel) {
        _colorBtnCancel = colorBtnCancel;
    }
    [self.btnCancel setTitleColor:colorBtnCancel forState:(UIControlStateNormal)];
}

- (void)setTxtCancel:(NSString *)txtCancel
{
    if (_txtCancel != txtCancel) {
        _txtCancel = txtCancel;
    }
    [self.btnCancel setTitle:txtCancel forState:(UIControlStateNormal)];
}

- (void)setFontTitle:(UIFont *)fontTitle
{
    if (_fontTitle != fontTitle) {
        _fontTitle = fontTitle;
    }
    self.labelTitle.font = fontTitle;
}

- (void)setFontCancel:(UIFont *)fontCancel
{
    if (_fontCancel != fontCancel) {
        _fontCancel = fontCancel;
    }
    self.btnCancel.titleLabel.font = fontCancel;
}

@end
