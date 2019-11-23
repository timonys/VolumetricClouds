
//calculate the height depending on the z coord of the ray and the volume containignn the clouds (z is vertical in UE4)
float height = (rayPosition - renderBoundsMin.z) / (renderBoundsMax.z - renderBoundsMin.z);


float PI = 3.1415f;

//Use our adapted Beers Law to calculate light attenuation and clamp it
float clampedAttenuation = max(exp(-BeersLawLightAbsorbtion * AccumulatedDensityToLight),exp(-BeersLawLightAbsorbtion * MaxAttenuation));
float densityAlteredAttenuation = max(DensityInfluence * DensitySample,clampedAttenuation);

//Calculate the dot angle between light direction and ray direction to use in our Henyey-Greenstein function
float dotLightEyeRay = dot(normalize(LightDirection),normalize(RayDirection));

//Calculate extra in-scattering
float squaredOutEccentricity = gOut * gOut;
float HGeffectOut = ((1.0 - squaredOutEccentricity) / pow(1.0 + squaredOutEccentricity - 2.0f * gOut * dotLightEyeRay, 1.5f)) / 4 * PI;

		
//Calculate the silver lining effect seen when looking towards the sun(Henyey-Greenstein)	
float squaredInEccentricity = gIn * gIn;
float InScatteringFactor = SunIntensity * pow(saturate(dotLightEyeRay),SunExponent);
float HGeffectIn = ((1.0 - squaredInEccentricity) / pow(1.0 + squaredInEccentricity - 2.0f * gIn * dotLightEyeRay, 1.5f)) / 4 * PI;

float InOutScattering = lerp(max(HGeffectIn,InScatteringFactor),HGeffectOut,InterpolateScatteringFactor);

//Calculate ambient absorption
float ambientAbsorption = 1 - saturate(AmountAmbientOutScattering * pow(DensitySample , CustomExpression0(Parameters,HeightPercentageInCloud,0,0.3f,0.8f,1.0f)) * saturate(pow(CustomExpression0(Parameters,HeightPercentageInCloud,0,0.3f,0.8f,1.0f),0.8f)));

//assemble final lighting
float lightEnergy = densityAlteredAttenuation * InOutScattering * ambientAbsorption * LightIntensity * LightColor * Transmittance * DensitySample;

return lightEnergy;
