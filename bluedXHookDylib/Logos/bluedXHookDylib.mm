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
    if (![NSStringFromClass(controller.class) isEqualToString:@"tjq"] ||
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
@class UINavigationController; @class UIViewController; @class BDADX_Blued_Splash_Image_ViewController; @class UIAlertController; @class UIWindow; 
static Class _logos_superclass$_ungrouped$UIViewController; static void (*_logos_orig$_ungrouped$UIViewController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST, SEL, BOOL);static void (*_logos_orig$_ungrouped$UIViewController$presentViewController$animated$completion$)(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST, SEL, UIViewController *, BOOL, void (^)(void));static void (*_logos_orig$_ungrouped$UIViewController$viewDidLayoutSubviews)(_LOGOS_SELF_TYPE_NORMAL UIViewController* _LOGOS_SELF_CONST, SEL);static Class _logos_superclass$_ungrouped$BDADX_Blued_Splash_Image_ViewController; static void (*_logos_orig$_ungrouped$BDADX_Blued_Splash_Image_ViewController$presentBluedSplashImageViewController)(_LOGOS_SELF_TYPE_NORMAL BDADX_Blued_Splash_Image_ViewController* _LOGOS_SELF_CONST, SEL);static Class _logos_superclass$_ungrouped$UIWindow; static void (*_logos_orig$_ungrouped$UIWindow$makeKeyAndVisible)(_LOGOS_SELF_TYPE_NORMAL UIWindow* _LOGOS_SELF_CONST, SEL);static Class _logos_superclass$_ungrouped$UINavigationController; static void (*_logos_orig$_ungrouped$UINavigationController$pushViewController$animated$)(_LOGOS_SELF_TYPE_NORMAL UINavigationController* _LOGOS_SELF_CONST, SEL, UIViewController *, BOOL);static Class _logos_supermetaclass$_ungrouped$UIAlertController; static UIAlertController* (*_logos_meta_orig$_ungrouped$UIAlertController$alertControllerWithTitle$message$preferredStyle$)(_LOGOS_SELF_TYPE_NORMAL Class _LOGOS_SELF_CONST, SEL, NSString *, NSString *, UIAlertControllerStyle);

#line 142 "/Users/bear/Desktop/myApps/bluedXHook/bluedXHookDylib/Logos/bluedXHookDylib.xm"


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
    if ([NSStringFromClass(self.class) isEqualToString:@"tjq"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BearPlaceCreditNearTelegram((UIViewController *)self);
        });
    }
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
    if ([NSStringFromClass(self.class) isEqualToString:@"tjq"]) {
        BearPlaceCreditNearTelegram((UIViewController *)self);
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

static __attribute__((constructor)) void _logosLocalCtor_babeaf76(int __unused argc, char __unused **argv, char __unused **envp) {
    NSLog(@"[bluedXHook] TG area credit hook initialized");
    {Class _logos_class$_ungrouped$UIViewController = objc_getClass("UIViewController"); _logos_superclass$_ungrouped$UIViewController = class_getSuperclass(_logos_class$_ungrouped$UIViewController); { _logos_register_hook(_logos_class$_ungrouped$UIViewController, @selector(viewDidAppear:), (IMP)&_logos_method$_ungrouped$UIViewController$viewDidAppear$, (IMP *)&_logos_orig$_ungrouped$UIViewController$viewDidAppear$);}{ _logos_register_hook(_logos_class$_ungrouped$UIViewController, @selector(presentViewController:animated:completion:), (IMP)&_logos_method$_ungrouped$UIViewController$presentViewController$animated$completion$, (IMP *)&_logos_orig$_ungrouped$UIViewController$presentViewController$animated$completion$);}{ _logos_register_hook(_logos_class$_ungrouped$UIViewController, @selector(viewDidLayoutSubviews), (IMP)&_logos_method$_ungrouped$UIViewController$viewDidLayoutSubviews, (IMP *)&_logos_orig$_ungrouped$UIViewController$viewDidLayoutSubviews);}Class _logos_class$_ungrouped$BDADX_Blued_Splash_Image_ViewController = objc_getClass("BDADX_Blued_Splash_Image_ViewController"); _logos_superclass$_ungrouped$BDADX_Blued_Splash_Image_ViewController = class_getSuperclass(_logos_class$_ungrouped$BDADX_Blued_Splash_Image_ViewController); { _logos_register_hook(_logos_class$_ungrouped$BDADX_Blued_Splash_Image_ViewController, @selector(presentBluedSplashImageViewController), (IMP)&_logos_method$_ungrouped$BDADX_Blued_Splash_Image_ViewController$presentBluedSplashImageViewController, (IMP *)&_logos_orig$_ungrouped$BDADX_Blued_Splash_Image_ViewController$presentBluedSplashImageViewController);}Class _logos_class$_ungrouped$UIWindow = objc_getClass("UIWindow"); _logos_superclass$_ungrouped$UIWindow = class_getSuperclass(_logos_class$_ungrouped$UIWindow); { _logos_register_hook(_logos_class$_ungrouped$UIWindow, @selector(makeKeyAndVisible), (IMP)&_logos_method$_ungrouped$UIWindow$makeKeyAndVisible, (IMP *)&_logos_orig$_ungrouped$UIWindow$makeKeyAndVisible);}Class _logos_class$_ungrouped$UINavigationController = objc_getClass("UINavigationController"); _logos_superclass$_ungrouped$UINavigationController = class_getSuperclass(_logos_class$_ungrouped$UINavigationController); { _logos_register_hook(_logos_class$_ungrouped$UINavigationController, @selector(pushViewController:animated:), (IMP)&_logos_method$_ungrouped$UINavigationController$pushViewController$animated$, (IMP *)&_logos_orig$_ungrouped$UINavigationController$pushViewController$animated$);}Class _logos_class$_ungrouped$UIAlertController = objc_getClass("UIAlertController"); Class _logos_metaclass$_ungrouped$UIAlertController = object_getClass(_logos_class$_ungrouped$UIAlertController); _logos_supermetaclass$_ungrouped$UIAlertController = class_getSuperclass(_logos_metaclass$_ungrouped$UIAlertController); { _logos_register_hook(_logos_metaclass$_ungrouped$UIAlertController, @selector(alertControllerWithTitle:message:preferredStyle:), (IMP)&_logos_meta_method$_ungrouped$UIAlertController$alertControllerWithTitle$message$preferredStyle$, (IMP *)&_logos_meta_orig$_ungrouped$UIAlertController$alertControllerWithTitle$message$preferredStyle$);}}
}

