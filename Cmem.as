/////////////////////////////////////////////////////////////////////////////
// MZ-700 Emulator "MZ-Memories" for XNA
// Memory Class
//
// $Id$
// Programmed by Takeshi Maruyama (Marukun)
/////////////////////////////////////////////////////////////////////////////
//
package {
  import flash.utils.*;
  
  class Cmem {
    // 定数の定義
    public static const ROM_START: int = 0;			// monitor rom
    public static const VID_START: int = 0x1000;    // video ram
    public static const RAM_START: int = 0x2000;	// 64k normal ram

    private static const RAM_ALLOC_SIZE: int = (0x10000 + (12 * 1024));

    /* */
    private static const ROM1_ADDR: int = 0x0000;		/* ROM1 mz addr */
    private static const ROM2_ADDR: int = 0xE800;		/* ROM2 mz addr */

    private static const MZ1R12_SIZE: int = 0x8000;		/* MZ-1R12のサイズ(32k) */
    private static const MZ1R12_MAX: int = 	64;			/* MZ-1R12の最大装着枚数 */
    private static const MZ1R18_SIZE: int = 0x10000;		/* MZ-1R18のサイズ(64k) */

    private static const ROMFONT_SIZE: int = 4096;		/* ROMFONT SIZE  */
    private static const PCG700_SIZE: int = 2048;		/* PCG-700 SIZE  */
    private static const PCG1500_SIZE: int = 8192;		/* PCG 1BANK SIZE  */

    private static const PCG1500BUF_SIZE: int = 65536;	/* DECODED PCG-BUF SIZE */

    private static const ROM_ACCESS_WAIT: int = 1;
    private static const VRAM_ACCESS_WAIT: int = 42;

    public static const MB_ROM1: uint  = 0;
    public static const MB_RAM: uint = 1;
    public static const MB_VRAM: uint = 2;
    public static const MB_IO: uint = 3;
    public static const MB_DUMMY: uint = 5;
    // unused
    private static const MB_FONT: uint = 6;
    private static const MB_PCGB: uint = 7;
    private static const MB_PCGR: uint = 8;
    private static const MB_PCGG: uint = 9;

    //
    private static var mem: Array = new Array(RAM_ALLOC_SIZE);
    private static var bank: Array = new Array(32); // Memory Bank Controller
    private var _8253: C8253;
    // キーボード
    private static var keyports: Array = new Array(10);
    
    private var vblank: int;
    private var tempo_strobe: int;
    private var cursor_cou: int;
    
    private var pb_select: int;
    
    private var touch_vram: int;
    
    private var wait: int;

    //---------------
    // コンストラクタ
    //---------------
    public function Cmem(a:C8253) {
      _8253 = a;
      
      reset();                    // リセット
    }
    
    //--------------------------
    // メモリイメージ先頭を取得
    //--------------------------
    public function getMem():Array {
      return mem;
    }

    //--------------------------
    // bank先頭を取得
    //--------------------------
    public function getBank():Array {
      return bank;
    }

    public function setVblank(v:int):void {
      vblank = v;
      //    System.out.println("setVblank("+v+")");
    }

    public function getVblank():int {
      return vblank;
    }

    public function eorStrobe():void {
      tempo_strobe ^= 1;
      //    System.out.println("tempo_strobe("+tempo_strobe+")");
      cursor_cou++;
    }

    /**
     * Returns the wait.
     * @return int
     */
    public function getWait(): int {
      return wait;
    }

    /**
     * Clear the wait.
     * @param wait The wait to set
     */
    public function clrWait(): void {
      this.wait = 0;
    }

    // ＶＲＡＭがさわられたか
    public function isTouchVram(): int {
      var r:int = touch_vram;

      touch_vram = 0;
      
      return r;
    }

    //-----------------
    // キー状態のクリア
    //-----------------
    public function keyClear():void {
      var i:int;
      
      for (i=0; i<10; i++) {
        keyports[i] = 0xFF;
      }
    }

    //-----------------
    // キーが押下される
    //-----------------
    public function keyDown(row: int, col: int) :void {
      keyports[row] &= (~(1 << col));
    }

    //-----------------
    // キーが離される
    //-----------------
    public function keyUp(row: int, col: int): void  {
      keyports[row] |= (1 << col);
    }

    //----------
    // リセット
    //----------
    public function reset():void {
      var i: int;

      wait = 0;					// メモリウェイト値　クリア
      _8253.init();               // PIT初期化
      
      for (i=9;i>=0;i--)
        keyports[i] = 0xFF;
      
      //
      for (i=1; i>=0; i--)
        bank[i] = MB_ROM1;
      
      for (i=25; i>=2; i--)
        bank[i] = MB_RAM;
      
      for (i=27; i>=26; i--)      // 0xD000-
        bank[i] = MB_VRAM;
      
      bank[28] = MB_IO;
      
      for (i=31; i>=29; i--)      // 0xE800
        bank[i] = MB_DUMMY;
      
      // VRAM初期化
      for (i=0x03FF; i>=0; i--) {
        mem[i+VID_START] = 0x00;
        mem[i+VID_START+0x800] = 0x71;
      }

      //
      vblank = 0;
      tempo_strobe = 0;
      cursor_cou = 0;
      
      pb_select = 0;
      touch_vram = 1;
      
    }
    
    //--------------
    // メモリリード
    //--------------
    public function read(adr: int): int {
      var a: int = (adr & 0xFFFF);
      var b: uint = bank[a >> 11];
      var r: int  = 0xFF;
      
      switch (b) {
      case MB_ROM1:
        r = mem[(a & 0x0FFF) + ROM_START];
        wait += ROM_ACCESS_WAIT;
        break;
        
      case MB_RAM:
        r = mem[(a & 0xFFFF) + RAM_START];
        break;
        
      case MB_VRAM:
        r = mem[(a & 0x0FFF) + VID_START];
        wait += VRAM_ACCESS_WAIT;
        break;
        
        case MB_IO:
        r = mmio_in(a);
        break;
        
      }
      
      return r & 0xFF;
    }
    
    //--------------
    // メモリライト
    //--------------
    public function write(adr: int, dat: int):void {
      var a:int = adr & 0xFFFF;
      var b:uint = bank[a >> 11];
      
      /*
	if (dat > 255) {
	  System.out.println("wrt overflow:"+adr+","+dat);
	  int c = 1;
	}
    dat &= 0xFF;
         */

      switch (b) {
      case MB_ROM1:
        break;
        
        case MB_RAM:
        mem[a + RAM_START] = dat;
        /*
      if (a == 0x1C4F) {
 		System.out.println("wrt:1C4F,"+dat);

      }
      else
      if (a == 0x1DB4) {
 		System.out.println("wrt:1DB4,"+dat);
      }
           */
        break;

      case MB_VRAM:
        mem[(a & 0x0FFF) + VID_START] = dat;
        //      System.out.println("VRAM "+Integer.toString(dat,16)+")");
        touch_vram = 1;
        wait += VRAM_ACCESS_WAIT;
        break;
        
      case MB_IO:
        mmio_out(a, dat);
        break;
        
      }
      
    }
    
    //-----------------------------
    // メモリマップトＩ／Ｏ　入力
    //-----------------------------
    private function mmio_in(adr: int): int {
      var r: int = 0x7e;
      var a:int = adr & 0xFFFF;
      var t: int;

      switch (a) {
      case 0xE000:
        return 0xff;
        
      case 0xE001:
        // read keyboard
        return (keyports[pb_select]) & 0xFF;

      case 0xE002:
        // bit 4 - motor (on=1)
        // bit 5 - tape data
        // bit 6 - cursor blink timer
        // bit 7 - vertical blanking signal (retrace?)
        t=(((cursor_cou%25)>15) ? 0x40:0);						// カーソル点滅タイマー
        //		tmp=(((hw700.retrace^1)<<7)|(hw700.motor<<4)|tmp|0x0F);
        t = ((vblank^1) << 7)|t|0x0F;
        return t;
        
      case 0xE003:
        return 0xff;
        
        // ＰＩＴ関連
      case 0xE004:
      case 0xE005:
      case 0xE006:
        r = _8253.inCnt(a-0xE004);
        break;
        
      case 0xE007:
        break;
        
      case 0xE008:
        // 音を鳴らすためのタイミングビット生成
        return (0x7e | tempo_strobe);
      }
      
      return r;
    }
    
    //-----------------------------
    // メモリマップトＩ／Ｏ　出力
    //-----------------------------
    private function mmio_out(adr: int, dat: int): void {
      var a: int = adr & 0xFFFF;

      switch (a) {
      case 0xE000:
        // $E000
        if ((dat & 0x80)==0)
          cursor_cou = 0;	// cursor blink timer reset
        
        pb_select = (dat & 15);
        if (pb_select>9)
          pb_select=9;
        break;
        
      case 0xE001:
        break;
        
      case 0xE002:
        _8253.outE002(dat);
        break;
        
      case 0xE003:
        _8253.outE003(dat);
        break;
        
      case 0xE004:
      case 0xE005:
      case 0xE006:
        _8253.outCnt(adr-0xE004, dat);
        break;
        
      case 0xE007:
        _8253.write_cw(dat);
        break;
        
      case 0xE008:
        _8253.outE008(dat);
        break;
        
        
      }
      
    }
  }
}
