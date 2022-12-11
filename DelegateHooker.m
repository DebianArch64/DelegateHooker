//
//  DelegateHooker.m
//  BackupDylib
//
//  Created by DebianArch on 12/6/22.
//

#import "DelegateHooker.h"
#import <objc/runtime.h>

@implementation HookDelegate
+(HookDelegate *)shared {
    static dispatch_once_t onceToken;
    static HookDelegate *appState;
    dispatch_once(&onceToken, ^{
        appState = [HookDelegate new];
        appState.instructions = [[NSMutableArray alloc] init];
    });
    return appState;
}

-(void)addInstruction:(SEL)selector delegate:(UIResponder <UIApplicationDelegate>*)hook errorHandler:(void (^)(NSError*))errorHandler
{
    void (^simpleBlock)(id) = ^(id delegate){
        NSError *error = NULL;
        [self redirectDelegate:selector originalDelegate:delegate delegate:hook skipHandler:true error:&error asyncError:errorHandler];
    };
    [_instructions addObject:simpleBlock];
}

-(void)sceneDelegateWaiter:(NSNotification*)notification
{
    if ([notification.object isKindOfClass:[UIScene class]]) {
        UIScene *scene = (UIScene *)notification.object;
        NSMutableArray *items = _instructions;
        for (void (^item)(id) in items)
        {
            item([scene delegate]);
        }
        [self setInstructions:@[].mutableCopy];
    }
}

-(void)appDelegateWaiter:(NSNotification*)notification
{
    NSMutableArray *items = _instructions;
    for (void (^item)(id) in items)
    {
        item([[[UIApplication class] performSelector:@selector(sharedApplication)] delegate]);
    }
    [self setInstructions:@[].mutableCopy];
}

-(BOOL)redirectDelegate:(SEL)selector delegate:(id)hook error:(NSError**)error asyncError:(void (^)(NSError*error))errorHandler
{
    BOOL isAppDelegate = [hook conformsToProtocol:@protocol(UIApplicationDelegate)];
    id delegate = NULL;
    if (isAppDelegate && [NSBundle.mainBundle.infoDictionary objectForKey:@"UIApplicationSceneManifest"] != NULL)
    {
        [self createError:error withString:@"This app doesn't use appdelegate." code:-2];
        _isDelegateSupported = false;
        return false;
    }
    else if (isAppDelegate)
    {
        delegate = [[[UIApplication class] performSelector:@selector(sharedApplication)] delegate];
        if (delegate == NULL)
        {
            void (^simpleBlock)(id) = ^(id delegate){
                NSError *error = NULL;
                [self redirectDelegate:selector originalDelegate:delegate delegate:hook skipHandler:true error:&error asyncError:errorHandler];
            };
            [self.instructions addObject:simpleBlock];
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(appDelegateWaiter:)
             name:UIApplicationDidFinishLaunchingNotification
             object:nil];
        }
        _isDelegateSupported = true;
        return true;
    }
    else if (@available(iOS 13, *))
    {
        delegate = [[[[[UIApplication class] performSelector:@selector(sharedApplication)] connectedScenes].allObjects firstObject] delegate];
        if (delegate == NULL)
        {
            void (^simpleBlock)(id) = ^(id delegate){
                NSError *error = NULL;
                [self redirectDelegate:selector originalDelegate:delegate delegate:hook skipHandler:true error:&error asyncError:errorHandler];
            };
            [self.instructions addObject:simpleBlock];
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(sceneDelegateWaiter:)
             name:UISceneWillConnectNotification
             object:nil];
            return true;
        }
    }
    return [self redirectDelegate:selector originalDelegate:delegate delegate:hook skipHandler:false error:error asyncError:errorHandler];
}

-(BOOL)redirectDelegate:(SEL)selector originalDelegate:(id)originalDelegate delegate:(id)hook skipHandler:(BOOL)skipHandler error:(NSError**)error asyncError:(void (^)(NSError*error))errorHandler
{
    if (originalDelegate == NULL || hook == NULL)
    {
        [self createError:error withString:@"NULL delegate given." code:-1];
        if (error != NULL)
        {
            errorHandler(*error);
        }
        return false;
    }
    
    if ([originalDelegate respondsToSelector:selector])
    { // swizzle with our own method.
        Method swizzler = class_getInstanceMethod([hook class], selector);
        if (swizzler == NULL)
        {
            [self createError:error withString:@"Implement the given function to your delegate." code:-1];
            if (error != NULL)
            {
                errorHandler(*error);
            }
            return false;
        }
        
        const char *sig = method_getTypeEncoding(swizzler);
        IMP implementation = class_getMethodImplementation([hook class], selector);
        class_replaceMethod([originalDelegate class], selector, implementation, sig);
        return true;
    }
    else if (!skipHandler)
    {
        [self addInstruction:selector delegate:hook errorHandler:errorHandler];
    }
    else if (!_didDelegateLoad)
    { // we can't dynamically add functions -> this is why this is handled before appdelegate gets set.
        Method swizzler = class_getInstanceMethod([hook class], selector);
        if (swizzler == NULL)
        {
            [self createError:error withString:@"Implement the given function to your delegate." code:-1];
            if (error != NULL)
            {
                errorHandler(*error);
            }
            return false;
        }
        
        const char *sig = method_getTypeEncoding(swizzler);
        IMP implementation = class_getMethodImplementation([hook class], selector);
        class_addMethod([originalDelegate class], selector, implementation, sig);
    }
    else
    {
        [self createError:error withString:@"You can't ADD new methods when delegate finishes mounting." code:-1];
        if (error != NULL)
        {
            errorHandler(*error);
        }
    }
    return true;
}

- (void)createError:(NSError **)error withString:(NSString *)string code:(int)code {
    if (error != NULL) {
        *error = [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: string}];
    }
}
@end

@interface UIApplication (Hooked)
@end

@implementation UIApplication (Hooked)
+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (![HookDelegate.shared isDelegateSupported]) // prevent app breakage
            return;
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
    NSMutableArray *items = [HookDelegate.shared instructions];
    for (void (^item)(id) in items)
    {
        item(delegate);
    }
    [self setDelegateHooker:delegate]; // since methods are swapped this runs original function.
    [HookDelegate.shared setDidDelegateLoad:true];
    [HookDelegate.shared setInstructions:@[].mutableCopy];
}

@end
