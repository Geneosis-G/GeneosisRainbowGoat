class RainbowGoat extends GGMutator;

var SoundCue rainbowSong;
var AudioComponent rainbowAC;
var bool playRainbow;
var bool oldPlayRainbow;

event Tick( float deltaTime )
{
	Super.Tick( deltaTime );

	MusicManager();
}

function MusicManager()
{
	if( rainbowAC == none || rainbowAC.IsPendingKill() )
	{
		rainbowAC = CreateAudioComponent( rainbowSong, false );
	}

	if(oldPlayRainbow != playRainbow)
	{
		StopSound(playRainbow);
		if(playRainbow)
		{
			rainbowAC.Play();
		}
		else
		{
			if(rainbowAC.IsPlaying())
			{
				rainbowAC.Stop();
			}
		}
	}
	else
	{
		if(playRainbow && !rainbowAC.IsPlaying())
		{
			rainbowAC.Play();
		}
	}

	oldPlayRainbow=playRainbow;
}

function SetPlayRainbow(bool play)
{
	if(playRainbow == play)
	{
		return;
	}

	playRainbow=play;
}

simulated function StopSound(bool stop)
{
	local GGPlayerControllerBase goatPC;
	local GGProfileSettings profile;

	goatPC=GGPlayerControllerBase( GetALocalPlayerController() );
	profile = goatPC.mProfileSettings;

	if(stop)
	{
		goatPC.SetAudioGroupVolume( 'Music', 0.f);
	}
	else
	{
		goatPC.SetAudioGroupVolume( 'Music', profile.GetMusicVolume());
	}
}

DefaultProperties
{
	rainbowSong=SoundCue'RainbowSounds.DoubleRainbowCue'

	mMutatorComponentClass=class'RainbowGoatComponent'
}