//
//  GLHelpful.m
//  BeautifulPanoramas
//
//  Created by Douglass Turner on 12/4/10.
//  Copyright 2010 Elastic Image Software LLC. All rights reserved.
//

#import "EISGLHelpful.h"
#import "Logging.h"

@implementation EISGLHelpful

+ (BOOL)checkGLError {
	
    switch( glGetError() ) {
			
        case GL_NO_ERROR:
            return YES;
			
        case GL_INVALID_ENUM:
            DLog(@"GL_INVALID_ENUM");
            return NO;
			
        case GL_INVALID_VALUE:
            DLog(@"GL_INVALID_VALUE");
            return NO;
			
        case GL_INVALID_OPERATION:
            DLog(@"GL_INVALID_OPERATION");
            return NO;
			
        case GL_STACK_OVERFLOW:
            DLog(@"GL_STACK_OVERFLOW");
            return NO;
			
        case GL_STACK_UNDERFLOW:
            DLog(@"GL_STACK_UNDERFLOW");
            return NO;
			
        case GL_OUT_OF_MEMORY:
            DLog(@"GL_OUT_OF_MEMORY");
            return NO;
			
    }
	
	return NO;
	
}

@end
