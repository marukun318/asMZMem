/////////////////////////////////////////////////////////////////////////////
// MZ-700 Emulator "MZ-Memories" for XNA
// I/O Class
//
// $Id$
// Programmed by Takeshi Maruyama (Marukun)
////////////////////////////////////////////////////////////////////////////

package {
  import flash.utils.*;
  
  class Cio {
    private var mem: Cmem;             // Memoryクラス

    //---------------
    // コンストラクタ
    //---------------
    public function Cio(a:Cmem) {
      mem = a;
    }

    //-------------------
    // I/Oにデータを出力
    //-------------------
    public function _out(port:int, dat:int):void {
      var b:Array = mem.getBank();
      var i:int;
	  
	  //    System.out.println("OUT "+Integer.toString(port,16)+")");

      switch (port & 0xFF) {
      case 0xe0:
        // make 0000-0FFF RAM
        b[0] = Cmem.MB_RAM;
        b[1] = Cmem.MB_RAM;
        break;

      case 0xe1:
        // make D000-FFFF RAM
        for (i=26;i<=31;i++)
          b[i] = Cmem.MB_RAM;
        break;

      case 0xe2:
        // make 0000-0FFF ROM
        b[0] = Cmem.MB_ROM1;
        b[1] = Cmem.MB_ROM1;
        break;

      case 0xe3:
        // make D000-FFFF VRAM/MMIO
        b[26] = Cmem.MB_VRAM;
        b[27] = Cmem.MB_VRAM;
        b[28] = Cmem.MB_IO;
        /*
      // 1500
      b[29] = Cmem.MB_ROM2;
      b[30] = Cmem.MB_ROM2;
      b[31] = Cmem.MB_ROM2;
         */
        // 700
        b[29] = Cmem.MB_DUMMY;
        b[30] = Cmem.MB_DUMMY;
        b[31] = Cmem.MB_DUMMY;
        break;

      case 0xe4:
        _out(0xe2,0);
        _out(0xe3,0);
        break;
      }

    }

    //---------------------
    // I/Oからデータを入力
    //---------------------
    public function _in(adr: int):int {

      return 0xFF;
    }
  }
}
