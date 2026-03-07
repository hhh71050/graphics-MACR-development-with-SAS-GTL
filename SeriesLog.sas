
proc template;
define statgraph Graphics.SeriesLog;
  dynamic _x _y _n _yRefLo _LoLabl _yRefHi _HiLabl _grp;
  mvar xTvLst xTdLst yLabl PtLabl GrpLabl title footer;
  nmvar xMax yMin yMax;
  begingraph;
    if (exists(title))
      entrytitle halign=center title;
    endif;
    if (exists(footer))
      entryfootnote halign=left footer;
    endif;
    layout lattice;
      layout overlay /xaxisopts=(linearopts=(viewmin=0 viewmax=xMax tickvaluelist=xTvLst
                                 tickdisplaylist=xTdLst tickvaluefitpolicy=thin))
                      yaxisopts=(label=yLabl type=log logopts=(base=10
                                 viewmin=yMin viewmax=yMax valuestype=expanded
                                 tickintervalstyle=logexpand minorticks=true));
        seriesplot x=_x y=_y /name='series' display=all datalabel=PtLabl group=_grp;
        if (exists(_n))
          innermargin /align=bottom;
            axistable x=_x value=_n /title='N' class=_grp
                                     colorgroup=_grp display=(values);
          endinnermargin;
        endif;
        if (exists(_yRefLo))
          referenceline y=_yRefLo /yaxis=Y lineattrs=(pattern=dash) curvelabel=_LoLabl
                                   curvelabellocation=inside curvelabelposition=min;
        endif;
        if (exists(_yRefHi))
          referenceline y=_yRefHi /yaxis=Y lineattrs=(pattern=dash) curvelabel=_HiLabl
                                   curvelabellocation=inside curvelabelposition=min;
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
