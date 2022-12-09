//
//  DelegateHooker.h
//  BackupDylib
//
//  Created by DebianArch on 12/6/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) NSMutableArray<void (^)(id)> *instructions;
@property (nonatomic) BOOL isDelegateSupported;
@property (nonatomic) BOOL didDelegateLoad;

+(AppDelegate *_Nonnull)shared;
-(BOOL)redirectDelegate:(SEL)selector delegate:(id)hook error:(NSError**)error asyncError:(void (^)(NSError*error))errorHandler;
-(BOOL)redirectDelegate:(SEL)selector originalDelegate:(id)originalDelegate delegate:(id)hook skipHandler:(BOOL)skipHandler error:(NSError**)error asyncError:(void (^)(NSError*error))errorHandler;
@end
NS_ASSUME_NONNULL_END
