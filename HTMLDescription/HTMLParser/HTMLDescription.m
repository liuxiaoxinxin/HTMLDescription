//
//  HTMLDescription.m
//  TopsTechLoop
//
//  Created by 刘继新 on 2017/9/12.
//  Copyright © 2017年 TopsTech. All rights reserved.
//

#import "HTMLDescription.h"

@implementation HTMLModel

@end

@implementation HTMLDescription

+ (void)captureHTMLDescriptionWithURL:(NSURL *)url complete:(void (^)(HTMLModel *data, NSError *error))complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        HTMLModel *model = [[HTMLModel alloc]init];
        model.URL = url;
        NSString *htmlString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        NSError *error = nil;
        HTMLParser *parser = [[HTMLParser alloc]initWithString:htmlString error:&error];
        if (nil == error) {
            HTMLNode *headNode = [parser head];
            HTMLNode *bodyNode = [parser body];
            
            HTMLNode *titleNode = [headNode findChildTag:@"title"];
            model.title = [titleNode contents];
            NSArray *metaNodes = [headNode findChildTags:@"meta"];
            for (HTMLNode *node in metaNodes) {
                if ([[node getAttributeNamed:@"name"] isEqualToString:@"description"]) {
                    model.descriptionText = [node getAttributeNamed:@"content"];
                    break;
                }
            }
            // 如果没有meta-description，继续在body正文内内抓取
            if (model.descriptionText == nil) {
                // 遍历body里所有<p>节点
                NSArray *paragraphNode = [bodyNode findChildTags:@"p"];
                NSString *firstContent = nil;
                for (HTMLNode *node in paragraphNode) {
                    NSString *content = [node allContents];
                    content = [content stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    content = [content stringByReplacingOccurrencesOfString:@" " withString:@""];
                    if (firstContent == nil) {
                        firstContent = content;
                    }
                    // 如果段落文字长度合适(大于30).就取出来用做描述
                    if (content.length > 30) {
                        model.descriptionText = content;
                        break;
                    }
                }
                if (model.descriptionText == nil) {
                    model.descriptionText = firstContent;
                }
            }
            // 抓取图片
            NSArray *imgNodes = [bodyNode findChildTags:@"img"];
            for (HTMLNode *node in imgNodes) {
                NSString *src = [self getImgTagSrc:node url:url];
                if (src) {
                    model.coverURL = src;
                    break;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complete) {
                complete(model, error);
            }
        });
    });
}

+ (NSString *)getImgTagSrc:(HTMLNode *)imgNode url:(NSURL *)url {
    NSString *src = [imgNode getAttributeNamed:@"src"];
    if (src == nil || src.length == 0) {
        src = [imgNode getAttributeNamed:@"data-src"];
    }
    if (src == nil || src.length == 0) {
        return nil;
    }
    if ([src hasPrefix:@"http://"] || [src hasPrefix:@"https://"]) {
        return src;
    }
    src = [NSString stringWithFormat:@"%@%@",url.host,src];
    return src;
}

@end
