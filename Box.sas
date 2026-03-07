/*=============================================================================
                            Environment Information
-------------------------------------------------------------------------------
 SAS Version            : 9.4 under Windows 10
-------------------------------------------------------------------------------
                            Purpose
-------------------------------------------------------------------------------
 Define Box Plot template with SAS GTL boxplotparm, note the input data must be
 precomputed with %BoxPlot
-------------------------------------------------------------------------------
                            GTL dynamic or mvar Description
-------------------------------------------------------------------------------
 title/footer, entrytitles and/or entryfootnote
 yLabl/xLabl, use to assign the label of axes, passed from %BoxPlot by default
 _y, Required, the statistical values needed for the box plot. At a minimum,
     there must be nonmissing values for the 25th and 75th percentiles
 _stat, Required, specifies the name of a column that contains the statistic
        represented by the value in the _y (at least nonmissing Y values for
        STAT in Q1 and Q3 are required)
 _x, Optional, qualify or classify the values in the _y, used to create a plot
     box for each classifier
 _grp, Optional, used to draw for each unique group value
 GrpLabl, define the title of lengend, passed from %BoxPlot by default
 _yRefHi/_yRefLo, define the upper/lower limit(normal range) of _y
-------------------------------------------------------------------------------
                            Programmer Information
-------------------------------------------------------------------------------
 Author                 : Houhui Hu                                Copyright(c)
 Creation Date          : 19JUL2023
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
define statgraph Graphics.Box;
  dynamic _by _y 'Req' _stat 'Req' _x _grp _OutlierLabl _yRefHi _yRefLo
          _N _Mean _Std _DATAMAX _MAX _Q3 _MEDIAN _Q1 _MIN _DATAMIN;
  mvar byval footer yLabl xLabl GrpLabl LablFar;
  begingraph;
    if (exists(_by))
      entrytitle halign=center 'Box Plot for ' eval(collabel(_by)) '=' byval;
    endif;
    if (exists(footer))
      entryfootnote halign=left footer /textattrs=(size=8);
    endif;
    layout lattice;
      layout overlay /xaxisopts=(label=xLabl display=(line tickvalues label)
                                 discreteopts=(tickvaluefitpolicy=rotate))
                      yaxisopts=(label=yLabl display=(line tickvalues label)
                                 griddisplay=on);

        if (exists(_x))
          blockplot x=_x block=_x
                   /display=(fill) filltype=alternate datatransparency=.7;
        endif;

        if (exists(_grp))
          boxplotparm y=_y stat=_stat x=_x
                     /name='box' group=_grp groupdisplay=cluster
                      datalabel=_OutlierLabl spread=true labelfar=LablFar;
         /* outlineattrs=(pattern=solid) medianattrs=(pattern=solid) extreme=true|false */
          if (exists(_x))
            innermargin /align=bottom separator=false pad=(bottom=0) opaque=true;
              axistable x=_x value=_N /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_Mean /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_Std /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_DATAMAX /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_MAX /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_Q3 /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_MEDIAN /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_Q1 /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_MIN /class=_grp classdisplay=cluster colorgroup=_grp;
              axistable x=_x value=_DATAMIN /class=_grp classdisplay=cluster colorgroup=_grp;
            endinnermargin;
          endif;
        else
          boxplotparm x=_x y=_y stat=_stat
                     /datalabel=_OutlierLabl spread=true labelfar=LablFar
                      displaystats=(DATAMIN MIN Q1 MEDIAN Q3 MAX DATAMAX STD MEAN N)
                      /* displaystats = (standard|all) */
                      ;
        endif;

        if (exists(_yRefHi))
          referenceline y=_yRefHi /yaxis=y lineattrs=(pattern=shortdash)
                                   curvelabel='Upper limit';
        endif;

        if (exists(_yRefLo))
          referenceline y=_yRefLo /yaxis=y lineattrs=(pattern=shortdash)
                                   curvelabel='Lower limit';
        endif;

      endlayout;
      if (exists(_grp))
        sidebar /align=bottom spacefill=false;
          discretelegend 'box' /title=GrpLabl;
        endsidebar;
      endif;
    endlayout;
  endgraph;
end;
run;
