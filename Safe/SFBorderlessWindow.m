//
//  SFBorderlessWindow.m
//  Safe
//
//  Created by Chuck Musser on 2/17/15.
//  Copyright (c) 2015 Chuck Musser. All rights reserved.
//

#import "SFBorderlessWindow.h"

@implementation SFBorderlessWindow

- (BOOL)canBecomeKeyWindow {
    // because the window is borderless, we have to make it active
    return YES;
}

- (BOOL)canBecomeMainWindow {
    // because the window is borderless, we have to make it active
    return YES;
}

@end
