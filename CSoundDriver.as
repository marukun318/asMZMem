package {
  import flash.utils.*;
  import flash.events.Event;
  import flash.events.SampleDataEvent;
  import flash.media.Sound;
  import flash.media.SoundChannel;
  import flash.media.SoundMixer;
  import flash.media.SoundTransform;

  //
  public class CSoundDriver {

    public const SAMPLING_RATE: int = 44100;
    public const BUFFER_LENGTH: int = 8192;

    private var sounds: Sound = null;

    //==========================================================================
    // コンストラクタ
    //==========================================================================
    public function CSoundDriver() {
      sounds = new Sound();
      sounds.addEventListener(SampleDataEvent.SAMPLE_DATA, samplesCallbackHandler);
    }

    // サウンドドライバ開始
    public function start(): void {

      if (sounds != null) {
        sounds.play();
      }
      
    }

    // サウンドコールバック
    private function samplesCallbackHandler(event:SampleDataEvent):void {
      var sample:Number;
      var sp:int = event.position;
      var i:int;

      // 試しに無音
      for (i=0; i < BUFFER_LENGTH; i++) {
        sample = 0;
        event.data.writeFloat(sample);
        event.data.writeFloat(sample);
      }
      
    }

  } // class
  
} // package