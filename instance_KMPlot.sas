/*=============================================================================
                            Environment Information
-------------------------------------------------------------------------------
 SAS Version            : 9.4 under Windows 10
-------------------------------------------------------------------------------
                            Purpose
-------------------------------------------------------------------------------
Call the compiled template(Graphics.KM) to draw Kaplan-Meier (survival) plot.
-------------------------------------------------------------------------------
                            Special Parameter Description
-------------------------------------------------------------------------------
by, could be any category variable if PARAM non-exist or contains only one
    value level, otherwise when PARAM contains multiple value level the by
    should only be assigned with PARAM
InteractLoc, a PC location that use to store the interaction EXCEL-file(s)
TmOpt, interaction file that use to assign the time-increament and maximum for
       tick on x-axis
AttrMap, interaction file of attribute map data that use to assign the LineColor,
         MarkerColor and TextColor for stratas
-------------------------------------------------------------------------------
                            Example Macro Call
-------------------------------------------------------------------------------
data bmt;
  set sashelp.bmt;
  SUBJID=put(_n_, z3.);
  PARAM='Disease-Free Survival (Days)';
  call streaminit(12345);
  SEX=ifc(rand('uniform')<.5, 'Male', 'Female');
  WEIGHT=round(rand('normal', 70, 10), .1);
  label SUBJID='Subject'
        PARAM='Parameter'
        SEX='Sex'
        WEIGHT='Weight (kg)'
        ;
run;
%KMPlot(DsIn=bmt, time=T, InteractLoc=D:\tst\Graphics, TmOpt=TmOpt.xlsx,
        CnsrVar=Status, CnsrLst=0, strata=Group, AttrMap=GrpAttrMap.xlsx)
%KMPlot(DsIn=bmt, by=SEX, CnsrVar=Status, CnsrLst=0,
        time=T, InteractLoc=D:\tst\Graphics, TmOpt=TmOpt.xlsx)
%KMPlot(DsIn=bmt, by=PARAM, CnsrVar=Status, CnsrLst=0,
        time=T, InteractLoc=D:\tst\Graphics, TmOpt=TmOpt.xlsx)
        time=T, InteractLoc=D:\tst\Graphics, TmOpt=TmOpt_SEX.xlsx)
-------------------------------------------------------------------------------
                            Programmer Information
-------------------------------------------------------------------------------
 Author                 : Houhui Hu                                Copyright(c)
 Creation Date          : 06-09 DEC2023
-------------------------------------------------------------------------------
                            Change Control Information
-------------------------------------------------------------------------------
 Modifications:
 Programmer/Date:       Reason:
 ----------------       -----------------------------------------------------
-------------------------------------------------------------------------------
                            Future
-------------------------------------------------------------------------------
 known issue: all median not reach, warning shown
==============================================================================*/

%macro KMPlot(DsIn=, whr=, by=, byN=, time=, InteractLoc=, TmOpt=,
              CnsrVar=, CnsrLst=, strata=, StrataN=, AttrMap=, PlotDs=);

%local StraLabl pars npar par xLabl byLabl bys nby nCNSR haveMedian
       title MaxTm TmBy;

data _TmpDs;
  set &DsIn;
  %if %nrbquote(&whr) ne %then if &whr;;
run;
%if &by ne %then %do;
  proc sort; by &byN &by; run;
%end;

/* check existence of PARAM, extract variable-label of &strata */
%let dsid = %sysfunc(open(_TmpDs));
  %let ParVn = %sysfunc(varnum(&dsid, PARAM));
  %if &strata ne %then
  %let StraLabl=%sysfunc(varlabel(&dsid, %sysfunc(varnum(&dsid, &strata))));
%let rc = %sysfunc(close(&dsid));

%if &ParVn>0 %then %do;
  proc sql noprint;
    select distinct PARAM into: pars separated by '|' from _TmpDs;
    %let npar=&sqlobs;
  quit;
  %if &npar=1 %then %do;
    data _null_;
      set _TmpDs;
      if _n_=1;
      call symputx('par', strip(scan(PARAM, 1, '(')));
      call symputx('xLabl', catx(' ', 'Time', cats('(', scan(PARAM, 2, '('))));
      %if &by ne and &by ne PARAM %then call symputx('byLabl', vlabel(&by));;
    run;
  %end;
  %else %if &npar>1 and &by ne PARAM %then %do; /* including &by= */
    %put WARNING: there are multiple parameters, the draw object may not clarify.;
    %goto EOC;
    /* so when PARAM existed, unless by is PARAM, levels of PARAM must be 1 */
  %end;
  %if &by=PARAM %then %do;
    %let bys=&pars;
    %let nby=&npar;
  %end;
%end;
%else %do;
  data _null_;
    set _TmpDs(keep=&time);
    if _n_=1;
    _PAR=vlabel(&time);
    call symputx('par', strip(scan(_PAR, 1, '(')));
    call symputx('xLabl', catx(' ', 'Time', cats('(', scan(_PAR, 2, '('))));
  run;
%end;

%if &by ne and &by ne PARAM %then %do;
  proc sort nodupkey data=_TmpDs(where=(^missing(&by)))
                     out=_uBy(keep=&byN &by);
    by &byN &by;
  run;
  proc sql noprint;
    select &by into :bys separated by '|' from _uBy;
    %let nby=&sqlobs;
  quit;
  data _null_;
    set _uBy;
    if _n_=1;
    call symputx('byLabl', vlabel(&by));
  run;
%end;

/* extract time option (maximum time) from data, we think only when PARAM */
/* NOT exist and by exist, or by is the PARAM may have different time attributes */
/* while different by-group within one parameter should have same time attributes */
proc means data=_TmpDs nway noprint;
  %if (&ParVn=0 and &by ne ) or (&by=PARAM and &npar>1) %then class &byN &by;;
  var &time;
  output out=MaxTm(drop=_:) max=MaxTm;
run;
data _TmOpt;
  set MaxTm;
  %if &npar=1 %then PARAM="&pars";; /* explicit the parameter for consideration */
  call missing(TmBy);
  label MaxTm=' '
        %if (&ParVn=0 and &by ne ) or (&by=PARAM and &npar>1) %then %do;
          &by=' ' %if &byN ne %then &byN=' ';
        %end;
        ;
run;
%if %bquote(&TmOpt)= %then %let TmOpt=TmOpt;;
options missing=' ';
%if %sysfunc(fileexist("&InteractLoc\&TmOpt"))=0 %then %do;
  ods excel file="&InteractLoc\&TmOpt"
            options(flow='table' sheet_name='TmOpt');
    proc report data=_TmOpt nowd style=[textalign=left]; run;
  ods excel close;
%end;
/* set appropriate values to the extractions accordingly, readin for later using */
proc import out=TmOpt datafile="&InteractLoc\&TmOpt" dbms=excel replace;
            range='TmOpt$';
            getnames=yes;
            mixed=yes;
            textsize=32767;
run;
/* check if the values assigned (if not, warning and goto EOC) */
data _null_;
  set TmOpt;
  if _n_=1 then call symputx('chk', TmBy);
run;
%if &chk= %then %do;
  %put WARNING: Appropriate values should be set at &InteractLoc\&TmOpt.;
  %goto EOC;
%end;

/* readin GTL attribute map dataset from the interact location */
%if &strata ne and %bquote(&AttrMap) ne %then %do;
  proc sort nodupkey data=_TmpDs(where=(^missing(&strata)))
                     out=_AttrMap(keep=&strataN &strata);
    by &strataN &strata;
  run;
  data _AttrMap;
    set _AttrMap;
    ID="&strata";
    Value=&strata;
    call missing(LineColor, MarkerColor, TextColor);
    Show='AttrMap';
  run;
  %if %sysfunc(fileexist("&InteractLoc\&AttrMap"))=0 %then %do;
    ods excel file="&InteractLoc\&AttrMap"
              options(flow='table' sheet_name='AttrMap');
      proc report data=_AttrMap nowd style=[textalign=left]; run;
    ods excel close;
  %end;
  proc import out=AttrMap datafile="&InteractLoc\&AttrMap" dbms=excel replace;
              range='AttrMap$';
              getnames=yes;
              mixed=yes;
              textsize=32767;
  run;
  data _null_;
    set AttrMap;
    if _n_=1;
    call symputx('chk1', LineColor);
  run;
  %if &chk1= %then %do;
    %put WARNING: An interaction with &InteractLoc\&AttrMap should be done,
                  after customizing attributes, re-call this macro;
  %end;
%end;

%if &PlotDs= %then %let PlotDs=PlotDs;;

%if &by ne %then %do i = 1 %to &nby;
  %let byval = %scan(&bys, &i, |);
  data _SubDs;
    set _TmpDs end=final;
    where &by="&byval";
    retain nCNSR 0;
    if &CnsrVar in (&CnsrLst) then nCNSR+1;
    if final then call symputx('nCNSR', nCNSR);
  run;
  data _null_;
    set TmOpt;
    %if (&ParVn=0 and &by ne ) or (&by=PARAM and &npar>1)
    %then where &by="&byval";;
    call symputx('MaxTm', MaxTm);
    call symputx('TmBy', TmBy);
    %if &by=PARAM %then %do;
      call symputx('par', strip(scan(PARAM, 1, '(')));
      call symputx('xLabl', catx(' ', 'Time', cats('(', scan(PARAM, 2, '('))));
    %end;
  run;
  %if &by=PARAM %then %let title=Kaplan-Meier Plot for &par;
  %else %let title=Kaplan-Meier Plot for &par when &byLabl is &byval;;

  ods exclude all;
  ods graphics on;
  ods output Quartiles=_Quartiles
             survivalplot=_SurvPlot0
             %if &strata ne %then HomTests=_HomTests;
             ;
  proc lifetest data=_SubDs
                plots=survival(atrisk(atrisktickonly)=0 to &MaxTm by &TmBy);
    %if &strata ne %then strata &strataN &strata;
    ;
    time &time * &CnsrVar(&CnsrLst);
    ods select Quartiles survivalplot %if &strata ne %then HomTests;;
  quit;
  data _SurvPlot;
    set _SurvPlot0;
    %if &strataN ne %then %do;
      &strata=strip(scan(scan(Stratum, 2, ':'), -1, '='));
      &strataN=StratumNum;
    %end;
    %else %if &strata ne %then %do;
      &strata=Stratum;
      if find(&strata, ':') then &strata=strip(scan(&strata, 2, ':'));
    %end;
    label &strata="&StraLabl";
    drop Stratum StratumNum;
  run;
  data _median(keep=&strataN &strata median prob);
    set _Quartiles;
    where Percent=50 & ^missing(Estimate);
    median=Estimate;
    prob=.5;
  run;
  %let dsid = %sysfunc(open(_median));
    %let haveMedian=%sysfunc(attrn(&dsid, nobs));
  %let rc = %sysfunc(close(&dsid));
  %if &strata ne %then %do;
    data _null_;
      set _HomTests;
      if _n_=1 then call symputx('LogRnkP', put(ProbChiSq, pvalue.));
    run;
  %end;
  data _by_&i;
    length &by $ 60;
    merge _SurvPlot _median;
    %if &strata ne %then %do;
      by &strataN &strata;
      if ^first.&strata then call missing(median, prob);
    %end;
    %else %do;
      if _n_ ne 1 then call missing(median, prob);
    %end;
    &by="&byval";
  run;

  ods exclude none;
  ods graphics /noborder width=25.8cm height=14cm;
  proc sgrender data=_by_&i template=Graphics.KM
                %if %bquote(&AttrMap) ne %then dattrmap=AttrMap;
                ;
    dynamic _by="&by" _Time="Time" _SurvProb="Survival"
            _tAtRisk="tAtRisk" _AtRisk="AtRisk"
            %if &nCNSR>0 %then _Censor="Censored";
            %if &haveMedian>0 %then _median="median" _prob="prob";
            %if &strata ne %then _strata="&strata";
            ;
    %if %bquote(&AttrMap) ne %then dattrvar &strata="&strata";
    ;
  run;
  %if &i=1 %then %do;
    data &PlotDs; set _by_1; run;
  %end;
  %else %do;
    proc append base=&PlotDs data=_by_&i; run;
  %end;
%end;
%else %do;
  %let title=Kaplan-Meier Plot for &par;
  data _null_;
    set _TmpDs end=final;
    retain nCNSR 0;
    if &CnsrVar in (&CnsrLst) then nCNSR+1;
    if final then call symputx('nCNSR', nCNSR);
  run;
  data _null_;
    set TmOpt;
    call symputx('MaxTm', MaxTm);
    call symputx('TmBy', TmBy);
  run;

  ods exclude all;
  ods graphics on;
  ods output Quartiles=_Quartiles
             survivalplot=_SurvPlot0
             %if &strata ne %then HomTests=_HomTests;
             ;
  proc lifetest data=_TmpDs
                plots=survival(atrisk(atrisktickonly)=0 to &MaxTm by &TmBy);
    %if &strata ne %then strata &strataN &strata;
    ;
    time &time * &CnsrVar(&CnsrLst);
    ods select Quartiles survivalplot %if &strata ne %then HomTests;;
  quit;
  data _SurvPlot;
    set _SurvPlot0;
    %if &strataN ne %then %do;
      &strata=strip(scan(scan(Stratum, 2, ':'), -1, '='));
      &strataN=StratumNum;
    %end;
    %else %if &strata ne %then %do;
      &strata=Stratum;
      if find(&strata, ':') then &strata=strip(scan(&strata, 2, ':'));
    %end;
    label &strata="&StraLabl";
    drop Stratum StratumNum;
  run;
  data _median(keep=&strataN &strata median prob);
    set _Quartiles;
    where Percent=50 & ^missing(Estimate);
    median=Estimate;
    prob=.5;
  run;
  %let dsid = %sysfunc(open(_median));
    %let haveMedian=%sysfunc(attrn(&dsid, nobs));
  %let rc = %sysfunc(close(&dsid));
  %if &strata ne %then %do;
    data _null_;
      set _HomTests;
      if _n_=1 then call symputx('LogRnkP', put(ProbChiSq, pvalue.));
    run;
  %end;
  data &PlotDs;
    merge _SurvPlot _median;
    %if &strata ne %then %do;
      by &strataN &strata;
      if ^first.&strata then call missing(median, prob);
    %end;
    %else %do;
      if _n_ ne 1 then call missing(median, prob);
    %end;
  run;

  ods exclude none;
  ods graphics /noborder width=25.8cm height=14cm;
  proc sgrender data=&PlotDs template=Graphics.KM
                %if %bquote(&AttrMap) ne %then dattrmap=AttrMap;
                ;
    dynamic _Time="Time" _SurvProb="Survival"
            _tAtRisk="tAtRisk" _AtRisk="AtRisk"
            %if &nCNSR>0 %then _Censor="Censored";
            %if &haveMedian>0 %then _median="median" _prob="prob";
            %if &strata ne %then _strata="&strata";
            ;
    %if %bquote(&AttrMap) ne %then dattrvar &strata="&strata";
    ;
  run;
%end;

ods exclude none;

proc datasets memtype=data nolist; delete _:; quit;
%EOC:

%mend KMPlot;
