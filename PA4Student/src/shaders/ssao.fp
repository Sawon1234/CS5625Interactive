/**
 * ssao.fp
 * 
 * Written for Cornell CS 5625 (Interactive Computer Graphics).
 * Copyright (c) 2013, Computer Science Department, Cornell University.
 * 
 * @author Sean Ryan (ser99)
 * @date 2013-03-23
 */

uniform sampler2DRect DiffuseBuffer;
uniform sampler2DRect PositionBuffer;

#define MAX_RAYS 100
uniform int NumRays;
uniform vec3 SampleRays[MAX_RAYS];
uniform float SampleRadius;

uniform mat4 ProjectionMatrix;
uniform vec2 ScreenSize;

/* Decodes a vec2 into a normalized vector See Renderer.java for more info. */
vec3 decode(vec2 v)
{
	vec3 n;
	n.z = 2.0 * dot(v.xy, v.xy) - 1.0;
	n.xy = normalize(v.xy) * sqrt(1.0 - n.z*n.z);
	return n;
}

void main()
{
	// TODO PA4: Implement SSAO. Your output color should be grayscale where white is unobscured and black is fully obscured.
	vec4 origin = texture2DRect(PositionBuffer, gl_FragCoord.xy);

	
	vec3 normal = decode(vec2(texture2DRect(DiffuseBuffer, gl_FragCoord.xy).a,
	                                   texture2DRect(PositionBuffer, gl_FragCoord.xy).a));
	vec3 rvec = vec3(0.0, 1.0, 0.0);
	vec3 tangent = normalize(rvec - normal * dot(rvec, normal));
   	vec3 bitangent = cross(normal, tangent);
   	mat3 tbn = mat3(tangent, bitangent, normal);
	float ssao = 0.0;
	float sumofdots = 0.0;
	bool isBackground = false;
	int i;
	for (i = 0; i < NumRays;i++) {
		vec3 sample = tbn * SampleRays[i];
		sample = sample * SampleRadius + origin.xyz;
		vec4 offset = vec4(sample, 1.0);
		offset = ProjectionMatrix * offset;
		offset.xyz /= offset.w;
		offset.xyz = offset.xyz * 0.5 + 0.5;
		offset.xy *= ScreenSize;
		float sampleDepth = texture2DRect(PositionBuffer, offset.xy).z;
		if (abs(sampleDepth)< 0.001) {
			isBackground = true;
			break;
		}
		ssao += (sampleDepth <= sample.z ? dot(normal,sample) : 0.0);
		sumofdots += dot(normal,sample);
	}
	ssao = (ssao / sumofdots);
	gl_FragColor = isBackground ? vec4(1.0) : vec4(ssao,ssao,ssao,1.0);
}
