//
//  ZLHttpsCheck.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "ZLHttpsCheck.h"

@implementation ZLHttpsCheck

/**
 验证证书是否是过期证书
 
 @return YES, 过期
 */
+ (BOOL)session:(NSURLSession *)session cert:(NSData *)certData didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    BOOL expired = NO;
    if ([challenge.protectionSpace.authenticationMethod
         isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        CFDataRef myCertData = (__bridge CFDataRef)certData;
        SecCertificateRef myCert = SecCertificateCreateWithData(NULL,
                                                                myCertData);
        SecPolicyRef myPolicy = SecPolicyCreateBasicX509();
        SecCertificateRef certArray[1] = { myCert };
        CFArrayRef myCerts = CFArrayCreate(NULL,
                                           (void *)certArray,
                                           1,
                                           NULL);
        SecTrustRef myTrust;
        OSStatus status = SecTrustCreateWithCertificates(myCerts,
                                                         myPolicy,
                                                         &myTrust);
        SecTrustResultType trustResult = 0;
        if (status == noErr) {
            status = SecTrustEvaluate(myTrust, &trustResult);
        }
        // If the trust result is kSecTrustResultInvalid, kSecTrustResultDeny, kSecTrustResultFatalTrustFailure, you cannot proceed and should fail gracefully.
        BOOL proceed = NO;
        switch (trustResult) {
            case kSecTrustResultProceed: // 1
                // NSLog(@"Proceed");
                proceed = YES;
                break;
                //            case kSecTrustResultConfirm: // 2
                //                // NSLog(@"Confirm");
                //                proceed = YES;
                //                break;
            case kSecTrustResultUnspecified: // 4
                // NSLog(@"Unspecified");
                break;
            case kSecTrustResultRecoverableTrustFailure:  // 5
                // NSLog(@"TrustFailure");
                proceed = [self recoverFromTrustFailure:myTrust];
                if (proceed) {
                    expired = YES;
                }
                break;
            case kSecTrustResultDeny: // 3
                // NSLog(@"Deny");
                break;
            case kSecTrustResultFatalTrustFailure: // 6
                // NSLog(@"FatalTrustFailure");
                break;
            case kSecTrustResultOtherError: // 7
                // NSLog(@"OtherError");
                break;
            case kSecTrustResultInvalid: // 0
                // NSLog(@"Invalid");
                break;
            default:
                // NSLog(@"Default");
                break;
        }
        if (myPolicy)
            CFRelease(myPolicy);
        if (proceed) {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust] forAuthenticationChallenge: challenge];
        } else {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    }
    return expired;
}

/**
 证书时间向前倒退一年，验证是否有效
 
 @return YES, 有效
 */
+ (BOOL)recoverFromTrustFailure:(SecTrustRef)myTrust {
    SecTrustResultType trustResult;
    OSStatus status = SecTrustEvaluate(myTrust, &trustResult);
    //Get time used to verify trust
    CFAbsoluteTime trustTime,currentTime,timeIncrement,newTime;
    CFDateRef newDate;
    if (trustResult == kSecTrustResultRecoverableTrustFailure) {
        trustTime = SecTrustGetVerifyTime(myTrust);
        timeIncrement = 31536000;
        currentTime = CFAbsoluteTimeGetCurrent();
        newTime = currentTime - timeIncrement;
        if (trustTime - newTime) {
            newDate = CFDateCreate(NULL, newTime);
            SecTrustSetVerifyDate(myTrust, newDate);
            status = SecTrustEvaluate(myTrust, &trustResult);
        }
    }
    if (trustResult != kSecTrustResultProceed) {
        return NO;
    } else {
        return YES;
    }
}

@end
