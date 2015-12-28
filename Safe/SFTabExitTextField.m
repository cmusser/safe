//
//  SFTabExitTextField.m
//  Safe
//
//  Created by Chuck Musser on 12/28/15.
//  Copyright © 2015 Chuck Musser. All rights reserved.
//

#import "SFTabExitTextField.h"

@implementation SFTabExitTextField

- (void)keyUp:(NSEvent *)theEvent {
    
    if (self.editable)
        [super keyDown:theEvent];
    else
        [_window makeFirstResponder:self.exitTarget];
}

@end
