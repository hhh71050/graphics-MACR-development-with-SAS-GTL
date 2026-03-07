/*=============================================================================
                            Environment Information
-------------------------------------------------------------------------------
 SAS Version            : 9.4 under Windows 10
-------------------------------------------------------------------------------
                            Purpose
-------------------------------------------------------------------------------
 Define Swimmer Plot template with SAS GTL.
-------------------------------------------------------------------------------
                            GTL dynamic or mvar Description
-------------------------------------------------------------------------------
 _subj, observation object, will act as y-axis e.g, SUBJID
 _low/_high, column or expression of minimum and maximum response values
 _grp, work as group option in highlowplot, e.g, TRTA
 _HiCap, column used to specify the type of highcap at the high end of the bar
         e.g, use a FilledArrow to indicates continued observation or response
 _HiLabl, column from shorted EVNTDESC (Event or Censoring Description)
-------------------------------------------------------------------------------
                            Programmer Information
-------------------------------------------------------------------------------
 Author                 : Houhui Hu                                Copyright(c)
 Creation Date          : 05JUN2024
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
define statgraph Graphics.Swimmer;
  dynamic _by _subj _low _high _grp _HiCap _HiLabl;
  mvar byval title footer xLabl GrpLabl;
  nmvar MaxTm TmBy;
  begingraph;
    if (exists(title))
      entrytitle halign=center title;
    endif;
    if (exists(footer))
      entryfootnote halign=left footer;
    endif;
    layout overlay /xaxisopts=
                    (label=xLabl griddisplay=on
                     linearopts=(viewmin=0 viewmax=MaxTm
                     tickvaluesequence=(start=0 end=MaxTm increment=TmBy)))
                    yaxisopts=
                    (type=discrete reverse=true
                     display=(label tickvalues)
                     tickvalueattrs=(size=7))
                     ;
      highlowplot y=_subj low=_low high=eval(dsort(_high, retain=all))
                 /name='HighLow' type=bar
                  highlabel=_HiLabl /* highcap=_HiCap */
                  group=_grp groupdisplay=cluster clusterwidth=.5
                  ;
      if (exists(_HiCap))
        scatterplot x=_HiCap y=_subj /* x=eval(_HiCap+.005*MaxTm) */
                   /group=_grp
                    markerattrs=(symbol=TriangleRightFilled size=10);
      endif;
      if (exists(_grp))
        discretelegend 'HighLow' /location=inside across=1
                                  title=GrpLabl autoalign=(bottomright);
      endif;
    endlayout;
  endgraph;
end;
run;
