//
//  LEOWebDAVUploadRequest.m
//  LEOWebDAV
//
//  Created by Liu Ley on 12-11-6.
//  Copyright (c) 2012年 SAE. All rights reserved.
//

#import "LEOWebDAVUploadRequest.h"
@interface LEOWebDAVUploadRequest ()
{
    NSData *_uploadData;
    NSString *_mimeType;
    NSInputStream *_inputStream;
    long long _dataSize;
}
@end
@implementation LEOWebDAVUploadRequest

@synthesize data=_uploadData;
@synthesize dataMimeType=_mimeType;

-(instancetype)initWithPath:(NSString *)thePath andData:(NSData *)data
{
    self=[super initWithPath:thePath];
    if(self){
        self.dataMimeType=@"application/octet-stream";
        NSParameterAssert(_uploadData != nil);
        self.data = data;
        _dataSize = [data length];
    }
    return self;
}

-(instancetype)initWithPath:(NSString *)thePath inputStream:(NSInputStream *)stream size:(long long)size
{
    self=[super initWithPath:thePath];
    if(self){
        self.dataMimeType=@"application/octet-stream";
        _inputStream = stream;
        _dataSize = size;
    }
    return self;
}

- (NSURLRequest *)request {
	
    NSString *len = [NSString stringWithFormat:@"%lld", (long long)_dataSize];
    NSLog(@"upload len:%@",len);
    
	NSMutableURLRequest *req = [self newRequestWithPath:self.path method:@"PUT"];
    [req setValue:self.dataMimeType forHTTPHeaderField:@"Content-Type"];
    [req setValue:len forHTTPHeaderField:@"Content-Length"];
    if (_inputStream)
    {
        [req setHTTPBodyStream:_inputStream];
    }
    else
    {
        [req setHTTPBody:_uploadData];
    }
    
	return req;
}

-(id)resultForData:(NSData *)data
{
    return data;
}
@end
