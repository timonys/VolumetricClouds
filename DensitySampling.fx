

float totalDensity = 0;

//1.Sample noises and store their data--
//- Base cloud noise
//Calculating the UVW coordinates to sample from
float3 baseCloudSamplePoint = (frac(RayPosition / NoiseTiling + WindMovement));
float4 baseCloudNoise = NoiseForBaseCloud.SampleLevel(NoiseForBaseCloudSampler,baseCloudSamplePoint,0);

//-Cloud detail noise
//Calculating the UVW coordinates to sample from 
float3 detailSamplePoint = (frac(RayPosition / DetailTiling + WindMovement));
//Sample from  the detail noise volume 
float4 detailNoise = DetailNoise.SampleLevel(DetailNoiseSampler,detailSamplePoint,0);

//-WeatherMap -> R = cloud type, G = transitioning, B = Height map, A = density
//Calculating the UV coordinates to sample from-> no w cause it's a 2D texture (2D coordinate ) we need
float2 weatherMapSamplePoint = (frac(RayPosition.xy / RenderVolumeScaleFactor*1.5f + WindMovement.xy));
//Sample from weathermap 2D texture 
float4 weatherInfo = WeatherMap.SampleLevel(WeatherMapSampler,weatherMapSamplePoint,0);
float transitionFactor = weatherInfo.g;
float cloudTypeCoverage = weatherInfo.r;
float maxHeight = weatherInfo.b;
float densityFromWeather = weatherInfo.a;

//2.Build Fractal brownian motion for base cloud and detail
float baseFBM = dot(baseCloudNoise.gba,float3(0.625f,0.25f,0.125f));
float detailFBM = dot(detailNoise.gba,float3(0.625f,0.25f,0.125f));

maxHeight = saturate(maxHeight + ((Coverage - 0.5) * 2));

//NOTE: Credits to Fredrik Haggstr and Arrowhead Game Studios for example remapping values and functions
//3.Form different shaping functions(edge rounding, density depending on height,.)

float cloudProbability = max(cloudTypeCoverage,(Coverage - 0.5f) * 2.0f * transitionFactor );


//-Rounding edges
float edgeRoundingBottom = saturate(CustomExpression0(Parameters, HeightPercentageInCloud, 0, 0.02f, 0, 1));
float edgeRoundingTop = saturate(CustomExpression0(Parameters, HeightPercentageInCloud, maxHeight * 0.15f, maxHeight, 1, 0));
float edgeShaping = edgeRoundingBottom * edgeRoundingTop;




//Density depending on height->lower at bottom
float densityBottomAltering = HeightPercentageInCloud * saturate(CustomExpression0(Parameters,HeightPercentageInCloud,0,0.15f,0,1)) ;
float densityTopAltering = saturate(CustomExpression0(Parameters, HeightPercentageInCloud,0.9f,1,1,0));
float combinedDensityAltering = transitionFactor * densityBottomAltering * densityTopAltering * densityFromWeather * 2*DensityFactor;

if(AnvilAmount != 0.0f)
{
	edgeShaping = pow(edgeShaping,saturate(CustomExpression0(Parameters,HeightPercentageInCloud ,0.65f ,0.95f ,1.0f ,1 -
				AnvilAmount * Coverage)));
	combinedDensityAltering *= lerp(1,saturate(CustomExpression0(Parameters,sqrt(HeightPercentageInCloud),0.4f ,0.95f ,1.0f ,0.2f) ),AnvilAmount);
}

//4.Combining detailing and base cloud
float baseCloudForm = CustomExpression0(Parameters,baseCloudNoise.r,baseFBM - 1, 1,0,1);
float detailInfluence = 0.35f * exp(-Coverage * 0.75f) * lerp(detailFBM,1 - detailFBM,saturate(HeightPercentageInCloud * 10));

//5.Combine all the different alterations to form the final cloud
float finalCloudFormation = saturate(CustomExpression0(Parameters,baseCloudForm * edgeShaping,1 - Coverage * cloudProbability,1,0,1));
totalDensity = saturate(CustomExpression0(Parameters,finalCloudFormation,detailInfluence,1,0,1)) * combinedDensityAltering;


return totalDensity;
