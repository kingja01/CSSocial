//
//  CSSocialServiceFacebook.m
//  CSCocialManager2.0
//
//  Created by Marko Hlebar on 6/21/12.
/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Clover Studio. All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "CSSocialServiceFacebook.h"
#import "CSSocialConstants.h"
#import "CSSocialUser.h"
#import "CSSocialParameter.h"
#import "CSFacebookParameter.h"
#import "CSSocial.h"
#import "CSSocialRequestFacebook.h"
#import "FacebookSDK.h"
#import <Social/SLComposeViewController.h>
#import <Social/SLServiceTypes.h>
#import "FBSettings.h"

/*
   FACEBOOK READ PERMISSIONS
   user_about_me                  friends_about_me                user_activities
   friends_activities             user_birthday                   friends_birthday
   user_checkins                  friends_checkins                user_education_history
   friends_education_history      user_events                     friends_events
   user_groups                    friends_groups                  user_hometown
   friends_hometown               user_interests                  friends_interests
   user_likes                     friends_likes                   user_notes
   friends_notes                  user_online_presence            friends_online_presence
   user_interests                 friends_interests               user_likes
   friends_likes                  user_notes                      friends_notes
   user_online_presence           friends_online_presence         user_religion_politics
   friends_religion_politics      user_status                     friends_status
   user_subscriptions             friends_subscriptions           user_videos
   friends_videos                 user_website                    friends_website
   user_work_history              friends_work_history            read_friendlists
   read_mailbox                   read_requests                   read_stream
   read_insights                  xmpp_login

   FACEBOOK PUBLISH PERMISSIONS
   publish_actions                publish_stream                  publish_checkins
   ads_management                 create_event                    rsvp_event
   manage_friendlists             manage_notifications            manage_pages
 */

#define kCSFBAccessTokenKey             @"FBAccessTokenKey"
#define kCSFBExpirationDateKey          @"FBExpirationDateKey"

///Get permissions here https://developers.facebook.com/docs/howtos/ios-6/
#define kCSFBAllReadPermissionsArray    [NSArray arrayWithObjects: \
                                         @"user_about_me",                  @"friends_about_me",                @"user_activities", \
                                         @"friends_activities",             @"user_birthday",                   @"friends_birthday", \
                                         @"user_checkins",                  @"friends_checkins",                @"user_education_history", \
                                         @"friends_education_history",      @"user_events",                     @"friends_events", \
                                         @"user_groups",                    @"friends_groups",                  @"user_hometown", \
                                         @"friends_hometown",               @"user_interests",                  @"friends_interests", \
                                         @"user_likes",                     @"friends_likes",                   @"user_notes", \
                                         @"friends_notes",                  @"user_online_presence",            @"friends_online_presence", \
                                         @"user_interests",                 @"friends_interests",               @"user_likes", \
                                         @"friends_likes",                  @"user_notes",                      @"friends_notes", \
                                         @"user_online_presence",           @"friends_online_presence",         @"user_religion_politics", \
                                         @"friends_religion_politics",      @"user_status",                     @"friends_status", \
                                         @"user_subscriptions",             @"friends_subscriptions",           @"user_videos", \
                                         @"friends_videos",                 @"user_website",                    @"friends_website", \
                                         @"user_work_history",              @"friends_work_history",            @"read_friendlists", \
                                         @"read_mailbox",                   @"read_requests",                   @"read_stream", \
                                         @"read_insights",                  @"xmpp_login",                      nil]

#define kCSFBAllPublishPermissionsArray [NSArray arrayWithObjects: \
                                         @"publish_actions",                @"publish_stream",                  @"publish_checkins", \
                                         @"ads_management",                 @"create_event",                    @"rsvp_event", \
                                         @"manage_friendlists",             @"manage_notifications",            @"manage_pages", \
                                         nil]

#pragma mark - CSSocialServiceFacebook

@interface CSSocialServiceFacebook ()
- (NSArray *)readPermissions;
- (NSArray *)publishPermissions;
@end

@implementation CSSocialServiceFacebook
{
    FBSession *_session;
}

- (void)dealloc {
    CS_RELEASE(_session);
    CS_SUPER_DEALLOC;
}

- (id)init {
    if ((self = [super init])) {
        ///TODO: add urlSchemeSuffix to plist, also allow for appID to be nil
        ///initialize session for the first time;
        [FBSettings setDefaultAppID:[self appID]];
        _session = [FBSession activeSession];

        self.audience = FBSessionDefaultAudienceEveryone;
    }
    return self;
}

- (BOOL)isAuthenticated {
    return (nil != _session && (_session.isOpen || FBSessionStateCreatedTokenLoaded == _session.state));
}

- (void)login:(CSVoidBlock)success error:(CSErrorBlock)error {
    self.loginSuccessBlock = success;
    self.loginFailedBlock = error;

    if (_session.isOpen) {
        if(self.loginSuccessBlock) self.loginSuccessBlock();
    } else {
        [FBSession openActiveSessionWithReadPermissions:[self readPermissions]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
        {
            ///session is updated and returns a new session object here
            [self handleSession:session status:status error:error];
        }];
    }
    _session = [FBSession activeSession];
}

- (void)handleSession:(FBSession *)session status:(FBSessionState)status error:(NSError *)error {
    _session = session;

    switch (status) {
        case FBSessionStateOpen:
            if(self.loginSuccessBlock) self.loginSuccessBlock();
            break;
        case FBSessionStateClosed:
            break;
        case FBSessionStateClosedLoginFailed:
            if(self.loginFailedBlock) self.loginFailedBlock(error);
            break;
        default:
            break;
    }
}

- (void)logout {
    [_session closeAndClearTokenInformation];
    _session = nil;
    [FBSession setActiveSession:_session];
}

- (CSSocialRequest *)constructRequestWithParameter:(id<CSSocialParameter>)parameter {
    CSSocialRequest *request = nil;

    switch (parameter.requestName) {
        case CSRequestLogin:
            break;
        case CSRequestLogout:
            break;
        case CSRequestUser:
            request = [CSSocialRequestFacebookUser requestWithService:_session parameters:[parameter parameters]];
            break;
        case CSRequestFriends:
            request = [CSSocialRequestFacebookFriends requestWithService:_session parameters:[parameter parameters]];
            break;
        case CSRequestFriendsPaging:
            request = [CSSocialRequestFacebookFriendsPaging requestWithService:_session parameters:[parameter parameters]];
            break;
        case CSRequestPostMessage:
            request = [CSSocialRequestFacebookPostWall requestWithService:_session parameters:[parameter parameters]];
            break;
        case CSRequestPostPhoto:
            request = [CSSocialRequestFacebookPostPhoto requestWithService:_session parameters:[parameter parameters]];
            break;
        case CSRequestGetUserImage:
            request = [CSSocialRequestFacebookGetUserImage requestWithService:_session parameters:[parameter parameters]];
            break;
        default:
            break;
    }

    return request;
}

-(NSString*) accessToken {
    return [[_session accessTokenData] accessToken];
}

- (NSString *)appID {
    NSString *appID = [[CSSocial configDictionary] objectForKey:kCSFacebookAppID];
    NSString *message = [NSString stringWithFormat:@"Add Facebook app ID %@ key to CSSocial.plist", kCSFacebookAppID];
    NSAssert(appID, message);
    return appID;
}

- (NSArray *)readPermissions {
    NSArray *permissions = [[CSSocial configDictionary] objectForKey:kCSFacebookPermissionsRead];
    NSString *message = [NSString stringWithFormat:@"Add array of permissions with %@ key to CSSocial.plist", kCSFacebookPermissionsRead];
    NSAssert(permissions, message);
    return permissions;
}

- (NSArray *)publishPermissions {
    NSArray *permissions = [[CSSocial configDictionary] objectForKey:kCSFacebookPermissionsPublish];
    NSString *message = [NSString stringWithFormat:@"Add array of permissions with %@ key to CSSocial.plist", kCSFacebookPermissionsPublish];
    NSAssert(permissions, message);
    return permissions;
}

- (BOOL)handleOpenURL:(NSURL *)url {
    return [_session handleOpenURL:url];
}

-(BOOL) openURL:(NSURL*) url sourceApplication:(NSString*) sourceApplication annotation:(id) annotation {
    return [_session handleOpenURL:url];
}

#pragma mark - Permissions And Permission handling

- (BOOL)permissionGranted:(NSString *)permission {
    return [[_session permissions] containsObject:permission];
}

- (void)requestPermissionsForRequest:(CSSocialRequest *)request permissionsBlock:(CSErrorBlock)permissionsBlock {
    CSSocialRequestFacebook *facebookRequest = (CSSocialRequestFacebook *)request;
    NSArray *permissions = facebookRequest.permissions;
    
    for (NSString *permission in permissions) {
        if (![self permissionGranted:permission]) {
            if ([self isPublishPermission:permission]) {
                [self requestPublishPermissions:@[permission]
                                     errorBlock:^(NSError *error) {
                                         permissionsBlock(error);
                                     }];
            } else {
                [self requestReadPermissions:@[permission]
                                  errorBlock:^(NSError *error) {
                    permissionsBlock(error);
                }];
            }
        } else permissionsBlock(nil);
    }
}

-(void) requestReadPermissions:(NSArray*) permissions errorBlock:(CSErrorBlock) errorBlock {
    [_session requestNewReadPermissions:permissions
                      completionHandler:^(FBSession *session, NSError *error) {
                          errorBlock(error);
                      }];
}

-(void) requestPublishPermissions:(NSArray*) permissions errorBlock:(CSErrorBlock) errorBlock {
    [_session requestNewPublishPermissions:permissions
                           defaultAudience:self.audience
                         completionHandler:^(FBSession *session, NSError *error) {
                             errorBlock(error);
                         }];
}

- (BOOL)isPublishPermission:(NSString *)permission {
    return [kCSFBAllPublishPermissionsArray containsObject:permission];
}

- (BOOL)isReadPermission:(NSString *)permission {
    return [kCSFBAllReadPermissionsArray containsObject:permission];
}

#pragma mark - Dialogs

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

- (id)showDialogWithMessage:(NSString *)message
                        url:(NSURL*) url
                      photo:(UIImage *)photo
                    handler:(CSErrorBlock)handlerBlock {
    
    if ([SLComposeViewController class]) {
        SLComposeViewController *viewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [viewController setInitialText:message];
        [viewController addImage:photo];
        [viewController setCompletionHandler:^(SLComposeViewControllerResult result)
         {
             switch (result) {
                 case SLComposeViewControllerResultDone:
                     handlerBlock(nil);
                     break;
                 case SLComposeViewControllerResultCancelled:
                     handlerBlock([self errorWithLocalizedDescription:@"Dialog cancelled."]);
                     break;
                 default:
                     break;
             }
             [[CSSocial viewController] dismissViewControllerAnimated:YES completion:nil];
         }];
        
        [[CSSocial viewController] presentViewController:viewController animated:YES completion:nil];
        return viewController;
    } else {
        [self login:^{
            
            // Put together the dialog parameters
            NSMutableDictionary *params =
            [NSMutableDictionary dictionaryWithObjectsAndKeys:
             //[url absoluteString],  @"title",
             message,               @"description",
             [url absoluteString],  @"link",
             //@"https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png", @"picture",
             nil];
            
            // Invoke the dialog
            [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                                   parameters:params
                                                      handler:
             ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                 if (error) {
                     // Error launching the dialog or publishing a story.
                     handlerBlock(error);
                 } else {
                     NSError *userCancelledError = [NSError errorWithDomain:@"com.clover-studio.cssocial"
                                                                       code:CSSocialErrorCodeUserCancelled
                                                                   userInfo:nil];
                     
                     if (result == FBWebDialogResultDialogNotCompleted) {
                         // User clicked the "x" icon
                         handlerBlock(userCancelledError);
                     } else {
                         // Handle the publish feed callback
                         NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                         if (![urlParams valueForKey:@"post_id"]) {
                             handlerBlock(userCancelledError);
                         } else {
                             handlerBlock(nil);
                         }
                     }
                 }
             }];
        }
              error:handlerBlock];
    }
    return nil;
}
         
@end
