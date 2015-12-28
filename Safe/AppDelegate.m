//
//  AppDelegate.m
//  Safe
//
//  Created by Chuck Musser on 2/11/15.
//  Copyright (c) 2015 Chuck Musser. All rights reserved.
//
#import <Carbon/Carbon.h>

#import "AppDelegate.h"
#import "DDHotKeyCenter.h"
#import "NAChloride.h"
#import "SFBorderlessWindow.h"
#import "SFTabExitTextField.h"
#import "CredentialFileDb.h"

#import "get_time_monotonic.h"

#define CUR_CREDENTIAL_NAME_USER_DEFAULTS_KEY @"curPwFile"

@interface AppDelegate ()

// UI Elements
@property (weak) IBOutlet SFBorderlessWindow *window;
@property (weak) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSPopUpButton *credentialFileListMenu;

@property (weak) IBOutlet NSBox *createCredentialFileBox;
@property (weak) IBOutlet NSSecureTextField *credentialFileMasterPwTextField;
@property (weak) IBOutlet NSTextField *credentialFileNameTextField;

@property (weak) IBOutlet NSBox *changeCredentialFilePwBox;
@property (weak) IBOutlet NSSecureTextField *changeCredentialFilePwTextField;

@property (weak) IBOutlet NSBox *masterPwAndLookupBox;
@property (weak) IBOutlet NSSecureTextField *masterPwField;
@property (weak) IBOutlet NSScrollView *nameContainer;
@property (nonatomic, assign) IBOutlet NCRAutocompleteTextView *lookupTextField;
@property (weak) IBOutlet NSTextField *curCredentialCountLabel;

@property (weak) IBOutlet NSBox *nameAndPwRegenBox;
@property (weak) IBOutlet NSTextField *curCredentialNameErrorLabel;

@property (weak) IBOutlet NSTextField *curCredentialNameTextField;
@property (weak) IBOutlet NSButton *curCredentialPwRegenButton;
@property (weak) IBOutlet NSButton *curCredentialDeleteButton;

@property (weak) IBOutlet SFTabExitTextField *curCredentialUserTextField;
@property (weak) IBOutlet SFTabExitTextField *curCredentialUrlTextField;

@property (weak) IBOutlet NSButton *editOrCancelButton;
@property (weak) IBOutlet NSButton *createOrOkButton;

// Data
@property (nonatomic, strong) NSArray *credentialFileNames;
@property (nonatomic, strong) NSString *curCredentialName;
@property (nonatomic, strong) NSMutableDictionary *credentialData;
@property (nonatomic) BOOL hasCredentialData;

@property (nonatomic, strong) NSArray *credentialNames;
@property (nonatomic, strong) NSString *curCredentialPw; // a "hidden" field, of sorts.
@property (nonatomic, strong) NSMutableDictionary *credentialsUsed;
@property (assign) NSInteger pasteboardCopyCount;
@property (nonatomic, strong) NSString *statsButtonText;
@property (assign) struct timespec windowVisibleTimestamp;
@property (nonatomic, strong) NSRunningApplication *appSwitchedFrom;

// Makes more sense to combine these into an enum, but editing is currently
// used in a binding and not sure how to use a enum there. Cocoa bindings:
// #notworththehassle?
@property (assign) BOOL editing;
@property (assign) BOOL newCredential;
@property (assign) BOOL deleteRequested;

@property (assign) int pwLen;

@end

@implementation AppDelegate

NSMutableDictionary *_credentialData;

NSStatusItem *_pwStatusItem;
NSColor *_redBg;
NSColor *_greenBg;

// Getter/setter pair. These are explicitly defined so that a related
// boolean property can be updated for the benefit of a KVO binding.
- (NSMutableDictionary *)credentialData {

    return _credentialData;
}

- (void)setCredentialData:(NSMutableDictionary *)data {

    _credentialData = data;
    self.hasCredentialData = (_credentialData != nil);

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    NAChlorideInit();

    self.pwLen = 15;

    _redBg = [NSColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2];
    _greenBg = [NSColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.4];

    _pwStatusItem = [[NSStatusBar systemStatusBar]
                statusItemWithLength:NSVariableStatusItemLength];

    [self.window center];
    [self resetPasteStats];

    NSImage *icon = [NSImage imageNamed:@"statusIcon"];
    //[icon setTemplate:TRUE];
    [_pwStatusItem setImage:icon];
    [_pwStatusItem setMenu:self.statusMenu];
    self.statusMenu.delegate = self; // respond to clicks on icon
    
    DDHotKeyCenter *c = [DDHotKeyCenter sharedHotKeyCenter];
    if (![c registerHotKeyWithKeyCode:kVK_ANSI_Grave
                                modifierFlags:NSControlKeyMask
                               target:self
                               action:@selector(hotkeyWithEvent:) object:nil]) {
    }

    [CredentialFileDb ensureCredentialDirectory];
    self.credentialFileNames = [CredentialFileDb getCredentialFileNames];
    [self.credentialFileListMenu selectItemWithTitle:[[NSUserDefaults standardUserDefaults]
                                        stringForKey:CUR_CREDENTIAL_NAME_USER_DEFAULTS_KEY]];
    
    self.lookupTextField.delegate = self;
    [self.lookupTextField setFont:[NSFont systemFontOfSize:30.0]];

    self.curCredentialUserTextField.exitTarget = self.lookupTextField;
    self.curCredentialUrlTextField.exitTarget = self.lookupTextField;

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

// NSMenuDelegate method for the status bar icon.
// Called when the user clicks the status bar icon.
- (void)menuWillOpen:(NSMenu *)menu {
    [self togglePwWindow];
}

// selector passed to the DDHotKeyCenter.
// Called when hotkey is pressed.
- (void) hotkeyWithEvent:(NSEvent *)hkEvent {
    [self togglePwWindow];
}

// Target-Action method for the button that presents the new
// credential file mini-form.
- (IBAction)startCreateCredentialFileClicked:(NSButton *)sender {

    self.createCredentialFileBox.hidden = NO;

}

// Target-Action method for the button that cancels the credential
// file mini-form.
- (IBAction)cancelCreateCredentialFileClicked:(NSButton *)sender {

    self.createCredentialFileBox.hidden = YES;

}

// Target-Action method for the button that hides the credential
// file mini-form and saves the new empty file.
- (IBAction)createCredentialFileClicked:(NSButton *)sender {


    NSString *result = [CredentialFileDb createEmptyWithName:self.credentialFileNameTextField.stringValue
                                               usingPassword:self.credentialFileMasterPwTextField.stringValue];
    if (result == nil) {
        self.createCredentialFileBox.hidden = YES;
        self.credentialFileNames = [CredentialFileDb getCredentialFileNames];
    } else {

    }

}

// Target-Action method for the button that presents the password change
// mini-form.
- (IBAction)startChangeCredentialFileMasterPwClicked:(NSButton *)sender {

    self.changeCredentialFilePwBox.hidden = NO;

}

// Target-Action method for the button that cancels the password change
// mini-form.
- (IBAction)cancelChangeCredentialFileMasterPasswordClicked:(NSButton *)sender {

    self.changeCredentialFilePwBox.hidden = YES;

}

// Target-Action method for the button that hides the password change
// mini-form and saves the current file with the new password.
- (IBAction)changeCredentialFileMasterPwClicked:(NSButton *)sender {

    self.changeCredentialFilePwBox.hidden = YES;
    self.masterPwField.stringValue = self.changeCredentialFilePwTextField.stringValue;
    [CredentialFileDb store:self.credentialData
                   withName:[self.credentialFileListMenu titleOfSelectedItem]
              usingPassword:self.masterPwField.stringValue];

}

// Target-Action method for the master password text field.
// Called when the user hits Enter in the field, after typing the password.
- (IBAction)masterPwEntered:(NSSecureTextField *)sender {
    
    @try {
        self.credentialData = [CredentialFileDb loadFileNamed:[self.credentialFileListMenu titleOfSelectedItem]
                            usingPassword:[sender stringValue]];
        [self refreshNamesAndLookupField:@""];
        self.lookupTextField.backgroundColor = _greenBg;
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                        dispatch_get_main_queue(), ^{
                            self.lookupTextField.backgroundColor = [NSColor whiteColor];
                        });
        [self.nameContainer setHidden:NO];
        [self.window makeFirstResponder:self.nameContainer];
        self.masterPwField.backgroundColor = [NSColor whiteColor];
        [self.masterPwField setHidden:YES];
        self.credentialFileListMenu.nextKeyView = self.lookupTextField;
        [self.createOrOkButton setEnabled:YES];

    }
    @catch (NSException *exception) {
        self.masterPwField.backgroundColor = _redBg;
    }

}

// Target-Action method for the credential list popup button
// Called when the user selects a file using the popup.
- (IBAction)pwFileDidChange:(NSPopUpButton *)sender {
    
    [self.editOrCancelButton setEnabled:NO];
    [self.createOrOkButton setEnabled:NO];
    self.credentialData = nil;
    [self clearCurCredentialFields];
    [self.lookupTextField setString:@""];
    self.masterPwField.stringValue = @"";
    [self.masterPwField setHidden:NO];
    self.credentialFileListMenu.nextKeyView = self.masterPwField;
    [self.nameContainer setHidden:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.credentialFileListMenu titleOfSelectedItem]
                 forKey:CUR_CREDENTIAL_NAME_USER_DEFAULTS_KEY];
    [defaults synchronize];
    [self.window makeFirstResponder:self.masterPwField];
    
}

// NCRAutocompleteTableViewDelegate method
// Called when the autocompletion popup needs a list of possible completions.
//
- (NSArray *)textView:(NSTextView *)textView
          completions:(NSArray *)words
  forPartialWordRange:(NSRange)charRange
  indexOfSelectedItem:(NSInteger *)index {
    NSMutableArray *matches = [NSMutableArray array];
    
    // Look for the text field contents in each name in the password list.
    // Note that the range provided in the parameters is not used. The entire
    // contents of the text field is searched for in each credential name. The
    // intent of the autocomplete view is to complete words, but this needs to
    // instead complete entire phrases.
    for (NSString *credentialName in self.credentialNames) {
        NSRange entireCredential = NSMakeRange(0, [credentialName length]);
        if ([credentialName rangeOfString:[textView string]
                          options:NSCaseInsensitiveSearch
                            range:entireCredential].location != NSNotFound) {
            [matches addObject:credentialName];
        }
    }
    [matches sortUsingSelector:@selector(compare:)];
    
    return matches;
}

// NCRAutocompleteTableViewDelegate method.
// Called when the autocomplete view completes the text in response to the user
// selecting something from the popup.
- (void)textInserted {

    self.curCredentialName = [[self.lookupTextField textStorage] string];
    self.curCredentialNameTextField.stringValue = self.curCredentialName;
    self.curCredentialUserTextField.stringValue = [self getCurCredentialField:@"username"];
    self.curCredentialPw = [self getCurCredentialField:@"password"];
    NSString *site = [self getCurCredentialField:@"site"];
    if (site != nil)
        self.curCredentialUrlTextField.stringValue = site;

    [self.editOrCancelButton setEnabled:YES];
    [self copyCurPwToClipboard];
    [self updatePasteStats];

    [self.lookupTextField selectAll:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(),
    ^{
        // After a waiting, if the mouse is outside and the window is
        // still visible, disappear.
        if (!NSPointInRect([NSEvent mouseLocation], self.window.frame)
            && [self.window isVisible])
            [self togglePwWindow];
    });

}

// NSTextViewDelegate method.
// Called when user actions in the text view result in a command request.
// One instance (handled here) is the user pressing the tab key, which needs
// to be interpreted by this applicationsas a request move to the next field.
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {

    if (aSelector == @selector(insertTab:)) {
        [[aTextView window] selectNextKeyView:nil];
        return YES;
    }

    return NO;
}

// NSButton target-action method
- (IBAction)pwRegenClicked:(NSButton *)sender {
    self.curCredentialPw = [self generatePassword];
}

// NSButton target-action method
- (IBAction)takePwFromPasteBoardClicked:(NSButton *)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    if (copiedItems) {
        self.curCredentialPw = [copiedItems objectAtIndex:0];
    }
}

// NSButton target-action method
- (IBAction)deleteClicked:(NSButton *)sender {

    self.deleteRequested = !self.deleteRequested;
    [self.curCredentialDeleteButton setImage:[NSImage imageNamed:self.deleteRequested
                                              ? @"deleteRequestedButtonIcon"
                                                                : @"deleteButtonIcon"]];

}

// NSButton target-action method
- (IBAction)editOrCancelClicked:(NSButton *)sender {
    // Previously, when the two fields "enabled" binding was active, the two fields
    // did not need to be restored, which doesn't make sense. Now that "editable"
    // bindings is the one in use, they need to be explicitly reset when the user
    // cancels editing. It seems like this makes sense and the old behavior didn't.
    // This is beause the value itself is not bound and so doesn't automatically
    // track whatever the current credential has.
    NSString *username = [self getCurCredentialField:@"username"];
    if (username != nil)
        self.curCredentialUserTextField.stringValue = username;
    NSString *site = [self getCurCredentialField:@"site"];
    if (site != nil)
        self.curCredentialUrlTextField.stringValue = site;

    [self maintainEditState:NO];
}

// NSButton target-action method
// Called when the user wants to create a new credential or is finished editing.
- (IBAction)createOrOkClicked:(NSButton *)sender {

    if (self.editing) {
        bool editOK = YES;

        NSString *name = [self.curCredentialNameTextField stringValue];
        NSMutableDictionary *existingCredential = [self.credentialData valueForKey:name];
        
        if (self.deleteRequested) {
            [self.credentialData removeObjectForKey:self.curCredentialName];
            [self refreshNamesAndLookupField:@""];
                [self.lookupTextField setString:@""];
            [self clearCurCredentialFields];
        } else if (name.length == 0) {
            editOK = NO;
            self.curCredentialNameErrorLabel.stringValue = @"name cannot be blank";
        } else {
            if (self.newCredential) {
                if (existingCredential) {
                    editOK = NO;
                    self.curCredentialNameErrorLabel.stringValue = @"name taken";
                } else {
                    [self.credentialData setObject:[NSMutableDictionary dictionaryWithCapacity:3]
                                            forKey:name];
                    [self refreshNamesAndLookupField:name];
                    [self setCurCredentialField:@"site" withValue:[self.curCredentialUrlTextField stringValue]];
                    [self setCurCredentialField:@"username" withValue:[self.curCredentialUserTextField stringValue]];
                    // Put new password into the clipboard. If the user didn't take it from the
                    // pasteboard, generate one.
                    [self setCurCredentialField:@"password"
                                      withValue:(self.curCredentialPw == nil)
                                                ? [self generatePassword] : self.curCredentialPw];
                    [self copyCurPwToClipboard];
                    [self updatePasteStats];
                }
            } else { // Edit existing
                if (![name isEqualToString:self.curCredentialName]) {
                    if (existingCredential) {
                        editOK = NO;
                        self.curCredentialNameErrorLabel.stringValue = @"name taken";
                    } else {
                        // Name change, copy to new key
                        NSMutableData *cur = [self.credentialData objectForKey:self.curCredentialName];
                        [self.credentialData setObject:cur forKey:name];
                        [self.credentialData removeObjectForKey:self.curCredentialName];
                        [self refreshNamesAndLookupField:name];
                    }
                }
                [self setCurCredentialField:@"site" withValue:[self.curCredentialUrlTextField stringValue]];
                [self setCurCredentialField:@"username" withValue:[self.curCredentialUserTextField stringValue]];
                if (![self.curCredentialPw isEqualToString:[self getCurCredentialField:@"password"]]) {
                    // if password changed, it must be saved. It's likely that the user will
                    // need to use it, so copy it to the clipboard.
                    [self setCurCredentialField:@"password" withValue:self.curCredentialPw];
                    [self copyCurPwToClipboard];
                    [self updatePasteStats];
                }
            }
        }
        
        if (editOK) {
            [CredentialFileDb store:self.credentialData
                           withName:[self.credentialFileListMenu titleOfSelectedItem]
                      usingPassword:self.masterPwField.stringValue];
            [self maintainEditState:YES];
        }
    } else {
        // Entering edit mode, new credential.
        [self clearCurCredentialFields];
        [self maintainEditState:YES];
    }

}
- (IBAction)resetStatsClicked:(NSButton *)sender {

    [self resetPasteStats];

}

// Internal-only method to refresh name-related data
// Called when user creates a new credential or renames an existing one.
- (void)refreshNamesAndLookupField:(NSString *)newName {

    self.curCredentialName = newName;
    self.credentialNames = [self.credentialData allKeys];
    self.curCredentialCountLabel.stringValue = [NSString stringWithFormat:@"%lu credential%@",
                                                (unsigned long)self.credentialNames.count,
                                                self.credentialNames.count == 1 ? @"" : @"s"];
    [self.lookupTextField setString:newName];

}

// Internal-only method to maintain buttons and editing state
- (void)maintainEditState:(BOOL)newCredential {

    self.deleteRequested = NO;
    self.curCredentialNameErrorLabel.stringValue = @"";

    if (self.editing) {
        self.editing = NO;
        [self.curCredentialDeleteButton setImage:[NSImage imageNamed:@"deleteButtonIcon"]];
        self.newCredential = NO;
        self.editOrCancelButton.enabled = ([self.credentialData valueForKey:self.curCredentialName] != nil);
        [self.editOrCancelButton setImage:[NSImage imageNamed:@"editButtonIcon"]];
        [self.createOrOkButton setImage:[NSImage imageNamed:@"createButtonIcon"]];
    } else {
        self.editing = YES;
        self.newCredential = newCredential;
        self.curCredentialDeleteButton.enabled = !self.newCredential;
        self.editOrCancelButton.enabled = YES;
        [self.editOrCancelButton setImage:[NSImage imageNamed:@"cancelEditButtonIcon"]];
        [self.createOrOkButton setImage:[NSImage imageNamed:@"okEditButtonIcon"]];
        [self.window makeFirstResponder:self.curCredentialNameTextField];
    }

    NSMutableDictionary* masterPwAndLookupAnim = [NSMutableDictionary dictionaryWithCapacity:1];
    [masterPwAndLookupAnim setObject:self.masterPwAndLookupBox forKey:NSViewAnimationTargetKey];
    [masterPwAndLookupAnim setObject:self.editing ? NSViewAnimationFadeOutEffect : NSViewAnimationFadeInEffect
                    forKey:NSViewAnimationEffectKey];
    
    NSMutableDictionary* nameAndPwRegenAnim = [NSMutableDictionary dictionaryWithCapacity:1];
    [nameAndPwRegenAnim setObject:self.nameAndPwRegenBox forKey:NSViewAnimationTargetKey];
    [nameAndPwRegenAnim setObject:self.editing ? NSViewAnimationFadeInEffect : NSViewAnimationFadeOutEffect
                              forKey:NSViewAnimationEffectKey];
    
    NSViewAnimation *theAnim = [[NSViewAnimation alloc]
                                initWithViewAnimations:[NSArray arrayWithObjects:masterPwAndLookupAnim, nameAndPwRegenAnim, nil]];
    [theAnim setDuration:.3];
    [theAnim setAnimationCurve:NSAnimationEaseIn];

    [theAnim startAnimation];

}

// Internal-only method to retrieve a field from the current credential
- (NSString *)getCurCredentialField:(NSString *)field {

    return [[self.credentialData valueForKey:self.curCredentialName] valueForKey:field];
}

// Internal-only method to update a field from the current credential
- (void)setCurCredentialField:(NSString *)field withValue:(NSString *)value {

    [[self.credentialData valueForKey:self.curCredentialName] setValue:value forKey:field];

}

// Internal-only method used to zap the current fields
// Called when changing the credential file and when entering edit mode
- (void)clearCurCredentialFields {
    self.curCredentialNameTextField.stringValue = @"";
    self.curCredentialPw = nil;
    self.curCredentialUserTextField.stringValue = @"";
    self.curCredentialUrlTextField.stringValue = @"";
}

// Internal-only method used to show/hide the window.
// Called when the global hotkey is pressed or the status bar icon is clicked.
- (void)togglePwWindow
{
    if ([self.window isVisible]) {
        [self.window orderOut:self];
        [self.appSwitchedFrom activateWithOptions:NSApplicationActivateIgnoringOtherApps];;
        struct timespec now = orwl_gettime();
        if (delta_below_threshold(self.windowVisibleTimestamp, now, 2))
            [self updatePasteStats];
    } else {
        self.appSwitchedFrom = [[NSWorkspace sharedWorkspace] frontmostApplication];
        [self.window makeKeyAndOrderFront:self];
        [self.window setLevel:NSStatusWindowLevel];
        [NSApp activateIgnoringOtherApps:YES];
        self.windowVisibleTimestamp = orwl_gettime();
        // Anticipating that the last searched for password is still useful.
        [self copyCurPwToClipboard];
    }
}

// Internal-only method used to generate a random password
-(NSString *)generatePassword {
    NSString *pwChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789_";
    NSUInteger pwCharsLen = [pwChars length];
    NSMutableString *pw = [[NSMutableString alloc] init];

    for (int i = 0; i < self.pwLen; i++) {
        unichar c = [pwChars characterAtIndex:arc4random_uniform((unsigned int)pwCharsLen)];
        [pw appendFormat:@"%c", c];
    }

    return pw;
}

// Internal-only method used to initialize or clear the paste statistics.
- (void)updatePasteStats {

    if (self.curCredentialPw != nil) {
        self.pasteboardCopyCount++;
        NSNumber *countForCurName = [self.credentialsUsed objectForKey:self.curCredentialName];
        if (countForCurName == nil)
            [self.credentialsUsed setObject:[NSNumber numberWithInt:0]
                                     forKey:self.curCredentialName];
        else
            [self.credentialsUsed setObject:[NSNumber numberWithInt:[countForCurName intValue] + 1 ]
                                     forKey:self.curCredentialName];

        self.statsButtonText = [NSString stringWithFormat:@"%-2lu | %-2ld",
                                (unsigned long)self.credentialsUsed.count,
                                (long)self.pasteboardCopyCount];
    }

}

// Internal-only method used to initialize or clear the paste statistics.
- (void)resetPasteStats {

    self.credentialsUsed = [[NSMutableDictionary alloc] init];
    self.pasteboardCopyCount = 0;
    self.statsButtonText = @"- | -";

}

// Internal-only method to copy the current password to the clipboard.
- (void)copyCurPwToClipboard {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];

    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType]
               owner:nil];
    [pb setString:[self getCurCredentialField:@"password"]
          forType:NSStringPboardType];
    
}

@end
