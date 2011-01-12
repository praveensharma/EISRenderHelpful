//
//  EISTexture.h
//  BeautifulPanoramas
//
//  Created by turner on 5/26/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define	checkPatternWidth  (8)
#define	checkPatternHeight (8)

typedef enum {
	NGTextureFormat_Invalid = 0,
	NGTextureFormat_A8,
	NGTextureFormat_LA88,
	NGTextureFormat_RGB_565,
	NGTextureFormat_RGBA_5551,
	NGTextureFormat_RGB_888,
	NGTextureFormat_RGBA_8888,
	NGTextureFormat_RGB_PVR2,
	NGTextureFormat_RGB_PVR4,
	NGTextureFormat_RGBA_PVR2,
	NGTextureFormat_RGBA_PVR4,
} NGTextureFormat;

@interface EISTexture : NSObject {
	
	GLuint		m_name;
	GLuint		m_location;
	
	GLuint		m_width;
	GLuint		m_height;
	
	NSUInteger	m_channelCount;
	
	NSString	*m_filename;
	
	NGTextureFormat m_format;
}

@property (nonatomic, assign) GLuint		name;
@property (nonatomic, assign) GLuint		location;
@property (nonatomic, assign) GLuint		width;
@property (nonatomic, assign) GLuint		height;
@property (nonatomic        ) NSUInteger	channelCount;
@property (nonatomic,   copy) NSString		*filename;
@property (nonatomic, readonly) NGTextureFormat format;

- (id)initWithOpearationResults:(NSDictionary *)results;

- (id)initWithImageData:(NSValue *)imageData 
				  width:(GLsizei)width
				 height:(GLsizei)height 
		 internalFormat:(GLint)internalFormat
				 format:(GLenum)format 
				   type:(GLenum)type 
				 mipmap:(BOOL)mipmap;

- (id)initWithImageFilePrefix:(NSString *)prefix mipmap:(BOOL)mipmap;

- (id)initWithImageFilePrefix:(NSString *)prefix suffix:(NSString *)suffix mipmap:(BOOL)mipmap;

- (id)initWithTextureFileNameFullPath:(NSString *)fullPath mipmap:(BOOL)mipmap;

- (id)initWithWaveletData:(NSDictionary *)data;

- (id)initAsRandomValuesWidth:(NSUInteger)width height:(NSUInteger)height;

- (id)initWithCheckPattern;

+ (BOOL) isSizePowerOfTwo:(uint32_t)size;

+ (int) nextPowerOfTwoGivenSize:(int)size;

+ (int) glColorGivenTextureFormat:(NGTextureFormat)format;

+ (int) glFormatGivenTextureFormat:(NGTextureFormat)format;

+ (NGTextureFormat) textureFormatFromCGImage:(CGImageRef)aCGImageRef;

+ (NSUInteger)channelsFromNGTextureFormat:(NGTextureFormat)format;

+ (uint8_t *) imageDataFromCGImageRef:(CGImageRef)imageRef textureFormat:(NGTextureFormat)format;

@end
