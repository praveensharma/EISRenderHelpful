//
//  EISTexture.m
//  BeautifulPanoramas
//
//  Created by turner on 5/26/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import "EISTexture.h"
#import "EISGLHelpful.h"
#import "Logging.h"

static int singles2halfp(void *dstHalfFloat, void *srcFloat, int length);

static GLubyte checkPatternUnsignedByte[checkPatternHeight * checkPatternWidth];
static float checkPatternFloat[checkPatternHeight * checkPatternWidth];

const int kMaxTextureSizeExp = 10;
#define kMaxTextureSize (1 << kMaxTextureSizeExp)

@interface EISTexture (PrivateMethods)

+ (NSString*)textureDescriptionFromNGTextureFormat:(NGTextureFormat)format;
+ (NSString*)glInternalDataFormatDescriptionFromNGTextureFormat:(NGTextureFormat)format;
+ (NSString*)glInternalColorFormatDescriptionFromNGTextureFormat:(NGTextureFormat)format;

+ (NSString*)alphaDescriptionForAlphaInfo:(CGImageAlphaInfo)alphaInfo;

+ (void) createCheckPatternUnsignedByte;
+ (void) createCheckPatternFloat;

+ (void) randomValueLookUpTableBuffer:(float *) buffer width:(NSUInteger)width height:(NSUInteger)height;

@end

@implementation EISTexture

@synthesize name = m_name;
@synthesize location = m_location;
@synthesize width = m_width;
@synthesize height = m_height;
@synthesize channelCount = m_channelCount;
@synthesize filename = m_filename;
@synthesize format = m_format;

- (void)dealloc {
	
//	DLog(@"%@", self);
	
	glDeleteTextures(1, &m_name);

	m_name = 0;
	m_location = 0;
	
    [m_filename release], m_filename = nil;
	
	[super dealloc];
}

+ (BOOL) isSizePowerOfTwo:(uint32_t)size {
	
	return ((size & (size - 1)) == 0);
}

+ (int) nextPowerOfTwoGivenSize:(int)size {
	
	if ([EISTexture isSizePowerOfTwo:size]) {
		
		return size;
		
	}
	
	for (int i = kMaxTextureSizeExp - 1; i > 0; i--) {
		
		if (size & (1 << i)) return (size << (i + 1));
		
	}
	
	return kMaxTextureSize;
	
}

+ (int) glColorGivenTextureFormat:(NGTextureFormat)format {
	
	switch (format) {
			
		case NGTextureFormat_RGB_888:
		case NGTextureFormat_RGBA_5551:
		case NGTextureFormat_RGBA_8888:
			return GL_RGBA;
						
		case NGTextureFormat_RGB_565:
			return GL_RGB;
			
		case NGTextureFormat_A8:
			return GL_ALPHA;
//			return GL_LUMINANCE;
			
		case NGTextureFormat_LA88:
			return GL_LUMINANCE_ALPHA;
			
		default:
			return 0;
	}

}

+ (int) glFormatGivenTextureFormat:(NGTextureFormat)format {
	
	switch (format) {
		case NGTextureFormat_A8:
		case NGTextureFormat_LA88:
		case NGTextureFormat_RGB_888:
		case NGTextureFormat_RGBA_8888:
			return GL_UNSIGNED_BYTE;
		case NGTextureFormat_RGBA_5551:
			return GL_UNSIGNED_SHORT_5_5_5_1;
		case NGTextureFormat_RGB_565:
			return GL_UNSIGNED_SHORT_5_6_5;
		default:
			return 0;
	}

}

+ (NGTextureFormat) textureFormatFromCGImage:(CGImageRef)aCGImageRef {
	
	DLog(@"Regarding alpha %@", [self alphaDescriptionForAlphaInfo:(CGImageGetAlphaInfo(aCGImageRef))]);

	CGImageAlphaInfo alpha = CGImageGetAlphaInfo(aCGImageRef);
	
	bool hasAlpha = FALSE;
	hasAlpha = (alpha != kCGImageAlphaNone && alpha != kCGImageAlphaNoneSkipLast && alpha != kCGImageAlphaNoneSkipFirst);
	
	CGColorSpaceRef color = CGImageGetColorSpace(aCGImageRef);
	CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(color);
	
	int bpp	= CGImageGetBitsPerPixel(aCGImageRef);
	
	if (color != NULL) {
		
		if ( colorSpaceModel == kCGColorSpaceModelMonochrome) {
			
			if (hasAlpha) {
				
				return NGTextureFormat_LA88;
			} else {
				
				return NGTextureFormat_A8;
			}
			
		}
		
		if (bpp == 16) {
			
			if (hasAlpha) {
				
				return NGTextureFormat_RGBA_5551;
			} else {
				
				return NGTextureFormat_RGB_565;
			}
			
		}
		
		if (hasAlpha) {
			
			return NGTextureFormat_RGBA_8888;
		} else {
			
			return NGTextureFormat_RGB_888;
		}
		
	}
	
	return NGTextureFormat_A8;

}

+ (uint8_t *) imageDataFromCGImageRef:(CGImageRef)imageRef textureFormat:(NGTextureFormat)format {
	
	CGContextRef	context		= NULL;
	uint8_t*		data		= NULL;
	CGColorSpaceRef	colorSpace	= NULL;
	
	int  width	=  CGImageGetWidth(imageRef);
	int height	= CGImageGetHeight(imageRef);
	
	int num_channels = 0;
	
	switch (format) {
			
		case NGTextureFormat_RGBA_8888:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			num_channels = 4;
			data = malloc(height * width * num_channels);
			context = CGBitmapContextCreate(data, 
											width, 
											height, 
											8, 
											num_channels * width, 
											colorSpace, 
											kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
			break;
			
		case NGTextureFormat_RGB_888:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			num_channels = 4;
			data = malloc(height * width * num_channels);
			context = CGBitmapContextCreate(data, 
											width, 
											height, 
											8, 
											num_channels * width, 
											colorSpace, 
											kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
			break;
			
		case NGTextureFormat_A8:
			colorSpace = CGColorSpaceCreateDeviceGray();
			num_channels = 1;
			data = malloc(height * width * num_channels);
			context = CGBitmapContextCreate(data, 
											width, 
											height, 
											8, 
											num_channels * width, 
											colorSpace, 
											kCGImageAlphaNone);
			break;
			
		case NGTextureFormat_LA88:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			num_channels = 4;
			data = malloc(height * width * num_channels);
			context = CGBitmapContextCreate(data, 
											width, 
											height, 
											8, 
											num_channels * width, 
											colorSpace, 
											kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
			break;
			
		default:
			break;
	}

	CGColorSpaceRelease(colorSpace);
	
	if(context == NULL) {
		
		return NULL;
	}
		
    CGContextSetBlendMode(context, kCGBlendModeCopy);
	
	// This is needed because Quartz uses an origin at lower left and UIKit uses
	// origin at upper left
	// CGAffineTransformMake(a b c d tx ty)
	//
	//   a  c  tx
	//   b  d  ty
	//
	// To invert the image do this
	//   1   0  0
	//   0  -1  height
	//
	CGAffineTransform flipped = CGAffineTransformMake(1, 0, 0, -1, 0, height);
	CGContextConcatCTM(context, flipped);
	
	CGRect rect =  CGRectMake(0, 0, width, height);
	CGContextDrawImage(context, rect, imageRef);
	
	CGContextRelease(context);
	
	return data;
}

- (id)initWithImageFilePrefix:(NSString *)prefix mipmap:(BOOL)mipmap {
	
	self.filename = prefix;
	
	NSString *path = nil;
	
	path = [[NSBundle mainBundle] pathForResource:prefix ofType:@"jpg"];
	
	if (nil == path) {
		
		path = [[NSBundle mainBundle] pathForResource:prefix ofType:@"png"];
		
		if (nil == path) {
			
			return self;
			
		} // if (nil == path)
		
	} // if (nil == path)
	
	return [self initWithTextureFileNameFullPath:path mipmap:mipmap];
	
}

- (id)initWithImageFilePrefix:(NSString *)prefix suffix:(NSString *)suffix mipmap:(BOOL)mipmap {
	
	self.filename = prefix;
	
	NSString *path = [[NSBundle mainBundle] pathForResource:prefix ofType:suffix];

	if ([suffix isEqualToString:@"jpg"] || [suffix isEqualToString:@"png"]) {
		
		return [self initWithTextureFileNameFullPath:path mipmap:mipmap];
	
	} // if ([suffix isEqualToString:@"jpg"] || [suffix isEqualToString:@"png"])

	return self;
	
}

- (id)initWithTextureFileNameFullPath:(NSString *)fullPath mipmap:(BOOL)mipmap {
	
	self = [super init];
	
	if(nil != self) {
		
		UIImage *uiImage = [[UIImage alloc] initWithContentsOfFile:fullPath];
		
		if (uiImage.CGImage != NULL) {
			
			m_format	= [EISTexture textureFormatFromCGImage:uiImage.CGImage];
			
			int glColorFormat = [EISTexture  glColorGivenTextureFormat:self.format];
			int  glDataFormat = [EISTexture glFormatGivenTextureFormat:self.format];
			
			m_width		= CGImageGetWidth( uiImage.CGImage);
			m_height	= CGImageGetHeight(uiImage.CGImage);
			
			m_channelCount	= [EISTexture channelsFromNGTextureFormat:self.format];

			DLog(@"%@", self);
			
			uint8_t *imageData = [EISTexture imageDataFromCGImageRef:uiImage.CGImage textureFormat:self.format];
			[uiImage release];
			
			
			glGenTextures(1, &m_name);
			glBindTexture(GL_TEXTURE_2D, m_name);
			
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			
			
			if (YES == mipmap) {
				
				// lerp 4 nearest texels and lerp between pyramid levels.
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
				
				// lerp 4 nearest texels.
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				
				
				
				glTexImage2D(GL_TEXTURE_2D, 0, glColorFormat, m_width, m_height, 0, glColorFormat, glDataFormat, imageData);
				glGenerateMipmap( GL_TEXTURE_2D );
				
			} else {
				
				// Straight texture mapping. NO mipmaps thank you very much.
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				
				glTexImage2D(GL_TEXTURE_2D, 0, glColorFormat, m_width, m_height, 0, glColorFormat, glDataFormat, imageData);
				
			}
			
			free(imageData);
						
		} else {
			
			[uiImage release];
		}
		
		
	} // if(nil != self)
	
	return self;
}

- (id)initWithOpearationResults:(NSDictionary *)results {
	
	int glColorFormat	=	[[results objectForKey:@"glColor" ] intValue];
	int glDataFormat	=	[[results objectForKey:@"glFormat"] intValue];
	int w				=	[[results objectForKey:@"width" ] intValue];
	int h				=	[[results objectForKey:@"height"] intValue];
	NSValue *value		=	[results objectForKey:@"textureData"];
	

	id thang = [self initWithImageData:value width:w height:h internalFormat:glColorFormat format:glColorFormat type:glDataFormat mipmap:NO];
	uint8_t *bits = [value pointerValue];
	free(bits);
	
	
	return thang;
	
}

- (id)initWithImageData:(NSValue *)imageData 
				  width:(GLsizei)width
				 height:(GLsizei)height 
		 internalFormat:(GLint)internalFormat
				 format:(GLenum)format 
				   type:(GLenum)type 
				 mipmap:(BOOL)mipmap {
	
	self = [super init];
	
	if(nil != self) {
		
		glGenTextures(1, &m_name);
		glBindTexture(GL_TEXTURE_2D, m_name);
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		GLvoid *data = [imageData pointerValue];

		if (YES == mipmap) {
			
			// lerp 4 nearest texels and lerp between pyramid levels.
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
			
			// lerp 4 nearest texels.
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		
			
			glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, width, height, 0, format, type, data);
			glGenerateMipmap( GL_TEXTURE_2D );
			
		} else {
			
			// Straight texture mapping. NO mipmaps thank you very much.
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			
			
			glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, width, height, 0, format, type, data);
			
		}
				
		if(glGetError()) {
			DLog(@"glTexImage2D failed");
		}
		
	} // if(nil != self)
	
	return self;

}

- (id)initWithWaveletData:(NSDictionary *)data {
	
	self = [super init];
	
	if(nil != self) {
		
		m_width		= [[data objectForKey:   @"width"] unsignedIntValue];
		m_height	= [[data objectForKey:  @"height"] unsignedIntValue];
		m_channelCount	= [[data objectForKey:@"channels"] unsignedIntValue];
		
		glGenTextures(1, &m_name);
		[EISGLHelpful checkGLError];
		glBindTexture(GL_TEXTURE_2D, m_name);
		[EISGLHelpful checkGLError];
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		[EISGLHelpful checkGLError];
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		[EISGLHelpful checkGLError];
		
		NSData *d = [data objectForKey:@"pixels"];
		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, m_width, m_height, 0, GL_LUMINANCE, GL_HALF_FLOAT_OES, (GLubyte *)[d bytes]);
		[EISGLHelpful checkGLError];
		
	}
	
	return self;
}

- (id)initAsRandomValuesWidth:(NSUInteger)width height:(NSUInteger)height {
	
	self = [super init];
	
	if(nil != self) {

		self.width = width;
		self.height = height;

		float *floats = malloc(self.width * self.height * sizeof(float));
		[EISTexture randomValueLookUpTableBuffer:floats width:self.width height:self.height];
		
		int numberOfSamples = self.width * self.height;
		int length = numberOfSamples * sizeof(unsigned short);
		unsigned short *halfFloats = (unsigned short *) malloc(length);
		
		(void)singles2halfp((void *)halfFloats, (void *)floats, numberOfSamples);
		free(floats);
		
		
		glGenTextures(1, &m_name);
		glBindTexture(GL_TEXTURE_2D, m_name);
		
		// Clamp at texture boundaries
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// NO interpolation of table values
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		
		m_channelCount	= 1;
		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, self.width, self.height, 0, GL_LUMINANCE, GL_HALF_FLOAT_OES, (GLubyte *)halfFloats);
		[EISGLHelpful checkGLError];
		
		free(halfFloats);
	}
	
	return self;
	
}

- (id)initWithCheckPatternLuminanceTextureUnsignedByte {
	
	self = [super init];
	
	if(nil != self) {
		
		[EISTexture createCheckPatternUnsignedByte];
		
		
		m_width	= checkPatternWidth;
		m_height	= checkPatternHeight;
		
		glGenTextures(1, &m_name);
		glBindTexture(GL_TEXTURE_2D, m_name);
		
		// Wrap at texture boundaries
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		
		m_channelCount	= 1;
//		glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA,		m_width, m_height, 0, GL_ALPHA,		GL_UNSIGNED_BYTE, (GLubyte *)checkPatternUnsignedByte);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE,	m_width, m_height, 0, GL_LUMINANCE,	GL_UNSIGNED_BYTE, (GLubyte *)checkPatternUnsignedByte);
		
		[EISGLHelpful checkGLError];
		
	}
	
	return self;
}

- (id)initWithCheckPatternLuminanceTextureHalfFloat {
	
	self = [super init];
	
	if(nil != self) {
		
		[EISTexture createCheckPatternFloat];
		
		self.width = checkPatternWidth;
		self.height = checkPatternHeight;

		int numberOfSamples = self.width * self.height;
		int length = numberOfSamples * sizeof(unsigned short);
		unsigned short *halfFloats = (unsigned short *) malloc(length);
		
		(void)singles2halfp((void *)halfFloats, (void *)checkPatternFloat, numberOfSamples);
				
		glGenTextures(1, &m_name);
		glBindTexture(GL_TEXTURE_2D, m_name);
		
		// Clamp at texture boundaries
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// NO interpolation of table values
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		
		m_channelCount	= 1;
		glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, self.width, self.height, 0, GL_LUMINANCE, GL_HALF_FLOAT_OES, (GLubyte *)halfFloats);
		[EISGLHelpful checkGLError];
		
		free(halfFloats);
	}
	
	return self;
}

- (NSString *)description {

	int glColorFormat = [EISTexture  glColorGivenTextureFormat:self.format];
	int  glDataFormat = [EISTexture glFormatGivenTextureFormat:self.format];
	
		return [NSString stringWithFormat:@"filename: %@  name: %d  location: %d  w x h: %d x %d  channels: %d  texture: %@  color: %@  data %@", 
				self.filename,
				self.name,
				self.location,
				self.width,
				self.height,
				self.channelCount,
				[EISTexture textureDescriptionFromNGTextureFormat:self.format],
				[EISTexture glInternalColorFormatDescriptionFromNGTextureFormat:glColorFormat],
				[EISTexture  glInternalDataFormatDescriptionFromNGTextureFormat:glDataFormat]
				];
	
}

#pragma mark -
#pragma mark TEITexture Private Methods

+ (NSString*)alphaDescriptionForAlphaInfo:(CGImageAlphaInfo)alphaInfo {
	
	NSString* result = nil;
	
	switch (alphaInfo) {
			
		case kCGImageAlphaNone:
			result = @"Alpha None";
			break;
		case kCGImageAlphaPremultipliedLast:
			result = @"Alpha Premultiplied Last";
			break;
		case kCGImageAlphaPremultipliedFirst:
			result = @"Alpha Premultiplied First";
			break;
		case kCGImageAlphaLast:
			result = @"Alpha Last";
			break;
		case kCGImageAlphaFirst:
			result = @"Alpha First";
			break;
		case kCGImageAlphaNoneSkipLast:
			result = @"Alpha None Skip Last";
			break;
		case kCGImageAlphaNoneSkipFirst:
			result = @"Alpha None Skip First";
			break;
		default:
			result = @"Unknown Alpha Description";
	}
	
	return result;
};

+ (NSString*)textureDescriptionFromNGTextureFormat:(NGTextureFormat)format {
	
	NSString* result = nil;
	
	switch (format) {
			
		case NGTextureFormat_Invalid:
			result = @"Invalid Texture Format";
			break;
		case NGTextureFormat_A8:
			result = @"alpha(8)";
			break;
		case NGTextureFormat_LA88:
			result = @"luminance(8) alpha(8)";
			break;
		case NGTextureFormat_RGB_565:
			result = @"rgb(565)";
			break;
		case NGTextureFormat_RGBA_5551:
			result = @"rgba(5551)";
			break;
		case NGTextureFormat_RGB_888:
			result = @"rgb(888)";
			break;
		case NGTextureFormat_RGBA_8888:
			result = @"rgba(8888)";
			break;
		case NGTextureFormat_RGB_PVR2:
			result = @"pvr-2bit(rgb)";
			break;
		case NGTextureFormat_RGB_PVR4:
			result = @"pvr-4bit(rgb)";
			break;
		case NGTextureFormat_RGBA_PVR2:
			result = @"pvr-2bit(rgba)";
			break;
		case NGTextureFormat_RGBA_PVR4:
			result = @"pvr-4bit(rgba)";
			break;
		default:
			result = @"Unknown Texture Format";
	}
	
	return result;
};

+ (NSString*)glInternalDataFormatDescriptionFromNGTextureFormat:(NGTextureFormat)format {
	
	NSString* result = nil;
	
	switch (format) {
			
		case GL_UNSIGNED_BYTE:
			result = @"GL_UNSIGNED_BYTE";
			break;
		case GL_UNSIGNED_SHORT_5_5_5_1:
			result = @"GL_UNSIGNED_SHORT_5_5_5_1";
			break;
		case GL_UNSIGNED_SHORT_5_6_5:
			result = @"GL_UNSIGNED_SHORT_5_6_5";
			break;
		default:
			result = @"Unknown Texture Format";
	}
	
	return result;
	
}

+ (NSString*)glInternalColorFormatDescriptionFromNGTextureFormat:(NGTextureFormat)format {
	
	NSString* result = nil;
	
	switch (format) {
			
		case GL_RGBA:
			result = @"GL_RGBA";
			break;
		case GL_RGB:
			result = @"GL_RGB";
			break;
		case GL_LUMINANCE:
			result = @"GL_LUMINANCE";
			break;
		case GL_ALPHA:
			result = @"GL_ALPHA";
			break;
		case GL_LUMINANCE_ALPHA:
			result = @"GL_LUMINANCE_ALPHA";
			break;
		default:
			result = @"Unknown Texture Format";
	}
	
	return result;
	
}

+ (NSUInteger)channelsFromNGTextureFormat:(NGTextureFormat)format {
	
	NSUInteger result = 0;
	
	switch (format) {
			
		case NGTextureFormat_Invalid:
			break;
			
		case NGTextureFormat_A8:
			result = 1;
			break;
			
		case NGTextureFormat_LA88:
			result = 2;
			break;
			
		case NGTextureFormat_RGB_PVR4:
		case NGTextureFormat_RGB_PVR2:
		case NGTextureFormat_RGB_888:
		case NGTextureFormat_RGB_565:
			result = 3;
			break;
			
		case NGTextureFormat_RGBA_PVR4:
		case NGTextureFormat_RGBA_PVR2:
		case NGTextureFormat_RGBA_8888:
		case NGTextureFormat_RGBA_5551:
			result = 4;
			break;
			
		default:
			result = 0;
	}
	
	return result;
};

+ (void) createCheckPatternUnsignedByte {
	
	NSUInteger k = 0;
	for (int i = 0; i < checkPatternHeight; i++) {
		
		for (int j = 0; j < checkPatternWidth; j++) {
			
			int c = ( ( ( (i & 0x8) == 0) ^ ( (j & 0x8) ) == 0) ) * 255;
			//			int c = ( ( ( (i & 0x4) == 0) ^ ( (j & 0x4) ) == 0) ) * 255;
			//			int c = ( ( ( (i & 0x2) == 0) ^ ( (j & 0x2) ) == 0) ) * 255;
			
			checkPatternUnsignedByte[ k ] = (GLubyte) c;
			
			++k;
		}		
		
	}
	
}

+ (void) createCheckPatternFloat {
	
	NSUInteger k = 0;
	for (int i = 0; i < checkPatternHeight; i++) {
		
		for (int j = 0; j < checkPatternWidth; j++) {
			
			int c = ( ( ( (i & 0x8) == 0) ^ ( (j & 0x8) ) == 0) ) * 255;
			//			int c = ( ( ( (i & 0x4) == 0) ^ ( (j & 0x4) ) == 0) ) * 255;
			//			int c = ( ( ( (i & 0x2) == 0) ^ ( (j & 0x2) ) == 0) ) * 255;
			
			checkPatternFloat[ k ] = (float) c;
			
			++k;
		}		
		
	}
	
}

+ (void) randomValueLookUpTableBuffer:(float *) buffer width:(NSUInteger)width height:(NSUInteger)height {

#define ARC4RANDOM_MAX (0x100000000)

	NSUInteger k = 0;
	for (int i = 0; i < width; i++) {
		
		for (int j = 0; j < height; j++) {
			
			// 0 to 1.0
			double r = ((double)arc4random() / ARC4RANDOM_MAX);
			
			buffer[k] = (float)r;
			
//			DLog(@"w(%d) x h(%d) = %.4f", i, j, buffer[k]);
			
			++k;
			
		} // for (height)
		
	} // for (width)
	
}

@end


#define  INT16_TYPE          short
#define UINT16_TYPE unsigned short
#define  INT32_TYPE          long
#define UINT32_TYPE unsigned long

int singles2halfp(void *dstHalfFloat, void *srcFloat, int length) {
	
    UINT16_TYPE *hp = (UINT16_TYPE *) dstHalfFloat; // Type pun output as an unsigned 16-bit int
    UINT32_TYPE *xp = (UINT32_TYPE *) srcFloat; // Type pun input as an unsigned 32-bit int
    UINT16_TYPE    hs, he, hm;
    UINT32_TYPE x, xs, xe, xm;
    int hes;
    static int next;  // Little Endian adjustment
    static int checkieee = 1;  // Flag to check for IEEE754, Endian, and word size
    double one = 1.0; // Used for checking IEEE754 floating point format
    UINT32_TYPE *ip; // Used for checking IEEE754 floating point format
    
    if( checkieee ) { // 1st call, so check for IEEE754, Endian, and word size
        ip = (UINT32_TYPE *) &one;
        if( *ip ) { // If Big Endian, then no adjustment
            next = 0;
        } else { // If Little Endian, then adjustment will be necessary
            next = 1;
            ip++;
        }
        if( *ip != 0x3FF00000u ) { // Check for exact IEEE 754 bit pattern of 1.0
            return 1;  // Floating point bit pattern is not IEEE 754
        }
        if( sizeof(INT16_TYPE) != 2 || sizeof(INT32_TYPE) != 4 ) {
            return 1;  // short is not 16-bits, or long is not 32-bits.
        }
        checkieee = 0; // Everything checks out OK
    }
    
    if( srcFloat == NULL || dstHalfFloat == NULL ) { // Nothing to convert (e.g., imag part of pure real)
        return 0;
    }
    
    while( length-- ) {
        x = *xp++;
        if( (x & 0x7FFFFFFFu) == 0 ) {  // Signed zero
            *hp++ = (UINT16_TYPE) (x >> 16);  // Return the signed zero
        } else { // Not zero
            xs = x & 0x80000000u;  // Pick off sign bit
            xe = x & 0x7F800000u;  // Pick off exponent bits
            xm = x & 0x007FFFFFu;  // Pick off mantissa bits
            if( xe == 0 ) {  // Denormal will underflow, return a signed zero
                *hp++ = (UINT16_TYPE) (xs >> 16);
            } else if( xe == 0x7F800000u ) {  // Inf or NaN (all the exponent bits are set)
                if( xm == 0 ) { // If mantissa is zero ...
                    *hp++ = (UINT16_TYPE) ((xs >> 16) | 0x7C00u); // Signed Inf
                } else {
                    *hp++ = (UINT16_TYPE) 0xFE00u; // NaN, only 1st mantissa bit set
                }
            } else { // Normalized number
                hs = (UINT16_TYPE) (xs >> 16); // Sign bit
                hes = ((int)(xe >> 23)) - 127 + 15; // Exponent unbias the single, then bias the halfp
                if( hes >= 0x1F ) {  // Overflow
                    *hp++ = (UINT16_TYPE) ((xs >> 16) | 0x7C00u); // Signed Inf
                } else if( hes <= 0 ) {  // Underflow
                    if( (14 - hes) > 24 ) {  // Mantissa shifted all the way off & no rounding possibility
                        hm = (UINT16_TYPE) 0u;  // Set mantissa to zero
                    } else {
                        xm |= 0x00800000u;  // Add the hidden leading bit
                        hm = (UINT16_TYPE) (xm >> (14 - hes)); // Mantissa
                        if( (xm >> (13 - hes)) & 0x00000001u ) // Check for rounding
                            hm += (UINT16_TYPE) 1u; // Round, might overflow into exp bit, but this is OK
                    }
                    *hp++ = (hs | hm); // Combine sign bit and mantissa bits, biased exponent is zero
                } else {
                    he = (UINT16_TYPE) (hes << 10); // Exponent
                    hm = (UINT16_TYPE) (xm >> 13); // Mantissa
                    if( xm & 0x00001000u ) // Check for rounding
                        *hp++ = (hs | he | hm) + (UINT16_TYPE) 1u; // Round, might overflow to inf, this is OK
                    else
                        *hp++ = (hs | he | hm);  // No rounding
                }
            }
        }
    }
    return 0;
}

