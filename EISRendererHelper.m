//
//  EISRendererHelper.m
//
//  Created by turner on 3/4/10.
//  Copyright 2010 Douglass Turner Consulting. All rights reserved.
//

#import "EISRendererHelper.h"
#import "Logging.h"

@implementation EISRendererHelper

@synthesize renderables = m_renderables;

- (void) dealloc {
	
	[m_renderables release], m_renderables = nil;
    [super dealloc];
}

- (id) init {
	
	if (self = [super init]) {
		
		self.renderables = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
							 [NSNull null], @"texture",
							 [NSNull null], @"model",
							nil] autorelease];

		EISVector3DSet(   m_eye, 0, 0,  0);
		EISVector3DSet(m_target, 0, 0, -1);
		EISVector3DSet(    m_up, 0, 1,  0);
		
		EISMatrix4x4SetIdentity(        m_modelTransform);
		EISMatrix4x4SetIdentity(m_surfaceNormalTransform);
		
		EISMatrix4x4SetIdentity(m_viewTransform);

		EISMatrix4x4SetIdentity(m_cameraTransform);
		
		EISMatrix4x4SetIdentity(m_viewModelTransform);
		
		EISMatrix4x4SetIdentity(m_projection);

		EISMatrix4x4SetIdentity(m_projectionViewModelTransform);
		
		EISMatrix4x4SetIdentity(m_scaleTransform);

		EISMatrix4x4SetIdentity(m_translationTransform);

		EISMatrix4x4SetIdentity(       m_anchoredScaleTranslation);
		EISMatrix4x4SetIdentity(m_inverseAnchoredScaleTranslation);
		

	} // if (self = [super init])
	
	return self;
}

// eye
- (float *) eye {
	return &m_eye[0];
}

- (void) setEye:(EISVector3D)input {
	m_eye[0] = input[0];
	m_eye[1] = input[1];
	m_eye[2] = input[2];
}

- (void) setEyeX:(float)x y:(float)y z:(float)z {
	m_eye[0] = x;
	m_eye[1] = y;
	m_eye[2] = z;
	
}

// target
- (float *) target {
	return &m_target[0];
}

- (void) setTarget:(EISVector3D)input {
	m_target[0] = input[0];
	m_target[1] = input[1];
	m_target[2] = input[2];
}

- (void) setTargetX:(float)x y:(float)y z:(float)z {
	m_target[0] = x;
	m_target[1] = y;
	m_target[2] = z;
	
}

// up
- (float *) up {
	return &m_up[0];
}

- (void) setUp:(EISVector3D)input {
	m_up[0] = input[0];
	m_up[1] = input[1];
	m_up[2] = input[2];
}

- (void) setUpX:(float)x y:(float)y z:(float)z {
	m_up[0] = x;
	m_up[1] = y;
	m_up[2] = z;
	
}

- (void)perspectiveProjectionWithFieldOfViewInDegreesY:(GLfloat)fieldOfViewInDegreesY 
							aspectRatioWidthOverHeight:(GLfloat)aspectRatioWidthOverHeight 
												  near:(GLfloat)near 
												   far:(GLfloat)far {
	
	GLfloat top		= near * tanf( EISDegreeToRadian(fieldOfViewInDegreesY)/2.0 );
	GLfloat bottom	= -top;
	
	GLfloat left	= bottom * aspectRatioWidthOverHeight;
	GLfloat right	=    top * aspectRatioWidthOverHeight;
		
	// column 1
	m_projection[_11] = (2.0 * near) / (right - left);
	m_projection[_12] = 0.0;
	m_projection[_13] = 0.0;
	m_projection[_14] = 0.0;
	
	// column 2
	m_projection[_21] = 0.0;
	m_projection[_22] = (2.0 * near)/(top - bottom);
	m_projection[_23] = 0.0;
	m_projection[_24] = 0.0;
	
	// column 3
	m_projection[_31] = (right + left)/(right - left);
	m_projection[_32] = (top + bottom)/(top - bottom);
	m_projection[_33] = -(far + near)/(far - near);
	m_projection[_34] = -1.0;
	
	// column 4
	m_projection[_41] = 0.0;
	m_projection[_42] = 0.0;
	m_projection[_43] = -(2.0 * far * near)/(far - near);
	m_projection[_44] = 0.0;
	
}

- (void)orthographicProjectionLeft:(GLfloat)left 
							 right:(GLfloat)right 
							   top:(GLfloat)top 
							bottom:(GLfloat)bottom 
							  near:(GLfloat)near 
							   far:(GLfloat)far {

	
	GLfloat a =  2.0f / (right - left);
	GLfloat b =  2.0f / (  top - bottom);
	GLfloat c = -2.0f / (  far - near);
	
	GLfloat tx = -(right + left  ) / (right - left);
	GLfloat ty = -(  top + bottom) / (  top - bottom);
	GLfloat tz = -(  far + near  ) / (  far - near);
	
	
	// column 1
	m_projection[_11] = a;
	m_projection[_12] = 0.0;
	m_projection[_13] = 0.0;
	m_projection[_14] = 0.0;
	
	// column 2
	m_projection[_21] = 0.0;
	m_projection[_22] = b;
	m_projection[_23] = 0.0;
	m_projection[_24] = 0.0;
	
	// column 3
	m_projection[_31] = 0.0;
	m_projection[_32] = 0.0;
	m_projection[_33] = c;
	m_projection[_34] = 0.0;
	
	// column 4
	m_projection[_41] = tx;
	m_projection[_42] = ty;
	m_projection[_43] = tz;
	m_projection[_44] = 1.0;
	
}

- (void) placeCameraAtLocation:(EISVector3D)location target:(EISVector3D)target up:(EISVector3D)up {
	
	// We use the Richard Paul matrix notation of n, o, a, and p 
	// for x, y, z axes of orientation and p as translation
	EISVector3D n; // x-axis
	EISVector3D o; // y-axis
	EISVector3D a; // z-axis
	EISVector3D p; // translation vector
	
	// The camera is always pointed along the -z axis. So the "a" vector = -(target - eye)
	EISVector3DSet(a, -(target[0] - location[0]), -(target[1] - location[1]), -(target[2] - location[2]));
	EISVector3DNormalize(a);
	
	// The up parameter is assumed approximate. It corresponds to the y-axis or "o" vector.
	EISVector3D o_approximate;
	EISVector3DCopy(o_approximate, up);
	EISVector3DNormalize(o_approximate);
	
	//	n = o_approximate X a
	EISVector3DCrossProduct(n, o_approximate, a);
	EISVector3DNormalize(n);
	
	// Calculate the exact up vector from the cross product
	// of the other basis vectors which are indeed orthogonal:
	//
	// o = a X n
	//
	EISVector3DCrossProduct(o, a, n);
	
	// The translation vector - location - is the eye location.
	// It is the where the camera is positioned in world space.
	// Copy it into the "p" vector
	EISVector3DCopy(p, location);
	
	// Build camera transform matrix from column vectors: n, o, a, p
	EISMatrix4x4SetIdentity(m_cameraTransform);
	MatrixElement(m_cameraTransform, 0, 0) = n[0];
	MatrixElement(m_cameraTransform, 1, 0) = n[1];
	MatrixElement(m_cameraTransform, 2, 0) = n[2];
	
	MatrixElement(m_cameraTransform, 0, 1) = o[0];
	MatrixElement(m_cameraTransform, 1, 1) = o[1];
	MatrixElement(m_cameraTransform, 2, 1) = o[2];
	
	MatrixElement(m_cameraTransform, 0, 2) = a[0];
	MatrixElement(m_cameraTransform, 1, 2) = a[1];
	MatrixElement(m_cameraTransform, 2, 2) = a[2];
	
	MatrixElement(m_cameraTransform, 0, 3) = p[0];
	MatrixElement(m_cameraTransform, 1, 3) = p[1];
	MatrixElement(m_cameraTransform, 2, 3) = p[2];
	
	// Build upper 3x3 of OpenGL style "view" transformation from transpose of camera orientation
	// This is the inversion process. Since these 3x3 matrices are orthonormal a transpose is 
	// sufficient to invert
	EISMatrix4x4SetIdentity(m_viewTransform);	
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			MatrixElement(m_viewTransform, i, j) = MatrixElement(m_cameraTransform, j, i);
		}
	}
	
	// Complete building OpenGL camera transform by inserting the translation vector
	// as described in Richard Paul.
	MatrixElement(m_viewTransform, 0, 3) = -EISVector3DDotProduct(p, n);
	MatrixElement(m_viewTransform, 1, 3) = -EISVector3DDotProduct(p, o);
	MatrixElement(m_viewTransform, 2, 3) = -EISVector3DDotProduct(p, a);
	
}

- (float *) projectionViewModelTransform {
	
	return &m_projectionViewModelTransform[0];
	
}

- (void) setProjectionViewModelTransform:(EISMatrix4x4)input {
	
	EISMatrix4x4Set(m_projectionViewModelTransform, input);
	
}

- (float *) viewModelTransform {
	
	return &m_viewModelTransform[0];
	
}

- (void) setViewModelTransform:(EISMatrix4x4)input {
	
	EISMatrix4x4Set(m_viewModelTransform, input);
	
}

- (float *) projection {
	
	return &m_projection[0];
	
}

- (void) setProjection:(EISMatrix4x4)input {
	
	EISMatrix4x4Set(m_projection, input);
	
}

- (float *) modelTransform {
	
	return &m_modelTransform[0];
	
}

- (void) setModelTransform:(EISMatrix4x4)input {
	
	EISMatrix4x4Set(m_modelTransform, input);
	
	EISMatrix4x4Inverse(m_modelTransform, m_surfaceNormalTransform);

}

- (float *) surfaceNormalTransform {
	
	return &m_surfaceNormalTransform[0];
	
}

- (float *) scaleTransform {
	
	return &m_scaleTransform[0];
	
}

- (void) setScaleTransform:(CGPoint)input {
	
	EISMatrix4x4SetScaling(m_scaleTransform, input.x, input.y, 1);
	
}

- (float *) anchoredScaleTranslation {
	
	return &m_anchoredScaleTranslation[0];
	
}

- (void) setAnchoredScaleTranslation:(CGPoint)input {
	
	EISMatrix4x4SetTranslation(       m_anchoredScaleTranslation,  input.x,  input.y, 0);
	EISMatrix4x4SetTranslation(m_inverseAnchoredScaleTranslation, -input.x, -input.y, 0);
	
}

- (float *) inverseAnchoredScaleTranslation {
	
	return &m_inverseAnchoredScaleTranslation[0];
	
}

- (float *) translationTransform {
	
	return &m_translationTransform[0];
	
}

- (void) setTranslationTransform:(CGPoint)input {
	
	EISMatrix4x4SetTranslation(m_translationTransform, input.x, input.y, 0);
}

- (float *) viewTransform {
	
	return &m_viewTransform[0];
	
}

- (void) setViewTransform:(EISMatrix4x4)input {
	
	EISMatrix4x4Set(m_viewTransform, input);
	
}

- (float *) cameraTransform {
	
	return &m_cameraTransform[0];
	
}

// From "An Introduction to Ray Tracing" edited by Andrew Glassner
// This is Eric Haines' derivation of uv using an lat/long approach
//
// Sp - north pole
// Se - vector pointing to reference point on equator
// Sn - outgoing ray from sphere origin to point of intersection on sphere
#define kEricHainesSphericalInverseMappingZero (0.0001)
+ (CGPoint) EricHainesSphericalInverseMappingSp:(EISVector3D)Sp 
											 Se:(EISVector3D)Se 
											 Sn:(EISVector3D)Sn {
	
	// obtain v	
	float phi;
	phi = EISVector3DDotProduct(Sn, Sp);
	
	if (fabsf(phi) > 1.0) {
		
		DLog(@"fabsf(phi) %.3f > 1", phi);
		
	} // if (fabsf(phi) > 1.0)
	
	phi = acosf(-1.0 * phi);
	
	float v = phi / M_PI;
	
	if (v < kEricHainesSphericalInverseMappingZero || v > (1.0 - kEricHainesSphericalInverseMappingZero)) {
		
		return CGPointMake(kEricHainesSphericalInverseMappingZero, v);
		
	} // if (...)
	
	
	
	// obtain u
	float sinPhi = sinf(phi);
	float SeDotSn = EISVector3DDotProduct(Se, Sn);
	float theta = acosf(SeDotSn / sinPhi) / (2.0 * M_PI);
	
	EISVector3D SpCrossSe;
	EISVector3DCrossProduct(SpCrossSe, Sp, Se);
	
	float SpCrossSeDotSn = EISVector3DDotProduct(SpCrossSe, Sn);
	
	if (SpCrossSeDotSn > 0.0) {
		
		return CGPointMake(theta, v);
	}
	
	return CGPointMake(1.0 - theta, v);
	
}

+ (void) echoTransform:(EISMatrix4x4)transform {
	
	DLog(@"%.3f %.3f %.3f %.3f", transform[_11], transform[_21], transform[_31], transform[_41]);
	DLog(@"%.3f %.3f %.3f %.3f", transform[_12], transform[_22], transform[_32], transform[_42]);
	DLog(@"%.3f %.3f %.3f %.3f", transform[_13], transform[_23], transform[_33], transform[_43]);
	DLog(@"%.3f %.3f %.3f %.3f", transform[_14], transform[_24], transform[_34], transform[_44]);
	DLog(@"\n");
}

@end
