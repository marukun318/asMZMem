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
    // ���C���N���X
    private static var m : asMZMem;

    // �\�t�g�L�[�̍ő吔
    private static const SOFTKEY_MAX : int = 100;

    private var nowkey : int;   // ���݉�����Ă���L�[�R�[�h
	private var keymap : int;   // ���ݕ\������Ă���L�[�}�b�v
//   	pTKEYAREA pa_bak;           // �ȑO������Ă����L�[�̔z�u���

    // �\�t�g�L�[�z�u���
    private static var KEYAREA : Array = new Array();

    // �\�t�g�L�[�z���`
    private static var keylst : Array = new Array();
    
    // �L�[�z�u
    private static const KEYPOS : Array = [
      // ��i��
      0x01,			// �\���J�n���W����
      16,0,200,0,			// �ʒu����
      0x02,			// �L�[�{�[�h�f�[�^�\��
      67,66,65,64,63,0xff,     // [F1][F2][F3][F4][F5]

      // ��i��
      0x01,			// �\���J�n���W����
      0,0,208,0,			// �ʒu����
      0x02,			// �L�[�{�[�h�f�[�^�\��
      05,43,42,41,40,39,38,37,36,46,47,49,50,51,62,0xff,     // [GRPH]1234567890-+*[BRK]

      // ��i��
      0x01,			// �\���J�n���W����
      4,0,216,0,			// �ʒu����
      0x02,			// �L�[�{�[�h�f�[�^�\��
      3,19,13,31,18,16,11,15,27,21,20,9,8,4,6,0xff,     // [ALPHA]QWERTYUIOP@(=[KANA]

      // �O�i��
      0x01,			// �\���J�n���W����
      8,0,224,0,			// �ʒu����
      0x02,			// �L�[�{�[�h�f�[�^�\��
      61,35,17,32,30,29,28,26,25,24,2,1,7,0,0xff,     // [CTRL]ASDFGHJKL;:)[CR]

      // �l�i��
      0x01,			// �\���J�n���W����
      12,0,232,0,			// �ʒu����
      0x02,			// �L�[�{�[�h�f�[�^�\��
      60,10,12,33,14,34,22,23,45,44,52,53,60,0xff,     // [SHIFT]ZXCVBNM,./?[SHIFT]

      // ����
      0x01,			// �\���J�n���W����
      (240&255),(240>>8),200,0,		// �ʒu����
      0x02,			// �L�[�{�[�h�f�[�^�\��
      59,58,0xff,     // [INS][DEL]

      // �X�y�[�X
      0x01,			// �\���J�n���W����
      (244&255),(244>>8),232,0,		// �ʒu����
      0x02,			// �L�[�{�[�h�f�[�^�\��
      48,0xff,        // [SPACE]

      // EOD
      0x00			// EOD
    ];


    //�R���X�g���N�^
    public function CSoftkey(main : asMZMem){
      m = main;

      // �L�[�z�u���̍쐬
      for (var i:int = 0; i<SOFTKEY_MAX; i++) {
        KEYAREA[i] = { flag : new int(), keytag : new int(), rect : new Rectangle() };
      }

      // �L�[�R�[�h
      keylst = [
      _keylst( 3, "CR", 0x00 ),			// 00 [CR]  00
      _keylst( 0, ":", 0x01),			// 01 [:]   01
      _keylst( 0, ";", 0x02),			// 02 [;]   02
      _keylst( 3, "ALPH", 0x04), // 04 [�p��]03
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
      _keylst( 0, "SPACE" ,0x64),      // 64 [SPACE]48
      _keylst( 0, "-", 0x65),          // 65 [-]   49
      _keylst( 0, "+", 0x66),          // 66 [+]   50
      _keylst( 0, "*", 0x67),          // 67 [*]   51

      _keylst( 0, "/", 0x70),          // 70 [/]   52
      _keylst( 0, "?", 0x71),          // 71 [?]   53
      _keylst( 0, "\x3d" , 0x72),          // 72 [<-]  54
      _keylst( 0, "\x3c" , 0x73),          // 73 [->]  55
      _keylst( 0, "\x3a" , 0x74),          // 74 [cursor down]56
      _keylst( 0, "\x3b" , 0x75),          // 75 [cursor up]57
      _keylst( 2, "DEL", 0x76),          // 76 [DEL]58
      _keylst( 2, "INS", 0x77),          // 77 [INS]59
    
      _keylst( 3|8, "SHFT", 0x80),    // 80 [SHIFT]60 (TOGGLE)
      _keylst( 3|8, "CTRL", 0x86),    // 86 [CTRL]61 (TOGGLE)
      _keylst( 2, "BRK", 0x87),          // 87 [BREAK]62
      
      _keylst( 1,"F5", 0x93),          // 93 [F5]63
      _keylst( 1,"F4", 0x94),          // 94 [F4]64
      _keylst( 1,"F3", 0x95),          // 95 [F3]65
      _keylst( 1,"F2", 0x96),          // 96 [F2]66
      _keylst( 1,"F1", 0x97)           // 97 [F1]67
    ];

      // �\�t�g�L�[������
      softkey_init();
    }

    // �L�[�{�[�h�p�[�c�̕`��
    // keykind : bit8 = push
    private function kb_parts_draw(x : int, y : int, keykind : int): int {
      var pk : Object = keylst[keykind];
      var str : String;
      var color : uint;
      var i : int;
      var result : int;

      color = pk.type;
      if ( (keykind & 0x100) != 0) { // ���]�\���w�肩�H
        color |= 0x100;
      }
      
      str = pk.dispcode;
      result = (pk.type & 7)+1;	// ������
      m.mz_kbchr_put(x, y, str, color);
      
      return result;
    }

    

    //--------------------
    // �\�t�g�L�[�̏�����
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
          x = KEYPOS[ptr]|(KEYPOS[ptr+1]<<8);
          x *= 2;
          ptr += 2;
          y = KEYPOS[ptr]|(KEYPOS[ptr+1]<<8);
          y *= 2;
          ptr += 2;
          break;
          
          case 0x02:
            while (true) {
              ch = KEYPOS[ptr++];
              if (ch == 0xFF) {
                break;
              }
              // �L�[�{�[�h���o�^
              with (KEYAREA[pKa]) {
                flag = 1;
                keytag = ch;
                rect.left = x;
                rect.top = y;
              }
              klen = (keylst[ch].type & 7)+1;
              
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
      nowkey = -1;        // �����ꂽ�L�[�͖���
      //      skeyWk->pa_bak = NULL;												/* �ȑO������Ă����L�[�̔z�u��� */

    }

    // �\�t�g�L�[�̕`��
    public function softkey_draw() : void {
      var ch : int, x : int, y : int, num : int;
      var klen : int;
      var pKa : int = 0;

      for (;;pKa++) {
        if (KEYAREA[pKa].flag == 0) {
            break;
        }
        
        // �L�[�{�[�h�\��
        klen = kb_parts_draw(KEYAREA[pKa].rect.left, KEYAREA[pKa].rect.top,
                             KEYAREA[pKa].keytag);
        
      }
      
    }

    // �\�t�g�L�[�𗣂����Ƃ��̕`��
    public function softkey_upkeydraw(code : int) : void {
      var pKa : int = 0; //skeyWk->keyarea;		// �L�[�z�u��񃏁[�N
	
      for (;;pKa++) {
        if (KEYAREA[pKa].flag == 0) {
          break;
        }

//		pKt = keylst[KEYAREA[pKa].keytag];
		if (keylst[KEYAREA[pKa].keytag].keycode == code) {
          // �L�[�{�[�h�\��
          kb_parts_draw(KEYAREA[pKa].rect.left,
                        KEYAREA[pKa].rect.top,
                        KEYAREA[pKa].keytag);
		}
      }
    }

    // �\�t�g�L�[���������Ƃ��̕`��
    public function softkey_downkeydraw(code : int) : void {
      var pKa : int = 0; //skeyWk->keyarea;		// �L�[�z�u��񃏁[�N
	
      for (;;pKa++) {
        if (KEYAREA[pKa].flag == 0) {
          break;
        }

//		pKt = keylst[KEYAREA[pKa].keytag];
		if (keylst[KEYAREA[pKa].keytag].keycode == code) {
          // �L�[�{�[�h�\��
          kb_parts_draw(KEYAREA[pKa].rect.left,
                        KEYAREA[pKa].rect.top,
                        KEYAREA[pKa].keytag|0x100);
		}
      }
    }

/*
//
int softkey_search(short x, short y, pTKEYAREA *pKret)
{
	int result = -1;
	int i;
	int xp,yp;
	pTKEYAREA pKa;
	
	pKa = skeyWk->keyarea;		// �L�[�z�u��񃏁[�N
	
	for (i=0; i<SOFTKEY_MAX; i++, pKa++)
	{
		if (!pKa->flag)
			continue;
		
		//
		xp = pKa->rect.left;
		yp = pKa->rect.top;
		if (x>=xp && y>=yp &&
			x<(xp+pKa->rect.width) && y<(yp+pKa->rect.height) )
		{
			result = pKa->keytag;
			if (pKret)
			{
				*pKret = pKa;
			}
			break;
		}
	}
	
	return result;
}


//
void softkey_down(short x, short y, int first)
{
	pTKEYAREA pa;
	pTKEYTAG pKt;
	int keyno = softkey_search(x,y,&pa);
	
	if (keyno >= 0)
	{
		// �O�ƈႤ�L�[��������Ă���
		if (skeyWk->nowkey != keyno)
		{
			// �O�̃L�[�͗���
			if (skeyWk->nowkey >= 0)
			{
				//
				softkey_upkeydraw(keylst[skeyWk->pa_bak->keytag].keycode);				// �\�t�g�L�[�𗣂����Ƃ��̕`��
				skeyWk->pa_bak = NULL;
				mz_keyup((DWORD)keylst[skeyWk->nowkey].keycode);
			}
		}
		skeyWk->nowkey = keyno;

		//
		pKt = &keylst[keyno];
		if (pKt->type & 8)
		{
			skeyWk->nowkey = -1;
			skeyWk->pa_bak = NULL;
			if (first)													// �ŏ��̃^�b�`��������c
			{
				// �g�O���L�[
				if (mz_keychk((DWORD)pKt->keycode) )
				{
					// ������Ă����Ȃ畜�A
					softkey_upkeydraw(pKt->keycode);					// �\�t�g�L�[�𗣂����Ƃ��̕`��
					mz_keyup((DWORD)pKt->keycode);
				}
				else
				{
					// ������Ă��Ȃ��������牟��
					softkey_downkeydraw(pKt->keycode);					// �\�t�g�L�[���������Ƃ��̕`��
					mz_keydown((DWORD)pKt->keycode);
				}
			}
		}
		else
		{
			// �ʏ�
			// �����ꂽ�L�[�̕\��
			softkey_downkeydraw(pKt->keycode);					// �\�t�g�L�[���������Ƃ��̕`��
			
			mz_keydown((DWORD)pKt->keycode);
			skeyWk->pa_bak = pa;
		}
	}
	else
	{
		// �w���ȃg�R�������̂�
		// �O�̃L�[�͗���
		if (skeyWk->nowkey >= 0)
		{
			mz_keyup((DWORD)keylst[skeyWk->nowkey].keycode);
			//
			softkey_upkeydraw(keylst[skeyWk->nowkey].keycode);			// �\�t�g�L�[�𗣂����Ƃ��̕`��
			skeyWk->pa_bak = NULL;
		}
		skeyWk->nowkey = -1;
	}

}

//
void softkey_up(short x, short y)
{
	pTKEYAREA pa;
	pTKEYTAG pKt;
	int keyno = softkey_search(x,y,&pa);

	if (keyno >= 0)
	{
		//
		pKt = &keylst[keyno];
		if (!(pKt->type & 8))
		{
			// �g�O���L�[�łȂ�������
			// �\�t�g�L�[�̕\���𕜋A
			softkey_upkeydraw((DWORD)pKt->keycode);						// �\�t�g�L�[�𗣂����Ƃ��̕`��
			skeyWk->pa_bak = NULL;
			
			skeyWk->nowkey = -1;
			mz_keyup((DWORD)pKt->keycode);
		}
		
	}

}

*/  









    
    // �\����
    private function _keylst(tp : int, disp: String, kcode : int) : Object {
      return { type: tp, dispcode: disp, keycode: kcode };
    }



  }
}
