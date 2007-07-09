/////////////////////////////////////////////////////////////////////////////
// MZ-700 Emulator "MZ-Memories" for ActionScript 3.0
// asMZMem Class
//
// $Id$
// Programmed by Takeshi Maruyama (Marukun)
////////////////////////////////////////////////////////////////////////////

package {
  import flash.ui.*;
  import flash.display.*;
  import flash.geom.*
  import flash.utils.ByteArray;
  import flash.events.*;

//  import flash.events.Event;

  
  //文字列を表示する
  public class asMZMem extends Sprite {

    // ＲＯＭモニタ
    [Embed(source='data/NEWMON7.ROM', mimeType='application/octet-stream')] 
	  private static const RomMon: Class;

    // テープイメージ
    [Embed(source='data/WH_newmon.mzt', mimeType='application/octet-stream')] 
	  private static const MztImg: Class;
    
    // key.def
    [Embed(source='./key.def', mimeType='application/octet-stream')] 
	  private static const KeyDef: Class;
    
    // フォント
    [Embed(source='./data/font0.png')] 
	  private var Font0: Class;
    [Embed(source='./data/font1.png')] 
	  private var Font1: Class;
    [Embed(source='./data/font2.png')] 
	  private var Font2: Class;
    [Embed(source='./data/font3.png')] 
	  private var Font3: Class;
    [Embed(source='./data/font4.png')] 
	  private var Font4: Class;
    [Embed(source='./data/font5.png')] 
	  private var Font5: Class;
    [Embed(source='./data/font6.png')] 
	  private var Font6: Class;
    [Embed(source='./data/font7.png')] 
	  private var Font7: Class;

    private static const font:Array = new Array(8); //イメージ

    // カラー
    private static const col: Array = [
      0x000000, 0x0000FF, 0xFF0000, 0xFF00FF,
      0x00FF00, 0x00FFFF, 0xFFFF00, 0xFFFFFF
      ];

    // ＶＭ関連
    private var _8253: C8253 = new C8253(); // ８２５３クラス
    private var mem: Cmem = new Cmem(_8253); // メモリクラス
    private var io: Cio = new Cio(mem); // Ｉ／Ｏクラス
    private var z80: Cz80 = new Cz80(_8253, mem, io); // Ｚ８０クラス

    // キー定義状態
    private var keytbl: Array = new Array(256);

    // アプレット状態
    private static var ST: int;

    // Shift状態
    private static var fShift: Boolean = false;
    private static var fCtrl: Boolean = false;
    private static var couKeyUp: int;
    
    // 仮想画面
    private static var offImg: BitmapData;
    // 子スプライト
    private static var child: Sprite;


    //コンストラクタ
    public function asMZMem(){

      trace("asMZMem()");
      // ＲＯＭモニタ
      var monitor: ByteArray = new RomMon() as ByteArray;
      // ＭＺＴイメージ
      var mzt: ByteArray = new MztImg() as ByteArray;

      child = new Sprite();
      addChild(child);

      // イベントリスナーの登録
      child.addEventListener(KeyboardEvent.KEY_DOWN,keyDownHandler);
      child.addEventListener(KeyboardEvent.KEY_UP,keyUpHandler);
      child.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
      child.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { stage.focus = child; });

      // 仮想画面追加
      offImg = new BitmapData(640, 400, false, 0xffffffff);
      child.addChild(new Bitmap(offImg));

      // フォーカス枠の消去
      stage.stageFocusRect = false;
      // フォーカス
      stage.focus = child;

      // key.def
      var keydef:ByteArray = new KeyDef();
      setup_key(keydef);

      // フォントセットアップ
      font[0] = new Font0();
      font[1] = new Font1();
      font[2] = new Font2();
      font[3] = new Font3();
      font[4] = new Font4();
      font[5] = new Font5();
      font[6] = new Font6();
      font[7] = new Font7();

      // ＲＯＭモニタセットアップ
      monitor_load(monitor);

      // ＭＺＴロード
      loadMZT(mzt);
      resetAll();               // リセット

/*
      //ラベルの追加
      var label:TextField=makeLabel("Hello World!");
      label.x=10;     //X座標
      label.y=10;     //Y座標
      addChild(label);//追加
*/

    }

    // 更新イベント
    private function enterFrameHandler(evt:Event):void {

      // Shiftキーの更新
      if (fShift) {
        mem.keyDown(8, 0);
      } else {
        mem.keyUp(8, 0);
      }

      // Ctrlキーの更新
      if (fCtrl) {
        mem.keyDown(8, 6);
      } else {
        mem.keyUp(8, 6);
      }

      //
	  switch (ST) {
	   case 0:
//        fillRect(0, 0, 640, 400, 0x0000FF);
        ST = 1;
        break;
	      	
	   case 1:
        // 初期化ロード
/*
        // ロード
		 load_job();
	    
		 // 引数によるＭＺＴ始動
//		 String fname = getParameter("mzt");
         String fname = "BdHopper.mzt";
		 if (fname != null) {
			loadMZT(fname);
		 }
  */
        
        mem.keyClear();         // キーボード初期化
	     resetAll();	     // リセット
        
	     ST = 2;
	     break;
      
      case 2:
//        updateKeyboard();       // キーボード更新
        
        // キー挙動　調整
        if (couKeyUp >0 ) {
          if ((--couKeyUp)==0) {
            mem.keyClear();
            trace("keyClear()");
          }
        }
        z80.update(int(Cz80.CPU_SPEED/30)); // ＣＰＵ実行：秒間３０ｆ

/*        
        // MZT読み込み
        if (fLoad) {
          fLoad = false;
          //	        loadMZT(sGameFile);
        }
  */

        break;
	  } // switch

      // ここで描画してあげる
	  switch (ST) {
	   case 0:
        // 初期化
        break;

	   case 1:
        // ロード
        break;

      case 2:
        // 描画
        drawScreenBG();
//        offImg.lock();
//        offImg.copyPixels(font[7].bitmapData, new Rectangle(0, 0, 128, 128), new Point(0, 0));
//        offImg.unlock();
        drawScreenFG();
        break;

      }

    }

    // キーダウンイベント
    private function keyDownHandler(evt:KeyboardEvent):void {
//      var c_sft: Boolean = false;
      
      trace("Key Down: keyCode="+evt.keyCode.toString(16)+" charCode="+evt.charCode.toString(16));

      if (evt.keyCode == 0x10) {
        // Shift
        fShift = true;
//        return;
      }
      if (evt.keyCode == 0x11) {
        // Ctrl
        fCtrl = true;
//        return;
      }

      // ActionScript3.0の、キーイベント取りこぼし対策
      // Shift or Ctrlを押したままキーを放すと、keyUpイベントが起きない
      if (fShift || fCtrl) {
        couKeyUp = 2;
      }

      // Shift
      /*
      if (evt.keyCode == Keyboard.SHIFT) {
        mem.keyDown(8, 0);
        evt.updateAfterEvent();
        return;
      };
        */
      // Shift
//      if (evt.shiftKey) {
//        mem.keyDown(8, 0);
//        evt.keyCode = 0x10;
//      }
      // Ctrl
      /*
      if (evt.ctrlKey) {
        mem.keyDown(8, 6);
        evt.keyCode = 0x11;
      }
        */

      var ks: int = keytbl[evt.keyCode];
      if (ks >= 0) {
        mem.keyDown(ks >> 4, ks & 0x0F);
      }

  //    evt.updateAfterEvent();
    }

    // キーアップイベント
    private function keyUpHandler(evt:KeyboardEvent):void {
      trace("Key Up: keyCode="+evt.keyCode.toString(16));
      
      if (evt.keyCode == 0x10) {
        // Shift
        fShift = false;
//        return;
      }
      if (evt.keyCode == 0x11) {
        // Shift
        fCtrl = false;
//        return;
      }
      
/*      
      if (evt.shiftKey) {
        mem.keyUp(8, 0);
        evt.keyCode = 0x10;
      }
  */
      /*
      // Ctrl
      if (evt.ctrlKey) {
        mem.keyUp(8, 6);
        evt.keyCode = 0x11;
      }
        */

      var ks: int = keytbl[evt.keyCode];
      if (ks >= 0) {
        mem.keyUp(ks >> 4, ks & 0x0F);
      }
      
//      evt.updateAfterEvent();
    }

    // 矩形描画
    private function fillRect(x:int, y:int ,w:uint,h: uint, color:uint): void {
      offImg.fillRect(new Rectangle(x, y, w, h), color);
    }

    // イメージの描画
    public function drawImage(source:IBitmapDrawable, x:int, y:int):void {
      var pos:Matrix = new Matrix();
      pos.translate(x, y);
      offImg.draw(source, pos);
    }

    // イメージの部分描画
    public function drawRegion(source:Bitmap, x:int, y:int, clip:Rectangle):void {
      offImg.copyPixels(source.bitmapData, clip, new Point(x, y));
    }

    //--------------------------
    // MZ-700の画面描画（文字）
    //--------------------------
    private function drawScreenFG(): void {
      var i:int, j:int;
      var x:int, y:int;
      var a:int, c:int, vo:int, vo2:int;
      var sx:int, sy:int;
      var t:int;
      var vram:Array = mem.getMem();
      var srcrect:Rectangle;

      // 描画
      vo = Cmem.VID_START;
      vo2 = 0;
      y = 0;
      for (i=0; i<25; i++) {
        x = 0;
        for (j=0; j<40; j++) {
          a = vram[vo] & 0xFF;
          c = vram[vo+0x800] & 0xFF;
          t = (c << 8) | a;
          
          if ((c & 0x80)!=0) {  // colorのbit7チェック
            a += 0x100;
          }

          // 背景色描画
          sx = (a & 15) << 4;
          sy = (a & 0x1F0);
          srcrect = new Rectangle(sx, sy, 16, 16);            // 表示元
//          srcrect = new Rectangle(16, 16, 16, 16);            // 表示元
          drawRegion(font[(c & 0x70)>>4], x, y, srcrect);
          
          x += 16;
          vo++;
          vo2++;
        }
        y += 16;
      }
    }

    //--------------------------
    // MZ-700の画面描画（背景）
    //--------------------------
    private function drawScreenBG(): void {
      var i: int, j: int;
      var x: int, y: int;
      var a: int, c: int, vo: int, vo2: int;
      var t: int;
      var vram:Array = mem.getMem();

      // ポリゴン描画の開始
      vo = Cmem.VID_START;
      vo2 = 0;
      y = 0;
      for (i=0; i<25; i++) {
        x = 0;
        for (j=0; j<40; j++) {
          a = vram[vo] & 0xFF;
          c = vram[vo+0x800] & 0xFF;
          t = (c << 8) | a;

          if ((c & 0x80)!=0) {  // colorのbit7チェック
            a += 0x100;
          }

          // 背景色描画
          fillRect(x, y, 16, 16, col[c & 7]); // 背景色
          
          x += 16;
          vo++;
          vo2++;
        }
        y += 16;
      }

    }

    //---------------
    // キー配列の定義
    //---------------
    private function setup_key(keydef: ByteArray): void {
      // keytbl[]
      var def:String = keydef.toString();
      var i: int, j:int;
      var done: Boolean = false;
      var lst: Array = def.split("\r\n");
      var arg: Array;

      for (i=0; i<256; i++) {
        keytbl[i] = -1;
      }

      for (i=0; i<lst.length; i++) {
        var str: String = new String(lst[i]);

        // コメント消去
        j = str.indexOf("//");
        if (j >= 0) {
          str = str.slice(0, j);
        }
        
        if (str.length == 0) {
          // 空行はスキップ
          continue;
        }

        // 引数解析
        arg = str.split("=");

        var kc: int, bit:int;
        // キーコード
        kc = parseInt(arg[1], 16);
        // MZ-700のキープローブ
        bit = parseInt(arg[0], 16);

        keytbl[kc] = bit;

        trace("keytbl["+kc.toString(16)+"]="+bit.toString(16));
        
//        trace(str);
      }

    }

    //-------------------
    // 全てのリセット  
    //-------------------
    private function resetAll(): void {
      z80.reset();
    }

    //------------------------
    // ＲＯＭモニタロード処理
    //------------------------
    private function monitor_load(mon: ByteArray):void {
      var i: int;

      trace("monitor_load_job()");
      
      // モニタＲＯＭ初期化
      var b:Array = mem.getMem();
      for (i=0x3FF; i>=0; i--) {
        b[i] = 0xC9;
      }

      // モニタＲＯＭ読み込み
      for (i=0; i<mon.length; i++) {
        b[i] = mon[i];
      }

        // NEW MONITOR用パッチ
        // SCROLL
        b[Cmem.ROM_START+0x0e42] = 0xed;
        b[Cmem.ROM_START+0x0e43] = 0xf0;

        // ?QDPCT
        b[Cmem.ROM_START+0x0dbc] = 0xed;
        b[Cmem.ROM_START+0x0dbd] = 0xf1;
        b[Cmem.ROM_START+0x0dbe] = 0xc9;

        // ?DSP
        b[Cmem.ROM_START+0x0db5] = 0xed;
        b[Cmem.ROM_START+0x0db6] = 0xf2;
        b[Cmem.ROM_START+0x0db7] = 0xc9;

        // ?ADCN
        b[Cmem.ROM_START+0x0bb9] = 0xed;
        b[Cmem.ROM_START+0x0bba] = 0xf3;
        b[Cmem.ROM_START+0x0bbb] = 0xc9;

        // ?DACN
        b[Cmem.ROM_START+0x0bce] = 0xed;
        b[Cmem.ROM_START+0x0bcf] = 0xf4;
        b[Cmem.ROM_START+0x0bd0] = 0xc9;

        // ?PRT
        b[Cmem.ROM_START+0x0946] = 0xed;
        b[Cmem.ROM_START+0x0947] = 0xf5;
        b[Cmem.ROM_START+0x0948] = 0xc9;

    }

    //-----------------------
    // テープファイル読み込み
    //-----------------------
    public function loadMZT(mzt: ByteArray) : Boolean {
      var top: uint, sz: uint, ex: uint;
      var i: int;
      var fOk: Boolean;
      var b: Array;

      fOk = false;
      ex = 0x0000;

      sz = (mzt[18]&255) | ((mzt[19]&255)<<8);
      top = (mzt[20]&255) | ((mzt[21]&255)<<8);
      ex = (mzt[22]&255) | ((mzt[23]&255)<<8);
      
      b = mem.getMem();
      for (i=0; i<sz; i++) {
        b[Cmem.RAM_START+top+i] = mzt[128+i];
      }
      
      fOk = true;

      // 読み込み成功だったら実行
      if (fOk) {
        z80.execProg(ex);
      }

      return fOk;
    }


    
  }
}
