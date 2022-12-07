//
//  DelegateHooker.m
//  BackupDylib
//
//  Created by DebianArch on 12/6/22.
//

#import "DelegateHooker.h"
#import <objc/runtime.h>

@implementation AppDelegate
+(AppDelegate *)shared {
    static dispatch_once_t onceToken;
    static AppDelegate *appState;
    dispatch_once(&onceToken, ^{
        appState = [AppDelegate new];
        appState.instructions = [[NSMutableArray alloc] init];
    });
    return appState;
}

-(void)addInstruction:(SEL)selector delegate:(UIResponder <UIApplicationDelegate>*)hook
{
    void (^simpleBlock)(id) = ^(id delegate){
        [self redirectDelegate:selector originalDelegate:delegate delegate:hook skipHandler:true];
    };
    [_instructions addObject:simpleBlock];
}

-(BOOL)redirectDelegate:(SEL)selector delegate:(UIResponder <UIApplicationDelegate>*)hook
{
    UIApplication *shared = [[UIApplication class] performSelector:@selector(sharedApplication)];
    return [self redirectDelegate:selector originalDelegate:[shared delegate] delegate:hook skipHandler:false];
}

-(BOOL)redirectDelegate:(SEL)selector originalDelegate:(id<UIApplicationDelegate> _Nullable)originalDelegate delegate:(UIResponder <UIApplicationDelegate>*)hook skipHandler:(BOOL)skipHandler
{
    if ([originalDelegate respondsToSelector:selector])
    { // swizzle with our own method.
        Method swizzler = class_getInstanceMethod([hook class], selector);
        if (swizzler == NULL)
        {
            NSLog(@"[redirectDelegate] Err: Implement the given function to your delegate.");
            return false;
        }
        
        const char *sig = method_getTypeEncoding(swizzler);
        IMP implementation = class_getMethodImplementation([hook class], selector);
        class_replaceMethod([originalDelegate class], selector, implementation, sig);
        return true;
    }
    else if (!skipHandler)
    {
        [self addInstruction:selector delegate:hook];
    }
    else if (!_didDelegateLoad)
    { // we can't dynamically add functions -> this is why this is handled before appdelegate gets set.
        Method swizzler = class_getInstanceMethod([hook class], selector);
        if (swizzler == NULL)
        {
            NSLog(@"[redirectDelegate] Err: Implement the given function to your delegate.");
            return false;
        }
        
        const char *sig = method_getTypeEncoding(swizzler);
        IMP implementation = class_getMethodImplementation([hook class], selector);
        class_addMethod([originalDelegate class], selector, implementation, sig);
    }
    else
    {
        NSLog(@"[redirectDelegate] You can't ADD new methods when delegate finishes mounting.");
    }
    return false;
}

@end

@interface UIApplication (Hooked)
@end

@implementation UIApplication (Hooked)
+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        SEL originalSelector = @selector(setDelegate:);
        SEL swizzledSelector = @selector(setDelegateHooker:);

        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        BOOL didAddMethod =
        class_addMethod(self,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(self,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }

    });
}

- (void)setDelegateHooker: (id) delegate
{
    NSMutableArray *items = [AppDelegate.shared instructions];
    for (void (^item)(id) in items)
    {
        item(delegate);
    }
    [self setDelegateHooker:delegate]; // since methods are swapped this runs original function.
    [AppDelegate.shared setDidDelegateLoad:true];
    [AppDelegate.shared setInstructions:@[].mutableCopy];
}

@end
