//
//  NSBundle+MyLibrary.m
//  Pods
//
//  Created by JR on 16/8/16.
//
//

#import "NSBundle+debugManager.h"

@implementation NSBundle (debugManager)

+ (NSBundle *)debugManagerBundle {
    return [self bundleWithURL:[self my_myLibraryBundleURL]];
}


+ (NSURL *)my_myLibraryBundleURL {
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"FNDebugSettingViewController")];
    return [bundle URLForResource:@"FNDebugManagerPod" withExtension:@"bundle"];
}

@end
