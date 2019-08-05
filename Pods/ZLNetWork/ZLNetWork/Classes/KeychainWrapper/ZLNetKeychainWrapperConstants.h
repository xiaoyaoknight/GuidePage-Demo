//
//  ZLNetKeychainWrapperConstants.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <Foundation/Foundation.h>

// Used for saving to NSUserDefaults that a PIN has been set and as the unique identifier for the Keychain
#define PIN_SAVED @"hasSavedPIN"

// Used for saving the users name to NSUserDefaults
#define USERNAME @"username"

// Used to specify the Application used in Keychain accessing
#define APP_NAME [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]

// Used to help secure the PIN
// Ideally, this is randomly generated, but to avoid unneccessary complexity and overhead of storing the Salt seperately we will standardize on this key.
// !!KEEP IT A SECRET!!
#define SALT_HASH @"FvTivqTqZXsgLLx1v3P8TGRyVHaSOB1pvfm02wvGadj7RLHV8GrfxaZ84oGA8RsKdNRpxdAojXYg9iAj"
