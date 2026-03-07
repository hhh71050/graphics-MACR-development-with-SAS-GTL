/*=============================================================================
                            Environment Information
-------------------------------------------------------------------------------
 SAS Version            : 9.4 under Windows 10
-------------------------------------------------------------------------------
                            Purpose
-------------------------------------------------------------------------------
 Define Kaplan-Meier(survival) Plot template with SAS GTL.
-------------------------------------------------------------------------------
                            GTL dynamic or mvar Description
-------------------------------------------------------------------------------
 _by, by group
 title/footer, text of entrytitle/entryfootnotes
 StraLabl, the text for sidebar-legend title, extract from the label of strata
 LogRnkP, used to entry Log Rank p value between stratas
 MaxTm, TmBy, define the viewmax and increment for x-axis
 yLabl, used to assign label of y-axis
 _Time _SurvProb _Censor _AtRisk _tAtRisk _Stratum, those variables are created
 by SAS proc lifetest with option of ods output survivalplot=
-------------------------------------------------------------------------------
                            Programmer Information
-------------------------------------------------------------------------------
 Author                 : Houhui Hu                                Copyright(c)
 Creation Date          : 4APR2019
-------------------------------------------------------------------------------
                            Change Control Information
-------------------------------------------------------------------------------
 Modifications:
 Programmer/Date:     		Reason:
 ----------------     		-----------------------------------------------------

-------------------------------------------------------------------------------
                            Future
-------------------------------------------------------------------------------
==============================================================================*/

proc template;
define statgraph Graphics.KM;
  dynamic _by _Time _SurvProb _Censor _AtRisk _tAtRisk _strata _median _prob;
  mvar title footer LogRnkP StraLabl xLabl yLabl;
  nmvar MaxTm TmBy;
  begingraph;
    if (exists(title))
      entrytitle halign=center title;
    endif;
    if (exists(footer))
      entryfootnote halign=left footer;
    endif;
    layout lattice;
      layout overlay /xaxisopts=(label=xLabl linearopts=(viewmin=0 viewmax=MaxTm
                      tickvaluesequence=(start=0 end=MaxTm increment=TmBy)
                      tickvaluefitpolicy=staggerthin))
                      yaxisopts=(label=yLabl linearopts=(viewmin=0 viewmax=1));
        stepplot x=_Time y=_SurvProb /group=_strata name='KM'
                                      lineattrs=(pattern=solid)
                                      ;
        if (exists(_Censor))
          scatterplot x=_Time y=_Censor /group=_strata name='Censor'
                                         markerattrs=(symbol=plus);
          layout gridded /border=true autoalign=(topright);
            entry '+ Censored';
          endlayout;
        endif;
        referenceline y=.5 /yaxis=Y lineattrs=(pattern=dash)
                            curvelabel='0.5' curvelabelposition=min;
        if (exists(_median))
          scatterplot x=_median y=_prob /group=_strata
                                         markerattrs=(symbol=diamond)
                                         datalabel=_median
                                      /* datalabelposition=auto|topright */
                                         ;
        endif;
        innermargin /align=bottom;
          axistable x=_tAtRisk value=_AtRisk /title='At Risk' class=_strata
                                              colorgroup=_strata
                                              display=(label values);
        endinnermargin;
        if (exists(LogRnkP))
          layout gridded /columns=1 autoalign=(bottomleft);
            entry halign=left 'Log Rank p: ' LogRnkP;
          endlayout;
        endif;
      endlayout;
      if (exists(_strata))
        sidebar /align=bottom spacefill=false;
          discretelegend 'KM' /title=StraLabl;
        endsidebar;
      endif;
    endlayout;
  endgraph;
end;
run;
