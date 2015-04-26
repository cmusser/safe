//
//  CredentialFileDb.m
//  Safe
//
//  Created by Chuck Musser on 2/13/15.
//  Copyright (c) 2015 Chuck Musser. All rights reserved.
//

#import "NAChloride.h"
#import "CredentialFileDb.h"

#define SALT_LEN 64
#define HASH_LEN 32

@implementation CredentialFileDb

+ (void)ensureCredentialDirectory {
    NSError *error;
    NSString *credentialDir = [self getUserCredentialDir];
    [[NSFileManager defaultManager] createDirectoryAtPath:credentialDir
                              withIntermediateDirectories:NO attributes:nil error:&error];
    if (error)
        NSLog(@"ensure: %@", error);
    else
        NSLog(@"ensure created: %@", credentialDir);

}

+ (NSArray *)getCredentialFileNames {
    NSError *error;
    NSArray *dirFiles = [[NSFileManager defaultManager]
                         contentsOfDirectoryAtPath:[self getUserCredentialDir] error:&error];
    NSArray *pwOnly = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.pw'"]];
    NSMutableArray *fileNames = [[NSMutableArray alloc ] initWithCapacity:[pwOnly count]];
    for (NSString *f in pwOnly) {
        [fileNames addObject:[f stringByDeletingPathExtension]];
    }

    return fileNames;
}

+ (NSMutableDictionary *) loadFileNamed:(NSString*)name usingPassword:(NSString *)password {
    NSError *error;
    NSData *file = [NSData dataWithContentsOfFile:[self getUserCredentialFileNamed:name]];
    NSData *key = [self deriveKeyFromPw:password andSalt:[file subdataWithRange:NSMakeRange(0,64)]];
    NASecretBox *secretBox = [[NASecretBox alloc] init];
    NSData *decrypted = [secretBox decrypt:[file subdataWithRange:NSMakeRange(SALT_LEN,
                                                                              [file length] - SALT_LEN)]
                                       key:key error:&error];
    if (error)
        NSLog(@"oops: %@", error);

    return [NSJSONSerialization JSONObjectWithData:decrypted
                                            options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves
                                              error:&error];
}

+ (void)store:(NSMutableDictionary *)credentials
     withName:(NSString*)name
usingPassword:(NSString *)password {
     NSError *error;
    NSData *plaintextData = [NSJSONSerialization dataWithJSONObject:credentials
                                                            options:0
                                                              error:&error];
    NSMutableData *outputData = [[NARandom randomData:64 error:&error] mutableCopy];
    NSData *key = [self deriveKeyFromPw:password andSalt:outputData];
    NASecretBox *secretBox = [[NASecretBox alloc] init];
    [outputData appendData:[secretBox encrypt:plaintextData key:key error:&error]];
    [outputData writeToFile:[self getUserCredentialFileNamed:name] atomically:YES];
}

+ (NSString *)createEmptyWithName:(NSString*)name
              usingPassword:(NSString *)password {

    if (![[NSFileManager defaultManager] fileExistsAtPath:[self getUserCredentialFileNamed:name]]) {
        [self store:[[NSMutableDictionary alloc] init]
           withName:name usingPassword:password];
        return nil;
    } else {
        NSLog(@"file exists");
        return @"File exists";
    }
}


// Internal-only class method
+ (NSString *)getUserCredentialDir {
    return [NSHomeDirectory() stringByAppendingPathComponent:@".pw"];
}

// Internal-only class method
+ (NSString *)getUserCredentialFileNamed:(NSString *)name {

    return [[[self getUserCredentialDir] stringByAppendingPathComponent:name] stringByAppendingString:@".pw"];
}

// Internal-only class method
+ (NSData *)deriveKeyFromPw:(NSString *)password
                    andSalt:(NSData *)salt {

    return [NAScrypt scrypt:[password dataUsingEncoding:NSUTF8StringEncoding]
                       salt:salt
                          N:16384U r:8 p:1 length:HASH_LEN error:nil];
}
@end
