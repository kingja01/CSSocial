//
//  CSFacebookParameter.h
//  CSCocialManager2.0
//
//  Created by Luka Fajl on 26.6.2012..
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

#import "CSSocialParameter.h"
#import <UIKit/UIImage.h>

@interface CSFacebookParameter : CSSocialParameter

+(id<CSSocialParameter>) message:(NSString *)message
                            name:(NSString*)name
                            link:(NSString*)link
                      pictureURL:(NSString*)pictureURL
                         caption:(NSString*)caption
                     description:(NSString*)description
                            icon:(NSString*) icon;

+(id<CSSocialParameter>) photo:(UIImage*)image message:(NSString*)message;
+(id<CSSocialParameter>) user;
+(id<CSSocialParameter>) userImage;
+(id<CSSocialParameter>) userImageWithType:(NSString*) type;
+(id<CSSocialParameter>) friends;

///+(id<CSSocialParameter>) friendsWithPagingOffset:(NSInteger) offset limit:(NSInteger) limit;

@end
