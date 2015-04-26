//
//  CredentialFileDb.h
//  Safe
//
//  Created by Chuck Musser on 2/13/15.
//  Copyright (c) 2015 Chuck Musser. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CredentialFileDb : NSObject

+ (void)ensureCredentialDirectory;
+ (NSArray *)getCredentialFileNames;
+ (NSMutableDictionary *)loadFileNamed:(NSString*)name
                         usingPassword:(NSString *)password;
+ (void)store:(NSMutableDictionary *)credentials
     withName:(NSString*)name
usingPassword:(NSString *)password;

+ (NSString *)createEmptyWithName:(NSString*)name
              usingPassword:(NSString *)password;

@end
