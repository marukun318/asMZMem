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
//    public const BUFFER_LENGTH: int = SAMPLING_RATE / 30 / 2;
//    public const BUFFER_LENGTH: int = 8192;
    public const BUFFER_LENGTH: int = 2048;

    private var sounds: Sound = null;
    private var bPlaying: Boolean = false;
    private var bPulse: int = 0;
    private var pulse_cou: int = 0;
    private var pulse_vec: int = 0;
    private var freq: int = 0;
    private var hw_freq: int = 0;

    private var buffer:Array = new Array(BUFFER_LENGTH*2); // sound buffer


    //==========================================================================
    // �R���X�g���N�^
    //==========================================================================
    public function CSoundDriver() {
      var i: int;
      
      hw_freq = SAMPLING_RATE;
      bPlaying = false;
      bPulse = 0;
      pulse_cou = 0;
      pulse_vec = 0;

      for (i=0; i<BUFFER_LENGTH * 2; i++) {
        buffer[i]=0;
      }
      sounds = new Sound();
      sounds.addEventListener(SampleDataEvent.SAMPLE_DATA, samplesCallbackHandler);
    }

    // �T�E���h�h���C�o�J�n
    public function start(): void {

      if (sounds != null) {
        sounds.play();
      }
      
    }

    // ���g���̐ݒ�
    public function setFreq(arg: int): void {
      bPlaying = true;
      freq = arg;
      pulse_vec = (arg << 16) / hw_freq * 2;
    }

    // ����
    public function stop(): void {
      bPlaying = false;
    }

    // �f�[�^�o�b�t�@�X�V
    public function update(arg: int): void {
      var sample:Number;
      var i:int;
      var a:int;
      var base: int = arg * BUFFER_LENGTH;

      a = base;
      if (!bPlaying) {
        for (i=0; i < BUFFER_LENGTH; i+=2) {
          buffer[a] = 0;
          buffer[a+1] = 0;
          a+=2;
        }
      } else {
        for (i=0; i < BUFFER_LENGTH; i+=2) {
          if ((pulse_cou += pulse_vec) & 0x10000) {
            bPulse ^= 1;
            pulse_cou &= 0x0FFFF;
          }

          sample = (bPulse == 0) ? -0.05 : 0.05;
          buffer[a] = sample;
          buffer[a+1] = sample;
          a+=2;
      }

      }

    }
    

    // �T�E���h�R�[���o�b�N
    private function samplesCallbackHandler(event:SampleDataEvent):void {
      var sp:int = event.position;
      var i:int;
      
      // �Đ���
      for (i=0; i < BUFFER_LENGTH*2; i+=2) {
        event.data.writeFloat(buffer[i]);
        event.data.writeFloat(buffer[i+1]);
      }

    }

  } // class
  
} // package