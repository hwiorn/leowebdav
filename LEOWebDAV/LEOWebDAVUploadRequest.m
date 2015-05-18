//
//  LEOWebDAVUploadRequest.m
//  LEOWebDAV
//
//  Created by Liu Ley on 12-11-6.
//  Copyright (c) 2012年 SAE. All rights reserved.
//

#import "LEOWebDAVUploadRequest.h"
@interface LEOWebDAVUploadRequest () <NSURLConnectionDataDelegate>
{
    NSData *_uploadData;
    NSString *_mimeType;
    NSURL *_fileURL;
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

-(instancetype)initWithPath:(NSString *)thePath fileURL:(NSURL *)url size:(long long)size
{
    self=[super initWithPath:thePath];
    if(self){
        self.dataMimeType=@"application/octet-stream";
        _fileURL = url;
        _dataSize = size;
    }
    return self;
}

- (NSURLRequest *)request {
	
    NSString *len = [NSString stringWithFormat:@"%lld", (long long)_dataSize];
    NSLog(@"upload len:%@",len);
    
	NSMutableURLRequest *req = [self newRequestWithPath:self.path method:@"PUT"];
//    [req setValue:self.dataMimeType forHTTPHeaderField:@"Content-Type"];
    [req setValue:len forHTTPHeaderField:@"Content-Length"];
    if (_fileURL)
    {
        [req setHTTPBodyStream:[[NSInputStream alloc] initWithURL:_fileURL]];
    }
    else
    {
        [req setHTTPBody:_uploadData];
    }
    
	return req;
}

-(NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
    return [[NSInputStream alloc] initWithURL:_fileURL];
}

-(id)resultForData:(NSData *)data
{
    return data;
}
@end
