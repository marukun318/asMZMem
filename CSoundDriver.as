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
    // �R���X�g���N�^
    //==========================================================================
    public function CSoundDriver() {
      sounds = new Sound();
      sounds.addEventListener(SampleDataEvent.SAMPLE_DATA, samplesCallbackHandler);
    }

    // �T�E���h�h���C�o�J�n
    public function start(): void {

      if (sounds != null) {
        sounds.play();
      }
      
    }

    // �T�E���h�R�[���o�b�N
    private function samplesCallbackHandler(event:SampleDataEvent):void {
      var sample:Number;
      var sp:int = event.position;
      var i:int;

      // �����ɖ���
      for (i=0; i < BUFFER_LENGTH; i++) {
        sample = 0;
        event.data.writeFloat(sample);
        event.data.writeFloat(sample);
      }
      
    }

  } // class
  
} // package