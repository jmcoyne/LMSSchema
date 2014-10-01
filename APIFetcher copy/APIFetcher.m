//
//  APIFetcher.m
//  auth
//
//  Created by Joan Coyne on 8/20/14.
//  Copyright (c) 2014 Mzinga. All rights reserved.
//

#import "APIFetcher.h"


@implementation APIFetcher


+ (NSURL *)URLForQuery:(NSString *)query
{
    query = [NSString stringWithFormat:@"%@&email=jcoyne@mzinga.com&authentication_token=mvsiZ62FvgPP9Myh1DyY", query];
    query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:query];

}

+ (NSURL *)URLforClassList

{
    return [self URLForQuery:@"https://test.lifeplot.com/api/v1/courses?"];
}
+ (NSURL *)URLforInformationAboutClass:(NSInteger)classId
{
    return [self URLForQuery:[NSString stringWithFormat:@"https://test.lifeplot.com/api/v1/courses/%d", classId]];
}
+ (NSURL *)URLforInformationAboutClassHardcoded
{
    return [self URLForQuery:@"https://test.lifeplot.com/api/v1/courses/1"];
}
+ (NSURL *)URLforCourseImage:(NSString *)courseImageURL
{
    return [NSURL URLWithString:courseImageURL];
}

@end
