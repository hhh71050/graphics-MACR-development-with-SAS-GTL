/*=============================================================================
                            Environment Information
-------------------------------------------------------------------------------
 SAS Version            : 9.4 under Windows 10
-------------------------------------------------------------------------------
                            Purpose
-------------------------------------------------------------------------------
 Define WaterFall Plot template with SAS GTL.
-------------------------------------------------------------------------------
                            GTL dynamic or mvar Description
-------------------------------------------------------------------------------
 _id, category of barchartparm, e.g, SUBJID
 _pchg, response of barchartparm, e.g, BDS.PCHG, ADTR.AVAL where PARAMCD=PCBSD
 _grp, work as group option in barchartparm, e.g, TRTA
 _BarLabl, column that work as datalabel option in barchartparm, e.g, ADRS.AVALC
           where PARAMCD=BOR
 yMin and yMax will be get from _pchg with some fix method
-------------------------------------------------------------------------------
                            Programmer Information
-------------------------------------------------------------------------------
 Author                 : Houhui Hu                                Copyright(c)
 Creation Date          : 18- FEB2023
-------------------------------------------------------------------------------
                            Change Control Information
-------------------------------------------------------------------------------
 Modifications:
 Programmer/Date:       Reason:
 ----------------       -----------------------------------------------------

-------------------------------------------------------------------------------
                            Future
-------------------------------------------------------------------------------

==============================================================================*/

proc template;
define statgraph Graphics.WaterFall;
  dynamic _by _id _pchg _grp _BarLabl;
  mvar title footer GrpLabl GridLabl;
  nmvar yMin yMax;
  begingraph;
    if (exists(title))
      entrytitle halign=center title;
    endif;
    if (exists(footer))
      entryfootnote halign=left footer;
    endif;
    layout overlay /xaxisopts=(display=(label tickvalues)
                               discreteopts=(tickvaluefitpolicy=rotate))
                    yaxisopts=(linearopts=(viewmin=yMin viewmax=yMax));
      barchartparm category=_id response=eval(dsort(_pchg, retain=all))
                  /name='bar' barwidth=.7 group=_grp groupdisplay=cluster
                   datalabel=_BarLabl;
      bandplot x=_id limitupper=20 limitlower=-30
              /datatransparency=0.6
               curvelabellocation=outside extend=true
               curvelabellower='-30%' curvelabelupper='20%';
               *legendlabel='Confidence';
      if (exists(_grp))
        discretelegend 'bar' /title=GrpLabl location=inside
                              autoalign=(topright) across=1;
      endif;
      layout gridded /columns=1 border=true autoalign=(bottomleft);
        entry halign=center GridLabl /textattrs=(size=8 weight=bold); *or GraphLabelText;
        entry 'C=CR' /textattrs=(size=7); *or textattrs=GraphValueText;
        entry 'R=PR' /textattrs=(size=7);
        entry 'S=SD' /textattrs=(size=7);
        entry 'P=PD' /textattrs=(size=7);
        entry 'N=NE' /textattrs=(size=7);
      endlayout;
    endlayout;
  endgraph;
end;
run;
