#line 1 "/Users/bear/Desktop/myApps/bluedXHook/bluedXHookDylib/Logos/bluedXHookDylib.xm"
;
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <string.h>


#define BEAR_PROMO_TRACE_ENABLED 1

static BOOL BearComesFromEnhancer(const void *caller) {
#if BEAR_PROMO_TRACE_ENABLED
    Dl_info symbol = {0};
    return caller != NULL && dladdr(caller, &symbol) != 0 &&
           symbol.dli_fname != NULL && strstr(symbol.dli_fname, "BluedEnhancer") != NULL;
#else
    return NO;
#endif
}

static BOOL BearClassBelongsToEnhancer(Class cls) {
#if BEAR_PROMO_TRACE_ENABLED
    const char *image = cls != Nil ? class_getImageName(cls) : NULL;
    return image != NULL && strstr(image, "BluedEnhancer") != NULL;
#else
    return NO;
#endif
}




#define BEAR_BLOCK_STARTUP_SPLASH 1
static NSString *const kBearStartupSplashClass = @"BDADX_Blued_Splash_Image_ViewController";

static BOOL BearIsStartupSplash(UIViewController *controller) {
    if (!controller) return NO;
    if ([NSStringFromClass(controller.class) isEqualToString:kBearStartupSplashClass]) return YES;
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        NSArray<UIViewController *> *stack = ((UINavigationController *)controller).viewControllers;
        return stack.count == 1 &&
               [NSStringFromClass(stack.firstObject.class) isEqualToString:kBearStartupSplashClass];
    }
    return NO;
}



@interface BDADX_Blued_Splash_Image_ViewController : UIViewController
- (void)presentBluedSplashImageViewController;
- (void)dealForSkipCloseSplashAd;
@end




#define BEAR_REPLACE_INTERNAL_LAUNCH_IMAGE 1
static CFAbsoluteTime kBearLaunchBeginTime = 0;
static BOOL BearIsEarlyLaunchAsset(NSString *name) {
#if BEAR_REPLACE_INTERNAL_LAUNCH_IMAGE
    if (name.length == 0) return NO;
    
    if (kBearLaunchBeginTime == 0 ||
        CFAbsoluteTimeGetCurrent() - kBearLaunchBeginTime > 30.0) return NO;
    return [name isEqualToString:@"launch_screen_new"] ||
           [name isEqualToString:@"launch_light"] ||
           [name isEqualToString:@"launch_dark"];
#else
    return NO;
#endif
}

static UIImage *BearStartupBrandImageForName(NSString *name, NSBundle *bundle) {
    if (bundle != nil && bundle != NSBundle.mainBundle) return nil;
    if (!BearIsEarlyLaunchAsset(name)) return nil;

    
    
    
    static UIImage *clearLaunchImage = nil;
    static dispatch_once_t clearOnce;
    dispatch_once(&clearOnce, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1.0);
        clearLaunchImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    if ([name isEqualToString:@"launch_screen_new"]) {
        NSLog(@"[bluedXHook][LaunchBrand] suppressed duplicate in-app launch_screen_new");
    } else {
        NSLog(@"[bluedXHook][LaunchBrand] suppressed old launch logo: %@", name);
    }
    return clearLaunchImage;
}


#include <objc/message.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

__attribute__((unused)) static void _logos_register_hook(Class _class, SEL _cmd, IMP _new, IMP *_old) {
unsigned int _count, _i;
Class _searchedClass = _class;
Method *_methods;
while (_searchedClass) {
_methods = class_copyMethodList(_searchedClass, &_count);
for (_i = 0; _i < _count; _i++) {
if (method_getName(_methods[_i]) == _cmd) {
if (_class == _searchedClass) {
*_old = method_setImplementation(_methods[_i], _new);
} else {
*_old = method_getImplementation(_methods[_i]);
class_addMethod(_class, _cmd, _new, method_getTypeEncoding(_methods[_i]));
}
free(_methods);
return;
}
}
free(_methods);
_searchedClass = class_getSuperclass(_searchedClass);
}
}
@class BDADX_Blued_Splash_Image_ViewController; @class UIWindow; @class UIImage; @class UINavigationController; @class UIAlertController; @class UIViewController; 
static Class _logos_supermetaclass$_ungrouped$UIImage; static UIImage * (*_logos_meta_orig$_ungrouped$UIImage$imageNamed$)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSString *);static UIImage * (*_logos_meta_orig$_ungrouped$UIImage$imageNamed$inBundle$compatibleWithTraitCollection$)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSString *, NSBundle *, UITraitCollection *);static Class _logos_superclass$_ungrouped$UIViewController; static void (*_logos_orig$_ungrouped$UIViewController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST, SEL, BOOL);static void (*_logos_orig$_ungrouped$UIViewController$viewWillDisappear$)(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST, SEL, BOOL);static void (*_logos_orig$_ungrouped$UIViewController$presentViewController$animated$completion$)(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST, SEL, UIViewController *, BOOL, void (^)(void));static void (*_logos_orig$_ungrouped$UIViewController$viewDidLayoutSubviews)(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST, SEL);static Class _logos_superclass$_ungrouped$BDADX_Blued_Splash_Image_ViewController; static void (*_logos_orig$_ungrouped$BDADX_Blued_Splash_Image_ViewController$presentBluedSplashImageViewController)(_LOGOS_SELF_TYPE_NORMAL BDADX_Blued_Splash_Image_ViewController* _LOGOS_SELF_CONST, SEL);static Class _logos_superclass$_ungrouped$UIWindow; static void (*_logos_orig$_ungrouped$UIWindow$makeKeyAndVisible)(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST, SEL);static Class _logos_superclass$_ungrouped$UINavigationController; static void (*_logos_orig$_ungrouped$UINavigationController$pushViewController$animated$)(_LOGOS_SELF_TYPE_NORMAL UINavigationController* _LOGOS_SELF_CONST, SEL, UIViewController *, BOOL);static Class _logos_supermetaclass$_ungrouped$UIAlertController; static UIAlertController* (*_logos_meta_orig$_ungrouped$UIAlertController$alertControllerWithTitle$message$preferredStyle$)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSString *, NSString *, UIAlertControllerStyle);

#line 95 "/Users/bear/Desktop/myApps/bluedXHook/bluedXHookDylib/Logos/bluedXHookDylib.xm"

static UIImage * _logos_meta_method$_ungrouped$UIImage$imageNamed$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * name) {
    UIImage *branded = BearStartupBrandImageForName(name, NSBundle.mainBundle);
    return branded ?: _logos_meta_orig$_ungrouped$UIImage$imageNamed$(self, _cmd, name);
}

static UIImage * _logos_meta_method$_ungrouped$UIImage$imageNamed$inBundle$compatibleWithTraitCollection$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * name, NSBundle * bundle, UITraitCollection * traitCollection) {
    UIImage *branded = BearStartupBrandImageForName(name, bundle);
    return branded ?: _logos_meta_orig$_ungrouped$UIImage$imageNamed$inBundle$compatibleWithTraitCollection$(self, _cmd, name, bundle, traitCollection);
}


#define BEAR_SETTINGS_TECH_UI 1


static NSString *const kBearPluginLabelText = @"Bear 来过 🐻";
static const NSInteger kBearPluginLabelTag = 20261030;

static UILabel *BearFindTextLabel(UIView *root, NSString *needle) {
    if ([root isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)root;
        NSString *text = label.text ?: label.attributedText.string;
        if ([text containsString:needle]) {
            return label;
        }
    }
    for (UIView *child in root.subviews) {
        UILabel *result = BearFindTextLabel(child, needle);
        if (result != nil) {
            return result;
        }
    }
    return nil;
}

static void BearPlaceCreditNearTelegram(UIViewController *controller) {
    if (BEAR_SETTINGS_TECH_UI ||
        ![NSStringFromClass(controller.class) isEqualToString:@"tjq"] ||
        ![controller isKindOfClass:[UITableViewController class]]) {
        return;
    }
    UITableView *table = ((UITableViewController *)controller).tableView;
    if (table == nil || !controller.isViewLoaded) {
        return;
    }

    
    
    UILabel *telegram = BearFindTextLabel(table, @"多啦B梦");
    UILabel *version = BearFindTextLabel(table, @"2.8.9 Final");
    if (version == nil) {
        version = BearFindTextLabel(table, @"Final终版");
    }

    
    UIView *anchor = version != nil ? version : telegram;
    if (anchor == nil || anchor.window == nil) {
        return;
    }

    CGRect anchorRect = [anchor convertRect:anchor.bounds toView:table];
    CGRect telegramRect = telegram != nil ?
        [telegram convertRect:telegram.bounds toView:table] : CGRectZero;

    
    CGFloat y = CGRectGetMaxY(anchorRect) + 3.0;
    if (telegram != nil && version != nil &&
        CGRectGetMinY(anchorRect) - CGRectGetMaxY(telegramRect) >= 24.0) {
        y = CGRectGetMaxY(telegramRect) + 3.0;
    }

    CGFloat width = MAX(0.0, CGRectGetWidth(table.bounds) - 24.0);
    CGRect creditFrame = CGRectMake(12.0, y, width, 19.0);
    UILabel *credit = (UILabel *)[table viewWithTag:kBearPluginLabelTag];
    if (credit == nil) {
        credit = [[UILabel alloc] initWithFrame:creditFrame];
        credit.tag = kBearPluginLabelTag;
        credit.text = kBearPluginLabelText;
        credit.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        credit.textColor = UIColor.labelColor;
        credit.textAlignment = NSTextAlignmentCenter;
        credit.backgroundColor = UIColor.clearColor;
        credit.userInteractionEnabled = NO;
        [table addSubview:credit];
        NSLog(@"[bluedXHook] TG/version anchor found. TG=%d version=%d; added credit at y=%.1f",
              telegram != nil, version != nil, y);
    } else {
        
        credit.frame = creditFrame;
    }

    
    
    UIEdgeInsets inset = table.contentInset;
    if (inset.bottom < 32.0) {
        inset.bottom = 32.0;
        table.contentInset = inset;
    }
}



static const NSInteger kTechFooterTag = 20261031;
static const NSInteger kTechDividerTag = 20261032;
static const NSInteger kTechHeaderTag = 20261033;
static char kTechOriginalBarKey, kTechOriginalTintKey, kTechOriginalBarStyleKey;
static char kTechOriginalScrollKey, kTechOriginalCompactKey, kTechTableInitializedKey;
static UIColor *TechRGB(CGFloat r,CGFloat g,CGFloat b) {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
}


static UIColor *TechBackground(void) { return TechRGB(242,241,246); }
static UIColor *TechCard(void) { return TechRGB(250,250,252); }
static UIColor *TechAccent(void) { return TechRGB(51,51,51); }
static UIColor *TechText(void) { return TechRGB(51,51,51); }
static UIColor *TechMuted(void) { return TechRGB(101,101,101); }
static UIColor *TechLine(void) { return TechRGB(226,226,226); }
static UIColor *TechSelected(void) { return TechRGB(227,228,253); }
static UIColor *TechHeaderTint(void) { return TechRGB(245,233,255); }

static UIImage *TechActionImage(CGSize size, CGFloat opacity) {
    size=CGSizeMake(MAX(1,ceil(size.width)),MAX(1,ceil(size.height)));
    static NSCache<NSString *,UIImage *> *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache=[NSCache new]; cache.countLimit=48; });
    NSString *key=[NSString stringWithFormat:@"%.0fx%.0f-%.2f",size.width,size.height,opacity];
    UIImage *cached=[cache objectForKey:key];
    if (cached) return cached;
    UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        CGRect rect=(CGRect){CGPointZero,size};
        [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:size.height/2.0] addClip];
        NSArray *colors=@[(id)[TechRGB(144,240,255) colorWithAlphaComponent:opacity].CGColor,
                          (id)[TechRGB(255,144,244) colorWithAlphaComponent:opacity].CGColor];
        CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient=CGGradientCreateWithColors(space,(__bridge CFArrayRef)colors,NULL);
        CGContextDrawLinearGradient(context.CGContext,gradient,
                                    CGPointMake(0,size.height/2.0),
                                    CGPointMake(size.width,size.height/2.0),0);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(space);
    }];
    [cache setObject:image forKey:key];
    return image;
}
static BOOL TechIsSettings(id vc) {
    return [NSStringFromClass([vc class]) isEqualToString:@"tjq"] &&
           [vc isKindOfClass:[UITableViewController class]];
}
static BOOL TechContainsSearch(UIView *v) {
    if ([v isKindOfClass:[UISearchBar class]]) return YES;
    for (UIView *child in v.subviews) if (TechContainsSearch(child)) return YES;
    return NO;
}
static NSString *TechBuildTime(void) {
    static NSString *stamp;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSDateFormatter *parser=[NSDateFormatter new], *output=[NSDateFormatter new];
        parser.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        parser.dateFormat=@"MMM d yyyy HH:mm:ss";
        output.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        output.dateFormat=@"yyyy-MM-dd HH:mm:ss";
        NSDate *date=[parser dateFromString:[NSString stringWithFormat:@"%s %s",__DATE__,__TIME__]];
        stamp=date ? [output stringFromDate:date] : [NSString stringWithFormat:@"%s %s",__DATE__,__TIME__];
    });
    return stamp;
}
static void TechStyleControls(UIView *view) {
    if (!view) return;
    if ([view isKindOfClass:[UISwitch class]]) {
        UISwitch *toggle=(UISwitch *)view;
        
        CGSize track=toggle.bounds.size;
        if (track.width<=0 || track.height<=0) track=CGSizeMake(51,31);
        toggle.onTintColor=[UIColor colorWithPatternImage:TechActionImage(track,1.0)];
        toggle.thumbTintColor=UIColor.whiteColor;
        toggle.tintColor=TechLine();
        
        return; 
    } else if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label=(UILabel *)view;
        label.textColor=TechText();
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button=(UIButton *)view;
        button.tintColor=TechAccent();
        [button setTitleColor:TechText() forState:UIControlStateNormal];
        [button setTitleColor:TechText() forState:UIControlStateHighlighted];
        [button setTitleColor:TechText() forState:UIControlStateSelected];
        [button setTitleColor:TechMuted() forState:UIControlStateDisabled];
        
        NSString *title=[button titleForState:UIControlStateNormal] ?: button.currentAttributedTitle.string;
        if (title.length>0 && CGRectGetWidth(button.bounds)>0 && CGRectGetHeight(button.bounds)>0) {
            CGSize size=button.bounds.size;
            [button setBackgroundImage:TechActionImage(size,1.0) forState:UIControlStateNormal];
            [button setBackgroundImage:TechActionImage(size,0.75) forState:UIControlStateHighlighted];
            [button setBackgroundImage:TechActionImage(size,1.0) forState:UIControlStateSelected];
            [button setBackgroundImage:TechActionImage(size,0.35) forState:UIControlStateDisabled];
        }
        return;
    }
    for (UIView *subview in view.subviews) TechStyleControls(subview);
}
static void TechStyleCell(UITableViewCell *cell, UITableView *table, NSIndexPath *path) {
    if (!cell) return;
    
    NSInteger count=(path && table) ? [table numberOfRowsInSection:path.section] : 0;
    BOOL first=(path && path.row==0), last=(path && path.row==count-1);
    CACornerMask corners=0;
    if (first) corners|=kCALayerMinXMinYCorner|kCALayerMaxXMinYCorner;
    if (last) corners|=kCALayerMinXMaxYCorner|kCALayerMaxXMaxYCorner;
    cell.backgroundColor=TechBackground();
    cell.tintColor=TechAccent();
    cell.contentView.backgroundColor=UIColor.clearColor;
    cell.contentView.layer.cornerRadius=0;
    cell.contentView.layer.borderWidth=0;
    cell.contentView.layer.masksToBounds=NO;
    if (!cell.backgroundView) cell.backgroundView=[UIView new];
    if (!cell.selectedBackgroundView) cell.selectedBackgroundView=[UIView new];
    for (UIView *surface in @[cell.backgroundView,cell.selectedBackgroundView]) {
        surface.backgroundColor=surface==cell.backgroundView ? TechCard() : TechSelected();
        surface.layer.cornerRadius=(first || last) ? 16 : 0;
        surface.layer.maskedCorners=corners;
        surface.layer.masksToBounds=YES;
        surface.userInteractionEnabled=NO;
    }
    TechStyleControls(cell.contentView);
    TechStyleControls(cell.accessoryView);
    if (cell.textLabel) {
        cell.textLabel.textColor=TechText();
        cell.textLabel.font=[UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        cell.textLabel.adjustsFontSizeToFitWidth=YES;
        cell.textLabel.minimumScaleFactor=0.85;
    }
    
    if (cell.detailTextLabel) {
        cell.detailTextLabel.textColor=TechMuted();
        cell.detailTextLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    }
    UIView *divider=[cell.contentView viewWithTag:kTechDividerTag];
    if (!divider) {
        divider=[UIView new]; divider.tag=kTechDividerTag;
        divider.backgroundColor=TechLine();
        divider.userInteractionEnabled=NO;
        divider.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        [cell.contentView addSubview:divider];
    }
    divider.hidden=last || count<=1;
    CGFloat scale=UIScreen.mainScreen.scale;
    CGFloat hairline=scale>0?1.0/scale:0.5;
    divider.frame=CGRectMake(18,MAX(0,CGRectGetHeight(cell.contentView.bounds)-hairline),
                             MAX(0,CGRectGetWidth(cell.contentView.bounds)-36),hairline);
}
static UITableViewCell *(*TechOriginalCell)(id,SEL,UITableView *,NSIndexPath *)=NULL;
static NSString *(*TechOriginalTitle)(id,SEL,UITableView *,NSInteger)=NULL;
static UITableViewCell *TechCell(id vc,SEL cmd,UITableView *table,NSIndexPath *path) {
    UITableViewCell *cell=TechOriginalCell?TechOriginalCell(vc,cmd,table,path):nil;
    TechStyleCell(cell,table,path);
    return cell;
}
static NSString *TechTitle(id vc,SEL cmd,UITableView *table,NSInteger section) {
    return section==0 ? nil : (TechOriginalTitle?TechOriginalTitle(vc,cmd,table,section):nil);
}
static CGFloat TechSectionHeight(id vc,SEL cmd,UITableView *table,NSInteger section) {
    return section==0 ? 0.01 : 36;
}
static void TechInstallCellHooks(Class cls) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Method method=class_getInstanceMethod(cls,@selector(tableView:cellForRowAtIndexPath:));
        Method title=class_getInstanceMethod(cls,@selector(tableView:titleForHeaderInSection:));
        if (method) TechOriginalCell=(UITableViewCell *(*)(id,SEL,UITableView *,NSIndexPath *))
            method_setImplementation(method,(IMP)TechCell);
        if (title) TechOriginalTitle=(NSString *(*)(id,SEL,UITableView *,NSInteger))
            method_setImplementation(title,(IMP)TechTitle);
        class_addMethod(cls,@selector(tableView:heightForHeaderInSection:),
                        (IMP)TechSectionHeight,"d32@0:8@16q24");
        NSLog(@"[bluedXHook][TechUI] tjq presentation hooks installed");
    });
}
static void TechHeader(UITableView *table) {
    UIView *existing=table.tableHeaderView;
    if (existing.tag==kTechHeaderTag && CGRectGetHeight(existing.frame)<=0.01) return;
    BOOL legacy=existing && (existing.tag==kTechHeaderTag || existing.tag==kTechFooterTag ||
        TechContainsSearch(existing) || BearFindTextLabel(existing,@"Blued增强插件") ||
        BearFindTextLabel(existing,@"2.8.9 Final"));
    if (existing && !legacy) return;
    
    UIView *spacer=[[UIView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(table.bounds),0.01)];
    spacer.tag=kTechHeaderTag;
    spacer.backgroundColor=TechBackground();
    spacer.userInteractionEnabled=NO;
    table.tableHeaderView=spacer;
}
static void TechFooter(UITableView *table) {
    UIView *existing=table.tableFooterView;
    if (existing && existing.tag==kTechFooterTag) return;
    if (existing && existing.subviews.count) return; 
    CGFloat width=CGRectGetWidth(table.bounds);
    UIView *footer=[[UIView alloc] initWithFrame:CGRectMake(0,0,width,96)];
    footer.tag=kTechFooterTag;
    footer.backgroundColor=TechBackground();
    footer.userInteractionEnabled=NO;
    UIView *line=[[UIView alloc] initWithFrame:CGRectMake(22,12,MAX(0,width-44),0.5)];
    line.autoresizingMask=UIViewAutoresizingFlexibleWidth;
    line.backgroundColor=TechLine();
    [footer addSubview:line];
    UILabel *version=[[UILabel alloc] initWithFrame:CGRectMake(12,23,width-24,20)];
    version.autoresizingMask=UIViewAutoresizingFlexibleWidth;
    version.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightSemibold];
    version.text=@"v1.0.0";
    version.textAlignment=NSTextAlignmentCenter;
    version.textColor=TechMuted();
    [footer addSubview:version];
    UILabel *time=[[UILabel alloc] initWithFrame:CGRectMake(12,45,width-24,19)];
    time.autoresizingMask=UIViewAutoresizingFlexibleWidth;
    time.font=[UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightRegular];
    time.text=TechBuildTime();
    time.textAlignment=NSTextAlignmentCenter;
    time.textColor=TechMuted();
    [footer addSubview:time];
    table.tableFooterView=footer;
}
static void TechNavigation(UIViewController *vc) {
    UINavigationBar *bar=vc.navigationController.navigationBar;
    if (!bar) return;
    if (vc.navigationItem.titleView.tag==kTechFooterTag &&
        objc_getAssociatedObject(bar,&kTechOriginalBarKey)) return; 
    if (!objc_getAssociatedObject(bar,&kTechOriginalBarKey)) {
        objc_setAssociatedObject(bar,&kTechOriginalBarKey,bar.standardAppearance,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(bar,&kTechOriginalScrollKey,bar.scrollEdgeAppearance ?: (id)NSNull.null,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(bar,&kTechOriginalCompactKey,bar.compactAppearance ?: (id)NSNull.null,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(bar,&kTechOriginalTintKey,bar.tintColor,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(bar,&kTechOriginalBarStyleKey,@(bar.barStyle),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UINavigationBarAppearance *a=[UINavigationBarAppearance new];
    [a configureWithOpaqueBackground];
    a.backgroundColor=TechHeaderTint();
    a.shadowColor=UIColor.clearColor;
    a.titleTextAttributes=@{NSForegroundColorAttributeName:TechText()};
    bar.standardAppearance=a;
    bar.scrollEdgeAppearance=a;
    bar.compactAppearance=a;
    bar.tintColor=TechAccent();
    bar.barStyle=UIBarStyleDefault;
    if (vc.navigationItem.titleView.tag!=kTechFooterTag) {
        UILabel *name=[UILabel new];
        name.tag=kTechFooterTag;
        name.accessibilityLabel=@"遇见pro";
        NSMutableAttributedString *text=[[NSMutableAttributedString alloc] initWithString:@"遇见pro"];
        [text addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18 weight:UIFontWeightBold],
            NSForegroundColorAttributeName:TechText()} range:NSMakeRange(0,text.length)];
        name.attributedText=text;
        [name sizeToFit];
        vc.navigationItem.title=@"遇见pro";
        vc.navigationItem.titleView=name;
    }
}
static void TechRestoreNavigation(UIViewController *vc) {
    UINavigationBar *bar=vc.navigationController.navigationBar;
    if (!bar) return;
    UINavigationBarAppearance *old=objc_getAssociatedObject(bar,&kTechOriginalBarKey);
    if (old) {
        bar.standardAppearance=old;
        id scroll=objc_getAssociatedObject(bar,&kTechOriginalScrollKey);
        id compact=objc_getAssociatedObject(bar,&kTechOriginalCompactKey);
        bar.scrollEdgeAppearance=(scroll==NSNull.null ? nil : scroll);
        bar.compactAppearance=(compact==NSNull.null ? nil : compact);
        objc_setAssociatedObject(bar,&kTechOriginalBarKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(bar,&kTechOriginalScrollKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(bar,&kTechOriginalCompactKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIColor *tint=objc_getAssociatedObject(bar,&kTechOriginalTintKey);
    if (tint) bar.tintColor=tint;
    NSNumber *style=objc_getAssociatedObject(bar,&kTechOriginalBarStyleKey);
    if (style) bar.barStyle=(UIBarStyle)style.integerValue;
    objc_setAssociatedObject(bar,&kTechOriginalTintKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(bar,&kTechOriginalBarStyleKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
static void TechApplySettings(UIViewController *vc) {
    if (!TechIsSettings(vc) || !vc.isViewLoaded) return;
    UITableView *table=((UITableViewController *)vc).tableView;
    if (!table) return;
    TechInstallCellHooks(vc.class);
    TechNavigation(vc);
    if (!objc_getAssociatedObject(table,&kTechTableInitializedKey)) {
        table.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;
        vc.view.backgroundColor=TechBackground();
        table.backgroundColor=TechBackground();
        table.separatorStyle=UITableViewCellSeparatorStyleNone;
        table.indicatorStyle=UIScrollViewIndicatorStyleBlack;
        table.rowHeight=56; table.estimatedRowHeight=56;
        table.sectionHeaderHeight=36; table.estimatedSectionHeaderHeight=0;
        objc_setAssociatedObject(table,&kTechTableInitializedKey,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    TechHeader(table);
    [[table viewWithTag:kBearPluginLabelTag] removeFromSuperview];
    for (UITableViewCell *cell in table.visibleCells) {
        TechStyleCell(cell,table,[table indexPathForCell:cell]);
    }
    for (NSInteger i=0;i<table.numberOfSections;i++) {
        UITableViewHeaderFooterView *section=[table headerViewForSection:i];
        if (!section) continue;
        if (i==0) { section.hidden=YES; continue; }
        section.hidden=NO;
        section.contentView.backgroundColor=TechBackground();
        section.textLabel.textColor=TechMuted();
        section.textLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    }
    TechFooter(table);
}





static void _logos_method$_ungrouped$UIViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    _logos_orig$_ungrouped$UIViewController$viewDidAppear$(self, _cmd, animated);
#if BEAR_BLOCK_STARTUP_SPLASH
    
    
    if (BearIsStartupSplash((UIViewController *)self)) {
        UIView *adView = self.view;
        NSLog(@"[bluedXHook][StartupAd] fallback: appeared by direct view insertion, superview=%@ root=%@",
              NSStringFromClass(adView.superview.class),
              NSStringFromClass(adView.window.rootViewController.class));
        adView.hidden = YES;
        adView.userInteractionEnabled = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            BDADX_Blued_Splash_Image_ViewController *splash =
                (BDADX_Blued_Splash_Image_ViewController *)self;
            [splash dealForSkipCloseSplashAd];
            [adView removeFromSuperview];
            NSLog(@"[bluedXHook][StartupAd] fallback: native skip/close completed, view detached");
        });
    }
#endif
#if BEAR_PROMO_TRACE_ENABLED
    if (BearClassBelongsToEnhancer(self.class)) {
        NSLog(@"[bluedXHook][PromoTrace] plugin controller appeared=%@ presentedBy=%@",
              NSStringFromClass(self.class), NSStringFromClass(self.presentingViewController.class));
    }
#endif
    if (TechIsSettings((UIViewController *)self)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            TechApplySettings((UIViewController *)self);
        });
    }
}


static void _logos_method$_ungrouped$UIViewController$viewWillDisappear$(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    if (TechIsSettings((UIViewController *)self)) TechRestoreNavigation((UIViewController *)self);
    _logos_orig$_ungrouped$UIViewController$viewWillDisappear$(self, _cmd, animated);
}

static void _logos_method$_ungrouped$UIViewController$presentViewController$animated$completion$(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIViewController * controller, BOOL animated, void (^completion)(void)) {
#if BEAR_BLOCK_STARTUP_SPLASH
    if (BearIsStartupSplash(controller)) {
        NSLog(@"[bluedXHook][StartupAd] blocked present host=%@ target=%@",
              NSStringFromClass(self.class), NSStringFromClass(controller.class));
        if (completion) completion();
        return;
    }
#endif
#if BEAR_PROMO_TRACE_ENABLED
    
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0))) ||
        BearClassBelongsToEnhancer(controller.class)) {
        NSString *alertTitle = @"";
        NSString *alertMessage = @"";
        if ([controller isKindOfClass:[UIAlertController class]]) {
            UIAlertController *alert = (UIAlertController *)controller;
            alertTitle = alert.title ?: @"";
            alertMessage = alert.message ?: @"";
        }
        NSLog(@"[bluedXHook][PromoTrace] present host=%@ target=%@ owner=%d title=%@ message=%@",
              NSStringFromClass(self.class), NSStringFromClass(controller.class),
              BearClassBelongsToEnhancer(controller.class), alertTitle, alertMessage);
    }
#endif
    _logos_orig$_ungrouped$UIViewController$presentViewController$animated$completion$(self, _cmd, controller, animated, completion);
}
static void _logos_method$_ungrouped$UIViewController$viewDidLayoutSubviews(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$_ungrouped$UIViewController$viewDidLayoutSubviews(self, _cmd);
    if (TechIsSettings((UIViewController *)self)) {
        TechApplySettings((UIViewController *)self);
    }
}







#if BEAR_BLOCK_STARTUP_SPLASH

static void _logos_method$_ungrouped$BDADX_Blued_Splash_Image_ViewController$presentBluedSplashImageViewController(_LOGOS_SELF_TYPE_NORMAL BDADX_Blued_Splash_Image_ViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    NSLog(@"[bluedXHook][StartupAd] blocked native splash presentation; running native skip/close");
    [self dealForSkipCloseSplashAd];
    
}

#endif

#if BEAR_PROMO_TRACE_ENABLED

static void _logos_method$_ungrouped$UIWindow$makeKeyAndVisible(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0)))) {
        NSLog(@"[bluedXHook][PromoTrace] window makeKeyAndVisible root=%@ level=%.1f",
              NSStringFromClass(self.rootViewController.class), self.windowLevel);
    }
    _logos_orig$_ungrouped$UIWindow$makeKeyAndVisible(self, _cmd);
}

#endif

#if BEAR_PROMO_TRACE_ENABLED

static void _logos_method$_ungrouped$UINavigationController$pushViewController$animated$(_LOGOS_SELF_TYPE_NORMAL UINavigationController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIViewController * controller, BOOL animated) {
#if BEAR_BLOCK_STARTUP_SPLASH
    if (BearIsStartupSplash(controller)) {
        NSLog(@"[bluedXHook][StartupAd] blocked navigation push target=%@",
              NSStringFromClass(controller.class));
        return;
    }
#endif
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0))) ||
        BearClassBelongsToEnhancer(controller.class)) {
        NSLog(@"[bluedXHook][PromoTrace] navigation push target=%@ parent=%@",
              NSStringFromClass(controller.class), NSStringFromClass(self.class));
    }
    _logos_orig$_ungrouped$UINavigationController$pushViewController$animated$(self, _cmd, controller, animated);
}



static UIAlertController* _logos_meta_method$_ungrouped$UIAlertController$alertControllerWithTitle$message$preferredStyle$(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * title, NSString * message, UIAlertControllerStyle style) {
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0)))) {
        NSLog(@"[bluedXHook][PromoTrace] plugin alert created title=%@ message=%@", title ?: @"", message ?: @"");
    }
    return _logos_meta_orig$_ungrouped$UIAlertController$alertControllerWithTitle$message$preferredStyle$(self, _cmd, title, message, style);
}

#endif

static __attribute__((constructor)) void _logosLocalCtor_e5b54f5a(int __unused argc, char __unused **argv, char __unused **envp) {
    kBearLaunchBeginTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"[bluedXHook] TG area credit hook initialized");
    {Class _logos_class$_ungrouped$UIImage = objc_getClass("UIImage"); Class _logos_metaclass$_ungrouped$UIImage = object_getClass(_logos_class$_ungrouped$UIImage); _logos_supermetaclass$_ungrouped$UIImage = class_getSuperclass(_logos_metaclass$_ungrouped$UIImage); { _logos_register_hook(_logos_metaclass$_ungrouped$UIImage, @selector(imageNamed:), (IMP)&_logos_meta_method$_ungrouped$UIImage$imageNamed$, (IMP *)&_logos_meta_orig$_ungrouped$UIImage$imageNamed$);}{ _logos_register_hook(_logos_metaclass$_ungrouped$UIImage, @selector(imageNamed:inBundle:compatibleWithTraitCollection:), (IMP)&_logos_meta_method$_ungrouped$UIImage$imageNamed$inBundle$compatibleWithTraitCollection$, (IMP *)&_logos_meta_orig$_ungrouped$UIImage$imageNamed$inBundle$compatibleWithTraitCollection$);}Class _logos_class$_ungrouped$UIViewController = objc_getClass("UIViewController"); _logos_superclass$_ungrouped$UIViewController = class_getSuperclass(_logos_class$_ungrouped$UIViewController); { _logos_register_hook(_logos_class$_ungrouped$UIViewController, @selector(viewDidAppear:), (IMP)&_logos_method$_ungrouped$UIViewController$viewDidAppear$, (IMP *)&_logos_orig$_ungrouped$UIViewController$viewDidAppear$);}{ _logos_register_hook(_logos_class$_ungrouped$UIViewController, @selector(viewWillDisappear:), (IMP)&_logos_method$_ungrouped$UIViewController$viewWillDisappear$, (IMP *)&_logos_orig$_ungrouped$UIViewController$viewWillDisappear$);}{ _logos_register_hook(_logos_class$_ungrouped$UIViewController, @selector(presentViewController:animated:completion:), (IMP)&_logos_method$_ungrouped$UIViewController$presentViewController$animated$completion$, (IMP *)&_logos_orig$_ungrouped$UIViewController$presentViewController$animated$completion$);}{ _logos_register_hook(_logos_class$_ungrouped$UIViewController, @selector(viewDidLayoutSubviews), (IMP)&_logos_method$_ungrouped$UIViewController$viewDidLayoutSubviews, (IMP *)&_logos_orig$_ungrouped$UIViewController$viewDidLayoutSubviews);}Class _logos_class$_ungrouped$BDADX_Blued_Splash_Image_ViewController = objc_getClass("BDADX_Blued_Splash_Image_ViewController"); _logos_superclass$_ungrouped$BDADX_Blued_Splash_Image_ViewController = class_getSuperclass(_logos_class$_ungrouped$BDADX_Blued_Splash_Image_ViewController); { _logos_register_hook(_logos_class$_ungrouped$BDADX_Blued_Splash_Image_ViewController, @selector(presentBluedSplashImageViewController), (IMP)&_logos_method$_ungrouped$BDADX_Blued_Splash_Image_ViewController$presentBluedSplashImageViewController, (IMP *)&_logos_orig$_ungrouped$BDADX_Blued_Splash_Image_ViewController$presentBluedSplashImageViewController);}Class _logos_class$_ungrouped$UIWindow = objc_getClass("UIWindow"); _logos_superclass$_ungrouped$UIWindow = class_getSuperclass(_logos_class$_ungrouped$UIWindow); { _logos_register_hook(_logos_class$_ungrouped$UIWindow, @selector(makeKeyAndVisible), (IMP)&_logos_method$_ungrouped$UIWindow$makeKeyAndVisible, (IMP *)&_logos_orig$_ungrouped$UIWindow$makeKeyAndVisible);}Class _logos_class$_ungrouped$UINavigationController = objc_getClass("UINavigationController"); _logos_superclass$_ungrouped$UINavigationController = class_getSuperclass(_logos_class$_ungrouped$UINavigationController); { _logos_register_hook(_logos_class$_ungrouped$UINavigationController, @selector(pushViewController:animated:), (IMP)&_logos_method$_ungrouped$UINavigationController$pushViewController$animated$, (IMP *)&_logos_orig$_ungrouped$UINavigationController$pushViewController$animated$);}Class _logos_class$_ungrouped$UIAlertController = objc_getClass("UIAlertController"); Class _logos_metaclass$_ungrouped$UIAlertController = object_getClass(_logos_class$_ungrouped$UIAlertController); _logos_supermetaclass$_ungrouped$UIAlertController = class_getSuperclass(_logos_metaclass$_ungrouped$UIAlertController); { _logos_register_hook(_logos_metaclass$_ungrouped$UIAlertController, @selector(alertControllerWithTitle:message:preferredStyle:), (IMP)&_logos_meta_method$_ungrouped$UIAlertController$alertControllerWithTitle$message$preferredStyle$, (IMP *)&_logos_meta_orig$_ungrouped$UIAlertController$alertControllerWithTitle$message$preferredStyle$);}}
}

