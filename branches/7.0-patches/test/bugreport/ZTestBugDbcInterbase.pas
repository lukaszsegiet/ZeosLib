{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{        Test Cases for Interbase DBC Bug Reports         }
{                                                         }
{*********************************************************}

{@********************************************************}
{    Copyright (c) 1999-2006 Zeos Development Group       }
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
{   http://zeosbugs.firmos.at (BUGTRACKER)                }
{   svn://zeos.firmos.at/zeos/trunk (SVN Repository)      }
{                                                         }
{   http://www.sourceforge.net/projects/zeoslib.          }
{   http://www.zeoslib.sourceforge.net                    }
{                                                         }
{                                                         }
{                                                         }
{                                 Zeos Development Group. }
{********************************************************@}

unit ZTestBugDbcInterbase;

interface

{$I ZBugReport.inc}

uses
  Classes, SysUtils, {$IFDEF FPC}testregistry{$ELSE}TestFramework{$ENDIF},
  ZDbcIntfs, ZCompatibility, ZDbcInterbase6, ZSqlTestCase;

type

  {** Implements a DBC bug report test case for Interbase. }
  TZTestDbcInterbaseBugReport = class(TZAbstractDbcSQLTestCase)
  protected
    function GetSupportedProtocols: string; override;
  published
    procedure Test789879;
    procedure Test841559;
    procedure Test843655;
    procedure Test865441;
    procedure Test864622;
    procedure Test886914;
    procedure Test886854;
    procedure Test934253;
  end;

implementation

uses ZTestCase, ZTestConsts;

{ TZTestDbcInterbaseBugReport }

function TZTestDbcInterbaseBugReport.GetSupportedProtocols: string;
begin
  Result := pl_all_interbase;
end;

procedure TZTestDbcInterbaseBugReport.Test789879;
var
  ResultSet: IZResultSet;
  Statement: IZStatement;
begin
  if SkipForReason(srClosedBug) then Exit;

  Statement := Connection.CreateStatement;
  Statement.SetResultSetType(rtScrollInsensitive);
  Statement.SetResultSetConcurrency(rcUpdatable);

  Statement.Execute('DELETE FROM TABLE789879');
  ResultSet := Statement.ExecuteQuery('SELECT * FROM TABLE789879');

  with ResultSet do
  begin
    MoveToInsertRow;
    UpdateFloat(1, 1.14);
    InsertRow;
  end;
  ResultSet := nil;

  ResultSet := Statement.ExecuteQuery('SELECT * FROM TABLE789879');
  with ResultSet do
  begin
    Next;
    CheckEquals(1.14, GetFloat(1), 0.001);
  end;
  ResultSet := nil;
  Statement.Close;
end;

{**
   Runs a test for bug report #833489
   Can't show messages from triggers
}
procedure TZTestDbcInterbaseBugReport.Test841559;
var
  Temp: boolean;
  Statement: IZStatement;
begin
  if SkipForReason(srClosedBug) then Exit;

  Temp := False;
  Statement := Connection.CreateStatement;
  Statement.SetResultSetType(rtScrollInsensitive);
  Statement.SetResultSetConcurrency(rcUpdatable);

  Statement.Execute('DELETE FROM TABLE841559');
  try
   Statement.Execute('INSERT INTO TABLE841559 (FLD1, FLD2) VALUES (1, NULL)');
  except
   Temp := True;
  end;
  CheckEquals(True, Temp, 'Just exception EXCEPTION841559');
end;

procedure TZTestDbcInterbaseBugReport.Test843655;
var
  Statement: IZStatement;
  ResultSet: IZResultSet;
  StrStream, BinStream: TMemoryStream;
  StrStream1, BinStream1: TStream;
begin
  if SkipForReason(srClosedBug) then Exit;

  { load data to the stream }
  BinStream := TMemoryStream.Create;
  StrStream := TMemoryStream.Create;
  BinStream.LoadFromFile('../../../database/images/dogs.jpg');
  BinStream.Size := 512;
  StrStream.LoadFromFile('../../../database/text/lgpl.txt');
  StrStream.Size := 512;

  BinStream1 := nil;
  StrStream1 := nil;

  Statement := Connection.CreateStatement;
  Statement.SetResultSetType(rtScrollInsensitive);
  Statement.SetResultSetConcurrency(rcUpdatable);
  try
    Statement.Execute('DELETE FROM BLOB_VALUES');

    ResultSet := Statement.ExecuteQuery('SELECT * FROM BLOB_VALUES');
    with ResultSet do
    begin
      MoveToInsertRow;
      UpdateInt(1, TEST_ROW_ID);
      UpdateAsciiStream(2, StrStream);
      UpdateBinaryStream(3, BinStream);
      InsertRow;
      Close;
    end;

    ResultSet := Statement.ExecuteQuery('SELECT * FROM BLOB_VALUES');
    with ResultSet do
    begin
      CheckEquals(True, Next);
      StrStream1 := GetAsciiStream(2);
      BinStream1 := GetBinaryStream(3);
      Close;
    end;
    CheckEquals(BinStream, BinStream1, '512 bytes binary stream');
    CheckEquals(StrStream, StrStream1, '512 bytes string stream');

    BinStream1.Free;
    StrStream1.Free;
    BinStream.LoadFromFile('../../../database/images/dogs.jpg');
    BinStream.Size := 1024;
    StrStream.LoadFromFile('../../../database/text/lgpl.txt');
    StrStream.Size := 1024;

    ResultSet := Statement.ExecuteQuery('SELECT * FROM BLOB_VALUES');
    with ResultSet do
    begin
      Next;
      UpdateAsciiStream(2, StrStream);
      UpdateBinaryStream(3, BinStream);
      UpdateRow;
      Close;
    end;

    ResultSet := Statement.ExecuteQuery('SELECT * FROM BLOB_VALUES');
    with ResultSet do
    begin
      CheckEquals(True, Next);
      StrStream1 := GetAsciiStream(2);
      BinStream1 := GetBinaryStream(3);
      Close;
    end;
    CheckEquals(BinStream, BinStream1, '1024 bytes binary stream');
    CheckEquals(StrStream, StrStream1, '1024 bytes string stream');
    Statement.Close;
  finally
    BinStream.Free;
    StrStream.Free;
    if Assigned(BinStream1) then
      BinStream1.Free;
    if Assigned(StrStream1) then
      StrStream1.Free;
  end;
end;

{**
   Runs a test for bug report #865441
   ZeosLib reports Ex. numeric(3,1) as IntegerField
}
procedure TZTestDbcInterbaseBugReport.Test864622;
var
  Statement: IZStatement;
  ResultSet: IZResultSet;
begin
  if SkipForReason(srClosedBug) then Exit;

  Statement := Connection.CreateStatement;
  Statement.SetResultSetType(rtScrollInsensitive);
  Statement.SetResultSetConcurrency(rcUpdatable);

  ResultSet := Statement.ExecuteQuery('SELECT * FROM TABLE864622');
  with ResultSet do
  begin
    with GetMetadata do
    begin
      CheckEquals(ord(stInteger), Ord(GetColumnType(1)));
      CheckEquals(ord(stFloat), Ord(GetColumnType(2)));
    end;
    CheckEquals(True, Next);
    CheckEquals(1, GetInt(1));
    CheckEquals(1.2, GetFloat(2), 0.01);
    Close;
  end;
end;

{**
   Runs a test for bug report #865441
   Error -104 with Field named PASSWORD in Firebird
}
procedure TZTestDbcInterbaseBugReport.Test865441;
var
  Statement: IZStatement;
  ResultSet: IZResultSet;
begin
  if SkipForReason(srClosedBug) then Exit;

  Statement := Connection.CreateStatement;
  Statement.SetResultSetType(rtScrollInsensitive);
  Statement.SetResultSetConcurrency(rcUpdatable);

  Statement.Execute('DELETE FROM TABLE865441');

  ResultSet := Statement.ExecuteQuery('SELECT * FROM TABLE865441');
  with ResultSet do
  begin
    MoveToInsertRow;
    UpdateInt(1, TEST_ROW_ID);
    UpdateString(2, 'passwd');
    InsertRow;
    Close;
  end;

  ResultSet := Statement.ExecuteQuery('SELECT * FROM TABLE865441');
  with ResultSet do
  begin
    Next;
    CheckEquals(TEST_ROW_ID, GetInt(1));
    CheckEquals('passwd', GetString(2));
    Close;
  end;

  Statement.Close;
end;

{**
   Runs a test for bug report #886854
   Incorrect field type
}
procedure TZTestDbcInterbaseBugReport.Test886854;
var
  Statement: IZStatement;
  ResultSet: IZResultSet;
  Metadata: IZResultSetMetadata;
begin
  if SkipForReason(srClosedBug) then Exit;

  Statement := Connection.CreateStatement;
  Statement.SetResultSetType(rtScrollInsensitive);
  Statement.SetResultSetConcurrency(rcUpdatable);

  ResultSet := Statement.ExecuteQuery('select rc.rdb$relation_name as rel_name, ' +
    'rc.rdb$index_name as ind_name, rs.rdb$field_name as field_name, ' +
    'rs.rdb$field_position as field_pos from rdb$relation_constraints rc ' +
    'left join rdb$index_segments rs on rs.rdb$index_name=rc. '+
    'rdb$index_name where rs.rdb$field_name is not null and rs. '+
    'rdb$field_name<>''DEP_ID'' and '+
    'rc.rdb$constraint_type=''PRIMARY KEY'' and rc.rdb$relation_name=''PEOPLE'' ' +
    'order by rc.rdb$relation_name');
  Metadata := ResultSet.GetMetadata;
  with Metadata do
  begin
    CheckEquals(4, GetColumnCount);
    //Client_Character_set sets column-type!!!!
    if ( Connection.GetConSettings.CPType = cCP_UTF16 ) then
    begin
      CheckEquals(ord(stUnicodeString), ord(GetColumnType(1)));
      CheckEquals(ord(stUnicodeString), ord(GetColumnType(2)));
      CheckEquals(ord(stUnicodeString), ord(GetColumnType(3)));
    end
    else
    begin
      CheckEquals(ord(stString), ord(GetColumnType(1)));
      CheckEquals(ord(stString), ord(GetColumnType(2)));
      CheckEquals(ord(stString), ord(GetColumnType(3)));
    end;
    CheckEquals(ord(stShort), ord(GetColumnType(4)));
  end;

  with ResultSet do
  begin
    Next;
    CheckEquals('PEOPLE', GetString(1));
    CheckEquals(Copy('RDB$PRIMARY2598', 1, Length('RDB$PRIMARY')),
      Copy(GetString(2), 1, Length('RDB$PRIMARY')));
    CheckEquals('P_ID', GetString(3));
    CheckEquals(0, GetInt(4));
    Close;
  end;
end;

{**
  Problem store data in database with character set DOS850
}
procedure TZTestDbcInterbaseBugReport.Test886914;
var
  Statement: IZStatement;
  PreparedStatement: IZPreparedStatement;
  ResultSet: IZResultSet;
begin
  if SkipForReason(srClosedBug) then Exit;

  Statement := Connection.CreateStatement;
  Statement.SetResultSetType(rtScrollInsensitive);
  Statement.SetResultSetConcurrency(rcUpdatable);

  Statement.Execute('DELETE FROM TABLE886914');
  Statement.Execute('INSERT INTO TABLE886914 VALUES (1, ''xyz'', ''RU'')');

  PreparedStatement := Connection.PrepareStatement(
    'UPDATE TABLE886914 SET ID=?, DESCRIPTION=?, FLAG=? WHERE ID=?;');
  with PreparedStatement do
  begin
    SetInt(1, 2);
    SetString(2, '');
    SetString(3, '');
    SetInt(4, 1);
    ExecuteUpdatePrepared;
    Close;
  end;
  PreparedStatement := nil;

  ResultSet := Statement.ExecuteQuery('SELECT * FROM TABLE886914');
  with ResultSet do
  begin
    Next;
    CheckEquals(2, GetInt(1));
    CheckEquals('', GetString(2));
    CheckEquals('', GetString(3));
    Close;
  end;

  ResultSet := nil;
  Statement.Close;
  Statement := nil;
end;

procedure TZTestDbcInterbaseBugReport.Test934253;
var
  Metadata: IZDatabaseMetadata;
  ResultSet: IZResultSet;
begin
  if SkipForReason(srClosedBug) then Exit;

  Metadata := Connection.GetMetadata;

  ResultSet := Metadata.GetTables('', '', 'DEPARTMENT', nil);
  with ResultSet do begin
    Check(Next);
    CheckEquals('', GetString(1));
    CheckEquals('', GetString(2));
    CheckEquals('DEPARTMENT', GetString(3));
    CheckEquals('TABLE', GetString(4));
  end;
  ResultSet.Close;
  ResultSet := nil;

  ResultSet := Metadata.GetTables('', '', 'DEP_VIEW', nil);
  with ResultSet do begin
    Next;
    CheckEquals('', GetString(1));
    CheckEquals('', GetString(2));
    CheckEquals('DEP_VIEW', GetString(3));
    CheckEquals('VIEW', GetString(4));
  end;
  ResultSet.Close;
  ResultSet := nil;
end;

initialization
  RegisterTest('bugreport',TZTestDbcInterbaseBugReport.Suite);
end.
