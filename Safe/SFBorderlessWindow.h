//
//  SFBorderlessWindow.h
//  Safe
//
//  Created by Chuck Musser on 2/17/15.
//  Copyright (c) 2015 Chuck Musser. All rights reserved.
//
// This class is needed in order to make subviews in a title-bar-less
// window focusable.

#import <Cocoa/Cocoa.h>

@interface SFBorderlessWindow : NSWindow

- (BOOL)canBecomeKeyWindow;
- (BOOL)canBecomeMainWindow;

@end
