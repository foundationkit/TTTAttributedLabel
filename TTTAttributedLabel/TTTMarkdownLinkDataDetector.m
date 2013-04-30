// TTTMarkdownLinkDataDetector.m
//
// Copyright (c) 2011 Mattt Thompson (http://mattt.me)
// Created by Matthias Tretter on 29.04.13.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TTTMarkdownLinkDataDetector.h"
#import <objc/runtime.h>


const NSTextCheckingTypes TTTTextCheckingTypeMarkdownLink = 1ULL << 20;
static NSString * const kTTTMarkdownLinkPattern = @"\\[(.*?)\\]\\((\\S+)(\\s+(\"|\').*?(\"|\'))?\\)";


static char linkTitleKey;
static char linkURLKey;


#pragma mark - NSTextCheckingResult (TTTMarkdownLink)

@implementation NSTextCheckingResult (TTTMarkdownLink)

- (NSString *)ttt_linkTitle {
    return objc_getAssociatedObject(self, &linkTitleKey);
}

- (NSURL *)ttt_URL {
    return objc_getAssociatedObject(self, &linkURLKey);
}

@end


@implementation TTTMarkdownLinkDataDetector

#pragma mark - Lifecycle

+ (instancetype)dataDetectorWithTypes:(NSTextCheckingTypes)checkingTypes error:(NSError *__autoreleasing *)error {
    return [[self alloc] initWithTypes:checkingTypes error:error];
}

- (instancetype)initWithTypes:(NSTextCheckingTypes)checkingTypes error:(NSError **)error {
    NSAssert(checkingTypes == TTTTextCheckingTypeMarkdownLink, @"Markdown link data detector currently only supports the checking type TTTTextCheckingTypeMarkdownLink");

    return (self = [super initWithPattern:kTTTMarkdownLinkPattern options:NSRegularExpressionCaseInsensitive error:error]);
}

- (id)initWithPattern:(NSString *) __unused pattern options:(NSRegularExpressionOptions)options error:(NSError *__autoreleasing *)error {
    return (self = [super initWithPattern:kTTTMarkdownLinkPattern options:options error:error]);
}

#pragma mark - NSRegularExpression

- (void)enumerateMatchesInString:(NSString *)string
                         options:(NSMatchingOptions)options
                           range:(NSRange)range
                      usingBlock:(void (^)(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop))block {

    [super enumerateMatchesInString:string options:options range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.numberOfRanges >= 3) {
            NSRange titleRange = [result rangeAtIndex:1];
            NSRange URLRange = [result rangeAtIndex:2];
            NSString *linkTitle = [string substringWithRange:titleRange];
            NSURL *URL = [NSURL URLWithString:[string substringWithRange:URLRange]];
            
            // TODO: update text checking result
            // [result setValue:@(TTTTextCheckingTypeMarkdownLink) forKey:@"resultType"];
            // [result setValue:[string substringWithRange:URLRange] forKey:@"URL"];
            objc_setAssociatedObject(result, &linkURLKey, URL, OBJC_ASSOCIATION_RETAIN);
            objc_setAssociatedObject(result, &linkTitleKey, linkTitle, OBJC_ASSOCIATION_COPY);

            block(result, flags, stop);
        }
    }];
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result inString:(NSString *)__unused string offset:(NSInteger) __unused offset template:(NSString *)templ {
    // $2 means substitute with URL, everything else means substitute with link title (Markdown default)
    if ([templ isEqualToString:@"$2"]) {
        return [result.ttt_URL absoluteString];
    }

    return result.ttt_linkTitle;
}

@end
