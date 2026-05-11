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
              CnsrVar=, CnsrLst=, strata=, StrataN=, AttrMap=, PlotDs=PlotDs);

%local StraLabl pars npar par xLabl byLabl bys nby nCNSR haveMedian
       title MaxTm TmBy;

data _TmpDs;
  set &DsIn;
  %if %nrbquote(&whr) ne %then if &whr;;
  %if &by = %then %do;
      _BY_DUMMY = "Overall";
      %let by = _BY_DUMMY;
      %let bys = Overall;
      %let nby = 1;
  %end;
run;
proc sort; by &byN &by; run;

/* check existence of PARAM, extract variable-label of &strata */
%let dsid = %sysfunc(open(_TmpDs));
%let ParVn = %sysfunc(varnum(&dsid, PARAM));
%if &strata ne %then %let StraLabl=%sysfunc(varlabel(&dsid, %sysfunc(varnum(&dsid, &strata))));

data _null_;
  set _TmpDs(keep=%if &ParVn>0 %then PARAM; %else &time;);
  if _n_=1;
  %if &ParVn>0 %then %do;
    call symputx('par', strip(scan(PARAM, 1, '(')));
    call symputx('xLabl', catx(' ', 'Time', cats('(', scan(PARAM, 2, '('))));
  %end;
  %else %do;
    _PAR = vlabel(&time);
    call symputx('par', strip(scan(_PAR, 1, '(')));
    call symputx('xLabl', catx(' ', 'Time', cats('(', scan(_PAR, 2, '('))));
  %end;
run;

%let rc = %sysfunc(close(&dsid));

%if &by ne _BY_DUMMY %then %do;
  proc sort nodupkey data=_TmpDs(where=(^missing(&by))) out=_uBy;
    by &byN &by;
  run;
  proc sql noprint;
    select &by into :bys separated by '|' from _uBy;
    %let nby=&sqlobs;
  quit;
  data _null_; set _uBy; if _n_=1; call symputx('byLabl', vlabel(&by)); run;
%end;

/* extract time options (maximum time and by-step) from data */
%_process_interact_files(Loc=&InteractLoc, File=&TmOpt, Type=TmOpt, Data=_TmpDs)

/* readin GTL attribute map dataset from the interact location */
%if &strata ne and %bquote(&AttrMap) ne %then %do;
  %_process_interact_files(Loc=&InteractLoc, File=&AttrMap, Type=AttrMap, Data=_TmpDs)
%end;

%do i = 1 %to &nby;
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
    %if &by ne _BY_DUMMY %then where &by="&byval";;
    call symputx('MaxTm', MaxTm);
    call symputx('TmBy', TmBy);
  run;
  %let title=Kaplan-Meier Plot for &par %if &by ne _BY_DUMMY %then when &byLabl is &byval;;

  ods exclude all;
  proc lifetest data=_SubDs plots=survival(atrisk(atrisktickonly)=0 to &MaxTm by &TmBy);
    %if &strata ne %then strata &strataN &strata;;
    time &time * &CnsrVar(&CnsrLst);
    ods output Quartiles=_Quartiles survivalplot=_SurvPlot0 %if &strata ne %then HomTests=_HomTests;;
  quit;
  ods exclude none;

  %_prepare_plot_data()

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

proc datasets memtype=data nolist; delete _:; quit;

%mend KMPlot;
