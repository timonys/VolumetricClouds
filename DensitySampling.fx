//UNREAL custom node

float density = 0.0f;

//calculate the height depending on the z coord of the ray and the volume containignn the clouds (z is vertical in UE4)
float height = (rayPosition - renderBoundsMin.z) / (renderBoundsMax.z - renderBoundsMin.z);


//Calculate 3D coordinate to sample from taking wind movement into account
float3 noiseCoords = (frac(rayPosition/noiseTiling + wind));
float4 densitySample = noiseTexture.SampleLevel(noiseTextureSampler, noiseCoords ,0);

//detail noise sample for added variety
float3 detailNoiseCoords= (frac(rayPosition/ detailTiling+ wind * 10));
float4 densityDetailSample = detailTexture.SampleLevel(detailTextureSampler, detailNoiseCoords, 0);

//Sample weather data(coverage,precipitation and shape) from a weathermap
float4 weatherData = weatherMap.SampleLevel(weatherMapSampler, rayPosition.xy / weatherTiling + wind.xy * 0.20f, 0);

weatherData.b = saturate(weatherData.b + ((coverage - 0.5f) * 2));

float weatherFactor = max(weatherData.r, saturate(coverage - 0.5f) * 2 * weatherData.g);

//**Remapping data to combine different cloud noises and values**
//**CREDITS to Guerilla Games and Andrew Schneider for remapping value examples**


float cloudType = saturate(CustomExpression0(Parameters, height , 0.0f, 0.07f, 0, 1)) * saturate(CustomExpression0(Parameters, height , weatherData.b * 0.2f, weatherData.b, 1, 0));

float cloudCoverageAndPrecipitation = precipitation * height  * saturate(CustomExpression0(Parameters,height , 0, 0.15f, 0, 1)) * saturate(CustomExpression0(Parameters, height , 0.9f, 1, 1, 0)) * weatherData.a * 2;

float baseFBMRemap = CustomExpression0(Parameters, densitySample.r, (densitySample.g * 0.625f + densitySample.b * 0.25f + densitySample.a * 0.125f) - 1, 1, 0, 1);

float detailFBM = densityDetailSample.r * 0.625f +  densityDetailSample.g * 0.25f +  densityDetailSample.b * 0.125f;

//Transition from whispy to billowy over height
float heightTransitionFactor = 0.35f * exp(-coverage  * 0.75f) * lerp(detailFBM , 1 - detailFBM , saturate(height * 10.0f));

float cloudWeatherInfluenced = saturate(CustomExpression0(Parameters, baseFBMRemap  * cloudType , 1 - precipitation * weatherFactor , 1, 0, 1));


density = saturate(CustomExpression0(Parameters,cloudWeatherInfluenced , heightTransitionFactor , 1, 0, 1)) * cloudCoverageAndPrecipitation;

return density;
