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
      (244&255),(244>>8),216,0,		// �ʒu����
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
      _keylst( 1,"\x03\x12",0x00 ),			// 00 [CR]  00
      _keylst( 0,"\x4F   ",0x01),			// 01 [:]   01
      _keylst( 0,"\x2C   ",0x02),			// 02 [;]   02
      _keylst( 3,"\x01\x0C\x10\x08",0x04), // 04 [�p��]03
      _keylst( 0,"\x2b   ",0x05),          // 05 [=]   04
      _keylst( 3,"\x07\x12\x10\x08",0x06),          // 06 [GRPH]05
      _keylst( 1,"\x94\x95",0x07),          // 07 KANA  06
      
      _keylst( 0,"\x69   ",0x13),          // 13 [)]     07
      _keylst( 0,"\x68   ",0x14),          // 14 [(]     08
      _keylst( 0,"\x55   ",0x15),          // 15 [@]   09
      _keylst( 0,"\x1A   ",0x16),          // 16 [Z]   10
      _keylst( 0,"\x19   ",0x17),          // 17 [Y]   11
      
      _keylst( 0,"\x18   ",0x20),          // 20 [X]   12
      _keylst( 0,"\x17   ",0x21),          // 21 [W]   13
      _keylst( 0,"\x16   ",0x22),          // 22 [V]   14
      _keylst( 0,"\x15   ",0x23),          // 23 [U]   15
      _keylst( 0,"\x14   ",0x24),          // 24 [T]   16
      _keylst( 0,"\x13   ",0x25),          // 25 [S]   17
      _keylst( 0,"\x12   ",0x26),          // 26 [R]   18
      _keylst( 0,"\x11   ",0x27),          // 27 [Q]   19
      
      _keylst( 0,"\x10   ",0x30),          // 30 [P]   20
      _keylst( 0,"\x0f   ",0x31),          // 31 [O]   21
      _keylst( 0,"\x0e   ",0x32),          // 32 [N]   22
      _keylst( 0,"\x0d   ",0x33),          // 33 [M]   23
      _keylst( 0,"\x0c   ",0x34),          // 34 [L]   24
      _keylst( 0,"\x0b   ",0x35),          // 35 [K]   25
      _keylst( 0,"\x0a   ",0x36),          // 36 [J]   26
      _keylst( 0,"\x09   ",0x37),          // 37 [I]   27
      
      _keylst( 0,"\x08   ",0x40),          // 40 [H]   28
      _keylst( 0,"\x07   ",0x41),          // 41 [G]   29
      _keylst( 0,"\x06   ",0x42),          // 42 [F]   30
      _keylst( 0,"\x05   ",0x43),          // 43 [E]   31
      _keylst( 0,"\x04   ",0x44),          // 44 [D]   32
      _keylst( 0,"\x03   ",0x45),          // 45 [C]   33
      _keylst( 0,"\x02   ",0x46),          // 46 [B]   34
      _keylst( 0,"\x01   ",0x47),          // 47 [A]   35

      _keylst( 0,"\x28   ",0x50),          // 50 [8]   36
      _keylst( 0,"\x27   ",0x51),          // 51 [7]   37
      _keylst( 0,"\x26   ",0x52),          // 52 [6]   38
      _keylst( 0,"\x25   ",0x53),          // 53 [5]   39
      _keylst( 0,"\x24   ",0x54),          // 54 [4]   40
      _keylst( 0,"\x23   ",0x55),          // 55 [3]   41
      _keylst( 0,"\x22   ",0x56),          // 56 [2]   42
      _keylst( 0,"\x21   ",0x57),          // 57 [1]   43
    
      _keylst( 0,"\x2e   ",0x60),          // 60 [.]   44
      _keylst( 0,"\x2f   ",0x61),          // 61 [,]   45
      _keylst( 0,"\x29   ",0x62),          // 62 [9]   46
      _keylst( 0,"\x20   ",0x63),          // 63 [0]   47
      _keylst( 4,"\x13\x10\x01\x03\x05",0x64),          // 64 [SPACE]48
      _keylst( 0,"\x2A   ",0x65),          // 65 [-]   49
      _keylst( 0,"\x6A   ",0x66),          // 66 [+]   50
      _keylst( 0,"\x6B   ",0x67),          // 67 [*]   51

      _keylst( 0,"\x2d   ",0x70),          // 70 [/]   52
      _keylst( 0,"\x49   ",0x71),          // 71 [?]   53
      _keylst( 0,"\xc4   ",0x72),          // 72 [<-]  54
      _keylst( 0,"\xc3   ",0x73),          // 73 [->]  55
      _keylst( 0,"\xc1    ",0x74),          // 74 [cursor down]56
      _keylst( 0,"\xc2    ",0x75),          // 75 [cursor up]57
      _keylst( 2,"\x04\x05\x0c",0x76),          // 76 [DEL]58
      _keylst( 2,"\x09\x0e\x13",0x77),          // 77 [INS]59
    
      _keylst( 3|8,"\x13\x08\x06\x14",0x80),    // 80 [SHIFT]60 (TOGGLE)
      _keylst( 3|8,"\x03\x14\x12\x0c",0x86),    // 86 [CTRL]61 (TOGGLE)
      _keylst( 2,"\x02\x12\x0B",0x87),          // 87 [BREAK]62
      
      _keylst( 1,"\x06\x25  ",0x93),          // 93 [F5]63
      _keylst( 1,"\x06\x24  ",0x94),          // 94 [F4]64
      _keylst( 1,"\x06\x23  ",0x95),          // 95 [F3]65
      _keylst( 1,"\x06\x22  ",0x96),          // 96 [F2]66
      _keylst( 1,"\x06\x21  ",0x97)           // 97 [F1]67
    ];

      // �\�t�g�L�[������
      softkey_init();
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
              if (ch == 0xFF)
                break;
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
//        klen = kb_parts_draw(KEYAREA[pKa].rect.left, KEYAREA[pKa].rect.top,
//                             KEYAREA[pKa].keytag);
        
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
/*          
          kb_parts_draw(KEYAREA[pKa].rect.left,
                        KEYAREA[pKa].rect.top,
                        KEYAREA[pKa].keytag);
  */
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
/*          
          kb_parts_draw(KEYAREA[pKa].rect.left,
                        KEYAREA[pKa].rect.top,
                        KEYAREA[pKa].keytag|0x100);
  */
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
