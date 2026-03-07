
proc template;
define statgraph Graphics.Scatter;
dynamic _title _footer _x _y _grp _Xmax _Xincr _Ymax _Yincr;
begingraph;
  if (exists(_title))
    entrytitle halign=center _title;
  endif;
  if (exists(_footer))
    entryfootnote halign=left _footer;
  endif;
  layout overlay/xaxisopts=(linearopts=(viewmin=0 viewmax=_Xmax
                            tickvaluesequence=(start=0 end=_Xmax increment=_Xincr)))
                 yaxisopts=(linearopts=(viewmin=0 viewmax=_Ymax
                            tickvaluesequence=(start=0 end=_Ymax increment=_Yincr)))
                 ;
    scatterplot x=_x y=_y /group=_grp name='scatter';
    discretelegend 'scatter';
    annotate;
  endlayout;
endgraph;
end;
run;
