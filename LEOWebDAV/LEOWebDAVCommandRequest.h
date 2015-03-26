//
//  LEOWebDAVAdditionalCommandRequest.h
//  DownloaderPlus
//
//  Created by Vasyuchenko Alexander on 26.03.15.
//  Copyright (c) 2015 Macsoftex. All rights reserved.
//

#import "LEOWebDAVRequest.h"

@interface LEOWebDAVCommandRequest : LEOWebDAVRequest

- (id)initWithCommand:(NSString*)command;

@end
