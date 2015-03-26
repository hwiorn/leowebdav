//
//  LEOWebDAVAdditionalCommandRequest.m
//  DownloaderPlus
//
//  Created by Vasyuchenko Alexander on 26.03.15.
//  Copyright (c) 2015 Macsoftex. All rights reserved.
//

#import "LEOWebDAVCommandRequest.h"

@implementation LEOWebDAVCommandRequest
{
    NSString *_command;
}

- (id)initWithCommand:(NSString*)command
{
    if (self = [super init])
    {
        if ( !command )
            _command = @"";
        else
            _command = command;
    }
    
    return self;
}

- (NSURLRequest*)request
{
    NSMutableURLRequest *req = [self newRequestWithPath:@"/" method:@"COMMAND"];
    [req setValue:_command forHTTPHeaderField:@"Command"];
    
    return req;
}

@end
