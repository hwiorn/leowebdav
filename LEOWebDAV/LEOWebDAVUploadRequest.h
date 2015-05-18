//
//  LEOWebDAVUploadRequest.h
//  LEOWebDAV
//
//  Created by Liu Ley on 12-11-6.
//  Copyright (c) 2012年 SAE. All rights reserved.
//

#import "LEOWebDAVRequest.h"

@interface LEOWebDAVUploadRequest : LEOWebDAVRequest
@property (strong) NSData *data;
@property (copy) NSString *dataMimeType;

-(instancetype)initWithPath:(NSString *)thePath andData:(NSData *)data;
-(instancetype)initWithPath:(NSString *)thePath fileURL:(NSURL *)url size:(long long)size;
@end
