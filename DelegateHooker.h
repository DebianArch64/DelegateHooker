//
//  DelegateHooker.h
//  BackupDylib
//
//  Created by DebianArch on 12/6/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic) NSMutableArray<void (^)(id)> *instructions;
@property (nonatomic) BOOL didDelegateLoad;
+(AppDelegate *)shared;
-(BOOL)redirectDelegate:(SEL)selector delegate:(UIResponder <UIApplicationDelegate>*)hook;
-(BOOL)redirectDelegate:(SEL)selector originalDelegate:(id<UIApplicationDelegate> _Nullable)originalDelegate delegate:(UIResponder <UIApplicationDelegate>*)hook skipHandler:(BOOL)skipHandler;
@end
