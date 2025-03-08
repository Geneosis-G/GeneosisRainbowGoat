class RainbowGoatComponent extends GGMutatorComponent;

/**
 * A colour represented by the four components Hue, Saturation, Value, and Alpha.
 * H must be between 0 and 360 (degrees).
 * S must be between 0 and 1.
 * V and A are normally between 0 and 1, but may exceed that range to give bloom.
 */
struct HSVColour
{
	var() float H, S, V, A;

	structdefaultproperties
	{
		A=1.0
	}
};

var Material mAngelMaterial;
var MaterialInstanceConstant mMaterialInstanceConstant;

var GGGoat gMe;
var SkeletalMeshComponent lastMesh;
var GGMutator myMut;

var bool isColorLocked;
var bool isOnePressed;
var bool isTwoPressed;
var LinearColor lockedColor;

var bool isDoubleRainbow;
var float doubleRainbowTimer;
var array< PostProcessChain > oldPPChains;
var PostProcessChain rainbowPPChain;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer( goat, owningMutator );

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;
		InitMaterial();
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;
	local float delay;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			if(isDoubleRainbow)
			{
				delay=doubleRainbowTimer/2.f;
			}
			else
			{
				delay=doubleRainbowTimer;
			}
			gMe.SetTimer( delay, false, NameOf( SwitchDoubleRainbow ), self);
		}

		if(newKey == 'ONE' || newKey == 'XboxTypeS_LeftShoulder')
		{
			isOnePressed=true;
		}

		if(newKey == 'TWO' || newKey == 'XboxTypeS_RightShoulder')
		{
			isTwoPressed=true;
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			if(gMe.IsTimerActive(NameOf( SwitchDoubleRainbow ), self))
			{
				gMe.ClearTimer(NameOf( SwitchDoubleRainbow ), self);
			}
		}

		if(newKey == 'ONE' || newKey == 'XboxTypeS_LeftShoulder')
		{
			isOnePressed=false;
		}

		if(newKey == 'TWO' || newKey == 'XboxTypeS_RightShoulder')
		{
			isTwoPressed=false;
		}
	}
}

function InitMaterial()
{
	lastMesh=gMe.mesh;
	if(MaterialInstanceConstant(lastMesh.GetMaterial(0)) == none)
	{
		gMe.mesh.SetMaterial( 0, mAngelMaterial );
		mMaterialInstanceConstant = lastMesh.CreateAndSetMaterialInstanceConstant( 0 );
	}
}

simulated event TickMutatorComponent( float delta )
{
	local LinearColor newColor, oldColor;

	if(gMe.Mesh != lastMesh)
	{
		InitMaterial();
	}
	mMaterialInstanceConstant=MaterialInstanceConstant(lastMesh.GetMaterial(0));
	if(mMaterialInstanceConstant == none)
		return;

	if(isOnePressed && isTwoPressed)
	{
		SetColorLocked(!isColorLocked);
		isOnePressed=false;
		isTwoPressed=false;
	}

	if(isColorLocked)
	{
		newColor=lockedColor;
	}
	else
	{
		mMaterialInstanceConstant.GetVectorParameterValue( 'color', oldColor );
		newColor=IncrementColor(oldColor);
	}
	mMaterialInstanceConstant.SetVectorParameterValue( 'color', newColor );
}

/**
 * Converts an RGB colour to an HSV colour, according to the algorithm described at http://en.wikipedia.org/wiki/HSL_and_HSV
 *
 * @param RGB the colour to convert.
 * @return the HSV representation of the colour.
 */
static final function HSVColour RGBToHSV(const out LinearColor RGB)
{
	local float Max;
	local float Min;
	local float Chroma;
	local HSVColour HSV;

	Min = FMin(FMin(RGB.R, RGB.G), RGB.B);
	Max = FMax(FMax(RGB.R, RGB.G), RGB.B);
	Chroma = Max - Min;

	//If Chroma is 0, then S is 0 by definition, and H is undefined but 0 by convention.
	if(Chroma != 0)
	{
		if(RGB.R == Max)
		{
			HSV.H = (RGB.G - RGB.B) / Chroma;

			if(HSV.H < 0.0)
			{
				HSV.H += 6.0;
			}
		}
		else if(RGB.G == Max)
		{
			HSV.H = ((RGB.B - RGB.R) / Chroma) + 2.0;
		}
		else //RGB.B == Max
		{
			HSV.H = ((RGB.R - RGB.G) / Chroma) + 4.0;
		}

		HSV.H *= 60.0;
		HSV.S = Chroma / Max;
	}

	HSV.V = Max;
	HSV.A = RGB.A;

	return HSV;
}

/**
 * Converts an HSV colour to an RGB colour, according to the algorithm described at http://en.wikipedia.org/wiki/HSL_and_HSV
 *
 * @param HSV the colour to convert.
 * @return the RGB representation of the colour.
 */
static final function LinearColor HSVToRGB(const out HSVColour HSV)
{
	local float Min;
	local float Chroma;
	local float Hdash;
	local float X;
	local LinearColor RGB;

	Chroma = HSV.S * HSV.V;
	Hdash = HSV.H / 60.0;
	X = Chroma * (1.0 - Abs((Hdash % 2.0) - 1.0));

	if(Hdash < 1.0)
	{
		RGB.R = Chroma;
		RGB.G = X;
	}
	else if(Hdash < 2.0)
	{
		RGB.R = X;
		RGB.G = Chroma;
	}
	else if(Hdash < 3.0)
	{
		RGB.G = Chroma;
		RGB.B = X;
	}
	else if(Hdash < 4.0)
	{
		RGB.G= X;
		RGB.B = Chroma;
	}
	else if(Hdash < 5.0)
	{
		RGB.R = X;
		RGB.B = Chroma;
	}
	else if(Hdash < 6.0)
	{
		RGB.R = Chroma;
		RGB.B = X;
	}

	Min = HSV.V - Chroma;

	RGB.R += Min;
	RGB.G += Min;
	RGB.B += Min;
	RGB.A = HSV.A;

	return RGB;
}

function LinearColor IncrementColor(LinearColor oldColor)
{
	local HSVColour tmpHSVColor;

	tmpHSVColor=RGBToHSV(oldColor);
	tmpHSVColor.H=tmpHSVColor.H + VSize(gMe.Velocity)/1000.f;
	tmpHSVColor.S=1.f;
	tmpHSVColor.V=1.f;

	return HSVToRGB(tmpHSVColor);
}

function SetColorLocked(bool lock)
{
	if(lock == isColorLocked)
	{
		return;
	}

	isColorLocked=lock;
	if(isColorLocked)
	{
		mMaterialInstanceConstant.GetVectorParameterValue( 'color', lockedColor );
	}
}

function SwitchDoubleRainbow()
{
	isDoubleRainbow = !isDoubleRainbow;
	RainbowGoat(myMut).SetPlayRainbow(isDoubleRainbow);
	if(isDoubleRainbow)
	{
		StartDoubleRainbowEffect();
	}
	else
	{
		StopDoubleRainbowEffect();
	}
}

function StartDoubleRainbowEffect()
{
	local int i;
	local GGLocalPlayer goatPlayer;

	goatPlayer = gMe.GetLocalPlayerGoat();

	for( i = 0; i < goatPlayer.PlayerPostProcessChains.Length; ++i )
	{
		oldPPChains.AddItem( goatPlayer.PlayerPostProcessChains[ i ] );
	}

	goatPlayer.RemoveAllPostProcessingChains();

	if( goatPlayer.InsertPostProcessingChain( rainbowPPChain, 0, false ) )
	{
		goatPlayer.TouchPlayerPostProcessChain();
	}
}

function StopDoubleRainbowEffect()
{
	local int i;
	local GGLocalPlayer goatPlayer;

	goatPlayer = gMe.GetLocalPlayerGoat();
	goatPlayer.RemoveAllPostProcessingChains();

	for( i = 0; i < oldPPChains.Length; ++i )
	{
		goatPlayer.InsertPostProcessingChain( oldPPChains[ i ], -1, false );
	}
	oldPPChains.Length=0;
}

DefaultProperties
{
	mAngelMaterial=Material'goat.Materials.Goat_Mat_03'

	doubleRainbowTimer=10.f
	rainbowPPChain=PostProcessChain'PPChain.Materials.PostProcessChain'
}