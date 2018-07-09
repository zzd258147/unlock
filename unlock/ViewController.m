//
//  ViewController.m
//  unlock
//
//  Copyright © 2018 aia. All rights reserved.
//

#import "ViewController.h"

#import <AFNetworking/AFHTTPSessionManager.h>

@interface ViewController ()
@property (strong) AFHTTPSessionManager *manager;

@property (weak) IBOutlet NSTextField *usernameTF;
@property (weak) IBOutlet NSTextField *passwordTF;

@property (weak) IBOutlet NSButton *unlockButton;

@property (weak) IBOutlet NSTextField *lanIdTf;

@property (weak) IBOutlet NSTextField *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.statusLabel.placeholderString = nil;
    
    self.manager = [[AFHTTPSessionManager alloc] init];
    self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.manager.responseSerializer = [AFHTTPResponseSerializer serializer];
}

- (IBAction)unlock:(id)sender {
    self.unlockButton.enabled = NO;
    
    [self unlockWithUsername:self.usernameTF.stringValue password:self.passwordTF.stringValue forLanId:self.lanIdTf.stringValue completion:^(BOOL result) {
        self.unlockButton.enabled = YES;
        
        self.statusLabel.placeholderString = nil;
    }];
}

- (void)unlockWithUsername:(NSString *)username password:(NSString *)password forLanId:(NSString *)lanId completion:(void (^)(BOOL result))completion {
    if (username.length == 0 || password.length == 0 || lanId.length == 0) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    self.statusLabel.placeholderString = @"login...";
    
    [self loginWithUsername:username password:password completion:^(BOOL result) {
        if (!result) {
            if (completion) {
                completion(NO);
            }
            return;
        }
        
        self.statusLabel.placeholderString = @"search userID...";
        
        [self searchUserIdForLanId:lanId completion:^(BOOL result, NSString *userId) {
            if (!result) {
                if (completion) {
                    completion(NO);
                }
                return;
            }
            
            self.statusLabel.placeholderString = @"unlock lanID...";
            
            [self unlockForLanId:lanId userId:userId completion:completion];
        }];
    }];
}

#pragma mark -
- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(void (^)(BOOL result))completion {
    [self.manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
        NSString *method = challenge.protectionSpace.authenticationMethod;
        
        if ([method isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            return NSURLSessionAuthChallengePerformDefaultHandling;
        } else if ([method isEqualToString:NSURLAuthenticationMethodNegotiate]) {
            return NSURLSessionAuthChallengeRejectProtectionSpace;
        } else if ([method isEqualToString:NSURLAuthenticationMethodNTLM]) {
            *credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
            return NSURLSessionAuthChallengeUseCredential;
        } else {
            return NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }];
    
    [self.manager GET:@"https://ssologon.aia.com/siteminderagent/ntlm/creds.ntc?target=%2Fauth%2Fredirect.asp%3Fauthtype%3Dwindows%26target%3Dhttps%253A%252F%252Fidm.aia.com%252Fsigma%252Fapp%252Findex" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        if ([html containsString:@"AIA Identity Portal"]) {
            if (completion) {
                completion(YES);
            }
        } else {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.alertStyle = NSAlertStyleInformational;
            alert.messageText = username;
            alert.informativeText = @"Login failed!";
            [alert runModal];
            
            if (completion) {
                completion(NO);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[NSAlert alertWithError:error] runModal];
        
        if (completion) {
            completion(NO);
        }
    }];
}

- (void)searchUserIdForLanId:(NSString *)lanId completion:(void (^)(BOOL result, NSString *userId))completion {
    [self.manager GET:[NSString stringWithFormat:@"https://idm.aia.com/sigma/rest/user/search/%@", lanId] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
        NSString *userId = [dic[@"userIds"] firstObject];
        
        if (userId.length > 0) {
            if (completion) {
                completion(YES, userId);
            }
        } else {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.alertStyle = NSAlertStyleInformational;
            alert.messageText = lanId;
            alert.informativeText = @"Search userID failed!";
            [alert runModal];
            
            if (completion) {
                completion(NO, nil);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[NSAlert alertWithError:error] runModal];
        
        if (completion) {
            completion(NO, nil);
        }
    }];
}

- (void)unlockForLanId:(NSString *)lanId userId:(NSString *)userId completion:(void (^)(BOOL result))completion {
    NSDictionary *dic = @{
                          @"objectId": userId,
                          @"invocationOperationId": @67,
                          @"requestForm": @{
                                  @"formId": @57,
                                  @"layout": @"[{\"backendName\":\"aia_LANID\",\"type\":\"text\",\"readOnly\":true,\"propLayoutName\":\"bf966e79-963e-41c5-877d-482732516177\",\"mandatory\":true,\"errors\":[],\"value\":\"\"},{\"backendName\":\"\",\"type\":\"message\",\"message\":\"<p><span style=\\\"font-size:10pt\\\">&nbsp; &nbsp;<strong><em>Note:</em></strong></span></p><ul><li><span style=\\\"font-size:10.5pt\\\">Please press &#39;<strong>Submit</strong>&#39; to unlock the LAN ID.</span><span style=\\\"font-size:10.5pt\\\"> T</span><span style=\\\"font-size:10.5pt\\\">he account </span><span style=\\\"font-size:10.5pt\\\">will be unlocked automatically </span><span style=\\\"font-size:10.5pt\\\">in Active Directory.</span><span style=\\\"font-size:10.5pt\\\"> A</span><span style=\\\"font-size:10.5pt\\\"> notification </span><span style=\\\"font-size:10.5pt\\\">email </span><span style=\\\"font-size:10.5pt\\\">will be sent to target user&#39;s email box.</span></li></ul><p><span style=\\\"font-size:14px\\\">&nbsp;</span></p><ul><li><span style=\\\"font-size:10.5pt\\\">Please note that system </span><span style=\\\"font-size:10.5pt\\\">may </span><span style=\\\"font-size:10.5pt\\\">take&nbsp;<strong>5</strong>&nbsp;minutes to <strong>10</strong>&nbsp;minutes for&nbsp;synchronization</span><span style=\\\"font-size:10.5pt\\\">.</span></li></ul><p><span style=\\\"font-size:14px\\\">&nbsp;</span></p><ul><li><span style=\\\"font-size:10.5pt\\\">If you press&nbsp;&#39;<strong>Save draft</strong>&#39;, system will on hold the reset request and save it in draft request list.</span></li></ul>\",\"size\":\"normal\",\"errors\":[]},{\"backendName\":\"|Unlockflag|\",\"hidden\":true,\"type\":\"text\",\"defaultValue\":\"\",\"propLayoutName\":\"e39c2393-ee8d-4d41-a2bd-b44c18c98d8d\",\"ref\":\"unlockflag\",\"initializationHandler\":\"function initialize(api, prop) {\\nvar unlockflag = api.getProp('unlockflag');\\n unlockflag.value = (api.getRequester().userData['FirstName'][0] + ' '+  api.getRequester().userData['LastName'][0]);\\n}\",\"errors\":[],\"value\":\"\"}]",
                                  @"formPropertyValues": @[
                                          @{
                                              @"formPropertyDefId": @976,
                                              @"values": @[lanId]
                                              },
                                          @{
                                              @"formPropertyDefId": @986,
                                              @"values": @[@"admin"]
                                              }
                                          ]
                                  }
                          };
    
    [self.manager POST:@"https://idm.aia.com/sigma/rest/invocationoperation" parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
        NSString *requestId = [NSString stringWithFormat:@"%@", dic[@"requestId"]];
        
        BOOL result = NO;
        NSString *informativeText = nil;
        
        if (requestId.length > 0) {
            result = YES;
            informativeText = [NSString stringWithFormat:@"Unlock lanID successfully! (RequestID: %@)", requestId];
        } else {
            result = NO;
            informativeText = @"Unlock lanID failed!";
        }
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = lanId;
        alert.informativeText = informativeText;
        [alert runModal];
        
        if (completion) {
            completion(result);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[NSAlert alertWithError:error] runModal];
        
        if (completion) {
            completion(NO);
        }
    }];
}

@end
