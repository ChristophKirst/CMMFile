(* ::Package:: *)

(* Author:
   Christoph Kirst
   06.2010
   Max Planck Institute for Dynamics and Self-Organization, Goettingen, Germany
   ckirst@nld.ds.mpg.de

   package to import and export binary data for use with c++ code via cmmfile.h

*)

BeginPackage["CMMFile`"]

CMMFile::error = "`1`";

$CMMFilePrintInfo::usage = "True for printing infos when writing data";

OpenReadCMMFile::usage = "OpenReadCMM[filename_] opens a cmm file for reading, returns an InputStream.";

OpenWriteCMMFile::usage = "OpenWriteCMM[filename_] opens a cmm file for writing, returns an OutputStream.";

CloseCMMFile::usage = "CloseCMM[str_] closes cmm file str.";


ReadCMMFile::usage = "ReadCMMFile[filename_] reads sequence of data entries in binary file filename.";

ReadCMM::usage = "ReadCMM[str_InputStream] reads one data entry in str and returns it or EndOfFile.";

ReadCMMType::usage = "ReadCMMType[str_InputStream] reads type form str.";

ReadCMMDim::usage = "ReadCMMDim[str_InputStream] reads dimension form str.";

ReadCMMSize::usage = "ReadCMMSize[str_InputStream] reads single dimension size form str.";

ReadCMMHeader::usage = "ReadCMMHeader[str_InputStream] reads type and size form str, returns {type, size}";

ReadCMMData::usage = "ReadCMMData[str_InputStream, t_, s_] reads data of type t and size s.";


WriteCMMFile::usage = "WriteCMMFile[filename_, data_List] writes sequence of entries in data to binary file filename.";

WriteCMM::usage = "WriteCMM[str_OutputStream, data_] writes single data entry to binary file str inlcuding headers.";

WriteCMMType::usage = "WriteCMMType[str_OutputStream, t_] writes type t to str.";

WriteCMMDim::usage = "WriteCMMDim[str_OutputStream, s_] writes dimension s to str.";

WriteCMMSize::usage = "WriteCMMSize[str_OutputStream, s_] writes single dimension size s to str.";

WriteCMMHeader::usage = "WriteCMMHeader[str_OutputStream, t_, s_] writes header for type t and dimension s to binary file str.";

WriteCMMData::usage = "WriteCMMData[str_OutputStream, data_] writes data to binary file str without headers.";

CMMType::usage = "CMMType[data_] returns CMMType of data.";

FromCMMType::usage = "FromCMMType[t_] returns Mathematica format of CMMType t.";

(*ToCMMType::usage = "ToCMMType[f_] returns CMMType of Mathematica format f.";*)

CMMDim::usage = "CMMDim[data_] returns CMMDim of data.";

SizeOfCMMType::usage = "SizeOfCMMType[t_] returns size in bytes of cmm type t.";


(* data sequences *)
ReadCMMSequence::usage = "ReadCMMSequence[str_InputStream] reads a sequence of data types.";

ReadCMMHeaderSequence::usage = "ReadCMMHeaderSequence[str_InputStream] reads a sequence of headers.";

ReadCMMDataSequence::usage = "ReadCMMDataSequence[str_InputStream, hs_] reads a sequence of data given by header sequence hs.\n" <> 
                             "ReadCMMDataSequence[str_InputStream, t_, s_] reads a single data entry in a sequence of type t and dim s";

WriteCMMHeaderSequence::usage = "WriteCMMHeaderSequence[str_OutputStream, hs_] writes a sequence of headers.";

WriteCMMStartSequence::usage = "WriteCMMStartSequence[str_OutputStream] writes start of sequence marker.";

WriteCMMEndSequence::usage = "WriteCMMEndSequence[str_OutputStream] writes end of sequence marker.";

WriteCMMDataSequence::usage= "WriteCMMDataSequence[str_OutputStream, dat_] writes a single entry of data dat into a data sequence.";

IncreaseActualHeader::usage = "IncreaseActualHeader[] increases the actual header in the header sequence.";



(* define datatypes *)
TypeREAL = "Real64";
TypeINTG = "Integer32";
TypeLONG = "Integer64";
TypeULNG = "UnsignedInteger64";
TypeTEXT = "TerminatedString";
TypeBOOL = "Character8";

(* data type headers *)
CMMREAL = "R";
CMMINTG = "I";
CMMLONG = "L"; 
CMMULNG = "U";
CMMTEXT = "T";
CMMBOOL = "B";

CMMBOOLTrue = "t";
CMMBOOLFalse = "f";

CMMSEQS = "S";
CMMSEQE = "E";

Begin["`Private`"]

$CMMFilePrintInfo = False;
$CMMFileHeaderSequence = {};
$CMMFileActualHeader = 0;

(*
ToCMMType[f_]:=(Message[CMMFile::error, "No CMMType for format: " <> ToString[f]]; "");
ToCMMType[TypeREAL] := CMMREAL;
ToCMMType[TypeINTG] := CMMINTG;
ToCMMType[TypeLONG] := CMMLONG;
ToCMMType[TypeULNG] := CMMULNG;
ToCMMType[TypeTEXT] := CMMTEXT;
ToCMMType[TypeBOOL] := CMMBOOL;
*)

FromCMMType[t_]:=(Message[CMMFile::error, "No format for CMMType: " <> ToString[t]] "");
FromCMMType[CMMREAL] := TypeREAL;
FromCMMType[CMMINTG] := TypeINTG;
FromCMMType[CMMLONG] := TypeLONG;
FromCMMType[CMMULNG] := TypeULNG;
FromCMMType[CMMTEXT] := TypeTEXT;
FromCMMType[CMMBOOL] := TypeBOOL;

CMMType[data_]:=(Message[CMMFile::error, "No CMMType for data."]; "");

CMMType[data_Integer]     := CMMINTG;
CMMType[data_?NumericQ]   := CMMREAL;
CMMType[data_String]      := CMMTEXT;
CMMType[data:(True|False)]:= CMMBOOL;

CMMType[data_?(ArrayQ[#, _, IntegerQ]&)]:=CMMINTG;
CMMType[data_?(ArrayQ[#, _, NumericQ]&)]:=CMMREAL;
CMMType[data_?(ArrayQ[#, _, StringQ]&)] :=CMMTEXT;
CMMType[data_?(ArrayQ[#, _, MatchQ[#, True|False]&] &)] := CMMBOOL;

CMMDim[data_]:=(Message[CMMFile::error, "No CMMDim for data."]; Indeterminate);
CMMDim[data_?AtomQ]  := {};
CMMDim[data_?ArrayQ] :=Dimensions[data];

SizeOfCMMType[CMMREAL] := 8;
SizeOfCMMType[CMMINTG] := 4;
SizeOfCMMType[CMMLONG] := 8;
SizeOfCMMType[CMMULNG] := 8;
SizeOfCMMType[CMMTEXT] := 1;
SizeOfCMMType[CMMBOOL] := 1;

SizeOf[TypeREAL] = 8;
SizeOf[TypeINTG] = 4;
SizeOf[TypeLONG] = 8;
SizeOf[TypeULNG] = 8;
SizeOf[TypeTEXT] = 1;
SizeOf[TypeBOOL] = 1;

TypeTYPE  = "Character8";
TypeDIM   = "Integer32";
TypeSIZE  = "Integer32";

FromCMMBool[CMMBOOLTrue] = True;
FromCMMBool[CMMBOOLFalse]= False;
ToCMMBool[True] = CMMBOOLTrue;
ToCMMBool[False]= CMMBOOLFalse;


OpenReadCMMFile[filename_]:= OpenRead[filename, BinaryFormat->True];

OpenWriteCMMFile[filename_]:= OpenWrite[filename, BinaryFormat->True];

CloseCMMFile[str_]:=Close[str];


ReadCMMType[str_InputStream]:=BinaryRead[str, TypeTYPE];

ReadCMMDim[str_InputStream]:=Module[{d}, 
   (* read dimension *)
   d = BinaryRead[str, TypeDIM];
   If[d===EndOfFile, Return[EndOfFile]];
   (*If[d<0, Return[{d}]];*)
   If[d==0, Return[{}]];
   (* read sizes of dimensions *)
   BinaryReadList[str, TypeSIZE, d]
];

ReadCMMSize[str_InputStream]:=Module[{}, 
   BinaryRead[str, TypeSIZE]
];


ReadCMMHeader[str_InputStream]:={ReadCMMType[str], ReadCMMDim[str]};

ReadCMMData[str_InputStream, t_]:=ReadCMMdata[str, t, {}];
ReadCMMData[str_InputStream, {t_, s_}]:=ReadCMMData[str, t, s];
ReadCMMData[str_InputStream, t_, s_]:=Module[{l = Length[s]},
   (* read data *)
   If[l==0, Return[BinaryRead[str, FromCMMType[t]]]];
   If[s[[1]] == -1,
      dat = BinaryReadList[str, FromCMMType[t]];
   ,
      dat = BinaryReadList[str, FromCMMType[t], Times @@ s];
   ];

   (* resize data *)
   If[l==1, Return[dat]];
   Fold[Partition, dat, Reverse[Drop[s,1]]]
];

ReadCMMData[str_InputStream, CMMBOOL, s_]:=Module[{l = Length[s]},
   (* read data *)
   If[l==0, Return[FromCMMBool[BinaryRead[str, FromCMMType[CMMBOOL]]]]];
   If[s[[1]] == -1,
      dat = BinaryReadList[str, FromCMMType[CMMBOOL]];
   ,
      dat = BinaryReadList[str, FromCMMType[CMMBOOL], Times @@ s];
   ];

   (* change to True / False values *)
   dat = FromCMMBool /@ dat;

   (* resize data *)
   If[l==1, Return[dat]];
   Fold[Partition, dat, Reverse[Drop[s,1]]]
];



ReadCMMData[str_InputStream, t_, s_, ns_]:=ReadCMMData[str, t, s, 1, ns];
ReadCMMData[str_InputStream, t_, s_, nr_, ns_]:=Module[{(*ss = s,*) l = Length[s], p, n},
   (* read data *)
   If[l==0, Return[BinaryRead[str, FromCMMType[t]]]];
   If[s[[1]] == -1,
      p = Times @@ Drop[s,1];
      dat = BinaryReadListSkip[str, FromCMMType[t], nr*p, ns*p, Infinity];
   ,
      p = Times @@ Drop[s,1];
      n = Floor[s[[1]]/(nr+ns)] + If[Mod[s[[1]],nr+ns]>=nr,1,0];
      dat = BinaryReadListSkip[str, FromCMMType[t], nr*p, ns*p, n];
   ];

   (* resize data *)
   If[l==1, Return[dat]];
   (*ss[[1]] = Length[dat] / Times[Drop[s,1]];*)
   Fold[Partition, dat, Reverse[Drop[s,1]]]
];

ReadCMMData[str_InputStream, CMMBOOL, s_, nr_, ns_]:=Module[{(*ss = s,*) l = Length[s], p, n},
   (* read data *)
   If[l==0, Return[FromCMMBool[BinaryRead[str, FromCMMType[CMMBOOL]]]]];
   If[s[[1]] == -1,
      p = Times @@ Drop[s,1];
      dat = BinaryReadListSkip[str, FromCMMType[CMMBOOL], nr*p, ns*p, Infinity];
   ,
      p = Times @@ Drop[s,1];
      n = Floor[s[[1]]/(nr+ns)] + If[Mod[s[[1]],nr+ns]>=nr,1,0];
      dat = BinaryReadListSkip[str, FromCMMType[CMMBOOL], nr*p, ns*p, n];
   ];


   (* change to True / False values *)
   dat = FromCMMBool /@ dat;

   (* resize data *)
   If[l==1, Return[dat]];
   (*ss[[1]] = Length[dat] / Times[Drop[s,1]];*)
   Fold[Partition, dat, Reverse[Drop[s,1]]]
];



ReadCMM[str_InputStream, ns_Integer]:=ReadCMM[str, 1, ns];
ReadCMM[str_InputStream, nr_Integer, ns_Integer]:=Module[{t, s},
   (* read header *)
   t = ReadCMMType[str];
   If[t===EndOfFile, Return[EndOfFile]];

   (* read size *)
   s = ReadCMMDim[str];
   If[MemberQ[Flatten[{s}], EndOfFile],
      Message[CMMFile::error, "File error while reading dimension and size!"];
      Return[$Failed]
   ];

   ReadCMMData[str, t, s, nr, ns]
];

ReadCMM[str_InputStream]:=Module[{t, s},
   (* read header *)
   t = ReadCMMType[str];
   If[t===EndOfFile, Return[EndOfFile]];
   If[t==CMMSEQS, SetStreamPosition[str, StreamPosition[str]-1]; Return[ReadCMMSequence[str]]];

   (* read size *)
   s = ReadCMMDim[str];
   If[MemberQ[Flatten[{s}], EndOfFile],
      Message[CMMFile::error, "File error while reading dimension and size!"];
      Return[$Failed]
   ];

   ReadCMMData[str, t, s]
];


ReadCMMFile[filename_String]:=Module[{str = OpenReadCMMFile[filename], data},
   data = ReadCMMFile[str];
   Close[str];
   data
];

ReadCMMFile[str_InputStream]:=Module[{data = {}, dat = ReadCMM[str]},
   While[dat =!= EndOfFile && dat =!= $Failed,
      data = Append[data, dat];
      dat = ReadCMM[str];
   ];
   data
];


WriteCMMType[str_OutputStream, t_]:=BinaryWrite[str, t , TypeTYPE];

WriteCMMDim[str_OutputStream, s_]:=Module[{},
   (* write dimension *)
   BinaryWrite[str, Length[s], TypeDIM];

   (* write size *)
   BinaryWrite[str, s, TypeSIZE];
];

WriteCMMSize[str_OutputStream, s_]:=Module[{},
   (* write size *)
   BinaryWrite[str, s, TypeSIZE];
];


WriteCMMHeader[str_OutputStream, t_]:=WriteCMMHeader[str, t, {}];
WriteCMMHeader[str_OutputStream, {t_, s_}]:=WriteCMMHeader[str, t, s];
WriteCMMHeader[str_OutputStream, t_, s_]:=Module[{},
   If[$CMMFilePrintInfo, Print["writing header: ", t, " ", s]];
   (* write type *)
   WriteCMMType[str, t];
   (* write dimension and size *)
   WriteCMMDim[str, s]
];

WriteCMMData[str_OutputStream, data_]:=Module[{type},
   type = CMMType[data]; If[type=="", Abort[]];
   WriteCMMData[str, data, type]
];
WriteCMMData[str_OutputStream, data_, type_]  :=BinaryWrite[str, Flatten[{data}], FromCMMType[type]];
WriteCMMData[str_OutputStream, data_, CMMBOOL]:=BinaryWrite[str, ToCMMBool /@ Flatten[{data}], FromCMMType[CMMBOOL]];

WriteCMM[str_OutputStream, data_]:=Module[{s,t},
   s = CMMDim[data]; If[s===Indeterminate, Abort[]];
   t = CMMType[data]; If[t=="", Abort[]];
   WriteCMMHeader[str, t, s];
   WriteCMMData[str, data, t];
];

WriteCMMFile[filename_String, data_List]:=Module[{str = OpenWriteCMMFile[filename]},
   WriteCMMFile[str, data];
   Close[str];
   filename
];

WriteCMMFile[str_OutputStream, data_List]:=WriteCMM[str, #]& /@ data;



(* Sequences of Data *)

ReadCMMSequence[str_InputStream]:=Module[{hs},
   hs = ReadCMMHeaderSequence[str];
   ReadCMMDataSequence[str, hs]
];

(* returns list {{type, dim},...} of headers *)
ReadCMMHeaderSequence[str_InputStream]:=Module[{t,s,hs},
   t = ReadCMMType[str];
   If[t!=CMMSEQS, Message[CMMFile::error, "Error while reading header sequence!"]; Abort[]];
   (* read the data type headers *)
   t = ReadCMMType[str];
   hs = {};
   While[t != CMMSEQE && t =!= EndOfFile,
      s = ReadCMMDim[str];
      hs = Append[hs,{t,s}];
      t = ReadCMMType[str];
   ];
   If[t!=CMMSEQE, Message[CMMFile::error, "Error while reading header sequence!"]; Abort[]];

   hs
];

ReadCMMDataSequence[str_InputStream, hs_]:=Module[{dat, data = {}, pos, end},
   pos = StreamPosition[str];
   SetStreamPosition[str, Infinity];
   end = StreamPosition[str];
   SetStreamPosition[str, pos];

   While[StreamPosition[str] < end, 
      dat = ReadCMMDataSequence[str, #[[1]], #[[2]]] & /@ hs;
      data = Append[data,dat];
   ];

   Transpose[data]
];


ReadCMMDataSequence[str_InputStream, t_, s_]:=Module[{l = Length[s], ss = s},
   (* read data *)
   If[l==0, Return[BinaryRead[str, FromCMMType[t]]]];
   If[s[[1]] == -1, ss[[1]] = ReadCMMSize[str]];

   dat = BinaryReadList[str, FromCMMType[t], Times @@ ss];

   (* resize data *)
   If[l==1, Return[dat]];
   Fold[Partition, dat, Reverse[Drop[ss,1]]]
];

ReadCMMDataSequence[str_InputStream, CMMBOOL, s_]:=Module[{l = Length[s], ss = s},
   (* read data *)
   If[l==0, Return[FromCMMBool[BinaryRead[str, FromCMMType[t]]]]];
   If[s[[1]] == -1, ss[[1]] = ReadCMMSize[str]];
   dat = BinaryReadList[str, FromCMMType[t], Times @@ ss];
   dat = FromCMMBool /@ dat;
   (* resize data *)
   If[l==1, Return[dat]];
   Fold[Partition, dat, Reverse[Drop[ss,1]]]
];



WriteCMMHeaderSequence[str_OutputStream, hs_]:=Module[{},
   WriteCMMStartSequence[str];
   WriteCMMHeader[str, #]& /@ hs;
   WriteCMMEndSequence[str];

   $CMMFileHeaderSequence = hs;
   $CMMFileActualHeader = 1;
];

WriteCMMStartSequence[str_OutputStream]:=WriteCMMType[str, CMMSEQS];

WriteCMMEndSequence[str_OutputStream]:=WriteCMMType[str, CMMSEQE];

WriteCMMDataSequence[str_OutputStream, dat_]:=Module[{s, t},
   t = $CMMFileHeaderSequence[[$CMMFileActualHeader,1]];

   If[CMMType[dat] != t, 
      Message[CMMFile::error, "Error while writing data of sequence: type mismatch!"]; Abort[]
   ];

   s = $CMMFileHeaderSequence[[$CMMFileActualHeader,2]];
   If[Length[s]>0 && s[[1]] == -1, s[[1]] = Length[dat]; WriteCMMSize[str, s[[1]]]];

   If[CMMDim[dat] != s,
      Message[CMMFile::error, "Error while writing data of sequence: dimension mismatch!"]; Abort[]
   ];

   WriteCMMData[str, dat, t];

   IncreaseActualHeader[];
];

IncreaseActualHeader[] := Module[{l = Length[$CMMFileHeaderSequence]},
   $CMMFileActualHeader = Mod[$CMMFileActualHeader, l] + 1;
];





(* binary skip + reading *)

BinaryReadListSkip[str_InputStream, type_, nr_, ns_]:=Module[{dat},
   dat = BinaryReadList[str, type, nr];
   Skip[str, Character, SizeOf[type] * ns];
   dat
];

BinaryReadListSkip[str_InputStream, TypeTEXT, nr_, ns_]:=Module[{dat},
   dat = BinaryReadList[str, TypeTEXT, nr];
   BinaryReadList[str, TypeTEXT, ns];
   dat
];

BinaryReadListSkip[str_InputStream, type_, nr_, ns_, n_Integer]:=
   Flatten[Table[BinaryReadListSkip[str, type, nr, ns], {n}]]

BinaryReadListSkip[str_InputStream, type_, nr_, ns_, Infinity]:=Module[{pos = StreamPosition[str], s, n},
   SetStreamPosition[str, Infinity];
   s = Floor[(StreamPosition[str] - pos)/SizeOf[type]];
   n = Floor[s/(nr+ns)] + If[Mod[s,nr+ns]>=nr,1,0];
   SetStreamPosition[str, pos];
   Flatten[Table[BinaryReadListSkip[str, type, nr, ns], {n}]]
];

BinaryReadListSkip[str_InputStream, TypeTEXT, nr_, ns_, Infinity]:=Module[{dat = {{1}}},
   While[dat[[-1]] != {},
      dat = {dat, BinaryReadListSkip[str, TypeTEXT, nr, ns]};
   ];
   DeleteCases[Drop[Flatten[dat],1], EndOfFile]
];








End[] 

EndPackage[]
