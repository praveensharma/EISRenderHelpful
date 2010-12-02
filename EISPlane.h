//
//  EISPlane.h
//
//  Created by Douglass Turner on 10/18/10.
//  Copyright 2010 Elastic Image Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EISVectorMatrix.h"

@interface EISPlane : NSObject {

	CGFloat m_a;
	CGFloat m_b;
	CGFloat m_c;
	CGFloat m_d;
}

- (id)initWithWithSurfaceNormal:(EISMatrix4x4)surfaceNormal pointOnPlane:(EISMatrix4x4)pointOnPlane;

- (void) cubicPanoramaFacePlaneIntersectionPoint:(EISMatrix4x4)point fromRayDirection:(EISMatrix4x4)rayDirection;

@property (nonatomic, readonly) CGFloat a;
@property (nonatomic, readonly) CGFloat b;
@property (nonatomic, readonly) CGFloat c;
@property (nonatomic, readonly) CGFloat d;

@end
