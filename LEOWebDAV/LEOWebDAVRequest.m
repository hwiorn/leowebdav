//
//  LEOWebDAVRequest.m
//  LEOWebDAV
//
//  Created by Liu Ley on 12-10-30.
//  Copyright (c) 2012年 SAE. All rights reserved.
//

#import "LEOWebDAVRequest.h"
#import "LEOWebDAVDefines.h"
#import "LEOWebDAVURL.h"

@interface LEOWebDAVRequest ()
{
    NSString *_path;
    NSString *_relativePath;
    NSURLConnection *_connection;
    NSMutableData *_data;
    BOOL _done,_cancelled;
    BOOL _executing;
    long long _contentLength;
    long long _currentLength;
    long long _requestBodyLength;
    
    NSFileHandle *_fileHandle;
}
@end

@implementation LEOWebDAVRequest
@synthesize path=_path;
@synthesize delegate=_delegate;
@synthesize relativePath=_relativePath;
@synthesize instance,errorAction,successAction,receiveAction,startAction;

#pragma mark - Public methods
-(id)initWithPath:(NSString *)thePath
{
    self=[super init];
    if(self){
        _path=[thePath==nil ? @"":thePath copy];
    }
    return self;
}

// Must BE Override
-(NSURLRequest *)request
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:@"Subclasses of LEOWebDAVRequest must override 'request'"
								 userInfo:nil];
	return nil;
}

// Must BE Override
-(id)resultForData:(NSData *)data
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
								   reason:@"Subclasses of LEOWebDAVRequest must override 'resultForData'"
								 userInfo:nil];
    return nil;
}

#pragma mark - Private methods
- (BOOL)isExecuting {
	return _executing;
}

- (BOOL)isFinished {
	return _done;
}

- (BOOL)isCancelled {
	return _cancelled;
}

- (void)cancelWithCode:(NSInteger)code {
	[self willChangeValueForKey:@"isCancelled"];
	
	[_connection cancel];
	_cancelled = YES;
    [_fileHandle closeFile];
	
    NSString *errorLocalDes=nil;
    if (code==403) {
        errorLocalDes=NSLocalizedString(@"Forbidden Request",@"");
    }
    else if (code==500) {
        errorLocalDes=NSLocalizedString(@"Unexpected condition, Internal Server Error", @"");
    }
    NSDictionary *dic=nil;
    if (errorLocalDes!=nil) {
        dic=[NSDictionary dictionaryWithObject:errorLocalDes forKey:NSLocalizedDescriptionKey];
    }
    NSError *error=[NSError errorWithDomain:kWebDAVErrorDomain code:code userInfo:dic];
	[self didFail:error];
	
	[self didChangeValueForKey:@"isCancelled"];
}

- (void)cancel {
	[self cancelWithCode:-1];
}

- (void)didFail:(NSError *)error {
	if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[_delegate request:self didFailWithError:error];
	}
	
	[self didFinish];
}

- (void)start {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(start)
							   withObject:nil waitUntilDone:NO];
		
		return;
	}
	[self willChangeValueForKey:@"isExecuting"];
	
    NSURLRequest *request = [self request];

    _requestBodyLength = [[request valueForHTTPHeaderField:@"Content-Length"] longLongValue];
    
	_executing = YES;
	_connection = [NSURLConnection connectionWithRequest:request
												delegate:self];
	
	if ([_delegate respondsToSelector:@selector(requestDidBegin:)])
		[_delegate requestDidBegin:self];
	
	[self didChangeValueForKey:@"isExecuting"];
}

- (void)didFinish {
    if (_executing==NO) {
        return;
    }
    
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	
	_done = YES;
	_executing = NO;
	
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

-(NSString *)concatenatedURLWithPath:(NSString *)thePath
{
    NSParameterAssert(thePath!=nil);

    NSString *relativeRoot=[self.rootURL relativePath];
    NSString *temp=[NSString stringWithString:thePath];
    if([thePath hasPrefix:relativeRoot]) {
        temp = [temp substringFromIndex:relativeRoot.length];
    }
    temp = [temp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    _relativePath=[[NSString alloc] initWithFormat:@"%@",temp];
    return [[self.rootURL absoluteString] stringByAppendingString:_relativePath];
}

- (NSMutableURLRequest *)newRequestWithPath:(NSString *)path method:(NSString *)method
{
    NSURL *url = [[NSURL alloc] initWithString:[self concatenatedURLWithPath:path]];
//	NSLog(@"url:%@",url);
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setHTTPMethod:method];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:kWebDAVDefalutTimeOut];
	return request;
}
#pragma mark - Connection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (_data)
    {
        [_data appendData:data];
    }
    else if (_fileHandle)
    {
        [_fileHandle writeData:data];
    }
	
    _currentLength+=data.length;
    if(_delegate!=nil && [_delegate respondsToSelector:@selector(request:didReceivedProgress:)]) {
        [_delegate request:self didReceivedProgress:(float)_currentLength/_contentLength];
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [_fileHandle closeFile];
	[self didFail:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSInteger code = [(NSHTTPURLResponse *)response statusCode];
//        NSDictionary *dic=connection.currentRequest.allHTTPHeaderFields;
//        NSLog(@"header:%@",dic);
		
		if (code >= 400) {
			[self cancelWithCode:code];
            return;
		}
        if (_tmpPath)
        {
            _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_tmpPath];
            if (_fileHandle == nil)
            {
                [[NSFileManager defaultManager] createFileAtPath:_tmpPath contents:nil attributes:nil];
                _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_tmpPath];
            }
        }
        else
        {
            _data = nil;
            _data = [[NSMutableData alloc] init];
            [_data setLength:0];
        }
        _contentLength = [response expectedContentLength];
        _currentLength = 0.0;
        
        if (_delegate !=nil && [_delegate respondsToSelector:@selector(requestDidBegin:)]) {
            [_delegate requestDidBegin:self];
        }
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
    [_fileHandle closeFile];
    if ( _delegate!=nil && [_delegate respondsToSelector:@selector(request:didSucceedWithResult:)]) {
		id result = [self resultForData:_data];
		
		[_delegate request:self didSucceedWithResult:result];
	}
	
	[self didFinish];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	BOOL result = [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault] ||
	[protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic] ||
	[protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest] ||
	[protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
	
	return result;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		if (self.allowUntrusedCertificate)
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
				 forAuthenticationChallenge:challenge];
		
		[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
	} else {
		if ([challenge previousFailureCount] == 0) {
			NSURLCredential *credential = [NSURLCredential credentialWithUser:self.userName
																	 password:self.password
																  persistence:NSURLCredentialPersistenceNone];
			
			[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
		} else {
			// Wrong login/password
			[[challenge sender] cancelAuthenticationChallenge:challenge];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if(_delegate!=nil && [_delegate respondsToSelector:@selector(request:didSendBodyData:)]) {
        float percent = (_requestBodyLength==0) ? 0 : ((float)totalBytesWritten / _requestBodyLength);
        //NSLog(@"writen: %d, total: %d, percent: %f", (int)totalBytesWritten, (int)_requestBodyLength, percent);
        [_delegate request:self didSendBodyData:percent];
	}
}
@end
