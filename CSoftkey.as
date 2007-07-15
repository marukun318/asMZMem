/////////////////////////////////////////////////////////////////////////////
// MZ-700 Emulator "MZ-Memories" for ActionScript 3.0
// CSoftkey Class
//
// $Id$
// Programmed by Takeshi Maruyama (Marukun)
////////////////////////////////////////////////////////////////////////////

package {
  import flash.utils.*;
  import flash.geom.*;

  //
  public class CSoftkey {
    // メインクラス
    private static var m : asMZMem;
    // メモリクラス
    private static var mem : Cmem;

    // ソフトキーの最大数
//    private static const SOFTKEY_MAX : int = 100;

    private var nowkey : int;   // 現在押されているキーコード
//	private var keymap : int;   // 現在表示されているキーマップ
   	private var pa_bak : Object = null; // 以前押されていたキーの配置情報

    public var fShift : Boolean = false; // シフトキー押下フラグ
    public var fCtrl : Boolean = false; // Ctrlキー押下フラグ

    // ソフトキー配置情報
    private static var KEYAREA : Array = new Array();

    // ソフトキー配列定義
    private static var keylst : Array = new Array();
    
    // キー配置
    private static const KEYPOS : Array = [
      // 零段目
      0x01,			// 表示開始座標決定
      48,416,                   // 位置決定
      0x02,			// キーボードデータ表示
      67,66,65,64,63,0xff,     // [F1][F2][F3][F4][F5]

      // 一段目
      0x01,			// 表示開始座標決定
      16,440,			// 位置決定
      0x02,			// キーボードデータ表示
      05,43,42,41,40,39,38,37,36,46,47,49,50,51,62,0xff,     // [GRPH]1234567890-+*[BRK]

      // 二段目
      0x01,			// 表示開始座標決定
      24,464,			// 位置決定
      0x02,			// キーボードデータ表示
      3,19,13,31,18,16,11,15,27,21,20,9,8,4,6,0xff,     // [ALPHA]QWERTYUIOP@(=[KANA]

      // 三段目
      0x01,			// 表示開始座標決定
      32,488,			// 位置決定
      0x02,			// キーボードデータ表示
      61,35,17,32,30,29,28,26,25,24,2,1,7,0,0xff,     // [CTRL]ASDFGHJKL;:)[CR]

      // 四段目
      0x01,			// 表示開始座標決定
      40,512,			// 位置決定
      0x02,			// キーボードデータ表示
      60,10,12,33,14,34,22,23,45,44,52,53,60,0xff,     // [SHIFT]ZXCVBNM,./?[SHIFT]

      // 離れ
      0x01,			// 表示開始座標決定
      480,416,		// 位置決定
      0x02,			// キーボードデータ表示
      59,58,0xff,     // [INS][DEL]
      
      0x01,			// 表示開始座標決定
      520,464,		// 位置決定
      0x02,			// キーボードデータ表示
      57, 0xFF,                // [↑]

      0x01,			// 表示開始座標決定
      504,488,		// 位置決定
      0x02,			// キーボードデータ表示
      54, 0xFF,                // [←]

      0x01,			// 表示開始座標決定
      536,488,		// 位置決定
      0x02,			// キーボードデータ表示
      55, 0xFF,                // [→]

      0x01,			// 表示開始座標決定
      520,512,		// 位置決定
      0x02,			// キーボードデータ表示
      56, 0xFF,                // [↓]

      // スペース
      0x01,			// 表示開始座標決定
      128,536,		// 位置決定
      0x02,			// キーボードデータ表示
      48,0xff,        // [SPACE]

      // EOD
      0x00			// EOD
    ];


    //コンストラクタ
    public function CSoftkey(main : asMZMem, memory : Cmem){
      m = main;
      mem = memory;

      // キーコード
      keylst = [
      _keylst( 3, "CR", 0x00 ),			// 00 [CR]  00
      _keylst( 0, ":", 0x01),			// 01 [:]   01
      _keylst( 0, ";", 0x02),			// 02 [;]   02
      _keylst( 3, "ALPH", 0x04), // 04 [英数]03
      _keylst( 0, "=", 0x05),          // 05 [=]   04
      _keylst( 3, "GRPH", 0x06),          // 06 [GRPH]05
      _keylst( 3, "KANA", 0x07),          // 07 KANA  06
      
      _keylst( 0, ")", 0x13),          // 13 [)]     07
      _keylst( 0, "(", 0x14),          // 14 [(]     08
      _keylst( 0, "@", 0x15),          // 15 [@]   09
      _keylst( 0, "Z", 0x16),          // 16 [Z]   10
      _keylst( 0, "Y", 0x17),          // 17 [Y]   11
      
      _keylst( 0, "X", 0x20),          // 20 [X]   12
      _keylst( 0, "W", 0x21),          // 21 [W]   13
      _keylst( 0, "V", 0x22),          // 22 [V]   14
      _keylst( 0, "U", 0x23),          // 23 [U]   15
      _keylst( 0, "T", 0x24),          // 24 [T]   16
      _keylst( 0, "S", 0x25),          // 25 [S]   17
      _keylst( 0, "R", 0x26),          // 26 [R]   18
      _keylst( 0, "Q", 0x27),          // 27 [Q]   19
      
      _keylst( 0, "P", 0x30),          // 30 [P]   20
      _keylst( 0, "O", 0x31),          // 31 [O]   21
      _keylst( 0, "N", 0x32),          // 32 [N]   22
      _keylst( 0, "M", 0x33),          // 33 [M]   23
      _keylst( 0, "L", 0x34),          // 34 [L]   24
      _keylst( 0, "K", 0x35),          // 35 [K]   25
      _keylst( 0, "J", 0x36),          // 36 [J]   26
      _keylst( 0, "I", 0x37),          // 37 [I]   27
      
      _keylst( 0, "H", 0x40),          // 40 [H]   28
      _keylst( 0, "G" ,0x41),          // 41 [G]   29
      _keylst( 0, "F", 0x42),          // 42 [F]   30
      _keylst( 0, "E", 0x43),          // 43 [E]   31
      _keylst( 0, "D", 0x44),          // 44 [D]   32
      _keylst( 0, "C", 0x45),          // 45 [C]   33
      _keylst( 0, "B", 0x46),          // 46 [B]   34
      _keylst( 0, "A", 0x47),          // 47 [A]   35

      _keylst( 0, "8", 0x50),          // 50 [8]   36
      _keylst( 0, "7", 0x51),          // 51 [7]   37
      _keylst( 0, "6", 0x52),          // 52 [6]   38
      _keylst( 0, "5", 0x53),          // 53 [5]   39
      _keylst( 0, "4", 0x54),          // 54 [4]   40
      _keylst( 0, "3", 0x55),          // 55 [3]   41
      _keylst( 0, "2", 0x56),          // 56 [2]   42
      _keylst( 0, "1", 0x57),          // 57 [1]   43
    
      _keylst( 0, ".", 0x60),          // 60 [.]   44
      _keylst( 0, ",", 0x61),          // 61 [,]   45
      _keylst( 0, "9", 0x62),          // 62 [9]   46
      _keylst( 0, "0", 0x63),          // 63 [0]   47
      _keylst( 0, "   SPACE   " ,0x64),      // 64 [SPACE]48
      _keylst( 0, "-", 0x65),          // 65 [-]   49
      _keylst( 0, "+", 0x66),          // 66 [+]   50
      _keylst( 0, "*", 0x67),          // 67 [*]   51

      _keylst( 0, "/", 0x70),          // 70 [/]   52
      _keylst( 0, "?", 0x71),          // 71 [?]   53
      _keylst( 0, "\x5F" , 0x72),          // 72 [<-]  54
      _keylst( 0, "\xC0" , 0x73),          // 73 [->]  55
      _keylst( 0, "\x80" , 0x74),          // 74 [cursor down]56
      _keylst( 0, "\x5E" , 0x75),          // 75 [cursor up]57
      _keylst( 2, "DEL", 0x76),          // 76 [DEL]58
      _keylst( 2, "INS", 0x77),          // 77 [INS]59
    
      _keylst( 3|8, "SHFT", 0x80),    // 80 [SHIFT]60 (TOGGLE)
      _keylst( 3|16, "CTRL", 0x86),    // 86 [CTRL]61 (TOGGLE)
      _keylst( 2, "BRK", 0x87),          // 87 [BREAK]62
      
      _keylst( 1,"F5", 0x93),          // 93 [F5]63
      _keylst( 1,"F4", 0x94),          // 94 [F4]64
      _keylst( 1,"F3", 0x95),          // 95 [F3]65
      _keylst( 1,"F2", 0x96),          // 96 [F2]66
      _keylst( 1,"F1", 0x97)           // 97 [F1]67
    ];

      // ソフトキー初期化
      softkey_init();
    }

    // キーボードパーツの描画
    // keykind : bit8 = push
    private function kb_parts_draw(x : int, y : int, keykind : int): int {
      var pk : Object = keylst[keykind & 0xFF];
      var str : String;
      var color : uint;
      var i : int;
      var result : int;

      color = pk.type;
      if ( (keykind & 0x100) != 0) { // 反転表示指定か？
        color |= 0x100;
      }
      
      str = pk.dispcode;
      result = (pk.type & 7)+1;	// 文字長
      m.mz_kbchr_put(x, y, str, color);
      
      return result;
    }

    

    //--------------------
    // ソフトキーの初期化
    //--------------------
    private function softkey_init() : void {
      var ptr : int;
      var ch : int, x : int, y : int;
      var klen : int;
      var pKa : int  = 0;

      ptr = 0;
      while (true) {
        ch = KEYPOS[ptr++];
        if (ch == 0)
          break;

        switch (ch) {
        case 0x01:
          x = KEYPOS[ptr];
          y = KEYPOS[ptr+1];
          ptr += 2;
          break;
          
          case 0x02:
            while (true) {
              ch = KEYPOS[ptr++];
              if (ch == 0xFF) {
                break;
              }
              // キーボード情報登録
              KEYAREA[pKa] = { keytag : new int(), rect : new Rectangle() };
              // キー配置情報の作成
              with (KEYAREA[pKa]) {
//                flag = 1;
                keytag = ch;
                rect.left = x;
                rect.top = y;
              }
              klen = keylst[ch].dispcode.length;
//              klen = (keylst[ch].type & 7)+1;
              
              with (KEYAREA[pKa]) {
               rect.width = (klen << 4);
               rect.height = 16;
              }
              x += ( ((klen << 3)+2) * 2);
//              trace("pKa = "+pKa);
              pKa++;
            }
           break;
        }
        
      }
      //
      nowkey = -1;        // 押されたキーは無し
      this.pa_bak = null;       // 以前押されていたキーの配置情報
    }

    // ソフトキーの描画
    public function softkey_draw() : void {
      var ch : int, x : int, y : int, num : int;
      var klen : int;
      var pKa : int;

      for (pKa = 0; pKa < KEYAREA.length; pKa++) {
        
        // キーボード表示
        klen = kb_parts_draw(KEYAREA[pKa].rect.left, KEYAREA[pKa].rect.top,
                             KEYAREA[pKa].keytag);
        
      }
      
    }

    // ソフトキーを離したときの描画
    public function softkey_upkeydraw(code : int) : void {
      var pKa : int; //skeyWk->keyarea;		// キー配置情報ワーク
      
//      trace("softkey_upkeydraw("+code+")");
      for (pKa = 0; pKa < KEYAREA.length; pKa++) {
		if (keylst[KEYAREA[pKa].keytag].keycode == code) {
          // キーボード表示
          kb_parts_draw(KEYAREA[pKa].rect.left,
                        KEYAREA[pKa].rect.top,
                        KEYAREA[pKa].keytag);
		}
      }
    }

    // ソフトキーを押したときの描画
    public function softkey_downkeydraw(code : int) : void {
      var pKa : int; //skeyWk->keyarea;		// キー配置情報ワーク
	
      for (pKa = 0; pKa < KEYAREA.length; pKa++) {
		if (keylst[KEYAREA[pKa].keytag].keycode == code) {
          // キーボード表示
          kb_parts_draw(KEYAREA[pKa].rect.left,
                        KEYAREA[pKa].rect.top,
                        KEYAREA[pKa].keytag|0x100);
		}
      }
    }

    // 引数の位置がソフトキーデータにヒットしているか
    public function softkey_search(x: int, y: int) : Object {
      var result : Object = null;
      var i : int;
      var xp : int, yp : int;
      var pKa : int;

//      trace("x="+x+" y="+y);
      
//      for (i=0; i<SOFTKEY_MAX; i++, pKa++) {
      for (pKa = 0; pKa < KEYAREA.length; pKa++) {
//        if (KEYAREA[pKa].flag == 0) {
//          continue;
//        }

		//
		xp = KEYAREA[pKa].rect.left;
		yp = KEYAREA[pKa].rect.top;
//        trace(i+": xp="+xp+" yp="+yp);
		
		if (x>=xp && y>=yp &&
			x<(xp+KEYAREA[pKa].rect.width) && y<(yp+KEYAREA[pKa].rect.height) )	{
          result = KEYAREA[pKa];
          break;
        }
      }
      
      return result;
    }

    // ソフトキー　押下
    public function softkey_down(x: int, y: int) : void {
      var pa : Object = softkey_search(x, y);
      var keyno : int = -1;

      if (pa != null) {
        keyno = pa.keytag;
      }

//      trace("softkey_down("+keyno+")");
      
      if (keyno >= 0) {
        // 前と違うキーが押されてたら
        if (this.nowkey != keyno) {
          // 前のキーは離す
          if (this.nowkey >= 0) {
            //
            softkey_upkeydraw(keylst[this.pa_bak.keytag].keycode);				// ソフトキーを離したときの描画
            this.pa_bak = null;
            mz_keyup(keylst[this.nowkey].keycode);
          }
        }
        this.nowkey = keyno;

		//
		if ((keylst[keyno].type & 24)!=0) {
          // Shift, CTRL
          this.nowkey = -1;
          this.pa_bak = null;
          var btn : Boolean;

          if ((keylst[keyno].type & 8)!=0) {
            btn = fShift;
          }
          if ((keylst[keyno].type & 16)!=0) {
            btn = fCtrl;
          }
          // トグルキー
          if (btn == true) { // 
            // 押されていたなら復帰
//            trace("toggle:up");
            softkey_upkeydraw(keylst[keyno].keycode); // ソフトキーを離したときの描画
//            mz_keyup(keylst[keyno].keycode);
            btn = false;
          } else {
            // 押されていなかったから押す
//            trace("toggle:down");
            softkey_downkeydraw(keylst[keyno].keycode); // ソフトキーを押したときの描画
//            mz_keydown(keylst[keyno].keycode);
            btn = true;
          }

          if ((keylst[keyno].type & 8)!=0) {
            fShift = btn;
          }
          if ((keylst[keyno].type & 16)!=0) {
            fCtrl = btn;
          }
          
        } else {
          // 通常
          // 押されたキーの表示
          softkey_downkeydraw(keylst[keyno].keycode); // ソフトキーを押したときの描画
          
          mz_keydown(keylst[keyno].keycode);
          this.pa_bak = pa;
        }
      } else {
        // ヘンなトコ押したので
        // 前のキーは離す
        if (this.nowkey >= 0) {
          mz_keyup(keylst[keyno].keycode);
          //
          softkey_upkeydraw(keylst[this.nowkey].keycode); // ソフトキーを離したときの描画
          this.pa_bak = null;
        }
        this.nowkey = -1;
      }

    }

    //
    public function softkey_up(x : int, y : int) : void {
      var pa : Object;
      var keyno : int = -1;

      if (this.pa_bak != null) {
        pa = pa_bak;
      } else {
        pa = softkey_search(x, y);
      }
      if (pa != null) {
        keyno = pa.keytag;
      }

//      trace("softkey_up("+keyno+")");
      
      if (keyno >= 0) {
        //
		if ((keylst[keyno].type & 24)==0) {
          // トグルキーでなかったら
          // ソフトキーの表示を復帰
          softkey_upkeydraw(keylst[keyno].keycode); // ソフトキーを離したときの描画
          this.pa_bak = null;
          
          this.nowkey = -1;
          mz_keyup(keylst[keyno].keycode);
        }
		
      }

    }

    // キーが押された（ソフトキーから呼び出し）
    private function mz_keydown(code : int) :void {
      mem.keyDown(code >> 4, code & 0x0F);
/*      
      if (fShift == true) {
        mem.keyDown(8, 0);
      }
      if (fCtrl == true) {
        mem.keyDown(8, 6);
      }
 */
    }
    
    // キーが離された（ソフトキーから呼び出し）
    private function mz_keyup(code : int) :void {
      mem.keyUp(code >> 4, code & 0x0F);
      /*
      if (fShift == true) {
        mem.keyUp(8, 0);
      }
      if (fCtrl == true) {
        mem.keyUp(8, 6);
      }
        */
    }

    // キーが押されているか
    private function mz_keychk(code : int) : Boolean {
      var r : Boolean = mem.keyChk(code >> 4, code & 0x0F);
//      trace("mz_keychk()="+r);
      return mem.keyChk(code >> 4, code & 0x0F);
    }

    // 構造体
    private function _keylst(tp : int, disp: String, kcode : int) : Object {
      return { type: tp, dispcode: disp, keycode: kcode };
    }



  }
}
