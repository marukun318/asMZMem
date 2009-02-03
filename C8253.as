/////////////////////////////////////////////////////////////////////////////
// MZ-700 Emulator "MZ-Memories" for ActionScript 3.0
// 8253 Class
//
// $Id$
// Programmed by Takeshi Maruyama (Marukun)
////////////////////////////////////////////////////////////////////////////

package {
//  import flash.display.*;
//  import flash.events.*;
  import flash.utils.*;
  
  class C8253 {
    // 定数の定義
    private const PIO_TIMER_RESO:int = 10;

    // stat
    private var st_bcd : int;
    private var st_m : int;
    private var st_rl : int;
    private var st_sc : int;
    private var st_int_mask : int;
    private var st_beep_mask : int;
    private var st_makesound : int;
    private var st_setsound : int;

    //
    private var bcd:Array = new Array(3); // BCD
    private var mode:Array = new Array(3); // MODE
    private var rl:Array = new Array(3); // RL
    private var rl_bak:Array = new Array(3); // RL Backup
    private var lat_flag:Array = new Array(3); // latch flag
    private var counter:Array = new Array(3); // Counter
    private var counter_base:Array = new Array(3); // CounterBase
    private var counter_out:Array = new Array(3); // Out
    private var counter_lat:Array = new Array(3); // Counter latch
    private var bit_hl:Array = new Array(3); // H/L

    private var snd : CSoundDriver;

    //==========================================================================
    // コンストラクタ
    //==========================================================================
    public function C8253(arg: CSoundDriver) {
      snd = arg;
      init();
    }

    //--------------------------------------------------
    // 初期化
    //--------------------------------------------------
    public function init(): void {
      var i : int;
      
      //
      for (i=0;i<3;i++) {
        bcd[i] = mode [i] = 0;
        rl[i] = rl_bak[i] = 3;
        counter_base[i] = counter[i] = counter_lat[i] = 0x0000;
        counter_out[i] = 0;
        lat_flag[i] = 0;
        bit_hl[i] = 0;
      }

      //
      st_bcd = 0;
      st_m = 0;
      st_rl = 3;
      st_sc = 0;

      st_beep_mask=1;		// サウンド(8253#0)の初期化
      st_int_mask=4;		// 割り込みの初期化

    }

    ////////////////////////////
    // 8253 control word write
    ////////////////////////////
    public function write_cw(cw:int): void {
      var i : int;

      st_bcd = cw & 1;
      st_m = (cw >> 1) & 7;
      st_rl = (cw >> 4) & 3;
      st_sc = (cw >> 6) & 3;

      //	st = &_8253_stat[_8253_dat.sc];
      i = st_sc;

      counter_out[i] = 0;         // count clr

      // カウンタ・ラッチ・オペレーション
      if (st_rl==0)
        {
          counter_lat[i] = counter[i];
          lat_flag[i] = 1;
          return;
        }

      bit_hl[i] = 0;
      lat_flag[i] = 0;
      rl[i] = st_rl;
      bcd[i] = st_bcd;
      mode[i] = st_m;
    }

    // Z80PIO割り込み用カウンタ
    public function pio_pitcount(): int {
      var  _out: int;
      var i:int = 0;

      _out = 0;

      // pio int=INT1(A4)
      // pit int=INT0(A3) or CPU INT
      if (st_makesound != 0) {											// e008 makesound=gate
        if (mode[i] != 3)	{											// 方形波の繰り返し波形じゃなかったら処理
          if (pitcount_job(i, PIO_TIMER_RESO)!=0) {
            _out = 1;
          }
        }
      }

      return _out;
    }

    //
    //
    private function pitcount_job(no:int, cou: int): int {
      var _out: int;

      _out = 0;

      switch (mode[no]) {
        /* mode 0 */
      case 0:
        if (counter[no] <= 0) {
          _out = 1;
          counter[no] = 0;
        } else {
          counter[no] -= cou;
        }
        break;

        /* mode 2 */
      case 2:
        counter[no] -= cou;
        if (counter[no]<=0)  {
          /* カウンタ初期値セット */
          counter[no] = counter_base[no];
          //			do{
          //			st->counter += (int) st->counter_base;
          //			}while (st->counter<0);
          _out = 1;                /* out pulse */
        }
        break;

      case 3:
        break;
        /* mode 4 */
      case 4:
        counter[no] -= cou;
        if (counter[no] <= 0) {
          /* カウンタ初期値セット */
          counter[no] = -1;
          _out = 1;                /* out pulse (1 time only) */
        }
        break;

      default:
        break;
      }

      counter_out[no] = _out;
      return _out;
    }

    //
    public function pit_count(): int {
      var ret:int = 0;

      // カウンタ１を進める
      if (pitcount_job(1,1)!=0) {
        // カウンタ２を進める
        ret = pitcount_job(2,1);
      }

      return ret;
    }

    //
    public function is_pit_int(): Boolean {
      var r: Boolean;
      /*
         if (_8253_stat[2].counter_out) {
           if ( _8253_dat.int_mask ) {
//             Z80_intflag |= 1;
//             Interrupt(0);
           }
         }
       */
      if (counter_out[2]!=0 && st_int_mask != 0)
        r = true;
      else
        r = false;

      return r;
    }

    /// カウンタ入力
    public function inCnt(cnt:int) :int {
      //    st = &_8253_stat[addr-0xE004];

      if (lat_flag[cnt]!=0) {
        /* カウンタラッチオペレーション */
        switch (rl[cnt]) {
        case 1:
          /* 下位８ビット呼び出し */
          lat_flag[cnt] = 0;						// counter latch opelation: off
          return (counter_lat[cnt] & 255);
        case 2:
          /* 上位８ビット呼び出し */
          lat_flag[cnt] = 0;						// counter latch opelation: off
          return (counter_lat[cnt] >> 8);
        case 3:
          /* カウンタ・ラッチ・オペレーション */
          if((bit_hl[cnt]^=1)!=0) return (counter_lat[cnt] & 255);			/* 下位 */
          else {
            lat_flag[cnt] = 0;					// counter latch opelation: off
            return (counter_lat[cnt]>>8); 	/* 上位 */
          }

        default:
          return 0x7f;
        }
      } else{
        switch (rl[cnt]) {
        case 1:
          /* 下位８ビット呼び出し */
          return (counter[cnt] & 255);
        case 2:
          /* 上位８ビット呼び出し */
          return (counter[cnt]>>8);
        case 3:
          /* 下位・上位 */
          if((bit_hl[cnt]^=1)!=0) return (counter[cnt] & 255);
          else return (counter[cnt]>>8);
//        default:
        }
      }

      return 0xff;
    }

    //
    public function outCnt(cnt: int, val: int): void {
      // カウンタに書き込み
      //		st = &_8253_stat[addr-0xE004];
      if (mode[cnt] == 0)	{       // モード０だったら、outをクリア
        counter_out[cnt] = 0;
      }
      lat_flag[cnt] = 0;						// counter latch opelation: off

      switch(rl[cnt]) {
      case 1:
        /* 下位８ビット書き込み */
        counter[cnt] = (val&0x00FF);
        counter_base[cnt] = counter[cnt];
        bit_hl[cnt]=0;
        break;

      case 2:
        /* 上位８ビット書き込み */
        counter[cnt] = (val << 8)&0xFF00;
        counter_base[cnt] = counter[cnt];
        bit_hl[cnt]=0;
        break;

      case 3:
        if (bit_hl[cnt]!=0) {
          counter[cnt] = ((counter[cnt] & 0xFF)|(val << 8))&0xFFFF;
          counter_base[cnt] = counter[cnt];
        } else {
          counter[cnt] = (val&0x00FF);
          counter_base[cnt] = counter[cnt];
        }
        bit_hl[cnt]^=1;
        break;
      }

      /* サウンド用のカウンタの場合 */
      if (cnt == 0) {
        if(bit_hl[cnt]==0) {
          play8253();
        }
      }

    }

    /// E002 out
    public function outE002(val:int):void {
      /* bit 0 - 8253 mask
       * bit 1 - cassete write data
       * bit 2 - intmsk
       * bit 3 - motor on
       */
      st_beep_mask = val & 0x01;
      st_int_mask=val & 0x04;
      play8253();
    }

    /// E003 out
    public function outE003(val:int): void {
      var i: int;

      // bit0:   1=Set / 0=Reset
      // Bit1-3: PC0-7
      i = (val >> 1) & 7;
      if ((val & 1)!=0){
        // SET
        switch (i) {
        case 0:
          st_beep_mask = 1;
          break;

        case 1:
          // Cassete
          // 1 byte: long:stop bit/ 1=long 0=short *8
          //        ts700.cmt_tstates = 0;
          break;

        case 2:
          st_int_mask = 4;
          break;
        }
      }
      else {
        // RESET
        switch (i) {
        case 0:
          st_beep_mask = 0;
          break;

          // Cassete
          // 1 byte: long:stop bit/ 1=long 0=short *8
        case 1:
          break;

        case 2:
          st_int_mask = 0;
          break;
        }
      }
      if (i==0 || i==2) {
        play8253();
      }

    }

    /// E008 out
    public function outE008(val:int): void {
      st_makesound=(val&1);
      play8253();
    }

    /////////////////////////////////////////////////////////////////
    // 8253 SOUND
    /////////////////////////////////////////////////////////////////
    private function play8253() : void {
      var freq2: int;
      var freqtmp: int;

 //     if (sound_di) {
 //       return;
 //     }

      if ((!st_beep_mask)  ){
        if (st_setsound)	{
          st_setsound = 0;
          snd.stop();
        }
        return;
      }

      // サウンドを鳴らす
      freqtmp = counter_base[0];
      if (st_makesound == 0) {
        st_setsound = 0;
        snd.stop();
      } else if (freqtmp>=0) {
        // play
        freq2 = (895000 / freqtmp);
        st_setsound = 1;
        snd.setFreq(freq2);
      } else {
        // stop
        snd.stop();
      }
    }
   
  }



}
