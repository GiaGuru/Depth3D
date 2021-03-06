 ////----------------//
 ///**SuperDepth3D**///
 //----------------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Depth Map Based 3D post-process shader v1.9.7  																																*//
 //* For Reshade 3.0																																								*//
 //* --------------------------																																						*//
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.																								*//
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.																				*//
 //* I would also love to hear about a project you are using it with.																												*//
 //* https://creativecommons.org/licenses/by/3.0/us/																																*//
 //*																																												*//
 //* Have fun,																																										*//
 //* Jose Negrete AKA BlueSkyDefender																																				*//
 //*																																												*//
 //* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader																				*//	
 //* ---------------------------------																																				*//
 //*																																												*//
 //* Original work was based on the shader code of a CryTech 3 Dev http://www.slideshare.net/TiagoAlexSousa/secrets-of-cryengine-3-graphics-technology								*//
 //* 																																												*//
 //* AO Work was based on the shader code of a Devmaster Dev																														*//
 //* code was take from http://forum.devmaster.net/t/disk-to-disk-ssao/17414																										*//
 //* arkano22 Disk to Disk AO GLSL code adapted to be used to add more detail to the Depth Map.																						*//
 //* http://forum.devmaster.net/users/arkano22/																																		*//
 //*																																												*//
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Determines The resolution of the Depth Map. For 4k Use 1.75 or 1.5. For 1440p Use 1.5 or 1.25. For 1080p use 1. Too low of a resolution will remove too much.
#define Depth_Map_Division 1.0

// Determines The Max Depth amount.
#define Depth_Max 50

uniform int Depth_Map <
	ui_type = "combo";
	ui_items = " 0 Normal\0 1 Normal Reversed-Z\0 2 Alternate Alpha\0 3 Alternate Beta\0 4 Alternate Gamma\0 5 Special\0";
	ui_label = "Depth Map Selection";
	ui_tooltip = "linearization for the zBuffer also Depth Map One to Five.\n"
			    "Normally you want to use 1,2, or 5."
			    "DM 3 and 4 are for indoor games.";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "drag";
	ui_min = 1.0; ui_max = 100.0;
	ui_label = "Depth Map Adjustment";
	ui_tooltip = "Adjust the depth map for your games.";
> = 7.5;

uniform float Offset <
	ui_type = "drag";
	ui_min = 0; ui_max = 1.0;
	ui_label = "Offset";
	ui_tooltip = "Offset is for the Special Depth Map Only.";
> = 0.5;

uniform int Divergence <
	ui_type = "drag";
	ui_min = 1; ui_max = Depth_Max;
	ui_label = "Divergence Slider";
	ui_tooltip = "Determines the amount of Image Warping and Separation.\n" 
				 "You can override this value.";
> = 15;

uniform float ZPD <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.375;
	ui_label = "Zero Parallax Distance";
	ui_tooltip = "ZPD controls the focus distance for the screen Pop-out effect.\n"
				"For FPS Games this should be around 0.005-0.075.\n"
				"Also Controlls Auto ZPD Power.\n"
				"Default is 0.010, Zero is off.";
> = 0.010;

uniform int Auto_ZPD <
	ui_type = "combo";
	ui_items = "Off\0Inverted\0Normal\0Inverted Alt\0Normal Alt\0";
	ui_label = "Auto Zero Parallax Distance Power";
	ui_tooltip = "Auto Zero Parallax Distance Power controls the focus distance for the screen Pop-out effect automatically.\n"
				"Inverted, is if your cam is close to a object you will have less Pop-out.\n"
				"Normal, is if your cam is close to a object you will have more Pop-out.\n"
				"Power of this effect is based off ZPD setting above.\n;
				"Default is Off.";
> = 0;

uniform int Dis_Occlusion <
	ui_type = "drag";
	ui_min = 0; ui_max = 5;
	ui_label = "Disocclusion Power";
	ui_tooltip = "Occlusion masking power adjustment.\n"
				"Disocclusion starts at One.\n"
				"Default is 1";
> = 1;

uniform float Perspective <
	ui_type = "drag";
	ui_min = -100; ui_max = 100;
	ui_label = "Perspective Slider";
	ui_tooltip = "Determines the perspective point.\n" 
				 "Default is 0";
> = 0;

uniform bool Depth_Map_View <
	ui_label = "Depth Map View";
	ui_tooltip = "Display the Depth Map.";
> = false;

uniform bool Depth_Map_Flip <
	ui_label = "Depth Map Flip";
	ui_tooltip = "Flip the depth map if it is upside down.";
> = false;

uniform int WDM <
	ui_type = "combo";
	ui_items = "Weapon DM Off\0Custom WDM\0 WDM 0\0";
	ui_label = "Weapon Depth Map";
	ui_tooltip = "Pick your weapon depth map for games.";
> = 0;

uniform float3 Weapon_Adjust <
	ui_type = "drag";
	ui_min = 0; ui_max = 25.0;
	ui_label = "Weapon Adjust Depth Map";
	ui_tooltip = "Adjust weapon depth map for FPS Hand.\n"
				 "X, is FPS Hand Scale Adjustment.\n"
				 "Y, is Cutoff Point Adjustment.\n"
				 "Y, Zero is Auto.\n"
				 "Default is (X 0.250, Y 0, Z 0).";
> = float3(0.0,0.250,0.0);

uniform float Weapon_Depth <
	ui_type = "drag";
	ui_min = -100; ui_max = 100;
	ui_label = "Weapon Depth Adjustment";
	ui_tooltip = "Pushes or Pulls the FPS Hand in or out of the screen.\n" 
				 "Default is 0";
> = 0;

uniform int Custom_Sidebars <
	ui_type = "combo";
	ui_items = "Mirrored Edges\0Black Edges\0Stretched Edges\0";
	ui_label = "Edge Selection";
	ui_tooltip = "Edges selection for your screen output.";
> = 1;

uniform int Stereoscopic_Mode <
	ui_type = "combo";
	ui_items = "Side by Side\0Top and Bottom\0Line Interlaced\0Column Interlaced\0Checkerboard 3D\0Anaglyph\0";
	ui_label = "3D Display Mode";
	ui_tooltip = "Stereoscopic 3D display output selection.";
> = 0;

uniform int Scaling_Support <
	ui_type = "combo";
	ui_items = " 2160p\0 Native\0 1080p A\0 1080p B\0 1050p A\0 1050p B\0 720p A\0 720p B\0";
	ui_label = "Scaling Support";
	ui_tooltip = "Dynamic Super Resolution , Virtual Super Resolution, downscaling, or Upscaling support for Line Interlaced, Column Interlaced, & Checkerboard 3D displays.";
> = 1;

uniform int Anaglyph_Colors <
	ui_type = "combo";
	ui_items = "Red/Cyan\0Dubois Red/Cyan\0Green/Magenta\0Dubois Green/Magenta\0";
	ui_label = "Anaglyph Color Mode";
	ui_tooltip = "Select colors for your 3D anaglyph glasses.";
> = 0;

uniform float Anaglyph_Desaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Anaglyph Desaturation";
	ui_tooltip = "Adjust anaglyph desaturation, Zero is Black & White, One is full color.";
> = 1.0;

uniform int Mode <
	ui_type = "combo";
	ui_items = "Normal\0Over Sample\0Tight\0";
	ui_label = "Sample Mode Selection";
	ui_tooltip = "Use this to hide artifacts.";
> = 0;

uniform bool Eye_Swap <
	ui_label = "Swap Eyes";
	ui_tooltip = "L/R to R/L.";
> = false;

uniform float Cross_Cursor_Size <
	ui_type = "drag";
	ui_min = 1; ui_max = 100;
	ui_label = "Cross Cursor Size";
	ui_tooltip = "Pick your size of the cross cursor.\n" 
				 "Default is 25";
> = 25.0;

uniform float3 Cross_Cursor_Color <
	ui_type = "color";
	ui_label = "Cross Cursor Color";
	ui_tooltip = "Pick your own cross cursor color.\n" 
				 "Default is (R 255, G 255, B 255)";
> = float3(1.0, 1.0, 1.0);

uniform bool InvertY <
	ui_label = "Invert Y-Axis";
	ui_tooltip = "Invert Y-Axis for the cross cursor.";
> = false;

//uniform float4 X <
//	ui_type = "drag";
//	ui_min = 0; ui_max = 1;
//	ui_label = "X";
//	ui_tooltip = "XYZW";
//> = float4(0,0,0,0);

/////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture DepthBufferTex : DEPTH;

sampler DepthBuffer 
	{ 
		Texture = DepthBufferTex; 
	};

texture BackBufferTex : COLOR;

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};

sampler BackBufferMIRROR 
	{ 
		Texture = BackBufferTex;
		AddressU = MIRROR;
		AddressV = MIRROR;
		AddressW = MIRROR;
	};

sampler BackBufferBORDER
	{ 
		Texture = BackBufferTex;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
	};

sampler BackBufferCLAMP
	{ 
		Texture = BackBufferTex;
		AddressU = CLAMP;
		AddressV = CLAMP;
		AddressW = CLAMP;
	};
	
texture texDM  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT/Depth_Map_Division; Format = RGBA32F;}; 

sampler SamplerDM
	{
		Texture = texDM;
	};
	
texture texDis  { Width = BUFFER_WIDTH/Depth_Map_Division; Height = BUFFER_HEIGHT/Depth_Map_Division; Format = RGBA32F;}; 

sampler SamplerDis
	{
		Texture = texDis;
	};

uniform float2 Mousecoords < source = "mousepoint"; > ;	
////////////////////////////////////////////////////////////////////////////////////Cross Cursor////////////////////////////////////////////////////////////////////////////////////	
float4 MouseCursor(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 Mpointer; 
	 
	if (!InvertY)
	{
		Mpointer = all(abs(Mousecoords - position.xy) < Cross_Cursor_Size) * (1 - all(abs(Mousecoords - position.xy) > Cross_Cursor_Size/(Cross_Cursor_Size/2))) ? float4(Cross_Cursor_Color, 1.0) : tex2D(BackBuffer, texcoord);//cross
	}
	else
	{
		Mpointer = all(abs(float2(Mousecoords.x,BUFFER_HEIGHT-Mousecoords.y) - position.xy) < Cross_Cursor_Size) * (1 - all(abs(float2(Mousecoords.x,BUFFER_HEIGHT-Mousecoords.y) - position.xy) > Cross_Cursor_Size/(Cross_Cursor_Size/2))) ? float4(Cross_Cursor_Color, 1.0) : tex2D(BackBuffer, texcoord);//cross
	}
	
	return Mpointer;
}


/////////////////////////////////////////////////////////////////////////////////Adapted Luminance/////////////////////////////////////////////////////////////////////////////////
texture texLum {Width = 256/2; Height = 256/2; Format = RGBA8; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1 
																				
sampler SamplerLum																
	{
		Texture = texLum;
		MipLODBias = 8.0f; //Luminance adapted luminance value from 1x1 Texture Mip lvl of 8
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	
texture texLumWeapon {Width = 256/2; Height = 256/2; Format = RGBA8; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1 
																				
sampler SamplerLumWeapon																
	{
		Texture = texLumWeapon;
		MipLODBias = 8.0f; //Luminance adapted luminance value from 1x1 Texture Mip lvl of 8
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};	
	
	float Lum(in float2 texcoord : TEXCOORD0)
	{
		float Luminance = tex2Dlod(SamplerLum,float4(texcoord,0,0)).r; //Average Luminance Texture Sample 

		return Luminance;
	}
	
		float LumWeapon(in float2 texcoord : TEXCOORD0)
	{
		float Luminance = tex2Dlod(SamplerLumWeapon,float4(texcoord,0,0)).g; //Average Luminance Texture Sample 

		return Luminance;
	}
/////////////////////////////////////////////////////////////////////////////////Depth Map Information/////////////////////////////////////////////////////////////////////////////////

float2 Depth(in float2 texcoord : TEXCOORD0)
{
		if (Depth_Map_Flip)
			texcoord.y =  1 - texcoord.y;
			
		float zBuffer = tex2D(DepthBuffer, texcoord).r; //Depth Buffer

		//Conversions to linear space.....
		//Near & Far Adjustment
		float DDA = 0.125/Depth_Map_Adjust; //Division Depth Map Adjust - Near
		float DDDA = 0.00125/Depth_Map_Adjust; //Division Depth Map Adjust - Near
		float Cal = (Depth_Map_Adjust/325)+1;
		float DA = Depth_Map_Adjust*2; //Depth Map Adjust - Near
		float Mix = 0.062;
		//All 1.0f are Far Adjustment
		
		//0. Normal
		float Normal = 1.0f * DDA / (1.0f + zBuffer * (DDA - 1.0f));
		
		//1. Reverse
		float NormalReverse = 1.0f * DDA / (DDA + zBuffer * (1.0f - DDA));
		
		//2. Raw Buffer
		float Raw = pow(abs(zBuffer),DA); //Looking to replace with exp(zBuffer*DA)
		
		//3. Raw Buffer Reverse
		float RawReverse = pow(abs(zBuffer - 1.0),DA); //Looking to replace with exp(-zBuffer*DA)
		
		//4 Alternate Normal
		float AlternateOne = (1.0f * DDA / (1.0f + zBuffer * (DDA - 1.0f)))*Cal;
		
		//5. Alternate Normal Reverse
		float AlternateTwo = (1.0f * DDA / (DDA + zBuffer * (1.0f - DDA)))*Cal;
		
		//6. Alternate Special
		float AlternateThree = log(zBuffer / DDDA) / log(0.2 / DDDA);
		AlternateThree = smoothstep(1,0,AlternateThree);
		
		//7. Special Depth Map
		float Special = pow(abs(exp(zBuffer)*Offset),DA*25);
		
		float2 DM;
		
		if (Depth_Map == 0)
		{
		DM.x = lerp(Normal,Raw,Mix);
		}		
		else if (Depth_Map == 1)
		{
		DM.x = lerp(NormalReverse,RawReverse,Mix);
		}
		else if (Depth_Map == 2)
		{
		DM.x = AlternateOne;
		}
		else if (Depth_Map == 3)
		{
		DM.x = AlternateTwo;
		}
		else if (Depth_Map == 4)
		{
		DM.x = AlternateThree;
		}			
		else
		{
		DM.x = Special;
		}
		
		if (Depth_Map == 0)
		{
		DM.y = lerp(Normal,Raw,Mix);
		}		
		else if (Depth_Map == 1)
		{
		DM.y = lerp(NormalReverse,RawReverse,Mix);
		}
		else if (Depth_Map == 2)
		{
		DM.y = AlternateOne;
		}
		else if (Depth_Map == 3)
		{
		DM.y = AlternateTwo;
		}
		else if (Depth_Map == 4)
		{
		DM.y = AlternateThree;
		}	
		else
		{
		DM.y = Special;
		}
	
	return float2(DM.x,DM.y);	
}

float2 WeaponDepth(in float2 texcoord : TEXCOORD0)
{
		if (Depth_Map_Flip)
			texcoord.y =  1 - texcoord.y;
			
		float zBufferWH = tex2D(DepthBuffer, texcoord).r; //Weapon Hand Depth Buffer
		//Weapon Depth Map
		//FPS Hand Depth Maps require more precision at smaller scales to work
		float constantF = 1.0;	
		float constantN = 0.01;
		
		zBufferWH = constantF * constantN / (constantF + zBufferWH * (constantN - constantF));
 		
		//Set Weapon Depth Map settings for the section below.//
		float WA_X; //Weapon_Adjust.x
		float WA_Y; //Weapon_Adjust.y
		float CoP; //Weapon_Adjust.z
		
		if (WDM == 1)
		{
		WA_X = Weapon_Adjust.x;
		WA_Y = Weapon_Adjust.y;
		}
		
		else if (WDM == 2)
		{
		WA_X = 2.855;
		WA_Y = 0.1375;
		CoP = 0.335;
		}
		//SWDMS Done//
 		
		//Scaled Section z-Buffer
		
		if (WDM >= 1)
		{
		WA_X /= 250;
		WA_Y /= 250;
		zBufferWH = WA_Y*zBufferWH/(WA_X-zBufferWH);
		}
		
		float Adj = Weapon_Depth/375; //Push & pull weapon in or out of screen.
		zBufferWH = smoothstep(Adj,1,zBufferWH) ;//Weapon Adjust smoothstep range from Adj-1
		
		//Auto Anti Weapon Depth Map Z-Fighting is always on.
		
		float AA,AL = abs(smoothstep(0,1,LumWeapon(texcoord)*2));
		
		if(AL <= 0.003)
		{
		AA = -0.003;
		}
		else if(AL <= 0.04)
		{
		AA = 0.025;
		}
		else
		{
		AA = 0.250;
		}
		
		
		if (WDM!= 1)
		zBufferWH = lerp(zBufferWH*AL,zBufferWH,AA);
		
		if (Weapon_Adjust.z == 0) //Zero Is auto
		{
		CoP = CoP;
		}
		else	
		{
		CoP = Weapon_Adjust.z;
		}
		
		return float2(saturate(zBufferWH.r),CoP);
}

void DepthMap(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 Color : SV_Target0)
{
		float N, R, G, B, D, LDM, RDM, Cutoff, A = 1;
		
		float2 DM = Depth(texcoord);
		
		float AverageLuminance = Depth(texcoord).x;	
		
		float WD = lerp(WeaponDepth(texcoord).x,1,0.0175);
		
		float CoP = WeaponDepth(texcoord).y; //Weapon Cutoff Point
				
		float CutOFFCal = (CoP/Depth_Map_Adjust)/2; //Weapon Cutoff Calculation
		
		Cutoff = step(lerp(DM.x,DM.y,0.5),CutOFFCal);
				
		if (WDM == 0)
		{
		LDM = DM.x;
		RDM = DM.y;
		}
		else
		{
		LDM = lerp(DM.x,WD,Cutoff);
		RDM = lerp(DM.y,WD,Cutoff);
		}
		
		R = LDM;
		G = AverageLuminance;
		B = RDM;
		
	Color = float4(R,G,B,A);
}

void Average_Luminance(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0)
{
	float3 Average_Luminance = tex2D(SamplerDM,float2(texcoord.x,texcoord.y)).ggg;
	color = float4(Average_Luminance,1);
}

void  Disocclusion(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0)
{
//bilateral blur\/
float2 DM;
float B, DP =  Divergence,Disocclusion_Power;

	if(Dis_Occlusion == 1)     
		{
		Disocclusion_Power = DP/350;
		}
else if(Dis_Occlusion == 2)     
		{
		Disocclusion_Power = DP/306.25;
		}
else if(Dis_Occlusion == 3)     
		{
		Disocclusion_Power = DP/262.5;
		}
else if(Dis_Occlusion == 4)   
		{
		Disocclusion_Power = DP/175;
		}
else if(Dis_Occlusion == 5)   
		{
		Disocclusion_Power = DP/min(-250,1-tex2Dlod(SamplerDM,float4(texcoord,0,0)).b/0.002);
		}
		
 float2 dir;
 const int Con = 10;
	
	if(Dis_Occlusion >= 1) 
	{
		const float weight[Con] = {0.01,-0.01,0.02,-0.02,0.03,-0.03,0.04,-0.04,0.05,-0.05};
		
		if(Dis_Occlusion >= 1)
		{
			dir = float2(0.5,0.0);
			B = Disocclusion_Power;
		}
		
		[loop]
		for (int i = 0; i < Con; i++)
		{	
			if(Dis_Occlusion >= 1) 
			{	
				DM += tex2Dlod(SamplerDM,float4(texcoord + dir * weight[i] * B ,0,0)).rb/Con;
			}
		}
	
	}
	else
	{
		DM = tex2Dlod(SamplerDM,float4(texcoord,0,0)).rb;
	}	                          

	color = float4(DM.x,0,DM.y,1);
}

////////////////////////////////////////////////Left/Right Eye////////////////////////////////////////////////////////

float4 PS_renderLR(in float2 texcoord : TEXCOORD0)
{
	float4 color,Samp;
	float DepthL = 1, DepthR = 1, ZP, MS, P, S, Z;
	
	if(Mode == 1)
	{
	Samp = float4(0.60, 0.58, 0.75, 1.5);
	}
	else if(Mode == 2)
	{
	Samp = float4(0.60, 0.58, 0.66, 1);
	}
	else
	{
	Samp = float4(0.50, 0.58, 0.66, 1);
	}
	
	float samples[4] = {Samp.x, Samp.y, Samp.z,Samp.w};
	float2 TCL, TCR;
	
	if(!Eye_Swap) //MS is Max Separation P is Perspective Adjustment
		{	
			P = Perspective * pix.x;
			MS = Divergence * pix.x;
		}
		else
		{
			P = -Perspective * pix.x;
			MS = -Divergence * pix.x;
		}
	
	if (Stereoscopic_Mode == 0)
		{
			TCR.x = (texcoord.x*2-1) - P;
			TCL.x = (texcoord.x*2) + P;
			TCR.y = texcoord.y;
			TCL.y = texcoord.y;
		}
	else if(Stereoscopic_Mode == 1)
		{
			TCR.x = texcoord.x - P;
			TCL.x = texcoord.x + P;
			TCR.y = texcoord.y*2-1;
			TCL.y = texcoord.y*2;
		}
	else
		{
			TCR.x = texcoord.x - P;
			TCL.x = texcoord.x + P;
			TCR.y = texcoord.y;
			TCL.y = texcoord.y;
		}
	
	[loop]
	for (int j = 0; j < 4; ++j) 
	{	
		S = samples[j] * MS;
		
		float L = tex2Dlod(SamplerDis,float4(TCL.x+S, TCL.y,0,0)).r;
		float R = tex2Dlod(SamplerDis,float4(TCR.x-S, TCR.y,0,0)).b;
		
		DepthL =  min(DepthL,L);
		DepthR =  min(DepthR,R);
	}
		float Luminance; //Average Luminance Texture Sample 
		
		if (Auto_ZPD == 1)
		{
			Luminance = smoothstep(0,1,Lum(texcoord));		
		}
		else if (Auto_ZPD == 2)
		{
			Luminance = smoothstep(1,0,Lum(texcoord));
		}
		else if (Auto_ZPD == 3)
		{
			Luminance = smoothstep(0,1,Lum(texcoord)*3);		
		}
		else if (Auto_ZPD == 4)
		{
			Luminance = smoothstep(1,0,Lum(texcoord)*3);
		}
		else
		{
		Luminance = 0;
		}
		
		float AL = abs(Luminance);
		
		if(Auto_ZPD >= 1)
		{
			Z = AL*ZPD; //Auto ZDP based on the Auto Anti Weapon Depth Map Z-Fighting code.
		}
		else
		{
			Z = ZPD;
		}
		
		if(ZPD == 0 && Auto_ZPD == 0)
		{
			ZP = 1.0;
		}
		else
		{
			ZP = 0.6875;
		}
		
		Z = max(0,Z);
		
	float ParallaxL = max(-0.05,MS * (1-Z/DepthL));
	float ParallaxR = max(-0.05,MS * (1-Z/DepthR));
	
		ParallaxL = lerp(ParallaxL,DepthL * MS,ZP);
		ParallaxR = lerp(ParallaxR,DepthR * MS,ZP);
		
		float ReprojectionLeft =  ParallaxL;
		float ReprojectionRight = ParallaxR;
	
	if(!Depth_Map_View)
	{
		if(Stereoscopic_Mode == 0)
		{
			if(Custom_Sidebars == 0)
			{
			color = texcoord.x < 0.5 ? tex2D(BackBufferMIRROR, float2((texcoord.x*2 + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferMIRROR, float2((texcoord.x*2-1 - P) - ReprojectionRight, texcoord.y));
			}
			else if(Custom_Sidebars == 1)
			{
			color = texcoord.x < 0.5 ? tex2D(BackBufferBORDER, float2((texcoord.x*2 + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferBORDER, float2((texcoord.x*2-1 - P) - ReprojectionRight, texcoord.y));
			}
			else
			{
			color = texcoord.x < 0.5 ? tex2D(BackBufferCLAMP, float2((texcoord.x*2 + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferCLAMP, float2((texcoord.x*2-1 - P) - ReprojectionRight, texcoord.y));
			}
		}
		else if(Stereoscopic_Mode == 1)
		{	
			if(Custom_Sidebars == 0)
			{
			color = texcoord.y < 0.5 ? tex2D(BackBufferMIRROR, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y*2)) : tex2D(BackBufferMIRROR, float2((texcoord.x - P) - ReprojectionRight, texcoord.y*2-1));
			}
			else if(Custom_Sidebars == 1)
			{
			color = texcoord.y < 0.5 ? tex2D(BackBufferBORDER, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y*2)) : tex2D(BackBufferBORDER, float2((texcoord.x - P) - ReprojectionRight, texcoord.y*2-1));
			}
			else
			{
			color = texcoord.y < 0.5 ? tex2D(BackBufferCLAMP, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y*2)) : tex2D(BackBufferCLAMP, float2((texcoord.x - P) - ReprojectionRight, texcoord.y*2-1));
			}
		}
		else if(Stereoscopic_Mode == 2)
		{
			float gridL;
			
			if(Scaling_Support == 0)
			{
			gridL = frac(texcoord.y*(2160.0/2));
			}			
			else if(Scaling_Support == 1)
			{
			gridL = frac(texcoord.y*(BUFFER_HEIGHT/2)); //Native
			}
			else if(Scaling_Support == 2)
			{
			gridL = frac(texcoord.y*(1080.0/2));
			}
			else if(Scaling_Support == 3)
			{
			gridL = frac(texcoord.y*(1081.0/2));
			}
			else if(Scaling_Support == 4)
			{
			gridL = frac(texcoord.y*(1050.0/2));
			}
			else if(Scaling_Support == 5)
			{
			gridL = frac(texcoord.y*(1051.0/2));
			}
			
			if(Custom_Sidebars == 0)
			{
			color = gridL > 0.5 ? tex2D(BackBufferMIRROR, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) :  tex2D(BackBufferMIRROR, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
			else if(Custom_Sidebars == 1)
			{
			color = gridL > 0.5 ? tex2D(BackBufferBORDER, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferBORDER, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
			else
			{
			color = gridL > 0.5 ? tex2D(BackBufferCLAMP, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferCLAMP, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
		}
		else if(Stereoscopic_Mode == 3)
		{
			float gridC;
			
			if(Scaling_Support == 0)
			{
			gridC = frac(texcoord.x*(3840.0/2));
			}			
			else if(Scaling_Support == 1)
			{
			gridC = frac(texcoord.x*(BUFFER_WIDTH/2)); //Native
			}
			else if(Scaling_Support == 2)
			{
			gridC = frac(texcoord.x*(1920.0/2));
			}
			else if(Scaling_Support == 3)
			{
			gridC = frac(texcoord.x*(1921.0/2));
			}
			else if(Scaling_Support == 6)
			{
			gridC = frac(texcoord.x*(1280.0/2));
			}
			else if(Scaling_Support == 7)
			{
			gridC = frac(texcoord.x*(1281.0/2));
			}
			
			
			if(Custom_Sidebars == 0)
			{
			color = gridC > 0.5 ? tex2D(BackBufferMIRROR, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) :  tex2D(BackBufferMIRROR, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
			else if(Custom_Sidebars == 1)
			{
			color = gridC > 0.5 ? tex2D(BackBufferBORDER, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferBORDER, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
			else
			{
			color = gridC > 0.5 ? tex2D(BackBufferCLAMP, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferCLAMP, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
		}
		else if(Stereoscopic_Mode == 4)
		{
			float gridy;
			float gridx;

			if(Scaling_Support == 1)
			{
			gridy = floor(texcoord.y*(BUFFER_HEIGHT)); //Native
			gridx = floor(texcoord.x*(BUFFER_WIDTH)); //Native
			}
			else if(Scaling_Support == 2)
			{
			gridy = floor(texcoord.y*(1080.0));
			gridx = floor(texcoord.x*(1920.0));
			}
			else if(Scaling_Support == 3)
			{
			gridy = floor(texcoord.y*(1081.0));
			gridx = floor(texcoord.x*(1921.0));
			}
			else if(Scaling_Support == 6)
			{
			gridy = floor(texcoord.y*(720.0));
			gridx = floor(texcoord.x*(1280.0));
			}
			else if(Scaling_Support == 7)
			{
			gridy = floor(texcoord.y*(721.0));
			gridx = floor(texcoord.x*(1281.0));
			}
			
			if(Custom_Sidebars == 0)
			{
			color = (int(gridy+gridx) & 1) < 0.5 ? tex2D(BackBufferMIRROR, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) :  tex2D(BackBufferMIRROR, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
			else if(Custom_Sidebars == 1)
			{
			color = (int(gridy+gridx) & 1) < 0.5 ? tex2D(BackBufferBORDER, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferBORDER, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
			else
			{
			color = (int(gridy+gridx) & 1) < 0.5 ? tex2D(BackBufferCLAMP, float2((texcoord.x + P) + ReprojectionLeft, texcoord.y)) : tex2D(BackBufferCLAMP, float2((texcoord.x - P) - ReprojectionRight, texcoord.y));
			}
		}
		else
		{
													
				float3 HalfLM = dot(tex2D(BackBufferMIRROR,float2((texcoord.x + P) + ReprojectionLeft,texcoord.y)).rgb,float3(0.299, 0.587, 0.114));
				float3 HalfRM = dot(tex2D(BackBufferMIRROR,float2((texcoord.x - P) - ReprojectionRight,texcoord.y)).rgb,float3(0.299, 0.587, 0.114));
				float3 LM = lerp(HalfLM,tex2D(BackBufferMIRROR,float2((texcoord.x + P) + ReprojectionLeft,texcoord.y)).rgb,Anaglyph_Desaturation);  
				float3 RM = lerp(HalfRM,tex2D(BackBufferMIRROR,float2((texcoord.x - P) - ReprojectionRight,texcoord.y)).rgb,Anaglyph_Desaturation); 
				
				float3 HalfLB = dot(tex2D(BackBufferBORDER,float2((texcoord.x + P) + ReprojectionLeft,texcoord.y)).rgb,float3(0.299, 0.587, 0.114));
				float3 HalfRB = dot(tex2D(BackBufferBORDER,float2((texcoord.x - P ) - ReprojectionRight,texcoord.y)).rgb,float3(0.299, 0.587, 0.114));
				float3 LB = lerp(HalfLB,tex2D(BackBufferBORDER,float2((texcoord.x + P) + ReprojectionLeft,texcoord.y)).rgb,Anaglyph_Desaturation);  
				float3 RB = lerp(HalfRB,tex2D(BackBufferBORDER,float2((texcoord.x - P) - ReprojectionRight,texcoord.y)).rgb,Anaglyph_Desaturation); 
				
				float4 C;
				float4 CT;
				
				if(Custom_Sidebars == 0)
				{
				C = float4(LM,1);
				CT = float4(RM,1);
				}
				else
				{
				C = float4(LB,1);
				CT = float4(RB,1);
				}

				
			if (Anaglyph_Colors == 0)
			{
				float4 LeftEyecolor = float4(1.0,0.0,0.0,1.0);
				float4 RightEyecolor = float4(0.0,1.0,1.0,1.0);
				

				color =  (C*LeftEyecolor) + (CT*RightEyecolor);

			}
			else if (Anaglyph_Colors == 1)
			{
			float red = 0.437 * C.r + 0.449 * C.g + 0.164 * C.b
					- 0.011 * CT.r - 0.032 * CT.g - 0.007 * CT.b;
			
			if (red > 1) { red = 1; }   if (red < 0) { red = 0; }

			float green = -0.062 * C.r -0.062 * C.g -0.024 * C.b 
						+ 0.377 * CT.r + 0.761 * CT.g + 0.009 * CT.b;
			
			if (green > 1) { green = 1; }   if (green < 0) { green = 0; }

			float blue = -0.048 * C.r - 0.050 * C.g - 0.017 * C.b 
						-0.026 * CT.r -0.093 * CT.g + 1.234  * CT.b;
			
			if (blue > 1) { blue = 1; }   if (blue < 0) { blue = 0; }


			color = float4(red, green, blue, 0);
			}
			else if (Anaglyph_Colors == 2)
			{
				float4 LeftEyecolor = float4(0.0,1.0,0.0,1.0);
				float4 RightEyecolor = float4(1.0,0.0,1.0,1.0);
				
				color =  (C*LeftEyecolor) + (CT*RightEyecolor);
				
			}
			else
			{
				
				
			float red = -0.062 * C.r -0.158 * C.g -0.039 * C.b
					+ 0.529 * CT.r + 0.705 * CT.g + 0.024 * CT.b;
			
			if (red > 1) { red = 1; }   if (red < 0) { red = 0; }

			float green = 0.284 * C.r + 0.668 * C.g + 0.143 * C.b 
						- 0.016 * CT.r - 0.015 * CT.g + 0.065 * CT.b;
			
			if (green > 1) { green = 1; }   if (green < 0) { green = 0; }

			float blue = -0.015 * C.r -0.027 * C.g + 0.021 * C.b 
						+ 0.009 * CT.r + 0.075 * CT.g + 0.937  * CT.b;
			
			if (blue > 1) { blue = 1; }   if (blue < 0) { blue = 0; }
					
			color = float4(red, green, blue, 0);
			}
		}	
	}
		else
	{		
			float4 Top = texcoord.x < 0.5 ? Lum(float2(texcoord.x*2,texcoord.y*2)).xxxx : tex2Dlod(SamplerDM,float4(texcoord.x*2-1 , texcoord.y*2,0,0)).rrbb;
			color = texcoord.y < 0.5 ? Top : tex2Dlod(SamplerDis,float4(texcoord.x,texcoord.y*2-1,0,0)).rrrr;
	}
	float Average_Luminance = texcoord.y < 0.5 ? 0.5 : tex2D(SamplerDM,float2(texcoord.x,texcoord.y)).g;
	return float4(color.rgb,Average_Luminance);
}

void Average_Luminance_Weapon(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0)
{
	float3 Average_Luminance = PS_renderLR(float2(texcoord.x,(texcoord.y + 0.500) * 0.500 + 0.250)).www;
	color = float4(Average_Luminance,1);
}

////////////////////////////////////////////////////////Logo/////////////////////////////////////////////////////////////////////////
uniform float timer < source = "timer"; >;
float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	//#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
	float HEIGHT = BUFFER_HEIGHT/2,WIDTH = BUFFER_WIDTH/2;	
	float2 LCD,LCE,LCP,LCT,LCH,LCThree,LCDD,LCDot,LCI,LCN,LCF,LCO;
	float size = 9.5,set = BUFFER_HEIGHT/2,offset = (set/size),Shift = 50;
	float4 Color = float4(PS_renderLR(texcoord).rgb,1),Done,Website,D,E,P,T,H,Three,DD,Dot,I,N,F,O;

	if(timer <= 10000)
	{
	//DEPTH
	//D
	float offsetD = (size*offset)/(set-((size/size)+(size/size)));
	LCD = float2(-90-Shift,0); 
	float4 OneD = all(abs(LCD+float2(WIDTH,HEIGHT)-position.xy) < float2(size,size*2));
	float4 TwoD = all(abs(LCD+float2(WIDTH*offsetD,HEIGHT)-position.xy) < float2(size,size*1.5));
	D = OneD-TwoD;
	//
	
	//E
	float offs = (size*offset)/(set-(size/size)/2);
	LCE = float2(-62-Shift,0); 
	float4 OneE = all(abs(LCE+float2(WIDTH,HEIGHT)-position.xy) < float2(size,size*2));
	float4 TwoE = all(abs(LCE+float2(WIDTH*offs,HEIGHT)-position.xy) < float2(size*0.875,size*1.5));
	float4 ThreeE = all(abs(LCE+float2(WIDTH,HEIGHT)-position.xy) < float2(size,size/3));
	E = (OneE-TwoE)+ThreeE;
	//
	
	//P
	float offsetP = (size*offset)/(set-((size/size)*5));
	float offsP = (size*offset)/(set-(size/size)*-11);
	float offseP = (size*offset)/(set-((size/size)*4.25));
	LCP = float2(-37-Shift,0);
	float4 OneP = all(abs(LCP+float2(WIDTH,HEIGHT/offsetP)-position.xy) < float2(size,size*1.5));
	float4 TwoP = all(abs(LCP+float2((WIDTH)*offsetD,HEIGHT/offsetP)-position.xy) < float2(size,size));
	float4 ThreeP = all(abs(LCP+float2(WIDTH/offseP,HEIGHT/offsP)-position.xy) < float2(size*0.200,size));
	P = (OneP-TwoP)+ThreeP;
	//

	//T
	float offsetT = (size*offset)/(set-((size/size)*16.75));
	float offsetTT = (size*offset)/(set-((size/size)*1.250));
	LCT = float2(-10-Shift,0);
	float4 OneT = all(abs(LCT+float2(WIDTH,HEIGHT*offsetTT)-position.xy) < float2(size/4,size*1.875));
	float4 TwoT = all(abs(LCT+float2(WIDTH,HEIGHT/offsetT)-position.xy) < float2(size,size/4));
	T = OneT+TwoT;
	//
	
	//H
	LCH = float2(13-Shift,0);
	float4 OneH = all(abs(LCH+float2(WIDTH,HEIGHT)-position.xy) < float2(size,size*2));
	float4 TwoH = all(abs(LCH+float2(WIDTH,HEIGHT)-position.xy) < float2(size/2,size*2));
	float4 ThreeH = all(abs(LCH+float2(WIDTH,HEIGHT)-position.xy) < float2(size,size/3));
	H = (OneH-TwoH)+ThreeH;
	//
	
	//Three
	float offsThree = (size*offset)/(set-(size/size)*1.250);
	LCThree = float2(38-Shift,0);
	float4 OneThree = all(abs(LCThree+float2(WIDTH,HEIGHT)-position.xy) < float2(size,size*2));
	float4 TwoThree = all(abs(LCThree+float2(WIDTH*offsThree,HEIGHT)-position.xy) < float2(size*1.2,size*1.5));
	float4 ThreeThree = all(abs(LCThree+float2(WIDTH,HEIGHT)-position.xy) < float2(size,size/3));
	Three = (OneThree-TwoThree)+ThreeThree;
	//
	
	//DD
	float offsetDD = (size*offset)/(set-((size/size)+(size/size)));
	LCDD = float2(65-Shift,0);
	float4 OneDD = all(abs(LCDD+float2(WIDTH,HEIGHT)-position.xy) < float2(size,size*2));
	float4 TwoDD = all(abs(LCDD+float2(WIDTH*offsetDD,HEIGHT)-position.xy) < float2(size,size*1.5));
	DD = OneDD-TwoDD;
	//
	
	//Dot
	float offsetDot = (size*offset)/(set-((size/size)*16));
	LCDot = float2(85-Shift,0);	
	float4 OneDot = all(abs(LCDot+float2(WIDTH,HEIGHT*offsetDot)-position.xy) < float2(size/3,size/3.3));
	Dot = OneDot;
	//
	
	//INFO
	//I
	float offsetI = (size*offset)/(set-((size/size)*18));
	float offsetII = (size*offset)/(set-((size/size)*8));
	float offsetIII = (size*offset)/(set-((size/size)*5));
	LCI = float2(101-Shift,0);	
	float4 OneI = all(abs(LCI+float2(WIDTH,HEIGHT*offsetI)-position.xy) < float2(size,size/4));
	float4 TwoI = all(abs(LCI+float2(WIDTH,HEIGHT/offsetII)-position.xy) < float2(size,size/4));
	float4 ThreeI = all(abs(LCI+float2(WIDTH,HEIGHT*offsetIII)-position.xy) < float2(size/4,size*1.5));
	I = OneI+TwoI+ThreeI;
	//
	
	//N
	float offsetN = (size*offset)/(set-((size/size)*7));
	float offsetNN = (size*offset)/(set-((size/size)*5));
	LCN = float2(126-Shift,0);	
	float4 OneN = all(abs(LCN+float2(WIDTH,HEIGHT/offsetN)-position.xy) < float2(size,size/4));
	float4 TwoN = all(abs(LCN+float2(WIDTH*offsetNN,HEIGHT*offsetNN)-position.xy) < float2(size/5,size*1.5));
	float4 ThreeN = all(abs(LCN+float2(WIDTH/offsetNN,HEIGHT*offsetNN)-position.xy) < float2(size/5,size*1.5));
	N = OneN+TwoN+ThreeN;
	//
	
	//F
	float offsetF = (size*offset)/(set-((size/size*7)));
	float offsetFF = (size*offset)/(set-((size/size)*5));
	float offsetFFF = (size*offset)/(set-((size/size)*-7.5));
	LCF = float2(153-Shift,0);	
	float4 OneF = all(abs(LCF+float2(WIDTH,HEIGHT/offsetF)-position.xy) < float2(size,size/4));
	float4 TwoF = all(abs(LCF+float2(WIDTH/offsetFF,HEIGHT*offsetFF)-position.xy) < float2(size/5,size*1.5));
	float4 ThreeF = all(abs(LCF+float2(WIDTH,HEIGHT/offsetFFF)-position.xy) < float2(size,size/4));
	F = OneF+TwoF+ThreeF;
	//
	
	//O
	float offsetO = (size*offset)/(set-((size/size*-5)));
	LCO = float2(176-Shift,0);	
	float4 OneO = all(abs(LCO+float2(WIDTH,HEIGHT/offsetO)-position.xy) < float2(size,size*1.5));
	float4 TwoO = all(abs(LCO+float2(WIDTH,HEIGHT/offsetO)-position.xy) < float2(size/1.5,size));
	O = OneO-TwoO;
	//
	}
	
	Website = D+E+P+T+H+Three+DD+Dot+I+N+F+O ? float4(1.0,1.0,1.0,1) : Color;
	
	if(timer >= 10000)
	{
	Done = Color;
	}
	else
	{
	Done = Website;
	}

	return Done;
}

///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//

technique Cross_Cursor
{			
			pass Cursor
		{
			VertexShader = PostProcessVS;
			PixelShader = MouseCursor;
		}	
}

technique Depth3D_Reprojection
{			
			pass zbuffer
		{
			VertexShader = PostProcessVS;
			PixelShader = DepthMap;
			RenderTarget = texDM;
		}
			pass AverageLuminance
		{
			VertexShader = PostProcessVS;
			PixelShader = Average_Luminance;
			RenderTarget = texLum;
		}
			pass Disocclusion
		{
			VertexShader = PostProcessVS;
			PixelShader = Disocclusion;
			RenderTarget = texDis;
		}
			pass AverageLuminanceWeapon
		{
			VertexShader = PostProcessVS;
			PixelShader = Average_Luminance_Weapon;
			RenderTarget = texLumWeapon;
		}
			pass StereoOut
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;
		}
}
