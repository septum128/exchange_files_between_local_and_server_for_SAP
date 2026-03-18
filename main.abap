*&---------------------------------------------------------------------*
*& プログラム名：サーバーローカル間のファイル交換
*& プログラムID：ZTOOL_EXCHANGE_FILES
*& 作成者名    ：セプタム(septum128)
*& 作成日付    ：2017/11/14
*& 処理概要    ：ファイルを読み込み、サーバーにアップロードする
*& 　　　　　　　サーバーファイルをローカルにダウンロードする
*&---------------------------------------------------------------------*
REPORT ZTOOL_EXCHANGE_FILES.

*----------------------------------------------------------------------*
*   構造 定義
*----------------------------------------------------------------------*
TYPES:
* ファイルパス
  BEGIN OF GTS_PATH,
    NAME TYPE PCFILE-PATH,
  END OF GTS_PATH,
  GTT_PATH TYPE STANDARD TABLE OF GTS_PATH,

* ファイルテキスト
  BEGIN OF GTS_TAB,
    DATA(10000) TYPE C,
  END   OF GTS_TAB,
  GTT_TAB TYPE STANDARD TABLE OF GTS_TAB.

*----------------------------------------------------------------------*
*   定数 定義
*----------------------------------------------------------------------*
CONSTANTS:
* ファイルタイプ
  BEGIN OF GCS_FILETYP,
    U TYPE CHAR1 VALUE 'U',
    D TYPE CHAR1 VALUE 'D',
  END   OF GCS_FILETYP,
* フラグ
  GCF_X  TYPE CHAR1 VALUE 'X'.

*----------------------------------------------------------------------*
*   選択画面 定義
*----------------------------------------------------------------------*
* 処理概要
SELECTION-SCREEN BEGIN OF BLOCK B0 WITH FRAME TITLE TEXT_007.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(79) TEXT_008.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(79) TEXT_009.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK B0.
SELECTION-SCREEN BEGIN OF BLOCK B1 WITH FRAME TITLE TEXT_001.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS:
      PR_APP   RADIOBUTTON GROUP RAD1 DEFAULT 'X'.
    SELECTION-SCREEN COMMENT 5(25) TEXT_002 FOR FIELD PR_APP.
    PARAMETERS:
      PR_LOCAL RADIOBUTTON GROUP RAD1.
    SELECTION-SCREEN COMMENT 35(25) TEXT_003 FOR FIELD PR_LOCAL.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK B1.

SELECTION-SCREEN BEGIN OF BLOCK B11 WITH FRAME TITLE TEXT_004.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(25) TEXT_005 FOR FIELD P_APP1.
    SELECTION-SCREEN POSITION 32.
    PARAMETERS:
      P_APP1  TYPE RLGRAP-FILENAME OBLIGATORY DEFAULT 'D:\'.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(25) TEXT_006 FOR FIELD P_FILE.
    SELECTION-SCREEN POSITION 32.
    PARAMETERS:
      P_FILE  TYPE RLGRAP-FILENAME OBLIGATORY DEFAULT 'C:\temp'.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(25) TEXT_010 FOR FIELD P_CDPG.
    SELECTION-SCREEN POSITION 32.
    PARAMETERS:
      P_CDPG TYPE TCP00-CPCODEPAGE OBLIGATORY DEFAULT '8000'.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(25) TEXT_011 FOR FIELD C_ZERO.
    SELECTION-SCREEN POSITION 32.
    PARAMETERS:
      C_ZERO AS CHECKBOX.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK B11.

*----------------------------------------------------------------------*
*   INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.

* 画面テキスト設定
  TEXT_001 = '処理選択'.
  TEXT_002 = 'ダウンロード'.
  TEXT_003 = 'アップロード'.
  TEXT_004 = '入出力情報'.
  TEXT_005 = 'サーバー'.
  TEXT_006 = 'ローカル'.
  TEXT_007 = '処理概要'.
  TEXT_008 = 'ダウンロード選択時、サーバファイルをローカルにダウンロードする。'.
  TEXT_009 = 'アップロード選択時、ローカルファイルをサーバーにアップロードする。'.
  TEXT_010 = 'コードページ'.
  TEXT_011 = '0件ファイルのアップロードを許可する'.

*----------------------------------------------------------------------*
*   AT SELECTION-SCREEN
*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_APP1.
* サーバーファイルの選択
  PERFORM F4_HELP_SERVER CHANGING P_APP1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_FILE.
* ローカルファイルの選択
  PERFORM F4_HELP_LOCAL CHANGING P_FILE.

AT SELECTION-SCREEN OUTPUT.
* 画面制御
  PERFORM DISPLAY_CONTROL.

*----------------------------------------------------------------------*
*   START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

* データダウンロード
  PERFORM DOWNLOAD_DATA.

*----------------------------------------------------------------------*
*   TOP-OF-PAGE
*----------------------------------------------------------------------*
TOP-OF-PAGE.

* 処理結果ヘッダ出力
  WRITE '[処理結果]'.
  SKIP 1.

*&---------------------------------------------------------------------*
*&      Form  F4_HELP_SERVER
*&---------------------------------------------------------------------*
*       サーバーファイルの選択
*----------------------------------------------------------------------*
FORM F4_HELP_SERVER  CHANGING POF_FILE TYPE RLGRAP-FILENAME.

  DATA:
    LDF_APPLSERV         TYPE CHAR01,
    LDF_TITLE            TYPE STRING,
    LDF_GUI_EXTENSION    TYPE STRING,
    LDF_GUI_EXT_FILTER   TYPE STRING,
    LDF_CANCELED         TYPE AS4FLAG,
    LDF_APPLSERV_LOGICAL TYPE AS4FLAG,
    LDF_APPLSERV_AL11    TYPE AS4FLAG,
    LDF_LOGICAL_FILE     TYPE AS4FLAG,
    LDF_FILE_NAME        TYPE STRING,
    LDF_FILE             TYPE FILE.

* ダウンロード(サーバーからローカル)が選択されている場合
  IF PR_APP IS NOT INITIAL.
*   引数のセット
    LDF_APPLSERV         = GCF_X.
    LDF_TITLE            = 'サーバーファイルの選択'.
    LDF_APPLSERV_LOGICAL = GCF_X.
    LDF_APPLSERV_AL11    = GCF_X.

*   サーバーファイルパスの取得
    CALL METHOD CL_RSAN_UT_FILES=>F4
      EXPORTING
        I_APPLSERV              = LDF_APPLSERV
        I_TITLE                 = LDF_TITLE
        I_GUI_EXTENSION         = LDF_GUI_EXTENSION
        I_GUI_EXT_FILTER        = LDF_GUI_EXT_FILTER
        I_APPLSERV_LOGICAL      = LDF_APPLSERV_LOGICAL
        I_APPLSERV_AL11         = LDF_APPLSERV_AL11
      IMPORTING
        E_CANCELED              = LDF_CANCELED
        E_LOGICAL_FILE          = LDF_LOGICAL_FILE
      CHANGING
        C_FILE_NAME             = LDF_FILE_NAME
      EXCEPTIONS
         FAILED                  = 1
         OTHERS                  = 2.

    IF SY-SUBRC = 0.
      IF LDF_CANCELED IS INITIAL.
        POF_FILE = LDF_FILE_NAME.
      ENDIF.
    ENDIF.

* アップロードが選択されている場合
  ELSE.
*   画面入力値の取得
    PERFORM DYNP_VALUES_READ USING 'P_APP1' CHANGING LDF_FILE.
    IF LDF_FILE IS INITIAL.
      MESSAGE 'サーバドライブを指定してください。[例 c:\]' TYPE 'STRING'.
      LEAVE TO LIST-PROCESSING.
    ENDIF.

*   サーバーフォルダパスの取得
    CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE'
      EXPORTING
        DIRECTORY        = LDF_FILE
        FILEMASK         = '*'
      IMPORTING
        SERVERFILE       = LDF_FILE
      EXCEPTIONS
        CANCELED_BY_USER = 1
        OTHERS           = 2.
    IF SY-SUBRC = 0.
      POF_FILE = LDF_FILE.
    ENDIF.

  ENDIF.

ENDFORM.                    " F4_HELP_SERVER
*&---------------------------------------------------------------------*
*&      FORM  DYNP_VALUES_READ
*&---------------------------------------------------------------------*
*       PAI 項目転送前に DYNPRO 項目値を読込(F4で画面項目を取得)
*----------------------------------------------------------------------*
*      -->AI_FIELDNAME   項目名
*      <--AO_FIELDVALUE  項目値
*----------------------------------------------------------------------*
FORM DYNP_VALUES_READ USING    VALUE(AI_FIELDNAME)  TYPE ANY
                      CHANGING VALUE(AO_FIELDVALUE) TYPE ANY.
  DATA:
    LDT_DYNPREAD TYPE STANDARD TABLE OF DYNPREAD, "現画面の値読込TBL
    LDS_DYNPREAD TYPE DYNPREAD.

  CLEAR AO_FIELDVALUE.

* フィールド名のセット
  LDS_DYNPREAD-FIELDNAME = AI_FIELDNAME.
  APPEND LDS_DYNPREAD TO LDT_DYNPREAD.

* PAI 項目転送前に DYNPRO 項目値を読込(F4で画面項目を取得)
  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      DYNAME               = SY-CPROG
      DYNUMB               = SY-DYNNR
    TABLES
      DYNPFIELDS           = LDT_DYNPREAD
    EXCEPTIONS
      INVALID_ABAPWORKAREA = 1
      INVALID_DYNPROFIELD  = 2
      INVALID_DYNPRONAME   = 3
      INVALID_DYNPRONUMMER = 4
      INVALID_REQUEST      = 5
      NO_FIELDDESCRIPTION  = 6
      INVALID_PARAMETER    = 7
      UNDEFIND_ERROR       = 8
      DOUBLE_CONVERSION    = 9
      STEPL_NOT_FOUND      = 10
      OTHERS               = 11.

  IF SY-SUBRC = 0.
*   フィールド値の取得
    READ TABLE LDT_DYNPREAD INTO LDS_DYNPREAD INDEX 1.
    AO_FIELDVALUE = LDS_DYNPREAD-FIELDVALUE.
  ENDIF.

ENDFORM.                    " DYNP_VALUES_READ
*&---------------------------------------------------------------------*
*&      Form  F4_HELP_LOCAL
*&---------------------------------------------------------------------*
*       ローカルファイルの選択
*----------------------------------------------------------------------*
FORM F4_HELP_LOCAL  CHANGING POF_FILE TYPE RLGRAP-FILENAME.

  DATA:
    LDF_DIR   TYPE STRING,
    LDF_RC    TYPE I,
    LDT_FILE  TYPE FILETABLE,
    LDS_FILE  TYPE FILE_TABLE.

* ダウンロード(サーバーからローカル)が選択されている場合
  IF PR_APP IS NOT INITIAL.
*   ローカルフォルダパスの取得
    CALL METHOD CL_GUI_FRONTEND_SERVICES=>DIRECTORY_BROWSE
      CHANGING
        SELECTED_FOLDER      = LDF_DIR
      EXCEPTIONS
        CNTL_ERROR           = 1
        ERROR_NO_GUI         = 2
        NOT_SUPPORTED_BY_GUI = 3
        OTHERS               = 4.
    IF SY-SUBRC = 0.
      POF_FILE = LDF_DIR.
    ENDIF.

* アップロード(ローカルからサーバー)が選択されている場合
  ELSE.
*   ローカルファイルパスの取得
    CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG
      CHANGING
        FILE_TABLE              = LDT_FILE
        RC                      = LDF_RC
      EXCEPTIONS
        FILE_OPEN_DIALOG_FAILED = 1
        CNTL_ERROR              = 2
        ERROR_NO_GUI            = 3
        NOT_SUPPORTED_BY_GUI    = 4
        OTHERS                  = 5.

*   正常時
    IF SY-SUBRC = 0.
      READ TABLE LDT_FILE INTO LDS_FILE INDEX 1.
      POF_FILE = LDS_FILE-FILENAME.
    ENDIF.

  ENDIF.

* 例外処理
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " F4_HELP_LOCAL
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_DATA
*&---------------------------------------------------------------------*
*       データダウンロード
*----------------------------------------------------------------------*
FORM DOWNLOAD_DATA .

  DATA:
    LDF_FILE    TYPE RLGRAP-FILENAME,
    LDF_FLNM    TYPE STRING,
    LDF_POS     TYPE I,
    LDF_SUBRC   TYPE SY-SUBRC,
    LDF_MSG     TYPE STRING,
    LDF_RESULT  TYPE STRING.

* ダウンロードを選択した場合
  IF PR_APP = GCF_X.
*   ファイル名の作成
    LDF_POS = STRLEN( P_FILE ) - 1.
    IF P_FILE+LDF_POS(1) <> '\'.
      CONCATENATE P_FILE '\' INTO P_FILE.
    ENDIF.
    PERFORM GET_FILE_NAME USING    P_APP1
                          CHANGING LDF_FLNM.
    CONCATENATE P_FILE
                LDF_FLNM
           INTO LDF_FILE.

*   メッセージ編集
    LDF_MSG = 'ファイルのダウンロードに失敗しました'.

*   ローカルにファイルをダウンロードする
    PERFORM FRM_FILE_DOWNLOAD_UPLOAD
         USING LDF_FILE                     "サーバーファイル
               P_APP1                       "ローカルファイル
               GCS_FILETYP-D                "ファイルタイプ
      CHANGING LDF_RESULT                   "メッセージ
               LDF_SUBRC.                   "リターンコード

* アップロードを選択した場合
  ELSE.
*   ファイル名の作成
    LDF_POS = STRLEN( P_APP1 ) - 1.
    IF P_APP1+LDF_POS(1) <> '\'.
      CONCATENATE P_APP1'\' INTO P_APP1.
    ENDIF.
    PERFORM GET_FILE_NAME USING    P_FILE
                          CHANGING LDF_FLNM.
    CONCATENATE P_APP1
                LDF_FLNM
           INTO LDF_FILE.

*   メッセージ編集
    LDF_MSG = 'ファイルのアップロードに失敗しました'.

* サーバーにファイルをアップロードする
  PERFORM FRM_FILE_DOWNLOAD_UPLOAD
       USING P_FILE                         "ローカルファイル
             LDF_FILE                       "サーバーファイル
             GCS_FILETYP-U                  "ファイルタイプ
    CHANGING LDF_RESULT                     "メッセージ
             LDF_SUBRC.                     "リターンコード

  ENDIF.

  IF LDF_SUBRC = 0.
*   正常メッセージ出力
    MESSAGE LDF_RESULT TYPE 'STRING'
      DISPLAY LIKE 'S'.
  ELSE.
*   エラー結果出力
    WRITE / LDF_RESULT.
*   エラーメッセージ出力
    MESSAGE LDF_MSG TYPE 'STRING'
      DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.                    " DOWNLOAD_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_FILE_NAME
*&---------------------------------------------------------------------*
*       ファイル名取得
*----------------------------------------------------------------------*
*      -->PIF_FPATH  完全ファイルパス
*      <--POF_FNAME  ファイル名
*----------------------------------------------------------------------*
FORM GET_FILE_NAME  USING    PIF_FPATH TYPE RLGRAP-FILENAME
                    CHANGING POF_FNAME TYPE STRING.

  DATA:
    LDT_PATH TYPE GTT_PATH,
    LDS_PATH TYPE GTS_PATH,
    LDF_TBLC TYPE I.

  CLEAR:
    POF_FNAME.

* ディレクトリ分割
  SPLIT PIF_FPATH AT '\'
                  INTO TABLE LDT_PATH.

* 分割件数のカウント
  DESCRIBE TABLE LDT_PATH LINES LDF_TBLC.

* 最終カウント数でファイル名を取得
  READ TABLE LDT_PATH INTO LDS_PATH
    INDEX LDF_TBLC.

* 引数のセット
  POF_FNAME = LDS_PATH-NAME.

ENDFORM.                    " GET_FILE_NAME
*&---------------------------------------------------------------------*
*&      Form  FRM_FILE_DOWNLOAD_UPLOAD
*&---------------------------------------------------------------------*
*       ローカル OR サーバーからのファイルダウンロード
*----------------------------------------------------------------------*
*      -->PIF_FILE    アップロード/ダウンロード用ローカルファイル
*      -->PIF_APP1    アップロード/ダウンロード用ローカルファイル
*      -->PIF_FILETYP ファイルタイプ
*      <--POF_RESULT  ダウンロードファイル名
*      <--POF_SUBRC   リターンコード
*----------------------------------------------------------------------*
FORM FRM_FILE_DOWNLOAD_UPLOAD  USING    PIF_LFILE   TYPE RLGRAP-FILENAME
                                        PIF_AFILE   TYPE RLGRAP-FILENAME
                                        PIF_FILETYP TYPE C
                               CHANGING POF_RESULT  TYPE STRING
                                        POF_SUBRC   TYPE SY-SUBRC.

  DATA:
    LDT_TAB1   TYPE GTT_TAB,
    LDT_TAB2   TYPE GTT_TAB,
    LDS_TAB1   TYPE GTS_TAB,
    LDS_TAB2   TYPE GTS_TAB,
    LDF_PCFILE TYPE STRING,
    LDF_OSMSG  TYPE STRING,
    LDF_SUBRC  TYPE CHAR1.

* サーバーからローカルにダウンロード
  IF PIF_FILETYP = GCS_FILETYP-D.
*   サーバーのファイルパスが入力されている場合(Tr-CD:AL11)
    IF PIF_AFILE IS NOT INITIAL.
      OPEN DATASET PIF_AFILE FOR INPUT IN LEGACY TEXT MODE
                                  CODE PAGE P_CDPG MESSAGE LDF_OSMSG.
      IF SY-SUBRC <> 0.
        POF_SUBRC  = SY-SUBRC.
        LDF_SUBRC = SY-SUBRC.
        CONCATENATE LDF_OSMSG 'RC =' LDF_SUBRC
               INTO POF_RESULT
          SEPARATED BY SPACE.
        RETURN.
      ENDIF.
      WHILE SY-SUBRC = 0.
        READ DATASET PIF_AFILE INTO LDS_TAB1.
        IF SY-SUBRC = 0.
          APPEND LDS_TAB1 TO LDT_TAB1.
          CLEAR LDS_TAB1.
        ENDIF.
      ENDWHILE.
      CLOSE DATASET PIF_AFILE.
    ENDIF.

*--Download file from Application server to local server.
    IF LDT_TAB1[] IS NOT INITIAL.
      LDF_PCFILE = PIF_LFILE.
      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
          FILENAME = LDF_PCFILE
          FILETYPE = 'BIN'
        TABLES
          DATA_TAB = LDT_TAB1
        EXCEPTIONS
          FILE_WRITE_ERROR                = 1
          NO_BATCH                        = 2
          GUI_REFUSE_FILETRANSFER         = 3
          INVALID_TYPE                    = 4
          NO_AUTHORITY                    = 5
          UNKNOWN_ERROR                   = 6
          HEADER_NOT_ALLOWED              = 7
          SEPARATOR_NOT_ALLOWED           = 8
          FILESIZE_NOT_ALLOWED            = 9
          HEADER_TOO_LONG                 = 10
          DP_ERROR_CREATE                 = 11
          DP_ERROR_SEND                   = 12
          DP_ERROR_WRITE                  = 13
          UNKNOWN_DP_ERROR                = 14
          ACCESS_DENIED                   = 15
          DP_OUT_OF_MEMORY                = 16
          DISK_FULL                       = 17
          DP_TIMEOUT                      = 18
          FILE_NOT_FOUND                  = 19
          DATAPROVIDER_EXCEPTION          = 20
          CONTROL_FLUSH_ERROR             = 21
          OTHERS                          = 22
          .
      IF SY-SUBRC = 0.
        POF_RESULT = 'ローカルへのファイルダウンロードが成功しました'.
      ELSE.
        POF_SUBRC = SY-SUBRC.
        LDF_SUBRC = SY-SUBRC.
        CONCATENATE '汎用M「GUI_DOWNLOAD」の実行に失敗しました RC = '
                    LDF_SUBRC
               INTO POF_RESULT.
      ENDIF.
    ENDIF.

* ローカルからサーバーにアップロード
  ELSE.
    LDF_PCFILE = PIF_LFILE.
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        FILENAME                = LDF_PCFILE
        FILETYPE                = 'BIN'
      TABLES
        DATA_TAB                = LDT_TAB2
      EXCEPTIONS
        FILE_OPEN_ERROR         = 1
        FILE_READ_ERROR         = 2
        NO_BATCH                = 3
        GUI_REFUSE_FILETRANSFER = 4
        INVALID_TYPE            = 5
        NO_AUTHORITY            = 6
        UNKNOWN_ERROR           = 7
        BAD_DATA_FORMAT         = 8
        HEADER_NOT_ALLOWED      = 9
        SEPARATOR_NOT_ALLOWED   = 10
        HEADER_TOO_LONG         = 11
        UNKNOWN_DP_ERROR        = 12
        ACCESS_DENIED           = 13
        DP_OUT_OF_MEMORY        = 14
        DISK_FULL               = 15
        DP_TIMEOUT              = 16
        OTHERS                  = 17.
    IF SY-SUBRC <> 0.
      POF_SUBRC = SY-SUBRC.
      LDF_SUBRC = SY-SUBRC.
      CONCATENATE '汎用M「GUI_UPLOAD」の実行に失敗しました RC = '
                  LDF_SUBRC
             INTO POF_RESULT.
      RETURN.
    ENDIF.

*   0件ファイルのアップロードが許可されていない場合
    IF C_ZERO IS INITIAL AND LDT_TAB2[] IS INITIAL.
      POF_SUBRC  = 1.
      POF_RESULT = 'ダウンロードデータが存在しません'.
    ELSE.
*     サーバーにファイル作成
      OPEN DATASET PIF_AFILE FOR OUTPUT IN LEGACY TEXT MODE
                              CODE PAGE P_CDPG MESSAGE LDF_OSMSG.
      IF SY-SUBRC = 0.
        LOOP AT LDT_TAB2 INTO LDS_TAB2.
          TRANSFER LDS_TAB2 TO PIF_AFILE.
        ENDLOOP.
        CLOSE DATASET PIF_AFILE.
        POF_RESULT = 'サーバーへのファイルアップロードが成功しました'.

*     ファイル作成失敗時
      ELSE.
        POF_SUBRC  = SY-SUBRC.
        POF_RESULT = LDF_OSMSG.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " FRM_FILE_DOWNLOAD_UPLOAD
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_CONTROL
*&---------------------------------------------------------------------*
*       画面制御
*----------------------------------------------------------------------*
FORM DISPLAY_CONTROL .

  IF PR_LOCAL IS NOT INITIAL.
*   処理なし
  ENDIF.

ENDFORM.                    " DISPLAY_CONTROL
