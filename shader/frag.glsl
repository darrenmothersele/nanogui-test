#version 330 core

/**
 * Raymarching Template from
 * http://raymarching.com/WebGL/WebGL_RaymarchingTemplate.htm
 */

// Raymarching Template
// Source - Raymarching.com
// Author - Gary "Shane" Warne
// eMail - mail@Raymarching.com, mail@Labyrinth.com
// Last update: 28th Aug, 2014

uniform float modulation;
uniform vec2 resolution;
uniform vec4 mouse;

out vec4 fragColor;

#define PI 3.1415926535898

const float eps = 0.005;
const int maxIterations = 128;
const float stepScale = 0.5;
const float stopThreshold = 0.005;

float sphere(in vec3 p, in vec3 centerPos, float radius) {
	return length(p-centerPos) - radius;
}

float sinusoidBumps(in vec3 p){
    return sin(p.x*16.+modulation*0.57)*cos(p.y*16.+modulation*2.17)*sin(p.z*16.-modulation*1.31) + 0.5*sin(p.x*32.+modulation*0.07)*cos(p.y*32.+modulation*2.11)*sin(p.z*32.-modulation*1.23);
}

float scene(in vec3 p) {
	return sphere(p, vec3(0., 0. , 2.), 1.) + 0.04*sinusoidBumps(p);
}

vec3 getNormal(in vec3 p) {
    float ref = scene(p);
	return normalize(vec3(
		scene(vec3(p.x+eps,p.y,p.z))-ref,
		scene(vec3(p.x,p.y+eps,p.z))-ref,
		scene(vec3(p.x,p.y,p.z+eps))-ref
	));
}

float rayMarching( vec3 origin, vec3 dir, float start, float end ) {

	float sceneDist = 1e4;
	float rayDepth = start;
	for ( int i = 0; i < maxIterations; i++ ) {

		sceneDist = scene( origin + dir * rayDepth );

		if (( sceneDist < stopThreshold ) || (rayDepth >= end)) {
		    break;
		}
		rayDepth += sceneDist * stepScale;
	}

	if ( sceneDist >= stopThreshold ) rayDepth = end;
	else rayDepth += sceneDist;

	return rayDepth;
}


void main(void) {

    vec2 aspect = vec2(resolution.x/resolution.y, 1.0);
	vec2 screenCoords = (2.0*gl_FragCoord.xy/resolution.xy - 1.0)*aspect;

	vec3 lookAt = vec3(0.,0.,0.);
	vec3 camPos = vec3(0., 0., -1.);

    // Camera setup.
    vec3 forward = normalize(lookAt-camPos);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x ));
    vec3 up = normalize(cross(forward,right));
    // FOV - Field of view.
    float FOV = 0.25;
    // ro - Ray origin
    vec3 ro = camPos;
    // rd - Ray direction
    vec3 rd = normalize(forward + FOV*screenCoords.x*right + FOV*screenCoords.y*up);

	// The screen's background color.
    vec3 bgcolor = vec3(1.,0.97,0.92)*0.15;
    float bgshade = (1.0-length(vec2(screenCoords.x/aspect.x, screenCoords.y+0.5) )*0.8);
	bgcolor *= bgshade; 


	// Ray marching.
	const float clipNear = 0.0;
	const float clipFar = 4.0;
	float dist = rayMarching(ro, rd, clipNear, clipFar );
	if ( dist >= clipFar ) {
		fragColor = vec4(bgcolor, 1.0);
	    return;
	}

	// sp - Surface position.
	vec3 sp = ro + rd*dist;
	vec3 surfNormal = getNormal(sp);

	// Lighting.
	// lp - Light position.
	vec3 lp = vec3(1.5*sin(modulation*0.5), 0.75+0.25*cos(modulation*0.5), -1.0);
	// ld - Light direction.
	vec3 ld = lp-sp;
	// lcolor - Light color.
	vec3 lcolor = vec3(1.,0.97,0.92);

	// Light falloff (attenuation)
	float len = length( ld );
	ld /= len;
	float lightAtten = min( 1.0 / ( 0.25*len*len ), 1.0 );

	vec3 ref = reflect(-ld, surfNormal);
	vec3 sceneColor = vec3(0.0);

	// The spherical object's color.
	vec3 objColor = vec3(1.0, 0.6, 0.8);
	float bumps =  sinusoidBumps(sp);
    objColor = clamp(objColor*0.8-vec3(0.4, 0.2, 0.1)*bumps, 0.0, 1.0);

	float ambient = .1;
	float specularPower = 16.0;
	float diffuse = max( 0.0, dot(surfNormal, ld) );
	float specular = max( 0.0, dot( ref, normalize(camPos-sp)) );
	specular = pow(specular, specularPower);

	sceneColor += (objColor*(diffuse*0.8+ambient)+specular*0.5)*lcolor*lightAtten;
	fragColor = vec4(clamp(sceneColor, 0.0, 1.0), 1.0);
}
