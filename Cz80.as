/////////////////////////////////////////////////////////////////////////////
// MZ-700 Emulator "MZ-Memories" for XNA
// Z80 Class
//
// $Id$
// Programmed by Takeshi Maruyama (Marukun)
// Original version in C++, by Toshiya Takeda
////////////////////////////////////////////////////////////////////////////

package {
  import flash.utils.*;
  
  class Cz80 {
    // Z80 フラグ
    private static const Z80_FLAG_C : int = 0x01;
    private static const Z80_FLAG_N : int = 0x02;
    private static const Z80_FLAG_P : int = 0x04;
    private static const Z80_FLAG_V : int = 0x04;
    private static const Z80_FLAG_Y : int = 0x08;
    private static const Z80_FLAG_H : int = 0x10;
    private static const Z80_FLAG_X : int = 0x20;
    private static const Z80_FLAG_Z : int = 0x40;
    private static const Z80_FLAG_S : int = 0x80;

    // タイミング系
    public static const CPU_SPEED : int = 3580000;		/* 3.580 MHz */
    private static const CPU_SPEED_BASE : int = 3580000;	/* 3.580 MHz */

    private static const PIT_CVAL : int = int(CPU_SPEED_BASE / 16000);
    private static const pit0cou_val : int = (CPU_SPEED_BASE / (895000 / 10) );			// 895kHz

    private static const VRAM_ACCESS_WAIT : int = 42;
    private static const TEMPO_TSTATES : int = int((CPU_SPEED*10)/381/2);
    private static const VBLANK_TSTATES : int = 45547;
    private static const VBLANK_IN_TSTATES : int = (59667-45547);


    // ROMエミュレート系
    private static const L_SWRK : int = 0x119D;
    private static const L_DSPXY : int = 0x1171;
    private static const L_MANG : int = 0x1173;
    private static const L_KANAF : int = 0x1170;
    private static const L_DPRNT : int = 0x1194;


    private static var irep_tmp:Array = [
      [0,0,1,0],[0,1,0,1],[1,0,1,1],[0,1,1,0]
    ];
    private static var drep_tmp:Array = [
      [0,1,0,0],[1,0,0,1],[0,0,1,0],[0,1,0,1]
    ];

    private static var mem: Cmem;      // Memoryクラス
    private static var io: Cio;        // I/Oクラス
    private static var _8253: C8253;

    //  private uint SZ[];
    private static var SZ: Array = [
      0x40,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8
      ];

    private static var SZP: Array = [
      0x44,0x00,0x00,0x04,0x00,0x04,0x04,0x00,0x08,0x0c,0x0c,0x08,0x0c,0x08,0x08,0x0c,
      0x00,0x04,0x04,0x00,0x04,0x00,0x00,0x04,0x0c,0x08,0x08,0x0c,0x08,0x0c,0x0c,0x08,
      0x20,0x24,0x24,0x20,0x24,0x20,0x20,0x24,0x2c,0x28,0x28,0x2c,0x28,0x2c,0x2c,0x28,
      0x24,0x20,0x20,0x24,0x20,0x24,0x24,0x20,0x28,0x2c,0x2c,0x28,0x2c,0x28,0x28,0x2c,
      0x00,0x04,0x04,0x00,0x04,0x00,0x00,0x04,0x0c,0x08,0x08,0x0c,0x08,0x0c,0x0c,0x08,
      0x04,0x00,0x00,0x04,0x00,0x04,0x04,0x00,0x08,0x0c,0x0c,0x08,0x0c,0x08,0x08,0x0c,
      0x24,0x20,0x20,0x24,0x20,0x24,0x24,0x20,0x28,0x2c,0x2c,0x28,0x2c,0x28,0x28,0x2c,
      0x20,0x24,0x24,0x20,0x24,0x20,0x20,0x24,0x2c,0x28,0x28,0x2c,0x28,0x2c,0x2c,0x28,
      0x80,0x84,0x84,0x80,0x84,0x80,0x80,0x84,0x8c,0x88,0x88,0x8c,0x88,0x8c,0x8c,0x88,
      0x84,0x80,0x80,0x84,0x80,0x84,0x84,0x80,0x88,0x8c,0x8c,0x88,0x8c,0x88,0x88,0x8c,
      0xa4,0xa0,0xa0,0xa4,0xa0,0xa4,0xa4,0xa0,0xa8,0xac,0xac,0xa8,0xac,0xa8,0xa8,0xac,
      0xa0,0xa4,0xa4,0xa0,0xa4,0xa0,0xa0,0xa4,0xac,0xa8,0xa8,0xac,0xa8,0xac,0xac,0xa8,
      0x84,0x80,0x80,0x84,0x80,0x84,0x84,0x80,0x88,0x8c,0x8c,0x88,0x8c,0x88,0x88,0x8c,
      0x80,0x84,0x84,0x80,0x84,0x80,0x80,0x84,0x8c,0x88,0x88,0x8c,0x88,0x8c,0x8c,0x88,
      0xa0,0xa4,0xa4,0xa0,0xa4,0xa0,0xa0,0xa4,0xac,0xa8,0xa8,0xac,0xa8,0xac,0xac,0xa8,
      0xa4,0xa0,0xa0,0xa4,0xa0,0xa4,0xa4,0xa0,0xa8,0xac,0xac,0xa8,0xac,0xa8,0xa8,0xac
      ];

    private static var SZ_BIT:Array = [
      0x44,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8
      ];

    private static var SZHV_INC: Array = [
      0x50,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x08,0x08,0x08,
      0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x28,0x28,0x28,0x28,0x28,0x28,0x28,0x28,
      0x94,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0x90,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0xb0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0xb0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0x90,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0x90,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
      0xb0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,
      0xb0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa0,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8,0xa8
      ];

    private static var SZHV_DEC: Array = [
      0x42,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x1a,
      0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x1a,
      0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x3a,
      0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x3a,
      0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x1a,
      0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x0a,0x1a,
      0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x3a,
      0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x3e,
      0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x9a,
      0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x9a,
      0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xba,
      0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xba,
      0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x9a,
      0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x82,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x8a,0x9a,
      0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xba,
      0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xa2,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xba
      ];

    private static var breg_tmp:Array = [
      0,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,
      1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,
      0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,
      0,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,
      1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,
      0,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,
      1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,
      1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1
      ];

    private static var cc_op: Array = [
      4,10, 7, 6, 4, 4, 7, 4, 4,11, 7, 6, 4, 4, 7, 4, 8,10, 7, 6, 4, 4, 7, 4,12,11, 7, 6, 4, 4, 7, 4,
      7,10,16, 6, 4, 4, 7, 4, 7,11,16, 6, 4, 4, 7, 4, 7,10,13, 6,11,11,10, 4, 7,11,13, 6, 4, 4, 7, 4,
      4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
      4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 7, 7, 7, 7, 7, 7, 4, 7, 4, 4, 4, 4, 4, 4, 7, 4,
      4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
      4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
      5,10,10,10,10,11, 7,11, 5,10,10, 0,10,17, 7,11, 5,10,10,11,10,11, 7,11, 5, 4,10,11,10, 0, 7,11,
      5,10,10,19,10,11, 7,11, 5, 4,10, 4,10, 0, 7,11, 5,10,10, 4,10,11, 7,11, 5, 6,10, 4,10, 0, 7,11
      ];
    private static var cc_cb: Array = [
      8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8,
      8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8,
      8, 8, 8, 8, 8, 8,12, 8, 8, 8, 8, 8, 8, 8,12, 8, 8, 8, 8, 8, 8, 8,12, 8, 8, 8, 8, 8, 8, 8,12, 8,
      8, 8, 8, 8, 8, 8,12, 8, 8, 8, 8, 8, 8, 8,12, 8, 8, 8, 8, 8, 8, 8,12, 8, 8, 8, 8, 8, 8, 8,12, 8,
      8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8,
      8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8,
      8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8,
      8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8, 8, 8, 8, 8, 8, 8,15, 8
      ];

    private static var cc_ed: Array = [
      8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
      8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
      12,12,15,20, 8, 8, 8, 9,12,12,15,20, 8, 8, 8, 9,12,12,15,20, 8, 8, 8, 9,12,12,15,20, 8, 8, 8, 9,
      12,12,15,20, 8, 8, 8,18,12,12,15,20, 8, 8, 8,18,12,12,15,20, 8, 8, 8, 8,12,12,15,20, 8, 8, 8, 8,
      8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
      16,16,16,16, 8, 8, 8, 8,16,16,16,16, 8, 8, 8, 8,16,16,16,16, 8, 8, 8, 8,16,16,16,16, 8, 8, 8, 8,
      8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
      8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
      ];

    private static var cc_xy: Array = [
      4, 4, 4, 4, 4, 4, 4, 4, 4,15, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,15, 4, 4, 4, 4, 4, 4,
      4,14,20,10, 9, 9, 9, 4, 4,15,20,10, 9, 9, 9, 4, 4, 4, 4, 4,23,23,19, 4, 4,15, 4, 4, 4, 4, 4, 4,
      4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4,
      9, 9, 9, 9, 9, 9,19, 9, 9, 9, 9, 9, 9, 9,19, 9,19,19,19,19,19,19, 4,19, 4, 4, 4, 4, 9, 9,19, 4,
      4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4,
      4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4, 4, 4, 4, 4, 9, 9,19, 4,
      4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
      4,14, 4,23, 4,15, 4, 4, 4, 8, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,10, 4, 4, 4, 4, 4, 4
      ];

    private static var cc_xycb: Array = [
      23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,
      23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,
      20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,
      20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,
      23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,
      23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,
      23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,
      23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23
      ];
    private static var cc_ex: Array = [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 5, 5, 0, 0, 0, 0, 5, 5, 5, 5, 0, 0, 0, 0,
      6, 0, 0, 0, 7, 0, 0, 2, 6, 0, 0, 0, 7, 0, 0, 2, 6, 0, 0, 0, 7, 0, 0, 2, 6, 0, 0, 0, 7, 0, 0, 2,
      6, 0, 0, 0, 7, 0, 0, 2, 6, 0, 0, 0, 7, 0, 0, 2, 6, 0, 0, 0, 7, 0, 0, 2, 6, 0, 0, 0, 7, 0, 0, 2
      ];

    private static var DAATable: Array = [
      0x0044,0x0100,0x0200,0x0304,0x0400,0x0504,0x0604,0x0700,0x0808,0x090c,0x1010,0x1114,0x1214,0x1310,0x1414,0x1510,
      0x1000,0x1104,0x1204,0x1300,0x1404,0x1500,0x1600,0x1704,0x180c,0x1908,0x2030,0x2134,0x2234,0x2330,0x2434,0x2530,
      0x2020,0x2124,0x2224,0x2320,0x2424,0x2520,0x2620,0x2724,0x282c,0x2928,0x3034,0x3130,0x3230,0x3334,0x3430,0x3534,
      0x3024,0x3120,0x3220,0x3324,0x3420,0x3524,0x3624,0x3720,0x3828,0x392c,0x4010,0x4114,0x4214,0x4310,0x4414,0x4510,
      0x4000,0x4104,0x4204,0x4300,0x4404,0x4500,0x4600,0x4704,0x480c,0x4908,0x5014,0x5110,0x5210,0x5314,0x5410,0x5514,
      0x5004,0x5100,0x5200,0x5304,0x5400,0x5504,0x5604,0x5700,0x5808,0x590c,0x6034,0x6130,0x6230,0x6334,0x6430,0x6534,
      0x6024,0x6120,0x6220,0x6324,0x6420,0x6524,0x6624,0x6720,0x6828,0x692c,0x7030,0x7134,0x7234,0x7330,0x7434,0x7530,
      0x7020,0x7124,0x7224,0x7320,0x7424,0x7520,0x7620,0x7724,0x782c,0x7928,0x8090,0x8194,0x8294,0x8390,0x8494,0x8590,
      0x8080,0x8184,0x8284,0x8380,0x8484,0x8580,0x8680,0x8784,0x888c,0x8988,0x9094,0x9190,0x9290,0x9394,0x9490,0x9594,
      0x9084,0x9180,0x9280,0x9384,0x9480,0x9584,0x9684,0x9780,0x9888,0x998c,0x0055,0x0111,0x0211,0x0315,0x0411,0x0515,
      0x0045,0x0101,0x0201,0x0305,0x0401,0x0505,0x0605,0x0701,0x0809,0x090d,0x1011,0x1115,0x1215,0x1311,0x1415,0x1511,
      0x1001,0x1105,0x1205,0x1301,0x1405,0x1501,0x1601,0x1705,0x180d,0x1909,0x2031,0x2135,0x2235,0x2331,0x2435,0x2531,
      0x2021,0x2125,0x2225,0x2321,0x2425,0x2521,0x2621,0x2725,0x282d,0x2929,0x3035,0x3131,0x3231,0x3335,0x3431,0x3535,
      0x3025,0x3121,0x3221,0x3325,0x3421,0x3525,0x3625,0x3721,0x3829,0x392d,0x4011,0x4115,0x4215,0x4311,0x4415,0x4511,
      0x4001,0x4105,0x4205,0x4301,0x4405,0x4501,0x4601,0x4705,0x480d,0x4909,0x5015,0x5111,0x5211,0x5315,0x5411,0x5515,
      0x5005,0x5101,0x5201,0x5305,0x5401,0x5505,0x5605,0x5701,0x5809,0x590d,0x6035,0x6131,0x6231,0x6335,0x6431,0x6535,
      0x6025,0x6121,0x6221,0x6325,0x6421,0x6525,0x6625,0x6721,0x6829,0x692d,0x7031,0x7135,0x7235,0x7331,0x7435,0x7531,
      0x7021,0x7125,0x7225,0x7321,0x7425,0x7521,0x7621,0x7725,0x782d,0x7929,0x8091,0x8195,0x8295,0x8391,0x8495,0x8591,
      0x8081,0x8185,0x8285,0x8381,0x8485,0x8581,0x8681,0x8785,0x888d,0x8989,0x9095,0x9191,0x9291,0x9395,0x9491,0x9595,
      0x9085,0x9181,0x9281,0x9385,0x9481,0x9585,0x9685,0x9781,0x9889,0x998d,0xa0b5,0xa1b1,0xa2b1,0xa3b5,0xa4b1,0xa5b5,
      0xa0a5,0xa1a1,0xa2a1,0xa3a5,0xa4a1,0xa5a5,0xa6a5,0xa7a1,0xa8a9,0xa9ad,0xb0b1,0xb1b5,0xb2b5,0xb3b1,0xb4b5,0xb5b1,
      0xb0a1,0xb1a5,0xb2a5,0xb3a1,0xb4a5,0xb5a1,0xb6a1,0xb7a5,0xb8ad,0xb9a9,0xc095,0xc191,0xc291,0xc395,0xc491,0xc595,
      0xc085,0xc181,0xc281,0xc385,0xc481,0xc585,0xc685,0xc781,0xc889,0xc98d,0xd091,0xd195,0xd295,0xd391,0xd495,0xd591,
      0xd081,0xd185,0xd285,0xd381,0xd485,0xd581,0xd681,0xd785,0xd88d,0xd989,0xe0b1,0xe1b5,0xe2b5,0xe3b1,0xe4b5,0xe5b1,
      0xe0a1,0xe1a5,0xe2a5,0xe3a1,0xe4a5,0xe5a1,0xe6a1,0xe7a5,0xe8ad,0xe9a9,0xf0b5,0xf1b1,0xf2b1,0xf3b5,0xf4b1,0xf5b5,
      0xf0a5,0xf1a1,0xf2a1,0xf3a5,0xf4a1,0xf5a5,0xf6a5,0xf7a1,0xf8a9,0xf9ad,0x0055,0x0111,0x0211,0x0315,0x0411,0x0515,
      0x0045,0x0101,0x0201,0x0305,0x0401,0x0505,0x0605,0x0701,0x0809,0x090d,0x1011,0x1115,0x1215,0x1311,0x1415,0x1511,
      0x1001,0x1105,0x1205,0x1301,0x1405,0x1501,0x1601,0x1705,0x180d,0x1909,0x2031,0x2135,0x2235,0x2331,0x2435,0x2531,
      0x2021,0x2125,0x2225,0x2321,0x2425,0x2521,0x2621,0x2725,0x282d,0x2929,0x3035,0x3131,0x3231,0x3335,0x3431,0x3535,
      0x3025,0x3121,0x3221,0x3325,0x3421,0x3525,0x3625,0x3721,0x3829,0x392d,0x4011,0x4115,0x4215,0x4311,0x4415,0x4511,
      0x4001,0x4105,0x4205,0x4301,0x4405,0x4501,0x4601,0x4705,0x480d,0x4909,0x5015,0x5111,0x5211,0x5315,0x5411,0x5515,
      0x5005,0x5101,0x5201,0x5305,0x5401,0x5505,0x5605,0x5701,0x5809,0x590d,0x6035,0x6131,0x6231,0x6335,0x6431,0x6535,
      0x0604,0x0700,0x0808,0x090c,0x0a0c,0x0b08,0x0c0c,0x0d08,0x0e08,0x0f0c,0x1010,0x1114,0x1214,0x1310,0x1414,0x1510,
      0x1600,0x1704,0x180c,0x1908,0x1a08,0x1b0c,0x1c08,0x1d0c,0x1e0c,0x1f08,0x2030,0x2134,0x2234,0x2330,0x2434,0x2530,
      0x2620,0x2724,0x282c,0x2928,0x2a28,0x2b2c,0x2c28,0x2d2c,0x2e2c,0x2f28,0x3034,0x3130,0x3230,0x3334,0x3430,0x3534,
      0x3624,0x3720,0x3828,0x392c,0x3a2c,0x3b28,0x3c2c,0x3d28,0x3e28,0x3f2c,0x4010,0x4114,0x4214,0x4310,0x4414,0x4510,
      0x4600,0x4704,0x480c,0x4908,0x4a08,0x4b0c,0x4c08,0x4d0c,0x4e0c,0x4f08,0x5014,0x5110,0x5210,0x5314,0x5410,0x5514,
      0x5604,0x5700,0x5808,0x590c,0x5a0c,0x5b08,0x5c0c,0x5d08,0x5e08,0x5f0c,0x6034,0x6130,0x6230,0x6334,0x6430,0x6534,
      0x6624,0x6720,0x6828,0x692c,0x6a2c,0x6b28,0x6c2c,0x6d28,0x6e28,0x6f2c,0x7030,0x7134,0x7234,0x7330,0x7434,0x7530,
      0x7620,0x7724,0x782c,0x7928,0x7a28,0x7b2c,0x7c28,0x7d2c,0x7e2c,0x7f28,0x8090,0x8194,0x8294,0x8390,0x8494,0x8590,
      0x8680,0x8784,0x888c,0x8988,0x8a88,0x8b8c,0x8c88,0x8d8c,0x8e8c,0x8f88,0x9094,0x9190,0x9290,0x9394,0x9490,0x9594,
      0x9684,0x9780,0x9888,0x998c,0x9a8c,0x9b88,0x9c8c,0x9d88,0x9e88,0x9f8c,0x0055,0x0111,0x0211,0x0315,0x0411,0x0515,
      0x0605,0x0701,0x0809,0x090d,0x0a0d,0x0b09,0x0c0d,0x0d09,0x0e09,0x0f0d,0x1011,0x1115,0x1215,0x1311,0x1415,0x1511,
      0x1601,0x1705,0x180d,0x1909,0x1a09,0x1b0d,0x1c09,0x1d0d,0x1e0d,0x1f09,0x2031,0x2135,0x2235,0x2331,0x2435,0x2531,
      0x2621,0x2725,0x282d,0x2929,0x2a29,0x2b2d,0x2c29,0x2d2d,0x2e2d,0x2f29,0x3035,0x3131,0x3231,0x3335,0x3431,0x3535,
      0x3625,0x3721,0x3829,0x392d,0x3a2d,0x3b29,0x3c2d,0x3d29,0x3e29,0x3f2d,0x4011,0x4115,0x4215,0x4311,0x4415,0x4511,
      0x4601,0x4705,0x480d,0x4909,0x4a09,0x4b0d,0x4c09,0x4d0d,0x4e0d,0x4f09,0x5015,0x5111,0x5211,0x5315,0x5411,0x5515,
      0x5605,0x5701,0x5809,0x590d,0x5a0d,0x5b09,0x5c0d,0x5d09,0x5e09,0x5f0d,0x6035,0x6131,0x6231,0x6335,0x6431,0x6535,
      0x6625,0x6721,0x6829,0x692d,0x6a2d,0x6b29,0x6c2d,0x6d29,0x6e29,0x6f2d,0x7031,0x7135,0x7235,0x7331,0x7435,0x7531,
      0x7621,0x7725,0x782d,0x7929,0x7a29,0x7b2d,0x7c29,0x7d2d,0x7e2d,0x7f29,0x8091,0x8195,0x8295,0x8391,0x8495,0x8591,
      0x8681,0x8785,0x888d,0x8989,0x8a89,0x8b8d,0x8c89,0x8d8d,0x8e8d,0x8f89,0x9095,0x9191,0x9291,0x9395,0x9491,0x9595,
      0x9685,0x9781,0x9889,0x998d,0x9a8d,0x9b89,0x9c8d,0x9d89,0x9e89,0x9f8d,0xa0b5,0xa1b1,0xa2b1,0xa3b5,0xa4b1,0xa5b5,
      0xa6a5,0xa7a1,0xa8a9,0xa9ad,0xaaad,0xaba9,0xacad,0xada9,0xaea9,0xafad,0xb0b1,0xb1b5,0xb2b5,0xb3b1,0xb4b5,0xb5b1,
      0xb6a1,0xb7a5,0xb8ad,0xb9a9,0xbaa9,0xbbad,0xbca9,0xbdad,0xbead,0xbfa9,0xc095,0xc191,0xc291,0xc395,0xc491,0xc595,
      0xc685,0xc781,0xc889,0xc98d,0xca8d,0xcb89,0xcc8d,0xcd89,0xce89,0xcf8d,0xd091,0xd195,0xd295,0xd391,0xd495,0xd591,
      0xd681,0xd785,0xd88d,0xd989,0xda89,0xdb8d,0xdc89,0xdd8d,0xde8d,0xdf89,0xe0b1,0xe1b5,0xe2b5,0xe3b1,0xe4b5,0xe5b1,
      0xe6a1,0xe7a5,0xe8ad,0xe9a9,0xeaa9,0xebad,0xeca9,0xedad,0xeead,0xefa9,0xf0b5,0xf1b1,0xf2b1,0xf3b5,0xf4b1,0xf5b5,
      0xf6a5,0xf7a1,0xf8a9,0xf9ad,0xfaad,0xfba9,0xfcad,0xfda9,0xfea9,0xffad,0x0055,0x0111,0x0211,0x0315,0x0411,0x0515,
      0x0605,0x0701,0x0809,0x090d,0x0a0d,0x0b09,0x0c0d,0x0d09,0x0e09,0x0f0d,0x1011,0x1115,0x1215,0x1311,0x1415,0x1511,
      0x1601,0x1705,0x180d,0x1909,0x1a09,0x1b0d,0x1c09,0x1d0d,0x1e0d,0x1f09,0x2031,0x2135,0x2235,0x2331,0x2435,0x2531,
      0x2621,0x2725,0x282d,0x2929,0x2a29,0x2b2d,0x2c29,0x2d2d,0x2e2d,0x2f29,0x3035,0x3131,0x3231,0x3335,0x3431,0x3535,
      0x3625,0x3721,0x3829,0x392d,0x3a2d,0x3b29,0x3c2d,0x3d29,0x3e29,0x3f2d,0x4011,0x4115,0x4215,0x4311,0x4415,0x4511,
      0x4601,0x4705,0x480d,0x4909,0x4a09,0x4b0d,0x4c09,0x4d0d,0x4e0d,0x4f09,0x5015,0x5111,0x5211,0x5315,0x5411,0x5515,
      0x5605,0x5701,0x5809,0x590d,0x5a0d,0x5b09,0x5c0d,0x5d09,0x5e09,0x5f0d,0x6035,0x6131,0x6231,0x6335,0x6431,0x6535,
      0x0046,0x0102,0x0202,0x0306,0x0402,0x0506,0x0606,0x0702,0x080a,0x090e,0x0402,0x0506,0x0606,0x0702,0x080a,0x090e,
      0x1002,0x1106,0x1206,0x1302,0x1406,0x1502,0x1602,0x1706,0x180e,0x190a,0x1406,0x1502,0x1602,0x1706,0x180e,0x190a,
      0x2022,0x2126,0x2226,0x2322,0x2426,0x2522,0x2622,0x2726,0x282e,0x292a,0x2426,0x2522,0x2622,0x2726,0x282e,0x292a,
      0x3026,0x3122,0x3222,0x3326,0x3422,0x3526,0x3626,0x3722,0x382a,0x392e,0x3422,0x3526,0x3626,0x3722,0x382a,0x392e,
      0x4002,0x4106,0x4206,0x4302,0x4406,0x4502,0x4602,0x4706,0x480e,0x490a,0x4406,0x4502,0x4602,0x4706,0x480e,0x490a,
      0x5006,0x5102,0x5202,0x5306,0x5402,0x5506,0x5606,0x5702,0x580a,0x590e,0x5402,0x5506,0x5606,0x5702,0x580a,0x590e,
      0x6026,0x6122,0x6222,0x6326,0x6422,0x6526,0x6626,0x6722,0x682a,0x692e,0x6422,0x6526,0x6626,0x6722,0x682a,0x692e,
      0x7022,0x7126,0x7226,0x7322,0x7426,0x7522,0x7622,0x7726,0x782e,0x792a,0x7426,0x7522,0x7622,0x7726,0x782e,0x792a,
      0x8082,0x8186,0x8286,0x8382,0x8486,0x8582,0x8682,0x8786,0x888e,0x898a,0x8486,0x8582,0x8682,0x8786,0x888e,0x898a,
      0x9086,0x9182,0x9282,0x9386,0x9482,0x9586,0x9686,0x9782,0x988a,0x998e,0x3423,0x3527,0x3627,0x3723,0x382b,0x392f,
      0x4003,0x4107,0x4207,0x4303,0x4407,0x4503,0x4603,0x4707,0x480f,0x490b,0x4407,0x4503,0x4603,0x4707,0x480f,0x490b,
      0x5007,0x5103,0x5203,0x5307,0x5403,0x5507,0x5607,0x5703,0x580b,0x590f,0x5403,0x5507,0x5607,0x5703,0x580b,0x590f,
      0x6027,0x6123,0x6223,0x6327,0x6423,0x6527,0x6627,0x6723,0x682b,0x692f,0x6423,0x6527,0x6627,0x6723,0x682b,0x692f,
      0x7023,0x7127,0x7227,0x7323,0x7427,0x7523,0x7623,0x7727,0x782f,0x792b,0x7427,0x7523,0x7623,0x7727,0x782f,0x792b,
      0x8083,0x8187,0x8287,0x8383,0x8487,0x8583,0x8683,0x8787,0x888f,0x898b,0x8487,0x8583,0x8683,0x8787,0x888f,0x898b,
      0x9087,0x9183,0x9283,0x9387,0x9483,0x9587,0x9687,0x9783,0x988b,0x998f,0x9483,0x9587,0x9687,0x9783,0x988b,0x998f,
      0xa0a7,0xa1a3,0xa2a3,0xa3a7,0xa4a3,0xa5a7,0xa6a7,0xa7a3,0xa8ab,0xa9af,0xa4a3,0xa5a7,0xa6a7,0xa7a3,0xa8ab,0xa9af,
      0xb0a3,0xb1a7,0xb2a7,0xb3a3,0xb4a7,0xb5a3,0xb6a3,0xb7a7,0xb8af,0xb9ab,0xb4a7,0xb5a3,0xb6a3,0xb7a7,0xb8af,0xb9ab,
      0xc087,0xc183,0xc283,0xc387,0xc483,0xc587,0xc687,0xc783,0xc88b,0xc98f,0xc483,0xc587,0xc687,0xc783,0xc88b,0xc98f,
      0xd083,0xd187,0xd287,0xd383,0xd487,0xd583,0xd683,0xd787,0xd88f,0xd98b,0xd487,0xd583,0xd683,0xd787,0xd88f,0xd98b,
      0xe0a3,0xe1a7,0xe2a7,0xe3a3,0xe4a7,0xe5a3,0xe6a3,0xe7a7,0xe8af,0xe9ab,0xe4a7,0xe5a3,0xe6a3,0xe7a7,0xe8af,0xe9ab,
      0xf0a7,0xf1a3,0xf2a3,0xf3a7,0xf4a3,0xf5a7,0xf6a7,0xf7a3,0xf8ab,0xf9af,0xf4a3,0xf5a7,0xf6a7,0xf7a3,0xf8ab,0xf9af,
      0x0047,0x0103,0x0203,0x0307,0x0403,0x0507,0x0607,0x0703,0x080b,0x090f,0x0403,0x0507,0x0607,0x0703,0x080b,0x090f,
      0x1003,0x1107,0x1207,0x1303,0x1407,0x1503,0x1603,0x1707,0x180f,0x190b,0x1407,0x1503,0x1603,0x1707,0x180f,0x190b,
      0x2023,0x2127,0x2227,0x2323,0x2427,0x2523,0x2623,0x2727,0x282f,0x292b,0x2427,0x2523,0x2623,0x2727,0x282f,0x292b,
      0x3027,0x3123,0x3223,0x3327,0x3423,0x3527,0x3627,0x3723,0x382b,0x392f,0x3423,0x3527,0x3627,0x3723,0x382b,0x392f,
      0x4003,0x4107,0x4207,0x4303,0x4407,0x4503,0x4603,0x4707,0x480f,0x490b,0x4407,0x4503,0x4603,0x4707,0x480f,0x490b,
      0x5007,0x5103,0x5203,0x5307,0x5403,0x5507,0x5607,0x5703,0x580b,0x590f,0x5403,0x5507,0x5607,0x5703,0x580b,0x590f,
      0x6027,0x6123,0x6223,0x6327,0x6423,0x6527,0x6627,0x6723,0x682b,0x692f,0x6423,0x6527,0x6627,0x6723,0x682b,0x692f,
      0x7023,0x7127,0x7227,0x7323,0x7427,0x7523,0x7623,0x7727,0x782f,0x792b,0x7427,0x7523,0x7623,0x7727,0x782f,0x792b,
      0x8083,0x8187,0x8287,0x8383,0x8487,0x8583,0x8683,0x8787,0x888f,0x898b,0x8487,0x8583,0x8683,0x8787,0x888f,0x898b,
      0x9087,0x9183,0x9283,0x9387,0x9483,0x9587,0x9687,0x9783,0x988b,0x998f,0x9483,0x9587,0x9687,0x9783,0x988b,0x998f,
      0xfabe,0xfbba,0xfcbe,0xfdba,0xfeba,0xffbe,0x0046,0x0102,0x0202,0x0306,0x0402,0x0506,0x0606,0x0702,0x080a,0x090e,
      0x0a1e,0x0b1a,0x0c1e,0x0d1a,0x0e1a,0x0f1e,0x1002,0x1106,0x1206,0x1302,0x1406,0x1502,0x1602,0x1706,0x180e,0x190a,
      0x1a1a,0x1b1e,0x1c1a,0x1d1e,0x1e1e,0x1f1a,0x2022,0x2126,0x2226,0x2322,0x2426,0x2522,0x2622,0x2726,0x282e,0x292a,
      0x2a3a,0x2b3e,0x2c3a,0x2d3e,0x2e3e,0x2f3a,0x3026,0x3122,0x3222,0x3326,0x3422,0x3526,0x3626,0x3722,0x382a,0x392e,
      0x3a3e,0x3b3a,0x3c3e,0x3d3a,0x3e3a,0x3f3e,0x4002,0x4106,0x4206,0x4302,0x4406,0x4502,0x4602,0x4706,0x480e,0x490a,
      0x4a1a,0x4b1e,0x4c1a,0x4d1e,0x4e1e,0x4f1a,0x5006,0x5102,0x5202,0x5306,0x5402,0x5506,0x5606,0x5702,0x580a,0x590e,
      0x5a1e,0x5b1a,0x5c1e,0x5d1a,0x5e1a,0x5f1e,0x6026,0x6122,0x6222,0x6326,0x6422,0x6526,0x6626,0x6722,0x682a,0x692e,
      0x6a3e,0x6b3a,0x6c3e,0x6d3a,0x6e3a,0x6f3e,0x7022,0x7126,0x7226,0x7322,0x7426,0x7522,0x7622,0x7726,0x782e,0x792a,
      0x7a3a,0x7b3e,0x7c3a,0x7d3e,0x7e3e,0x7f3a,0x8082,0x8186,0x8286,0x8382,0x8486,0x8582,0x8682,0x8786,0x888e,0x898a,
      0x8a9a,0x8b9e,0x8c9a,0x8d9e,0x8e9e,0x8f9a,0x9086,0x9182,0x9282,0x9386,0x3423,0x3527,0x3627,0x3723,0x382b,0x392f,
      0x3a3f,0x3b3b,0x3c3f,0x3d3b,0x3e3b,0x3f3f,0x4003,0x4107,0x4207,0x4303,0x4407,0x4503,0x4603,0x4707,0x480f,0x490b,
      0x4a1b,0x4b1f,0x4c1b,0x4d1f,0x4e1f,0x4f1b,0x5007,0x5103,0x5203,0x5307,0x5403,0x5507,0x5607,0x5703,0x580b,0x590f,
      0x5a1f,0x5b1b,0x5c1f,0x5d1b,0x5e1b,0x5f1f,0x6027,0x6123,0x6223,0x6327,0x6423,0x6527,0x6627,0x6723,0x682b,0x692f,
      0x6a3f,0x6b3b,0x6c3f,0x6d3b,0x6e3b,0x6f3f,0x7023,0x7127,0x7227,0x7323,0x7427,0x7523,0x7623,0x7727,0x782f,0x792b,
      0x7a3b,0x7b3f,0x7c3b,0x7d3f,0x7e3f,0x7f3b,0x8083,0x8187,0x8287,0x8383,0x8487,0x8583,0x8683,0x8787,0x888f,0x898b,
      0x8a9b,0x8b9f,0x8c9b,0x8d9f,0x8e9f,0x8f9b,0x9087,0x9183,0x9283,0x9387,0x9483,0x9587,0x9687,0x9783,0x988b,0x998f,
      0x9a9f,0x9b9b,0x9c9f,0x9d9b,0x9e9b,0x9f9f,0xa0a7,0xa1a3,0xa2a3,0xa3a7,0xa4a3,0xa5a7,0xa6a7,0xa7a3,0xa8ab,0xa9af,
      0xaabf,0xabbb,0xacbf,0xadbb,0xaebb,0xafbf,0xb0a3,0xb1a7,0xb2a7,0xb3a3,0xb4a7,0xb5a3,0xb6a3,0xb7a7,0xb8af,0xb9ab,
      0xbabb,0xbbbf,0xbcbb,0xbdbf,0xbebf,0xbfbb,0xc087,0xc183,0xc283,0xc387,0xc483,0xc587,0xc687,0xc783,0xc88b,0xc98f,
      0xca9f,0xcb9b,0xcc9f,0xcd9b,0xce9b,0xcf9f,0xd083,0xd187,0xd287,0xd383,0xd487,0xd583,0xd683,0xd787,0xd88f,0xd98b,
      0xda9b,0xdb9f,0xdc9b,0xdd9f,0xde9f,0xdf9b,0xe0a3,0xe1a7,0xe2a7,0xe3a3,0xe4a7,0xe5a3,0xe6a3,0xe7a7,0xe8af,0xe9ab,
      0xeabb,0xebbf,0xecbb,0xedbf,0xeebf,0xefbb,0xf0a7,0xf1a3,0xf2a3,0xf3a7,0xf4a3,0xf5a7,0xf6a7,0xf7a3,0xf8ab,0xf9af,
      0xfabf,0xfbbb,0xfcbf,0xfdbb,0xfebb,0xffbf,0x0047,0x0103,0x0203,0x0307,0x0403,0x0507,0x0607,0x0703,0x080b,0x090f,
      0x0a1f,0x0b1b,0x0c1f,0x0d1b,0x0e1b,0x0f1f,0x1003,0x1107,0x1207,0x1303,0x1407,0x1503,0x1603,0x1707,0x180f,0x190b,
      0x1a1b,0x1b1f,0x1c1b,0x1d1f,0x1e1f,0x1f1b,0x2023,0x2127,0x2227,0x2323,0x2427,0x2523,0x2623,0x2727,0x282f,0x292b,
      0x2a3b,0x2b3f,0x2c3b,0x2d3f,0x2e3f,0x2f3b,0x3027,0x3123,0x3223,0x3327,0x3423,0x3527,0x3627,0x3723,0x382b,0x392f,
      0x3a3f,0x3b3b,0x3c3f,0x3d3b,0x3e3b,0x3f3f,0x4003,0x4107,0x4207,0x4303,0x4407,0x4503,0x4603,0x4707,0x480f,0x490b,
      0x4a1b,0x4b1f,0x4c1b,0x4d1f,0x4e1f,0x4f1b,0x5007,0x5103,0x5203,0x5307,0x5403,0x5507,0x5607,0x5703,0x580b,0x590f,
      0x5a1f,0x5b1b,0x5c1f,0x5d1b,0x5e1b,0x5f1f,0x6027,0x6123,0x6223,0x6327,0x6423,0x6527,0x6627,0x6723,0x682b,0x692f,
      0x6a3f,0x6b3b,0x6c3f,0x6d3b,0x6e3b,0x6f3f,0x7023,0x7127,0x7227,0x7323,0x7427,0x7523,0x7623,0x7727,0x782f,0x792b,
      0x7a3b,0x7b3f,0x7c3b,0x7d3f,0x7e3f,0x7f3b,0x8083,0x8187,0x8287,0x8383,0x8487,0x8583,0x8683,0x8787,0x888f,0x898b,
      0x8a9b,0x8b9f,0x8c9b,0x8d9f,0x8e9f,0x8f9b,0x9087,0x9183,0x9283,0x9387,0x9483,0x9587,0x9687,0x9783,0x988b,0x998f
      ];

    //----------------
    // ASCII TO DISPLAY CODE TBL [Japanese]
    public static var asc2disp_j: Array = [
      0xF0,0xF0,0xF0,0xF3,0xF0,0xF5,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,
      0xF0,0xC1,0xC2,0xC3,0xC4,0xC5,0xC6,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,0xF0,
      0x00,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6B,0x6A,0x2F,0x2A,0x2E,0x2D,
      0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x4F,0x2C,0x51,0x2B,0x57,0x49,
      0x55,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,
      0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x52,0x59,0x54,0x50,0x45,
      0xC7,0xC8,0xC9,0xCA,0xCB,0xCC,0xCD,0xCE,0xCF,0xDF,0xE7,0xE8,0xE9,0xEA,0xEC,0xED,
      0xD0,0xD1,0xD2,0xD3,0xD4,0xD5,0xD6,0xD7,0xD8,0xD9,0xDA,0xDB,0xDC,0xDD,0xDE,0xC0,
      0x80,0xBD,0x9D,0xB1,0xB5,0xB9,0xB4,0x9E,0xB2,0xB6,0xBA,0xBE,0x9F,0xB3,0xB7,0xBB,
      0xBF,0xA3,0x85,0xA4,0xA5,0xA6,0x94,0x87,0x88,0x9C,0x82,0x98,0x84,0x92,0x90,0x83,
      0x91,0x81,0x9A,0x97,0x93,0x95,0x89,0xA1,0xAF,0x8B,0x86,0x96,0xA2,0xAB,0xAA,0x8A,
      0x8E,0xB0,0xAD,0x8D,0xA7,0xA8,0xA9,0x8F,0x8C,0xAE,0xAC,0x9B,0xA0,0x99,0xBC,0xB8,
      0x40,0x3B,0x3A,0x70,0x3C,0x71,0x5A,0x3D,0x43,0x56,0x3F,0x1E,0x4A,0x1C,0x5D,0x3E,
      0x5C,0x1F,0x5F,0x5E,0x37,0x7B,0x7F,0x36,0x7A,0x7E,0x33,0x4B,0x4C,0x1D,0x6C,0x5B,
      0x78,0x41,0x35,0x34,0x74,0x30,0x38,0x75,0x39,0x4D,0x6F,0x6E,0x32,0x77,0x76,0x72,
      0x73,0x47,0x7C,0x53,0x31,0x4E,0x6D,0x48,0x46,0x7D,0x44,0x1B,0x58,0x79,0x42,0x60
      ];


    private var _Sscount : int;          // stateカウンタ
    private var _Svcount : int;          // vsyncカウンタ

    private var _SPC : int;              // PC
    private var _SSP : int;              // SP

    //  private var _SAF : int;
    private var _A : int;
    private var _F : int;
    private var _SBC : int;
    private var _SDE : int;
    private var _SHL : int;
    private var _SIX : int;
    private var _SIY : int;

    private var _S_AF : int;
    private var _S_BC : int;
    private var _S_DE : int;
    private var _S_HL : int;

    private var _I : int;
    private var _R : int;

    private var _SIM : int;
    private var _SIFF1 : int;
    private var _SIFF2 : int;

    private var _SEA : int;

    private var _S_INTFLAG : int;

    private var tracec : int;
    private var _Stempo_tstate : int;
    private var _Stempo_tstate2 : int;
    private var _Spit_tstate : int;

    private var _Sdebug : int;

    //
    private function _SInterruptFinished() : void {
      //  	_ScntInterrupt();
      //    DoRETI();
    }

    //
    private function _SInterruptEnabled() : void {
      //  	_ScntInterrupt();
      //    _SDoIRQ();
      //    _SDoIRQ(0);
    }

    //----------------------------------
    // ステート数を数える
    //----------------------------------
    private function _Sstate_count(st: int) : void {
      var w: int = mem.getWait();

      // メモリウェイトを考慮
      if (w > 0) {
        st += w;
        mem.clrWait();
      }

      _Sscount -= st;

      // ＶＳＹＮＣ
      _Svcount += st;
      if (mem.getVblank()==0) {
        if (_Svcount >= VBLANK_TSTATES) {
          _Svcount -= VBLANK_TSTATES;
          mem.setVblank(1);
        }
      } else {
        // 垂直帰線期間
        if (_Svcount >= VBLANK_IN_TSTATES) {
          _Svcount -= VBLANK_IN_TSTATES;
          mem.setVblank(0);
        }
      }

      // テンポ生成
      _Stempo_tstate += st;
      //    if ((_Stempo_tstate - _Stempo_tstate2)>=TEMPO_TSTATES) {
      if ((_Stempo_tstate - _Stempo_tstate2)>=46982) {
        _Stempo_tstate2 = _Stempo_tstate;
        mem.eorStrobe();
      }




    }

    // Ａレジスタ取得
    private function _SgetA() : int {
      //    return (_SAF >> 8) & 0xFF;
      return _A & 0xFF;
    }

    // Ｆレジスタ取得
    private function _SgetF() : int {
      //    return _SAF & 0xFF;
      return _F & 0xFF;
    }

    // ＡＦレジスタ取得
    private function _SgetAF() : int {
      return (_A << 8) | _F;
    }

    // Ｂレジスタ取得
    private function _SgetB() : int {
      return (_SBC >> 8) & 0xFF;
    }

    // Ｃレジスタ取得
    private function _SgetC() : int {
      return _SBC & 0xFF;
    }

    // Ｄレジスタ取得
    private function _SgetD() : int {
      return (_SDE >> 8) & 0xFF;
    }

    // Ｅレジスタ取得
    private function _SgetE() : int {
      return _SDE & 0xFF;
    }

    // Ｈレジスタ取得
    private function _SgetH() : int {
      return (_SHL >> 8) & 0xFF;
    }

    // Ｌレジスタ取得
    private function _SgetL() : int {
      return _SHL & 0xFF;
    }

    // ＩＸ－Ｌレジスタ取得
    private function _SgetXL() : int {
      return _SIX & 0xFF;
    }

    // ＩＸ－Ｈレジスタ取得
    private function _SgetXH() : int {
      return (_SIX >> 8) & 0xFF;
    }

    // ＩＹ－Ｌレジスタ取得
    private function _SgetYL() : int {
      return _SIY & 0xFF;
    }

    // ＩＹ－Ｈレジスタ取得
    private function _SgetYH() : int {
      return (_SIY >> 8) & 0xFF;
    }

    // Ａレジスタ設定
    private function _SsetA(v: int) : void {
      _A = v & 0xFF;
    }

    // Ｆレジスタ設定
    private function _SsetF(v: int) : void {
      _F = v & 0xFF;
    }

    // ＡＦレジスタ設定
    private function _SsetAF(v: int) : void {
      //    return (_A << 8) | _F;
      _F = (v & 0xFF);
      _A = (v >> 8)& 0xFF;
    }

    // Ｂレジスタ設定
    private function _SsetB(v: int) : void {
      _SBC &= 0x00FF;
      _SBC |= ((v << 8) & 0xFF00);
    }

    // Ｃレジスタ設定
    private function _SsetC(v: int) : void {
      _SBC &= 0xFF00;
      _SBC |= (v & 0xFF);
    }

    // Ｄレジスタ設定
    private function _SsetD(v: int) : void {
      _SDE &= 0x00FF;
      _SDE |= ((v << 8) & 0xFF00);
    }

    // Ｅレジスタ設定
    private function _SsetE(v: int) : void {
      _SDE &= 0xFF00;
      _SDE |= (v & 0xFF);
    }

    // Ｈレジスタ設定
    private function _SsetH(v: int) : void {
      _SHL &= 0x00FF;
      _SHL |= ((v << 8) & 0xFF00);
    }

    // Ｌレジスタ設定
    private function _SsetL(v: int) : void {
      _SHL &= 0xFF00;
      _SHL |= (v & 0xFF);
    }

    // ＩＸ－Ｈレジスタ設定
    private function _SsetXH(v: int) : void {
      _SIX &= 0x00FF;
      _SIX |= ((v << 8) & 0xFF00);
    }

    // ＩＸ－Ｌレジスタ設定
    private function _SsetXL(v: int) : void {
      _SIX &= 0xFF00;
      _SIX |= (v & 0xFF);
    }

    // ＩＹ－Ｈレジスタ設定
    private function _SsetYH(v: int) : void {
      _SIY &= 0x00FF;
      _SIY |= ((v << 8) & 0xFF00);
    }

    // ＩＹ－Ｌレジスタ設定
    private function _SsetYL(v: int) : void {
      _SIY &= 0xFF00;
      _SIY |= (v & 0xFF);
    }

    // ＰＣから１バイト読み込む
    private function _SREADM_PC() : int {
      var r: int = mem.read(_SPC++);
      _SPC &= 0xFFFF;

      return r;
    }

    // 任意のアドレスから１バイト読み込む
    private function _SREADM8(adr: int) : int {
      return mem.read(adr);
    }

    // 指定アドレスからワードを読み込む
    private function _SREADM16(adr: int) : int {
      return mem.read(adr) | (mem.read(adr+1)<<8);
    }

    // バイトメモリを書き込む
    private function _SWRITEM(adr: int, val: int) : void {
      mem.write(adr, val);
    }

    // ワードメモリを書き込む
    private function _SWRITEM16(adr: int, val: int) : void {
      mem.write(adr, val & 0xFF);
      mem.write(adr+1, (val>>8)& 0xFF);
    }

    private function _SPOP() : int {
      var res: int = _SREADM16(_SSP);
      _SSP += 2;
      _SSP &= 0xFFFF;
      return res;
    }
    private function _SPUSH(val: int) : void {
      _SSP -= 2;
      _SSP &= 0xFFFF;
      _SWRITEM16(_SSP, val);
    }

    // 相対アドレス
    private function _SEAX() : void {
      //    int res = ReadMemory(_SPC++);
      var res: int = _SREADM_PC();
      _SEA = _SIX + ((res < 128) ? res : res - 256);
    }
    private function _SEAY() : void {
      //    int res = ReadMemory(_SPC++);
      var res: int = _SREADM_PC();
      _SEA = _SIY + ((res < 128) ? res : res - 256);
    }

    // オペランド
    private function _SJP_COND(cond: int, b: Boolean) : void {
      if (b) {
        // true
        if((_F & cond)!=0) {
          _SPC = _SREADM16(_SPC);
        } else {
          _SPC += 2;
        }
      } else {
        // false
        if((_F & cond)==0) {
          _SPC = _SREADM16(_SPC);
        } else {
          _SPC += 2;
        }
      }

    }
    private function _SJR() : void {
      //    int res = ReadMemory(PC++);
      var res: int = _SREADM_PC();
      _SPC += (res < 128) ? res : res - 256;
    }

    //
    private function _SJR_COND(cond: int, opcode: int, b: Boolean) : void {
      var res: int = _SREADM_PC();
      if (b) {
        // true
        if((_F & cond)!=0) {
          _SPC += (res < 128) ? res : res - 256;
          //        _Sscount -= cc_ex[opcode];
          _Sstate_count(cc_ex[opcode]);

        }

      } else {
        // false
        if((_F & cond)==0) {
          _SPC += (res < 128) ? res : res - 256;
          //        _Sscount -= cc_ex[opcode];
          _Sstate_count(cc_ex[opcode]);
        }

      }
    }
    //
    private function _SJR_COND_VALNZ(reg: int, opcode: int) : void {
      var res: int = _SREADM_PC();
      // true
      if(reg != 0) {
        _SPC += (res < 128) ? res : res - 256;
        //_Sscount -= cc_ex[opcode];
        _Sstate_count(cc_ex[opcode]);
      }
    }
    private function _SCALL() : void {
      _SEA = _SREADM16(_SPC);
      _SPC += 2;
      _SPUSH(_SPC);
      _SPC = _SEA;
    }
    private function _SCALL_COND(cond: int, opcode: int, b: Boolean) : void {
      if (b) {
        // true
        if((_F & cond)!=0) {
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SPUSH(_SPC);
          _SPC = _SEA;
          //        _Sscount -= cc_ex[opcode];
          _Sstate_count(cc_ex[opcode]);
        } else {
          _SPC += 2;
        }
      } else {
        // false
        if((_F & cond)==0) {
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SPUSH(_SPC);
          _SPC = _SEA;
          //        _Sscount -= cc_ex[opcode];
          _Sstate_count(cc_ex[opcode]);
        } else {
          _SPC += 2;
        }

      }
    }
    private function _SRET() : void {
      _SPC = _SPOP();
    }
    private function _SRET_COND(cond: int, opcode: int, b: Boolean) : void {
      if (b) {
        // true
        if((_F & cond)!=0) {
          _SPC = _SPOP();
          //        _Sscount -= cc_ex[opcode];
          _Sstate_count(cc_ex[opcode]);
        }
      } else {
        // false
        if((_F & cond)==0) {
          _SPC = _SPOP();
          //        _Sscount -= cc_ex[opcode];
          _Sstate_count(cc_ex[opcode]);
        }
      }
    }
    private function _SDI() : void {
      _SIFF1 = _SIFF2 = 0;
    }
    private function _SEI() : void {
      //    _SIFF1 = _SIFF2 = 1;
      if (_SIFF1 == 0) {
        _SIFF1 = _SIFF2 = 1;
        // 割り込みカウント処理
        _SInterruptEnabled();
        //      _ScntInterrupt();

      } else {
        _SIFF2 = 1;
      }

    }
    private function _SRST(addr: int) : void {
      _SPUSH(_SPC);
      _SPC = addr;
    }
    private function _SRETN() : void {
      _SPC = _SPOP();
      _SIFF1 = _SIFF2;
      if(_SIFF1!=0) { _SInterruptEnabled(); }
    }
    private function _SRETI() : void {
      _SPC = _SPOP();
      _SInterruptFinished();
    }

    private function _SEX_DE_HL() : void {
      var tmp: int;
      tmp = _SDE; _SDE = _SHL; _SHL = tmp;
    }
    private function _SEXX() : void {
      var tmp: int;
      tmp = _SBC; _SBC = _S_BC; _S_BC = tmp;
      tmp = _SDE; _SDE = _S_DE; _S_DE = tmp;
      tmp = _SHL; _SHL = _S_HL; _S_HL = tmp;
    }

    private function _SEXSP(reg: int) : int {
      var res: int = _SREADM16(_SSP);
      _SWRITEM16(_SSP, reg);
      return res & 0xFFFF;
    }

    //add-otdr
    // Ａレジスタ加算
    private function _SADD(value: int) : void {
      var res: int = _A + value;
      _F = SZ[res & 0xff] | ((res >> 8) & Z80_FLAG_C) | ((_A ^ res ^ value) & Z80_FLAG_H) | (((value ^ _A ^ 0x80) & (value ^ res) & 0x80) >> 5);
      _A = res & 0xFF;
    }

    // Ａレジスタキャリー加算
    private function _SADC(value: int) : void {
      var res: int = _A + value + (_F & Z80_FLAG_C);
      _F = SZ[res & 0xff] | ((res >> 8) & Z80_FLAG_C) | ((_A ^ res ^ value) & Z80_FLAG_H) | (((value ^ _A ^ 0x80) & (value ^ res) & 0x80) >> 5);
      _A = res & 0xFF;
    }

    // Ａレジスタ減算
    private function _SSUB(value: int) : void {
      var res: int = _A - value;
      _F = SZ[res & 0xff] | ((res >> 8) & Z80_FLAG_C) | Z80_FLAG_N | ((_A ^ res ^ value) & Z80_FLAG_H) | (((value ^ _A) & (_A ^ res) & 0x80) >> 5);
      _A = res & 0xFF;
    }

    // Ａレジスタキャリー減算
    private function _SSBC(value: int) : void {
      var res: int = _A - value - (_F & Z80_FLAG_C);
      _F = SZ[res & 0xff] | ((res >> 8) & Z80_FLAG_C) | Z80_FLAG_N | ((_A ^ res ^ value) & Z80_FLAG_H) | (((value ^ _A) & (_A ^ res) & 0x80) >> 5);
      _A = res & 0xFF;
    }

    // １６ビットレジスタ加算
    private function _SADD16(dreg: int, sreg: int) : int {
      var res: int = dreg + sreg;

      _F = ((_F & (Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_V)) | (((dreg ^ res ^ sreg) >> 8) & Z80_FLAG_H) | ((res >> 16) & Z80_FLAG_C) | ((res >> 8) & (Z80_FLAG_Y | Z80_FLAG_X)));

      return res & 0xFFFF;
    }

    private function _SADC16(reg: int) : void {
      var res: int = _SHL + reg + (_F & Z80_FLAG_C);
      _F = ((((_SHL ^ res ^ reg) >> 8) & Z80_FLAG_H) | ((res >> 16) & Z80_FLAG_C) | ((res >> 8) & (Z80_FLAG_S | Z80_FLAG_Y | Z80_FLAG_X)) |
            (((res & 0xffff)!=0) ? 0 : Z80_FLAG_Z) | (((reg ^ _SHL ^ 0x8000) & (reg ^ res) & 0x8000) >> 13));
      _SHL = res & 0xFFFF;
    }


    private function _SSBC16(reg: int) : void {
      var res: int = _SHL - reg;
      if ((_F & Z80_FLAG_C)!=0) {
        res--;
      }
      _F = ((((_SHL ^ res ^ reg) >> 8) & Z80_FLAG_H) | Z80_FLAG_N | ((res >> 16) & Z80_FLAG_C) |
            ((res >> 8) & (Z80_FLAG_S | Z80_FLAG_Y | Z80_FLAG_X)) | (((res & 0xffff)!=0) ? 0 : Z80_FLAG_Z) |
            (((reg ^ _SHL) & (_SHL ^ res) &0x8000) >> 13));
      _SHL = res & 0xFFFF;
    }

    private function _SNEG() : void {
      var value: int = _A;
      _A = 0;
      //    int value = _SgetA();
      //    _SsetA(0);
      _SSUB(value);
    }
    private function _SDAA() : void {
      var idx: int = _A;
      var f: int = _F;
      if((f & Z80_FLAG_C)!=0) idx |= 0x100;
      if((f & Z80_FLAG_H)!=0) idx |= 0x200;
      if((f & Z80_FLAG_N)!=0) idx |= 0x400;
      _SsetAF(DAATable[idx]);
    }

    // AND
    private function _SAND(v: int) : void {
      _A &= v;
      _F = SZP[_A] | Z80_FLAG_H;
    }

    // OR
    private function _SOR(v: int) : void {
      _A |= v;
      _F = SZP[_A];
    }
    // XOR
    private function _SXOR(v: int) : void {
      _A ^= v;
      _F = SZP[_A];
    }

    // CP
    private function _SCP(value: int) : void {
      var res: int = _A - value;

      _F = (SZ[res & 0xff] & (Z80_FLAG_S | Z80_FLAG_Z)) | (value & (Z80_FLAG_Y | Z80_FLAG_X)) |
        ((res >> 8) & Z80_FLAG_C) | Z80_FLAG_N | ((_A ^ res ^ value) & Z80_FLAG_H) |
          ((((value ^ _A) & (_A ^ res)) >> 5) & Z80_FLAG_V);
    }

    // ８ビットレジスタインクリメント
    private function _SINC(v: int) : int {
      var res: int = (v + 1) & 0xFF;
      _F = (_F & Z80_FLAG_C) | SZHV_INC[res];

      return res;
    }

    // ８ビットレジスタデクリメント
    private function _SDEC(v: int) : int {
      var res: int = (v - 1) & 0xFF;
      _F = (_F & Z80_FLAG_C) | SZHV_DEC[res];

      return res;
    }

    // RLCA
    private function _SRLCA() : void {
      _A = ((_A << 1) | (_A >> 7)) & 0xFF;
      _F = (_F & (Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_V)) | (_A & (Z80_FLAG_Y | Z80_FLAG_X | Z80_FLAG_C));
    }

    // RRCA
    private function _SRRCA() : void {
      _F = (_F & (Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_P)) | (_A & Z80_FLAG_C);
      _A = ((_A >> 1) | (_A << 7)) & 0xFF;
      _F |= (_A & (Z80_FLAG_Y | Z80_FLAG_X));
    }

    // RLA
    private function _SRLA() : void {
      var res: int = (_A << 1) | (_F & Z80_FLAG_C);
      var c: int = ((_A & 0x80)!=0) ? Z80_FLAG_C : 0;
      _F = (_F & (Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_V)) | c | (res & (Z80_FLAG_Y | Z80_FLAG_X));
      _A = res & 0xFF;
    }
    private function _SRRA() : void {
      var res: int = ((_A >> 1)&0x7f) | ((_F << 7) & 0x80);
      var c: int = ((_A & 0x01)!=0) ? Z80_FLAG_C : 0;
      _F = (_F & (Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_V)) | c | (res & (Z80_FLAG_Y | Z80_FLAG_X));
      _A = res;
    }
    private function _SRRD() : void {
      /*
    BYTE n = ReadMemory(HL);
    WriteMemory(HL, (n >> 4) | (_A << 4));
    _A = (_A & 0xf0) | (n & 0x0f);
    _F = (_F & CF) | SZP[_A];
       */
      var n: int = _SREADM8(_SHL);
      mem.write(_SHL, (n >> 4) | (_A << 4));
      _A = (_A & 0xf0) | (n & 0x0f);
      _F = (_F & Z80_FLAG_C) | SZP[_A];
    }

    //
    private function _SRLD() : void {
      var n: int = _SREADM8(_SHL);
      /*
    BYTE n = ReadMemory(HL);
    WriteMemory(HL, (n << 4) | (_A & 0x0f));
    _A = (_A & 0xf0) | (n >> 4);
    _F = (_F & CF) | SZP[_A];
       */

      mem.write(_SHL, (n << 4) | (_A & 0x0f));
      _A = (_A & 0xf0) | (n >> 4);
      _F = (_F & Z80_FLAG_C) | SZP[_A];
    }

    private function _SRLC(value: int) : int {
      var res: int = value;
      var c: int = ((res & 0x80)!=0) ? Z80_FLAG_C : 0;

      res = ((res << 1) | (res >> 7)) & 0xff;
      _F = SZP[res] | c;

      return res;
    }

    private function _SRRC(value: int) : int {
      var res: int = value;
      var c: int = ((res & 0x01)!=0) ? Z80_FLAG_C : 0;

      res = ((res >> 1) | (res << 7)) & 0xff;
      _F = SZP[res] | c;

      return res;
    }


    private function _SRL(value: int) : int {
      var res: int = value;
      var c: int = ((res & 0x80)!=0) ? Z80_FLAG_C : 0;

      res = ((res << 1) | (_F & Z80_FLAG_C)) & 0xff;
      _F = SZP[res] | c;

      return res;
    }

    private function _SRR(value: int) : int {
      var res: int = value;
      var c: int = ((res & 0x01)!=0) ? Z80_FLAG_C : 0;

      res = ((res >> 1) & 0x7f) | ((_F << 7) & 0x80);
      _F = SZP[res] | c;

      return res;
    }

    private function _SSLA(value: int) : int {
      var res: int = value;
      var c: int = ((res & 0x80)!=0) ? Z80_FLAG_C : 0;

      res = (res << 1) & 0xff;
      _F = SZP[res] | c;

      return res;
    }

    private function _SSRA(value: int) : int {
      var res: int = value;
      var c: int = ((res & 0x01)!=0) ? Z80_FLAG_C : 0;

      res = ((res >> 1) | (res & 0x80)) & 0xff;
      _F = SZP[res] | c;

      return res;
    }


    private function _SSLL(value: int) : int {
      var res: int = value;
      var c: int = ((res & 0x80)!=0) ? Z80_FLAG_C : 0;
      res = ((res << 1) | 0x01) & 0xff;
      _F = SZP[res] | c;

      return res;
    }

    private function _SSRL(value: int) : int {
      var res: int = value;
      var c: int = ((res & 0x01)!=0) ? Z80_FLAG_C : 0;
      res = (res >> 1) & 0xff;
      _F = SZP[res] | c;

      return res;
    }

    private function _SBIT(bit: int, reg: int) : void {
      _F = (_F & Z80_FLAG_C) | Z80_FLAG_H | SZ_BIT[reg & (1 << bit)];
    }
    private function _SBIT_XY(bit: int, reg: int) : void {
      _F = (_F & Z80_FLAG_C) | Z80_FLAG_H | (SZ_BIT[reg & (1 << bit)] & ~(Z80_FLAG_Y | Z80_FLAG_X)) | ((_SEA >> 8) & (Z80_FLAG_Y | Z80_FLAG_X));
    }

    private function _SRES(bit: int, value: int) : int {
      return value & ~(1 << bit);
    }

    private function _SSET(bit: int, value: int) : int {
      return value | (1 << bit);
    }

    private function _SLDI() : void {
      var i: int = _SREADM8(_SHL);
      mem.write(_SDE, i);

      _F &= Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_C;
      if (((_A + i) & 0x02)!=0) _F |= Z80_FLAG_Y; // bit 1 -> flag 5
      if (((_A + i) & 0x08)!=0) _F |= Z80_FLAG_X; // bit 3 -> flag 3
      //  _SHL++; _SDE++; _SBC--;
      _SHL++; _SHL &= 0xFFFF;
      _SDE++; _SDE &= 0xFFFF;
      _SBC--; _SBC &= 0xFFFF;

      if(_SBC !=0) _F |= Z80_FLAG_V;
    }

    private function _SCPI() : void {
      var val: int = _SREADM8(_SHL);
      var res: int = (_A - val)& 0xFF;

      _SHL++; _SHL &= 0xFFFF;
      _SBC--; _SBC &= 0xFFFF;
      _F = (_F & Z80_FLAG_C) | (SZ[res] & ~(Z80_FLAG_Y | Z80_FLAG_X)) | ((_A ^ val ^ res) & Z80_FLAG_H) | Z80_FLAG_N;
      if((_F & Z80_FLAG_H)!=0) res -= 1;
      if((res & 0x02)!=0) _F |= Z80_FLAG_Y; // bit 1 -> flag 5
      if((res & 0x08)!=0) _F |= Z80_FLAG_X; // bit 3 -> flag 3
      if(_SBC!=0) _F |= Z80_FLAG_V;
    }

    private function _SINI() : void {
      var b: int = _SgetB();
      var c: int = _SgetC();
      //    int i = io.in(c, b);
      var i: int = io._in(c);
      b = (b-1)&0xFF;
      mem.write(_SHL, i);
      //    _SHL++;
      _SHL++; _SHL &= 0xFFFF;
      _F = SZ[b];
      if((i & Z80_FLAG_S)!=0) _F |= Z80_FLAG_N;
      if(((((c + 1) & 0xff) + i) & 0x100)!=0) _F |= Z80_FLAG_H | Z80_FLAG_C;
      if(((irep_tmp[c & 3,i & 3] ^ breg_tmp[b] ^ (c >> 2) ^ (i >> 2)) & 1)!=0) _F |= Z80_FLAG_P;

      _SsetB(b);
    }
    private function _SOUTI() : void {
      var b: int = _SgetB();
      var c: int = _SgetC();
      var i: int = _SREADM8(_SHL);
      b = (b-1)&0xFF;
      io._out(c, i);
      //    WriteIO(_C, _B, io);
      //    _SHL++;
      _SHL++; _SHL &= 0xFFFF;
      _F = SZ[b];
      if((i & Z80_FLAG_S)!=0) _F |= Z80_FLAG_N;
      if(((((c + 1) & 0xff) + i) & 0x100)!=0) _F |= Z80_FLAG_H | Z80_FLAG_C;
      if(((irep_tmp[c & 3,i & 3] ^ breg_tmp[b] ^ (c >> 2) ^ (i >> 2)) & 1)!=0) _F |= Z80_FLAG_P;

      _SsetB(b);
    }

    private function _SLDD() : void {
      var i: int = _SREADM8(_SHL);
      mem.write(_SDE, i);
      _F &= Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_C;
      if (((_A + i) & 0x02)!=0) _F |= Z80_FLAG_Y; // bit 1 -> flag 5
      if (((_A + i) & 0x08)!=0) _F |= Z80_FLAG_X; // bit 3 -> flag 3
      //    _SHL--; _SDE--; _SBC--;
      _SHL--; _SHL &= 0xFFFF;
      _SDE--; _SDE &= 0xFFFF;
      _SBC--; _SBC &= 0xFFFF;
      if(_SBC!=0) _F |= Z80_FLAG_V;
    }
    private function _SCPD() : void {
      var val: int = _SREADM8(_SHL);
      var res: int = (_A - val)&0xFF;
      //    _SHL--; _SBC--;
      _SHL--; _SHL &= 0xFFFF;
      _SBC--; _SBC &= 0xFFFF;
      _F = (_F & Z80_FLAG_C) | (SZ[res] & ~(Z80_FLAG_Y | Z80_FLAG_X)) | ((_A ^ val ^ res) & Z80_FLAG_H) | Z80_FLAG_N;
      if((_F & Z80_FLAG_H)!=0) res -= 1;
      if((res & 0x02)!=0) _F |= Z80_FLAG_Y; // bit 1 -> flag 5
      if((res & 0x08)!=0) _F |= Z80_FLAG_X; // bit 3 -> flag 3
      if(_SBC!=0) _F |= Z80_FLAG_V;
    }

    private function _SIND() : void {
      var b: int = _SgetB();
      var c: int = _SgetC();
      var i: int = io._in(c);
      b = (b-1)& 0xFF;
      mem.write(_SHL, i);
      //    _SHL--;
      _SHL--; _SHL &= 0xFFFF;
      _F = SZ[b];
      if((i & Z80_FLAG_S)!=0) _F |= Z80_FLAG_N;
      if(((((c - 1) & 0xff) + i) & 0x100)!=0) _F |= Z80_FLAG_H | Z80_FLAG_C;
      if(((drep_tmp[c & 3,i & 3] ^ breg_tmp[b] ^ (c >> 2) ^ (i >> 2)) & 1)!=0) _F |= Z80_FLAG_P;
      _SsetB(b);
    }
    private function _SOUTD() : void {
      var b: int = _SgetB();
      var c: int = _SgetC();
      var i: int = _SREADM8(_SHL);

      b = (b-1)& 0xFF;
      io._out(c, i);
      //    _SHL--;
      _SHL--; _SHL &= 0xFFFF;
      _F = SZ[b];
      if((i & Z80_FLAG_S)!=0) _F |= Z80_FLAG_N;
      if(((((c - 1) & 0xff) + i) & 0x100)!=0) _F |= Z80_FLAG_H | Z80_FLAG_C;
      if(((drep_tmp[c & 3,i & 3] ^ breg_tmp[b] ^ (c >> 2) ^ (i >> 2)) & 1)!=0) _F |= Z80_FLAG_P;
      _SsetB(b);
    }
    private function _SLDIR() : void {
      _SLDI();
      if(_SBC!=0) {
        _SPC -= 2;
        //      _Sscount -= cc_ex[0xb0];
        _Sstate_count(cc_ex[0xb0]);
      }
    }

    private function _SCPIR() : void {
      _SCPI();
      if((_SBC!=0) && ((_F & Z80_FLAG_Z)==0)) {
        _SPC -= 2;
        //      _Sscount -= cc_ex[0xb1];
        _Sstate_count(cc_ex[0xb1]);
      }
    }

    private function _SINIR() : void {
      _SINI();
      if(_SgetB()!=0) {
        _SPC -= 2;
        //      _Sscount -= cc_ex[0xb2];
        _Sstate_count(cc_ex[0xb2]);
      }
    }
    private function _SOTIR() : void {
      _SOUTI();
      if(_SgetB()!=0) {
        _SPC -= 2;
        //      _Sscount -= cc_ex[0xb3];
        _Sstate_count(cc_ex[0xb3]);
      }
    }
    private function _SLDDR() : void {
      _SLDD();
      if(_SBC!=0) {
        _SPC -= 2;
        //      _Sscount -= cc_ex[0xb8];
        _Sstate_count(cc_ex[0xb8]);
      }
    }
    private function _SCPDR() : void {
      _SCPD();
      if((_SBC!=0) && ((_F & Z80_FLAG_Z)==0)) {
        _SPC -= 2;
        //      _Sscount -= cc_ex[0xb9];
        _Sstate_count(cc_ex[0xb9]);
      }
    }

    private function _SINDR() : void {
      _SIND();
      if(_SgetB()!=0) {
        _SPC -= 2;
        //      _Sscount -= cc_ex[0xba];
        _Sstate_count(cc_ex[0xba]);
      }
    }

    private function _SOTDR() : void {
      _SOUTD();
      if(_SgetB()!=0) {
        _SPC -= 2;
        //      _Sscount -= cc_ex[0xbb];
        _Sstate_count(cc_ex[0xbb]);
      }
    }

    //==========================================================================
    // コンストラクタ
    //==========================================================================
    public function Cz80(c:C8253, a: Cmem , b: Cio) {
      _8253 = c;
      mem = a;
      io = b;
    }

    //----------------
    // デバッグモード
    //----------------
    public function setDebug(f: int) :void {
      _Sdebug = f;
    }

    //----------
    // リセット
    //----------
    public function reset() :void {
      mem.reset();
      _8253.init();

      _SPC = _SSP =0;
      _R = 0;

      _SIM = 0;
      _SIFF1 = _SIFF2 = 0;
      _SsetAF(0);
      _SBC = _SDE = _SHL = _SIX = _SIY = 0;
      _S_BC = _S_DE = _S_HL = 0;

      _S_INTFLAG = 0;
      //
      _Svcount = _Sscount = 0;
      _Stempo_tstate = _Stempo_tstate2 = 0;
      _Spit_tstate = 0;

    }

    // IRQ
    private function _SDoIRQ(vector: int) : void {

      if (_SIFF1 == 0)
        return;

      /*
	if(HALT) {
		PC++;
		HALT = 0;
	}
       */
      if (_SIM == 0) {
        // MODE 0 (RST命令のみサポート)
        _SPUSH(_SPC);
        switch (vector) {
        case 0xc7:		// RST 00H
          _SPC = 0x0000;
          break;
        case 0xcf:		// RST 08H
          _SPC = 0x0008;
          break;
        case 0xd7:		// RST 10H
          _SPC = 0x0010;
          break;
        case 0xdf:		// RST 18H
          _SPC = 0x0018;
          break;
        case 0xe7:		// RST 20H
          _SPC = 0x0020;
          break;
        case 0xef:		// RST 28H
          _SPC = 0x0028;
          break;
        case 0xf7:		// RST 30H
          _SPC = 0x0030;
          break;
        case 0xff:		// RST 38H
          _SPC = 0x0038;
          break;
        }
        _SIFF1 = _SIFF2 = 0;
        //      _Sscount -= 7;
        _Sstate_count(7);
      }
      else if (_SIM == 1) {
        //    	System.out.println("DoIRQ("+ vector + ")");

        if ((_S_INTFLAG & 1) != 0) {
          _S_INTFLAG &= (~1);

          // MODE 1
          _SPUSH(_SPC);
          _SPC = 0x0038;
          _SIFF1 = _SIFF2 = 0;
          //      _Sscount -= 7;
          _Sstate_count(7);
        }
      }
      else {
        // MODE 2
        _SPUSH(_SPC);
        //      PC = ReadMemory16((_I << 8) | vector);
        _SPC = _SREADM16((_I << 8) | vector);
        _SIFF1 = _SIFF2 = 0;
        //      _Sscount -= 7;
        _Sstate_count(7);
      }
    }

    /*
void CPU::DoNMI()
{
	// NMI発生
	if(HALT) {
		PC++;
		HALT = 0;
	}
	PUSH(PC);
	PC = 0x0066;
	count -= 5;
	IFF1 = 0;
}
     */

    //----------------------------------
    // 割り込みカウント処理
    //----------------------------------
    private function _ScntInterrupt() : void {
      // 割り込み
      // Pit Interrupt (MZ-700)
      if ( (_Stempo_tstate - _Spit_tstate)  >= PIT_CVAL)  {
        //       _Spit_tstate -= PIT_CVAL;
        _Spit_tstate = _Stempo_tstate;
        if (_8253.pit_count()!=0) {
          if (_8253.is_pit_int()) {
            _S_INTFLAG |= 1;
            _SDoIRQ(0);
          }
        }
      }

    }


    //-----------------
    // 実行アドレス指定
    //-----------------
    public function execProg(adr: int):void {
      var b: Array = mem.getMem();
      /*
    _SIM = 1;
    _SIFF1 = _SIFF2 = 0;
    _SSP = 0x10F0;   // スタックポインタ初期化
    _8253.init();
       */
      reset();

      //    reset();
      //	update(CPU_SPEED/10);	// BIOSを少し実行

      /*
	_SIM = 1;
	_SIFF1 = _SIFF2 = 0;
    _SSP = 0x10F0;	// スタックポインタ初期化
    _8253.init();
    mem.reset();
       */
      //    _SPC = adr;

      // モニタ書き換え
      // NEW-MONITOR
      b[0x0085] = 0xC3;
      b[0x0086] = (adr & 0xFF);
      b[0x0087] = (adr >> 8);
      /*
    // 1Z-009A
  	b[0x00A2] = (u: int)0xC3;
  	b[0x00A3] = (u: int)(adr & 0xFF);
  	b[0x00A4] = (u: int)(adr >> 8);
       */
      //
      b = null;
    }

    //------------
    // ＣＰＵ更新
    //------------
    public function update(state: int):int {
      var code: int;
      var tmp: int;

      _Sscount = state;

      // Ｚ８０実行
      while (_Sscount > 0) {
        /*
  	  if (_SPC == 0xBFB5) {
    	_Sdebug = 1;
    　}
         */
        /*
  	  if (_SPC == 0x0DBF && _A == 0xF5) {
    	_Sdebug = 1;
    　}
         */
        //	  // メモリウェイトの処理
        //      _Sstate_count(mem.getWait());
        // 	  // ウェイトクリア
        // 	  mem.clrWait();

        // 割り込み処理
        _ScntInterrupt();

        //
        code = _SREADM_PC();
        //      _Sscount -= cc_op[a];
        _Sstate_count(cc_op[code]);
        _R = (_R & 0x80) | ((_R + 1) & 0x7f);

        if (_Sdebug !=0) {
          //	    if (_SPC >= 0x1000) {
//          System.out.print(strHex(_SPC-1, 4)+":"+strHex(code, 2)+" ");
          if ((++tracec)>=10) {
            tracec = 0;
//            System.out.println(" ");
          }
          //	     }
        }

        switch (code) {
        case 0x00:
          // nop
          break;

        case 0x01:
          // LD BC,mmnn
          _SBC = _SREADM16(_SPC);
          _SPC += 2;
          break;

        case 0x02:
          // LD (BC),A
          mem.write(_SBC, _A);
          break;

        case 0x03:
          // INC BC
          ++_SBC;
          _SBC &= 0xFFFF;
          break;

        case 0x04:
          // INC B
          _SsetB(_SINC(_SgetB()));
          break;

        case 0x05:
          // DEC B
          _SsetB(_SDEC(_SgetB()));
          break;

        case 0x06:
          // LD B,nn
          _SsetB(_SREADM_PC());
          break;

        case 0x07:
          // RLCA
          _SRLCA();
          break;

        case 0x08:
          // EX AF,AF'
          //        tmp = _SAF; _SAF = _S_AF; _S_AF = tmp;
          tmp = _SgetAF(); _SsetAF(_S_AF); _S_AF = tmp;
          break;

        case 0x09:
          // ADD HL,BC
          _SHL = _SADD16(_SHL, _SBC);
          break;

        case 0x0a:
          // LD A, (BC)
          _A =_SREADM8(_SBC);
          //        _A = ReadMemory(BC);
          break;

        case 0x0b:
          // DEC BC
          --_SBC;
          _SBC &= 0xFFFF;
          break;

        case 0x0c:
          // INC C
          //				_C = INC(_C);
          _SsetC(_SINC(_SgetC()));
          break;

        case 0x0d:
          // DEC C
          //				_C = DEC(_C);
          _SsetC(_SDEC(_SgetC()));
          break;

        case 0x0e:
          // LD C, n
          //				_C = ReadMemory(PC++);
          _SsetC(_SREADM_PC());
          break;

        case 0x0f: // RRCA
          _SRRCA();
          break;

        case 0x10: // DJNZ o
          //				_B--;
          //				JR_COND(_B, 0x10);
          tmp = _SgetB();
          tmp--;
          _SsetB(tmp);
          _SJR_COND_VALNZ(tmp, 0x10);
          break;

        case 0x11:
          // LD DE, w
          //				DE = ReadMemory16(PC);
          //				PC += 2;
          //        _SDE = _SREADM_PC() | (_SREADM_PC()<<8);
          _SDE = _SREADM16(_SPC);
          _SPC += 2;
          break;

        case 0x12: // LD (DE), A
          //				WriteMemory(DE, _A);
          mem.write(_SDE, _A);
          break;

        case 0x13:
          // INC DE
          ++_SDE;
          _SDE &= 0xFFFF;
          break;

        case 0x14:
          // INC D
          //				_D = INC(_D);
          _SsetD(_SINC(_SgetD()));
          break;

        case 0x15:
          // DEC D
          //				_D = DEC(_D);
          _SsetD(_SDEC(_SgetD()));
          break;

        case 0x16: // LD D, n
          //				_D = ReadMemory(PC++);
          _SsetD(_SREADM_PC());
          break;

        case 0x17: // RLA
          _SRLA();
          break;

        case 0x18:
          // JR o
          _SJR();
          break;

        case 0x19:
          // ADD HL, DE
          _SHL = _SADD16(_SHL, _SDE);
          break;

        case 0x1a:
          // LD A, (DE)
          //				_A = ReadMemory(DE);
          _A = (_SREADM8(_SDE));
          break;

        case 0x1b: // DEC DE
          --_SDE;
          _SDE &= 0xFFFF;
          break;

        case 0x1c:
          // INC E
          //				_E = INC(_E);
          _SsetE(_SINC(_SgetE()));
          break;

        case 0x1d:
          // DEC E
          //				_E = DEC(_E);
          _SsetE(_SDEC(_SgetE()));
          break;

        case 0x1e:
          // LD E, n
          //				_E = ReadMemory(PC++);
          _SsetE(_SREADM_PC());
          break;

        case 0x1f:
          // RRA
          _SRRA();
          break;

        case 0x20: // JR NZ, o
          //				JR_COND(!(_F & ZF), 0x20);
          _SJR_COND(Z80_FLAG_Z, 0x20, false);
          break;

        case 0x21:
          // LD HL, w
          //				HL = ReadMemory16(PC);
          //				PC += 2;
          _SHL = _SREADM16(_SPC);
          _SPC += 2;
          break;

        case 0x22: // LD (w), HL
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          //				EA = ReadMemory16(PC);
          //				PC += 2;
          _SWRITEM16(_SEA, _SHL);
          break;

        case 0x23:
          // INC HL
          ++_SHL;
          _SHL &= 0xFFFF;
          break;

        case 0x24:
          // INC H
          //				_H = INC(_H);
          _SsetH(_SINC(_SgetH()));
          break;

        case 0x25:
          // DEC H
          //				_H = DEC(_H);
          _SsetH(_SDEC(_SgetH()));
          break;

        case 0x26:
          // LD H, n
          //				_H = ReadMemory(PC++);
          _SsetH(_SREADM_PC());
          break;

        case 0x27: // DAA
          _SDAA();
          break;

        case 0x28: // JR Z, o
          //				JR_COND(_F & ZF, 0x28);
          _SJR_COND(Z80_FLAG_Z, 0x28, true);
          break;

        case 0x29:
          // ADD HL, HL
          _SHL = _SADD16(_SHL, _SHL);
          break;

        case 0x2a:
          // LD HL, (w)
          //				EA = ReadMemory16(PC);
          //				PC += 2;
          ///				HL = ReadMemory16(EA);
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SHL = _SREADM16(_SEA);
          break;

        case 0x2b:
          // DEC HL
          _SHL--;
          _SHL &= 0xFFFF;
          break;

        case 0x2c:
          // INC L
          //				_L = INC(_L);
          _SsetL(_SINC(_SgetL()));
          break;

        case 0x2d:
          // DEC L
          //				_L = DEC(_L);
          _SsetL(_SDEC(_SgetL()));
          break;

        case 0x2e:
          // LD L, n
          //				_L = ReadMemory(PC++);
          _SsetL(_SREADM_PC());
          break;

        case 0x2f:
          // CPL
          //				_A ^= 0xff;
          //				_F = (_F & (SF | ZF | PF | CF)) | HF | NF | (_A & (YF | XF));
          _A ^= 0xff;
          _F = (_F & (Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_P | Z80_FLAG_C)) | Z80_FLAG_H | Z80_FLAG_N | (_A & (Z80_FLAG_Y | Z80_FLAG_X));
          break;

        case 0x30: // JR NC, o
          //				JR_COND(!(_F & CF), 0x30);
          _SJR_COND(Z80_FLAG_C, 0x30, false);
          break;

        case 0x31:
          // LD SP, w
          //				SP = ReadMemory16(PC);
          //				PC += 2;
          _SSP = _SREADM16(_SPC);
          _SPC += 2;
          break;

        case 0x32: // LD (w), A
          //				EA = ReadMemory16(PC);
          //				PC += 2;
          //				WriteMemory(EA, _A);
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          mem.write(_SEA, _A);
          break;

        case 0x33:
          // INC SP
          ++_SSP;
          _SSP &= 0xFFFF;
          break;

        case 0x34:
          // INC (HL)
          //				WriteMemory(HL, INC(ReadMemory(HL)));
          mem.write(_SHL, _SINC(_SREADM8(_SHL)));
          break;

        case 0x35:
          // DEC (HL)
          //				WriteMemory(HL, DEC(ReadMemory(HL)));
          mem.write(_SHL, _SDEC(_SREADM8(_SHL)));
          break;

        case 0x36:
          // LD (HL), n
          //				WriteMemory(HL, ReadMemory(PC++));
          mem.write(_SHL, _SREADM_PC());
          break;

        case 0x37: // SCF
          //        _SsetF(_SgetF() | Z80_FLAG_C);
          //				_F = (_F & (SF | ZF | PF)) | CF | (_A & (YF | XF));
          _F = (_F & (Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_P)) | Z80_FLAG_C | (_A & (Z80_FLAG_Y | Z80_FLAG_X));
          break;

        case 0x38: // JR C, o
          //				JR_COND(_F & CF, 0x38);
          _SJR_COND(Z80_FLAG_C, 0x38, true);
          break;

        case 0x39:
          // ADD HL, SP
          _SHL = _SADD16(_SHL, _SSP);
          break;

        case 0x3a:
          // LD A, (w)
          //				EA = ReadMemory16(PC);
          //				PC += 2;
          //				_A = ReadMemory(EA);
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _A = _SREADM8(_SEA);
          break;

        case 0x3b:
          // DEC SP
          --_SSP;
          _SSP &= 0xFFFF;
          break;

        case 0x3c:
          // INC A
          //				_A = INC(_A);
          _A = (_SINC(_A));
          break;

        case 0x3d:
          // DEC A
          //				_A = DEC(_A);
          _A = (_SDEC(_A));
          break;

        case 0x3e: // LD A, n
          //				_A = ReadMemory(PC++);
          _A = (_SREADM_PC());
          break;

        case 0x3f:
          // CCF
          _F = ((_F & (Z80_FLAG_S | Z80_FLAG_Z | Z80_FLAG_P | Z80_FLAG_C)) |
                ((_F & Z80_FLAG_C) << 4) | (_A & (Z80_FLAG_Y | Z80_FLAG_X))) ^ Z80_FLAG_C;
          break;

        case 0x40:
          // LD B, B
          break;

        case 0x41:
          // LD B, C
          _SsetB(_SgetC());
          break;

        case 0x42:
          // LD B, D
          //				_B = _D;
          _SsetB(_SgetD());
          break;

        case 0x43:
          // LD B, E
          //				_B = _E;
          _SsetB(_SgetE());
          break;

        case 0x44:
          // LD B, H
          //				_B = _H;
          _SsetB(_SgetH());
          break;

        case 0x45:
          // LD B, L
          //				_B = _L;
          _SsetB(_SgetL());
          break;

        case 0x46:
          // LD B, (HL)
          //				_B = ReadMemory(HL);
          _SsetB(_SREADM8(_SHL));
          break;

        case 0x47:
          // LD B, A
          //				_B = _A;
          _SsetB(_A);
          break;

        case 0x48:
          // LD C, B
          //				_C = _B;
          _SsetC(_SgetB());
          break;

        case 0x49: // LD C, C
          break;

        case 0x4a: // LD C, D
          //				_C = _D;
          _SsetC(_SgetD());
          break;

        case 0x4b: // LD C, E
          //				_C = _E;
          _SsetC(_SgetE());
          break;

        case 0x4c: // LD C, H
          //				_C = _H;
          _SsetC(_SgetH());
          break;

        case 0x4d: // LD C, L
          //				_C = _L;
          _SsetC(_SgetL());
          break;

        case 0x4e:
          // LD C, (HL)
          //				_C = ReadMemory(HL);
          _SsetC(_SREADM8(_SHL));
          break;

        case 0x4f: // LD C, A
          //				_C = _A;
          _SsetC(_A);
          break;

        case 0x50: // LD D, B
          //				_D = _B;
          _SsetD(_SgetB());
          break;

        case 0x51: // LD D, C
          //				_D = _C;
          _SsetD(_SgetC());
          break;

        case 0x52: // LD D, D
          break;

        case 0x53: // LD D, E
          //				_D = _E;
          _SsetD(_SgetE());
          break;

        case 0x54: // LD D, H
          //				_D = _H;
          _SsetD(_SgetH());
          break;

        case 0x55: // LD D, L
          //				_D = _L;
          _SsetD(_SgetL());
          break;

        case 0x56: // LD D, (HL)
          //				_D = ReadMemory(HL);
          _SsetD(_SREADM8(_SHL));
          break;

        case 0x57: // LD D, A
          //				_D = _A;
          _SsetD(_A);
          break;

        case 0x58: // LD E, B
          //				_E = _B;
          _SsetE(_SgetB());
          break;

        case 0x59: // LD E, C
          //				_E = _C;
          _SsetE(_SgetC());
          break;

        case 0x5a: // LD E, D
          //				_E = _D;
          _SsetE(_SgetD());
          break;

        case 0x5b: // LD E, E
          break;

        case 0x5c: // LD E, H
          //				_E = _H;
          _SsetE(_SgetH());
          break;

        case 0x5d: // LD E, L
          //				_E = _L;
          _SsetE(_SgetL());
          break;

        case 0x5e: // LD E, (HL)
          //				_E = ReadMemory(HL);
          _SsetE(_SREADM8(_SHL));
          break;

        case 0x5f: // LD E, A
          //				_E = _A;
          _SsetE(_A);
          break;

        case 0x60: // LD H, B
          //				_H = _B;
          _SsetH(_SgetB());
          break;

        case 0x61: // LD H, C
          //				_H = _C;
          _SsetH(_SgetC());
          break;

        case 0x62: // LD H, D
          //				_H = _D;
          _SsetH(_SgetD());
          break;

        case 0x63: // LD H, E
          //				_H = _E;
          _SsetH(_SgetE());
          break;

        case 0x64: // LD H, H
          break;

        case 0x65: // LD H, L
          //				_H = _L;
          _SsetH(_SgetL());
          break;

        case 0x66: // LD H, (HL)
          //				_H = ReadMemory(HL);
          _SsetH(_SREADM8(_SHL));
          break;

        case 0x67: // LD H, A
          //				_H = _A;
          _SsetH(_A);
          break;

        case 0x68: // LD L, B
          //				_L = _B;
          _SsetL(_SgetB());
          break;

        case 0x69: // LD L, C
          //				_L = _C;
          _SsetL(_SgetC());
          break;

        case 0x6a: // LD L, D
          //				_L = _D;
          _SsetL(_SgetD());
          break;

        case 0x6b: // LD L, E
          //				_L = _E;
          _SsetL(_SgetE());
          break;

        case 0x6c: // LD L, H
          //				_L = _H;
          _SsetL(_SgetH());
          break;

        case 0x6d: // LD L, L
          break;

        case 0x6e: // LD L, (HL)
          //				_L = ReadMemory(HL);
          _SsetL(_SREADM8(_SHL));
          break;

        case 0x6f: // LD L, A
          //				_L = _A;
          _SsetL(_A);
          break;

        case 0x70: // LD (HL), B
          //				WriteMemory(HL, _B);
          mem.write(_SHL, _SgetB());
          break;

        case 0x71: // LD (HL), C
          //				WriteMemory(HL, _C);
          mem.write(_SHL, _SgetC());
          break;

        case 0x72: // LD (HL), D
          //				WriteMemory(HL, _D);
          mem.write(_SHL, _SgetD());
          break;

        case 0x73: // LD (HL), E
          //				WriteMemory(HL, _E);
          mem.write(_SHL, _SgetE());
          break;

        case 0x74: // LD (HL), H
          //				WriteMemory(HL, _H);
          mem.write(_SHL, _SgetH());
          break;

        case 0x75: // LD (HL), L
          //				WriteMemory(HL, _L);
          mem.write(_SHL, _SgetL());
          break;

        case 0x76: // HALT
          --_SPC;
          _SPC &= 0xFFFF;
          //				HALT = 1;
          break;

        case 0x77: // LD (HL), A
          //				WriteMemory(HL, _A);
          mem.write(_SHL, _A);
          break;

        case 0x78: // LD A, B
          //				_A = _B;
          _A = _SgetB();
          break;

        case 0x79: // LD A, C
          //				_A = _C;
          _A = (_SgetC());
          break;

        case 0x7a: // LD A, D
          //				_A = _D;
          _A = (_SgetD());
          break;

        case 0x7b: // LD A, E
          //				_A = _E;
          _A = (_SgetE());
          break;

        case 0x7c: // LD A, H
          //				_A = _H;
          _A = (_SgetH());
          break;

        case 0x7d: // LD A, L
          //				_A = _L;
          _A = (_SgetL());
          break;

        case 0x7e: // LD A, (HL)
          //				_A = ReadMemory(HL);
          _A = (_SREADM8(_SHL));
          break;

        case 0x7f: // LD A, A
          break;

        case 0x80: // ADD A, B
          _SADD(_SgetB());
          break;

        case 0x81: // ADD A, C
          _SADD(_SgetC());
          break;

        case 0x82: // ADD A, D
          _SADD(_SgetD());
          break;

        case 0x83: // ADD A, E
          _SADD(_SgetE());
          break;

        case 0x84: // ADD A, H
          _SADD(_SgetH());
          break;

        case 0x85: // ADD A, L
          _SADD(_SgetL());
          break;

        case 0x86: // ADD A, (HL)
          //				ADD(ReadMemory(HL));
          _SADD(_SREADM8(_SHL));
          break;

        case 0x87: // ADD A, A
          _SADD(_A);
          //				ADD(_A);
          break;

        case 0x88: // ADC A, B
          //				ADC(_B);
          _SADC(_SgetB());
          break;

        case 0x89: // ADC A, C
          //				ADC(_C);
          _SADC(_SgetC());
          break;

        case 0x8a: // ADC A, D
          //				ADC(_D);
          _SADC(_SgetD());
          break;

        case 0x8b: // ADC A, E
          //				ADC(_E);
          _SADC(_SgetE());
          break;

        case 0x8c: // ADC A, H
          //				ADC(_H);
          _SADC(_SgetH());
          break;

        case 0x8d: // ADC A, L
          //				ADC(_L);
          _SADC(_SgetL());
          break;

        case 0x8e: // ADC A, (HL)
          //				ADC(ReadMemory(HL));
          _SADC(_SREADM8(_SHL));
          break;

        case 0x8f: // ADC A, A
          //				ADC(_A);
          _SADC(_A);
          break;

        case 0x90: // SUB B
          //				SUB(_B);
          _SSUB(_SgetB());
          break;

        case 0x91: // SUB C
          //				SUB(_C);
          _SSUB(_SgetC());
          break;

        case 0x92: // SUB D
          //				SUB(_D);
          _SSUB(_SgetD());
          break;

        case 0x93: // SUB E
          //				SUB(_E);
          _SSUB(_SgetE());
          break;

        case 0x94: // SUB H
          //				SUB(_H);
          _SSUB(_SgetH());
          break;

        case 0x95: // SUB L
          //				SUB(_L);
          _SSUB(_SgetL());
          break;

        case 0x96: // SUB (HL)
          //				SUB(ReadMemory(HL));
          _SSUB(_SREADM8(_SHL));
          break;

        case 0x97: // SUB A
          //				SUB(_A);
          _SSUB(_A);
          break;

        case 0x98: // SBC A, B
          //				SBC(_B);
          _SSBC(_SgetB());
          break;

        case 0x99: // SBC A, C
          //				SBC(_C);
          _SSBC(_SgetC());
          break;

        case 0x9a: // SBC A, D
          //				SBC(_D);
          _SSBC(_SgetD());
          break;

        case 0x9b: // SBC A, E
          //				SBC(_E);
          _SSBC(_SgetE());
          break;

        case 0x9c: // SBC A, H
          //				SBC(_H);
          _SSBC(_SgetH());
          break;

        case 0x9d: // SBC A, L
          //				SBC(_L);
          _SSBC(_SgetL());
          break;

        case 0x9e: // SBC A, (HL)
          //				SBC(ReadMemory(HL));
          _SSBC(_SREADM8(_SHL));
          break;

        case 0x9f: // SBC A, A
          //				SBC(_A);
          _SSBC(_A);
          break;

        case 0xa0: // AND B
          //				AND(_B);
          _SAND(_SgetB());
          break;

        case 0xa1: // AND C
          //				AND(_C);
          _SAND(_SgetC());
          break;

        case 0xa2: // AND D
          //				AND(_D);
          _SAND(_SgetD());
          break;

        case 0xa3: // AND E
          //				AND(_E);
          _SAND(_SgetE());
          break;

        case 0xa4: // AND H
          //				AND(_H);
          _SAND(_SgetH());
          break;

        case 0xa5: // AND L
          //				AND(_L);
          _SAND(_SgetL());
          break;

        case 0xa6: // AND (HL)
          //				AND(ReadMemory(HL));
          _SAND(_SREADM8(_SHL));
          break;

        case 0xa7: // AND A
          //				AND(_A);
          _SAND(_A);
          break;

        case 0xa8: // XOR B
          //				XOR(_B);
          _SXOR(_SgetB());
          break;

        case 0xa9: // XOR C
          //				XOR(_C);
          _SXOR(_SgetC());
          break;

        case 0xaa: // XOR D
          //				XOR(_D);
          _SXOR(_SgetD());
          break;

        case 0xab: // XOR E
          //				XOR(_E);
          _SXOR(_SgetE());
          break;

        case 0xac: // XOR H
          //				XOR(_H);
          _SXOR(_SgetH());
          break;

        case 0xad: // XOR L
          //				XOR(_L);
          _SXOR(_SgetL());
          break;

        case 0xae: // XOR (HL)
          //				XOR(ReadMemory(HL));
          _SXOR(_SREADM8(_SHL));
          break;

        case 0xaf: // XOR A
          //				XOR(_A);
          _SXOR(_A);
          break;

        case 0xb0: // OR B
          //				OR(_B);
          _SOR(_SgetB());
          break;

        case 0xb1: // OR C
          //				OR(_C);
          _SOR(_SgetC());
          break;

        case 0xb2: // OR D
          //				OR(_D);
          _SOR(_SgetD());
          break;

        case 0xb3: // OR E
          //				OR(_E);
          _SOR(_SgetE());
          break;

        case 0xb4: // OR H
          //				OR(_H);
          _SOR(_SgetH());
          break;

        case 0xb5: // OR L
          //				OR(_L);
          _SOR(_SgetL());
          break;

        case 0xb6: // OR (HL)
          //				OR(ReadMemory(HL));
          _SOR(_SREADM8(_SHL));
          break;

        case 0xb7: // OR A
          //				OR(_A);
          _SOR(_A);
          break;

        case 0xb8: // CP B
          //				CP(_B);
          _SCP(_SgetB());
          break;

        case 0xb9: // CP C
          //				CP(_C);
          _SCP(_SgetC());
          break;

        case 0xba: // CP D
          //				CP(_D);
          _SCP(_SgetD());
          break;

        case 0xbb: // CP E
          //				CP(_E);
          _SCP(_SgetE());
          break;

        case 0xbc: // CP H
          //				CP(_H);
          _SCP(_SgetH());
          break;

        case 0xbd: // CP L
          //				CP(_L);
          _SCP(_SgetL());
          break;

        case 0xbe: // CP (HL)
          //				CP(ReadMemory(HL));
          _SCP(_SREADM8(_SHL));
          break;

        case 0xbf: // CP A
          //				CP(_A);
          _SCP(_A);
          break;

        case 0xc0: // RET NZ
          //				RET_COND(!(_F & ZF), 0xc0);
          _SRET_COND(Z80_FLAG_Z, 0xc0, false);
          break;

        case 0xc1: // POP BC
          _SBC = _SPOP();
          break;
        case 0xc2: // JP NZ, a
          _SJP_COND(Z80_FLAG_Z, false);
          break;
        case 0xc3: // JP a
          _SPC = _SREADM16(_SPC);
          break;
        case 0xc4: // CALL NZ, a
          //				CALL_COND(!(_F & ZF), 0xc4);
          _SCALL_COND(Z80_FLAG_Z, 0xc4, false);
          break;
        case 0xc5: // PUSH BC
          _SPUSH(_SBC);
          break;
        case 0xc6: // ADD A, n
          //				ADD(ReadMemory(PC++));
          _SADD(_SREADM_PC());
          break;

        case 0xc7: // RST 0
          _SRST(0x00);
          break;
        case 0xc8: // RET Z
          //				RET_COND(_F & ZF, 0xc8);
          _SRET_COND(Z80_FLAG_Z, 0xc8, true);
          break;
        case 0xc9: // RET
          _SRET();
          break;
        case 0xca: // JP Z, a
          _SJP_COND(Z80_FLAG_Z, true);
          break;

        case 0xcb: // **** CB xx
          _ScodeCB();
          break;

        case 0xcc: // CALL Z, a
          //				CALL_COND(_F & ZF, 0xcc);
          _SCALL_COND(Z80_FLAG_Z, 0xcc, true);
          break;
        case 0xcd: // CALL a
          _SCALL();
          break;
        case 0xce: // ADC A, n
          //				ADC(ReadMemory(PC++));
          _SADC(_SREADM_PC());
          break;
        case 0xcf: // RST 1
          _SRST(0x08);
          break;
        case 0xd0: // RET NC
          //				RET_COND(!(_F & CF), 0xd0);
          _SRET_COND(Z80_FLAG_C, 0xd0, false);
          break;
        case 0xd1: // POP DE
          _SDE = _SPOP();
          break;
        case 0xd2: // JP NC, a
          //				JP_COND(!(_F & CF));
          _SJP_COND(Z80_FLAG_C, false);
          break;
        case 0xd3: // OUT (n), A
          //				WriteIO(ReadMemory(PC++), _A, _A);
          io._out(_SREADM_PC(), _A);
          break;
        case 0xd4: // CALL NC, a
          //				CALL_COND(!(_F & CF), 0xd4);
          _SCALL_COND(Z80_FLAG_C, 0xd4, false);
          break;
        case 0xd5: // PUSH DE
          _SPUSH(_SDE);
          break;
        case 0xd6: // SUB n
          //				SUB(ReadMemory(PC++));
          _SSUB(_SREADM_PC());
          break;
        case 0xd7: // RST 2
          _SRST(0x10);
          break;
        case 0xd8: // RET C
          //				RET_COND(_F & CF, 0xd8);
          _SRET_COND(Z80_FLAG_C, 0xd8, true);
          break;
        case 0xd9: // EXX
          _SEXX();
          break;
        case 0xda: // JP C, a
          //				JP_COND(_F & CF);
          _SJP_COND(Z80_FLAG_C, true);
          break;
        case 0xdb: // IN A, (n)
          //				_A = ReadIO(ReadMemory(PC++), _A);
          _A = (io._in(_SREADM_PC()));
          break;
        case 0xdc: // CALL C, a
          //				CALL_COND(_F & CF, 0xdc);
          _SCALL_COND(Z80_FLAG_C, 0xdc, true);
          break;
        case 0xdd: // **** DD xx
          _ScodeDD();
          break;
        case 0xde: // SBC A, n
          //				SBC(ReadMemory(PC++));
          _SSBC(_SREADM_PC());
          break;
        case 0xdf: // RST 3
          _SRST(0x18);
          break;
        case 0xe0: // RET PO
          //				RET_COND(!(_F & PF), 0xe0);
          _SRET_COND(Z80_FLAG_P, 0xe0, false);
          break;
        case 0xe1: // POP HL
          _SHL = _SPOP();
          break;
        case 0xe2: // JP PO, a
          //				JP_COND(!(_F & PF));
          _SJP_COND(Z80_FLAG_P, false);
          break;
        case 0xe3: // EX HL, (SP)
          _SHL = _SEXSP(_SHL);
          break;
        case 0xe4: // CALL PO, a
          //				CALL_COND(!(_F & PF), 0xe4);
          _SCALL_COND(Z80_FLAG_P, 0xe4, false);
          break;
        case 0xe5: // PUSH HL
          _SPUSH(_SHL);
          break;
        case 0xe6: // AND n
          //				AND(ReadMemory(PC++));
          _SAND(_SREADM_PC());
          break;
        case 0xe7: // RST 4
          _SRST(0x20);
          break;
        case 0xe8: // RET PE
          //				RET_COND(_F & PF, 0xe8);
          _SRET_COND(Z80_FLAG_P, 0xe8, true);
          break;
        case 0xe9: // JP (HL)
          //				PC = HL;
          _SPC = _SHL;
          break;
        case 0xea: // JP PE, a
          //				JP_COND(_F & PF);
          _SJP_COND(Z80_FLAG_P, true);
          break;
        case 0xeb: // EX DE, HL
          _SEX_DE_HL();
          break;
        case 0xec: // CALL PE, a
          //				CALL_COND(_F & PF, 0xec);
          _SCALL_COND(Z80_FLAG_P, 0xec, true);
          break;
        case 0xed: // **** ED xx
          _ScodeED();
          break;
        case 0xee: // XOR n
          //				XOR(ReadMemory(PC++));
          _SXOR(_SREADM_PC());
          break;
        case 0xef: // RST 5
          _SRST(0x28);
          break;
        case 0xf0: // RET P
          //				RET_COND(!(_F & SF), 0xf0);
          _SRET_COND(Z80_FLAG_S, 0xf0, false);
          break;
        case 0xf1: // POP AF
          //        _SAF = _SPOP();
          _SsetAF(_SPOP());
          break;
        case 0xf2: // JP P, a
          //				JP_COND(!(_F & SF));
          _SJP_COND(Z80_FLAG_S, false);
          break;
        case 0xf3: // DI
          _SDI();
          break;
        case 0xf4: // CALL P, a
          //				CALL_COND(!(_F & SF), 0xf4);
          _SCALL_COND(Z80_FLAG_S, 0xf4, false);
          break;
        case 0xf5: // PUSH AF
          _SPUSH(_SgetAF());
          break;
        case 0xf6: // OR n
          //				OR(ReadMemory(PC++));
          _SOR(_SREADM_PC());
          break;
        case 0xf7: // RST 6
          _SRST(0x30);
          break;
        case 0xf8: // RET M
          //				RET_COND(_F & SF, 0xf8);
          _SRET_COND(Z80_FLAG_S, 0xf8, true);
          break;
        case 0xf9: // LD SP, HL
          _SSP = _SHL;
          break;
        case 0xfa: // JP M, a
          //				JP_COND(_F & SF);
          _SJP_COND(Z80_FLAG_S, true);
          break;
        case 0xfb: // EI
          _SEI();
          break;
        case 0xfc: // CALL M, a
          //				CALL_COND(_F & SF, 0xfc);
          _SCALL_COND(Z80_FLAG_S, 0xfc, true);
          break;
        case 0xfd: // **** FD xx
          _ScodeFD();
          break;
        case 0xfe: // CP n
          //				CP(ReadMemory(PC++));
          _SCP(_SREADM_PC());
          break;
        case 0xff: // RST 7
          _SRST(0x38);
          break;
        }

      }

      return 0;
    }


    //
    private function _ScodeCB() : void {
      var tmp: int;

      // 命令の実行
      var code: int = _SREADM_PC();
      //    _Sscount -= cc_cb[code];
      _Sstate_count(cc_cb[code]);
      _R = (_R & 0x80) | ((_R + 1) & 0x7f);

      switch (code) {
      case 0x00: // RLC B
        //      _B = RLC(_B);
        _SsetB(_SRLC(_SgetB()));
        break;
      case 0x01: // RLC C
        //      _C = RLC(_C);
        _SsetC(_SRLC(_SgetC()));
        break;
      case 0x02: // RLC D
        //      _D = RLC(_D);
        _SsetD(_SRLC(_SgetD()));
        break;
      case 0x03: // RLC E
        //      _E = RLC(_E);
        _SsetE(_SRLC(_SgetE()));
        break;
      case 0x04: // RLC H
        //      _H = RLC(_H);
        _SsetH(_SRLC(_SgetH()));
        break;
      case 0x05: // RLC L
        //      _L = RLC(_L);
        _SsetL(_SRLC(_SgetL()));
        break;
      case 0x06: // RLC (HL)
        //      WriteMemory(HL, RLC(ReadMemory(HL)));
        mem.write(_SHL, _SRLC(_SREADM8(_SHL)));
        break;
      case 0x07: // RLC A
        //      _A = RLC(_A);
        _A = _SRLC(_A);
        break;

      case 0x08: // RRC B
        //_B = RRC(_B);
        tmp = _SRRC(_SgetB());
        _SsetB(tmp);
        break;
      case 0x09: // RRC C
        //      _C = RRC(_C);
        tmp = _SRRC(_SgetC());
        _SsetC(tmp);
        break;
      case 0x0a: // RRC D
        //      _D = RRC(_D);
        tmp = _SRRC(_SgetD());
        _SsetD(tmp);
        break;
      case 0x0b: // RRC E
        //      _E = RRC(_E);
        tmp = _SRRC(_SgetE());
        _SsetE(tmp);
        break;
      case 0x0c: // RRC H
        //      _H = RRC(_H);
        tmp = _SRRC(_SgetH());
        _SsetH(tmp);
        break;
      case 0x0d: // RRC L
        //      _L = RRC(_L);
        tmp = _SRRC(_SgetL());
        _SsetL(tmp);
        break;
      case 0x0e: // RRC (HL)
        //      WriteMemory(HL, RRC(ReadMemory(HL)));
        tmp = _SRRC(_SREADM8(_SHL));
        mem.write(_SHL, tmp);
        break;
      case 0x0f: // RRC A
        //      _A = RRC(_A);
        _A = _SRRC(_A);
        break;

      case 0x10: // RL B
        //      _B = RL(_B);
        tmp = _SRL(_SgetB());
        _SsetB(tmp);
        break;
      case 0x11: // RL C
        //      _C = RL(_C);
        tmp = _SRL(_SgetC());
        _SsetC(tmp);
        break;
      case 0x12: // RL D
        //      _D = RL(_D);
        tmp = _SRL(_SgetD());
        _SsetD(tmp);
        break;
      case 0x13: // RL E
        //      _E = RL(_E);
        tmp = _SRL(_SgetE());
        _SsetE(tmp);
        break;
      case 0x14: // RL H
        //      _H = RL(_H);
        tmp = _SRL(_SgetH());
        _SsetH(tmp);
        break;
      case 0x15: // RL L
        //      _L = RL(_L);
        tmp = _SRL(_SgetL());
        _SsetL(tmp);
        break;
      case 0x16: // RL (HL)
        //      WriteMemory(HL, RL(ReadMemory(HL)));
        tmp = _SRL(_SREADM8(_SHL));
        mem.write(_SHL, tmp);
        break;
      case 0x17: // RL A
        //      _A = RL(_A);
        _A = _SRL(_A);
        break;

      case 0x18: // RR B
        //      _B = RR(_B);
        tmp = _SRR(_SgetB());
        _SsetB(tmp);
        break;
      case 0x19: // RR C
        //      _C = RR(_C);
        tmp = _SRR(_SgetC());
        _SsetC(tmp);
        break;
      case 0x1a: // RR D
        //      _D = RR(_D);
        tmp = _SRR(_SgetD());
        _SsetD(tmp);
        break;
      case 0x1b: // RR E
        //      _E = RR(_E);
        tmp = _SRR(_SgetE());
        _SsetE(tmp);
        break;
      case 0x1c: // RR H
        //      _H = RR(_H);
        tmp = _SRR(_SgetH());
        _SsetH(tmp);
        break;
      case 0x1d: // RR L
        //      _L = RR(_L);
        tmp = _SRR(_SgetL());
        _SsetL(tmp);
        break;
      case 0x1e: // RR (HL)
        //      WriteMemory(HL, RR(ReadMemory(HL)));
        tmp = _SRR(_SREADM8(_SHL));
        mem.write(_SHL, tmp);
        break;
      case 0x1f: // RR A
        //      _A = RR(_A);
        _A = _SRR(_A);
        break;

      case 0x20: // SLA B
        //      _B = SLA(_B);
        tmp = _SSLA(_SgetB());
        _SsetB(tmp);
        break;
      case 0x21: // SLA C
        //      _C = SLA(_C);
        tmp = _SSLA(_SgetC());
        _SsetC(tmp);
        break;
      case 0x22: // SLA D
        //      _D = SLA(_D);
        tmp = _SSLA(_SgetD());
        _SsetD(tmp);
        break;
      case 0x23: // SLA E
        //      _E = SLA(_E);
        tmp = _SSLA(_SgetE());
        _SsetE(tmp);
        break;
      case 0x24: // SLA H
        //      _H = SLA(_H);
        tmp = _SSLA(_SgetH());
        _SsetH(tmp);
        break;
      case 0x25: // SLA L
        //      _L = SLA(_L);
        tmp = _SSLA(_SgetL());
        _SsetL(tmp);
        break;
      case 0x26: // SLA (HL)
        //      WriteMemory(HL, SLA(ReadMemory(HL)));
        tmp = _SSLA(_SREADM8(_SHL));
        mem.write(_SHL, tmp);
        break;
      case 0x27: // SLA A
        //      _A = SLA(_A);
        _A = _SSLA(_A);
        break;

      case 0x28: // SRA B
        //      _B = SRA(_B);
        tmp = _SSRA(_SgetB());
        _SsetB(tmp);
        break;
      case 0x29: // SRA C
        //      _C = SRA(_C);
        tmp = _SSRA(_SgetC());
        _SsetC(tmp);
        break;
      case 0x2a: // SRA D
        //      _D = SRA(_D);
        tmp = _SSRA(_SgetD());
        _SsetD(tmp);
        break;
      case 0x2b: // SRA E
        //      _E = SRA(_E);
        tmp = _SSRA(_SgetE());
        _SsetE(tmp);
        break;
      case 0x2c: // SRA H
        //      _H = SRA(_H);
        tmp = _SSRA(_SgetH());
        _SsetH(tmp);
        break;
      case 0x2d: // SRA L
        //      _L = SRA(_L);
        tmp = _SSRA(_SgetL());
        _SsetL(tmp);
        break;
      case 0x2e: // SRA (HL)
        //      WriteMemory(HL, SRA(ReadMemory(HL)));
        tmp = _SSRA(_SREADM8(_SHL));
        mem.write(_SHL, tmp);
        break;
      case 0x2f: // SRA A
        //      _A = SRA(_A);
        _A = _SSRA(_A);
        break;

      case 0x30: // SLL B
        //      _B = SLL(_B);
        tmp = _SSLL(_SgetB());
        _SsetB(tmp);
        break;
      case 0x31: // SLL C
        //      _C = SLL(_C);
        tmp = _SSLL(_SgetC());
        _SsetC(tmp);
        break;
      case 0x32: // SLL D
        //      _D = SLL(_D);
        tmp = _SSLL(_SgetD());
        _SsetD(tmp);
        break;
      case 0x33: // SLL E
        //      _E = SLL(_E);
        tmp = _SSLL(_SgetE());
        _SsetE(tmp);
        break;
      case 0x34: // SLL H
        //      _H = SLL(_H);
        tmp = _SSLL(_SgetH());
        _SsetH(tmp);
        break;
      case 0x35: // SLL L
        //      _L = SLL(_L);
        tmp = _SSLL(_SgetL());
        _SsetL(tmp);
        break;
      case 0x36: // SLL (HL)
        //      WriteMemory(HL, SLL(ReadMemory(HL)));
        tmp = _SSLL(_SREADM8(_SHL));
        mem.write(_SHL, tmp);
        break;
      case 0x37: // SLL A
        //      _A = SLL(_A);
        _A = _SSLL(_A);
        break;

      case 0x38: // SRL B
        //      _B = SRL(_B);
        tmp = _SSRL(_SgetB());
        _SsetB(tmp);
        break;
      case 0x39: // SRL C
        //      _C = SRL(_C);
        tmp = _SSRL(_SgetC());
        _SsetC(tmp);
        break;
      case 0x3a: // SRL D
        //      _D = SRL(_D);
        tmp = _SSRL(_SgetD());
        _SsetD(tmp);
        break;
      case 0x3b: // SRL E
        //      _E = SRL(_E);
        tmp = _SSRL(_SgetE());
        _SsetE(tmp);
        break;
      case 0x3c: // SRL H
        //      _H = SRL(_H);
        tmp = _SSRL(_SgetH());
        _SsetH(tmp);
        break;
      case 0x3d: // SRL L
        //      _L = SRL(_L);
        tmp = _SSRL(_SgetL());
        _SsetL(tmp);
        break;
      case 0x3e: // SRL (HL)
        //			WriteMemory(HL, SRL(ReadMemory(HL)));
        tmp = _SSRL(_SREADM8(_SHL));
        mem.write(_SHL, tmp);
        break;
      case 0x3f: // SRL A
        //			_A = SRL(_A);
        _A = _SSRL(_A);
        break;

      case 0x40: // BIT 0, B
        //      BIT(0, _B);
        _SBIT(0, _SgetB());
        break;
      case 0x41: // BIT 0, C
        //      BIT(0, _C);
        _SBIT(0, _SgetC());
        break;
      case 0x42: // BIT 0, D
        //      BIT(0, _D);
        _SBIT(0, _SgetD());
        break;
      case 0x43: // BIT 0, E
        //      BIT(0, _E);
        _SBIT(0, _SgetE());
        break;
      case 0x44: // BIT 0, H
        //      BIT(0, _H);
        _SBIT(0, _SgetH());
        break;
      case 0x45: // BIT 0, L
        //      BIT(0, _L);
        _SBIT(0, _SgetL());
        break;
      case 0x46: // BIT 0, (HL)
        //      BIT(0, ReadMemory(HL));
        _SBIT(0, _SREADM8(_SHL));
        break;
      case 0x47: // BIT 0, A
        //      BIT(0, _A);
        _SBIT(0, _A);
        break;

      case 0x48: // BIT 1, B
        //      BIT(1, _B);
        _SBIT(1, _SgetB());
        break;
      case 0x49: // BIT 1, C
        //      BIT(1, _C);
        _SBIT(1, _SgetC());
        break;
      case 0x4a: // BIT 1, D
        //      BIT(1, _D);
        _SBIT(1, _SgetD());
        break;
      case 0x4b: // BIT 1, E
        //      BIT(1, _E);
        _SBIT(1, _SgetE());
        break;
      case 0x4c: // BIT 1, H
        //      BIT(1, _H);
        _SBIT(1, _SgetH());
        break;
      case 0x4d: // BIT 1, L
        //      BIT(1, _L);
        _SBIT(1, _SgetL());
        break;
      case 0x4e: // BIT 1, (HL)
        //      BIT(1, ReadMemory(HL));
        _SBIT(1, _SREADM8(_SHL));
        break;
      case 0x4f: // BIT 1, A
        //      BIT(1, _A);
        _SBIT(1, _A);
        break;

      case 0x50: // BIT 2, B
        //      BIT(2, _B);
        _SBIT(2, _SgetB());
        break;
      case 0x51: // BIT 2, C
        //      BIT(2, _C);
        _SBIT(2, _SgetC());
        break;
      case 0x52: // BIT 2, D
        //      BIT(2, _D);
        _SBIT(2, _SgetD());
        break;
      case 0x53: // BIT 2, E
        //      BIT(2, _E);
        _SBIT(2, _SgetE());
        break;
      case 0x54: // BIT 2, H
        //      BIT(2, _H);
        _SBIT(2, _SgetH());
        break;
      case 0x55: // BIT 2, L
        //      BIT(2, _L);
        _SBIT(2, _SgetL());
        break;
      case 0x56: // BIT 2, (HL)
        //      BIT(2, ReadMemory(HL));
        _SBIT(2, _SREADM8(_SHL));
        break;
      case 0x57: // BIT 2, A
        //      BIT(2, _A);
        _SBIT(2, _A);
        break;

      case 0x58: // BIT 3, B
        //      BIT(3, _B);
        _SBIT(3, _SgetB());
        break;
      case 0x59: // BIT 3, C
        //      BIT(3, _C);
        _SBIT(3, _SgetC());
        break;
      case 0x5a: // BIT 3, D
        //      BIT(3, _D);
        _SBIT(3, _SgetD());
        break;
      case 0x5b: // BIT 3, E
        //      BIT(3, _E);
        _SBIT(3, _SgetE());
        break;
      case 0x5c: // BIT 3, H
        //      BIT(3, _H);
        _SBIT(3, _SgetH());
        break;
      case 0x5d: // BIT 3, L
        //      BIT(3, _L);
        _SBIT(3, _SgetL());
        break;
      case 0x5e: // BIT 3, (HL)
        //      BIT(3, ReadMemory(HL));
        _SBIT(3, _SREADM8(_SHL));
        break;
      case 0x5f: // BIT 3, A
        //      BIT(3, _A);
        _SBIT(3, _A);
        break;

      case 0x60: // BIT 4, B
        //      BIT(4, _B);
        _SBIT(4, _SgetB());
        break;
      case 0x61: // BIT 4, C
        //      BIT(4, _C);
        _SBIT(4, _SgetC());
        break;
      case 0x62: // BIT 4, D
        //      BIT(4, _D);
        _SBIT(4, _SgetD());
        break;
      case 0x63: // BIT 4, E
        //      BIT(4, _E);
        _SBIT(4, _SgetE());
        break;
      case 0x64: // BIT 4, H
        //      BIT(4, _H);
        _SBIT(4, _SgetH());
        break;
      case 0x65: // BIT 4, L
        //      BIT(4, _L);
        _SBIT(4, _SgetL());
        break;
      case 0x66: // BIT 4, (HL)
        //      BIT(4, ReadMemory(HL));
        _SBIT(4, _SREADM8(_SHL));
        break;
      case 0x67: // BIT 4, A
        //      BIT(4, _A);
        _SBIT(4, _A);
        break;

      case 0x68: // BIT 5, B
        //      BIT(5, _B);
        _SBIT(5, _SgetB());
        break;
      case 0x69: // BIT 5, C
        //      BIT(5, _C);
        _SBIT(5, _SgetC());
        break;
      case 0x6a: // BIT 5, D
        //      BIT(5, _D);
        _SBIT(5, _SgetD());
        break;
      case 0x6b: // BIT 5, E
        //      BIT(5, _E);
        _SBIT(5, _SgetE());
        break;
      case 0x6c: // BIT 5, H
        //      BIT(5, _H);
        _SBIT(5, _SgetH());
        break;
      case 0x6d: // BIT 5, L
        //      BIT(5, _L);
        _SBIT(5, _SgetL());
        break;
      case 0x6e: // BIT 5, (HL)
        //      BIT(5, ReadMemory(HL));
        _SBIT(5, _SREADM8(_SHL));
        break;
      case 0x6f: // BIT 5, A
        //      BIT(5, _A);
        _SBIT(5, _A);
        break;

      case 0x70: // BIT 6, B
        //      BIT(6, _B);
        _SBIT(6, _SgetB());
        break;
      case 0x71: // BIT 6, C
        //      BIT(6, _C);
        _SBIT(6, _SgetC());
        break;
      case 0x72: // BIT 6, D
        //      BIT(6, _D);
        _SBIT(6, _SgetD());
        break;
      case 0x73: // BIT 6, E
        //      BIT(6, _E);
        _SBIT(6, _SgetE());
        break;
      case 0x74: // BIT 6, H
        //      BIT(6, _H);
        _SBIT(6, _SgetH());
        break;
      case 0x75: // BIT 6, L
        //      BIT(6, _L);
        _SBIT(6, _SgetL());
        break;
      case 0x76: // BIT 6, (HL)
        //      BIT(6, ReadMemory(HL));
        _SBIT(6, _SREADM8(_SHL));
        break;
      case 0x77: // BIT 6, A
        //      BIT(6, _A);
        _SBIT(6, _A);
        break;

      case 0x78: // BIT 7, B
        //      BIT(7, _B);
        _SBIT(7, _SgetB());
        break;
      case 0x79: // BIT 7, C
        //      BIT(7, _C);
        _SBIT(7, _SgetC());
        break;
      case 0x7a: // BIT 7, D
        //      BIT(7, _D);
        _SBIT(7, _SgetD());
        break;
      case 0x7b: // BIT 7, E
        //      BIT(7, _E);
        _SBIT(7, _SgetE());
        break;
      case 0x7c: // BIT 7, H
        //      BIT(7, _H);
        _SBIT(7, _SgetH());
        break;
      case 0x7d: // BIT 7, L
        //      BIT(7, _L);
        _SBIT(7, _SgetL());
        break;
      case 0x7e: // BIT 7, (HL)
        //      BIT(7, ReadMemory(HL));
        _SBIT(7, _SREADM8(_SHL));
        break;
      case 0x7f: // BIT 7, A
        //      BIT(7, _A);
        _SBIT(7, _A);
        break;

      case 0x80: // RES 0, B
        //      _B = RES(0, _B);
        _SsetB(_SRES(0, _SgetB()));
        break;
      case 0x81: // RES 0, C
        //      _C = RES(0, _C);
        _SsetC(_SRES(0, _SgetC()));
        break;
      case 0x82: // RES 0, D
        //      _D = RES(0, _D);
        _SsetD(_SRES(0, _SgetD()));
        break;
      case 0x83: // RES 0, E
        //      _E = RES(0, _E);
        _SsetE(_SRES(0, _SgetE()));
        break;
      case 0x84: // RES 0, H
        //      _H = RES(0, _H);
        _SsetH(_SRES(0, _SgetH()));
        break;
      case 0x85: // RES 0, L
        //      _L = RES(0, _L);
        _SsetL(_SRES(0, _SgetL()));
        break;
      case 0x86: // RES 0, (HL)
        //      WriteMemory(HL, RES(0, ReadMemory(HL)));
        mem.write(_SHL,_SRES(0, _SREADM8(_SHL)));
        break;
      case 0x87: // RES 0, A
        //      _A = RES(0, _A);
        _A = (_SRES(0, _A));
        break;

      case 0x88: // RES 1, B
        //      _B = RES(1, _B);
        _SsetB(_SRES(1, _SgetB()));
        break;
      case 0x89: // RES 1, C
        //      _C = RES(1, _C);
        _SsetC(_SRES(1, _SgetC()));
        break;
      case 0x8a: // RES 1, D
        //      _D = RES(1, _D);
        _SsetD(_SRES(1, _SgetD()));
        break;
      case 0x8b: // RES 1, E
        //      _E = RES(1, _E);
        _SsetE(_SRES(1, _SgetE()));
        break;
      case 0x8c: // RES 1, H
        //      _H = RES(1, _H);
        _SsetH(_SRES(1, _SgetH()));
        break;
      case 0x8d: // RES 1, L
        //			_L = RES(1, _L);
        _SsetL(_SRES(1, _SgetL()));
        break;
      case 0x8e: // RES 1, (HL)
        //      WriteMemory(HL, RES(1, ReadMemory(HL)));
        mem.write(_SHL,_SRES(1, _SREADM8(_SHL)));
        break;
      case 0x8f: // RES 1, A
        //      _A = RES(1, _A);
        _A = (_SRES(1, _A));
        break;

      case 0x90: // RES 2, B
        //      _B = RES(2, _B);
        _SsetB(_SRES(2, _SgetB()));
        break;
      case 0x91: // RES 2, C
        //      _C = RES(2, _C);
        _SsetC(_SRES(2, _SgetC()));
        break;
      case 0x92: // RES 2, D
        //      _D = RES(2, _D);
        _SsetD(_SRES(2, _SgetD()));
        break;
      case 0x93: // RES 2, E
        //      _E = RES(2, _E);
        _SsetE(_SRES(2, _SgetE()));
        break;
      case 0x94: // RES 2, H
        //      _H = RES(2, _H);
        _SsetH(_SRES(2, _SgetH()));
        break;
      case 0x95: // RES 2, L
        //      _L = RES(2, _L);
        _SsetL(_SRES(2, _SgetL()));
        break;
      case 0x96: // RES 2, (HL)
        //      WriteMemory(HL, RES(2, ReadMemory(HL)));
        mem.write(_SHL,_SRES(2, _SREADM8(_SHL)));
        break;
      case 0x97: // RES 2, A
        //      _A = RES(2, _A);
        _A = (_SRES(2, _A));
        break;

      case 0x98: // RES 3, B
        //      _B = RES(3, _B);
        _SsetB(_SRES(3, _SgetB()));
        break;
      case 0x99: // RES 3, C
        //      _C = RES(3, _C);
        _SsetC(_SRES(3, _SgetC()));
        break;
      case 0x9a: // RES 3, D
        //      _D = RES(3, _D);
        _SsetD(_SRES(3, _SgetD()));
        break;
      case 0x9b: // RES 3, E
        //      _E = RES(3, _E);
        _SsetE(_SRES(3, _SgetE()));
        break;
      case 0x9c: // RES 3, H
        //      _H = RES(3, _H);
        _SsetH(_SRES(3, _SgetH()));
        break;
      case 0x9d: // RES 3, L
        //      _L = RES(3, _L);
        _SsetL(_SRES(3, _SgetL()));
        break;
      case 0x9e: // RES 3, (HL)
        //      WriteMemory(HL, RES(3, ReadMemory(HL)));
        mem.write(_SHL,_SRES(3, _SREADM8(_SHL)));
        break;
      case 0x9f: // RES 3, A
        //      _A = RES(3, _A);
        _A = (_SRES(3, _A));
        break;

      case 0xa0: // RES 4, B
        //      _B = RES(4, _B);
        _SsetB(_SRES(4, _SgetB()));
        break;
      case 0xa1: // RES 4, C
        //      _C = RES(4, _C);
        _SsetC(_SRES(4, _SgetC()));
        break;
      case 0xa2: // RES 4, D
        //      _D = RES(4, _D);
        _SsetD(_SRES(4, _SgetD()));
        break;
      case 0xa3: // RES 4, E
        //      _E = RES(4, _E);
        _SsetE(_SRES(4, _SgetE()));
        break;
      case 0xa4: // RES 4, H
        //      _H = RES(4, _H);
        _SsetH(_SRES(4, _SgetH()));
        break;
      case 0xa5: // RES 4, L
        //      _L = RES(4, _L);
        _SsetL(_SRES(4, _SgetL()));
        break;
      case 0xa6: // RES 4, (HL)
        //      WriteMemory(HL, RES(4, ReadMemory(HL)));
        mem.write(_SHL,_SRES(4, _SREADM8(_SHL)));
        break;
      case 0xa7: // RES 4, A
        //      _A = RES(4, _A);
        _A = (_SRES(4, _A));
        break;

      case 0xa8: // RES 5, B
        //      _B = RES(5, _B);
        _SsetB(_SRES(5, _SgetB()));
        break;
      case 0xa9: // RES 5, C
        //      _C = RES(5, _C);
        _SsetC(_SRES(5, _SgetC()));
        break;
      case 0xaa: // RES 5, D
        //      _D = RES(5, _D);
        _SsetD(_SRES(5, _SgetD()));
        break;
      case 0xab: // RES 5, E
        //      _E = RES(5, _E);
        _SsetE(_SRES(5, _SgetE()));
        break;
      case 0xac: // RES 5, H
        //      _H = RES(5, _H);
        _SsetH(_SRES(5, _SgetH()));
        break;
      case 0xad: // RES 5, L
        //      _L = RES(5, _L);
        _SsetL(_SRES(5, _SgetL()));
        break;
      case 0xae: // RES 5, (HL)
        //      WriteMemory(HL, RES(5, ReadMemory(HL)));
        mem.write(_SHL,_SRES(5, _SREADM8(_SHL)));
        break;
      case 0xaf: // RES 5, A
        //      _A = RES(5, _A);
        _A = (_SRES(5, _A));
        break;

      case 0xb0: // RES 6, B
        //      _B = RES(6, _B);
        _SsetB(_SRES(6, _SgetB()));
        break;
      case 0xb1: // RES 6, C
        //      _C = RES(6, _C);
        _SsetC(_SRES(6, _SgetC()));
        break;
      case 0xb2: // RES 6, D
        //      _D = RES(6, _D);
        _SsetD(_SRES(6, _SgetD()));
        break;
      case 0xb3: // RES 6, E
        //      _E = RES(6, _E);
        _SsetE(_SRES(6, _SgetE()));
        break;
      case 0xb4: // RES 6, H
        //      _H = RES(6, _H);
        _SsetH(_SRES(6, _SgetH()));
        break;
      case 0xb5: // RES 6, L
        //      _L = RES(6, _L);
        _SsetL(_SRES(6, _SgetL()));
        break;
      case 0xb6: // RES 6, (HL)
        //      WriteMemory(HL, RES(6, ReadMemory(HL)));
        mem.write(_SHL,_SRES(6, _SREADM8(_SHL)));
        break;
      case 0xb7: // RES 6, A
        //      _A = RES(6, _A);
        _A = (_SRES(6, _A));
        break;

      case 0xb8: // RES 7, B
        //      _B = RES(7, _B);
        _SsetB(_SRES(7, _SgetB()));
        break;
      case 0xb9: // RES 7, C
        //      _C = RES(7, _C);
        _SsetC(_SRES(7, _SgetC()));
        break;
      case 0xba: // RES 7, D
        //      _D = RES(7, _D);
        _SsetD(_SRES(7, _SgetD()));
        break;
      case 0xbb: // RES 7, E
        //      _E = RES(7, _E);
        _SsetE(_SRES(7, _SgetE()));
        break;
      case 0xbc: // RES 7, H
        //      _H = RES(7, _H);
        _SsetH(_SRES(7, _SgetH()));
        break;
      case 0xbd: // RES 7, L
        //      _L = RES(7, _L);
        _SsetL(_SRES(7, _SgetL()));
        break;
      case 0xbe: // RES 7, (HL)
        //      WriteMemory(HL, RES(7, ReadMemory(HL)));
        mem.write(_SHL,_SRES(7, _SREADM8(_SHL)));
        break;
      case 0xbf: // RES 7, A
        //      _A = RES(7, _A);
        _A = (_SRES(7, _A));
        break;

      case 0xc0: // SET 0, B
        //      _B = SET(0, _B);
        _SsetB(_SSET(0, _SgetB()));
        break;
      case 0xc1: // SET 0, C
        //      _C = SET(0, _C);
        _SsetC(_SSET(0, _SgetC()));
        break;
      case 0xc2: // SET 0, D
        //      _D = SET(0, _D);
        _SsetD(_SSET(0, _SgetD()));
        break;
      case 0xc3: // SET 0, E
        //      _E = SET(0, _E);
        _SsetE(_SSET(0, _SgetE()));
        break;
      case 0xc4: // SET 0, H
        //      _H = SET(0, _H);
        _SsetH(_SSET(0, _SgetH()));
        break;
      case 0xc5: // SET 0, L
        //      _L = SET(0, _L);
        _SsetL(_SSET(0, _SgetL()));
        break;
      case 0xc6: // SET 0, (HL)
        //      WriteMemory(HL, SET(0, ReadMemory(HL)));
        mem.write(_SHL,_SSET(0, _SREADM8(_SHL)));
        break;
      case 0xc7: // SET 0, A
        //      _A = SET(0, _A);
        _A = (_SSET(0, _A));
        break;

      case 0xc8: // SET 1, B
        //      _B = SET(1, _B);
        _SsetB(_SSET(1, _SgetB()));
        break;
      case 0xc9: // SET 1, C
        //      _C = SET(1, _C);
        _SsetC(_SSET(1, _SgetC()));
        break;
      case 0xca: // SET 1, D
        //      _D = SET(1, _D);
        _SsetD(_SSET(1, _SgetD()));
        break;
      case 0xcb: // SET 1, E
        //      _E = SET(1, _E);
        _SsetE(_SSET(1, _SgetE()));
        break;
      case 0xcc: // SET 1, H
        //      _H = SET(1, _H);
        _SsetH(_SSET(1, _SgetH()));
        break;
      case 0xcd: // SET 1, L
        //      _L = SET(1, _L);
        _SsetL(_SSET(1, _SgetL()));
        break;
      case 0xce: // SET 1, (HL)
        //      WriteMemory(HL, SET(1, ReadMemory(HL)));
        mem.write(_SHL,_SSET(1, _SREADM8(_SHL)));
        break;
      case 0xcf: // SET 1, A
        //      _A = SET(1, _A);
        _A = (_SSET(1, _A));
        break;

      case 0xd0: // SET 2, B
        //      _B = SET(2, _B);
        _SsetB(_SSET(2, _SgetB()));
        break;
      case 0xd1: // SET 2, C
        //      _C = SET(2, _C);
        _SsetC(_SSET(2, _SgetC()));
        break;
      case 0xd2: // SET 2, D
        //      _D = SET(2, _D);
        _SsetD(_SSET(2, _SgetD()));
        break;
      case 0xd3: // SET 2, E
        //      _E = SET(2, _E);
        _SsetE(_SSET(2, _SgetE()));
        break;
      case 0xd4: // SET 2, H
        //      _H = SET(2, _H);
        _SsetH(_SSET(2, _SgetH()));
        break;
      case 0xd5: // SET 2, L
        //      _L = SET(2, _L);
        _SsetL(_SSET(2, _SgetL()));
        break;
      case 0xd6: // SET 2, (HL)
        //      WriteMemory(HL, SET(2, ReadMemory(HL)));
        mem.write(_SHL,_SSET(2, _SREADM8(_SHL)));
        break;
      case 0xd7: // SET 2, A
        //      _A = SET(2, _A);
        _A = (_SSET(2, _A));
        break;

      case 0xd8: // SET 3, B
        //      _B = SET(3, _B);
        _SsetB(_SSET(3, _SgetB()));
        break;
      case 0xd9: // SET 3, C
        //      _C = SET(3, _C);
        _SsetC(_SSET(3, _SgetC()));
        break;
      case 0xda: // SET 3, D
        //      _D = SET(3, _D);
        _SsetD(_SSET(3, _SgetD()));
        break;
      case 0xdb: // SET 3, E
        //      _E = SET(3, _E);
        _SsetE(_SSET(3, _SgetE()));
        break;
      case 0xdc: // SET 3, H
        //      _H = SET(3, _H);
        _SsetH(_SSET(3, _SgetH()));
        break;
      case 0xdd: // SET 3, L
        //      _L = SET(3, _L);
        _SsetL(_SSET(3, _SgetL()));
        break;
      case 0xde: // SET 3, (HL)
        //      WriteMemory(HL, SET(3, ReadMemory(HL)));
        mem.write(_SHL,_SSET(3, _SREADM8(_SHL)));
        break;
      case 0xdf: // SET 3, A
        //      _A = SET(3, _A);
        _A = (_SSET(3, _A));
        break;

      case 0xe0: // SET 4, B
        //      _B = SET(4, _B);
        _SsetB(_SSET(4, _SgetB()));
        break;
      case 0xe1: // SET 4, C
        //      _C = SET(4, _C);
        _SsetC(_SSET(4, _SgetC()));
        break;
      case 0xe2: // SET 4, D
        //      _D = SET(4, _D);
        _SsetD(_SSET(4, _SgetD()));
        break;
      case 0xe3: // SET 4, E
        //      _E = SET(4, _E);
        _SsetE(_SSET(4, _SgetE()));
        break;
      case 0xe4: // SET 4, H
        //      _H = SET(4, _H);
        _SsetH(_SSET(4, _SgetH()));
        break;
      case 0xe5: // SET 4, L
        //      _L = SET(4, _L);
        _SsetL(_SSET(4, _SgetL()));
        break;
      case 0xe6: // SET 4, (HL)
        //      WriteMemory(HL, SET(4, ReadMemory(HL)));
        mem.write(_SHL,_SSET(4, _SREADM8(_SHL)));
        break;
      case 0xe7: // SET 4, A
        //      _A = SET(4, _A);
        _A = (_SSET(4, _A));
        break;

      case 0xe8: // SET 5, B
        //      _B = SET(5, _B);
        _SsetB(_SSET(5, _SgetB()));
        break;
      case 0xe9: // SET 5, C
        //      _C = SET(5, _C);
        _SsetC(_SSET(5, _SgetC()));
        break;
      case 0xea: // SET 5, D
        //      _D = SET(5, _D);
        _SsetD(_SSET(5, _SgetD()));
        break;
      case 0xeb: // SET 5, E
        //      _E = SET(5, _E);
        _SsetE(_SSET(5, _SgetE()));
        break;
      case 0xec: // SET 5, H
        //      _H = SET(5, _H);
        _SsetH(_SSET(5, _SgetH()));
        break;
      case 0xed: // SET 5, L
        //      _L = SET(5, _L);
        _SsetL(_SSET(5, _SgetL()));
        break;
      case 0xee: // SET 5, (HL)
        //      WriteMemory(HL, SET(5, ReadMemory(HL)));
        mem.write(_SHL,_SSET(5, _SREADM8(_SHL)));
        break;
      case 0xef: // SET 5, A
        //      _A = SET(5, _A);
        _A = (_SSET(5, _A));
        break;

      case 0xf0: // SET 6, B
        //      _B = SET(6, _B);
        _SsetB(_SSET(6, _SgetB()));
        break;
      case 0xf1: // SET 6, C
        //      _C = SET(6, _C);
        _SsetC(_SSET(6, _SgetC()));
        break;
      case 0xf2: // SET 6, D
        //      _D = SET(6, _D);
        _SsetD(_SSET(6, _SgetD()));
        break;
      case 0xf3: // SET 6, E
        //      _E = SET(6, _E);
        _SsetE(_SSET(6, _SgetE()));
        break;
      case 0xf4: // SET 6, H
        //      _H = SET(6, _H);
        _SsetH(_SSET(6, _SgetH()));
        break;
      case 0xf5: // SET 6, L
        //      _L = SET(6, _L);
        _SsetL(_SSET(6, _SgetL()));
        break;
      case 0xf6: // SET 6, (HL)
        //      WriteMemory(HL, SET(6, ReadMemory(HL)));
        mem.write(_SHL,_SSET(6, _SREADM8(_SHL)));
        break;
      case 0xf7: // SET 6, A
        //      _A = SET(6, _A);
        _A = (_SSET(6, _A));
        break;

      case 0xf8: // SET 7, B
        //      _B = SET(7, _B);
        _SsetB(_SSET(7, _SgetB()));
        break;
      case 0xf9: // SET 7, C
        //      _C = SET(7, _C);
        _SsetC(_SSET(7, _SgetC()));
        break;
      case 0xfa: // SET 7, D
        //      _D = SET(7, _D);
        _SsetD(_SSET(7, _SgetD()));
        break;
      case 0xfb: // SET 7, E
        //      _E = SET(7, _E);
        _SsetE(_SSET(7, _SgetE()));
        break;
      case 0xfc: // SET 7, H
        //      _H = SET(7, _H);
        _SsetH(_SSET(7, _SgetH()));
        break;
      case 0xfd: // SET 7, L
        //      _L = SET(7, _L);
        _SsetL(_SSET(7, _SgetL()));
        break;
      case 0xfe: // SET 7, (HL)
        //      WriteMemory(HL, SET(7, ReadMemory(HL)));
        mem.write(_SHL,_SSET(7, _SREADM8(_SHL)));
        break;
      case 0xff: // SET 7, A
        //      _A = SET(7, _A);
        _A = (_SSET(7, _A));
        break;

      default:
        trace(strHex(_SPC-1,4)+": CB:未定義 "+strHex(code, 2));
//        Console.WriteLine("{0:4X}: CB:未定義 {1:2X}", _SPC-1, code);
        break;
      }
    }

    private function _ScodeDD() : void {
      // 命令の実行
      var code: int = _SREADM_PC();
      //    _Sscount -= cc_xy[code];
      _Sstate_count(cc_xy[code]);
      _R = (_R & 0x80) | ((_R + 1) & 0x7f);

      switch(code) {
      case 0x09: // ADD IX, BC
        _SIX = _SADD16(_SIX, _SBC);
        break;
      case 0x19: // ADD IX, DE
        _SIX = _SADD16(_SIX, _SDE);
        break;
      case 0x21: // LD IX, w
        //      _SIX = ReadMemory16(_SPC);
        _SIX = _SREADM16(_SPC);
        _SPC += 2;
        break;
      case 0x22: // LD (w), IX
        //      EA = ReadMemory16(PC);
        _SEA = _SREADM16(_SPC);
        _SPC += 2;
        //      WriteMemory16(EA, IX);
        _SWRITEM16(_SEA, _SIX);
        break;
      case 0x23: // INC IX
        ++_SIX;
        _SIX &= 0xFFFF;
        break;
      case 0x24: // INC HX
        //      _XH = INC(_XH);
        _SsetXH(_SINC(_SgetXH()));
        break;
      case 0x25: // DEC HX
        //      _XH = DEC(_XH);
        _SsetXH(_SDEC(_SgetXH()));
        break;
      case 0x26: // LD HX, n
        //      _XH = ReadMemory(PC++);
        _SsetXH(_SREADM_PC());
        break;
      case 0x29: // ADD IX, IX
        _SIX = _SADD16(_SIX, _SIX);
        break;
      case 0x2a: // LD IX, (w)
        //      EA = ReadMemory16(PC);
        //      PC += 2;
        //      IX = ReadMemory16(EA);
        _SEA = _SREADM16(_SPC);
        _SPC += 2;
        _SIX = _SREADM16(_SEA);
        break;
      case 0x2b: // DEC IX
        --_SIX;
        _SIX &= 0xFFFF;
        break;
      case 0x2c: // INC LX
        //      _XL = INC(_XL);
        _SsetXL(_SINC(_SgetXL()));
        break;
      case 0x2d: // DEC LX
        //      _XL = DEC(_XL);
        _SsetXL(_SDEC(_SgetXL()));
        break;
      case 0x2e: // LD LX, n
        //      _XL = ReadMemory(PC++);
        _SsetXL(_SREADM_PC());
        break;
      case 0x34: // INC (IX+o)
        _SEAX();
        //      WriteMemory(EA, INC(ReadMemory(EA)));
        _SWRITEM(_SEA, _SINC(_SREADM8(_SEA)));
        break;
      case 0x35: // DEC (IX+o)
        _SEAX();
        //      WriteMemory(EA, DEC(ReadMemory(EA)));
        _SWRITEM(_SEA, _SDEC(_SREADM8(_SEA)));
        break;
      case 0x36: // LD (IX+o), n
        _SEAX();
        //      WriteMemory(EA, ReadMemory(PC++));
        _SWRITEM(_SEA, _SREADM_PC());
        break;
      case 0x39: // ADD IX, SP
        _SIX = _SADD16(_SIX, _SSP);
        break;
      case 0x44: // LD B, HX
        //      _B = _XH;
        _SsetB(_SgetXH());
        break;
      case 0x45: // LD B, LX
        //     _B = _XL;
        _SsetB(_SgetXL());
        break;
      case 0x46: // LD B, (IX+o)
        _SEAX();
        //      _B = ReadMemory(EA);
        _SsetB(_SREADM8(_SEA));
        break;
      case 0x4c: // LD C, HX
        //      _C = _XH;
        _SsetC(_SgetXH());
        break;
      case 0x4d: // LD C, LX
        //      _C = _XL;
        _SsetC(_SgetXL());
        break;
      case 0x4e: // LD C, (IX+o)
        _SEAX();
        //      _C = ReadMemory(EA);
        _SsetC(_SREADM8(_SEA));
        break;
      case 0x54: // LD D, HX
        //      _D = _XH;
        _SsetD(_SgetXH());
        break;
      case 0x55: // LD D, LX
        //      _D = _XL;
        _SsetD(_SgetXL());
        break;
      case 0x56: // LD D, (IX+o)
        _SEAX();
        //      _D = ReadMemory(EA);
        _SsetD(_SREADM8(_SEA));
        break;
      case 0x5c: // LD E, HX
        //      _E = _XH;
        _SsetE(_SgetXH());
        break;
      case 0x5d: // LD E, LX
        //      _E = _XL;
        _SsetE(_SgetXL());
        break;
      case 0x5e: // LD E, (IX+o)
        _SEAX();
        //      _E = ReadMemory(EA);
        _SsetE(_SREADM8(_SEA));
        break;
      case 0x60: // LD HX, B
        //      _XH = _B;
        _SsetXH(_SgetB());
        break;
      case 0x61: // LD HX, C
        //      _XH = _C;
        _SsetXH(_SgetC());
        break;
      case 0x62: // LD HX, D
        //      _XH = _D;
        _SsetXH(_SgetD());
        break;
      case 0x63: // LD HX, E
        //      _XH = _E;
        _SsetXH(_SgetE());
        break;
      case 0x64: // LD HX, HX
        break;
      case 0x65: // LD HX, LX
        //      _XH = _XL;
        _SsetXH(_SgetXL());
        break;
      case 0x66: // LD H, (IX+o)
        _SEAX();
        //      _H = ReadMemory(EA);
        _SsetH(_SREADM8(_SEA));
        break;
      case 0x67: // LD HX, A
        //      _XH = _A;
        _SsetXH(_A);
        break;
      case 0x68: // LD LX, B
        //      _XL = _B;
        _SsetXL(_SgetB());
        break;
      case 0x69: // LD LX, C
        //      _XL = _C;
        _SsetXL(_SgetC());
        break;
      case 0x6a: // LD LX, D
        //      _XL = _D;
        _SsetXL(_SgetD());
        break;
      case 0x6b: // LD LX, E
        //      _XL = _E;
        _SsetXL(_SgetE());
        break;
      case 0x6c: // LD LX, HX
        //      _XL = _XH;
        _SsetXL(_SgetXH());
        break;
      case 0x6d: // LD LX, LX
        break;
      case 0x6e: // LD L, (IX+o)
        _SEAX();
        //      _L = ReadMemory(EA);
        _SsetL(_SREADM8(_SEA));
        break;
      case 0x6f: // LD LX, A
        //      _XL = _A;
        _SsetXL(_A);
        break;
      case 0x70: // LD (IX+o), B
        _SEAX();
        //      WriteMemory(EA, _B);
        _SWRITEM(_SEA, _SgetB());
        break;
      case 0x71: // LD (IX+o), C
        _SEAX();
        //      WriteMemory(EA, _C);
        _SWRITEM(_SEA, _SgetC());
        break;
      case 0x72: // LD (IX+o), D
        _SEAX();
        //      WriteMemory(EA, _D);
        _SWRITEM(_SEA, _SgetD());
        break;
      case 0x73: // LD (IX+o), E
        _SEAX();
        //      WriteMemory(EA, _E);
        _SWRITEM(_SEA, _SgetE());
        break;
      case 0x74: // LD (IX+o), H
        _SEAX();
        //      WriteMemory(EA, _H);
        _SWRITEM(_SEA, _SgetH());
        break;
      case 0x75: // LD (IX+o), L
        _SEAX();
        //      WriteMemory(EA, _L);
        _SWRITEM(_SEA, _SgetL());
        break;
      case 0x77: // LD (IX+o), A
        _SEAX();
        //      WriteMemory(EA, _A);
        _SWRITEM(_SEA, _A);
        break;
      case 0x7c: // LD A, HX
        //      _A = _XH;
        _A = (_SgetXH());
        break;
      case 0x7d: // LD A, LX
        //      _A = _XL;
        _A = (_SgetXL());
        break;
      case 0x7e: // LD A, (IX+o)
        _SEAX();
        //      _A = ReadMemory(EA);
        _A = (_SREADM8(_SEA));
        break;
      case 0x84: // ADD A, HX
        _SADD(_SgetXH());
        break;
      case 0x85: // ADD A, LX
        _SADD(_SgetXL());
        break;
      case 0x86: // ADD A, (IX+o)
        _SEAX();
        _SADD(_SREADM8(_SEA));
        break;
      case 0x8c: // ADC A, HX
        _SADC(_SgetXH());
        break;
      case 0x8d: // ADC A, LX
        _SADC(_SgetXL());
        break;
      case 0x8e: // ADC A, (IX+o)
        _SEAX();
        _SADC(_SREADM8(_SEA));
        break;
      case 0x94: // SUB HX
        _SSUB(_SgetXH());
        break;
      case 0x95: // SUB LX
        _SSUB(_SgetXL());
        break;
      case 0x96: // SUB (IX+o)
        _SEAX();
        _SSUB(_SREADM8(_SEA));
        break;
      case 0x9c: // SBC A, HX
        _SSBC(_SgetXH());
        break;
      case 0x9d: // SBC A, LX
        _SSBC(_SgetXL());
        break;
      case 0x9e: // SBC A, (IX+o)
        _SEAX();
        _SSBC(_SREADM8(_SEA));
        break;
      case 0xa4: // AND HX
        _SAND(_SgetXH());
        break;
      case 0xa5: // AND LX
        _SAND(_SgetXL());
        break;
      case 0xa6: // AND (IX+o)
        _SEAX();
        _SAND(_SREADM8(_SEA));
        break;
      case 0xac: // XOR HX
        _SXOR(_SgetXH());
        break;
      case 0xad: // XOR LX
        _SXOR(_SgetXL());
        break;
      case 0xae: // XOR (IX+o)
        _SEAX();
        _SXOR(_SREADM8(_SEA));
        break;
      case 0xb4: // OR HX
        _SOR(_SgetXH());
        break;
      case 0xb5: // OR LX
        _SOR(_SgetXL());
        break;
      case 0xb6: // OR (IX+o)
        _SEAX();
        _SOR(_SREADM8(_SEA));
        break;
      case 0xbc: // CP HX
        _SCP(_SgetXH());
        break;
      case 0xbd: // CP LX
        _SCP(_SgetXL());
        break;
      case 0xbe: // CP (IX+o)
        _SEAX();
        //      _SCP(ReadMemory(_SEA));
        _SCP(_SREADM8(_SEA));
        break;
      case 0xcb: // ** DD CB xx
        _SEAX();
        _ScodeXY();
        break;
      case 0xe1: // POP IX
        _SIX = _SPOP();
        break;
      case 0xe3: // EX (SP), IX
        _SIX = _SEXSP(_SIX);
        break;
      case 0xe5: // PUSH IX
        _SPUSH(_SIX);
        break;
      case 0xe9: // JP (IX)
        _SPC = _SIX;
        break;
      case 0xf9: // LD SP, IX
        _SSP = _SIX;
        break;
      default: // 未定義
        trace(strHex(_SPC-1,4)+": DD:未定義 "+strHex(code, 2));
//        Console.WriteLine("{0:4X}: DD:未定義 {1:2X}", _SPC-1, code);
        break;
      }

    }

    private function _ScodeED() : void {
      // 命令の実行
      var code: int = _SREADM_PC();

      //	_Sscount -= cc_ed[code];
      _Sstate_count(cc_ed[code]);
      _R = (_R & 0x80) | ((_R + 1) & 0x7f);

      switch(code)
        {
        case 0x40: // IN B, (C)
          //      _B = ReadIO(_C, _B);
          //      _F = (_F & CF) | SZP[_B];
          _SsetB(io._in(_SgetC()));
          _F = (_F & Z80_FLAG_C) | SZP[_SgetB()];
          break;
        case 0x41: // OUT (C), B
          //      WriteIO(_C, _B, _B);
          io._out(_SgetC(), _SgetB());
          break;
        case 0x42: // SBC HL, BC
          _SSBC16(_SBC);
          break;
        case 0x43: // LD (w), BC
          //      EA = ReadMemory16(PC);
          //      PC += 2;
          //      WriteMemory16(EA, BC);

          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SWRITEM16(_SEA, _SBC);
          break;
        case 0x44: // NEG
          _SNEG();
          break;
        case 0x45: // RETN;
          _SRETN();
          break;
        case 0x46: // IM 0
          _SIM = 0;
          break;
        case 0x47: // LD I, A
          _I = _A;
          break;
        case 0x48: // IN C, (C)
          //      _C = ReadIO(_C, _B);
          //      _F = (_F & CF) | SZP[_C];
          _SsetC(io._in(_SgetC()));
          _F = (_F & Z80_FLAG_C) | SZP[_SgetC()];
          break;
        case 0x49: // OUT (C), C
          //      WriteIO(_C, _B, _C);
          io._out(_SgetC(), _SgetC());
          break;
        case 0x4a: // ADC HL, BC
          _SADC16(_SBC);
          break;
        case 0x4b: // LD BC, (w)
          //      EA = ReadMemory16(PC);
          //      PC += 2;
          //      BC = ReadMemory16(EA);
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SBC = _SREADM16(_SEA);
          break;
        case 0x4c: // NEG
          _SNEG();
          break;
        case 0x4d: // RETI
          _SRETI();
          break;
        case 0x4e: // IM 0
          _SIM = 0;
          break;
        case 0x4f: // LD R, A
          _R = _A;
          break;
        case 0x50: // IN D, (C)
          //      _D = ReadIO(_C, _B);
          //      _F = (_F & CF) | SZP[_D];
          _SsetD(io._in(_SgetC()));
          _F = (_F & Z80_FLAG_C) | SZP[_SgetD()];
          break;
        case 0x51: // OUT (C), D
          //      WriteIO(_C, _B, _D);
          io._out(_SgetC(), _SgetD());
          break;
        case 0x52: // SBC HL, DE
          _SSBC16(_SDE);
          break;
        case 0x53: // LD (w), DE
          //      EA = ReadMemory16(PC);
          //      PC += 2;
          //      WriteMemory16(EA, DE);
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SWRITEM16(_SEA, _SDE);
          break;
        case 0x54: // NEG
          _SNEG();
          break;
        case 0x55: // RETN;
          _SRETN();
          break;
        case 0x56: // IM 1
          _SIM = 1;
          break;
        case 0x57: // LD A, I
          _A = (_I);
          //      _F = (_F & CF) | SZ[_A] | (IFF2 << 2);
          _F = (_F & Z80_FLAG_C) | SZ[_A] | (_SIFF2 << 2);
          break;
        case 0x58: // IN E, (C)
          //      _E = ReadIO(_C, _B);
          //      _F = (_F & CF) | SZP[_E];
          _SsetE(io._in(_SgetC()));
          _F = (_F & Z80_FLAG_C) | SZP[_SgetE()];
          break;
        case 0x59: // OUT (C), E
          //      WriteIO(_C, _B, _E);
          io._out(_SgetC(), _SgetE());
          break;
        case 0x5a: // ADC HL, DE
          _SADC16(_SDE);
          break;
        case 0x5b: // LD DE, (w)
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SDE = _SREADM16(_SEA);
          break;
        case 0x5c: // NEG
          _SNEG();
          break;
        case 0x5d: // RETI
          _SRETI();
          break;
        case 0x5e: // IM 2
          _SIM = 2;
          break;
        case 0x5f: // LD A, R
          //      _A = _R;
          //      _F = (_F & CF) | SZ[_A] | (IFF2 << 2);
          _A = (_R);
          _F = (_F & Z80_FLAG_C) | SZ[_A] | (_SIFF2 << 2);
          break;
        case 0x60: // IN H, (C)
          //      _H = ReadIO(_C, _B);
          //      _F = (_F & CF) | SZP[_H];
          _SsetH(io._in(_SgetC()));
          _F = (_F & Z80_FLAG_C) | SZP[_SgetH()];
          break;
        case 0x61: // OUT (C), H
          //      WriteIO(_C, _B, _H);
          io._out(_SgetC(), _SgetH());
          break;
        case 0x62: // SBC HL, HL
          _SSBC16(_SHL);
          break;
        case 0x63: // LD (w), HL
          //      EA = ReadMemory16(PC);
          //      PC += 2;
          //      WriteMemory16(EA, HL);
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SWRITEM16(_SEA, _SHL);
          break;
        case 0x64: // NEG
          _SNEG();
          break;
        case 0x65: // RETN;
          _SRETN();
          break;
        case 0x66: // IM 0
          _SIM = 0;
          break;
        case 0x67: // RRD (HL)
          _SRRD();
          break;
        case 0x68: // IN L, (C)
          //      _L = ReadIO(_C, _B);
          //      _F = (_F & CF) | SZP[_L];
          _SsetL(io._in(_SgetC()));
          _F = (_F & Z80_FLAG_C) | SZP[_SgetL()];
          break;
        case 0x69: // OUT (C), L
          //      WriteIO(_C, _B, _L);
          io._out(_SgetC(), _SgetL());
          break;
        case 0x6a: // ADC HL, HL
          _SADC16(_SHL);
          break;
        case 0x6b: // LD HL, (w)
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SHL = _SREADM16(_SEA);
          break;
        case 0x6c: // NEG
          _SNEG();
          break;
        case 0x6d: // RETI
          _SRETI();
          break;
        case 0x6e: // IM 0
          _SIM = 0;
          break;
        case 0x6f: // RLD (HL)
          _SRLD();
          break;
        case 0x70: // IN 0, (C)
          //      _F = (_F & CF) | SZP[ReadIO(_C, _B)];
          _F = (_F & Z80_FLAG_C) | SZP[io._in(_SgetC())];
          break;
        case 0x71: // OUT (C), 0
          //      WriteIO(_C, _B, 0);
          io._out(_SgetC(), 0);
          break;
        case 0x72: // SBC HL, SP
          _SSBC16(_SSP);
          break;
        case 0x73: // LD (w), SP
          /*
      EA = ReadMemory16(PC);
      PC += 2;
      WriteMemory16(EA, SP);
           */
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SWRITEM16(_SEA, _SSP);
          break;
        case 0x74: // NEG
          _SNEG();
          break;
        case 0x75: // RETN;
          _SRETN();
          break;
        case 0x76: // IM 1
          _SIM = 1;
          break;
        case 0x78: // IN A, (C)
          //      _A = ReadIO(_C, _B);
          //      _F = (_F & CF) | SZP[_A];
          _A = (io._in(_SgetC()));
          _F = (_F & Z80_FLAG_C) | SZP[_A];
          break;
        case 0x79: // OUT (C), A
          //      WriteIO(_C, _B, _A);
          io._out(_SgetC(), _A);
          break;
        case 0x7a: // ADC HL, SP
          _SADC16(_SSP);
          break;
        case 0x7b: // LD SP, (w)
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SSP = _SREADM16(_SEA);
          break;
        case 0x7c: // NEG
          _SNEG();
          break;
        case 0x7d: // RETI
          _SRETI();
          break;
        case 0x7e: // IM 2
          _SIM = 2;
          break;
        case 0xa0: // LDI
          _SLDI();
          break;
        case 0xa1: // CPI
          _SCPI();
          break;
        case 0xa2: // INI
          _SINI();
          break;
        case 0xa3: // OUTI
          _SOUTI();
          break;
        case 0xa8: // LDD
          _SLDD();
          break;
        case 0xa9: // CPD
          _SCPD();
          break;
        case 0xaa: // IND
          _SIND();
          break;
        case 0xab: // OUTD
          _SOUTD();
          break;
        case 0xb0: // LDIR
          _SLDIR();
          break;
        case 0xb1: // CPIR
          _SCPIR();
          break;
        case 0xb2: // INIR
          _SINIR();
          break;
        case 0xb3: // OTIR
          _SOTIR();
          break;
        case 0xb8: // LDDR
          _SLDDR();
          break;
        case 0xb9: // CPDR
          _SCPDR();
          break;
        case 0xba: // INDR
          _SINDR();
          break;
        case 0xbb: // OTDR
          _SOTDR();
          break;

          // patch for NEW MONITOR
        case 0xf0: // スクロール
          pem_scroll();
          break;
        case 0xf1:  // ?QDPCT
          pem_qdpct(_A);
          break;
        case 0xf2:
          em_qdsp(); // ?DSP
          break;
        case 0xf3: //?ADCN
          em_qadcn();
          break;
        case 0xf4: //?DACN
          em_qdacn();
          break;
        case 0xf5:  // ?PRT
          em_qprt();
          break;

        default: // 未定義
          trace(strHex(_SPC-1,4)+": ED:未定義 "+strHex(code, 2));
//          Console.WriteLine("{0:4X}: ED:未定義 {1:2X}", _SPC-1, code);
          break;
        }

    }

    private function _ScodeFD() : void {
      // 命令の実行
      var code: int = _SREADM_PC();

      //	_Sscount -= cc_xy[code];
      _Sstate_count(cc_xy[code]);
      _R = (_R & 0x80) | ((_R + 1) & 0x7f);

      switch(code)
        {
        case 0x09: // ADD IY, BC
          _SIY = _SADD16(_SIY, _SBC);
          break;
        case 0x19: // ADD IY, DE
          _SIY = _SADD16(_SIY, _SDE);
          break;
        case 0x21: // LD IY, w
          //      IY = ReadMemory16(PC);
          //      PC += 2;
          _SIY = _SREADM16(_SPC);
          _SPC += 2;
          break;
        case 0x22: // LD (w), IY
          //      EA = ReadMemory16(PC);
          //      PC += 2;
          //      WriteMemory16(EA, IY);
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SWRITEM16(_SEA, _SIY);
          break;
        case 0x23: // INC IY
          ++_SIY;
          _SIY &= 0xFFFF;
          break;
        case 0x24: // INC HY
          //      _YH = INC(_YH);
          _SsetYH(_SINC(_SgetYH()));
          break;
        case 0x25: // DEC HY
          //      _YH = DEC(_YH);
          _SsetYH(_SDEC(_SgetYH()));
          break;
        case 0x26: // LD HY, n
          //      _YH = ReadMemory(PC++);
          _SsetYH(_SREADM_PC());
          break;
        case 0x29: // ADD IY, IY
          _SIY = _SADD16(_SIY, _SIY);
          break;
        case 0x2a: // LD IY, (w)
          _SEA = _SREADM16(_SPC);
          _SPC += 2;
          _SIY = _SREADM16(_SEA);
          break;
        case 0x2b: // DEC IY
          --_SIY;
          _SIY &= 0xFFFF;
          break;
        case 0x2c: // INC LY
          //      _YL = INC(_YL);
          _SsetYL(_SINC(_SgetYL()));
          break;
        case 0x2d: // DEC LY
          //      _YL = DEC(_YL);
          _SsetYL(_SDEC(_SgetYL()));
          break;
        case 0x2e: // LD LY, n
          //      _YL = ReadMemory(PC++);
          _SsetYL(_SREADM_PC());
          break;
        case 0x34: // INC (IY+o)
          //      EAY();
          //      WriteMemory(EA, INC(ReadMemory(EA)));
          _SEAY();
          _SWRITEM(_SEA, _SINC(_SREADM8(_SEA)));
          break;
        case 0x35: // DEC (IY+o)
          _SEAY();
          //      WriteMemory(EA, DEC(ReadMemory(EA)));
          _SWRITEM(_SEA, _SDEC(_SREADM8(_SEA)));
          break;
        case 0x36: // LD (IY+o), n
          _SEAY();
          //      WriteMemory(EA, ReadMemory(PC++));
          _SWRITEM(_SEA, _SREADM_PC());
          break;
        case 0x39: // ADD IY, SP
          _SIY = _SADD16(_SIY, _SSP);
          break;
        case 0x44: // LD B, HY
          //      _B = _YH;
          _SsetB(_SgetYH());
          break;
        case 0x45: // LD B, LY
          //      _B = _YL;
          _SsetB(_SgetYL());
          break;
        case 0x46: // LD B, (IY+o)
          _SEAY();
          _SsetB(_SREADM8(_SEA));
          break;
        case 0x4c: // LD C, HY
          //      _C = _YH;
          _SsetC(_SgetYH());
          break;
        case 0x4d: // LD C, LY
          //      _C = _YL;
          _SsetC(_SgetYL());
          break;
        case 0x4e: // LD C, (IY+o)
          _SEAY();
          //      _C = ReadMemory(EA);
          _SsetC(_SREADM8(_SEA));
          break;
        case 0x54: // LD D, HY
          //      _D = _YH;
          _SsetD(_SgetYH());
          break;
        case 0x55: // LD D, LY
          //      _D = _YL;
          _SsetD(_SgetYL());
          break;
        case 0x56: // LD D, (IY+o)
          _SEAY();
          //      _D = ReadMemory(EA);
          _SsetD(_SREADM8(_SEA));
          break;
        case 0x5c: // LD E, HY
          //      _E = _YH;
          _SsetE(_SgetYH());
          break;
        case 0x5d: // LD E, LY
          //      _E = _YL;
          _SsetE(_SgetYL());
          break;
        case 0x5e: // LD E, (IY+o)
          _SEAY();
          //      _E = ReadMemory(EA);
          _SsetE(_SREADM8(_SEA));
          break;
        case 0x60: // LD HY, B
          //      _YH = _B;
          _SsetYH(_SgetB());
          break;
        case 0x61: // LD HY, C
          //      _YH = _C;
          _SsetYH(_SgetC());
          break;
        case 0x62: // LD HY, D
          //      _YH = _D;
          _SsetYH(_SgetD());
          break;
        case 0x63: // LD HY, E
          //      _YH = _E;
          _SsetYH(_SgetE());
          break;
        case 0x64: // LD HY, HY
          break;
        case 0x65: // LD HY, LY
          //      _YH = _YL;
          _SsetYH(_SgetYL());
          break;
        case 0x66: // LD H, (IY+o)
          _SEAY();
          //      _H = ReadMemory(EA);
          _SsetH(_SREADM8(_SEA));
          break;
        case 0x67: // LD HY, A
          //      _YH = _A;
          _SsetYH(_A);
          break;
        case 0x68: // LD LY, B
          //      _YL = _B;
          _SsetYL(_SgetB());
          break;
        case 0x69: // LD LY, C
          //      _YL = _C;
          _SsetYL(_SgetC());
          break;
        case 0x6a: // LD LY, D
          //      _YL = _D;
          _SsetYL(_SgetD());
          break;
        case 0x6b: // LD LY, E
          //      _YL = _E;
          _SsetYL(_SgetE());
          break;
        case 0x6c: // LD LY, HY
          //      _YL = _YH;
          _SsetYL(_SgetYH());
          break;
        case 0x6d: // LD LY, LY
          break;
        case 0x6e: // LD L, (IY+o)
          _SEAY();
          //      _L = ReadMemory(EA);
          _SsetL(_SREADM8(_SEA));
          break;
        case 0x6f: // LD LY, A
          //      _YL = _A;
          _SsetYL(_A);
          break;

        case 0x70: // LD (IY+o), B
          _SEAY();
          //      WriteMemory(EA, _B);
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x71: // LD (IY+o), C
          _SEAY();
          //      WriteMemory(EA, _C);
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x72: // LD (IY+o), D
          _SEAY();
          //      WriteMemory(EA, _D);
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x73: // LD (IY+o), E
          _SEAY();
          //      WriteMemory(EA, _E);
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x74: // LD (IY+o), H
          _SEAY();
          //      WriteMemory(EA, _H);
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x75: // LD (IY+o), L
          _SEAY();
          //      WriteMemory(EA, _L);
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x77: // LD (IY+o), A
          _SEAY();
          //      WriteMemory(EA, _A);
          _SWRITEM(_SEA, _A);
          break;
        case 0x7c: // LD A, HY
          //      _A = _YH;
          _A = (_SgetYH());
          break;
        case 0x7d: // LD A, LY
          //      _A = _YL;
          _A = (_SgetYL());
          break;
        case 0x7e: // LD A, (IY+o)
          _SEAY();
          //      _A = ReadMemory(EA);
          _A = (_SREADM8(_SEA));
          break;
        case 0x84: // ADD A, HY
          //      ADD(_YH);
          _SADD(_SgetYH());
          break;
        case 0x85: // ADD A, LY
          //      ADD(_YL);
          _SADD(_SgetYL());
          break;
        case 0x86: // ADD A, (IY+o)
          _SEAY();
          //      ADD(ReadMemory(EA));
          _SADD(_SREADM8(_SEA));
          break;
        case 0x8c: // ADC A, HY
          //      ADC(_YH);
          _SADC(_SgetYH());
          break;
        case 0x8d: // ADC A, LY
          //      ADC(_YL);
          _SADC(_SgetYL());
          break;
        case 0x8e: // ADC A, (IY+o)
          _SEAY();
          //      ADC(ReadMemory(EA));
          _SADC(_SREADM8(_SEA));
          break;
        case 0x94: // SUB HY
          //      SUB(_YH);
          _SSUB(_SgetYH());
          break;
        case 0x95: // SUB LY
          //      SUB(_YL);
          _SSUB(_SgetYL());
          break;
        case 0x96: // SUB (IY+o)
          _SEAY();
          //      SUB(ReadMemory(EA));
          _SSUB(_SREADM8(_SEA));
          break;
        case 0x9c: // SBC A, HY
          //      SBC(_YH);
          _SSBC(_SgetYH());
          break;
        case 0x9d: // SBC A, LY
          //      SBC(_YL);
          _SSBC(_SgetYL());
          break;
        case 0x9e: // SBC A, (IY+o)
          _SEAY();
          //     SBC(ReadMemory(EA));
          _SSBC(_SREADM8(_SEA));
          break;
        case 0xa4: // AND HY
          //      AND(_YH);
          _SAND(_SgetYH());
          break;
        case 0xa5: // AND LY
          //      AND(_YL);
          _SAND(_SgetYL());
          break;
        case 0xa6: // AND (IY+o)
          _SEAY();
          //      AND(ReadMemory(EA));
          _SAND(_SREADM8(_SEA));
          break;
        case 0xac: // XOR HY
          //      XOR(_YH);
          _SXOR(_SgetYH());
          break;
        case 0xad: // XOR LY
          //			XOR(_YL);
          _SXOR(_SgetYL());
          break;
        case 0xae: // XOR (IY+o)
          _SEAY();
          //      XOR(ReadMemory(EA));
          _SXOR(_SREADM8(_SEA));
          break;
        case 0xb4: // OR HY
          //OR(_YH);
          _SOR(_SgetYH());
          break;
        case 0xb5: // OR LY
          //      OR(_YL);
          _SOR(_SgetYL());
          break;
        case 0xb6: // OR (IY+o)
          _SEAY();
          //OR(ReadMemory(EA));
          _SOR(_SREADM8(_SEA));
          break;
        case 0xbc: // CP HY
          //CP(_YH);
          _SCP(_SgetYH());
          break;
        case 0xbd: // CP LY
          //      CP(_YL);
          _SCP(_SgetYL());
          break;
        case 0xbe: // CP (IY+o)
          _SEAY();
          //CP(ReadMemory(EA));
          _SCP(_SREADM8(_SEA));
          break;
        case 0xcb: // ** FD CB xx
          _SEAY();
          _ScodeXY();
          break;
        case 0xe1: // POP IY
          _SIY = _SPOP();
          break;
        case 0xe3: // EX (SP), IY
          _SIY = _SEXSP(_SIY);
          break;
        case 0xe5: // PUSH IY
          _SPUSH(_SIY);
          break;
        case 0xe9: // JP (IY)
          _SPC = _SIY;
          break;
        case 0xf9: // LD SP, IY
          _SSP = _SIY;
          break;
        default: // 未定義
          trace("FD:未定義 "+strHex(code, 2));
//          Console.WriteLine("{0:4X}: FD:未定義 {1:2X}", _SPC-1, code);
          break;
        }

    }

    //
    private function _ScodeXY() : void {
      var code: int = _SREADM_PC();

      //	_Sscount -= cc_xy[code];
      _Sstate_count(cc_xy[code]);
      _R = (_R & 0x80) | ((_R + 1) & 0x7f);

      switch(code)
        {
        case 0x00: // RLC B=(XY+o)
          //      _B = RLC(ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRLC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x01: // RLC C=(XY+o)
          //      _C = RLC(ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRLC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x02: // RLC D=(XY+o)
          //      _D = RLC(ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRLC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x03: // RLC E=(XY+o)
          //      _E = RLC(ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRLC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x04: // RLC H=(XY+o)
          //      _H = RLC(ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRLC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x05: // RLC L=(XY+o)
          //      _L = RLC(ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRLC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x06: // RLC (XY+o)
          //      WriteMemory(EA, RLC(ReadMemory(EA)));
          _SWRITEM(_SEA, _SRLC(_SREADM8(_SEA)));
          break;
        case 0x07: // RLC A=(XY+o)
          //      _A = RLC(ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRLC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x08: // RRC B=(XY+o)
          //      _B = RRC(ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRRC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x09: // RRC C=(XY+o)
          //      _C = RRC(ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRRC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x0a: // RRC D=(XY+o)
          //      _D = RRC(ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRRC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x0b: // RRC E=(XY+o)
          //      _E = RRC(ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRRC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x0c: // RRC H=(XY+o)
          //      _H = RRC(ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRRC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x0d: // RRC L=(XY+o)
          //      _L = RRC(ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRRC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x0e: // RRC (XY+o)
          //      WriteMemory(EA, RRC(ReadMemory(EA)));
          _SWRITEM(_SEA, _SRRC(_SREADM8(_SEA)));
          break;
        case 0x0f: // RRC A=(XY+o)
          //      _A = RRC(ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRRC(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x10: // RL B=(XY+o)
          //     _B = RL(ReadMemory(EA));
          //     WriteMemory(EA, _B);
          _SsetB(_SRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x11: // RL C=(XY+o)
          //      _C = RL(ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x12: // RL D=(XY+o)
          //      _D = RL(ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x13: // RL E=(XY+o)
          //      _E = RL(ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x14: // RL H=(XY+o)
          //      _H = RL(ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x15: // RL L=(XY+o)
          //      _L = RL(ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x16: // RL (XY+o)
          //      WriteMemory(EA, RL(ReadMemory(EA)));
          _SWRITEM(_SEA, _SRL(_SREADM8(_SEA)));
          break;
        case 0x17: // RL A=(XY+o)
          //      _A = RL(ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x18: // RR B=(XY+o)
          //      _B = RR(ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRR(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x19: // RR C=(XY+o)
          //      _C = RR(ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRR(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x1a: // RR D=(XY+o)
          //      _D = RR(ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRR(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x1b: // RR E=(XY+o)
          //      _E = RR(ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRR(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x1c: // RR H=(XY+o)
          //      _H = RR(ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRR(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x1d: // RR L=(XY+o)
          //      _L = RR(ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRR(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x1e: // RR (XY+o)
          //      WriteMemory(EA, RR(ReadMemory(EA)));
          _SWRITEM(_SEA, _SRR(_SREADM8(_SEA)));
          break;
        case 0x1f: // RR A=(XY+o)
          //      _A = RR(ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRR(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x20: // SLA B=(XY+o)
          //      _B = SLA(ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSLA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x21: // SLA C=(XY+o)
          //      _C = SLA(ReadMemory(EA));
          //     WriteMemory(EA, _C);
          _SsetC(_SSLA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x22: // SLA D=(XY+o)
          //      _D = SLA(ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSLA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x23: // SLA E=(XY+o)
          //      _E = SLA(ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSLA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x24: // SLA H=(XY+o)
          //      _H = SLA(ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSLA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x25: // SLA L=(XY+o)
          //      _L = SLA(ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSLA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x26: // SLA (XY+o)
          //      WriteMemory(EA, SLA(ReadMemory(EA)));
          _SWRITEM(_SEA, _SSLA(_SREADM8(_SEA)));
          break;
        case 0x27: // SLA A=(XY+o)
          //      _A = SLA(ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSLA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;
        case 0x28: // SRA B=(XY+o)
          //      _B = SRA(ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSRA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x29: // SRA C=(XY+o)
          //      _C = SRA(ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSRA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x2a: // SRA D=(XY+o)
          //      _D = SRA(ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSRA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x2b: // SRA E=(XY+o)
          //      _E = SRA(ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSRA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x2c: // SRA H=(XY+o)
          //      _H = SRA(ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSRA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x2d: // SRA L=(XY+o)
          //      _L = SRA(ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSRA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x2e: // SRA (XY+o)
          //      WriteMemory(EA, SRA(ReadMemory(EA)));
          _SWRITEM(_SEA, _SSRA(_SREADM8(_SEA)));
          break;
        case 0x2f: // SRA A=(XY+o)
          //      _A = SRA(ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSRA(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x30: // SLL B=(XY+o)
          //      _B = SLL(ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSLL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x31: // SLL C=(XY+o)
          //      _C = SLL(ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSLL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x32: // SLL D=(XY+o)
          //      _D = SLL(ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSLL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x33: // SLL E=(XY+o)
          //      _E = SLL(ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSLL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x34: // SLL H=(XY+o)
          //      _H = SLL(ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSLL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x35: // SLL L=(XY+o)
          //      _L = SLL(ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSLL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x36: // SLL (XY+o)
          //      WriteMemory(EA, SLL(ReadMemory(EA)));
          _SWRITEM(_SEA, _SSLL(_SREADM8(_SEA)));
          break;
        case 0x37: // SLL A=(XY+o)
          //      _A = SLL(ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSLL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x38: // SRL B=(XY+o)
          //      _B = SRL(ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x39: // SRL C=(XY+o)
          //      _C = SRL(ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x3a: // SRL D=(XY+o)
          //      _D = SRL(ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x3b: // SRL E=(XY+o)
          //      _E = SRL(ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x3c: // SRL H=(XY+o)
          //      _H = SRL(ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x3d: // SRL L=(XY+o)
          //      _L = SRL(ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x3e: // SRL (XY+o)
          //      WriteMemory(EA, SRL(ReadMemory(EA)));
          _SWRITEM(_SEA, _SSRL(_SREADM8(_SEA)));
          break;
        case 0x3f: // SRL A=(XY+o)
          //      _A = SRL(ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSRL(_SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x40: // BIT 0, B=(XY+o)
        case 0x41: // BIT0, C=(XY+o)
        case 0x42: // BIT 0, D=(XY+o)
        case 0x43: // BIT 0, E=(XY+o)
        case 0x44: // BIT 0, H=(XY+o)
        case 0x45: // BIT 0, L=(XY+o)
        case 0x46: // BIT 0, (XY+o)
        case 0x47: // BIT 0, A=(XY+o)
          //      BIT_XY(0, ReadMemory(EA));
          _SBIT_XY(0, _SREADM8(_SEA));
          break;

        case 0x48: // BIT 1, B=(XY+o)
        case 0x49: // BIT1, C=(XY+o)
        case 0x4a: // BIT 1, D=(XY+o)
        case 0x4b: // BIT 1, E=(XY+o)
        case 0x4c: // BIT 1, H=(XY+o)
        case 0x4d: // BIT 1, L=(XY+o)
        case 0x4e: // BIT 1, (XY+o)
        case 0x4f: // BIT 1, A=(XY+o)
          //      BIT_XY(1, ReadMemory(EA));
          _SBIT_XY(1, _SREADM8(_SEA));
          break;

        case 0x50: // BIT 2, B=(XY+o)
        case 0x51: // BIT2, C=(XY+o)
        case 0x52: // BIT 2, D=(XY+o)
        case 0x53: // BIT 2, E=(XY+o)
        case 0x54: // BIT 2, H=(XY+o)
        case 0x55: // BIT 2, L=(XY+o)
        case 0x56: // BIT 2, (XY+o)
        case 0x57: // BIT 2, A=(XY+o)
          //      BIT_XY(2, ReadMemory(EA));
          _SBIT_XY(2, _SREADM8(_SEA));
          break;

        case 0x58: // BIT 3, B=(XY+o)
        case 0x59: // BIT3, C=(XY+o)
        case 0x5a: // BIT 3, D=(XY+o)
        case 0x5b: // BIT 3, E=(XY+o)
        case 0x5c: // BIT 3, H=(XY+o)
        case 0x5d: // BIT 3, L=(XY+o)
        case 0x5e: // BIT 3, (XY+o)
        case 0x5f: // BIT 3, A=(XY+o)
          //      BIT_XY(3, ReadMemory(EA));
          _SBIT_XY(3, _SREADM8(_SEA));
          break;

        case 0x60: // BIT 4, B=(XY+o)
        case 0x61: // BIT4, C=(XY+o)
        case 0x62: // BIT 4, D=(XY+o)
        case 0x63: // BIT 4, E=(XY+o)
        case 0x64: // BIT 4, H=(XY+o)
        case 0x65: // BIT 4, L=(XY+o)
        case 0x66: // BIT 4, (XY+o)
        case 0x67: // BIT 4, A=(XY+o)
          //      BIT_XY(4, ReadMemory(EA));
          _SBIT_XY(4, _SREADM8(_SEA));
          break;

        case 0x68: // BIT 5, B=(XY+o)
        case 0x69: // BIT5, C=(XY+o)
        case 0x6a: // BIT 5, D=(XY+o)
        case 0x6b: // BIT 5, E=(XY+o)
        case 0x6c: // BIT 5, H=(XY+o)
        case 0x6d: // BIT 5, L=(XY+o)
        case 0x6e: // BIT 5, (XY+o)
        case 0x6f: // BIT 5, A=(XY+o)
          //      BIT_XY(5, ReadMemory(EA));
          _SBIT_XY(5, _SREADM8(_SEA));
          break;

        case 0x70: // BIT 6, B=(XY+o)
        case 0x71: // BIT6, C=(XY+o)
        case 0x72: // BIT 6, D=(XY+o)
        case 0x73: // BIT 6, E=(XY+o)
        case 0x74: // BIT 6, H=(XY+o)
        case 0x75: // BIT 6, L=(XY+o)
        case 0x76: // BIT 6, (XY+o)
        case 0x77: // BIT 6, A=(XY+o)
          //      BIT_XY(6, ReadMemory(EA));
          _SBIT_XY(6, _SREADM8(_SEA));
          break;

        case 0x78: // BIT 7, B=(XY+o)
        case 0x79: // BIT7, C=(XY+o)
        case 0x7a: // BIT 7, D=(XY+o)
        case 0x7b: // BIT 7, E=(XY+o)
        case 0x7c: // BIT 7, H=(XY+o)
        case 0x7d: // BIT 7, L=(XY+o)
        case 0x7e: // BIT 7, (XY+o)
        case 0x7f: // BIT 7, A=(XY+o)
          //      BIT_XY(7, ReadMemory(EA));
          _SBIT_XY(7, _SREADM8(_SEA));
          break;

        case 0x80: // RES 0, B=(XY+o)
          //      _B = RES(0, ReadMemory(EA));
          //     WriteMemory(EA, _B);
          _SsetB(_SRES(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x81: // RES 0, C=(XY+o)
          //      _C = RES(0, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRES(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x82: // RES 0, D=(XY+o)
          //      _D = RES(0, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRES(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x83: // RES 0, E=(XY+o)
          //      _E = RES(0, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRES(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x84: // RES 0, H=(XY+o)
          //      _H = RES(0, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRES(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x85: // RES 0, L=(XY+o)
          //      _L = RES(0, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRES(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x86: // RES 0, (XY+o)
          //      WriteMemory(EA, RES(0, ReadMemory(EA)));
          _SWRITEM(_SEA, _SRES(0, _SREADM8(_SEA)));
          break;
        case 0x87: // RES 0, A=(XY+o)
          //      _A = RES(0, ReadMemory(EA));
          //     WriteMemory(EA, _A);
          _A = (_SRES(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x88: // RES 1, B=(XY+o)
          //      _B = RES(1, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRES(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x89: // RES 1, C=(XY+o)
          //      _C = RES(1, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRES(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x8a: // RES 1, D=(XY+o)
          //      _D = RES(1, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRES(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x8b: // RES 1, E=(XY+o)
          //      _E = RES(1, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRES(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x8c: // RES 1, H=(XY+o)
          //      _H = RES(1, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRES(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x8d: // RES 1, L=(XY+o)
          //      _L = RES(1, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRES(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x8e: // RES 1, (XY+o)
          //      WriteMemory(EA, RES(1, ReadMemory(EA)));
          _SWRITEM(_SEA, _SRES(1, _SREADM8(_SEA)));
          break;
        case 0x8f: // RES 1, A=(XY+o)
          //      _A = RES(1, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRES(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x90: // RES 2, B=(XY+o)
          //      _B = RES(2, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRES(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x91: // RES 2, C=(XY+o)
          //      _C = RES(2, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRES(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x92: // RES 2, D=(XY+o)
          //      _D = RES(2, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRES(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x93: // RES 2, E=(XY+o)
          //      _E = RES(2, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRES(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x94: // RES 2, H=(XY+o)
          //      _H = RES(2, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRES(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x95: // RES 2, L=(XY+o)
          //      _L = RES(2, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRES(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x96: // RES 2, (XY+o)
          //      WriteMemory(EA, RES(2, ReadMemory(EA)));
          _SWRITEM(_SEA, _SRES(2, _SREADM8(_SEA)));
          break;
        case 0x97: // RES 2, A=(XY+o)
          //      _A = RES(2, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRES(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0x98: // RES 3, B=(XY+o)
          //      _B = RES(3, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRES(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0x99: // RES 3, C=(XY+o)
          //      _C = RES(3, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRES(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0x9a: // RES 3, D=(XY+o)
          //      _D = RES(3, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRES(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0x9b: // RES 3, E=(XY+o)
          //      _E = RES(3, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRES(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0x9c: // RES 3, H=(XY+o)
          //      _H = RES(3, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRES(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0x9d: // RES 3, L=(XY+o)
          //      _L = RES(3, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRES(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0x9e: // RES 3, (XY+o)
          //      WriteMemory(EA, RES(3, ReadMemory(EA)));
          _SWRITEM(_SEA, _SRES(3, _SREADM8(_SEA)));
          break;
        case 0x9f: // RES 3, A=(XY+o)
          //      _A = RES(3, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRES(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xa0: // RES 4, B=(XY+o)
          //      _B = RES(4, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRES(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xa1: // RES 4, C=(XY+o)
          //      _C = RES(4, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRES(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xa2: // RES 4, D=(XY+o)
          //      _D = RES(4, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRES(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xa3: // RES 4, E=(XY+o)
          //      _E = RES(4, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRES(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xa4: // RES 4, H=(XY+o)
          //      _H = RES(4, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRES(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xa5: // RES 4, L=(XY+o)
          //      _L = RES(4, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRES(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xa6: // RES 4, (XY+o)
          //      WriteMemory(EA, RES(4, ReadMemory(EA)));
          _SWRITEM(_SEA, _SRES(4, _SREADM8(_SEA)));
          break;
        case 0xa7: // RES 4, A=(XY+o)
          //      _A = RES(4, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRES(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xa8: // RES 5, B=(XY+o)
          //      _B = RES(5, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRES(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xa9: // RES 5, C=(XY+o)
          //      _C = RES(5, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRES(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xaa: // RES 5, D=(XY+o)
          //      _D = RES(5, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRES(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xab: // RES 5, E=(XY+o)
          //      _E = RES(5, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRES(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xac: // RES 5, H=(XY+o)
          //      _H = RES(5, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRES(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xad: // RES 5, L=(XY+o)
          //      _L = RES(5, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRES(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xae: // RES 5, (XY+o)
          //      WriteMemory(EA, RES(5, ReadMemory(EA)));
          _SWRITEM(_SEA, _SRES(5, _SREADM8(_SEA)));
          break;
        case 0xaf: // RES 5, A=(XY+o)
          //      _A = RES(5, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRES(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xb0: // RES 6, B=(XY+o)
          //      _B = RES(6, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRES(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xb1: // RES 6, C=(XY+o)
          //      _C = RES(6, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRES(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xb2: // RES 6, D=(XY+o)
          //      _D = RES(6, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRES(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xb3: // RES 6, E=(XY+o)
          //      _E = RES(6, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRES(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xb4: // RES 6, H=(XY+o)
          //      _H = RES(6, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRES(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xb5: // RES 6, L=(XY+o)
          //      _L = RES(6, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRES(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xb6: // RES 6, (XY+o)
          //      WriteMemory(EA, RES(6, ReadMemory(EA)));
          _SWRITEM(_SEA, _SRES(6, _SREADM8(_SEA)));
          break;
        case 0xb7: // RES 6, A=(XY+o)
          //      _A = RES(6, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRES(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xb8: // RES 7, B=(XY+o)
          //      _B = RES(7, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SRES(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xb9: // RES 7, C=(XY+o)
          //      _C = RES(7, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SRES(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xba: // RES 7, D=(XY+o)
          //      _D = RES(7, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SRES(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xbb: // RES 7, E=(XY+o)
          //      _E = RES(7, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SRES(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xbc: // RES 7, H=(XY+o)
          //      _H = RES(7, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SRES(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xbd: // RES 7, L=(XY+o)
          //      _L = RES(7, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SRES(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xbe: // RES 7, (XY+o)
          //			WriteMemory(EA, RES(7, ReadMemory(EA)));
          _SWRITEM(_SEA, _SRES(7, _SREADM8(_SEA)));
          break;
        case 0xbf: // RES 7, A=(XY+o)
          //      _A = RES(7, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SRES(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xc0: // SET 0, B=(XY+o)
          //      _B = SET(0, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSET(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xc1: // SET 0, C=(XY+o)
          //      _C = SET(0, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSET(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xc2: // SET 0, D=(XY+o)
          //      _D = SET(0, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSET(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xc3: // SET 0, E=(XY+o)
          //      _E = SET(0, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSET(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xc4: // SET 0, H=(XY+o)
          //      _H = SET(0, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSET(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xc5: // SET 0, L=(XY+o)
          //      _L = SET(0, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSET(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xc6: // SET 0, (XY+o)
          //			WriteMemory(EA, SET(0, ReadMemory(EA)));
          _SWRITEM(_SEA, _SSET(0, _SREADM8(_SEA)));
          break;
        case 0xc7: // SET 0, A=(XY+o)
          //      _A = SET(0, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSET(0, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xc8: // SET 1, B=(XY+o)
          //			_B = SET(1, ReadMemory(EA));
          //			WriteMemory(EA, _B);
          _SsetB(_SSET(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xc9: // SET 1, C=(XY+o)
          //      _C = SET(1, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSET(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xca: // SET 1, D=(XY+o)
          //      _D = SET(1, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSET(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xcb: // SET 1, E=(XY+o)
          //      _E = SET(1, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSET(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xcc: // SET 1, H=(XY+o)
          //      _H = SET(1, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSET(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xcd: // SET 1, L=(XY+o)
          //      _L = SET(1, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSET(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xce: // SET 1, (XY+o)
          //			WriteMemory(EA, SET(1, ReadMemory(EA)));
          _SWRITEM(_SEA, _SSET(1, _SREADM8(_SEA)));
          break;
        case 0xcf: // SET 1, A=(XY+o)
          //      _A = SET(1, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSET(1, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xd0: // SET 2, B=(XY+o)
          //      _B = SET(2, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSET(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xd1: // SET 2, C=(XY+o)
          //      _C = SET(2, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSET(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xd2: // SET 2, D=(XY+o)
          //      _D = SET(2, ReadMemory(EA));
          //     WriteMemory(EA, _D);
          _SsetD(_SSET(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xd3: // SET 2, E=(XY+o)
          //      _E = SET(2, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSET(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xd4: // SET 2, H=(XY+o)
          //      _H = SET(2, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSET(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xd5: // SET 2, L=(XY+o)
          //      _L = SET(2, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSET(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xd6: // SET 2, (XY+o)
          //			WriteMemory(EA, SET(2, ReadMemory(EA)));
          _SWRITEM(_SEA, _SSET(2, _SREADM8(_SEA)));
          break;
        case 0xd7: // SET 2, A=(XY+o)
          //      _A = SET(2, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSET(2, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xd8: // SET 3, B=(XY+o)
          //      _B = SET(3, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSET(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xd9: // SET 3, C=(XY+o)
          //      _C = SET(3, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSET(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xda: // SET 3, D=(XY+o)
          //      _D = SET(3, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSET(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xdb: // SET 3, E=(XY+o)
          //      _E = SET(3, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSET(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xdc: // SET 3, H=(XY+o)
          //      _H = SET(3, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSET(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xdd: // SET 3, L=(XY+o)
          //      _L = SET(3, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSET(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xde: // SET 3, (XY+o)
          //			WriteMemory(EA, SET(3, ReadMemory(EA)));
          _SWRITEM(_SEA, _SSET(3, _SREADM8(_SEA)));
          break;
        case 0xdf: // SET 3, A=(XY+o)
          //      _A = SET(3, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSET(3, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xe0: // SET 4, B=(XY+o)
          //      _B = SET(4, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSET(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xe1: // SET 4, C=(XY+o)
          //      _C = SET(4, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSET(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xe2: // SET 4, D=(XY+o)
          //      _D = SET(4, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSET(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xe3: // SET 4, E=(XY+o)
          //      _E = SET(4, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSET(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xe4: // SET 4, H=(XY+o)
          //      _H = SET(4, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSET(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xe5: // SET 4, L=(XY+o)
          //      _L = SET(4, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSET(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xe6: // SET 4, (XY+o)
          //			WriteMemory(EA, SET(4, ReadMemory(EA)));
          _SWRITEM(_SEA, _SSET(4, _SREADM8(_SEA)));
          break;
        case 0xe7: // SET 4, A=(XY+o)
          //      _A = SET(4, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSET(4, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xe8: // SET 5, B=(XY+o)
          //			_B = SET(5, ReadMemory(EA));
          //			WriteMemory(EA, _B);
          _SsetB(_SSET(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xe9: // SET 5, C=(XY+o)
          //      _C = SET(5, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSET(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xea: // SET 5, D=(XY+o)
          //      _D = SET(5, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSET(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xeb: // SET 5, E=(XY+o)
          //      _E = SET(5, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSET(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xec: // SET 5, H=(XY+o)
          //      _H = SET(5, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSET(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xed: // SET 5, L=(XY+o)
          //      _L = SET(5, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSET(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xee: // SET 5, (XY+o)
          //			WriteMemory(EA, SET(5, ReadMemory(EA)));
          _SWRITEM(_SEA, _SSET(5, _SREADM8(_SEA)));
          break;
        case 0xef: // SET 5, A=(XY+o)
          //      _A = SET(5, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSET(5, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xf0: // SET 6, B=(XY+o)
          //      _B = SET(6, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSET(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xf1: // SET 6, C=(XY+o)
          //      _C = SET(6, ReadMemory(EA));
          //     WriteMemory(EA, _C);
          _SsetC(_SSET(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xf2: // SET 6, D=(XY+o)
          //      _D = SET(6, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSET(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xf3: // SET 6, E=(XY+o)
          //      _E = SET(6, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSET(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xf4: // SET 6, H=(XY+o)
          //      _H = SET(6, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSET(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xf5: // SET 6, L=(XY+o)
          //      _L = SET(6, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSET(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xf6: // SET 6, (XY+o)
          //			WriteMemory(EA, SET(6, ReadMemory(EA)));
          _SWRITEM(_SEA, _SSET(6, _SREADM8(_SEA)));
          break;
        case 0xf7: // SET 6, A=(XY+o)
          //      _A = SET(6, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSET(6, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        case 0xf8: // SET 7, B=(XY+o)
          //      _B = SET(7, ReadMemory(EA));
          //      WriteMemory(EA, _B);
          _SsetB(_SSET(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetB());
          break;
        case 0xf9: // SET 7, C=(XY+o)
          //      _C = SET(7, ReadMemory(EA));
          //      WriteMemory(EA, _C);
          _SsetC(_SSET(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetC());
          break;
        case 0xfa: // SET 7, D=(XY+o)
          //      _D = SET(7, ReadMemory(EA));
          //      WriteMemory(EA, _D);
          _SsetD(_SSET(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetD());
          break;
        case 0xfb: // SET 7, E=(XY+o)
          //      _E = SET(7, ReadMemory(EA));
          //      WriteMemory(EA, _E);
          _SsetE(_SSET(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetE());
          break;
        case 0xfc: // SET 7, H=(XY+o)
          //      _H = SET(7, ReadMemory(EA));
          //      WriteMemory(EA, _H);
          _SsetH(_SSET(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetH());
          break;
        case 0xfd: // SET 7, L=(XY+o)
          //      _L = SET(7, ReadMemory(EA));
          //      WriteMemory(EA, _L);
          _SsetL(_SSET(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _SgetL());
          break;
        case 0xfe: // SET 7, (XY+o)
          //			WriteMemory(EA, SET(7, ReadMemory(EA)));
          _SWRITEM(_SEA, _SSET(7, _SREADM8(_SEA)));
          break;
        case 0xff: // SET 7, A=(XY+o)
          //      _A = SET(7, ReadMemory(EA));
          //      WriteMemory(EA, _A);
          _A = (_SSET(7, _SREADM8(_SEA)));
          _SWRITEM(_SEA, _A);
          break;

        default:
          trace("XY:未定義 "+strHex(code, 2));
//          Console.WriteLine("XY:未定義 {0:2X}", code);
          break;


        }

    }

    //////////////////////////////////////////////////
    // VRAM SCROLL UP
    //////////////////////////////////////////////////
    private function pem_scroll() : void {
      var i: int;
      var b: Array;
      /*
    // TEXT SCROLL
    CopyMemory(mem + VID_START, mem + VID_START + 40, (40*24) );
    // COLOR SCROLL
    CopyMemory(mem + VID_START + 0x800, mem + VID_START + 0x800 + 40, (40*24) );

    // 最下行の消去
    ZeroMemory(mem + VID_START + (24*40) , 40);
    FillMemory(mem + VID_START + 0x800 + (24*40), 40, (bk_color) ? bk_color : 0x71);

    mz_refresh_screen(REFSC_ALL);
       */
      b = mem.getMem();
      // TEXT SCROLL
//      Array.Copy(b, Cmem.VID_START + 40, b, Cmem.VID_START, (40 * 24));
		for (i=0; i<(40*24); i++) {
			b[Cmem.VID_START + i] = b[Cmem.VID_START + 40 + i];
		}

      // COLOR SCROLL
//      Array.Copy(b,Cmem.VID_START+0x800+40, b, Cmem.VID_START+0x800, (40*24));
		for (i=0; i<(40*24); i++) {
			b[Cmem.VID_START+0x800 + i] = b[Cmem.VID_START + 0x800 + 40 + i];
		}

      // 最下行の消去
      for (i=39; i>=0; i--) {
        b[Cmem.VID_START + (24*40) + i] = 0;
        b[Cmem.VID_START + 0x800 + (24*40) + i] = 0x71;
      }

      // 適当にウェイト
      //    _Sstate_count(100);
    }

    //-------------------------------------
    //  COMPUTE POINT ADDRESS
    //  HL=SCREEN COORDINATE (x,y)
    //  EXIT HL=POINT ADDRESS ON SCREEN
    //-------------------------------------
    private function em_qpont() : void {
      var x: int;
      var y: int;
      var vrm: int;

      x = _SREADM8(L_DSPXY);
      y = _SREADM8(L_DSPXY + 1);

      vrm = 0xD000 + x + (y*40);

      _SsetH(vrm >> 8);
      _SsetL(vrm & 0xFF);
    }

    //------------------------------------
    // ?DSP:
    //  DISPLAY ON POINTER
    //  ACC=DISPLAY CODE
    //  EXCEPT F0H
    //------------------------------------
    private function em_qdsp() : void {
      var vrm: int;
      var af: int;
      var bc: int;
	  var de: int;
	  var hl: int;

      var x: int;
      var y: int;
      var val: int;
      var sml: int;

      // KEEP Regs
      af = _SgetAF();
      bc = _SBC;
      de = _SDE;
      hl = _SHL;

      _A &= 0xFF;

      //
      em_qpont();

      sml = 0;

      vrm = _SHL;
      if (_A == 0xF5) {      // small/large
        x = _SREADM8(L_SWRK);
        x ^= 0x40;
        _SWRITEM(L_SWRK, x);

        // Restore Regs
        _SsetAF(af);
        _SBC = bc;
        _SDE = de;
        _SHL = hl;
        return;
      }

      //--
      x = _SREADM8(L_SWRK);      // 0x80 = shift / 0x40 = LargeSmall Flg
      if ((x & 0xC0)!=0) sml = 1;

      val = _SREADM8(vrm + 0x800);            // color RAM
      _SWRITEM(vrm + 0x800 , ((sml==0) ? (val & 0x7F) : (val | 0x80)) );       // ATTR
      _SWRITEM(vrm , _A);                     // TEXT VRAM

      //--
      x = _SREADM8(L_DSPXY);
      y = _SREADM8(L_DSPXY + 1);
      if (x==39) {
        em__mang(); // not implements
        if ((_F & Z80_FLAG_C)==0) {
          _SWRITEM(L_MANG,1);
          _SWRITEM(L_MANG+1,0);
        }
      }


      _A = 0xC3;        // CURSL
      pem_qdpct(_A);    //

      // Restore Regs
      _SsetAF(af);
      _SBC = bc;
      _SDE = de;
      _SHL = hl;
    }

    //////////////////////////////////////////////////
    // EXEC CONTROL CODE
    //////////////////////////////////////////////////
    private function pem_qdpct(a: int) : void {
      var x: int, y: int;
      var i: int;

      x = _SREADM8(L_DSPXY);
      y = _SREADM8(L_DSPXY + 1);

      _A = a & 0xFF;

      switch (a) {
      case 0xC0:
        //SCROL
        pem_scroll();
        break;

      case 0xC1:
        //CURSD
        if (y == 24)
          pem_scroll();
        else
          y++;
        break;

      case 0xC2:
        //CURSU
        if (y!=0)
          y--;
        break;

      case 0xC3:
        //CURSR
        x++;
        if (x>39) {
          x=0;
          if (y == 24)
            pem_scroll();
          else
            y++;
        }
        break;

      case 0xC4:
        //CURSL
        x--;
        if (x<0) {
          if (y!=0) {
            x=39;
            y--;
          }
          else x=0;
        }
        break;

      case 0xC5:
        //HOME
        x = y = 0;
        break;

      case 0xC6:
        //CLRS
        x = y = 0;
        var b:Array = mem.getMem();
        for (i=26;i>=0;i--) {
          b[Cmem.RAM_START+L_MANG+i]=0;
        }
        for (i=0x3FF;i>=0;i--) {
          b[Cmem.VID_START+i]=0;
          b[Cmem.VID_START+0x800+i]=0x71;
        }
        /*
        ZeroMemory(Cmem + RAM_START + L_MANG, 27);
        ZeroMemory(Cmem + VID_START , 0x400);
        FillMemory(Cmem + VID_START + 0x800, 0x400, (bk_color) ? bk_color : 0x71);
         */
        break;

      case 0xC7:
        //DEL
        break;

      case 0xC8:
        //INST
        break;

      case 0xC9:
        //ALPHA
        _SWRITEM(L_KANAF, 0);
        break;

      case 0xCA:
        //KANA
        _SWRITEM(L_KANAF, 1);
        break;

      case 0xCB:
        //?RSTR
        break;

      case 0xCC:
        //?RSTR
        break;

      case 0xCD:
        //CR
        a = _SREADM8(L_SWRK);
        _SWRITEM(L_SWRK, (a & 0x7F) );     // SHIFT CLR
        em__mang();
        if ((_A & 1)!=0) {
          x=0;
          y++;
        }
        else
          {
            x=0;
            y++;
            if (y>=25){
              y=24;
              pem_scroll();
            }
          }
        break;

      case 0xCE:
        //?RSTR
        break;

      case 0xCF:
        //?RSTR
        break;

      default:;
        return;
      }

      _SWRITEM(L_DSPXY, x);
      _SWRITEM(L_DSPXY + 1, y);
    }

    //
    private function em__mang() : void {
      var x: int, y: int;
      var v: int, a: int;
      var ofs: int;

      x = _SREADM8(L_DSPXY);
      y = _SREADM8(L_DSPXY + 1);

      ofs = L_MANG + y;

      v = _SREADM8(ofs);

      ofs++;
      a = _SREADM8(ofs);
      a <<= 1;
      _SWRITEM(ofs, a);

      v |= a;

      a = _SREADM8(ofs);
      a >>= 1;
      _SWRITEM(ofs, a);

      if ((v & 1)!=0) {
        v = (0x80)|(v>>1);
        //        Z80_set_carry(Regs,1);
        _F |= Z80_FLAG_C;
      }
      else
        {
          v >>= 1;
          //        Z80_set_carry(Regs,0);
          _F &= (~Z80_FLAG_C);
        }
      _A = v;

      _SsetD(ofs >> 8);
      _SsetE(ofs & 0xFF);

      _SsetH(y);
      _SsetL(x);
    }

    // PRNT3
    private function em_prnt3() : void {
      var x: int;

      em_qdsp();
      x = _SREADM8(L_DPRNT);
      x++;
      if (x >= 80)
        x -= 80;
      _SWRITEM(L_DPRNT,x);
    }

    //------------------------------------
    //  PRINT ROUTINE
    //  1 CHARACTER
    //  INPUT:C=ASCII DATA (QDSP+QDPCT)
    private function em_qprt() : void {
      var a: int;

      em_qadcn();
      a = (_A & 0xFF);
      _SsetC(a);                   // C=A

      if (a == 0xF0) return;

      if ( (a >= 0xC0) && (a <= 0xC6) ) {
        // control code
        pem_qdpct(a);
      } else {
        em_prnt3();
      }

    }


    //------------------------------------
    //  ASCII TO DISPLAY CODE CONVERT
    //  IN ACC:ASCII
    //  EXIT ACC:DISPLAY CODE
    private function em_qadcn() : void {
      var _in: int = _A & 0xFF;

      _A = asc2disp_j[_in];
    }

    //------------------------------------------
    //  DISPLAY CODE TO ASCII CONVERSION
    //  IN ACC=DISPLAY CODE
    //  EXIT ACC=ASCII
    private function em_qdacn() : void {
      var i: int;
      var _in: int = (_A & 0xFF);

      for (i=0;i<256;i++) {
        if (_in == asc2disp_j[i]) {
          _A = i;
          return;
        }
      }

    }
	
	// デバッグ用16進数値表示
	private function strHex(v: int, k: int) : String {
		var s: String;
		var ls: String;
		var b: int;
		
		s = "0000" + v.toString(16);
		b = s.length - k;
		ls = s.substring(b, b+k);
		
		return ls;
	}

    
  }
}
