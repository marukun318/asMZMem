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
  import flash.net.*;
  import flash.text.*;

  //文字列を表示する
  public class asMZMem extends Sprite {

    // ＲＯＭモニタ
    [Embed(source='data/NEWMON7.ROM', mimeType='application/octet-stream')] 
//    [Embed(source='data/1Z009.ROM', mimeType='application/octet-stream')] 
	  private static const RomMon: Class;

    // key.def
    [Embed(source='./key.def', mimeType='application/octet-stream')] 
	  private static const KeyDef: Class;
    
    // フォント
    [Embed(source='./data/font7.png', mimeType='application/octet-stream')] 
	  private var Font: Class;

    private static const font:Array = new Array(8); //イメージ
    private static var fnt: ByteArray // フォントバイナリ

    // ステート定数
    private static const ST_ROMMON : int = 0; // ＲＯＭモニタセットアップ
    private static const ST_FONT : int = 1; // フォントセットアップ
    private static const ST_FONTWAIT : int = 2; // フォントセットアップ待機
    private static const ST_FONTNEXT : int = 3; // 次のフォントへ
    private static const ST_MZT : int = 4; // ＭＺＴダウンロード
    private static const ST_MZTWAIT : int = 5; // ＭＺＴダウンロード待機
    private static const ST_ENGINEINIT : int = 8; // エンジン初期化
    private static const ST_RUNNING : int = 9; // エンジン実行
    
    // カラー
    private static const col: Array = [
      0x000000, 0x0000FF, 0xFF0000, 0xFF00FF,
      0x00FF00, 0x00FFFF, 0xFFFF00, 0xFFFFFF
      ];

    // キーボードカラー
    private static const kb_col1 : Array = [
      0xf0f0f0, 0x2e24fa, 0xf8ae2d, 0xf8ae2d
      ];
    // キーボードカラー（影）
    private static const kb_col2 : Array = [
      0x9c9c9b, 0x151074, 0x815a17, 0x815a17
      ];

    // サウンドドライバ
    private var dyn_sound : CSoundDriver = new CSoundDriver();
    
    // ＶＭ関連
    private var _8253: C8253 = new C8253(dyn_sound); // ８２５３クラス
    private var mem: Cmem = new Cmem(_8253); // メモリクラス
    private var io: Cio = new Cio(mem); // Ｉ／Ｏクラス
    private var z80: Cz80 = new Cz80(_8253, mem, io); // Ｚ８０クラス

    // ソフトキー
    private var skey : CSoftkey;

    // キー定義状態
    private var keytbl: Array = new Array(256);

    //ＶＲＡＭテンポラリ
    private static var vtmp : Array = new Array(0x1000);

    // CRC-Table
    private static var CRC_TBL : Array = new Array(256);

    // アプレット状態
    private static var ST: int;

    // Shift状態
    private static var fShift: Boolean = false;
    private static var fCtrl: Boolean = false;
    private static var couKeyUp: int;

    // 読み込みフォントインデックス
    private static var loadFont : int;

    // 読み込みmztファイル名
    private static var mztname : String = "data/WH_newmon.mzt";
    
    // 仮想画面
    private static var offImg: BitmapData;
    // 子スプライト
    private static var child: Sprite;

    // 文字表示用
    private static var label: TextField;
    private static var format: TextFormat; //フォーマット
    //コンストラクタ
    public function asMZMem(){
      skey = new CSoftkey(this, mem); // ソフトキークラスの作成

      ST = ST_ROMMON;           // ＲＯＭモニタセットアップ

      //ラベル
      label = new TextField();
      label.autoSize = TextFieldAutoSize.LEFT;
      label.text = "MOJI TEST";

       // フォーマット
      format = new TextFormat();
      format.font ="_等幅";
      format.size = 13;
      format.color = 0x000000;

      //
      child = new Sprite();
      addChild(child);

      // 仮想画面追加
      offImg = new BitmapData(stage.stageWidth, stage.stageHeight, false, 0xffffffff);
      child.addChild(new Bitmap(offImg));

      // イベントリスナーの登録
      child.addEventListener(KeyboardEvent.KEY_DOWN,keyDownHandler);
      child.addEventListener(KeyboardEvent.KEY_UP,keyUpHandler);
      child.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
      child.addEventListener(MouseEvent.CLICK, mouseClickHandler);
      child.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
      child.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);

      // フォーカス枠の消去
      stage.stageFocusRect = false;
      // フォーカス
      stage.focus = child;

      // 初期化文字列
//      drawString("Now Initializing...", 0, 0);

      // CRCの初期化
      var i : int, j : int;
      for (i = 0; i < 256; i++) {
        var l: uint = i;
        for (j = 0; j < 8; j++) {
          if (l & 1) {
            l = uint(uint(0xedb88320) ^ uint(l >>> 1));
          } else {
            l = uint(l >>> 1);
          }
        }
        CRC_TBL[i] = l;
      }

      // key.def
      var keydef:ByteArray = new KeyDef();
      setup_key(keydef);

      // フォントをByteArrayで読み込み
      fnt = new Font() as ByteArray;

      // Ｗｅｂ引数取得
      var flashvars:Object;
      var param1:String;
      var param2:String;
      
      flashvars = LoaderInfo(loaderInfo).parameters;
      param1 = flashvars["mzt"];
      param2 = flashvars["param2"];

      if (param1 != null) {
        mztname = param1;
      }
      
//      trace("mztname = "+mztname);
//      trace("param2 = "+param2);
    }

    // 更新イベント
    private function enterFrameHandler(evt:Event):void {
      //
	  switch (ST) {
	   case ST_ROMMON:
        // ＲＯＭモニタ読み込み
        var monitor: ByteArray = new RomMon() as ByteArray;

        // ＲＯＭモニタセットアップ
        monitor_load(monitor);

        //
        loadFont = 0;
        ST = ST_FONT;
        break;
	      	
	   case ST_FONT:
        // フォント初期化
        var ofs : int = searchPLTE(fnt); // パレットチャンクを探す
        
        var a : int;
        // パレット動的作成
//        trace("loadFont="+loadFont);
        if ((loadFont & 2) != 0) {
          a = 0xFF;
        } else {
          a = 0x00;
        }
        fnt[ofs+11] = a;
        
        if ((loadFont & 4) != 0) {
          a = 0xFF;
        } else {
          a = 0x00;
        }
        fnt[ofs+12] = a;
        
        if ((loadFont & 1) != 0) {
          a = 0xFF;
        } else {
          a = 0x00;
        }
        fnt[ofs+13] = a;
        
        //
        update_CRC(fnt, ofs);  // CRC更新
        
        //
        var loader:Loader = new Loader();
      
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
        loader.loadBytes(fnt);

        ST = ST_FONTWAIT;
        break;

        case ST_FONTWAIT:
        break;
        
        case ST_FONTNEXT:
        // 次のフォントチェック
        if ((++loadFont)>7) {
          // 読み込み終了
          ST = ST_MZT;
        } else {
          // 次のフォントへ
          ST = ST_FONT;
        }
        break;
        

      case ST_MZT:
        // ＭＺＴロード
        
        // 空プログレスバー描画
        drawProgressBar(0, 100);
        
        // リクエストの生成
        var request:URLRequest = new URLRequest(mztname);
        
        //ローダーの生成
        var binloader:URLLoader = new URLLoader();
        binloader.dataFormat = URLLoaderDataFormat.BINARY;

        //リスナーの指定
        binloader.addEventListener(ProgressEvent.PROGRESS,           mzt_progressHandler);
        binloader.addEventListener(Event.COMPLETE,                   mzt_completeHandler);
        binloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,mzt_securityErrorHandler);
        binloader.addEventListener(IOErrorEvent.IO_ERROR,            mzt_ioErrorHandler);

        //XMLの読み込み
        binloader.load(request);

        ST = ST_MZTWAIT;
        break;

      case ST_MZTWAIT:
        // バイナリロード待ち
        break;
        
      case ST_ENGINEINIT:
        // 起動直前
        dyn_sound.start();      // サウンドドライバの開始
        mem.keyClear();         // キーボード初期化
        resetAll();             // リセット

        // ソフトキーボード描画
        skey.softkey_draw();
        
        ST = ST_RUNNING;
        break;
      
      case ST_RUNNING:
        // Shiftキーの更新
        if (fShift || skey.fShift) {
          mem.keyDown(8, 0);
        } else {
          mem.keyUp(8, 0);
        }

        // Ctrlキーの更新
        if (fCtrl || skey.fCtrl) {
          mem.keyDown(8, 6);
        } else {
          mem.keyUp(8, 6);
        }
        
        // キー挙動　調整
/*        
        if (couKeyUp >0 ) {
          if ((--couKeyUp)==0) {
            mem.keyUp(8, 0);    // shift
            mem.keyUp(8, 6);    // ctrl

//            mem.keyClear();
//            trace("keyClear()");
          }
        }
*/
        z80.update(int(Cz80.CPU_SPEED/60)); // ＣＰＵ実行：秒間３０ｆ
        dyn_sound.update(0);     // サウンド更新
        
        z80.update(int(Cz80.CPU_SPEED/60)); // ＣＰＵ実行：秒間３０ｆ
        dyn_sound.update(1);     // サウンド更新

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
//       case ST_MZT:
//       case ST_MZTWAIT:

//        break;


      case ST_RUNNING:
        // 描画
        drawScreen700();
        break;

        // 初期化
      default:
        break;

      }

    }

    // キーダウンイベント
    private function keyDownHandler(evt:KeyboardEvent):void {
//      var c_sft: Boolean = false;
      
//      trace("Key Down: keyCode="+evt.keyCode.toString(16)+" charCode="+evt.charCode.toString(16));

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
//      trace("Key Up: keyCode="+evt.keyCode.toString(16));
      
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

    // マウスクリックハンドラー
    private function mouseClickHandler(e:MouseEvent) : void {
      stage.focus = child;
    }

    // マウスアップハンドラー
    private function mouseUpHandler(e:MouseEvent) : void {
//      trace("mouseUpHandler() x="+e.localX+" y="+e.localY);

      skey.softkey_up(e.localX, e.localY);
    }

    // マウスダウンハンドラー
    private function mouseDownHandler(e:MouseEvent) : void {
//      trace("mouseDownHandler()");

      skey.softkey_down(e.localX, e.localY);
    }

    //--------------------------
    // BITMAP download handler
    //--------------------------

    // loader complete Handler
    private function completeHandler(event:Event):void {
      var ldr:Loader = Loader(event.target.loader);

//      trace(loadFont+":completeHandler("+ldr.content+")");

      // プログレスバー描画
      drawProgressBar(loadFont+1, 8);

      font[loadFont] = Bitmap(ldr.content);

      ST = ST_FONTNEXT;
    }

    // loader error handler
    private function ioErrorHandler(event:IOErrorEvent):void {
      drawString("Unable to load image", 0, 13);
    }

    //--------------------------
    // binary download handler
    //--------------------------

    // プログレスイベントの処理
    private function mzt_progressHandler(evt:ProgressEvent):void {
//      trace("ロード中 "+evt.bytesLoaded+"/"+evt.bytesTotal);
//      drawString("ロード中 "+evt.bytesLoaded+"/"+evt.bytesTotal, 0, 13);

      // プログレスバー描画
      drawProgressBar(evt.bytesLoaded, evt.bytesTotal);
    }
    
    // 完了イベントの処理
    private function mzt_completeHandler(evt:Event):void {
      var loader:URLLoader = URLLoader(evt.target);

      // プログレスバー描画
      drawProgressBar(100, 100);

      // MZT読み込みバッファ
      var mztbuf : ByteArray = loader.data;

      // mzt読み込み
      loadMZT(mztbuf);

      // ステート変更
      ST = ST_ENGINEINIT;
    }

    // ダウンロードゲージ 描画
    private function drawProgressBar(now:int, max:int): void {
      var w : int = 240;
      var h : int = 24;
      var x : int = (640 - w) / 2;
      var y : int = (400 - h) / 2;

      // ベース
      fillRect(x, y, w, h, 0x010101);
      x += 2;
      y += 2;
      w -= 4;
      h -= 4;

      var a : int = (now << 16) / max;
      a = (a * w) >> 16;

      // 中身
      fillRect(x, y, a, h, 0xFF0000);
      
    }

    
    //IOエラーイベントの処理
    private function mzt_ioErrorHandler(evt:IOErrorEvent):void {
      drawString("ダウンロードエラー", 0, 13);
    }
    
    //セキュリティエラーイベントの処理
    private function mzt_securityErrorHandler(evt:SecurityErrorEvent):void {
      drawString("セキュリティエラー", 0, 13);
    }

    // 矩形描画（塗りつぶしあり）
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

    // 文字列の描画
    private function drawString(text:String, x:int, y:int): void {
      label.text = text;
      label.setTextFormat(format);
      var pos:Matrix = new Matrix();
      pos.translate(
        x - (label.width  - label.textWidth) / 2,
        y - (label.height - label.textHeight) / 2);
//        y - (label.height - label.textHeight) / 2 - label.textHeight);
      offImg.draw(label, pos);
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
//          t = (c << 8) | a;

//          if ((c & 0x80)!=0) {  // colorのbit7チェック
//            a += 0x100;
//          }

          // 背景色描画
          fillRect(x, y, 16, 16, col[c & 7]); // 背景色
          
          x += 16;
          vo++;
          vo2++;
        }
        y += 16;
      }

    }

  
  //------------------------------
  // MZ-700の画面描画（最適化版）
  //------------------------------
  private function drawScreen700() : void {
    var i : int, j : int;
    var x : int, y : int;
    var a : int, c : int, vo : int, vo2 : int;
    var sx:  int, sy : int;
    var t : int;
    var vram : Array = mem.getMem();
    var srcrect : Rectangle;

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
        
        if (vtmp[vo2] != t) {
          // テキスト書き換え
          // バックカラーfill
          fillRect(x, y, 16, 16, col[c & 7]);
          // 文字描画
          sx = (a & 15) << 4;
          sy = (a & 0x1F0);
          srcrect = new Rectangle(sx, sy, 16, 16);            // 表示元
          drawRegion(font[(c & 0x70)>>4], x, y, srcrect);
          //
          vtmp[vo2] = t;
        }
        x += 16;
        vo++;
        vo2++;
      }
      y += 16;
    }
    


  }

    // MZフォントで文字列表示
    public function mz_print(str : String, x : int, y : int, col : int): void {
      var i : int;
      var ch : int;
      var srcrect : Rectangle;
      var sx : int;
      var sy : int;

      for (i=0; i<str.length; i++, x += 16) {
        ch = str.charCodeAt(i);
        // コード変換
        ch = Cz80.asc2disp_j[ch];

        if (ch == 0) {
          continue;
        }

        // 描画
        sx = (ch & 15) << 4;
        sy = (ch & 0x1F0);
        srcrect = new Rectangle(sx, sy, 16, 16);            // 表示元
        drawRegion(font[col], x, y, srcrect);

      }

    }

    // MZの画面にテキスト文字を表示（ＱＶＧＡ）
    //
    //In:	x = chr.X
    //		y = chr.Y
    //		code  = Display Code
    //		color = Color type 0=白 1=青 2=オレンジ bit8=push
    // color bit8=左ライン
    public function mz_kbchr_put(x : int, y: int, str : String, color : uint) : void {
      var sx : int;
      var sy : int;
      var len : int = str.length;
      var mcol : int = 0;
      var c1 : int;
      var c2 : int;

      if ((color & 7) != 0) {
        mcol = 7;
      }
      if ((color & 0x100) != 0) {
        // キーボード押された
        c1 = kb_col2[color & 7];
        c2 = kb_col1[color & 7];
      } else {
        // キーボード普通
        c2 = kb_col2[color & 7];
        c1 = kb_col1[color & 7];
      }

      fillRect(x, y, len*16, 16, c2);
      fillRect(x, y, len*16-2, 14, c1);
      // キートップ
      mz_print(str, x-1, y-1, mcol);
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

//        trace("keytbl["+kc.toString(16)+"]="+bit.toString(16));
      }

    }

    //-------------------
    // 全てのリセット  
    //-------------------
    private function resetAll(): void {
      // ＶＲＡＭテンポラリの初期化
      for (var i : int = 0; i<0x1000; i++) {
        vtmp[i] =- 1;
      }

      z80.reset();
    }

    //------------------------
    // ＲＯＭモニタロード処理
    //------------------------
    private function monitor_load(mon: ByteArray):void {
      var i: int;

//      trace("monitor_load_job()");
      
      // モニタＲＯＭ初期化
      var b:Array = mem.getMem();
      for (i=0x3FF; i>=0; i--) {
        b[i] = 0xC9;
      }

      // モニタＲＯＭ読み込み
      for (i=0; i<mon.length; i++) {
        b[i] = mon[i];
      }

      if (b[0x06F3] != '1') {
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

    //-----------
    // CRCを計算
    //-----------
    private function crc(abyte0 : ByteArray, pos : int, len : int) : uint {
      var l : uint = 0xffffffff;

      abyte0.position = pos;
      for (var j: int = 0; j < len; j++) {
        l = uint(CRC_TBL[(l ^ abyte0.readUnsignedByte()) & uint(0x00ff)] ^ uint(l >>> 8) );
      }
      return l ^ uint(0xffffffff);
    }

    //---------------------
    // チャンクのCRCを更新
    //---------------------
    // b[] = チャンクのbyte配列を示す
    private function update_CRC(b : ByteArray, ofs : int) : void {
      var len : int = (b[ofs]&0x00ff)<<24 | (b[ofs+1]&0x00ff)<<16 | (b[ofs+2]&0x00ff)<<8 | (b[ofs+3]&0x00ff);
      var l : uint = crc(b, ofs+4, len+4); // include chunk name

//      trace("update_CRC("+strHex(ofs,8)+") len="+len+" crc="+strHex(l, 8));
      b[ofs+len+8] = ((l >>> 24) & 255);
      b[ofs+len+9] = ((l >>> 16) & 255);
      b[ofs+len+10] =((l >>> 8) & 255);
      b[ofs+len+11] =(l & 255);
    }

    //------------------------
    // パレットチャンクを探す
    //------------------------
    // 戻り値ofs=PLTEチャンクの先頭
    // 'PLTE' (4bytes)
    // Bytes (4bytes)
    // PAL DATA = (ofs+8)
    private static function searchPLTE(png : ByteArray) : int {
      var ofs : int = 0;
    
      while (true) {
        if (png[ofs] == 0x50) { // P
          if (png[ofs+1] == 0x4C) { // L
            if (png[ofs+2] == 0x54) { // T
              if (png[ofs+3] == 0x45) { // E
                break;
              }
            }
          }
        }
        ofs++;
      }
      // パレット更新
      ofs -= 4;
      
      return ofs;
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
