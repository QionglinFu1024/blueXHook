%config(generator=internal);
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <string.h>

// PromoTrace is diagnostic-only: no presentation is blocked or dismissed.
#define BEAR_PROMO_TRACE_ENABLED 1

static BOOL BearComesFromEnhancer(const void *caller) {
#if BEAR_PROMO_TRACE_ENABLED
    Dl_info symbol = {0};
    return caller != NULL && dladdr(caller, &symbol) != 0 &&
           symbol.dli_fname != NULL && strstr(symbol.dli_fname, "YuJianProCore.dylib") != NULL;
#else
    return NO;
#endif
}

static BOOL BearClassBelongsToEnhancer(Class cls) {
#if BEAR_PROMO_TRACE_ENABLED
    const char *image = cls != Nil ? class_getImageName(cls) : NULL;
    return image != NULL && strstr(image, "YuJianProCore.dylib") != NULL;
#else
    return NO;
#endif
}

// The startup splash image ad is owned by Blued itself (verified in the
// 2026-10-30 launch log), not by BluedEnhancer. Match only this exact
// controller; other Blued ads and every enhancer feature are untouched.
#define BEAR_BLOCK_STARTUP_SPLASH 1
static NSString *const kBearStartupSplashClass = @"BDADX_Blued_Splash_Image_ViewController";

static BOOL BearIsStartupSplash(UIViewController *controller) {
    if (!controller) return NO;
    if ([NSStringFromClass(controller.class) isEqualToString:kBearStartupSplashClass]) return YES;
    // Only unwrap a navigation controller whose sole root is the splash.
    if ([controller isKindOfClass:[UINavigationController class]]) {
        NSArray<UIViewController *> *stack = ((UINavigationController *)controller).viewControllers;
        return stack.count == 1 &&
               [NSStringFromClass(stack.firstObject.class) isEqualToString:kBearStartupSplashClass];
    }
    return NO;
}

// This class is present in Blued's own ObjC class table. Its native
// dealForSkipCloseSplashAd calls the supplied skip handler and dismisses the ad.
@interface BDADX_Blued_Splash_Image_ViewController : UIViewController
- (void)presentBluedSplashImageViewController;
- (void)dealForSkipCloseSplashAd;
@end

// The app creates a second launch image overlay after iOS has already shown
// our branded LaunchScreen. Keep only the system LaunchScreen visually:
// suppress the in-process legacy images instead of showing MeetPro twice.
#define BEAR_REPLACE_INTERNAL_LAUNCH_IMAGE 1
static CFAbsoluteTime kBearLaunchBeginTime = 0;
static BOOL BearIsEarlyLaunchAsset(NSString *name) {
#if BEAR_REPLACE_INTERNAL_LAUNCH_IMAGE
    if (name.length == 0) return NO;
    // Avoid altering unrelated in-app UI after the initial loading period.
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

    // Return a valid transparent UIImage rather than nil: nil would let some
    // app code fall back to the original Assets.car and display Blued again.
    // This also avoids adding any new window/view or changing startup timing.
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

%hook UIImage
+ (UIImage *)imageNamed:(NSString *)name {
    UIImage *branded = BearStartupBrandImageForName(name, NSBundle.mainBundle);
    return branded ?: %orig;
}

+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle compatibleWithTraitCollection:(UITraitCollection *)traitCollection {
    UIImage *branded = BearStartupBrandImageForName(name, bundle);
    return branded ?: %orig;
}
%end

#define BEAR_SETTINGS_TECH_UI 1
// The credit belongs beside the existing BluedEnhancer Telegram/version area,
// not at the end of UITableView.tableFooterView.
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

    // These are the exact strings identified in the original dylib.
    // UIKit may render them inside a cell, header, or the custom settings view.
    UILabel *telegram = BearFindTextLabel(table, @"多啦B梦");
    UILabel *version = BearFindTextLabel(table, @"2.8.9 Final");
    if (version == nil) {
        version = BearFindTextLabel(table, @"Final终版");
    }

    // Without an actual visible anchor, do not guess a fixed bottom position.
    UIView *anchor = version != nil ? version : telegram;
    if (anchor == nil || anchor.window == nil) {
        return;
    }

    CGRect anchorRect = [anchor convertRect:anchor.bounds toView:table];
    CGRect telegramRect = telegram != nil ?
        [telegram convertRect:telegram.bounds toView:table] : CGRectZero;

    // Prefer immediately under the TG text when the gap to version allows it.
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
        // Table/cell layout may change; follow the existing version text.
        credit.frame = creditFrame;
    }

    // Allow scrolling to the credit even if the plugin's version is its last row.
    // This does not move or replace the Telegram action or original labels.
    UIEdgeInsets inset = table.contentInset;
    if (inset.bottom < 32.0) {
        inset.bottom = 32.0;
        table.contentInset = inset;
    }
}


// Isolated "遇见pro" visual skin. Never replace the original switches/data source.
static const NSInteger kTechFooterTag = 20261031;
static const NSInteger kTechDividerTag = 20261032;
static const NSInteger kTechHeaderTag = 20261033;
static char kTechOriginalBarKey, kTechOriginalTintKey, kTechOriginalBarStyleKey;
static char kTechOriginalScrollKey, kTechOriginalCompactKey, kTechTableInitializedKey;
static UIColor *TechRGB(CGFloat r,CGFloat g,CGFloat b) {
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
}
// Palette from alinye's design sources: light lavender-gray, near-white,
// charcoal text and a soft pink/lilac header wash.
static UIColor *TechBackground(void) { return TechRGB(242,241,246); }
static UIColor *TechCard(void) { return TechRGB(250,250,252); }
static UIColor *TechAccent(void) { return TechRGB(51,51,51); }
static UIColor *TechText(void) { return TechRGB(51,51,51); }
static UIColor *TechMuted(void) { return TechRGB(101,101,101); }
static UIColor *TechLine(void) { return TechRGB(226,226,226); }
static UIColor *TechSelected(void) { return TechRGB(227,228,253); }
static UIColor *TechHeaderTint(void) { return TechRGB(245,233,255); }
// "选择TA合页" uses a cyan-to-pink pill with charcoal lettering.
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
        // Native UISwitch still owns its state, thumb, hit target and animation.
        // UISwitch derives solid color components internally. A pattern color
        // cannot supply them and crashes UIKit while it builds the track colors.
        toggle.onTintColor=TechRGB(40,115,255);
        toggle.thumbTintColor=UIColor.whiteColor;
        toggle.tintColor=TechLine();
        // Preserve the native state, targets and accessibility behavior.
        return; // Do not recolor UIKit's internal switch labels.
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
        // Keep icon-only actions clear; apply the reference pill to text actions.
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
    // Style the full cell background so accessories share the same surface.
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
    // Apply secondary color after traversing labels, otherwise it is overwritten.
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
    // A minimal spacer suppresses UIKit's automatic header gap.
    UIView *spacer=[[UIView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(table.bounds),0.01)];
    spacer.tag=kTechHeaderTag;
    spacer.backgroundColor=TechBackground();
    spacer.userInteractionEnabled=NO;
    table.tableHeaderView=spacer;
}
static void TechFooter(UITableView *table) {
    UIView *existing=table.tableFooterView;
    if (existing && existing.tag==kTechFooterTag) return;
    if (existing && existing.subviews.count) return; // preserve unknown original actions
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
        objc_getAssociatedObject(bar,&kTechOriginalBarKey)) return; // Avoid repeated nav layout.
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
        name.accessibilityLabel=@"遇见Bro";
        NSMutableAttributedString *text=[[NSMutableAttributedString alloc] initWithString:@"遇见Bro"];
        [text addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18 weight:UIFontWeightBold],
            NSForegroundColorAttributeName:TechText()} range:NSMakeRange(0,text.length)];
        name.attributedText=text;
        [name sizeToFit];
        vc.navigationItem.title=@"遇见Bro";
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


// MARK: - MeetPro entry migration (UI only; original Enhancer dylib stays loaded)
static const NSInteger kBearMeetProButtonTag = 2026110101;
static char kBearHiddenSettingsRowKey, kBearSettingsRowUpdateKey, kBearOriginalTGButtonKey;

static UIViewController *BearOwningController(UIResponder *responder) {
    UIResponder *next = responder;
    for (NSInteger i=0; next && i<32; i++, next=next.nextResponder) {
        if ([next isKindOfClass:[UIViewController class]]) return (UIViewController *)next;
    }
    return nil;
}

static UIImage *BearMeetProEntryIcon(void) {
    static UIImage *image;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *path = [NSBundle.mainBundle pathForResource:@"MeetProIcon60x60@3x" ofType:@"png"];
        if (path) image = [UIImage imageWithContentsOfFile:path];
    });
    return image;
}

static void BearOpenEnhancerSettings(UIView *source) {
    Class settingsClass = objc_getClass("tjq");
    UIViewController *owner = BearOwningController(source);
    if (!owner || !settingsClass || ![settingsClass isSubclassOfClass:[UIViewController class]]) {
        NSLog(@"[bluedXHook][Entry] Cannot open enhancer settings, owner=%@ tjq=%@",
              owner, settingsClass);
        if (owner && !settingsClass) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"遇见Bro"
                message:@"插件设置尚未就绪，请稍后重试。" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                style:UIAlertActionStyleDefault handler:nil]];
            [owner presentViewController:alert animated:YES completion:nil];
        }
        return;
    }
    UINavigationController *navigation = owner.navigationController;
    if (navigation && [navigation.topViewController isKindOfClass:settingsClass]) return;
    UIViewController *vc = [[settingsClass alloc] init];
    if (!vc) return;
    vc.hidesBottomBarWhenPushed = YES;
    if (navigation) {
        [navigation pushViewController:vc animated:YES];
    } else {
        UINavigationController *wrap = [[UINavigationController alloc] initWithRootViewController:vc];
        [owner presentViewController:wrap animated:YES completion:nil];
    }
    NSLog(@"[bluedXHook][Entry] opened existing %@ from %@", settingsClass, owner.class);
}

static BOOL BearLooksLikeTelegramControl(UIButton *button) {
    NSMutableString *tokens = [NSMutableString string];
    for (NSString *s in @[
        button.currentTitle ?: @"",
        button.accessibilityLabel ?: @"",
        button.accessibilityIdentifier ?: @""
    ]) {
        if (s.length) [tokens appendFormat:@" %@ ", s.lowercaseString];
    }
    for (id target in button.allTargets) {
        NSArray *actions = [button actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
        for (NSString *action in actions) [tokens appendFormat:@" %@ ", action.lowercaseString];
    }
    NSString *txt = tokens.lowercaseString;
    return [txt containsString:@"telegram"] ||
           [txt containsString:@"opentg"] ||
           [txt containsString:@"tgbutton"] ||
           [txt containsString:@"open_tg"] ||
           [txt containsString:@"taptg"] ||
           [txt containsString:@"clicktg"] ||
           [txt containsString:@" tg "];
}

// Detect the actual TG control rather than guessing a coordinate beside Settings.
// Native Mine navigation controls are known from BDMineTransNavView's class:
// settingBtn, qualificationBtn and myAvatarBtn. An extra small interactive view
// in the same top-right row can be the injected TG control.
static BOOL BearViewInsideView(UIView *view, UIView *container) {
    return container && (view==container || [view isDescendantOfView:container]);
}

static void BearCollectMineTapViews(UIView *root, NSMutableArray<UIView *> *views) {
    if ([root isKindOfClass:[UIControl class]] || root.gestureRecognizers.count) {
        [views addObject:root];
    }
    for (UIView *child in root.subviews) BearCollectMineTapViews(child, views);
}

static BOOL BearButtonTargetIsEnhancer(UIButton *button) {
    for (id target in button.allTargets) {
        if (BearClassBelongsToEnhancer([target class])) return YES;
        for (NSString *selector in [button actionsForTarget:target
                                               forControlEvent:UIControlEventTouchUpInside]) {
            Method method=class_getInstanceMethod([target class],NSSelectorFromString(selector));
            if (!method) continue;
            Dl_info info={0};
            if (dladdr((void *)method_getImplementation(method),&info) &&
                info.dli_fname && strstr(info.dli_fname,"YuJianProCore.dylib")) return YES;
        }
    }
    return NO;
}

static UIView *BearFindOriginalMineTG(UIView *nav, UIButton *entry) {
    UIButton *setting=nil, *qualification=nil, *avatar=nil;
    @try {
        setting=[nav valueForKey:@"settingBtn"];
        qualification=[nav valueForKey:@"qualificationBtn"];
        avatar=[nav valueForKey:@"myAvatarBtn"];
    } @catch (__unused NSException *e) {}
    if (![setting isKindOfClass:[UIButton class]] || !setting.superview) return nil;
    if (![qualification isKindOfClass:[UIButton class]]) qualification=nil;
    if (![avatar isKindOfClass:[UIButton class]]) avatar=nil;
    CGRect gear=[setting convertRect:setting.bounds toView:nav];

    NSMutableArray<UIView *> *tapViews=[NSMutableArray array];
    BearCollectMineTapViews(nav,tapViews);
    NSMutableArray<UIView *> *unknown=[NSMutableArray array];
    for (UIView *view in tapViews) {
        if (view==nav || view==entry || view.hidden || view.alpha < 0.05 ||
            !view.superview || BearViewInsideView(view,setting) ||
            BearViewInsideView(view,qualification) ||
            BearViewInsideView(view,avatar)) continue;
        CGRect rect=[view convertRect:view.bounds toView:nav];
        // Exclude the Mine content, invisible elements and large overlays.
        if (rect.size.width < 18 || rect.size.height < 18 ||
            rect.size.width > 62 || rect.size.height > 62 ||
            CGRectGetMidX(rect) < CGRectGetWidth(nav.bounds)*0.48 ||
            fabs(CGRectGetMidY(rect)-CGRectGetMidY(gear)) > 32) continue;
        if (CGRectIntersectsRect(CGRectInset(rect,3,3),gear)) continue;
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button=(UIButton *)view;
            if (BearLooksLikeTelegramControl(button) || BearButtonTargetIsEnhancer(button)) {
                NSLog(@"[bluedXHook][Entry] TG matched via original button target=%@",
                      button.accessibilityIdentifier ?: @"(none)");
                return button;
            }
        }
        // A UIView/UIImageView with a tap recognizer is also a possible TG
        // injection, not just a named UIButton.
        if ([view isKindOfClass:[UIControl class]] || view.gestureRecognizers.count) {
            [unknown addObject:view];
        }
    }
    if (unknown.count==1) {
        NSLog(@"[bluedXHook][Entry] TG matched as sole extra Mine nav control class=%@",
              NSStringFromClass([unknown.firstObject class]));
        return unknown.firstObject;
    }
    static char kBearMissingTGLoggedKey;
    if (!objc_getAssociatedObject(nav,&kBearMissingTGLoggedKey)) {
        objc_setAssociatedObject(nav,&kBearMissingTGLoggedKey,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSLog(@"[bluedXHook][Entry] TG not identified: %lu candidates; no extra Pro entry added",
              (unsigned long)unknown.count);
        for (UIView *view in unknown) {
            CGRect rect=[view convertRect:view.bounds toView:nav];
            NSLog(@"[bluedXHook][Entry] candidate class=%@ frame=%@",
                  NSStringFromClass(view.class),NSStringFromCGRect(rect));
        }
    }
    return nil;
}

static void BearApplyMineEntry(UIView *nav) {
    if (!nav || !nav.window || !objc_getClass("tjq")) return;
    UIButton *entry=(UIButton *)[nav viewWithTag:kBearMeetProButtonTag];
    if (entry && ![entry isKindOfClass:[UIButton class]]) return;

    UIView *oldTG=objc_getAssociatedObject(nav,&kBearOriginalTGButtonKey);
    if (oldTG && !oldTG.superview) {
        objc_setAssociatedObject(nav,&kBearOriginalTGButtonKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        oldTG=nil;
    }
    if (!oldTG) {
        oldTG=BearFindOriginalMineTG(nav,entry);
        if (oldTG) objc_setAssociatedObject(nav,&kBearOriginalTGButtonKey,oldTG,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // Never add another button in a guessed empty slot. Leave the original TG
    // and fallback settings intact until its actual UIKit control is identified.
    if (!oldTG) {
        [entry removeFromSuperview];
        return;
    }
    CGRect oldFrame=[oldTG convertRect:oldTG.bounds toView:nav];
    if (CGRectIsEmpty(oldFrame) || !isfinite(oldFrame.origin.x) ||
        !isfinite(oldFrame.origin.y)) return;
    // Preserve original Auto Layout spacing (UIStackView removes hidden items).
    oldTG.alpha=0;
    oldTG.userInteractionEnabled=NO;

    if (!entry) {
        entry=[UIButton buttonWithType:UIButtonTypeCustom];
        entry.tag=kBearMeetProButtonTag;
        entry.accessibilityLabel=@"遇见Bro插件设置";
        entry.accessibilityIdentifier=@"bear.meetpro.entry";
        UIImage *icon=BearMeetProEntryIcon();
        if (icon) [entry setImage:icon forState:UIControlStateNormal];
        else [entry setTitle:@"Pro" forState:UIControlStateNormal];
        entry.imageView.contentMode=UIViewContentModeScaleAspectFit;
        entry.clipsToBounds=YES;
        entry.layer.cornerRadius=10;
        entry.backgroundColor=[UIColor colorWithRed:0.06 green:0.08 blue:0.14 alpha:1];
        __weak UIView *weakNav=nav;
        [entry addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            UIView *strongNav=weakNav;
            if (strongNav) BearOpenEnhancerSettings(strongNav);
        }] forControlEvents:UIControlEventTouchUpInside];
        [nav addSubview:entry];
        NSLog(@"[bluedXHook][Entry] replaced original TG control at %@",
              NSStringFromCGRect(oldFrame));
    }
    entry.frame=oldFrame;
    [nav bringSubviewToFront:entry];
}

static BOOL BearContainsEnhancerEntry(UIView *root) {
    if (!root) return NO;
    if ([root isKindOfClass:[UILabel class]]) {
        UILabel *label=(UILabel *)root;
        NSString *text=label.text ?: label.attributedText.string;
        if ([text containsString:@"Blued增强设置"]) return YES;
    }
    for (UIView *child in root.subviews) if (BearContainsEnhancerEntry(child)) return YES;
    return NO;
}

static void BearHideLegacySettingsEntry(UIViewController *controller) {
    if (!controller || ![NSStringFromClass(controller.class) isEqualToString:@"BDSettingViewController"]) return;
    if (!objc_getClass("tjq")) return; // Do not hide the fallback before plugin loads.
    UITableView *table = nil;
    @try { table = [(id)controller valueForKey:@"contentTable"]; }
    @catch (__unused NSException *e) {}
    if (![table isKindOfClass:[UITableView class]]) return;

    // Handle a custom header insertion without discarding unrelated sections.
    UIView *header = table.tableHeaderView;
    if (BearContainsEnhancerEntry(header) && CGRectGetHeight(header.frame)>0.5) {
        CGRect frame=header.frame;
        frame.size.height=0.01;
        header.frame=frame;
        table.tableHeaderView=header;
        header.hidden=YES;
        NSLog(@"[bluedXHook][Entry] collapsed enhancer settings tableHeaderView");
    }

    for (UITableViewCell *cell in table.visibleCells) {
        if (!BearContainsEnhancerEntry(cell)) continue;
        NSIndexPath *index=[table indexPathForCell:cell];
        if (!index) continue;
        NSIndexPath *previous=objc_getAssociatedObject(table,&kBearHiddenSettingsRowKey);
        cell.hidden=YES;
        cell.userInteractionEnabled=NO;
        if ([previous isEqual:index]) return;
        objc_setAssociatedObject(table,&kBearHiddenSettingsRowKey,index,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (objc_getAssociatedObject(table,&kBearSettingsRowUpdateKey)) return;
        objc_setAssociatedObject(table,&kBearSettingsRowUpdateKey,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (table.window && [table.dataSource numberOfSectionsInTableView:table] > index.section &&
                [table.dataSource tableView:table numberOfRowsInSection:index.section] > index.row) {
                [table beginUpdates];
                [table endUpdates];
                NSLog(@"[bluedXHook][Entry] collapsed legacy settings row %@",index);
            }
            objc_setAssociatedObject(table,&kBearSettingsRowUpdateKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        });
        return;
    }
}

%hook BDMineTransNavView
- (void)layoutSubviews {
    %orig;
    BearApplyMineEntry((UIView *)self);
}
%end

%hook BDSettingViewController
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *hidden = objc_getAssociatedObject(tableView,&kBearHiddenSettingsRowKey);
    if (hidden && [hidden isEqual:indexPath]) return 0.01;
    return %orig(tableView,indexPath);
}
%end

// We know the settings class (tjq) because its heOpenTelegram method appears
// in BluedEnhancer, but hook the UIKit superclass so late class loading is OK.
%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
#if BEAR_BLOCK_STARTUP_SPLASH
    // This covers any alternate code path adding the splash view directly to
    // the existing root window, bypassing the class's own present method.
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
    if ([NSStringFromClass(self.class) isEqualToString:@"BDSettingViewController"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BearHideLegacySettingsEntry((UIViewController *)self);
        });
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    if (TechIsSettings((UIViewController *)self)) TechRestoreNavigation((UIViewController *)self);
    %orig(animated);
}

- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion {
#if BEAR_BLOCK_STARTUP_SPLASH
    if (BearIsStartupSplash(controller)) {
        NSLog(@"[bluedXHook][StartupAd] blocked present host=%@ target=%@",
              NSStringFromClass(self.class), NSStringFromClass(controller.class));
        if (completion) completion();
        return;
    }
#endif
#if BEAR_PROMO_TRACE_ENABLED
    // Only observe presentations initiated by the enhancer itself, not all Blued UI.
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
    %orig(controller, animated, completion);
}
- (void)viewDidLayoutSubviews {
    %orig;
    if (TechIsSettings((UIViewController *)self)) {
        TechApplySettings((UIViewController *)self);
    } else if ([NSStringFromClass(self.class) isEqualToString:@"BDSettingViewController"]) {
        BearHideLegacySettingsEntry((UIViewController *)self);
    }
}

%end


// Blued presents this splash by attaching its view to AppDelegate's window,
// not by using UIKit presentViewController / UINavigationController push.
// Hook the method found in the original Blued executable instead of guessing.
#if BEAR_BLOCK_STARTUP_SPLASH
%hook BDADX_Blued_Splash_Image_ViewController
- (void)presentBluedSplashImageViewController {
    NSLog(@"[bluedXHook][StartupAd] blocked native splash presentation; running native skip/close");
    [self dealForSkipCloseSplashAd];
    // Do not call %orig: that is the method that installs the ad into the window.
}
%end
#endif

#if BEAR_PROMO_TRACE_ENABLED
%hook UIWindow
- (void)makeKeyAndVisible {
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0)))) {
        NSLog(@"[bluedXHook][PromoTrace] window makeKeyAndVisible root=%@ level=%.1f",
              NSStringFromClass(self.rootViewController.class), self.windowLevel);
    }
    %orig;
}
%end
#endif

#if BEAR_PROMO_TRACE_ENABLED
%hook UINavigationController
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated {
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
    %orig(controller, animated);
}
%end

%hook UIAlertController
+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)style {
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0)))) {
        NSLog(@"[bluedXHook][PromoTrace] plugin alert created title=%@ message=%@", title ?: @"", message ?: @"");
    }
    return %orig(title, message, style);
}
%end
#endif

%ctor {
    kBearLaunchBeginTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"[bluedXHook] TG area credit hook initialized");
    %init;
}

