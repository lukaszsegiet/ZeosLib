{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{         PostgreSQL Database Connectivity Classes        }
{                                                         }
{         Originally written by Sergey Seroukhov          }
{                           and Sergey Merkuriev          }
{                                                         }
{*********************************************************}

{@********************************************************}
{    Copyright (c) 1999-2012 Zeos Development Group       }
{                                                         }
{ License Agreement:                                      }
{                                                         }
{ This library is distributed in the hope that it will be }
{ useful, but WITHOUT ANY WARRANTY; without even the      }
{ implied warranty of MERCHANTABILITY or FITNESS FOR      }
{ A PARTICULAR PURPOSE.  See the GNU Lesser General       }
{ Public License for more details.                        }
{                                                         }
{ The source code of the ZEOS Libraries and packages are  }
{ distributed under the Library GNU General Public        }
{ License (see the file COPYING / COPYING.ZEOS)           }
{ with the following  modification:                       }
{ As a special exception, the copyright holders of this   }
{ library give you permission to link this library with   }
{ independent modules to produce an executable,           }
{ regardless of the license terms of these independent    }
{ modules, and to copy and distribute the resulting       }
{ executable under terms of your choice, provided that    }
{ you also meet, for each linked independent module,      }
{ the terms and conditions of the license of that module. }
{ An independent module is a module which is not derived  }
{ from or based on this library. If you modify this       }
{ library, you may extend this exception to your version  }
{ of the library, but you are not obligated to do so.     }
{ If you do not wish to do so, delete this exception      }
{ statement from your version.                            }
{                                                         }
{                                                         }
{ The project web site is located on:                     }
{   http://zeos.firmos.at  (FORUM)                        }
{   http://sourceforge.net/p/zeoslib/tickets/ (BUGTRACKER)}
{   svn://svn.code.sf.net/p/zeoslib/code-0/trunk (SVN)    }
{                                                         }
{   http://www.sourceforge.net/projects/zeoslib.          }
{                                                         }
{                                                         }
{                                 Zeos Development Group. }
{********************************************************@}

unit ZDbcPostgreSqlUtils;

interface

{$I ZDbc.inc}

uses
  Classes, {$IFDEF MSEgui}mclasses,{$ENDIF} SysUtils,
  ZDbcIntfs, ZPlainPostgreSqlDriver, ZDbcPostgreSql, ZDbcLogging,
  ZCompatibility, ZVariant;

{**
  Indicate what field type is a number (integer, float and etc.)
  @param  the SQLType field type value
  @result true if field type number
}
function IsNumber(Value: TZSQLType): Boolean;

{**
   Return ZSQLType from PostgreSQL type name
   @param Connection a connection to PostgreSQL
   @param The TypeName is PostgreSQL type name
   @return The ZSQLType type
}
function PostgreSQLToSQLType(const Connection: IZPostgreSQLConnection;
  const TypeName: string): TZSQLType; overload;

{**
    Another version of PostgreSQLToSQLType()
      - comparing integer should be faster than AnsiString?
   Return ZSQLType from PostgreSQL type name
   @param Connection a connection to PostgreSQL
   @param TypeOid is PostgreSQL type OID
   @return The ZSQLType type
}
function PostgreSQLToSQLType(const ConSettings: PZConSettings;
  const OIDAsBlob: Boolean; const TypeOid: Integer): TZSQLType; overload;

{**
   Return PostgreSQL type name from ZSQLType
   @param The ZSQLType type
   @return The Postgre TypeName
}
function SQLTypeToPostgreSQL(SQLType: TZSQLType; IsOidAsBlob: Boolean): string; overload;
procedure SQLTypeToPostgreSQL(SQLType: TZSQLType; IsOidAsBlob: Boolean; out aOID: OID); overload;

{**
  add by Perger -> based on SourceForge:
  [ 1520587 ] Fix for 1484704: bytea corrupted on post when not using utf8,
  file: 1484704.patch

  Converts a binary string into escape PostgreSQL format.
  @param Value a binary stream.
  @return a string in PostgreSQL binary string escape format.
}
function EncodeBinaryString(SrcBuffer: PAnsiChar; Len: Integer; Quoted: Boolean = False): RawByteString;

{**
  Encode string which probably consists of multi-byte characters.
  Characters ' (apostraphy), low value (value zero), and \ (back slash) are encoded. Since we have noticed that back slash is the second byte of some BIG5 characters (each of them is two bytes in length), we need a characterset aware encoding function.
  @param CharactersetCode the characterset in terms of enumerate code.
  @param Value the regular string.
  @return the encoded string.
}
function PGEscapeString(SrcBuffer: PAnsiChar; SrcLength: Integer;
    ConSettings: PZConSettings; Quoted: Boolean): RawByteString;

{**
  Converts an string from escape PostgreSQL format.
  @param Value a string in PostgreSQL escape format.
  @return a regular string.
}
function DecodeString(const Value: AnsiString): AnsiString;

{**
  Checks for possible sql errors.
  @param Connection a reference to database connection to execute Rollback.
  @param PlainDriver a PostgreSQL plain driver.
  @param Handle a PostgreSQL connection reference.
  @param LogCategory a logging category.
  @param LogMessage a logging message.
  @param ResultHandle the Handle to the Result
}
procedure HandlePostgreSQLError(const Sender: IImmediatelyReleasable;
  const PlainDriver: TZPostgreSQLPlainDriver; conn: PGconn;
  LogCategory: TZLoggingCategory; const LogMessage: RawByteString;
  ResultHandle: PZPostgreSQLResult);

function PGSucceeded(ErrorMessage: PAnsiChar): Boolean; {$IFDEF WITH_INLINE}inline;{$ENDIF}

{**
   Resolve problem with minor version in PostgreSql bettas
   @param Value a minor version string like "4betta2"
   @return a miror version number
}
function GetMinorVersion(const Value: string): Word;

{**
  Prepares an SQL parameter for the query.
  @param ParameterIndex the first parameter is 1, the second is 2, ...
  @return a string representation of the parameter.
}
function PGPrepareAnsiSQLParam(const Value: TZVariant; const ClientVarManager: IZClientVariantManager;
  const Connection: IZPostgreSQLConnection; ChunkSize: Cardinal; InParamType: TZSQLType;
  oidasblob, DateTimePrefix, QuotedNumbers: Boolean; ConSettings: PZConSettings): RawByteString;

//https://www.postgresql.org/docs/9.1/static/datatype-datetime.html

//macros from datetime.c
function date2j(y, m, d: Integer): Integer;
procedure j2date(jd: Integer; out AYear, AMonth, ADay: Word);
procedure dt2time(jd: Int64; out Hour, Min, Sec: Word; out fsec: LongWord); overload;
procedure dt2time(jd: Double; out Hour, Min, Sec: Word; out fsec: LongWord); overload;

procedure DateTime2PG(const Value: TDateTime; out Result: Int64); overload;
procedure DateTime2PG(const Value: TDateTime; out Result: Double); overload;

procedure Date2PG(const Value: TDateTime; out Result: Integer);

procedure Time2PG(const Value: TDateTime; out Result: Int64); overload;
procedure Time2PG(const Value: TDateTime; out Result: Double); overload;

function PG2DateTime(Value: Double): TDateTime; overload;
procedure PG2DateTime(Value: Double; out Year, Month, Day, Hour, Min, Sec: Word;
  out fsec: LongWord); overload;

function PG2DateTime(Value: Int64): TDateTime; overload;
procedure PG2DateTime(Value: Int64; out Year, Month, Day, Hour, Min, Sec: Word;
  out fsec: LongWord); overload;

function PG2Time(Value: Double): TDateTime; overload;
function PG2Time(Value: Int64): TDateTime; overload;

function PG2Date(Value: Integer): TDateTime;

function PG2SmallInt(P: Pointer): SmallInt; {$IFDEF WITH_INLINE}inline;{$ENDIF}
procedure SmallInt2PG(Value: SmallInt; Buf: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}

function PG2Word(P: Pointer): Word; {$IFDEF WITH_INLINE}inline;{$ENDIF}
procedure Word2PG(Value: Word; Buf: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}

function PG2Integer(P: Pointer): Integer; {$IFDEF WITH_INLINE}inline;{$ENDIF}
procedure Integer2PG(Value: Integer; Buf: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}

function PG2LongWord(P: Pointer): LongWord; {$IFDEF WITH_INLINE}inline;{$ENDIF}
procedure LongWord2PG(Value: LongWord; Buf: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}

function PG2Int64(P: Pointer): Int64; {$IFDEF WITH_INLINE}inline;{$ENDIF}
procedure Int642PG(const Value: Int64; Buf: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}

function PG2Currency(P: Pointer): Currency; {$IFDEF WITH_INLINE}inline;{$ENDIF}
procedure Currency2PG(const Value: Currency; Buf: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}

function PG2Single(P: Pointer): Single; {$IFDEF WITH_INLINE}inline;{$ENDIF}
procedure Single2PG(Value: Single; Buf: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}

function PG2Double(P: Pointer): Double; {$IFDEF WITH_INLINE}inline;{$ENDIF}
procedure Double2PG(const Value: Double; Buf: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}

procedure MoveReverseByteOrder(Dest, Src: PAnsiChar; Len: LengthInt);



implementation

uses Math,
  ZFastCode, ZMessages, ZDbcPostgreSqlResultSet, ZDbcUtils, ZSysUtils;

{**
   Return ZSQLType from PostgreSQL type name
   @param Connection a connection to PostgreSQL
   @param The TypeName is PostgreSQL type name
   @return The ZSQLType type
}
function PostgreSQLToSQLType(const Connection: IZPostgreSQLConnection;
  const TypeName: string): TZSQLType;
var
  TypeNameLo: string;
begin
  TypeNameLo := LowerCase(TypeName);
  if (TypeNameLo = 'interval') or (TypeNameLo = 'char') or (TypeNameLo = 'bpchar')
    or (TypeNameLo = 'varchar') or (TypeNameLo = 'bit') or (TypeNameLo = 'varbit')
  then//EgonHugeist: Highest Priority Client_Character_set!!!!
    if (Connection.GetConSettings.CPType = cCP_UTF16) then
      Result := stUnicodeString
    else
      Result := stString
  else if TypeNameLo = 'text' then
    Result := stAsciiStream
  else if TypeNameLo = 'oid' then
  begin
    if Connection.IsOidAsBlob() then
      Result := stBinaryStream
    else
      Result := stInteger;
  end
  else if TypeNameLo = 'name' then
    Result := stString
  else if TypeNameLo = 'enum' then
    Result := stString
  else if TypeNameLo = 'cidr' then
    Result := stString
  else if TypeNameLo = 'inet' then
    Result := stString
  else if TypeNameLo = 'macaddr' then
    Result := stString
  else if TypeNameLo = 'int2' then
    Result := stSmall
  else if TypeNameLo = 'int4' then
    Result := stInteger
  else if TypeNameLo = 'int8' then
    Result := stLong
  else if TypeNameLo = 'float4' then
    Result := stFloat
  else if (TypeNameLo = 'float8') or (TypeNameLo = 'decimal')
    or (TypeNameLo = 'numeric') then
    Result := stDouble
  else if TypeNameLo = 'money' then
    Result := stCurrency
  else if TypeNameLo = 'bool' then
    Result := stBoolean
  else if TypeNameLo = 'date' then
    Result := stDate
  else if TypeNameLo = 'time' then
    Result := stTime
  else if (TypeNameLo = 'datetime') or (TypeNameLo = 'timestamp')
    or (TypeNameLo = 'timestamptz') or (TypeNameLo = 'abstime') then
    Result := stTimestamp
  else if TypeNameLo = 'regproc' then
    Result := stString
  else if TypeNameLo = 'bytea' then
  begin
    if Connection.IsOidAsBlob then
      Result := stBytes
    else
      Result := stBinaryStream;
  end
  else if (TypeNameLo = 'int2vector') or (TypeNameLo = 'oidvector') then
    Result := stAsciiStream
  else if (TypeNameLo <> '') and (TypeNameLo[1] = '_') then // ARRAY TYPES
    Result := stAsciiStream
  else if (TypeNameLo = 'uuid') then
    Result := stGuid
  else
    Result := stUnknown;

  if (Connection.GetConSettings.CPType = cCP_UTF16) then
    if Result = stAsciiStream then
      Result := stUnicodeStream;
end;

{**
   Another version of PostgreSQLToSQLType()
     - comparing integer should be faster than AnsiString.
   Return ZSQLType from PostgreSQL type name
   @param Connection a connection to PostgreSQL
   @param TypeOid is PostgreSQL type OID
   @return The ZSQLType type
}
function PostgreSQLToSQLType(const ConSettings: PZConSettings;
  const OIDAsBlob: Boolean; const TypeOid: Integer): TZSQLType; overload;
begin
  case TypeOid of
    INTERVALOID, CHAROID, BPCHAROID, VARCHAROID:  { interval/char/bpchar/varchar }
      if (ConSettings.CPType = cCP_UTF16) then
          Result := stUnicodeString
        else
          Result := stString;
    TEXTOID: Result := stAsciiStream; { text }
    OIDOID: { oid }
      begin
        if OidAsBlob then
          Result := stBinaryStream
        else
          Result := stInteger;
      end;
    NAMEOID: Result := stString; { name }
    INT2OID: Result := stSmall; { int2 }
    INT4OID: Result := stInteger; { int4 }
    INT8OID: Result := stLong; { int8 }
    CIDROID: Result := stString; { cidr }
    INETOID: Result := stString; { inet }
    MACADDROID: Result := stString; { macaddr }
    FLOAT4OID: Result := stFloat; { float4 }
    FLOAT8OID, NUMERICOID: Result := stDouble; { float8/numeric. no 'decimal' any more }
    CASHOID: Result := stCurrency; { money }
    BOOLOID: Result := stBoolean; { bool }
    DATEOID: Result := stDate; { date }
    TIMEOID: Result := stTime; { time }
    TIMESTAMPOID, TIMESTAMPTZOID, ABSTIMEOID: Result := stTimestamp; { timestamp,timestamptz/abstime. no 'datetime' any more}
    BITOID, VARBITOID: Result := stString; {bit/ bit varying string}
    REGPROCOID: Result := stString; { regproc }
    1034: Result := stAsciiStream; {aclitem[]}
    BYTEAOID: { bytea }
      begin
        if OidAsBlob then
          Result := stBytes
        else
          Result := stBinaryStream;
      end;
    UUIDOID: Result := stGUID; {uuid}
    INT2VECTOROID, OIDVECTOROID: Result := stAsciiStream; { int2vector/oidvector. no '_aclitem' }
    143,629,651,719,791,1000..OIDARRAYOID,1040,1041,1115,1182,1183,1185,1187,1231,1263,
    1270,1561,1563,2201,2207..2211,2949,2951,3643,3644,3645,3735,3770 : { other array types }
      Result := stAsciiStream;
    else
      Result := stUnknown;
  end;

  if (ConSettings.CPType = cCP_UTF16) then
    if Result = stAsciiStream then
      Result := stUnicodeStream;
end;

function SQLTypeToPostgreSQL(SQLType: TZSQLType; IsOidAsBlob: boolean): string;
begin
  case SQLType of
    stBoolean: Result := 'bool';
    stByte, stSmall, stInteger, stLong: Result := 'int';
    stFloat, stDouble, stBigDecimal: Result := 'numeric';
    stString, stUnicodeString, stAsciiStream, stUnicodeStream: Result := 'text';
    stDate: Result := 'date';
    stTime: Result := 'time';
    stTimestamp: Result := 'timestamp';
    stGuid: Result := 'uuid';
    stBinaryStream, stBytes:
      if IsOidAsBlob then
        Result := 'oid'
      else
        Result := 'bytea';
  end;
end;

procedure SQLTypeToPostgreSQL(SQLType: TZSQLType; IsOidAsBlob: Boolean; out aOID: OID);
begin
  case SQLType of
    stBoolean: aOID := BOOLOID;
    stByte, stShort, stSmall: aOID := INT2OID;
    stWord, stInteger: aOID := INT4OID;
    stLongWord, stLong, stULong: aOID := INT8OID;
    stFloat: aOID := FLOAT4OID;
    stDouble, stBigDecimal: aOID := FLOAT8OID;
    stCurrency: aOID := FLOAT8OID;//CASHOID;  the pg money has a scale of 2 while we've a scale of 4
    stString, stUnicodeString,//: aOID := VARCHAROID;
    stAsciiStream, stUnicodeStream: aOID := TEXTOID;
    stDate: aOID := DATEOID;
    stTime: aOID := TIMEOID;
    stTimestamp: aOID := TIMESTAMPOID;
    stGuid: aOID := OIDOID;
    stBytes: aOID := BYTEAOID;
    stBinaryStream:
      if IsOidAsBlob
      then aOID := OIDOID
      else aOID := BYTEAOID;
  end;
end;

{**
  Indicate what field type is a number (integer, float and etc.)
  @param  the SQLType field type value
  @result true if field type number
}
function IsNumber(Value: TZSQLType): Boolean;
begin
  Result := Value in [stByte, stSmall, stInteger, stLong,
    stFloat, stDouble, stBigDecimal];
end;

{**
  Encode string which probably consists of multi-byte characters.
  Characters ' (apostraphy), low value (value zero), and \ (back slash) are encoded.
  Since we have noticed that back slash is the second byte of some BIG5 characters
    (each of them is two bytes in length), we need a characterset aware encoding function.
  @param CharactersetCode the characterset in terms of enumerate code.
  @param Value the regular string.
  @return the encoded string.
}
function PGEscapeString(SrcBuffer: PAnsiChar; SrcLength: Integer;
    ConSettings: PZConSettings; Quoted: Boolean): RawByteString;
var
  I, LastState: Integer;
  DestLength: Integer;
  DestBuffer: PAnsiChar;

  function pg_CS_stat(stat: integer; character: integer;
          CharactersetCode: TZPgCharactersetType): integer;
  begin
    if character = 0 then
      stat := 0;

    case CharactersetCode of
      csUTF8, csUNICODE_PODBC:
        begin
          if (stat < 2) and (character >= $80) then
          begin
            if character >= $fc then
              stat := 6
            else if character >= $f8 then
              stat := 5
            else if character >= $f0 then
              stat := 4
            else if character >= $e0 then
              stat := 3
            else if character >= $c0 then
              stat := 2;
          end
          else
            if (stat > 2) and (character > $7f) then
              Dec(stat)
            else
              stat := 0;
        end;
  { Shift-JIS Support. }
      csSJIS:
        begin
      if (stat < 2)
        and (character > $80)
        and not ((character > $9f) and (character < $e0)) then
        stat := 2
      else if stat = 2 then
        stat := 1
      else
        stat := 0;
        end;
  { Chinese Big5 Support. }
      csBIG5:
        begin
      if (stat < 2) and (character > $A0) then
        stat := 2
      else if stat = 2 then
        stat := 1
      else
        stat := 0;
        end;
  { Chinese GBK Support. }
      csGBK:
        begin
      if (stat < 2) and (character > $7F) then
        stat := 2
      else if stat = 2 then
        stat := 1
      else
        stat := 0;
        end;

  { Korian UHC Support. }
      csUHC:
        begin
      if (stat < 2) and (character > $7F) then
        stat := 2
      else if stat = 2 then
        stat := 1
      else
        stat := 0;
        end;

  { EUC_JP Support }
      csEUC_JP:
        begin
      if (stat < 3) and (character = $8f) then { JIS X 0212 }
        stat := 3
      else
      if (stat <> 2)
        and ((character = $8e) or
        (character > $a0)) then { Half Katakana HighByte & Kanji HighByte }
        stat := 2
      else if stat = 2 then
        stat := 1
      else
        stat := 0;
        end;

  { EUC_CN, EUC_KR, JOHAB Support }
      csEUC_CN, csEUC_KR, csJOHAB:
        begin
      if (stat < 2) and (character > $a0) then
        stat := 2
      else if stat = 2 then
        stat := 1
      else
        stat := 0;
        end;
      csEUC_TW:
        begin
      if (stat < 4) and (character = $8e) then
        stat := 4
      else if (stat = 4) and (character > $a0) then
        stat := 3
      else if ((stat = 3) or (stat < 2)) and (character > $a0) then
        stat := 2
      else if stat = 2 then
        stat := 1
      else
        stat := 0;
        end;
        { Chinese GB18030 support.Added by Bill Huang <bhuang@redhat.com> <bill_huanghb@ybb.ne.jp> }
      csGB18030:
        begin
      if (stat < 2) and (character > $80) then
        stat := 2
      else if stat = 2 then
      begin
        if (character >= $30) and (character <= $39) then
          stat := 3
        else
          stat := 1;
      end
      else if stat = 3 then
      begin
        if (character >= $30) and (character <= $39) then
          stat := 1
        else
          stat := 3;
      end
      else
        stat := 0;
        end;
      else
      stat := 0;
    end;
    Result := stat;
  end;

begin
  DestBuffer := SrcBuffer; //safe entry
  DestLength := Ord(Quoted) shl 1;
  LastState := 0;
  for I := 1 to SrcLength do
  begin
    LastState := pg_CS_stat(LastState,integer(SrcBuffer^),
      TZPgCharactersetType(ConSettings.ClientCodePage.ID));
    if (SrcBuffer^ in [#0, '''']) or ((SrcBuffer^ = '\') and (LastState = 0)) then
      Inc(DestLength, 4)
    else
      Inc(DestLength);
    Inc(SrcBuffer);
  end;

  SrcBuffer := DestBuffer; //restore entry
  SetLength(Result, DestLength);
  DestBuffer := Pointer(Result);
  if Quoted then begin
    DestBuffer^ := '''';
    Inc(DestBuffer);
  end;

  LastState := 0;
  for I := 1 to SrcLength do
  begin
    LastState := pg_CS_stat(LastState,integer(SrcBuffer^),
      TZPgCharactersetType(ConSettings.ClientCodePage.ID));
    if CharInSet(SrcBuffer^, [#0, '''']) or ((SrcBuffer^ = '\') and (LastState = 0)) then
    begin
      DestBuffer[0] := '\';
      DestBuffer[1] := AnsiChar(Ord('0') + (Byte(SrcBuffer^) shr 6));
      DestBuffer[2] := AnsiChar(Ord('0') + ((Byte(SrcBuffer^) shr 3) and $07));
      DestBuffer[3] := AnsiChar(Ord('0') + (Byte(SrcBuffer^) and $07));
      Inc(DestBuffer, 4);
    end
    else
    begin
      DestBuffer^ := SrcBuffer^;
      Inc(DestBuffer);
    end;
    Inc(SrcBuffer);
  end;
  if Quoted then
    DestBuffer^ := '''';
end;


{**
  add by Perger -> based on SourceForge:
  [ 1520587 ] Fix for 1484704: bytea corrupted on post when not using utf8,
  file: 1484704.patch

  Converts a binary string into escape PostgreSQL format.
  @param Value a binary stream.
  @return a string in PostgreSQL binary string escape format.
}
function EncodeBinaryString(SrcBuffer: PAnsiChar; Len: Integer; Quoted: Boolean = False): RawByteString;
var
  I: Integer;
  DestLength: Integer;
  DestBuffer: PAnsiChar;
begin
  DestBuffer := SrcBuffer; //save entry
  DestLength := Ord(Quoted) shl 1;
  for I := 1 to Len do
  begin
    if (Byte(SrcBuffer^) < 32) or (Byte(SrcBuffer^) > 126)
    or (SrcBuffer^ in ['''', '\']) then
      Inc(DestLength, 5)
    else
      Inc(DestLength);
    Inc(SrcBuffer);
  end;
  SrcBuffer := DestBuffer; //restore

  SetLength(Result, DestLength);
  DestBuffer := Pointer(Result);
  if Quoted then begin
    DestBuffer^ := '''';
    Inc(DestBuffer);
  end;

  for I := 1 to Len do
  begin
    if (Byte(SrcBuffer^) < 32) or (Byte(SrcBuffer^) > 126) or (SrcBuffer^ in ['''', '\']) then
    begin
      DestBuffer[0] := '\';
      DestBuffer[1] := '\';
      DestBuffer[2] := AnsiChar(Ord('0') + (Byte(SrcBuffer^) shr 6));
      DestBuffer[3] := AnsiChar(Ord('0') + ((Byte(SrcBuffer^) shr 3) and $07));
      DestBuffer[4] := AnsiChar(Ord('0') + (Byte(SrcBuffer^) and $07));
      Inc(DestBuffer, 5);
    end
    else
    begin
      DestBuffer^ := SrcBuffer^;
      Inc(DestBuffer);
    end;
    Inc(SrcBuffer);
  end;
  if Quoted then
    DestBuffer^ := '''';
end;

{**
  Converts an string from escape PostgreSQL format.
  @param Value a string in PostgreSQL escape format.
  @return a regular string.
}
function DecodeString(const Value: AnsiString): AnsiString;
var
  SrcLength, DestLength: Integer;
  SrcBuffer, DestBuffer: PAnsiChar;
begin
  SrcLength := Length(Value);
  SrcBuffer := PAnsiChar(Value);
  SetLength(Result, SrcLength);
  DestLength := 0;
  DestBuffer := PAnsiChar(Result);

  while SrcLength > 0 do
  begin
    if SrcBuffer^ = '\' then
    begin
      Inc(SrcBuffer);
      if CharInSet(SrcBuffer^, ['\', '''']) then
      begin
        DestBuffer^ := SrcBuffer^;
        Inc(SrcBuffer);
        Dec(SrcLength, 2);
      end
      else
      begin
        DestBuffer^ := AnsiChar(((Byte(SrcBuffer[0]) - Ord('0')) shl 6)
          or ((Byte(SrcBuffer[1]) - Ord('0')) shl 3)
          or ((Byte(SrcBuffer[2]) - Ord('0'))));
        Inc(SrcBuffer, 3);
        Dec(SrcLength, 4);
      end;
    end
    else
    begin
      DestBuffer^ := SrcBuffer^;
      Inc(SrcBuffer);
      Dec(SrcLength);
    end;
    Inc(DestBuffer);
    Inc(DestLength);
  end;
  SetLength(Result, DestLength);
end;

{**
  Checks for possible sql errors.
  @param Connection a reference to database connection to execute Rollback.
  @param PlainDriver a PostgreSQL plain driver.
  @param Handle a PostgreSQL connection reference.
  @param LogCategory a logging category.
  @param LogMessage a logging message.
  //FirmOS 22.02.06
  @param ResultHandle the Handle to the Result
}
procedure HandlePostgreSQLError(const Sender: IImmediatelyReleasable;
  const PlainDriver: TZPostgreSQLPlainDriver; conn: PGconn;
  LogCategory: TZLoggingCategory; const LogMessage: RawByteString;
  ResultHandle: PZPostgreSQLResult);
var
   resultErrorField: PAnsiChar;
   ErrorMessage: PAnsiChar;
   ConSettings: PZConSettings;
   aMessage, aErrorStatus: String;
begin
  ErrorMessage := PlainDriver.PQerrorMessage(conn);
  if PGSucceeded(ErrorMessage) then Exit;

  if Assigned(ResultHandle) and Assigned(PlainDriver.PQresultErrorField) {since 7.4}
  then resultErrorField := PlainDriver.PQresultErrorField(ResultHandle,Ord(PG_DIAG_SQLSTATE))
  else resultErrorField := nil;

  if Assigned(Sender) then begin
    ConSettings := Sender.GetConSettings;
    aMessage := Format(SSQLError1, [ConSettings^.ConvFuncs.ZRawToString(
        ErrorMessage, ConSettings^.ClientCodePage^.CP, ConSettings^.CTRL_CP)]);
    aErrorStatus := ConSettings^.ConvFuncs.ZRawToString(resultErrorField,
          ConSettings^.ClientCodePage^.CP, ConSettings^.CTRL_CP);
    if DriverManager.HasLoggingListener then
      DriverManager.LogError(LogCategory, ConSettings^.Protocol, LogMessage,
        0, ErrorMessage);
  end else begin
    aMessage := Format(SSQLError1, [String(ErrorMessage)]);
    aErrorStatus := String(resultErrorField);
    if DriverManager.HasLoggingListener then
      DriverManager.LogError(LogCategory, 'postresql', LogMessage, 0, ErrorMessage);
  end;


  if ResultHandle <> nil then
    PlainDriver.PQclear(ResultHandle);
  if PlainDriver.PQstatus(conn) = CONNECTION_BAD then begin
    if Assigned(Sender) then
      Sender.ReleaseImmediat(Sender);
    raise EZSQLConnectionLost.CreateWithCodeAndStatus(Ord(CONNECTION_BAD), aErrorStatus, aMessage);
  end else if LogCategory <> lcUnprepStmt then //silence -> https://sourceforge.net/p/zeoslib/tickets/246/
    raise EZSQLException.CreateWithStatus(aErrorStatus, aMessage);
end;

function PGSucceeded(ErrorMessage: PAnsiChar): Boolean;
begin
  Result := (ErrorMessage = nil) or (ErrorMessage^ = #0);
end;

{**
   Resolve problem with minor version in PostgreSql bettas
   @param Value a minor version string like "4betta2"
   @return a miror version number
}
function GetMinorVersion(const Value: string): Word;
var
  I: integer;
  Temp: string;
begin
  Temp := '';
  for I := 1 to Length(Value) do
    if CharInSet(Value[I], ['0'..'9']) then
      Temp := Temp + Value[I]
    else
      Break;
  Result := StrToIntDef(Temp, 0);
end;

{**
  Prepares an SQL parameter for the query.
  @param ParameterIndex the first parameter is 1, the second is 2, ...
  @return a string representation of the parameter.
}
function PGPrepareAnsiSQLParam(const Value: TZVariant; const ClientVarManager: IZClientVariantManager;
  const Connection: IZPostgreSQLConnection; ChunkSize: Cardinal;
  InParamType: TZSQLType; oidasblob, DateTimePrefix, QuotedNumbers: Boolean;
  ConSettings: PZConSettings): RawByteString;
var
  TempBlob: IZBlob;
  WriteTempBlob: IZPostgreSQLOidBlob;
  CharRec: TZCharRec;
  TempVar: TZVariant;
begin
  if ClientVarManager.IsNull(Value)  then
    Result := 'NULL'
  else case InParamType of
    stBoolean:
      Result := BoolStrsUpRaw[ClientVarManager.GetAsBoolean(Value)];
    stByte, stShort, stWord, stSmall, stLongWord, stInteger, stUlong, stLong,
    stFloat, stDouble, stCurrency, stBigDecimal:
      begin
        Result := ClientVarManager.GetAsRawByteString(Value);
        if QuotedNumbers then Result := #39+Result+#39;
      end;
    stBytes:
      Result := Connection.EncodeBinary(SoftVarManager.GetAsBytes(Value), True);
    stString, stUnicodeString: begin
        ClientVarManager.Assign(Value, TempVar);
        CharRec := ClientVarManager.GetAsCharRec(TempVar, ConSettings.ClientCodePage^.CP);
        Result := Connection.EscapeString(CharRec.P, CharRec.Len, True);
      end;
    stGuid: if Value.VType = vtBytes
            then Result := #39+GUIDToRaw(Value.VBytes)+#39
            else Result := #39+ClientVarManager.GetAsRawByteString(Value)+#39;
    stDate:
      if DateTimePrefix then
        Result := DateTimeToRawSQLDate(ClientVarManager.GetAsDateTime(Value),
          ConSettings^.WriteFormatSettings, True, '::date')
      else
        Result := DateTimeToRawSQLDate(ClientVarManager.GetAsDateTime(Value),
          ConSettings^.WriteFormatSettings, True);
    stTime:
      if DateTimePrefix then
        Result := DateTimeToRawSQLTime(ClientVarManager.GetAsDateTime(Value),
          ConSettings^.WriteFormatSettings, True, '::time')
      else
        Result := DateTimeToRawSQLTime(ClientVarManager.GetAsDateTime(Value),
          ConSettings^.WriteFormatSettings, True);
    stTimestamp:
      if DateTimePrefix then
        Result := DateTimeToRawSQLTimeStamp(ClientVarManager.GetAsDateTime(Value),
          ConSettings^.WriteFormatSettings, True, '::timestamp')
      else
        Result := DateTimeToRawSQLTimeStamp(ClientVarManager.GetAsDateTime(Value),
          ConSettings^.WriteFormatSettings, True);
    stAsciiStream, stUnicodeStream, stBinaryStream:
      begin
        TempBlob := ClientVarManager.GetAsInterface(Value) as IZBlob;
        if not TempBlob.IsEmpty then
        begin
          case InParamType of
            stBinaryStream:
              if (Connection.IsOidAsBlob) or oidasblob then
              begin
                try
                  WriteTempBlob := TZPostgreSQLOidBlob.Create(
                    TZPostgreSQLPlainDriver(Connection.GetIZPlainDriver.GetInstance),
                    nil, 0, Connection.GetConnectionHandle, 0, ChunkSize);
                  WriteTempBlob.WriteBuffer(TempBlob.GetBuffer, TempBlob.Length);
                  Result := IntToRaw(WriteTempBlob.GetBlobOid);
                finally
                  WriteTempBlob := nil;
                end;
              end
              else
                Result := Connection.EncodeBinary(TempBlob.GetBuffer, TempBlob.Length, True);
            stAsciiStream, stUnicodeStream:
              if TempBlob.IsClob then begin
                CharRec.P := TempBlob.GetPAnsiChar(ConSettings^.ClientCodePage^.CP);
                Result := Connection.EscapeString(CharRec.P, TempBlob.Length, True)
              end else
                Result := Connection.EscapeString(GetValidatedAnsiStringFromBuffer(TempBlob.GetBuffer,
                  TempBlob.Length, ConSettings));
          end; {case..}
        end
        else
          Result := 'NULL';
        TempBlob := nil;
      end; {if not TempBlob.IsEmpty then}
    else
      RaiseUnsupportedParameterTypeException(InParamType);
  end;
end;

function date2j(y, m, d: Integer): Integer;
var
  julian: Integer;
  century: Integer;
begin
  if (m > 2) then begin
    m := m+1;
    y := y+4800;
  end else begin
    m := M + 13;
    y := y + 4799;
  end;

  century := y div 100;
  julian := y * 365 - 32167;
  julian := julian + y div 4 - century + century div 4;
  Result := julian + 7834 * m div 256 + d;
end;

procedure j2date(jd: Integer; out AYear, AMonth, ADay: Word);
var
  julian, quad, extra: LongWord;
  y: Integer;
begin
  julian := jd;
  julian := julian + 32044;
  quad := julian div 146097;
  extra := (julian - quad * 146097) * 4 + 3;
  julian := julian + 60 + quad * 3 + extra div 146097;
  quad := julian div 1461;
  julian := julian - quad * 1461;
  y := julian * 4 div 1461;
  if y <> 0 then
    julian := (julian + 305) mod 365
  else
    julian := (julian + 306) mod 366;
  julian := julian + 123;
  y := y + Integer(quad * 4);
  AYear := y - 4800;
  quad := julian * 2141 div 65536;
  ADay := julian - 7834 * quad div 256;
  AMonth := (quad + 10) mod 12{MONTHS_PER_YEAR} + 1;
end;

{$IFNDEF ENDIAN_BIG}
procedure Reverse2Bytes(P: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}
var W: Byte;
begin
  W := PByte(P)^;
  PByteArray(P)[0] := PByteArray(P)[1];
  PByteArray(P)[1] := W;
end;
{$ENDIF}

{$IFNDEF ENDIAN_BIG}
procedure Reverse4Bytes(P: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}
var W: Word;
begin
  W := PWord(P)^;
  PByteArray(P)[0] := PByteArray(P)[3];
  PByteArray(P)[1] := PByteArray(P)[2];
  PByteArray(P)[2] := PByteArray(@W)[1];
  PByteArray(P)[3] := PByteArray(@W)[0];
end;
{$ENDIF}

{$IFNDEF ENDIAN_BIG}
procedure Reverse8Bytes(P: Pointer); {$IFDEF WITH_INLINE}inline;{$ENDIF}
var W: LongWord;
begin
  W := PLongWord(P)^;
  PByteArray(P)[0] := PByteArray(P)[7];
  PByteArray(P)[1] := PByteArray(P)[6];
  PByteArray(P)[2] := PByteArray(P)[5];
  PByteArray(P)[3] := PByteArray(P)[4];
  PByteArray(P)[4] := PByteArray(@W)[3];
  PByteArray(P)[5] := PByteArray(@W)[2];
  PByteArray(P)[6] := PByteArray(@W)[1];
  PByteArray(P)[7] := PByteArray(@W)[0];
end;
{$ENDIF}

procedure DateTime2PG(const Value: TDateTime; out Result: Int64);
var Year, Month, Day, Hour, Min, Sec, MSec: Word;
  Date: Int64; //overflow save multiply
begin
  DecodeDate(Value, Year, Month, Day);
  Date := date2j(Year, Month, Day) - POSTGRES_EPOCH_JDATE;
  DecodeTime(Value, Hour, Min, Sec, MSec);
  //timestamps do not play with microseconds!!
  Result := ((Hour * MINS_PER_HOUR + Min) * SECS_PER_MINUTE + Sec) * MSecsPerSec + MSec;
  Result := (Date * MSecsPerDay + Result) * MSecsPerSec;
  {$IFNDEF ENDIAN_BIG}
  Reverse8Bytes(@Result);
  {$ENDIF}
end;

procedure DateTime2PG(const Value: TDateTime; out Result: Double);
var Year, Month, Day, Hour, Min, Sec, MSec: Word;
  Date: Double; //overflow save multiply
begin
  DecodeDate(Value, Year, Month, Day);
  Date := date2j(Year, Month, Day) - POSTGRES_EPOCH_JDATE;
  DecodeTime(Value, Hour, Min, Sec, MSec);
  Result := (Hour * MinsPerHour + Min) * SecsPerMin + Sec + Msec / MSecsPerSec;
  Result := Date * SECS_PER_DAY + Result;
  {$IFNDEF ENDIAN_BIG}
  Reverse8Bytes(@Result);
  {$ENDIF}
end;

function PG2DateTime(Value: Double): TDateTime;
var date: TDateTime;
  Year, Month, Day, Hour, Min, Sec: Word;
  fsec: LongWord;
begin
  PG2DateTime(Value, Year, Month, Day, Hour, Min, Sec, fsec);
  TryEncodeDate(Year, Month, Day, date);
  dt2time(Value, Hour, Min, Sec, fsec);
  TryEncodeTime(Hour, Min, Sec, fsec, Result);
  Result := date + Result;
end;

procedure PG2DateTime(value: Double; out Year, Month, Day, Hour, Min, Sec: Word;
  out fsec: LongWord);
var
  date: Double;
  time: Double;
begin
  {$IFNDEF ENDIAN_BIG}
  Reverse8Bytes(@Value);
  {$ENDIF}
  time := value;
  if Time < 0
  then date := Ceil(time / SecsPerDay)
  else date := Floor(time / SecsPerDay);
  if date <> 0 then
    Time := Time - Round(date * SecsPerDay);
  if Time < 0 then begin
    Time := Time + SecsPerDay;
    date := date - 1;
  end;
  date := date + POSTGRES_EPOCH_JDATE;
  j2date(Integer(Trunc(date)), Year, Month, Day);
  dt2time(Time, Hour, Min, Sec, fsec);
end;

function PG2DateTime(Value: Int64): TDateTime;
var date: TDateTime;
  Year, Month, Day, Hour, Min, Sec: Word;
  fsec: LongWord;
begin
  PG2DateTime(Value, Year, Month, Day, Hour, Min, Sec, fsec);
  if not TryEncodeDate(Year, Month, Day, date) then
    Date := 0;
  if not TryEncodeTime(Hour, Min, Sec, fsec div MSecsPerSec, Result) then
    Result := 0;
  Result := date + Result;
end;

procedure PG2DateTime(Value: Int64; out Year, Month, Day, Hour, Min, Sec: Word;
  out fsec: LongWord);
var date: Int64;
begin
  {$IFNDEF ENDIAN_BIG}
  Reverse8Bytes(@Value);
  {$ENDIF}
  date := Value div USECS_PER_DAY;
  Value := Value mod USECS_PER_DAY;
  if Value < 0 then begin
    Value := Value + USECS_PER_DAY;
    date := date - 1;
  end;
  date := date + POSTGRES_EPOCH_JDATE;
  j2date(date, Year, Month, Day);
  dt2time(Value, Hour, Min, Sec, fsec);
end;

procedure dt2time(jd: Int64; out Hour, Min, Sec: Word; out fsec: LongWord);
begin
  Hour := jd div USECS_PER_HOUR;
  jd := jd - Int64(Hour) * Int64(USECS_PER_HOUR);
  Min := jd div USECS_PER_MINUTE;
  jd := jd - Int64(Min) * Int64(USECS_PER_MINUTE);
  Sec := jd div USECS_PER_SEC;
  Fsec := jd - (Int64(Sec) * Int64(USECS_PER_SEC));
end;

procedure dt2time(jd: Double; out Hour, Min, Sec: Word; out fsec: LongWord);
begin
  Hour := Trunc(jd / SECS_PER_HOUR);
  jd := jd - Hour * SECS_PER_HOUR;
  Min := Trunc(jd / SECS_PER_MINUTE);
  jd := jd - Min * SECS_PER_MINUTE;
  Sec := Trunc(jd);
  Fsec := Trunc(jd - Sec);
end;

procedure Time2PG(const Value: TDateTime; out Result: Int64);
var Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(Value, Hour, Min, Sec, MSec);
  Result := (((((hour * MINS_PER_HOUR) + min) * SECS_PER_MINUTE) + sec) * USECS_PER_SEC) + Msec;
  {$IFNDEF ENDIAN_BIG}
  Reverse8Bytes(@Result);
  {$ENDIF}
end;

procedure Time2PG(const Value: TDateTime; out Result: Double);
var Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(Value, Hour, Min, Sec, MSec);
  //macro of datetime.c
  Result := (((hour * MINS_PER_HOUR) + min) * SECS_PER_MINUTE) + sec + Msec;
  {$IFNDEF ENDIAN_BIG}
  Reverse8Bytes(@Result);
  {$ENDIF}
end;

function PG2Time(Value: Double): TDateTime;
var Hour, Min, Sec: Word; fsec: LongWord;
begin
  {$IFNDEF ENDIAN_BIG}
  Reverse8Bytes(@Value);
  {$ENDIF}
  dt2Time(Value, Hour, Min, Sec, fsec);
  if not TryEncodeTime(Hour, Min, Sec, Fsec, Result) then
    Result := 0;
end;

function PG2Time(Value: Int64): TDateTime;
var Hour, Min, Sec: Word; fsec: LongWord;
begin
  {$IFNDEF ENDIAN_BIG}
  Reverse8Bytes(@Value);
  {$ENDIF}
  dt2Time(Value, Hour, Min, Sec, fsec);
  if not TryEncodeTime(Hour, Min, Sec, Fsec, Result) then
    Result := 0;
end;

procedure Date2PG(const Value: TDateTime; out Result: Integer);
var y,m,d: Word;
begin
  DecodeDate(Value, y,m,d);
  Result := date2j(y,m,d) - POSTGRES_EPOCH_JDATE;
  {$IFNDEF ENDIAN_BIG}
  Reverse4Bytes(@Result);
  {$ENDIF}
end;

function PG2Date(Value: Integer): TDateTime;
var
  Year, Month, Day: Word;
begin
  {$IFNDEF ENDIAN_BIG}
  Reverse4Bytes(@Value);
  {$ENDIF}
  j2date(Value+POSTGRES_EPOCH_JDATE, Year, Month, Day);
  if not TryEncodeDate(Year, Month, Day, Result) then
    Result := 0;
end;

procedure MoveReverseByteOrder(Dest, Src: PAnsiChar; Len: LengthInt);
begin
  { adjust byte order of host to network  }
  {$IFNDEF ENDIAN_BIG}
  Dest := Dest+Len-1;
  while Len > 0 do begin
    Dest^ := Src^;
    dec(Dest);
    Inc(Src);
    dec(Len);
  end;
  {$ELSE}
  Move(Src^, Dest^, Len);
  {$ENDIF}
end;

function PG2SmallInt(P: Pointer): SmallInt;
begin
  Result := PSmallInt(P)^;
  {$IFNDEF ENDIAN_BIG}Reverse2Bytes(@Result){$ENDIF}
end;

procedure SmallInt2PG(Value: SmallInt; Buf: Pointer);
begin
  PSmallInt(Buf)^ := Value;
  {$IFNDEF ENDIAN_BIG}Reverse2Bytes(Buf){$ENDIF}
end;

function PG2Word(P: Pointer): Word;
begin
  Result := PWord(P)^;
  {$IFNDEF ENDIAN_BIG}Reverse2Bytes(@Result){$ENDIF}
end;

procedure Word2PG(Value: Word; Buf: Pointer);
begin
  PWord(Buf)^ := Value;
  {$IFNDEF ENDIAN_BIG}Reverse2Bytes(Buf){$ENDIF}
end;

function PG2Integer(P: Pointer): Integer;
begin
  Result := PInteger(P)^;
  {$IFNDEF ENDIAN_BIG}Reverse4Bytes(@Result){$ENDIF}
end;

procedure Integer2PG(Value: Integer; Buf: Pointer);
begin
  PInteger(Buf)^ := Value;
  {$IFNDEF ENDIAN_BIG}Reverse4Bytes(Buf){$ENDIF}
end;

function PG2LongWord(P: Pointer): LongWord;
begin
  Result := PLongWord(P)^;
  {$IFNDEF ENDIAN_BIG}Reverse4Bytes(@Result){$ENDIF}
end;

procedure LongWord2PG(Value: LongWord; Buf: Pointer);
begin
  PLongWord(Buf)^ := Value;
  {$IFNDEF ENDIAN_BIG}Reverse4Bytes(Buf){$ENDIF}
end;

function PG2Int64(P: Pointer): Int64;
begin
  Result := PInt64(P)^;
  {$IFNDEF ENDIAN_BIG}Reverse8Bytes(@Result){$ENDIF}
end;

procedure Int642PG(const Value: Int64; Buf: Pointer);
begin
  PInt64(Buf)^ := Value;
  {$IFNDEF ENDIAN_BIG}Reverse8Bytes(Buf){$ENDIF}
end;

function PG2Currency(P: Pointer): Currency;
begin
  PInt64(@Result)^ := PInt64(P)^; //move first
  {$IFNDEF ENDIAN_BIG}Reverse8Bytes(@Result);{$ENDIF}
  Result := PInt64(@Result)^/100;
end;

procedure Currency2PG(const Value: Currency; Buf: Pointer);
begin
  PInt64(Buf)^ := Trunc(Value*100);
  {$IFNDEF ENDIAN_BIG}Reverse8Bytes(Buf){$ENDIF}
end;

function PG2Single(P: Pointer): Single;
begin
  Result := PSingle(P)^;
  {$IFNDEF ENDIAN_BIG}Reverse4Bytes(@Result){$ENDIF}
end;

procedure Single2PG(Value: Single; Buf: Pointer);
begin
  PSingle(Buf)^ := Value;
  {$IFNDEF ENDIAN_BIG}Reverse4Bytes(Buf){$ENDIF}
end;

function PG2Double(P: Pointer): Double;
begin
  Result := PDouble(P)^;
  {$IFNDEF ENDIAN_BIG}Reverse8Bytes(@Result){$ENDIF}
end;

procedure Double2PG(const Value: Double; Buf: Pointer);
begin
  PDouble(Buf)^ := Value;
  {$IFNDEF ENDIAN_BIG}Reverse8Bytes(Buf){$ENDIF}
end;

end.
