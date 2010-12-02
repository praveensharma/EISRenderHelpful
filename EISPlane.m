//
//  EISPlane.m
//
//  Created by Douglass Turner on 10/18/10.
//  Copyright 2010 Elastic Image Software LLC. All rights reserved.
//

#import "EISPlane.h"
#import "Logging.h"

@implementation EISPlane

@synthesize a = m_a;
@synthesize b = m_b;
@synthesize c = m_c;
@synthesize d = m_d;

- (void)dealloc {
	
	DLog(@"");

	[super dealloc];
}

- (id)initWithWithSurfaceNormal:(EISMatrix4x4)surfaceNormal pointOnPlane:(EISMatrix4x4)pointOnPlane {
	
	self = [super init];
	if (nil != self) {
		
		m_a = surfaceNormal[0];
		m_b = surfaceNormal[1];
		m_c = surfaceNormal[2];
		
		float norm = sqrtf(m_a * m_a + m_b * m_b + m_c * m_c);
		
		m_a /= norm;
		m_b /= norm;
		m_c /= norm;
		
		// Calculate the residual
		m_d = -( pointOnPlane[0] * m_a + pointOnPlane[1] * m_b + pointOnPlane[2] * m_c );
				
	} // if (nil != self)
	
	return self;
}

- (void) cubicPanoramaFacePlaneIntersectionPoint:(EISMatrix4x4)point fromRayDirection:(EISMatrix4x4)rayDirection {

	CGFloat dotProduct =  m_a * rayDirection[0] + m_b * rayDirection[1] + m_c * rayDirection[2];
			
    CGFloat t = -m_d / dotProduct;
	
	point[0] = t * rayDirection[0];
	point[1] = t * rayDirection[1];
	point[2] = t * rayDirection[2];
	
}

@end
