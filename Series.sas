
proc template;
define statgraph Graphics.Series;
  dynamic _x _y _yErr _n _yRefLo _LoLabl _yRefHi _HiLabl _grp;
  mvar xTvLst xTdLst IncRng yLabl PtLabl GrpLabl title footer;
  nmvar xMax yMin yMax;
  begingraph; /* for xBreak: /axisbreaktype=axis axisbreaksymbol=bracket */
    if (exists(title))
      entrytitle halign=center title;
    endif;
    if (exists(footer))
      entryfootnote halign=left footer;
    endif;
    layout lattice;
      layout overlay /xaxisopts=(
                        linearopts=(viewmin=0 viewmax=xMax
                        tickvaluelist=xTvLst tickdisplaylist=xTdLst
                        tickvaluefitpolicy=thin)
                      )
                      /* for xBreak: includeranges=IncRng (e.g, 0-75 215-290) */
                      yaxisopts=(
                        label=yLabl linearopts=(viewmin=yMin viewmax=yMax)
                      ); /* shortlabel='meaning, short label' */
        if (exists(_yErr))
          seriesplot x=_x y=_y /name='series' display=all
                                datalabel=PtLabl group=_grp
                                groupdisplay=cluster clusterwidth=.5
                                yerrorlower=eval(_y+_yErr)
                                yerrorupper=eval(_y-_yErr);
        else
          seriesplot x=_x y=_y /name='series' display=all
                                datalabel=PtLabl group=_grp;
        endif;
        if (exists(_n))
          innermargin /align=bottom;
            axistable x=_x value=_n /title='N' class=_grp
                                     colorgroup=_grp display=(values);
          endinnermargin;
        endif;
        if (exists(_yRefLo))
          referenceline y=_yRefLo /yaxis=Y lineattrs=(pattern=dash)
                                   curvelabel=_LoLabl
                                   curvelabellocation=inside
                                   curvelabelposition=min;
        endif;
        if (exists(_yRefHi))
          referenceline y=_yRefHi /yaxis=Y lineattrs=(pattern=dash)
                                   curvelabel=_HiLabl
                                   curvelabellocation=inside
                                   curvelabelposition=min;
        endif;
      endlayout;
      if (exists(_grp))
        sidebar /align=bottom spacefill=false;
          discretelegend 'series' /title=GrpLabl;
        endsidebar;
      endif;
    endlayout;
  endgraph;
end;
quit;
